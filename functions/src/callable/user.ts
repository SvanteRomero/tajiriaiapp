/* eslint-disable require-jsdoc */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();
const storage = admin.storage();

async function deleteCollection(path: string, batchSize: number) {
  const collectionRef = db.collection(path);
  const query = collectionRef.orderBy("__name__").limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(query: FirebaseFirestore.Query, resolve: (value: unknown) => void) {
  const snapshot = await query.get();

  if (snapshot.size === 0) {
    return resolve(0);
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();

  process.nextTick(() => {
    deleteQueryBatch(query, resolve);
  });
}

export const deleteUserData = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const uid = request.auth.uid;

  try {
    // Delete Firestore sub-collections
    const subcollections = ["transactions", "accounts", "goals", "budgets", "categories"];
    for (const collection of subcollections) {
      await deleteCollection(`users/${uid}/${collection}`, 50);
    }

    // Delete main user document
    await db.collection("users").doc(uid).delete();

    // Delete profile picture from Storage
    const bucket = storage.bucket();
    const file = bucket.file(`user_avatars/${uid}.jpg`);
    const [exists] = await file.exists();
    if (exists) {
      await file.delete();
    }

    // Delete user from Auth
    await admin.auth().deleteUser(uid);

    return {success: true, message: "User data deleted successfully."};
  } catch (error) {
    console.error("Error deleting user data:", error);
    throw new HttpsError("internal", "Failed to delete user data.");
  }
});
