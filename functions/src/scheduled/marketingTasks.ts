// functions/src/scheduled/marketingTasks.ts
import {onSchedule} from "firebase-functions/v2/scheduler";
import {firestoreService} from "../services/firestoreService";
import * as admin from "firebase-admin";
import {aiService} from "../services/aiService";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const sendWeeklySummary = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "UTC",
  },
  async () => {
    console.log("Hourly check for weekly summary...");
    const usersSnapshot = await firestoreService.getUsers();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();
      const timezone = user.timezone || "UTC";

      let nowInUserTimezone;
      try {
        nowInUserTimezone = new Date(new Date().toLocaleString("en-US", {timeZone: timezone}));
      } catch (e) {
        console.error(`Invalid timezone '${timezone}' for user ${userId}.`);
        continue;
      }

      // Send on Sunday at 9 AM local time
      if (nowInUserTimezone.getDay() === 0 && nowInUserTimezone.getHours() === 9) {
        if (user.financialSummaries) {
          const sevenDaysAgo = new Date(nowInUserTimezone);
          sevenDaysAgo.setDate(nowInUserTimezone.getDate() - 7);

          const expensesSnapshot = await admin.firestore().collection("users").doc(userId).collection("transactions")
            .where("type", "==", "expense").where("date", ">=", sevenDaysAgo).get();

          const incomeSnapshot = await admin.firestore().collection("users").doc(userId).collection("transactions")
            .where("type", "==", "income").where("date", ">=", sevenDaysAgo).get();

          const totalExpense = expensesSnapshot.docs.reduce((acc, exp) => acc + exp.data().amount, 0);
          const totalIncome = incomeSnapshot.docs.reduce((acc, inc) => acc + inc.data().amount, 0);

          const payload = {
            notification: {
              title: "Your Weekly Financial Summary",
              body: `Last week, you spent ${totalExpense.toFixed(2)} and earned ${totalIncome.toFixed(2)}.`,
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
  }
);

export const sendFinancialTip = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "UTC",
  },
  async () => {
    console.log("Hourly check for financial tip...");

    const usersSnapshot = await firestoreService.getUsers();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();
      const timezone = user.timezone || "UTC";

      let nowInUserTimezone;
      try {
        nowInUserTimezone = new Date(new Date().toLocaleString("en-US", {timeZone: timezone}));
      } catch (e) {
        console.error(`Invalid timezone '${timezone}' for user ${userId}.`);
        continue;
      }

      // Send daily at 10 AM local time
      if (nowInUserTimezone.getHours() === 10) {
        if (user && user.financialTips) {
          try {
            const transactions = await firestoreService.getUserTransactionsForTip(userId);
            const budgets = await firestoreService.getUserBudgetsForTip(userId);
            const goals = await firestoreService.getUserGoalsForTip(userId);
            const categories = await firestoreService.getUserCategories(userId);

            const financialData = {transactions, budgets, goals, categories};
            const personalizedTip = await aiService.getPersonalizedFinancialTip(userId, financialData);

            const payload = {
              notification: {
                title: "Your Daily Financial Tip from Tajiri! 💡",
                body: personalizedTip,
              },
              topic: userId,
            };

            await admin.messaging().send(payload);
            console.log(`Sent personalized financial tip to user ${userId}`);
          } catch (error) {
            console.error(`Error sending personalized financial tip to user ${userId}:`, error);
          }
        }
      }
    }
    console.log("Finished hourly check for financial tips.");
  }
);
