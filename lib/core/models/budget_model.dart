// lib/core/models/budget_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String? id;
  final String category;
  final double amount;
  final int month;
  final int year;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      category: data['category'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      month: (data['month'] as num?)?.toInt() ?? 0,
      year: (data['year'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }
}