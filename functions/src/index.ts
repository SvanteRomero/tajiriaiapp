/* eslint-disable linebreak-style */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable max-len */
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Import callable functions
export * from "./callable/transactions";
export * from "./callable/goals";
export * from "./callable/budgets";
export * from "./callable/aiAdvisor";
export * from "./callable/accounts";

// Import scheduled functions
export * from "./scheduled/dailyTasks";
export * from "./scheduled/cleanupTasks";
export * from "./scheduled/marketingTasks";

// Import triggered functions
export * from "./triggers/authTriggers";
export * from "./triggers/transactionTriggers";

