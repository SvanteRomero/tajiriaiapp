// functions/callable/accounts.ts
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {firestoreService} from "../services/firestoreService";

export const addAccount = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;
  const {accountName, initialBalance, currency} = request.data;

  if (!accountName || initialBalance === undefined || currency === undefined) {
    throw new HttpsError("invalid-argument", "Missing required fields for account: accountName, initialBalance, currency.");
  }

  try {
    const newAccount = {
      name: accountName,
      balance: Number(initialBalance),
      currency: currency || "TZS", // Default to USD if not provided
    };
    await firestoreService.addAccount(userId, newAccount); // Assuming firestoreService.addAccount exists and takes userId and account data
    return {success: true, message: `Account '${accountName}' with ${currency} ${initialBalance} added successfully!`};
  } catch (error) {
    console.error("Error adding account:", error);
    throw new HttpsError("internal", "Failed to add account. Please try again.");
  }
});
