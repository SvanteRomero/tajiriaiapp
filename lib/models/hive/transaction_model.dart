import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class HiveTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String type;

  @HiveField(6)
  final String userId;

  @HiveField(7)
  bool isSynced;

  HiveTransaction({
    required this.id,
    required this.username,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.userId,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'description': description,
    'amount': amount,
    'date': date,
    'type': type,
    'userId': userId,
  };

  factory HiveTransaction.fromFirestore(Map<String, dynamic> data, String id, String userId) {
    return HiveTransaction(
      id: id,
      username: data['username'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as DateTime),
      type: data['type'] ?? 'expense',
      userId: userId,
      isSynced: true,
    );
  }
}
