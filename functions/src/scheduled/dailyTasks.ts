// functions/scheduled/dailyTasks.ts
import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {firestoreService} from "../services/firestoreService";
import {checkAndSendMilestoneNotification, checkAndSendStreakNotification} from "../utils/notificationUtils"; // Assuming this is also refactored

const db = admin.firestore();

export const processDailyGoals = onSchedule(
  {
    schedule: "every 12 hours",
    timeZone: "Africa/Dar_es_Salaam",
  },
  async () => {
    console.log("Running daily goal processing...");

    const usersSnapshot = await firestoreService.getUsers();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();
      const activeGoals = await firestoreService.getActiveGoals(userId);

      for (const goalDoc of activeGoals) {
        const goalData = goalDoc.data;
        const goalId = goalDoc.id;
        goalData.id = goalId; // Add the ID to the data object for the payload

        const dailyLimit = goalData.daily_limit;
        const timezone = goalData.timezone || "Africa/Dar_es_Salaam";
        const now = new Date();

        const userTimeZoneDate = new Date(now.toLocaleString("en-US", {timeZone: timezone}));
        userTimeZoneDate.setHours(0, 0, 0, 0);
        const startOfDay = admin.firestore.Timestamp.fromDate(userTimeZoneDate);

        const endOfDay = new Date(userTimeZoneDate);
        endOfDay.setDate(userTimeZoneDate.getDate() + 1);
        endOfDay.setMilliseconds(endOfDay.getMilliseconds() - 1);
        const endOfToday = admin.firestore.Timestamp.fromDate(endOfDay);

        const expensesSnapshot = await db
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .where("type", "==", "expense")
          .where("date", ">=", startOfDay)
          .where("date", "<=", endOfToday)
          .get();

        let totalSpentToday = 0;
        expensesSnapshot.forEach((doc) => {
          totalSpentToday += (doc.data().amount || 0);
        });

        let savedAmountToday = 0;
        let dailyStatus = "skipped";
        const oldStreak = goalData.streak_count || 0;

        const goalStartDate = goalData.start_date.toDate();
        const isFirstDay = userTimeZoneDate.toDateString() === goalStartDate.toDateString();

        if (totalSpentToday > 0 || !isFirstDay) {
          if (totalSpentToday <= dailyLimit) {
            savedAmountToday = dailyLimit - totalSpentToday;
            dailyStatus = "success";
            goalData.streak_count = (goalData.streak_count || 0) + 1;
          } else {
            dailyStatus = "failed";
            goalData.streak_count = 0;
            goalData.grace_days_used = (goalData.grace_days_used || 0) + 1;
          }
        }

        // Milestone & Streak Logic
        const oldSavedAmount = goalData.saved_amount || 0;
        const newSavedAmount = oldSavedAmount + savedAmountToday;
        await checkAndSendMilestoneNotification(userId, user, goalData, oldSavedAmount, newSavedAmount);
        if (goalData.streak_count > oldStreak) {
          await checkAndSendStreakNotification(userId, user, goalData.streak_count);
        }
        // End Milestone & Streak Logic

        const newGoalStatus = newSavedAmount >= goalData.target_amount ? "completed" : goalData.status;

        await firestoreService.updateGoal(userId, goalId, {
          saved_amount: newSavedAmount,
          streak_count: goalData.streak_count,
          grace_days_used: goalData.grace_days_used,
          status: newGoalStatus,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        await firestoreService.addDailyGoalLog(userId, goalId, userTimeZoneDate.toISOString().split("T")[0], {
          date: startOfDay,
          spent_amount: totalSpentToday,
          saved_amount: savedAmountToday,
          status: dailyStatus,
          comment: dailyStatus === "success" ? `Well done, ${savedAmountToday.toFixed(2)} saved!` : `Overspent by ${(totalSpentToday - dailyLimit).toFixed(2)}.`,
        });

        if (user.goalNotifications) {
          const payload = {
            notification: {
              title: `Daily Goal Update: ${goalData.goal_name}`,
              body: `You spent ${totalSpentToday.toFixed(2)} today. Your new balance is ${newSavedAmount.toFixed(2)}.`,
            },
            topic: userId,
          };
          try {
            await admin.messaging().send(payload);
          } catch (error) {
            console.error("Error sending goal notification:", error);
          }
        }
      }
    }
    console.log("Daily goal processing finished.");
  }
);
