/* eslint-disable linebreak-style */
/* eslint-disable max-len */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {GoogleAuth} from "google-auth-library";
import {VertexAI} from "@google-cloud/vertexai";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

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

// Function specifically for the AI Advisor Chat
export const getAdvisoryMessage = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid; // Used to fetch user-specific data
  const userMessage = request.data.message as string;

  if (!userMessage) {
    throw new HttpsError("invalid-argument", "The function must be called with a 'message' argument.");
  }

  try {
    // --- FETCH USER-SPECIFIC FINANCIAL DATA ---
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
        .map((exp) => `- ${exp.description || exp.category}: ${exp.currency} ${exp.amount.toFixed(2)} on ${new Date(exp.date._seconds * 1000).toLocaleDateString()}`)
        .join("\n") : "No expenses were found for this period.";

    const goalsSnapshot = await db.collection("users").doc(userId).collection("goals").get();
    const goals = goalsSnapshot.docs.map((doc) => doc.data());

    const goalsContext = goals.length > 0 ?
      goals
        .map((goal) => `- Goal: '${goal.goal_name}', Progress: ${goal.saved_amount.toFixed(2)} / ${goal.target_amount.toFixed(2)}`)
        .join("\n") : "No active savings goals found.";


    // --- CONSTRUCT THE PROMPT ---
    const prompt = `
      You are a friendly and helpful AI financial advisor named Tajiri for an expense tracker app.
      The current date is ${new Date().toLocaleDateString()}.
      A user is asking for advice. Your tone should be encouraging and non-judgmental.

      USER'S QUESTION: "${userMessage}"
      
      Based on the user's question, I have retrieved the following financial data for this user:

      1. SPENDING DATA ${timeFrameText}:
      ${expenseContext}

      2. ACTIVE SAVINGS GOALS:
      ${goalsContext}

      Based on ALL of this data (spending and goals), provide a concise, helpful, and actionable response (max 3-4 sentences).
      Connect their spending habits to their goal progress where relevant. For example, if they ask about saving money, you can suggest cutting back on a high-spending category to help them reach their goals faster.
      If no data was found, state that. If their question is not related to finance, politely decline to answer.
    `;

    // --- CALL THE GEMINI API ---
    const auth = new GoogleAuth({scopes: "https://www.googleapis.com/auth/cloud-platform"});
    const projectId = await auth.getProjectId();
    const location = "us-central1";
    const vertexAI = new VertexAI({project: projectId, location: location});

    const generativeModel = vertexAI.preview.getGenerativeModel({
      model: "gemini-2.5-pro",
    });

    const result = await generativeModel.generateContent(prompt);
    const response = result.response;

    if (!response.candidates || response.candidates.length === 0) {
      throw new HttpsError("internal", "No response from AI model.");
    }

    const aiResponseText = response.candidates[0].content.parts[0]?.text;

    return {reply: aiResponseText ?? "Sorry, I couldn't process that. Could you try rephrasing?"};
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("Error in getAdvisoryMessage:", error);
    throw new HttpsError("internal", "An error occurred while getting your advice.");
  }
});


// Specific callable functions for direct UI actions
export const createTransaction = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;
  const {description, amount, type, category, accountId, currency} = request.data;

  if (!description || !amount || !type || !category || !accountId || !currency) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  const transaction = {
    description,
    amount: Number(amount),
    type,
    category,
    accountId,
    currency,
    date: admin.firestore.Timestamp.now(),
  };

  await db.collection("users").doc(userId).collection("transactions").add(transaction);
  return {success: true, message: "Transaction created successfully."};
});

export const getSpendingSummary = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;
  const {timeFrame} = request.data;

  const {startDate, endDate, timeFrameText} = getDateRangeFromText(timeFrame || "this month");

  const expenseQuery = db
    .collection("users").doc(userId).collection("transactions")
    .where("type", "==", "expense")
    .where("date", ">=", startDate)
    .where("date", "<=", endDate);

  const expensesSnapshot = await expenseQuery.get();
  const expenses = expensesSnapshot.docs.map((doc) => doc.data());

  if (expenses.length === 0) {
    return {reply: `No spending recorded ${timeFrameText}.`};
  }

  const totalSpending = expenses.reduce((acc, exp) => acc + exp.amount, 0);
  const summary = expenses.map((exp) => `- ${exp.description}: ${exp.currency} ${exp.amount.toFixed(2)}`).join("\n");

  return {
    reply: `Here's your spending summary ${timeFrameText}:\n\n${summary}\n\nTotal: ${totalSpending.toFixed(2)}`,
  };
});

