// functions/scheduled/dailyTasks.ts
import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {firestoreService} from "../services/firestoreService";
import {checkAndSendMilestoneNotification, checkAndSendStreakNotification} from "../utils/notificationUtils";

const db = admin.firestore();

export const processDailyGoals = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "UTC",
  },
  async () => {
    console.log("Hourly check for daily goal processing...");

    const usersSnapshot = await firestoreService.getUsers();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const user = userDoc.data();
      const timezone = user.timezone || "UTC"; // Default to UTC if not set

      let nowInUserTimezone;
      try {
        nowInUserTimezone = new Date(new Date().toLocaleString("en-US", {timeZone: timezone}));
      } catch (e) {
        console.error(`Invalid timezone '${timezone}' for user ${userId}. Defaulting to UTC.`);
        nowInUserTimezone = new Date(new Date().toLocaleString("en-US", {timeZone: "UTC"}));
      }

      // We want to run this just after midnight, so we check for hour 0.
      if (nowInUserTimezone.getHours() !== 0) {
        continue;
      }

      const activeGoals = await firestoreService.getActiveGoals(userId);

      for (const goalDoc of activeGoals) {
        const goalData = goalDoc.data;
        const goalId = goalDoc.id;
        goalData.id = goalId;

        const yesterday = new Date(nowInUserTimezone);
        yesterday.setDate(nowInUserTimezone.getDate() - 1);

        const startOfDay = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate());
        const endOfDay = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate(), 23, 59, 59, 999);

        const lastProcessedDate = goalData.lastProcessedDate?.toDate();
        if (lastProcessedDate && lastProcessedDate.getTime() === startOfDay.getTime()) {
          console.log(`Goal ${goalId} for user ${userId} already processed for this date. Skipping.`);
          continue;
        }

        const startOfDayTimestamp = admin.firestore.Timestamp.fromDate(startOfDay);
        const endOfDayTimestamp = admin.firestore.Timestamp.fromDate(endOfDay);

        const expensesSnapshot = await db.collection("users").doc(userId).collection("transactions")
          .where("type", "==", "expense")
          .where("date", ">=", startOfDayTimestamp)
          .where("date", "<=", endOfDayTimestamp).get();

        let totalSpentToday = 0;
        expensesSnapshot.forEach((doc) => {
          totalSpentToday += (doc.data().amount || 0);
        });

        // CORRECTED: The variable 'dailyLimit' is accessed from 'goalData'.
        const savedAmountToday = goalData.daily_limit - totalSpentToday;
        const dailyStatus = savedAmountToday >= 0 ? "success" : "failed";

        let newStreakCount = goalData.streak_count || 0;
        let newGraceDaysUsed = goalData.grace_days_used || 0;

        if (dailyStatus === "success") {
          newStreakCount++;
        } else {
          newStreakCount = 0;
          newGraceDaysUsed++;
        }

        const oldSavedAmount = goalData.saved_amount || 0;
        const newSavedAmount = oldSavedAmount + savedAmountToday;

        await checkAndSendMilestoneNotification(userId, user, goalData, oldSavedAmount, newSavedAmount);

        if (newStreakCount > (goalData.streak_count || 0)) {
          await checkAndSendStreakNotification(userId, user, newStreakCount);
        }

        const newGoalStatus = newSavedAmount >= goalData.target_amount ? "completed" : "active";

        await firestoreService.updateGoal(userId, goalId, {
          saved_amount: newSavedAmount,
          streak_count: newStreakCount,
          grace_days_used: newGraceDaysUsed,
          status: newGoalStatus,
          lastProcessedDate: startOfDayTimestamp,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        await firestoreService.addDailyGoalLog(userId, goalId, startOfDay.toISOString().split("T")[0], {
          date: startOfDayTimestamp,
          spent_amount: totalSpentToday,
          saved_amount: savedAmountToday > 0 ? savedAmountToday : 0,
          status: dailyStatus,
          comment: dailyStatus === "success" ?
            `Well done, you saved ${savedAmountToday.toFixed(2)}!` :
            `Overspent by ${(totalSpentToday - goalData.daily_limit).toFixed(2)}.`,
        });

        if (user.goalNotifications) {
          const payload = {
            notification: {
              title: `Daily Goal Update: ${goalData.goal_name}`,
              body: `You spent ${totalSpentToday.toFixed(2)} yesterday. Your new saved amount is ${newSavedAmount.toFixed(2)}.`,
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
    console.log("Hourly check finished.");
  }
);
