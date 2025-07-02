/* eslint-disable linebreak-style */
/* eslint-disable @typescript-eslint/no-explicit-any */
// functions/utils/notificationUtils.ts
import * as admin from "firebase-admin";

/**
 * Checks if a user has crossed a savings goal milestone and sends a notification.
 * @param {string} userId The user's ID.
 * @param {any} user The user's data object.
 * @param {any} goalData The goal data object.
 * @param {number} oldSavedAmount The amount saved before the update.
 * @param {number} newSavedAmount The amount saved after the update.
 */
export async function checkAndSendMilestoneNotification(userId: string, user: any, goalData: any, oldSavedAmount: number, newSavedAmount: number) {
  const targetAmount = goalData.target_amount;
  const milestones = [0.25, 0.50, 0.75, 1.0]; // 25%, 50%, 75%, 100%

  for (const milestone of milestones) {
    const milestoneAmount = targetAmount * milestone;
    // Check if the user just crossed this milestone
    if (oldSavedAmount < milestoneAmount && newSavedAmount >= milestoneAmount) {
      const percentage = milestone * 100;
      let title = `You've hit ${percentage}% of your goal! 🎉`;
      let body = `Amazing work on your '${goalData.goal_name}' goal. You're getting closer!`;

      if (milestone === 1.0) {
        title = "Goal Complete! 🏆";
        body = `Congratulations! You've successfully reached your goal of saving for '${goalData.goal_name}'!`;
      }

      const payload = {
        notification: {title, body},
        data: {"payload": `view_goal_${goalData.id}`}, // Navigate to the specific goal
        topic: userId,
      };

      if (user && user.goalNotifications) {
        try {
          await admin.messaging().send(payload);
          console.log(`Sent milestone notification to ${userId} for ${percentage}%`);
        } catch (error) {
          console.error("Error sending milestone notification:", error);
        }
      }
      // Stop after sending the first milestone notification to avoid spam
      return;
    }
  }
}

/**
 * Checks if a user has hit a logging streak and sends a notification.
 * @param {string} userId The user's ID.
 * @param {any} user The user's data object.
 * @param {number} streakCount The new streak count.
 */
export async function checkAndSendStreakNotification(userId: string, user: any, streakCount: number) {
  // Streaks we want to celebrate
  const streakMilestones = [7, 14, 30, 60, 100];

  if (streakMilestones.includes(streakCount)) {
    const payload = {
      notification: {
        title: "New Logging Streak! 🔥",
        body: `You've logged your expenses for ${streakCount} days in a row. That's some serious dedication!`,
      },
      topic: userId,
    };

    if (user && user.goalNotifications) { // We can reuse the goalNotifications setting
      try {
        await admin.messaging().send(payload);
        console.log(`Sent streak notification to ${userId} for ${streakCount} days`);
      } catch (error) {
        console.error("Error sending streak notification:", error);
      }
    }
  }
}
