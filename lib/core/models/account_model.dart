import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final String id;
  final String name;
  final double balance;
  final String currency;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
  });

  factory Account.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Account(
      id: doc.id,
      name: data['name'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'balance': balance,
      'currency': currency,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Account &&
      other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}