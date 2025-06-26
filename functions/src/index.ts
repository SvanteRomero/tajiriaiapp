/* eslint-disable @typescript-eslint/no-unused-vars */
// functions/src/index.ts
/* eslint-disable max-len */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler"; // Correct import for scheduled functions
import {GoogleAuth} from "google-auth-library";
import {VertexAI} from "@google-cloud/vertexai";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Make sure to set this secret using the Firebase CLI:
// firebase functions:secrets:set GEMINI_API_KEY
functions.params.defineString("GEMINI_API_KEY");

/**
 * A helper function to determine a date range from text.
 * @param {string} text The user's message.
 * @return {{startDate: Date, endDate: Date, timeFrameText: string}} A date range.
 */
function getDateRangeFromText(text: string): {startDate: Date, endDate: Date, timeFrameText: string} {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const lowerCaseText = text.toLowerCase();

  let startDate = new Date(0); // Default to all time
  let endDate = new Date();
  let timeFrameText = "of all time";

  if (lowerCaseText.includes("this month")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), 1);
    timeFrameText = "for this month";
  } else if (lowerCaseText.includes("last month")) {
    startDate = new Date(today.getFullYear(), today.getMonth() - 1, 1);
    endDate = new Date(today.getFullYear(), today.getMonth(), 0);
    timeFrameText = "for last month";
  } else if (lowerCaseText.includes("last week")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay() - 6);
    endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay());
    timeFrameText = "for last week";
  } else if (lowerCaseText.includes("this week")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay() + 1);
    timeFrameText = "for this week";
  } else if (lowerCaseText.includes("yesterday")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    endDate = today;
    timeFrameText = "for yesterday";
  } else if (lowerCaseText.includes("today")) {
    startDate = today;
    timeFrameText = "for today";
  }

  return {startDate, endDate, timeFrameText};
}

// Existing getAdvisoryMessage function (modified to use CallableRequest type hint)
export const getAdvisoryMessage = onCall(async (request: CallableRequest) => {
  // 1. Authenticate the user - access auth from request.auth
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }
  const userId = request.auth.uid;
  // Access the message from request.data
  const userMessage = request.data.message as string;

  if (!userMessage) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with a 'message' argument.",
    );
  }

  try {
    // --- FETCH TRANSACTIONS (EXPENSE DATA) ---
    const {startDate, endDate, timeFrameText} = getDateRangeFromText(userMessage);

    let expenseQuery: admin.firestore.Query = db
      .collection("users").doc(userId).collection("transactions")
      .where("type", "==", "expense");

    if (startDate.getTime() > 0) {
      expenseQuery = expenseQuery.where("date", ">=", startDate);
    }
    expenseQuery = expenseQuery.where("date", "<=", endDate).orderBy("date", "desc");

    const expensesSnapshot = await expenseQuery.get();
    const expenses = expensesSnapshot.docs.map((doc) => doc.data());

    const expenseContext = expenses.length > 0 ?
      expenses
        .map((exp) => `- ${exp.description || exp.category}: $${exp.amount.toFixed(2)} on ${new Date(exp.date._seconds * 1000).toLocaleDateString()}`)
        .join("\n") : "No expenses were found for this period.";

    // --- FETCH GOALS DATA ---
    const goalsSnapshot = await db.collection("users").doc(userId).collection("goals").get();
    const goals = goalsSnapshot.docs.map((doc) => doc.data());

    const goalsContext = goals.length > 0 ?
      goals
        .map((goal) => `- Goal: '${goal.goal_name}', Progress: $${goal.saved_amount.toFixed(2)} / $${goal.target_amount.toFixed(2)}`)
        .join("\n") : "No active savings goals found.";

    // --- CONSTRUCT THE PROMPT ---
    const prompt = `
      You are a friendly and helpful AI financial advisor named Tajiri for an expense tracker app.
      The current date is ${new Date().toLocaleDateString()}.
      A user is asking for advice. Your tone should be encouraging and non-judgmental.

      USER'S QUESTION: "${userMessage}"

      Based on the user's question, I have retrieved the following financial data:

      1. SPENDING DATA ${timeFrameText}:
      ${expenseContext}

      2. ACTIVE SAVINGS GOALS:
      ${goalsContext}

      Based on ALL of this data (both spending and goals), provide a concise, helpful, and actionable response (max 3-4 sentences).
      Connect their spending habits to their goal progress where relevant. For example, if they ask about saving money, you can suggest cutting back on a high-spending category to help them reach their goals faster.
      If no data was found, state that. If their question is not related to finance, politely decline to answer.
    `;

    // --- CALL THE GEMINI API ---
    const auth = new GoogleAuth({scopes: "https://www.googleapis.com/auth/cloud-platform"});
    const projectId = await auth.getProjectId();
    const location = "us-central1";
    const vertexAI = new VertexAI({project: projectId, location: location});

    const generativeModel = vertexAI.preview.getGenerativeModel({
      model: "gemini-2.5-flash",
    });

    const result = await generativeModel.generateContent(prompt);
    const response = result.response;

    if (!response.candidates || response.candidates.length === 0) {
      throw new HttpsError("internal", "No response from AI model.");
    }

    const aiResponseText = response.candidates[0].content.parts[0].text;

    return {reply: aiResponseText};
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error; // Re-throw HttpsError directly
    }
    console.error("Error in getAdvisoryMessage:", error);
    throw new HttpsError("internal", "An error occurred while getting your advice.");
  }
});


