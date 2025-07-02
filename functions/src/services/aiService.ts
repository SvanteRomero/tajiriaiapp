/* eslint-disable @typescript-eslint/no-explicit-any */
// functions/services/aiService.ts
import {GoogleAuth} from "google-auth-library";
import {VertexAI} from "@google-cloud/vertexai";

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
  async getIntentAndEntities(userMessage: string) {
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
   * Generates a personalized financial tip based on user's financial data.
   * @param {string} userId The user's ID.
   * @param {object} financialData User's financial data including transactions, budgets, goals.
   * @returns {Promise<string>} A personalized financial tip.
   */
  // CORRECTED: Changed the type of 'categories' in financialData to a map.
  async getPersonalizedFinancialTip(userId: string, financialData: { transactions: any[], budgets: any[], goals: any[], categories: { [key: string]: { type: "income" | "expense"; keywords: string[]; } } }) {
    const generativeModel = await this.getGenerativeModel();

    const {transactions, budgets, goals, categories} = financialData;

    // Summarize transactions
    const spendingSummary: { [category: string]: number } = {};
    const incomeSummary: { [category: string]: number } = {};
    const recentTransactions = transactions.slice(0, 10); // Focus on recent activity

    recentTransactions.forEach((t) => {
      if (t.type === "expense") {
        spendingSummary[t.category] = (spendingSummary[t.category] || 0) + t.amount;
      } else if (t.type === "income") {
        incomeSummary[t.category] = (incomeSummary[t.category] || 0) + t.amount;
      }
    });

    const spendingText = Object.entries(spendingSummary).map(([cat, amount]) => `${cat}: ${amount.toFixed(2)}`).join(", ");
    const incomeText = Object.entries(incomeSummary).map(([cat, amount]) => `${cat}: ${amount.toFixed(2)}`).join(", ");

    // Summarize budgets
    const budgetText = budgets.map((b) => `Budget for ${b.category}: ${b.amount.toFixed(2)}`).join(", ");

    // Summarize goals
    const goalText = goals.map((g) => `Goal '${g.goal_name}': Target ${g.target_amount.toFixed(2)}, Saved ${g.saved_amount.toFixed(2)}, Daily Limit ${g.daily_limit.toFixed(2)}, Ends ${g.end_date.toDate().toLocaleDateString()}`).join("; ");

    // Summarize categories (newly added to prompt context)
    const categoriesText = Object.entries(categories).map(([name, data]) => `${name} (Type: ${data.type})`).join(", ");


    const prompt = `
    Based on the following financial data for the user (amounts are in their local currency unless specified):

    Recent Spending Categories: ${spendingText || "No recent spending."}
    Recent Income Categories: ${incomeText || "No recent income."}
    Current Budgets: ${budgetText || "No active budgets."}
    Active Goals: ${goalText || "No active goals."}
    User's Custom Categories: ${categoriesText || "No custom categories."}

    Provide ONE personalized and actionable financial tip (max 2-3 sentences).
    Focus on practical advice, such as:
    - Identifying a potential overspending area and suggesting a small, actionable change.
    - Encouraging progress on a specific goal.
    - Suggesting reviewing subscriptions if applicable based on categories.
    - Simple saving hacks related to their spending.
    - Avoid generic statements like "save money" or "budget wisely".
    - Make it direct and encouraging.

    Example Tip Format: "We noticed you spent a bit much on [category]. Try [specific action] to save [small amount/percentage]."
    `;

    const result = await generativeModel.generateContent(prompt);
    if (!result.response.candidates || result.response.candidates.length === 0) {
      return "I'm not able to generate a personalized tip right now. How about reviewing your common expenses?";
    }
    return result.response.candidates[0].content.parts[0].text ?? "Here's a general tip: track your spending regularly to understand where your money goes!";
  },
};
