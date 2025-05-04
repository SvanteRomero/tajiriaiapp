// @dart=2.12
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/components/empty_page.dart';

import '../models/transaction.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoading = true;


  @override
  void initState() {
    super.initState();

    // TODO: Fetch transactions from the server
  }


  // List to store transactions

  // Calculate current balance
  double get _currentBalance {
    return transactions.fold(0, (sum, transaction) {
      return sum +
          (transaction.type == TransactionType.income
              ? transaction.amount
              : -transaction.amount);
    });
  }

  // Format currency
  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'Tsh ', name: "Shillings")
        .format(amount);
  }

  // Format date
  String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  // Stub method for adding transaction
  void addTransaction({TransactionType? type}) {
    // TODO: Implement transaction addition logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Transaction'),
        content: const Text('Transaction form will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: transactions.isEmpty ? _buildEmptyState() : _buildPopulatedState(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addTransaction(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyPage(
        pageIconData: Icons.receipt_long_sharp,
        pageTitle: "No Transactions yet",
        pageDescription: "Tap the + button to add your first transaction");
  }

  Widget _buildPopulatedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 24),
          _buildRecentTransactionsHeader(),
          const SizedBox(height: 16),
          _buildTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      color: Color.fromARGB(255, 0, 44, 85),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [

                const Icon(Icons.account_balance_wallet,
                    size: 32, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Current Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatCurrency(_currentBalance),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        addTransaction(type: TransactionType.income),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Money'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement transfer action
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Transfer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Implement see all action
          },
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          leading: Icon(
            transaction.type == TransactionType.income
                ? Icons.money
                : Icons.shopping_cart,
            color: transaction.type == TransactionType.income
                ? Colors.green
                : Colors.red,
          ),
          title: Text(transaction.description),
          subtitle: Text(_formatDate(transaction.date)),
          trailing: Text(
            '${transaction.type == TransactionType.income ? '+' : '-'} ${_formatCurrency(transaction.amount)}',
            style: TextStyle(
              color: transaction.type == TransactionType.income
                  ? Colors.green
                  : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
