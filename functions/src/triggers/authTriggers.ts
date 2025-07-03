import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const triggerWelcomeNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const uid = request.auth.uid;
  const userRecord = await admin.auth().getUser(uid);
  const displayName = userRecord.displayName || "friend";

  const fcmPayload = {
    // This is what the user sees
    notification: {
      title: `Welcome to Tajiri AI, ${displayName}!`,
      body: "We're excited to help you on your financial journey. Let's get started!",
    },
    // This is the data for your app to handle taps
    data: {
      payload: "open_chat", // The crucial payload
    },
    topic: uid,
  };

  try {
    await admin.messaging().send(fcmPayload);
    console.log(`Successfully sent welcome message to user ${uid}`);
    return {success: true};
  } catch (error) {
    console.error(`Error sending welcome notification to ${uid}:`, error);
    throw new HttpsError("internal", "Failed to send welcome notification.");
  }
});
