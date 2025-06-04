/// Defines the types of transactions available in the application
/// - [income]: Represents money received
/// - [expense]: Represents money spent
enum TransactionType { income, expense }

/// Transaction represents a financial transaction in the Tajiri AI application
/// Records both income and expenses with associated metadata
class Transaction {
  /// Username of the transaction owner
  final String username;

  /// Description of the transaction
  /// Provides context about the income or expense
  final String description;

  /// Amount of money involved in the transaction
  /// Stored as a double to handle decimal values
  final double amount;

  /// Date and time when the transaction occurred
  final DateTime date;

  /// Type of transaction (income or expense)
  /// Used for categorization and calculations
  final TransactionType type;

  /// Main category of the transaction (e.g., "Housing", "Transportation")
  final String mainCategory;

  /// Subcategory of the transaction (e.g., "Rent", "Fuel")
  final String subCategory;

  /// Creates a new Transaction instance
  /// 
  /// Required parameters:
  /// - [username]: Owner of the transaction
  /// - [description]: Purpose or context of the transaction
  /// - [amount]: Monetary value
  /// - [date]: When the transaction occurred
  /// - [type]: Whether it's an income or expense
  /// - [mainCategory]: Primary category of the transaction
  /// - [subCategory]: Secondary category of the transaction
  Transaction({
    required this.username,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.mainCategory,
    required this.subCategory,
  });

  /// Creates a Transaction from a Firestore document
  factory Transaction.fromFirestore(Map<String, dynamic> data) {
    return Transaction(
      username: data['username'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as DateTime),
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      mainCategory: data['mainCategory'] ?? 'Other',
      subCategory: data['subCategory'] ?? 'Miscellaneous',
    );
  }

  /// Converts the Transaction to a Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'description': description,
      'amount': amount,
      'date': date,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'mainCategory': mainCategory,
      'subCategory': subCategory,
    };
  }
}
