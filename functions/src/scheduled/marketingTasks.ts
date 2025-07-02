import {onSchedule} from "firebase-functions/v2/scheduler";
import {firestoreService} from "../services/firestoreService";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const sendWeeklySummary = onSchedule(
  {
    schedule: "every sunday 09:00",
    timeZone: "Africa/Dar_es_Salaam",
  },
  async () => {
    console.log("Running weekly summary function...");
    const usersSnapshot = await firestoreService.getUsers();
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();
      if (user.financialSummaries) {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const expensesSnapshot = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .where("type", "==", "expense")
          .where("date", ">=", sevenDaysAgo)
          .get();

        const incomeSnapshot = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .where("type", "==", "income")
          .where("date", ">=", sevenDaysAgo)
          .get();

        const totalExpense = expensesSnapshot.docs.reduce(
          (acc, exp) => acc + exp.data().amount,
          0
        );
        const totalIncome = incomeSnapshot.docs.reduce(
          (acc, inc) => acc + inc.data().amount,
          0
        );

        const payload = {
          notification: {
            title: "Your Weekly Financial Summary",
            body: `Last week, you spent ${totalExpense.toFixed(
              2
            )} and earned ${totalIncome.toFixed(2)}.`,
          },
          topic: userId,
        };

        try {
          await admin.messaging().send(payload);
        } catch (error) {
          console.error("Error sending weekly summary:", error);
        }
      }
    }
  }
);

export const sendFinancialTip = onSchedule(
  {
    schedule: "every day 10:00",
    timeZone: "Africa/Dar_es_Salaam",
  },
  async () => {
    console.log("Running financial tip function...");
    const usersSnapshot = await firestoreService.getUsers();
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();
      if (user.financialTips) {
        const tips = [
          "Set a budget and stick to it.",
          "Automate your savings.",
          "Pay off your high-interest debt first.",
          "Review your subscriptions and cancel any you don't use.",
        ];
        const tip = tips[Math.floor(Math.random() * tips.length)];
        const payload = {
          notification: {
            title: "Your Weekly Financial Tip",
            body: tip,
          },
          topic: userId,
        };
        try {
          await admin.messaging().send(payload);
        } catch (error) {
          console.error("Error sending financial tip:", error);
        }
      }
    }
  }
);
