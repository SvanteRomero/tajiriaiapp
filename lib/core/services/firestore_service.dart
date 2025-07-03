import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tajiri_ai/core/models/user_model.dart';
import 'package:tajiri_ai/core/models/account_model.dart';
import 'package:tajiri_ai/core/models/budget_model.dart';
import 'package:tajiri_ai/core/models/transaction_model.dart';
import 'package:tajiri_ai/core/models/goal_model.dart';
import 'package:tajiri_ai/core/models/user_category_model.dart';
import 'package:tajiri_ai/screens/details/goal_details_page.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches a real-time stream of the user's accounts.
  Stream<List<Account>> getAccounts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList());
  }

  /// Adds a new account to Firestore for the user.
  Future<void> addAccount(String userId, Account account) async {
    final accountsRef =
        _db.collection('users').doc(userId).collection('accounts');
    final querySnapshot =
        await accountsRef.where('name', isEqualTo: account.name).get();
    String finalName = account.name;
    if (querySnapshot.docs.isNotEmpty) {
      finalName = '${account.name} (${account.currency})';
    }
    final newAccount = Account(
      id: '',
      name: finalName,
      balance: account.balance,
      currency: account.currency,
    );
    await accountsRef.add(newAccount.toJson());
  }

  /// Updates an existing account in Firestore.
  Future<void> updateAccount(String userId, Account account) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(account.id)
        .update(account.toJson());
  }

  /// Deletes an account from Firestore.
  Future<void> deleteAccount(String userId, String accountId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  /// Adds a new income or expense transaction and updates the corresponding account balance.
  /// This supports offline caching and will sync when the connection is restored.
  Future<void> addTransaction(String userId, TransactionModel transaction) async {
    final batch = _db.batch();
    final transactionRef = _db.collection('users').doc(userId).collection('transactions').doc();
    final accountRef = _db.collection('users').doc(userId).collection('accounts').doc(transaction.accountId);

    final accountDoc = await accountRef.get(const GetOptions(source: Source.cache));
    if (accountDoc.exists) {
        final currentBalance = (accountDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
        final newBalance = transaction.type == TransactionType.income
            ? currentBalance + transaction.amount
            : currentBalance - transaction.amount;
        batch.update(accountRef, {'balance': newBalance});
    }

    batch.set(transactionRef, transaction.toJson());
    return batch.commit();
  }

  /// Adds a transfer transaction between two accounts.
  Future<void> addTransferTransaction(String userId, String fromAccountId,
      String toAccountId, double amount, String currency) async {
    final batch = _db.batch();

    final fromAccountRef = _db.collection('users').doc(userId).collection('accounts').doc(fromAccountId);
    final toAccountRef = _db.collection('users').doc(userId).collection('accounts').doc(toAccountId);
    final transactionRef = _db.collection('users').doc(userId).collection('transactions').doc();

    final fromAccountDoc = await fromAccountRef.get(const GetOptions(source: Source.cache));
    final toAccountDoc = await toAccountRef.get(const GetOptions(source: Source.cache));

    if (!fromAccountDoc.exists || !toAccountDoc.exists) {
      throw Exception("One or both accounts not found. Please ensure you are online to sync account data.");
    }

    final fromAccount = Account.fromFirestore(fromAccountDoc);
    final toAccount = Account.fromFirestore(toAccountDoc);

    if (fromAccount.currency != toAccount.currency) {
      throw Exception("Currency must be the same for transfers.");
    }

    batch.update(fromAccountRef, {'balance': fromAccount.balance - amount});
    batch.update(toAccountRef, {'balance': toAccount.balance + amount});

    final transferTransaction = TransactionModel(
      id: transactionRef.id,
      accountId: '',
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      description: 'Transfer',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.transfer,
      category: 'Transfer',
      currency: currency,
    );

    batch.set(transactionRef, transferTransaction.toJson());

    return batch.commit();
  }

  /// Updates an existing transaction and adjusts account balances accordingly.
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
      DocumentSnapshot oldAccountDoc =
          await firestoreTransaction.get(oldAccountRef);
      DocumentSnapshot newAccountDoc =
          await firestoreTransaction.get(newAccountRef);

      if (!oldAccountDoc.exists || !newAccountDoc.exists) {
        throw Exception("One or both accounts not found!");
      }

      double oldAccountBalance =
          (oldAccountDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
      double newAccountBalance =
          (newAccountDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;

      // Revert the old transaction amount
      if (oldTransaction.type == TransactionType.income) {
        oldAccountBalance -= oldTransaction.amount;
      } else {
        oldAccountBalance += oldTransaction.amount;
      }

      // Apply the new transaction amount
      if (newTransaction.type == TransactionType.income) {
        newAccountBalance += newTransaction.amount;
      } else {
        newAccountBalance -= newTransaction.amount;
      }

      firestoreTransaction.update(oldAccountRef, {'balance': oldAccountBalance});
      if (oldTransaction.accountId != newTransaction.accountId) {
        firestoreTransaction.update(newAccountRef, {'balance': newAccountBalance});
      }

      firestoreTransaction.update(transactionRef, newTransaction.toJson());
    });
  }

  /// Deletes a transaction and adjusts the account balance.
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
          (accountDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
      double newBalance;
      if (transaction.type == TransactionType.income) {
        newBalance = currentBalance - transaction.amount;
      } else {
        newBalance = currentBalance + transaction.amount;
      }
      firestoreTransaction.update(accountRef, {'balance': newBalance});
      firestoreTransaction.delete(transactionRef);
    });
  }

  /// Fetches a real-time stream of transactions, ordered by date.
  /// Includes metadata changes to provide instant UI updates for pending transactions.
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        // This is the key change: it tells Firestore to send an update
        // not just when data changes, but also when its sync status changes.
        .snapshots(includeMetadataChanges: true) 
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Fetches a real-time stream of all the user's goals.
  Stream<List<Goal>> getGoals(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList());
  }
  
  /// Adds a new goal to Firestore.
  Future<void> addGoal(String userId, Goal goal) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .add(goal.toJson());
  }

  /// Updates an existing goal in Firestore.
  Future<void> updateGoal(String userId, Goal goal) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goal.id)
        .update(goal.toJson());
  }

  /// Deletes a goal from Firestore.
  Future<void> deleteGoal(String userId, String goalId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  /// Fetches the daily logs for a specific goal.
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

  /// Adds a new custom category for the user.
  Future<void> addUserCategory(String userId, UserCategory category) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(category.toJson());
  }

  /// Fetches a stream of the user's custom categories, optionally filtered by type.
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

  /// Updates an existing user category.
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

  /// Deletes a user category.
  Future<void> deleteUserCategory(String userId, String categoryId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  /// Fetches a stream of budgets for the current month.
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

  /// Adds a new budget to Firestore.
  Future<void> addBudget(String userId, Budget budget) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .add(budget.toJson());
  }

  /// Updates an existing budget.
  Future<void> updateBudget(String userId, Budget budget) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toJson());
  }

  /// Deletes a budget.
  Future<void> deleteBudget(String userId, String budgetId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  /// Updates a user's notification settings in their main document.
  Future<void> updateUserNotificationSettings(
      String userId, Map<String, dynamic> settings) {
    return _db.collection('users').doc(userId).set(
          settings,
          SetOptions(merge: true),
        );
  }

  /// Fetches a stream of the user's main document data.
  Stream<UserModel> getUser(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

  /// Fetches a single goal by its ID.
  Future<Goal?> getGoalById(String userId, String goalId) async {
    try {
      final doc =
          await _db.collection('users').doc(userId).collection('goals').doc(goalId).get();
      if (doc.exists) {
        return Goal.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Error fetching goal by ID: $e");
      return null;
    }
  }
}