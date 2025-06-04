/// Defines the core data structures for financial transactions in the application.
/// This includes both the transaction type enumeration and the transaction model class.

/// Represents the type of financial transaction.
/// 
/// [income] represents money received (e.g., salary, allowance)
/// [expense] represents money spent (e.g., food, transport)
enum TransactionType { income, expense }

/// A data model representing a financial transaction.
/// 
/// This model is used throughout the application to track and manage
/// user financial transactions. It includes essential information about
/// each transaction such as who made it, what it was for, and its value.
class Transaction {
  /// Username of the person who made the transaction
  final String username;

  /// Description or purpose of the transaction
  final String description;

  /// Amount of money involved in the transaction
  final double amount;

  /// Date and time when the transaction occurred
  final DateTime date;

  /// Type of transaction (income or expense)
  final TransactionType type;

  /// Creates a new Transaction instance.
  /// 
  /// All fields are required to ensure complete transaction records:
  /// - [username]: identifies who made the transaction
  /// - [description]: explains what the transaction was for
  /// - [amount]: specifies how much money was involved
  /// - [date]: records when the transaction occurred
  /// - [type]: indicates whether it was an income or expense
  Transaction({
    required this.username,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  /// Creates a Transaction from a Firestore document map.
  factory Transaction.fromMap(Map<String, dynamic> data) {
    return Transaction(
      username: data['username'] as String,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: DateTime.parse(data['date'] as String),
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }

  /// Converts a Transaction into a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type == TransactionType.income ? 'income' : 'expense',
    };
  }
}

// Example transaction for testing purposes
Transaction transaction = Transaction(
  username: "user1",
  description: "Salary",
  amount: 5000,
  date: DateTime.now(),
  type: TransactionType.income,
);

// Example transaction list for testing purposes
final List<Transaction> transactions = [transaction];
