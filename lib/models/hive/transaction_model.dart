import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @HiveField(8)
  final String mainCategory;

  @HiveField(9)
  final String subCategory;

  static const List<String> validTypes = ['income', 'expense'];
  static final RegExp idPattern = RegExp(r'^[a-zA-Z0-9-_]+$');

  HiveTransaction._internal({
    required this.id,
    required this.username,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.userId,
    required this.mainCategory,
    required this.subCategory,
    this.isSynced = false,
  }) {
    _validate();
  }

  factory HiveTransaction({
    required String id,
    required String username,
    required String description,
    required double amount,
    required DateTime date,
    required String type,
    required String userId,
    required String mainCategory,
    required String subCategory,
    bool isSynced = false,
  }) {
    // Sanitize inputs
    final sanitizedDescription = description.trim();
    final sanitizedType = type.toLowerCase().trim();
    final sanitizedCategory = mainCategory.trim();
    final sanitizedSubCategory = subCategory.trim();

    return HiveTransaction._internal(
      id: id,
      username: username,
      description: sanitizedDescription,
      amount: amount,
      date: date,
      type: sanitizedType,
      userId: userId,
      mainCategory: sanitizedCategory,
      subCategory: sanitizedSubCategory,
      isSynced: isSynced,
    );
  }

  void _validate() {
    if (id.isEmpty || !idPattern.hasMatch(id)) {
      throw ArgumentError('Invalid transaction ID format');
    }
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    if (amount.isNaN || amount.isInfinite) {
      throw ArgumentError('Invalid amount value');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
    if (description.isEmpty) {
      throw ArgumentError('Description cannot be empty');
    }
    if (!validTypes.contains(type)) {
      throw ArgumentError('Invalid transaction type: $type');
    }
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      throw ArgumentError('Transaction date cannot be in the future');
    }
    if (mainCategory.isEmpty) {
      throw ArgumentError('Main category cannot be empty');
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'username': username,
        'description': description,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'type': type,
        'userId': userId,
        'mainCategory': mainCategory,
        'subCategory': subCategory,
      };
    } catch (e) {
      throw FormatException('Failed to convert transaction to JSON: $e');
    }
  }

  factory HiveTransaction.fromFirestore(Map<String, dynamic> data, String id, String userId) {
    try {
      // Validate required fields
      final requiredFields = ['amount', 'date', 'type'];
      for (final field in requiredFields) {
        if (!data.containsKey(field)) {
          throw FormatException('Missing required field: $field');
        }
      }

      final amount = data['amount'];
      final date = data['date'];
      
      if (amount == null) throw FormatException('Amount is required');
      if (date == null) throw FormatException('Date is required');

      // Convert amount to double
      final double parsedAmount;
      if (amount is int) {
        parsedAmount = amount.toDouble();
      } else if (amount is double) {
        parsedAmount = amount;
      } else {
        throw FormatException('Invalid amount type: ${amount.runtimeType}');
      }

      // Convert date to DateTime
      final DateTime parsedDate;
      if (date is Timestamp) {
        parsedDate = date.toDate();
      } else if (date is DateTime) {
        parsedDate = date;
      } else {
        throw FormatException('Invalid date type: ${date.runtimeType}');
      }

      return HiveTransaction(
        id: id,
        username: data['username'] as String? ?? '',
        description: data['description'] as String? ?? '',
        amount: parsedAmount,
        date: parsedDate,
        type: (data['type'] as String?)?.toLowerCase() ?? 'expense',
        userId: userId,
        mainCategory: data['mainCategory'] as String? ?? 'Other',
        subCategory: data['subCategory'] as String? ?? 'Miscellaneous',
        isSynced: true,
      );
    } catch (e) {
      throw FormatException('Error creating transaction from Firestore: $e');
    }
  }

  @override
  String toString() => 'Transaction(id: $id, amount: $amount, type: $type, '
      'category: $mainCategory, date: $date)';

  HiveTransaction copyWith({
    String? id,
    String? username,
    String? description,
    double? amount,
    DateTime? date,
    String? type,
    String? userId,
    String? mainCategory,
    String? subCategory,
    bool? isSynced,
  }) {
    return HiveTransaction(
      id: id ?? this.id,
      username: username ?? this.username,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
