// functions/callable/goals.ts
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {firestoreService} from "../services/firestoreService";

export const createGoal = onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  return firestoreService.createGoal(request.auth.uid, request.data);
});
