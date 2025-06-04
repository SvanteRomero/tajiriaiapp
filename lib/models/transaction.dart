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

  /// Creates a new Transaction instance
  /// 
  /// Required parameters:
  /// - [username]: Owner of the transaction
  /// - [description]: Purpose or context of the transaction
  /// - [amount]: Monetary value
  /// - [date]: When the transaction occurred
  /// - [type]: Whether it's an income or expense
  Transaction({
    required this.username,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });
}

// Example transaction for testing purposes
/// Sample transaction representing a salary payment
Transaction transaction = Transaction(
  username: "user1",
  description: "Salary",
  amount: 5000,
  date: DateTime.now(),
  type: TransactionType.income
);

/// List of transactions for testing and development
final List<Transaction> transactions = [transaction];
