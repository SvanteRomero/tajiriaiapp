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

  TransactionModel({
    this.id,
    required this.accountId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.currency,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
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