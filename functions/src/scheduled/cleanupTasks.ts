import {onSchedule} from "firebase-functions/v2/scheduler";
import {firestoreService} from "../services/firestoreService";
import * as admin from "firebase-admin";

export const deleteAbandonedGoals = onSchedule(
  {schedule: "every 12 hours", timeZone: "UTC"},
  async () => {
    console.log("Running scheduled function to delete abandoned goals...");
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
    const cutoffTimestamp = admin.firestore.Timestamp.fromDate(threeDaysAgo);
    const usersSnapshot = await firestoreService.getUsers();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const goalsToDeleteSnapshot = await firestoreService.getAbandonedGoals(userId, cutoffTimestamp);
      if (goalsToDeleteSnapshot.empty) continue;

      const batch = admin.firestore().batch();
      goalsToDeleteSnapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Deleted ${goalsToDeleteSnapshot.size} abandoned goals for user ${userId}.`);
    }

    console.log("Finished deleting abandoned goals.");
  }
);

export const sendChatNudgeNotification = onSchedule(
  {schedule: "every 72 hours", timeZone: "Africa/Dar_es_Salaam"},
  async () => {
    console.log("Running scheduled function to nudge users to chat...");
    const nudgeMessages = [
      "Have a financial question on your mind? Your AI advisor is here to help.",
      "Curious about your spending habits or how to save more? Ask Tajiri!",
      "It's a great day to check in on your financial goals. Ask your AI advisor for tips!",
    ];
    const usersSnapshot = await firestoreService.getUsers();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();
      if (user && user.personalizedAlerts) {
        const messageBody = nudgeMessages[Math.floor(Math.random() * nudgeMessages.length)];
        const payload = {
          notification: {
            title: "Got a Question? 💬",
            body: messageBody,
          },
          data: {
            payload: "open_chat",
          },
          topic: userId,
        };
        try {
          await admin.messaging().send(payload);
          console.log(`Successfully sent chat nudge to user ${userId}`);
        } catch (error) {
          console.error(`Error sending chat nudge to user ${userId}:`, error);
        }
      }
    }

    console.log("Finished sending chat nudges.");
  }
);
