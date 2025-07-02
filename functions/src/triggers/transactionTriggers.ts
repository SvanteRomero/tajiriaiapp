import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {firestoreService} from "../services/firestoreService";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const sendTransactionalNotification = onDocumentCreated(
  "users/{userId}/transactions/{transactionId}",
  async (event) => {
    const transaction = event.data?.data();
    const userId = event.params.userId;

    if (!transaction) {
      console.log("No transaction data found.");
      return;
    }

    const userDoc = await firestoreService.getUserNotificationSettings(userId);
    const user = userDoc;

    if (
      user &&
            user.transactionalNotifications &&
            transaction.amount > 1000
    ) {
      const payload = {
        notification: {
          title: "Large Transaction Alert",
          body: `A new transaction of ${transaction.currency} ${transaction.amount.toFixed(
            2
          )} for "${transaction.description}" has been recorded.`,
        },
        topic: userId,
      };

      try {
        await admin.messaging().send(payload);
      } catch (error) {
        console.error("Error sending transaction notification:", error);
      }
    }
  }
);
