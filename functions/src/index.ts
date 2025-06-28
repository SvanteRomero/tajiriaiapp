/* eslint-disable linebreak-style */
/* eslint-disable @typescript-eslint/no-explicit-any */

/* eslint-disable require-jsdoc */
/* eslint-disable max-len */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {GoogleAuth} from "google-auth-library";
import {VertexAI} from "@google-cloud/vertexai";

admin.initializeApp();
const db = admin.firestore();

functions.params.defineString("GEMINI_API_KEY");

// ===============================================================================================
// Internal Helper Functions for Core Logic
// ===============================================================================================

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

/**
 * Creates a new transaction in Firestore for a given user and updates the account balance.
 * @param {string} userId - The ID of the user.
 * @param {any} data - The transaction data.
 * @return {Promise<{success: boolean, message: string}>} A confirmation message.
 */
async function _createTransaction(userId: string, data: any) {
  const {description, amount, type, category, accountId, currency} = data;
  if (!description || !amount || !type || !category || !accountId || !currency) {
    throw new HttpsError("invalid-argument", "Missing required fields for transaction.");
  }

  const numericAmount = Number(amount);
  const transactionRef = db.collection("users").doc(userId).collection("transactions").doc();
  const accountRef = db.collection("users").doc(userId).collection("accounts").doc(accountId);

  return db.runTransaction(async (firestoreTransaction) => {
    const accountDoc = await firestoreTransaction.get(accountRef);
    if (!accountDoc.exists) {
      throw new HttpsError("not-found", "The specified account does not exist.");
    }

    const currentBalance = (accountDoc.data()?.balance || 0) as number;
    const newBalance = type === "income" ? currentBalance + numericAmount : currentBalance - numericAmount;

    firestoreTransaction.update(accountRef, {balance: newBalance});

    const transactionData = {
      description,
      amount: numericAmount,
      type,
      category,
      accountId,
      currency,
      date: admin.firestore.Timestamp.now(),
    };

    firestoreTransaction.set(transactionRef, transactionData);

    return {success: true, message: "Transaction created and account balance updated."};
  });
}


/**
 * Creates a new goal in Firestore for a given user.
 * @param {string} userId - The ID of the user.
 * @param {any} data - The goal data.
 * @return {Promise<{success: boolean, message: string}>} A confirmation message.
 */
