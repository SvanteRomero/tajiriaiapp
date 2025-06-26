// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tajiri_ai/core/models/account_model.dart';
import 'package:tajiri_ai/core/models/budget_model.dart';
import 'package:tajiri_ai/core/models/transaction_model.dart';
import 'package:tajiri_ai/core/models/goal_model.dart';
import 'package:tajiri_ai/core/models/user_category_model.dart'; // NEW: Import UserCategory
import 'package:tajiri_ai/screens/goal_details_page.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to fetch accounts for a user
  Stream<List<Account>> getAccounts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList());
  }

  // Method to add a new account
  Future<void> addAccount(String userId, Account account) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .add(account.toJson());
  }

  // NEW: Method to update an existing account
  Future<void> updateAccount(String userId, Account account) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(account.id)
        .update(account.toJson());
  }

  // NEW: Method to delete an account
  Future<void> deleteAccount(String userId, String accountId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  // Method to add a transaction and update account balance atomically
  Future<void> addTransaction(String userId, TransactionModel transaction) {
    final transactionRef = _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc();
    final accountRef = _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(transaction.accountId);

    return _db.runTransaction((firestoreTransaction) async {
      // Get the account document
      DocumentSnapshot accountDoc = await firestoreTransaction.get(accountRef);
      if (!accountDoc.exists) {
        throw Exception("Account not found!");
      }

      // Calculate the new balance
      double currentBalance =
          (accountDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ??
              0.0;
      double newBalance = transaction.type == TransactionType.income
          ? currentBalance + transaction.amount
          : currentBalance - transaction.amount;

      // Update the account balance
      firestoreTransaction.update(accountRef, {'balance': newBalance});

      // Add the new transaction
      firestoreTransaction.set(transactionRef, transaction.toJson());
    });
  }

  // NEW: Method to update a transaction and atomically adjust account balance
  Future<void> updateTransaction(String userId,
      TransactionModel oldTransaction, TransactionModel newTransaction) {
    final transactionRef = _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(newTransaction.id);
    final oldAccountRef = _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(oldTransaction.accountId);
    final newAccountRef = _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(newTransaction.accountId);

    return _db.runTransaction((firestoreTransaction) async {
      // 1. Get old and new account documents
      DocumentSnapshot oldAccountDoc =
          await firestoreTransaction.get(oldAccountRef);
      DocumentSnapshot newAccountDoc =
          await firestoreTransaction.get(newAccountRef);

      if (!oldAccountDoc.exists || !newAccountDoc.exists) {
        throw Exception("One or both accounts not found!");
      }

      double oldAccountBalance =
          (oldAccountDoc.data() as Map<String, dynamic>)['balance']
                  ?.toDouble() ??
              0.0;
      double newAccountBalance =
          (newAccountDoc.data() as Map<String, dynamic>)['balance']
                  ?.toDouble() ??
              0.0;

      // 2. Reverse the old transaction's impact on its account
      if (oldTransaction.type == TransactionType.income) {
        oldAccountBalance -= oldTransaction.amount;
      } else {
        oldAccountBalance += oldTransaction.amount;
      }

      // 3. Apply the new transaction's impact to its account
      if (newTransaction.type == TransactionType.income) {
        newAccountBalance += newTransaction.amount;
      } else {
        newAccountBalance -= newTransaction.amount;
      }

      // 4. Update account balances
      firestoreTransaction.update(oldAccountRef, {'balance': oldAccountBalance});
      // Only update newAccountRef if it's different from oldAccountRef
      if (oldTransaction.accountId != newTransaction.accountId) {
        firestoreTransaction.update(
            newAccountRef, {'balance': newAccountBalance});
      }

      // 5. Update the transaction document
      firestoreTransaction.update(transactionRef, newTransaction.toJson());
    });
  }

  // NEW: Method to delete a transaction and atomically reverse its impact on account balance
  Future<void> deleteTransaction(String userId, TransactionModel transaction) {
    final transactionRef = _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id);
    final accountRef = _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(transaction.accountId);

    return _db.runTransaction((firestoreTransaction) async {
      DocumentSnapshot accountDoc = await firestoreTransaction.get(accountRef);
      if (!accountDoc.exists) {
        throw Exception("Account not found!");
      }

      double currentBalance =
          (accountDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ??
              0.0;
      double newBalance;

      // Reverse the transaction's impact
      if (transaction.type == TransactionType.income) {
        newBalance = currentBalance - transaction.amount;
      } else {
        newBalance = currentBalance + transaction.amount;
      }

      // Update account balance
      firestoreTransaction.update(accountRef, {'balance': newBalance});

      // Delete the transaction
      firestoreTransaction.delete(transactionRef);
    });
  }

  // Example method to fetch transactions for a user
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  // --- GOAL RELATED METHODS ---

  // Method to fetch goals for a user
  Stream<List<Goal>> getGoals(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList());
  }

  // Method to add a new goal
  Future<void> addGoal(String userId, Goal goal) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .add(goal.toJson());
  }

  // NEW: Method to update an existing goal
  Future<void> updateGoal(String userId, Goal goal) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goal.id)
        .update(goal.toJson());
  }

  // NEW: Method to delete a goal
  Future<void> deleteGoal(String userId, String goalId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  // Method to fetch daily logs for a specific goal
  Stream<List<DailyLog>> getDailyLogs(String userId, String goalId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .collection('daily_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyLog.fromFirestore(doc.data()))
            .toList());
  }

  // NEW: Category Management Methods

  // Method to add a new user-defined category
  Future<void> addUserCategory(String userId, UserCategory category) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(category.toJson());
  }

  // Method to fetch user-defined categories
  Stream<List<UserCategory>> getUserCategories(String userId,
      {TransactionType? type}) {
    Query query = _db.collection('users').doc(userId).collection('categories');

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserCategory.fromFirestore(doc))
        .toList());
  }

  // Method to update an existing user-defined category
  Future<void> updateUserCategory(String userId, UserCategory category) {
    if (category.id == null) {
      throw Exception("Category ID is required for updating.");
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .update(category.toJson());
  }

  // Method to delete a user-defined category
  Future<void> deleteUserCategory(String userId, String categoryId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // --- BUDGET RELATED METHODS ---

  // Method to fetch budgets for the current month
  Stream<List<Budget>> getBudgets(String userId) {
    final now = DateTime.now();
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .where('month', isEqualTo: now.month)
        .where('year', isEqualTo: now.year)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList());
  }

  // Method to add a new budget
  Future<void> addBudget(String userId, Budget budget) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .add(budget.toJson());
  }

  // Method to update an existing budget
  Future<void> updateBudget(String userId, Budget budget) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toJson());
  }

  // Method to delete a budget
  Future<void> deleteBudget(String userId, String budgetId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }
}