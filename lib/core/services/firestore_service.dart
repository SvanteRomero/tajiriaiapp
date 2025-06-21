import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tajiri_ai/core/models/account_model.dart';
import 'package:tajiri_ai/core/models/transaction_model.dart';

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
      double currentBalance = (accountDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
      double newBalance = transaction.type == TransactionType.income
          ? currentBalance + transaction.amount
          : currentBalance - transaction.amount;
      
      // Update the account balance
      firestoreTransaction.update(accountRef, {'balance': newBalance});

      // Add the new transaction
      firestoreTransaction.set(transactionRef, transaction.toJson());
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
}