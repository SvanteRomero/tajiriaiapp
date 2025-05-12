import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as my_model;
import 'package:tajiri_ai/components/empty_page.dart';

class Home extends StatefulWidget {
  final User user;
  const Home({Key? key, required this.user}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isLoading = true;
  List<my_model.Transaction> _transactions = [];
  List<String> _transactionIds = [];
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchTransactions();
  }

  Future<void> _fetchUserName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('name')) {
          setState(() {
            _displayName = data['name'] as String;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTransactions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
      final docs = snapshot.docs;
      final transactions = docs.map((doc) {
        final data = doc.data();
        final type = (data['type'] as String) == 'income'
            ? my_model.TransactionType.income
            : my_model.TransactionType.expense;
        return my_model.Transaction(
          username: data['username'] as String,
          description: data['description'] as String,
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          type: type,
        );
      }).toList();
      setState(() {
        _transactions = transactions;
        _transactionIds = docs.map((doc) => doc.id).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalIncome => _transactions
      .where((tx) => tx.type == my_model.TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get _totalExpense => _transactions
      .where((tx) => tx.type == my_model.TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get _currentBalance => _totalIncome - _totalExpense;

  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0).format(amount);

  Widget _buildEmptyState() => EmptyPage(
    pageIconData: Icons.add_box_outlined,
    pageTitle: 'No Transactions Yet',
    pageDescription: "Tap '+' to add your first transaction",
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : (_transactions.isEmpty
        ? _buildEmptyState()
        : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF1976D2),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${_displayName.isNotEmpty ? _displayName : 'User'}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 32, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Current Balance',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatCurrency(_currentBalance),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        onPressed: _showAddTypeDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Income'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        onPressed: _showAddTypeDialog,
                        icon: const Icon(Icons.remove),
                        label: const Text('Add Expense'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Recent Transactions',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_transactions.length, (i) {
          final tx = _transactions[i];
          return ListTile(
            leading: Icon(
              tx.type == my_model.TransactionType.income
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: tx.type == my_model.TransactionType.income
                  ? Colors.green
                  : Colors.red,
            ),
            title: Text(tx.description),
            subtitle: Text(DateFormat.yMMMd().format(tx.date)),
            trailing: Text(
              '${tx.type == my_model.TransactionType.income ? '+' : '-'} ${_formatCurrency(tx.amount)}',
              style: TextStyle(
                  color: tx.type == my_model.TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () => _showTransactionDetailsDialog(i),
            onLongPress: () => _showEditTransactionDialog(i),
          );
        }),
      ],
    )),
    floatingActionButton:
    FloatingActionButton(onPressed: _showAddTypeDialog, child: const Icon(Icons.add)),
  );

  void _showAddTypeDialog() {}
  void _showTransactionDetailsDialog(int index) {}
  void _showEditTransactionDialog(int index) {}
}
