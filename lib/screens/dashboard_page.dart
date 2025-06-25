// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tajiri_ai/core/models/account_model.dart';
import '../core/models/transaction_model.dart';
import '../core/services/firestore_service.dart';
import '../core/utils/snackbar_utils.dart'; // Import snackbar_utils for user feedback
import 'edit_transaction_page.dart'; // Import the new EditTransactionPage

class DashboardPage extends StatefulWidget {
  final User user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();

  // Function to show delete confirmation and perform delete
  Future<bool> _confirmAndDeleteTransaction(TransactionModel transaction) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: Text("Are you sure you want to delete '${transaction.description}'? This will adjust your account balance."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteTransaction(widget.user.uid, transaction);
        if (mounted) {
          showCustomSnackbar(context, 'Transaction deleted!');
        }
        return true; // Indicate that the item was successfully dismissed/deleted
      } catch (e) {
        if (mounted) {
          showCustomSnackbar(context, 'Failed to delete transaction. Please try again.', type: SnackbarType.error);
        }
        return false; // Indicate that deletion failed
      }
    }
    return false; // User cancelled dismissal
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: CombineLatestStream.combine2(
        _firestoreService.getTransactions(widget.user.uid),
        _firestoreService.getAccounts(widget.user.uid),
        (List<TransactionModel> transactions, List<Account> accounts) => {'transactions': transactions, 'accounts': accounts},
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("No data available."));
        }

        final transactions = snapshot.data!['transactions'] as List<TransactionModel>;
        final accounts = snapshot.data!['accounts'] as List<Account>;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("No transactions yet", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text("Tap the '+' button to add your first one!", style: GoogleFonts.poppins(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        double totalBalance = accounts.fold(0.0, (sum, item) => sum + item.balance);
        double totalIncome = transactions.where((t) => t.type == TransactionType.income).fold(0, (sum, item) => sum + item.amount);
        double totalExpense = transactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, item) => sum + item.amount);

        return Column(
          children: [
            _buildBalanceCard(totalBalance, totalIncome, totalExpense),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent Transactions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  // Wrap with Dismissible for swipe-to-delete
                  return Dismissible(
                    key: ValueKey(transaction.id), // Unique key for Dismissible
                    direction: DismissDirection.endToStart, // Swipe from right to left
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) => _confirmAndDeleteTransaction(transaction), // Show confirmation dialog
                    onDismissed: (direction) {
                      // No need to show snackbar here as it's already shown in _confirmAndDeleteTransaction
                    },
                    child: _buildTransactionTile(transaction),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade500, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Balance", style: GoogleFonts.poppins(color: Colors.white70)),
          Text(
            NumberFormat.currency(symbol: '\$').format(balance),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseRow(Icons.arrow_upward, "Income", income, Colors.greenAccent),
              _buildIncomeExpenseRow(Icons.arrow_downward, "Expense", expense, Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(IconData icon, String label, double amount, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            Text(
              NumberFormat.currency(symbol: '\$').format(amount),
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red.shade400 : Colors.green.shade400;
    final sign = isExpense ? '-' : '+';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: color),
        ),
        title: Text(transaction.description, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
        trailing: Text(
          "$sign ${NumberFormat.currency(symbol: '\$').format(transaction.amount)}",
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        // Make ListTile tappable for editing
        onTap: () async {
          final bool? result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditTransactionPage(user: widget.user, transaction: transaction),
            ),
          );
          // No explicit refresh needed as StreamBuilder will handle it upon data changes
        },
      ),
    );
  }
}