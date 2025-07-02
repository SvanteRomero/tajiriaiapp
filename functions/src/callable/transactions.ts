/* eslint-disable @typescript-eslint/no-explicit-any */
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {firestoreService} from "../services/firestoreService";
import {getDateRangeFromText} from "../utils/dateUtils";

export const createTransaction = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  return firestoreService.createTransaction(request.auth.uid, request.data);
});

export const getSpendingSummary = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  const userId = request.auth.uid;
  const {timeFrame} = request.data;

  const {startDate, endDate, timeFrameText} = getDateRangeFromText(timeFrame || "this month");

  const expenses = await firestoreService.getSpendingSummaryData(userId, startDate, endDate);

  if (expenses.length === 0) {
    return {reply: `No spending recorded ${timeFrameText}.`};
  }

  const totalSpending = expenses.reduce((acc: number, exp: any) => acc + exp.amount, 0);
  const summary = expenses.map((exp: any) => `- ${exp.description}: ${exp.currency} ${exp.amount.toFixed(2)}`).join("\n");

  return {
    reply: `Here's your spending summary ${timeFrameText}:\n\n${summary}\n\nTotal: ${totalSpending.toFixed(2)}`,
  };
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

  await firestoreService.deleteTransaction(userId, transactionId);
  return {success: true, message: "Transaction deleted successfully."};
});
