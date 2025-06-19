/* eslint-disable max-len */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
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

// Use the modern onCall handler from the v2 SDK
export const getAdvisoryMessage = onCall(async (request) => {
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
        .map((goal) => `- Goal: '${goal.title}', Progress: $${goal.currentAmount.toFixed(2)} / $${goal.targetAmount.toFixed(2)}`)
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
      model: "gemini-1.0-pro",
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
