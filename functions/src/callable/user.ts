/* eslint-disable @typescript-eslint/no-explicit-any */
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Initialize the Admin SDK once if it hasn't been already.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

/**
 * [ONE-TIME USE] Claims the first administrator account if no other admins exist.
 * This should be called from the browser console by the first user after they sign up.
 * It should be disabled or deleted after the first admin is successfully created.
 */
export const claimFirstAdmin = onCall(async (request) => {
  // 1. Ensure the user calling this function is authenticated.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to call this function."
    );
  }

  // 2. Check if any admin users already exist to prevent misuse.
  const listUsersResult = await auth.listUsers(10); // Check a small batch of users
  for (const user of listUsersResult.users) {
    if (user.customClaims && user.customClaims["admin"] === true) {
      throw new HttpsError(
        "already-exists",
        "An admin user already exists. This function can no longer be used."
      );
    }
  }

  // 3. If no admins exist, make the current user an admin.
  const uid = request.auth.uid;
  await auth.setCustomUserClaims(uid, {admin: true});

  return {
    message: `Success! You (${request.auth.token.email}) are now the first admin. Please refresh.`,
  };
});


/**
 * [ADMIN] Deletes a specified user's account and all their data.
 */
export const deleteUserData = onCall(async (request) => {
  if (request.auth?.token.admin !== true) {
    throw new HttpsError("permission-denied", "This function can only be called by an administrator.");
  }

  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError("invalid-argument", "The function must be called with a 'uid' argument.");
  }

  try {
    await db.collection("users").doc(uid).delete();
    await auth.deleteUser(uid);
    console.log(`ADMIN ACTION: Successfully deleted user ${uid}`);
    return {message: `Successfully deleted user ${uid}.`};
  } catch (error) {
    console.error(`ADMIN ACTION: Error deleting user ${uid}:`, error);
    throw new HttpsError("internal", "An unexpected error occurred while deleting the user.");
  }
});

/**
 * [ADMIN] Toggles a user's account status (disabled/enabled).
 */
export const toggleUserStatus = onCall(async (request) => {
  if (request.auth?.token.admin !== true) {
    throw new HttpsError("permission-denied", "This function can only be called by an administrator.");
  }
  const {uid, disable} = request.data;
  if (!uid || typeof disable !== "boolean") {
    throw new HttpsError("invalid-argument", "The function must be called with 'uid' (string) and 'disable' (boolean) arguments.");
  }
  try {
    await auth.updateUser(uid, {disabled: disable});
    const status = disable ? "disabled" : "enabled";
    return {message: `User ${uid} has been ${status}.`};
  } catch (error) {
    throw new HttpsError("internal", "An error occurred while updating user status.");
  }
});

/**
 * [ADMIN] Creates a new admin user or upgrades an existing user to an admin.
 */
export const setUserAsAdmin = onCall(async (request) => {
  if (request.auth?.token.admin !== true) {
    throw new HttpsError("permission-denied", "This function can only be called by an existing administrator.");
  }
  const {email, password} = request.data;
  if (typeof email !== "string" || email.length === 0) {
    throw new HttpsError("invalid-argument", "The function must be called with an 'email' argument.");
  }

  try {
    let user;
    let message;
    try {
      user = await auth.getUserByEmail(email);
      await auth.setCustomUserClaims(user.uid, {admin: true});
      message = `Success! Existing user ${email} has been upgraded to an admin.`;
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        if (!password || password.length < 6) {
          throw new HttpsError("invalid-argument", "A password of at least 6 characters is required to create a new admin user.");
        }
        user = await auth.createUser({
          email: email,
          password: password,
          displayName: `${email.split("@")[0]} (Admin)`,
        });
        await auth.setCustomUserClaims(user.uid, {admin: true});
        message = `Success! New admin account created for ${email}.`;
      } else {
        throw error;
      }
    }
    return {message: message};
  } catch (error) {
    console.error(`Error processing admin request for ${email}:`, error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "An unexpected error occurred.");
  }
});

/**
 * [USER] Deletes the currently authenticated user's own account and data.
 */
export const deleteOwnAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in to delete your account.");
  }
  const uid = request.auth.uid;
  try {
    await db.collection("users").doc(uid).delete();
    await auth.deleteUser(uid);
    console.log(`USER ACTION: User ${uid} successfully deleted their own account.`);
    return {message: "Your account has been successfully deleted."};
  } catch (error) {
    console.error(`USER ACTION: Error deleting own account for user ${uid}:`, error);
    throw new HttpsError("internal", "An unexpected error occurred while deleting your account.");
  }
});

// Add this new function to the end of the file

/**
 * Checks the status of a logged-in user to determine redirection logic.
 * @returns {{status: "admin" | "can-claim" | "non-admin"}}
 * - "admin": User has admin privileges.
 * - "can-claim": User is not an admin, but no other admins exist.
 * - "non-admin": User is not an admin, and other admins already exist.
 */
export const checkUserStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  // 1. Check if the calling user is already an admin.
  if (request.auth.token.admin === true) {
    return {status: "admin"};
  }

  // 2. If not an admin, check if any other admin user exists.
  try {
    // We only need to find one admin to know if the role is taken.
    const listUsersResult = await admin.auth().listUsers(100);
    for (const user of listUsersResult.users) {
      if (user.customClaims && user.customClaims["admin"] === true) {
        // An admin exists, but it's not the current user.
        return {status: "non-admin"};
      }
    }
    // If the loop completes and no admin was found, this user can claim the role.
    return {status: "can-claim"};
  } catch (error) {
    console.error("Error while checking for existing admin users:", error);
    // For security, default to "non-admin" if an error occurs.
    throw new HttpsError("internal", "An error occurred while checking user status.");
  }
});