export const createGoal = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;
  const {goalName, targetAmount, endDate, dailyLimit} = request.data;

  if (!goalName || !targetAmount || !endDate || !dailyLimit) {
    throw new HttpsError("invalid-argument", "Missing required fields: goalName, targetAmount, endDate, dailyLimit.");
  }

  const goal = {
    goal_name: goalName,
    target_amount: Number(targetAmount),
    saved_amount: 0,
    start_date: admin.firestore.Timestamp.now(),
    end_date: admin.firestore.Timestamp.fromDate(new Date(endDate)),
    daily_limit: Number(dailyLimit),
    status: "active",
    created_at: admin.firestore.Timestamp.now(),
  };

  await db.collection("users").doc(userId).collection("goals").add(goal);
  return {success: true, message: "Goal created successfully."};
});

export const createBudget = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;
  const {category, amount} = request.data;

  if (!category || !amount) {
    throw new HttpsError("invalid-argument", "Missing required fields: category, amount.");
  }

  const now = new Date();
  const budget = {
    category,
    amount: Number(amount),
    month: now.getMonth() + 1,
    year: now.getFullYear(),
  };

  await db.collection("users").doc(userId).collection("budgets").add(budget);
  return {success: true, message: "Budget created successfully."};
});

export const deleteTransaction = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;
  const {transactionId} = request.data;

  if (!transactionId) {
    throw new HttpsError("invalid-argument", "transactionId is required.");
  }

  await db.collection("users").doc(userId).collection("transactions").doc(transactionId).delete();
  return {success: true, message: "Transaction deleted successfully."};
});

export const suggestDailyLimit = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;

  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const thirtyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);

  const expensesSnapshot = await db
    .collection("users").doc(userId).collection("transactions")
    .where("type", "==", "expense")
    .where("date", ">=", thirtyDaysAgoTimestamp)
    .get();

  let totalSpending = 0;
  const uniqueDays = new Set<string>();

  expensesSnapshot.forEach((doc) => {
    totalSpending += (doc.data().amount || 0);
    const date = (doc.data().date as admin.firestore.Timestamp).toDate().toDateString();
    uniqueDays.add(date);
  });

  const numberOfDays = uniqueDays.size > 0 ? uniqueDays.size : 30;
  const suggestedLimit = totalSpending / numberOfDays;

  let aiResponse = "";
  if (totalSpending === 0) {
    aiResponse = "I can't suggest a daily limit because you haven't recorded any expenses in the last 30 days. Start by tracking your spending to get a clearer picture!";
  } else {
    // Assuming TZS as a primary currency for suggestion text, this could be made more dynamic.
    aiResponse = `Based on your average daily spending of TZS ${suggestedLimit.toFixed(2)} over the last month, a reasonable daily limit for your goal could be around TZS ${suggestedLimit.toFixed(2)}. You can adjust this based on how fast you want to save!`;
  }

  return {reply: aiResponse};
});

export const processDailyGoals = onSchedule(
  {
    schedule: "every day 00:05",
    timeZone: "Africa/Dar_es_Salaam",
  },
  async () => {
    console.log("Running daily goal processing...");

    const usersRef = db.collection("users");
    const usersSnapshot = await usersRef.get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const goalsRef = usersRef.doc(userId).collection("goals");
      const activeGoalsSnapshot = await goalsRef.where("status", "==", "active").get();

      for (const goalDoc of activeGoalsSnapshot.docs) {
        const goalData = goalDoc.data();
        const goalId = goalDoc.id;

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
        let dailyStatus = "skipped";

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

        const newSavedAmount = (goalData.saved_amount || 0) + savedAmountToday;
        const newGoalStatus = newSavedAmount >= goalData.target_amount ? "completed" : goalData.status;

        await goalsRef.doc(goalId).update({
          saved_amount: newSavedAmount,
          streak_count: goalData.streak_count,
          grace_days_used: goalData.grace_days_used,
          status: newGoalStatus,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        await goalsRef.doc(goalId).collection("daily_logs").doc(userTimeZoneDate.toISOString().split("T")[0]).set({
          date: startOfDay,
          spent_amount: totalSpentToday,
          saved_amount: savedAmountToday,
          status: dailyStatus,
          comment: dailyStatus === "success" ? `Well done, ${savedAmountToday.toFixed(2)} saved!` : `Overspent by ${(totalSpentToday - dailyLimit).toFixed(2)}.`,
        });
      }
    }
    console.log("Daily goal processing finished.");
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
        .where("status", "==", "abandoned")
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
