// functions/callable/aiAdvisor.ts (Updated)
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {aiService} from "../services/aiService";
import {firestoreService} from "../services/firestoreService";


export const getAdvisoryMessage = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const userId = request.auth.uid;
  const userMessage = request.data.message as string;
  const lowerCaseMessage = userMessage.toLowerCase();

  if (!userMessage) {
    throw new HttpsError("invalid-argument", "The function must be called with a 'message' argument.");
  }

  try {
    // AI-Powered Intent Recognition & Entity Extraction
    const intentData = await aiService.getIntentAndEntities(userMessage);

    // Execute Actions Based on Intent
    if (intentData.intent === "create_transaction") {
      const {amount, description, type} = intentData;
      if (!amount || !description || !type) {
        return {reply: "I see you want to add a transaction, but I'm missing some details. Please tell me the amount and what it was for."};
      }

      // Dynamic Category Assignment Logic (still needs userCategories)
      const userCategories = await firestoreService.getUserCategories(userId); // Fetch categories here
      let assignedCategory = "Miscellaneous";
      for (const categoryName of Object.keys(userCategories)) {
        for (const keyword of userCategories[categoryName].keywords) {
          if (lowerCaseMessage.includes(keyword)) {
            assignedCategory = categoryName;
            break;
          }
        }
        if (assignedCategory !== "Miscellaneous") break;
      }

      // Get user's primary account
      const account = await firestoreService.getUserPrimaryAccount(userId);
      if (!account) {
        return {reply: "I can't add a transaction because you don't have an account yet. Please add an account first."};
      }

      await firestoreService.createTransaction(userId, {
        description: description,
        amount,
        type,
        category: assignedCategory,
        accountId: account.id,
        currency: account.data.currency,
      });

      return {reply: `I've logged a transaction of ${account.data.currency} ${amount} for "${description}" under the '${assignedCategory}' category.`};
    } else if (intentData.intent === "add_account") {
      const {accountName, initialBalance, currency} = intentData;

      if (!accountName) {
        return {reply: "To add an account, I need a name for it. What would you like to call it?"};
      }

      // Provide a default or ask for initial balance/currency if missing
      const finalInitialBalance = initialBalance ?? 0; // Default to 0 if not provided
      const finalCurrency = currency ?? "TZS"; // Default to TZS if not provided

      // Here, instead of directly adding, you could ask for confirmation from the user in the app's UI
      // For now, we'll proceed directly:
      await firestoreService.addAccount(userId, {
        name: accountName,
        balance: finalInitialBalance,
        currency: finalCurrency,
      });
      return {reply: `I've successfully created a new account named '${accountName}' with an initial balance of ${finalCurrency} ${finalInitialBalance}.`};
    }

    // Default to General Advisory Chat
    const chatResponse = await aiService.getChatResponse(userMessage);
    return {reply: chatResponse};
  } catch (error) {
    console.error("Error in getAdvisoryMessage:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "An error occurred while processing your request.");
  }
});
