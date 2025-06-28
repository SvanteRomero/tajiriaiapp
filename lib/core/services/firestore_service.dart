// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/models/account_model.dart';
import '/core/models/budget_model.dart';
import '/core/models/transaction_model.dart';
import '/core/models/goal_model.dart';
import '/core/models/user_category_model.dart';
import '/screens/goal_details_page.dart';

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

  // UPDATED: Method to add a new account with currency and unique name check
  Future<void> addAccount(String userId, Account account) async {
    final accountsRef =
        _db.collection('users').doc(userId).collection('accounts');

    // Check if an account with the same name exists
    final querySnapshot =
        await accountsRef.where('name', isEqualTo: account.name).get();

    String finalName = account.name;
    // If docs with the same name are found, append the currency code
    if (querySnapshot.docs.isNotEmpty) {
      finalName = '${account.name} (${account.currency})';
    }

    final newAccount = Account(
      id: '', // Firestore will generate this
      name: finalName,
      balance: account.balance,
      currency: account.currency,
    );

    await accountsRef.add(newAccount.toJson());
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

  // UPDATED: Method to add a transaction and update account balance atomically
  Future<void> addTransaction(String userId, TransactionModel transaction) async {
    final batch = _db.batch();

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

    // We can't use a transaction for offline support, so we'll do a batched write.
    // This is not as safe as a transaction, but it will work offline.
    final accountDoc = await accountRef.get();
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


  // UPDATED: Method to handle transfers between accounts of the same currency
  Future<void> addTransferTransaction(String userId, String fromAccountId,
      String toAccountId, double amount, String description) async {
    final batch = _db.batch();
    final fromAccountRef = _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(fromAccountId);
    final toAccountRef = _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(toAccountId);
    final debitTransactionRef =
        _db.collection('users').doc(userId).collection('transactions').doc();
    final creditTransactionRef =
        _db.collection('users').doc(userId).collection('transactions').doc();

    final fromAccountDoc = await fromAccountRef.get();
    final toAccountDoc = await toAccountRef.get();

    if (!fromAccountDoc.exists || !toAccountDoc.exists) {
      throw Exception("One or both accounts not found!");
    }

    final fromAccount = Account.fromFirestore(fromAccountDoc);
    final toAccount = Account.fromFirestore(toAccountDoc);

    if (fromAccount.currency != toAccount.currency) {
      throw Exception("Currency must be the same for transfers.");
    }

    // Update balances
    batch.update(fromAccountRef, {'balance': fromAccount.balance - amount});
    batch.update(toAccountRef, {'balance': toAccount.balance + amount});

    // Create transactions
    final debitTransaction = TransactionModel(
      id: debitTransactionRef.id,
      accountId: fromAccountId,
      description: 'Transfer to ${toAccount.name}: $description',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.expense, // Representing money leaving the account
      category: 'Transfer',
      currency: fromAccount.currency,
    );

    final creditTransaction = TransactionModel(
      id: creditTransactionRef.id,
      accountId: toAccountId,
      description: 'Transfer from ${fromAccount.name}: $description',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.income, // Representing money entering the account
      category: 'Transfer',
      currency: toAccount.currency,
    );

    batch.set(debitTransactionRef, debitTransaction.toJson());
    batch.set(creditTransactionRef, creditTransaction.toJson());

    return batch.commit();
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
        firestoreTransaction
            .update(newAccountRef, {'balance': newAccountBalance});
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