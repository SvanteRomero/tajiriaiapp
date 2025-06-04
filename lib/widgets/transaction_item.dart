import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as my_model;

class TransactionItem extends StatelessWidget {
  final my_model.Transaction transaction;
  final String Function(double) formatCurrency;
  final Future<bool> Function() onDelete;
  final VoidCallback onDismissed;

  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.formatCurrency,
    required this.onDelete,
    required this.onDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(transaction.date.toIso8601String() + transaction.description),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20.0),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (_) async {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (shouldDelete ?? false) {
        final success = await onDelete();
        if (success) {
          onDismissed();
          return true;
        }
      }
      return false;
    },
    child: ListTile(
      leading: Icon(
        transaction.type == my_model.TransactionType.income
            ? Icons.arrow_downward
            : Icons.arrow_upward,
        color: transaction.type == my_model.TransactionType.income
            ? Colors.green
            : Colors.red,
      ),
      title: Text(transaction.description),
      subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
      trailing: Text(
        '${transaction.type == my_model.TransactionType.income ? '+' : '-'} ${formatCurrency(transaction.amount)}',
        style: TextStyle(
          color: transaction.type == my_model.TransactionType.income
              ? Colors.green
              : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
