import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

export const sendWelcomeNotification = onDocumentCreated(
  "users/{userId}",
  async (event) => {
    const user = event.data?.data();
    const userId = event.params.userId;

    if (!user) {
      console.log("No user data found.");
      return;
    }

    if (user.financialTips) {
      const payload = {
        notification: {
          title: `Welcome to Tajiri AI, ${user.displayName || "friend"}!`,
          body: "We're excited to help you on your financial journey. Let's get started!",
        },
        topic: userId,
      };

      try {
        await admin.messaging().send(payload);
        console.log(`Successfully sent welcome message to user ${userId}`);
      } catch (error) {
        console.error("Error sending welcome notification:", error);
      }
    }
  }
);

