import {onSchedule} from "firebase-functions/v2/scheduler";
import {firestoreService} from "../services/firestoreService";
import * as admin from "firebase-admin";
import {aiService} from "../services/aiService";

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
    schedule: "every day 10:00", // Changed from 'every monday 10:00' based on prompt
    timeZone: "Africa/Dar_es_Salaam",
  },
  async () => {
    console.log("Running personalized financial tip function...");

    const usersSnapshot = await firestoreService.getUsers(); // Fetch all users

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();

      if (user && user.financialTips) { // Check user's notification settings
        try {
          // Fetch user's financial data
          const transactions = await firestoreService.getUserTransactionsForTip(userId);
          const budgets = await firestoreService.getUserBudgetsForTip(userId);
          const goals = await firestoreService.getUserGoalsForTip(userId);
          const categories = await firestoreService.getUserCategories(userId); // Fetch categories for better context

          const financialData = {transactions, budgets, goals, categories};

          // Generate a personalized tip using AI
          const personalizedTip = await aiService.getPersonalizedFinancialTip(userId, financialData);

          const payload = {
            notification: {
              title: "Your Daily Financial Tip from Tajiri! 💡",
              body: personalizedTip,
            },
            topic: userId, // Target the specific user
          };

          await admin.messaging().send(payload);
          console.log(`Sent personalized financial tip to user ${userId}`);
        } catch (error) {
          console.error(`Error sending personalized financial tip to user ${userId}:`, error);
        }
      }
    }
    console.log("Finished sending personalized financial tips.");
  }
);
