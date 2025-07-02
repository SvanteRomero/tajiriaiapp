// functions/services/aiService.ts
import {GoogleAuth} from "google-auth-library";
import {VertexAI} from "@google-cloud/vertexai";
import * as admin from "firebase-admin"; // Needed for admin.firestore.Timestamp
import {firestoreService} from "./firestoreService"; // Import firestoreService

export const aiService = {
  async getGenerativeModel() {
    const auth = new GoogleAuth({scopes: "https://www.googleapis.com/auth/cloud-platform"});
    const projectId = await auth.getProjectId();
    const location = "us-central1"; // Or your preferred region
    const vertexAI = new VertexAI({project: projectId, location: location});
    return vertexAI.preview.getGenerativeModel({model: "gemini-2.5-pro"});
  },

  /**
   * Determines user intent and extracts entities for financial operations.
   * @param {string} userMessage The raw user message.
   * @return {Promise<any>} Parsed intent data.
   */
  async getIntentAndEntities(userMessage: string) { // Removed userCategories as it's not directly needed for intent extraction here
    const generativeModel = await this.getGenerativeModel();

    const intentPrompt = `
    You are an expert at analyzing user messages to understand their financial intent.
    Based on the user's message, determine if they want to 'create_transaction', 'add_account', or just 'chat'.
    
    Message: "${userMessage}"

    Follow these rules:
    1.  If the message mentions spending, buying, paying, earning, receiving money, or contains a clear monetary value, the intent is 'create_transaction'.
        -   Extract the 'amount' as a number (without currency symbols).
        -   Extract the 'description' (the main subject of the transaction).
        -   Determine the 'type' ('expense' for spending, 'income' for earning). If unsure, default to 'expense'.
    
    2.  If the message mentions creating an account, new account, or setting up a fund, the intent is 'add_account'.
        -   Extract the 'accountName' (e.g., "Savings Account", "Current Account").
        -   Extract the 'initialBalance' as a number.
        -   Extract the 'currency' (e.g., "USD", "TZS", "EUR"). Default to "USD" if not specified.
    
    3.  For anything else (questions, greetings, general statements), the intent is 'chat'.
    
    Respond in JSON format only. If a field is not present or cannot be extracted, omit it from the JSON.

    Examples:
    -   User: "I spent 5000 on lunch with a friend" -> {"intent": "create_transaction", "amount": 5000, "description": "lunch with a friend", "type": "expense"}
    -   User: "Received 150k for the design project" -> {"intent": "create_transaction", "amount": 150000, "description": "design project", "type": "income"}
    -   User: "Create a new savings account with 1000 USD" -> {"intent": "add_account", "accountName": "savings account", "initialBalance": 1000, "currency": "USD"}
    -   User: "Add a new current account" -> {"intent": "add_account", "accountName": "current account"}
    -   User: "How can I reduce my monthly bills?" -> {"intent": "chat"}
    `;

    const intentResult = await generativeModel.generateContent(intentPrompt);
    if (!intentResult.response.candidates || intentResult.response.candidates.length === 0) {
      throw new Error("No response from AI model for intent recognition.");
    }
    const rawIntentResponse = intentResult.response.candidates[0].content.parts[0].text;
    const cleanIntentResponse = rawIntentResponse?.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(cleanIntentResponse ?? "{}");
  },

  /**
   * Generates a general chat response from the AI advisor.
   * @param {string} userMessage The user's message.
   * @return {Promise<string>} The AI's chat response.
   */
  async getChatResponse(userMessage: string) {
    const generativeModel = await this.getGenerativeModel();
    const chatPrompt = `
        You are a friendly and insightful financial advisor named Tajiri.
        The user's question is: "${userMessage}"
        Provide a concise, encouraging, and helpful response (max 3-4 sentences).
      `;
    const chatResult = await generativeModel.generateContent(chatPrompt);
    if (!chatResult.response.candidates || chatResult.response.candidates.length === 0) {
      throw new Error("No response from AI model for chat.");
    }
    return chatResult.response.candidates[0].content.parts[0].text ?? "I'm not sure how to respond to that. Can you try rephrasing?";
  },

  /**
   * Suggests a daily spending limit based on recent user expenses.
   * @param {string} userId The user's ID.
   * @return {Promise<string>} The AI's suggestion.
   */
  async suggestDailyLimit(userId: string) {
    const expenses = await firestoreService.getTransactionsForDailyLimitSuggestion(userId);

    let totalSpending = 0;
    const uniqueDays = new Set<string>();

    expenses.forEach((exp) => {
      totalSpending += (exp.amount || 0);
      const date = (exp.date as admin.firestore.Timestamp).toDate().toDateString();
      uniqueDays.add(date);
    });

    const numberOfDays = uniqueDays.size > 0 ? uniqueDays.size : 30; // Default to 30 if no unique days
    const suggestedLimit = totalSpending / numberOfDays;

    if (totalSpending === 0) {
      return "I can't suggest a daily limit because you haven't recorded any expenses in the last 30 days. Start by tracking your spending to get a clearer picture!";
    } else {
      // You might want to fetch the user's primary currency here for a more accurate suggestion.
      return `Based on your average daily spending of ${suggestedLimit.toFixed(2)} over the last month, a reasonable daily limit for your goal could be around ${suggestedLimit.toFixed(2)}. You can adjust this based on how fast you want to save!`;
    }
  },
};