async function _createGoal(userId: string, data: any) {
  const {goalName, targetAmount, endDate, dailyLimit} = data;

  if (!goalName || !targetAmount || !endDate || !dailyLimit) {
    throw new HttpsError("invalid-argument", "Missing required fields for goal: goalName, targetAmount, endDate, dailyLimit.");
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
}


/**
 * Main function for the AI Advisor Chat
 * This function now uses Gemini to determine the user's intent.
 */
export const getAdvisoryMessage = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const userId = request.auth.uid;
  const userMessage = request.data.message as string;

  if (!userMessage) {
    throw new HttpsError("invalid-argument", "The function must be called with a 'message' argument.");
  }

  // --- Initialize Vertex AI ---
  const auth = new GoogleAuth({scopes: "https://www.googleapis.com/auth/cloud-platform"});
  const projectId = await auth.getProjectId();
  const location = "us-central1";
  const vertexAI = new VertexAI({project: projectId, location: location});
  const generativeModel = vertexAI.preview.getGenerativeModel({model: "gemini-2.5-pro"});

  // --- Intent Recognition Prompt ---
  const intentPrompt = `
  You are an intelligent financial assistant. Your goal is to understand the user's request and categorize it into one of the following intents: 'create_transaction', 'create_goal', 'get_spending_summary', or 'chat'.

  Analyze the user's message: "${userMessage}"

  Follow these rules for intent recognition:
  1.  **'create_transaction'**: The user wants to record a new expense or income.
      -   Extract 'amount' (as a number) and 'description' (a string).
      -   If the user mentions "spent," "paid," "bought," or similar words, the transaction 'type' is 'expense.'
      -   If the user mentions "earned," "received," "got paid," or similar words, the 'type' is 'income.'
      -   If the type is not specified, ask the user to clarify.

  2.  **'create_goal'**: The user wants to set a new financial goal.
      -   Extract 'goalName' (a string), 'targetAmount' (a number), 'endDate' (in YYYY-MM-DD format), and 'dailyLimit' (a number).
      -   If any of these are missing, ask for the missing information.

  3.  **'get_spending_summary'**: The user wants to see a summary of their spending.
      -   Extract the 'timeFrame' (e.g., "this week," "last month," "today").
      -   If no time frame is mentioned, default to "this month."

  4.  **'chat'**: If the user's request does not fit any of the above, classify it as a general chat.

  Respond in JSON format only.

  Examples:
  -   User: "I spent 5000 on lunch"
      Response: {"intent": "create_transaction", "amount": 5000, "description": "lunch", "type": "expense"}

  -   User: "I want to save for a new car. The goal is 2,000,000 by the end of next year. My daily spending limit is 15,000"
      Response: {"intent": "create_goal", "goalName": "New Car", "targetAmount": 2000000, "endDate": "2025-12-31", "dailyLimit": 15000}

  -   User: "Show me my spending for last week"
      Response: {"intent": "get_spending_summary", "timeFrame": "last week"}

  -   User: "What's the best way to save money?"
      Response: {"intent": "chat"}
  `;

  try {
    const intentResult = await generativeModel.generateContent(intentPrompt);
    if (!intentResult.response.candidates || intentResult.response.candidates.length === 0) {
      throw new HttpsError("internal", "No response from AI model for intent recognition.");
    }

    const rawIntentResponse = intentResult.response.candidates[0].content.parts[0].text;
    const cleanIntentResponse = rawIntentResponse?.replace(/```json/g, "").replace(/```/g, "");

    const intentData = JSON.parse(cleanIntentResponse ?? "{}");

    // --- Execute Actions Based on Intent ---

    if (intentData.intent === "create_transaction") {
      const {amount, description, type} = intentData;
      if (!amount || !description || !type) {
        return {reply: "I see you want to add a transaction, but I'm missing some details. Please tell me the amount, what it was for, and whether it was an expense or income."};
      }

      const accountsSnapshot = await db.collection("users").doc(userId).collection("accounts").limit(1).get();
      if (accountsSnapshot.empty) {
        return {reply: "I can't add a transaction because you don't have an account yet. Please add an account first."};
      }
      const account = accountsSnapshot.docs[0].data();
      const accountId = accountsSnapshot.docs[0].id;

      await _createTransaction(userId, {
        description,
        amount,
        type,
        category: "General",
        accountId,
        currency: account.currency,
      });

      return {reply: `Transaction of ${account.currency} ${amount} for "${description}" has been added as an ${type}.`};
    }

    if (intentData.intent === "create_goal") {
      await _createGoal(userId, intentData);
      return {reply: `I've created a new goal for you: "${intentData.goalName}" with a target of ${intentData.targetAmount}.`};
    }

    if (intentData.intent === "get_spending_summary") {
      const {timeFrame} = intentData;
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
    }


    // --- Default to Advisory Chat ---
    const chatPrompt = `
        You are a friendly financial advisor named Tajiri. Your goal is to provide concise, helpful, and encouraging financial advice.

        User's question: "${userMessage}"
        
        Provide a response that is easy to understand and actionable (max 3-4 sentences).
      `;
    const chatResult = await generativeModel.generateContent(chatPrompt);
    if (!chatResult.response.candidates || chatResult.response.candidates.length === 0) {
      throw new HttpsError("internal", "No response from AI model for chat.");
    }
    const chatResponse = chatResult.response.candidates[0].content.parts[0].text;

    return {reply: chatResponse ?? "I'm not sure how to respond to that. Can you try rephrasing?"};
  } catch (error) {
    console.error("Error in getAdvisoryMessage:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "An error occurred while processing your request.");
  }
});


export const createTransaction = onCall(async (request: CallableRequest) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  return _createTransaction(request.auth.uid, request.data);
});

export const createGoal = onCall(async (request: CallableRequest) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  return _createGoal(request.auth.uid, request.data);
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
