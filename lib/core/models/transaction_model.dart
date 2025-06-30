// lib/core/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String? id;
  final String accountId; // Still used for income/expense
  final String? fromAccountId; // Specifically for transfers
  final String? toAccountId;   // Specifically for transfers
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String currency;
  final bool isPending;

  TransactionModel({
    this.id,
    required this.accountId,
    this.fromAccountId,
    this.toAccountId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.currency,
    this.isPending = false,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      accountId: data['accountId'] ?? '',
      fromAccountId: data['fromAccountId'], // New field
      toAccountId: data['toAccountId'],   // New field
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: _stringToTransactionType(data['type']),
      category: data['category'] ?? 'Other',
      currency: data['currency'] ?? 'USD',
      isPending: doc.metadata.hasPendingWrites,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'fromAccountId': fromAccountId, // New field
      'toAccountId': toAccountId,     // New field
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'category': category,
      'currency': currency,
    };
  }

  static TransactionType _stringToTransactionType(String? type) {
    switch (type) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        // Default to expense for any unknown types to be safe.
        return TransactionType.expense;
    }
  }
}