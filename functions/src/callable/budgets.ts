import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {firestoreService} from "../services/firestoreService";

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

  await firestoreService.addBudget(userId, budget);

  return {
    success: true,
    message: "Budget created successfully.",
  };
});