// New Cloud Function to process daily goals
export const processDailyGoals = onSchedule( // Fixed: use onSchedule from firebase-functions/v2/scheduler
  {
    schedule: "every day 00:05", // Using a specific time
    timeZone: "Africa/Dar_es_Salaam", // Specify the time zone for the schedule
  },
  async (_context) => { // Fixed: Renamed context to _context to suppress unused variable warning
    console.log("Running daily goal processing...");

    const usersRef = db.collection("users");
    const usersSnapshot = await usersRef.get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const goalsRef = usersRef.doc(userId).collection("goals");
      const activeGoalsSnapshot = await goalsRef.where("goal_status", "==", "active").get();

      for (const goalDoc of activeGoalsSnapshot.docs) {
        const goalData = goalDoc.data();
        const goalId = goalDoc.id;

        const dailyLimit = goalData.daily_limit;
        const timezone = goalData.timezone || "Africa/Dar_es_Salaam"; // Use saved timezone or default
        const now = new Date();

        // Convert current date to the user's timezone for accurate daily tracking
        const userTimeZoneDate = new Date(now.toLocaleString("en-US", {timeZone: timezone}));
        userTimeZoneDate.setHours(0, 0, 0, 0); // Start of the day in user's timezone
        const startOfDay = admin.firestore.Timestamp.fromDate(userTimeZoneDate);

        // End of the day in user's timezone (just before next midnight)
        const endOfDay = new Date(userTimeZoneDate);
        endOfDay.setDate(userTimeZoneDate.getDate() + 1);
        endOfDay.setMilliseconds(endOfDay.getMilliseconds() - 1);
        const endOfToday = admin.firestore.Timestamp.fromDate(endOfDay);


        // Fetch user's expenses for today
        const expensesSnapshot = await usersRef
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
        let dailyStatus = "skipped"; // Default to skipped if no transactions

        // Handle first-day edge case: if start_date is today, don't penalize for previous spending
        const goalStartDate = goalData.start_date.toDate();
        const isFirstDay = userTimeZoneDate.toDateString() === goalStartDate.toDateString();

        if (totalSpentToday > 0 || !isFirstDay) { // Only process if there's spending or it's not the first day
          if (totalSpentToday <= dailyLimit) {
            savedAmountToday = dailyLimit - totalSpentToday;
            dailyStatus = "success";
            goalData.streak_count = (goalData.streak_count || 0) + 1;
            console.log(`User ${userId} saved ${savedAmountToday} today for goal ${goalId}. Streak: ${goalData.streak_count}`);
          } else {
            const overspentAmount = totalSpentToday - dailyLimit;
            dailyStatus = "failed";
            goalData.streak_count = 0; // Reset streak
            goalData.grace_days_used = (goalData.grace_days_used || 0) + 1;
            console.warn(`User ${userId} overspent by ${overspentAmount} for goal ${goalId}. Grace days used: ${goalData.grace_days_used}`);
          }
        }


        // Update goal document
        const newSavedAmount = (goalData.saved_amount || 0) + savedAmountToday;
        const newGoalStatus = newSavedAmount >= goalData.target_amount ? "completed" : goalData.goal_status;

        await goalsRef.doc(goalId).update({
          saved_amount: newSavedAmount,
          streak_count: goalData.streak_count,
          grace_days_used: goalData.grace_days_used,
          goal_status: newGoalStatus,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Write a new daily_log document
        await goalsRef.doc(goalId).collection("daily_logs").doc(userTimeZoneDate.toISOString().split("T")[0]).set({
          date: startOfDay,
          spent_amount: totalSpentToday,
          saved_amount: savedAmountToday,
          status: dailyStatus,
          comment: dailyStatus === "success" ? `Well done, ${savedAmountToday.toFixed(2)} saved!` : `Overspent by ${(totalSpentToday - dailyLimit).toFixed(2)}.`,
        });

        // Trigger push notification (pseudo-code)
        // You'll need to integrate with a notification service (e.g., Firebase Cloud Messaging)
        let notificationMessage = "";
        if (dailyStatus === "success") {
          notificationMessage = `🎉 You saved ${savedAmountToday.toFixed(2)} towards your ${goalData.goal_name} goal today! Streak: ${goalData.streak_count} days.`;
        } else if (dailyStatus === "failed") {
          notificationMessage = `⚠️ You overspent today for your ${goalData.goal_name} goal. Grace days used: ${goalData.grace_days_used}.`;
        } else {
          notificationMessage = `Daily goal check completed for ${goalData.goal_name}.`;
        }

        // Example: Send notification via FCM (requires client-side token registration)
        // admin.messaging().sendToDevice(userFcmToken, { notification: { title: 'Goal Update', body: notificationMessage } });
        console.log(`Notification for user ${userId}: ${notificationMessage}`);


        // Optionally trigger Tajiri AI chat message (can be a separate callable function)
        // This is a simplified example; a real implementation would involve a more complex AI interaction flow.
        let aiFeedback = "";
        if (newGoalStatus === "completed") {
          aiFeedback = `🎊 Congrats! You've successfully completed your goal: ${goalData.goal_name}! Your dedication paid off.`;
          console.log(`AI message for user ${userId}: ${aiFeedback}`);
          // You could then save this message to a 'messages' subcollection for the AI chat.
        } else if (dailyStatus === "success" && goalData.streak_count > 0 && goalData.streak_count % 7 === 0) {
          aiFeedback = `Awesome consistency! You're on a ${goalData.streak_count}-day saving streak for your ${goalData.goal_name} goal. Keep it up!`;
          console.log(`AI message for user ${userId}: ${aiFeedback}`);
        } else if (dailyStatus === "failed" && goalData.grace_days_used > 0) {
          aiFeedback = `It looks like you went a little over your daily limit today for your ${goalData.goal_name} goal. You've used ${goalData.grace_days_used} grace days. Let's get back on track tomorrow!`;
          console.log(`AI message for user ${userId}: ${aiFeedback}`);
        }
        // To trigger AI message, you'd call a separate function here or directly write to a chat collection
        // await db.collection("users").doc(userId).collection("messages").add({
        //   text: aiFeedback,
        //   isFromUser: false,
        //   timestamp: admin.firestore.FieldValue.serverTimestamp()
        // });
      }
    }
    console.log("Daily goal processing finished.");
  });

// Callable function to suggest daily limit (AI Assistant)
export const suggestDailyLimit = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }
  const userId = request.auth.uid;

  // Calculate average daily spending for the last 30 days
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const thirtyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);

  const expensesSnapshot = await db
    .collection("users").doc(userId).collection("transactions")
    .where("type", "==", "expense")
    .where("date", ">=", thirtyDaysAgoTimestamp)
    .get();

  let totalSpending = 0;
  const uniqueDays = new Set<string>(); // Fixed: Changed 'let' to 'const'

  expensesSnapshot.forEach((doc) => {
    totalSpending += (doc.data().amount || 0);
    const date = (doc.data().date as admin.firestore.Timestamp).toDate().toDateString();
    uniqueDays.add(date);
  });

  const numberOfDays = uniqueDays.size > 0 ? uniqueDays.size : 30; // Prevent division by zero, default to 30 days if no expenses
  const suggestedLimit = totalSpending / numberOfDays;

  let aiResponse = "";
  if (totalSpending === 0) {
    aiResponse = "Based on your spending history, I recommend setting a realistic daily spending limit. You haven't recorded any expenses in the last 30 days, so start by tracking your usual spending to get a clearer picture.";
  } else {
    aiResponse = `Based on your average daily spending of TZS ${suggestedLimit.toFixed(2)} over the last 30 days, a reasonable daily spending limit for your goal could be TZS ${suggestedLimit.toFixed(2)}. Remember, setting a slightly lower limit can help you reach your goals faster!`;
  }

  return {reply: aiResponse};
});

export const deleteAbandonedGoals = onSchedule(
  {
    schedule: "every 12 hours",
    timeZone: "UTC",
  },
  async () => {
    console.log("Running scheduled function to delete abandoned goals...");

    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
    const cutoffTimestamp = admin.firestore.Timestamp.fromDate(threeDaysAgo);

    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const goalsRef = db
        .collection("users")
        .doc(userId)
        .collection("goals");

      const abandonedGoalsQuery = goalsRef
        .where("goal_status", "==", "abandoned")
        .where("abandoned_at", "<=", cutoffTimestamp);

      const goalsToDeleteSnapshot = await abandonedGoalsQuery.get();

      if (goalsToDeleteSnapshot.empty) {
        continue;
      }

      const batch = db.batch();
      goalsToDeleteSnapshot.forEach((doc) => {
        console.log(`Scheduling deletion for goal ${doc.id} for user ${userId}.`);
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${goalsToDeleteSnapshot.size} abandoned goals for user ${userId}.`);
    }

    console.log("Finished deleting abandoned goals.");
  }
);
