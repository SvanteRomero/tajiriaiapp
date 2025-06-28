// lib/screens/dashboard_page.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '/core/models/account_model.dart';
import '/core/models/transaction_model.dart';
import '/core/services/firestore_service.dart';
import '/core/utils/snackbar_utils.dart';
import 'edit_transaction_page.dart';

class DashboardPage extends StatefulWidget {
  final User user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;
  
  // A Key to force the StreamBuilder to rebuild from scratch
  Key _streamBuilderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((connectivityResult) {
      _updateConnectionStatus(connectivityResult, isInitialCheck: true);
    });
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((connectivityResult) {
      _updateConnectionStatus(connectivityResult);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
  
  Stream<Map<String, dynamic>> _createDashboardStream() {
    // This helper function creates the stream that gets data for the dashboard.
    return CombineLatestStream.combine2(
      _firestoreService.getTransactions(widget.user.uid),
      _firestoreService.getAccounts(widget.user.uid),
      (List<TransactionModel> transactions, List<Account> accounts) =>
          {'transactions': transactions, 'accounts': accounts},
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResult,
      {bool isInitialCheck = false}) {
    if (!mounted) return;

    final bool wasOffline = _isOffline;
    final bool isNowOffline =
        connectivityResult.contains(ConnectivityResult.none);

    // Update the state immediately to show the offline/online status in the UI
    if (wasOffline != isNowOffline) {
      setState(() {
        _isOffline = isNowOffline;
      });
    }

    // Show snackbar notifications and handle data refresh only when the status actually changes.
    if (!isInitialCheck && wasOffline != isNowOffline) {
      if (isNowOffline) {
        showCustomSnackbar(context, 'You are now offline.',
            type: SnackbarType.info);
      } else {
        showCustomSnackbar(context, 'You are back online! Syncing data...',
            type: SnackbarType.success);
        
        // When coming back online, wait a couple of seconds for Firestore to sync
        // in the background before forcing the UI to refresh.
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _streamBuilderKey = UniqueKey();
            });
          }
        });
      }
    }
  }

  Future<bool> _confirmAndDeleteTransaction(
      TransactionModel transaction) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: Text(
            "Are you sure you want to delete '${transaction.description}'? This will adjust your account balance."),
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
        return true;
      } catch (e) {
        if (mounted) {
          showCustomSnackbar(
              context, 'Failed to delete transaction. Please try again.',
              type: SnackbarType.error);
        }
        return false;
      }
    }
    return false;
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EditTransactionPage(user: widget.user, transaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      key: _streamBuilderKey, // Assign the key here
      stream: _createDashboardStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final transactions =
            (snapshot.data?['transactions'] as List<TransactionModel>?) ?? [];
        final accounts =
            (snapshot.data?['accounts'] as List<Account>?) ?? [];

        if (transactions.isEmpty && !_isOffline) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long,
                    size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("No transactions yet",
                    style: GoogleFonts.poppins(
                        fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text("Tap the '+' button to add your first one!",
                    style: GoogleFonts.poppins(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        final accountMap = {for (var acc in accounts) acc.id: acc};

        double totalBalance =
            accounts.fold(0.0, (sum, item) => sum + item.balance);
        double totalIncome = transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0, (sum, item) => sum + item.amount);
        double totalExpense = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0, (sum, item) => sum + item.amount);

        return Column(
          children: [
            _buildBalanceCard(
                totalBalance,
                totalIncome,
                totalExpense,
                accounts.isNotEmpty ? accounts.first.currency : '\$'),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent Transactions",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final account = accountMap[transaction.accountId];
                  return Dismissible(
                    key: ValueKey(transaction.id),
                    background: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await _editTransaction(transaction);
                        return false;
                      } else {
                        return await _confirmAndDeleteTransaction(
                            transaction);
                      }
                    },
                    child: _buildTransactionTile(transaction, account),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(
      double balance, double income, double expense, String currencySymbol) {
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
          BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Balance",
              style: GoogleFonts.poppins(color: Colors.white70)),
          Text(
            NumberFormat.currency(symbol: currencySymbol).format(balance),
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildIncomeExpenseRow(Icons.arrow_upward, "Income",
                    income, Colors.greenAccent, currencySymbol),
              ),
              Expanded(
                child: _buildIncomeExpenseRow(Icons.arrow_downward, "Expense",
                    expense, Colors.redAccent, currencySymbol),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(IconData icon, String label, double amount,
      Color color, String currencySymbol) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            Text(
              NumberFormat.currency(symbol: currencySymbol).format(amount),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction, Account? account) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red.shade400 : Colors.green.shade400;
    final sign = isExpense ? '-' : '+';
    final currencySymbol = account?.currency ?? '\$';
    final tileColor =
        transaction.isPending ? Colors.grey.shade300 : Colors.white;

    return Card(
      color: tileColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: color),
        ),
        title: Text(transaction.description,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Text(DateFormat.yMMMd().format(transaction.date)),
            if (transaction.isPending) ...[
              const SizedBox(width: 8),
              const Icon(Icons.sync, size: 16, color: Colors.grey),
            ]
          ],
        ),
        trailing: Text(
          "$sign ${NumberFormat.currency(symbol: currencySymbol).format(transaction.amount)}",
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