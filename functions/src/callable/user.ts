import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Initialize the Admin SDK once if it hasn't been already.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

/**
 * [ADMIN] Deletes a specified user's account and all their data.
 * Can only be called by an authenticated user with an `admin` custom claim.
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
 * For enhanced security, the client should enforce re-authentication of the acting admin
 * before calling this function.
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
