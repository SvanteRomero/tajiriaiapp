// Transaction type enum
enum TransactionType { income, expense }

// Transaction model
class Transaction {
  final String username;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.username,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });
}
Transaction transaction = new Transaction(username: "user1", description: "Salary", amount: 5000, date: DateTime.now(), type: TransactionType.income);
final List<Transaction> transactions = [transaction];