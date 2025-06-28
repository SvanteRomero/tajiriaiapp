// lib/core/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String? id;
  final String accountId;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String currency;
  final bool isPending; // This flag will be true if the transaction hasn't been synced

  TransactionModel({
    this.id,
    required this.accountId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.currency,
    this.isPending = false, // Default to false
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      accountId: data['accountId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] == 'income'
          ? TransactionType.income
          : data['type'] == 'expense'
              ? TransactionType.expense
              : TransactionType.transfer,
      category: data['category'] ?? 'Other',
      currency: data['currency'] ?? 'USD',
      // This is the key part: Firestore's metadata tells us if there are pending writes.
      isPending: doc.metadata.hasPendingWrites,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'category': category,
      'currency': currency,
    };
  }
}