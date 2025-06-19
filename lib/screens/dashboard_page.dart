import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/models/transaction_model.dart';

class DashboardPage extends StatefulWidget {
  final User user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        final transactions = snapshot.data!.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
        double totalIncome = transactions.where((t) => t.type == TransactionType.income).fold(0, (sum, item) => sum + item.amount);
        double totalExpense = transactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, item) => sum + item.amount);
        double balance = totalIncome - totalExpense;

        return Column(
          children: [
            _buildBalanceCard(balance, totalIncome, totalExpense),
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
                  return _buildTransactionTile(transactions[index]);
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
          Text("Current Balance", style: GoogleFonts.poppins(color: Colors.white70)),
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
      ),
    );
  }
}