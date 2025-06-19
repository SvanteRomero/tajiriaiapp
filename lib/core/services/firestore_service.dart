import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tajiri_ai/core/models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // Example method to add a transaction
  Future<void> addTransaction(String userId, TransactionModel transaction) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add(transaction.toJson());
  }

  // Add more methods for goals, user profiles, etc. as needed
}