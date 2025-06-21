import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String? id;
  final String accountId; // Add this line
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;

  TransactionModel({
    this.id,
    required this.accountId, // Add this line
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      accountId: data['accountId'] ?? '', // Add this line
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: data['category'] ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId, // Add this line
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type.name, // 'income' or 'expense'
      'category': category,
    };
  }
}