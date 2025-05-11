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

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
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

  double get _totalIncome =>
      _transactions
          .where((tx) => tx.type == my_model.TransactionType.income)
          .fold(0.0, (sum, tx) => sum + tx.amount);

  double get _totalExpense =>
      _transactions
          .where((tx) => tx.type == my_model.TransactionType.expense)
          .fold(0.0, (sum, tx) => sum + tx.amount);

  double get _currentBalance => _totalIncome - _totalExpense;

  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0).format(amount);

  Future<void> _showAddTypeDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Transaction Type'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddTransactionDialog(my_model.TransactionType.income);
            },
            child: const Text('Add Income'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddTransactionDialog(my_model.TransactionType.expense);
            },
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTransactionDialog(my_model.TransactionType type) async {
    final _formKey = GlobalKey<FormState>();
    String description = '';
    double amount = 0.0;
    DateTime date = DateTime.now();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == my_model.TransactionType.income ? 'Add Income' : 'Add Expense'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                onSaved: (v) => description = v!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null || n <= 0 ? 'Enter valid amount' : null;
                },
                onSaved: (v) => amount = double.parse(v!),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => date = picked);
                },
                child: Text(DateFormat.yMd().format(date)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: type == my_model.TransactionType.income ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState!.save();
                final tx = my_model.Transaction(
                  username: widget.user.displayName ?? widget.user.email ?? 'User',
                  description: description,
                  amount: amount,
                  date: date,
                  type: type,
                );
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user.uid)
                    .collection('transactions')
                    .add({
                  'username': tx.username,
                  'description': tx.description,
                  'amount': tx.amount,
                  'date': Timestamp.fromDate(tx.date),
                  'type': tx.type.name,
                });
                Navigator.pop(context);
                _fetchTransactions();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransactionDetailsDialog(int index) async {
    final tx = _transactions[index];
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${tx.description}'),
            Text('Amount: ${_formatCurrency(tx.amount)}'),
            Text('Date: ${DateFormat.yMd().format(tx.date)}'),
            Text('Type: ${tx.type.name}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _showEditTransactionDialog(int index) async {
    final id = _transactionIds[index];
    final oldTx = _transactions[index];
    final _formKey = GlobalKey<FormState>();
    String description = oldTx.description;
    double amount = oldTx.amount;
    DateTime date = oldTx.date;
    my_model.TransactionType type = oldTx.type;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                  onSaved: (v) => description = v!.trim(),
                ),
                TextFormField(
                  initialValue: amount.toString(),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || n <= 0 ? 'Enter valid amount' : null;
                  },
                  onSaved: (v) => amount = double.parse(v!),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                  child: Text(DateFormat.yMd().format(date)),
                ),
                DropdownButtonFormField<my_model.TransactionType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: my_model.TransactionType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: type == my_model.TransactionType.income ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState!.save();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user.uid)
                    .collection('transactions')
                    .doc(id)
                    .update({
                  'description': description,
                  'amount': amount,
                  'date': Timestamp.fromDate(date),
                  'type': type.name,
                });
                Navigator.pop(context);
                _fetchTransactions();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int index) async {
    final id = _transactionIds[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('transactions')
          .doc(id)
          .delete();
      _fetchTransactions();
    }
  }

  Widget _buildEmptyState() => EmptyPage(
    pageIconData: Icons.add_box_outlined,
    pageTitle: 'No Transactions Yet',
    pageDescription: "Tap '+' to add your first transaction",
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : (_transactions.isEmpty ? _buildEmptyState() : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color.fromARGB(255, 0, 44, 85),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, ${widget.user.displayName ?? widget.user.email ?? 'User'}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 32, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Current Balance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_formatCurrency(_currentBalance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                        onPressed: () => _showAddTransactionDialog(my_model.TransactionType.income),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Income'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                        onPressed: () => _showAddTransactionDialog(my_model.TransactionType.expense),
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
        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_transactions.length, (i) {
          final tx = _transactions[i];
          return InkWell(
            onTap: () => _showTransactionDetailsDialog(i),
            onDoubleTap: () => _showEditTransactionDialog(i),
            onLongPress: () => showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(leading: const Icon(Icons.edit), title: const Text('Edit'), onTap: () { Navigator.pop(context); _showEditTransactionDialog(i); }),
                  ListTile(leading: const Icon(Icons.delete), title: const Text('Delete'), onTap: () { Navigator.pop(context); _confirmDelete(i); }),
                ],
              ),
            ),
            child: ListTile(
              leading: Icon(tx.type == my_model.TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward, color: tx.type == my_model.TransactionType.income ? Colors.green : Colors.red),
              title: Text(tx.description),
              subtitle: Text(DateFormat.yMMMd().format(tx.date)),
              trailing: Text(
                '${tx.type == my_model.TransactionType.income ? '+' : '-'} ${_formatCurrency(tx.amount)}',
                style: TextStyle(color: tx.type == my_model.TransactionType.income ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    )),
    floatingActionButton: FloatingActionButton(onPressed: _showAddTypeDialog, child: const Icon(Icons.add)),
  );
}
