/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable valid-jsdoc */
// functions/services/firestoreService.ts
import * as admin from "firebase-admin";

const db = admin.firestore();

export const firestoreService = {
  /**
   * Creates a new transaction in Firestore for a given user and updates the account balance.
   * @param {string} userId - The ID of the user.
   * @param {any} data - The transaction data.
   * @return {Promise<{success: boolean, message: string}>} A confirmation message.
   */
  async createTransaction(userId: string, data: any) {
    const {description, amount, type, category, accountId, currency} = data;
    if (!description || !amount || !type || !category || !accountId || !currency) {
      throw new Error("Missing required fields for transaction.");
    }

    const numericAmount = Number(amount);
    const transactionRef = db.collection("users").doc(userId).collection("transactions").doc();
    const accountRef = db.collection("users").doc(userId).collection("accounts").doc(accountId);

    return db.runTransaction(async (firestoreTransaction) => {
      const accountDoc = await firestoreTransaction.get(accountRef);
      if (!accountDoc.exists) {
        throw new Error("The specified account does not exist.");
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
  },

  /**
   * Creates a new goal in Firestore for a given user.
   * @param {string} userId - The ID of the user.
   * @param {any} data - The goal data.
   * @return {Promise<{success: boolean, message: string}>} A confirmation message.
   */
  async createGoal(userId: string, data: any) {
    const {goalName, targetAmount, endDate, dailyLimit} = data;

    if (!goalName || !targetAmount || !endDate || !dailyLimit) {
      throw new Error("Missing required fields for goal: goalName, targetAmount, endDate, dailyLimit.");
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
  },

  /**
   * Fetches user's custom categories from Firestore.
   * @param {string} userId The user's ID.
   * @returns {Promise<Record<string, {type: "income" | "expense", keywords: string[]}>>} User categories.
   */
  async getUserCategories(userId: string) {
    const categoriesSnapshot = await db.collection("users").doc(userId).collection("categories").get();
    const userCategories: {[key: string]: {type: "income" | "expense", keywords: string[]}} = {};

    categoriesSnapshot.forEach((doc) => {
      const categoryData = doc.data();
      const name = categoryData.name as string;
      const type = categoryData.type as "income" | "expense";

      if (name && type) {
        const keywords = name.toLowerCase().split(/[\s/]+/).filter((k) => k.length > 2);
        userCategories[name] = {type, keywords: [...new Set([name.toLowerCase(), ...keywords])]};
      }
    });
    return userCategories;
  },

  /**
   * Gets the primary account for a user.
   * @param {string} userId The user's ID.
   * @return {Promise<{id: string, data: any} | null>} The primary account and its ID, or null if none.
   */
  async getUserPrimaryAccount(userId: string) {
    const accountsSnapshot = await db.collection("users").doc(userId).collection("accounts").limit(1).get();
    if (accountsSnapshot.empty) {
      return null;
    }
    return {id: accountsSnapshot.docs[0].id, data: accountsSnapshot.docs[0].data()};
  },

  async getSpendingSummaryData(userId: string, startDate: Date, endDate: Date) {
    const expenseQuery = db
      .collection("users").doc(userId).collection("transactions")
      .where("type", "==", "expense")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(startDate))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(endDate));

    const expensesSnapshot = await expenseQuery.get();
    return expensesSnapshot.docs.map((doc) => doc.data());
  },

  async getTransactionsForDailyLimitSuggestion(userId: string) {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const thirtyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);

    const expensesSnapshot = await db
      .collection("users").doc(userId).collection("transactions")
      .where("type", "==", "expense")
      .where("date", ">=", thirtyDaysAgoTimestamp)
      .get();

    return expensesSnapshot.docs.map((doc) => doc.data());
  },

  async getUserNotificationSettings(userId: string) {
    const userDoc = await db.collection("users").doc(userId).get();
    return userDoc.data();
  },

  async updateGoal(userId: string, goalId: string, updateData: any) {
    return db.collection("users").doc(userId).collection("goals").doc(goalId).update(updateData);
  },

  async addDailyGoalLog(userId: string, goalId: string, date: string, logData: any) {
    return db.collection("users").doc(userId).collection("goals").doc(goalId).collection("daily_logs").doc(date).set(logData);
  },

  async getActiveGoals(userId: string) {
    const activeGoalsSnapshot = await db.collection("users").doc(userId).collection("goals").where("status", "==", "active").get();
    return activeGoalsSnapshot.docs.map((doc) => ({id: doc.id, data: doc.data()}));
  },

  async getAbandonedGoals(userId: string, cutoffTimestamp: admin.firestore.Timestamp) {
    return db.collection("users").doc(userId).collection("goals")
      .where("status", "==", "abandoned")
      .where("abandoned_at", "<=", cutoffTimestamp)
      .get();
  },

  async getUsers() {
    return db.collection("users").get();
  },

  async addBudget(userId: string, budgetData: any) {
    return db.collection("users").doc(userId).collection("budgets").add(budgetData);
  },

  async deleteTransaction(userId: string, transactionId: string) {
    return db.collection("users").doc(userId).collection("transactions").doc(transactionId).delete();
  },

  /**
   * Adds a new account for a user.
   * @param {string} userId The user's ID.
   * @param {any} accountData The account data (name, balance, currency).
   * @return {Promise<void>}
   */
  async addAccount(userId: string, accountData: any) {
    const {name, balance, currency} = accountData;

    // Optional: Check if an account with this name already exists for the user
    const existingAccountSnapshot = await db.collection("users").doc(userId).collection("accounts")
      .where("name", "==", name).limit(1).get();

    if (!existingAccountSnapshot.empty) {
      throw new Error(`Account with name '${name}' already exists.`);
    }

    await db.collection("users").doc(userId).collection("accounts").add({
      name,
      balance,
      currency,
    });
  },

  /**
   * Fetches recent transactions for a user from a given date.
   * @param {string} userId The user's ID.
   * @param {Date} fromDate The start date for fetching transactions.
   * @return {Promise<any[]>} An array of recent transaction data.
   */
  async getRecentTransactions(userId: string, fromDate: Date) {
    const fromTimestamp = admin.firestore.Timestamp.fromDate(fromDate);
    const transactionsSnapshot = await db.collection("users").doc(userId).collection("transactions")
      .where("date", ">=", fromTimestamp)
      .orderBy("date", "desc") // Order by date to get truly "recent"
      .limit(20) // Limit to a reasonable number for analysis
      .get();
    return transactionsSnapshot.docs.map((doc) => doc.data());
  },

  /**
   * Fetches active goals for a user.
   * @param {string} userId The user's ID.
   * @return {Promise<any[]>} An array of active goal data with IDs.
   */
  async getActiveGoalsForUser(userId: string) {
    const goalsSnapshot = await db.collection("users").doc(userId).collection("goals")
      .where("status", "==", "active")
      .get();
    return goalsSnapshot.docs.map((doc) => ({id: doc.id, data: doc.data()}));
  },

  /**
   * Fetches budgets for the current month for a user.
   * @param {string} userId The user's ID.
   * @return {Promise<any[]>} An array of current month's budget data with IDs.
   */
  async getCurrentMonthBudgets(userId: string) {
    const now = new Date();
    const budgetsSnapshot = await db.collection("users").doc(userId).collection("budgets")
      .where("month", "==", now.getMonth() + 1)
      .where("year", "==", now.getFullYear())
      .get();
    return budgetsSnapshot.docs.map((doc) => ({id: doc.id, data: doc.data()}));
  },

  async getUserTransactionsForTip(userId: string) {
    const transactionsSnapshot = await db.collection("users").doc(userId).collection("transactions")
      .orderBy("date", "desc")
      .limit(20) // Get recent transactions for analysis
      .get();
    return transactionsSnapshot.docs.map((doc) => doc.data());
  },

  async getUserBudgetsForTip(userId: string) {
    const now = new Date();
    const budgetsSnapshot = await db.collection("users").doc(userId).collection("budgets")
      .where("month", "==", now.getMonth() + 1)
      .where("year", "==", now.getFullYear())
      .get();
    return budgetsSnapshot.docs.map((doc) => doc.data());
  },

  async getUserGoalsForTip(userId: string) {
    const goalsSnapshot = await db.collection("users").doc(userId).collection("goals")
      .where("status", "==", "active")
      .get();
    return goalsSnapshot.docs.map((doc) => doc.data());
  },
};
