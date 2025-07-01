// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '/core/models/account_model.dart';
import '/core/models/budget_model.dart';
import '/core/models/transaction_model.dart';
import '/core/models/goal_model.dart';
import '/core/models/user_category_model.dart';
import '../../screens/details/goal_details_page.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (getAccounts, addAccount, updateAccount, deleteAccount methods are unchanged)

  Stream<List<Account>> getAccounts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList());
  }

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

  Future<void> updateAccount(String userId, Account account) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(account.id)
        .update(account.toJson());
  }

  Future<void> deleteAccount(String userId, String accountId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }
  
  // Method for standard income/expense transactions (already supports offline)
  Future<void> addTransaction(String userId, TransactionModel transaction) async {
    final batch = _db.batch();
    final transactionRef = _db.collection('users').doc(userId).collection('transactions').doc();
    final accountRef = _db.collection('users').doc(userId).collection('accounts').doc(transaction.accountId);
    
    // This part requires a read, which can be tricky offline, but Firestore handles caching.
    // The write itself is added to the batch and will execute when online.
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

  // CORRECTED: Method to handle transfers with offline support
  Future<void> addTransferTransaction(String userId, String fromAccountId,
      String toAccountId, double amount, String currency) async {
    final batch = _db.batch();

    final fromAccountRef = _db.collection('users').doc(userId).collection('accounts').doc(fromAccountId);
    final toAccountRef = _db.collection('users').doc(userId).collection('accounts').doc(toAccountId);
    final transactionRef = _db.collection('users').doc(userId).collection('transactions').doc();

    // Perform reads from the cache first to ensure offline capability
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

    // Prepare updates for the batch
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

    // Commit the batched write. This will be queued offline and execute upon connection.
    return batch.commit();
  }

  // ... (updateTransaction, deleteTransaction, getTransactions, and all other methods are unchanged)
  
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
          (oldAccountDoc.data() as Map<String, dynamic>)['balance']
                  ?.toDouble() ??
              0.0;
      double newAccountBalance =
          (newAccountDoc.data() as Map<String, dynamic>)['balance']
                  ?.toDouble() ??
              0.0;

      if (oldTransaction.type == TransactionType.income) {
        oldAccountBalance -= oldTransaction.amount;
      } else {
        oldAccountBalance += oldTransaction.amount;
      }

      if (newTransaction.type == TransactionType.income) {
        newAccountBalance += newTransaction.amount;
      } else {
        newAccountBalance -= newTransaction.amount;
      }

      firestoreTransaction.update(oldAccountRef, {'balance': oldAccountBalance});
      if (oldTransaction.accountId != newTransaction.accountId) {
        firestoreTransaction
            .update(newAccountRef, {'balance': newAccountBalance});
      }

      firestoreTransaction.update(transactionRef, newTransaction.toJson());
    });
  }

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
      if (transaction.type == TransactionType.income) {
        newBalance = currentBalance - transaction.amount;
      } else {
        newBalance = currentBalance + transaction.amount;
      }
      firestoreTransaction.update(accountRef, {'balance': newBalance});
      firestoreTransaction.delete(transactionRef);
    });
  }

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

  Stream<List<Goal>> getGoals(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList());
  }

  Future<void> addGoal(String userId, Goal goal) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .add(goal.toJson());
  }

  Future<void> updateGoal(String userId, Goal goal) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goal.id)
        .update(goal.toJson());
  }

  Future<void> deleteGoal(String userId, String goalId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

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

  Future<void> addUserCategory(String userId, UserCategory category) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(category.toJson());
  }

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

  Future<void> deleteUserCategory(String userId, String categoryId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

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

  Future<void> addBudget(String userId, Budget budget) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .add(budget.toJson());
  }

  Future<void> updateBudget(String userId, Budget budget) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toJson());
  }

  Future<void> deleteBudget(String userId, String budgetId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  Future<void> updateUserNotificationSettings(
      String userId, Map<String, dynamic> settings) {
    return _db.collection('users').doc(userId).set(
          settings,
          SetOptions(merge: true),
        );
  }

  Stream<UserModel> getUser(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

}