import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Ensure Firebase is initialized (it's often done in the main index.ts,
// but it's safe to ensure it's initialized here as well if this is a separate entry point).
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * [ADMIN] Gathers and computes key metrics for the admin analytics dashboard.
 *
 * This function calculates:
 * - Total number of users.
 * - New signups in the last 30 days.
 * - A leaderboard of top users based on a scoring metric (e.g., goals completed).
 *
 * Can only be called by an authenticated user with an `admin` custom claim.
 */
export const getAnalyticsData = onCall(async (request) => {
  // 1. Authorization Check: Ensure the caller is an admin.
  if (request.auth?.token.admin !== true) {
    throw new HttpsError(
      "permission-denied",
      "This function can only be called by an administrator."
    );
  }

  try {
    // --- Metric 1: Core User Counts ---
    const usersSnapshot = await db.collection("users").get();
    const totalUsers = usersSnapshot.size;
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    let newSignups = 0;
    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      // Ensure createdAt exists and is a Timestamp before converting
      if (userData.createdAt && userData.createdAt.toDate) {
        if (userData.createdAt.toDate() > thirtyDaysAgo) {
          newSignups++;
        }
      }
    });


    // --- Metric 2: User Leaderboard (Example based on 'goalsCompleted') ---
    // This query assumes you have a 'goalsCompleted' field in your user documents.
    // You can adjust the field and ordering as needed.
    const leaderboardSnapshot = await db.collection("users")
      .orderBy("goalsCompleted", "desc")
      .limit(5)
      .get();

    const leaderboard = leaderboardSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        uid: doc.id,
        name: data.displayName || "Unnamed User",
        email: data.email,
        // Provide default values if fields might be missing
        goalsCompleted: data.goalsCompleted || 0,
        transactions: data.transactionsCount || 0, // Example field
        savingsRate: data.savingsRate || 0, // Example field
      };
    });

    // --- You can add more metric calculations here as your app grows ---
    // For example, calculating platform usage or goal completion rates
    // would require querying additional collections or fields.


    // 3. Return all computed data in a single object
    return {
      totalUsers,
      newSignups,
      leaderboard,
      // Add other metrics here
      // For example:
      // platformUsage: { android: 68, ios: 25, web: 7 }, // Dummy data for now
      // goalCompletionRate: { completed: 55, inProgress: 35, abandoned: 10 } // Dummy data
    };
  } catch (error) {
    console.error("Error fetching analytics data:", error);
    throw new HttpsError(
      "internal",
      "An unexpected error occurred while fetching analytics data."
    );
  }
});
