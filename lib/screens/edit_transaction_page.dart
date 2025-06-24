// lib/screens/edit_transaction_page.dart
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/core/models/account_model.dart';
import 'package:tajiri_ai/core/models/transaction_model.dart';
import 'package:logging/logging.dart';
import 'package:tajiri_ai/core/utils/snackbar_utils.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';

class EditTransactionPage extends StatefulWidget {
  final User user;
  final TransactionModel transaction; // The transaction to be edited

  const EditTransactionPage({Key? key, required this.user, required this.transaction}) : super(key: key);

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TransactionType _selectedType;
  late DateTime _selectedDate;
  String? _selectedAccountId;
  late String _selectedCategory;
  bool _isLoading = false;
  final Logger _logger = Logger('EditTransactionPage');
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _expenseCategories = ['Groceries', 'Shopping', 'Rent', 'Transport', 'Subscriptions', 'Dining Out', 'Other'];
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Investment', 'Other'];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(text: widget.transaction.amount.toStringAsFixed(2));
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
    _selectedAccountId = widget.transaction.accountId;
    _selectedCategory = widget.transaction.category;

    // Ensure the initial category is valid for the initial type
    List<String> currentCategories = _selectedType == TransactionType.expense ? _expenseCategories : _incomeCategories;
    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        showCustomSnackbar(context, 'Please select an account.', type: SnackbarType.error);
        return;
      }
      setState(() => _isLoading = true);

      final updatedTransaction = TransactionModel(
        id: widget.transaction.id, // Keep the existing ID for update
        accountId: _selectedAccountId!,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        category: _selectedCategory,
      );

      try {
        await _firestoreService.updateTransaction(widget.user.uid, widget.transaction, updatedTransaction);
        if (mounted) {
          showCustomSnackbar(context, 'Transaction updated successfully!');
          Navigator.of(context).pop(true); // Pop with true to indicate success
        }
      } catch (e, s) {
        _logger.severe('Failed to update transaction', e, s);
        if (mounted) {
          showCustomSnackbar(context, 'Failed to update transaction. Please try again.', type: SnackbarType.error);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: Text("Are you sure you want to delete this transaction: '${widget.transaction.description}'? This action cannot be undone and will adjust your account balance."),
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

    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteTransaction(widget.user.uid, widget.transaction);
        if (mounted) {
          showCustomSnackbar(context, 'Transaction deleted successfully!');
          Navigator.of(context).pop(true); // Pop with true to indicate success
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackbar(context, 'Failed to delete transaction. Please try again.', type: SnackbarType.error);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentCategories = _selectedType == TransactionType.expense ? _expenseCategories : _incomeCategories;
    // Ensure the selected category is valid for the current type, reset to 'Other' if not
    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Transaction"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Delete Transaction",
            onPressed: _isLoading ? null : _deleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(currentCategories), // Pass currentCategories to update category dropdown
              const SizedBox(height: 20),
              _buildAccountSelector(),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Description"), validator: (value) => value!.isEmpty ? 'Please enter a description' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount", prefixText: "\$ "),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategorySelector(currentCategories),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector() {
    return StreamBuilder<List<Account>>(
      stream: _firestoreService.getAccounts(widget.user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var accounts = snapshot.data!;
        if (accounts.isEmpty) {
          return const Text("Please create an account first on your profile page.");
        }
        // Ensure _selectedAccountId is still valid among current accounts
        if (_selectedAccountId != null && !accounts.any((acc) => acc.id == _selectedAccountId)) {
          _selectedAccountId = null; // Reset if the previously selected account was deleted
        }
        return DropdownButtonFormField<String>(
          value: _selectedAccountId,
          hint: const Text("Select Account"),
          decoration: const InputDecoration(labelText: "Account"),
          items: accounts.map((Account account) {
            return DropdownMenuItem<String>(
              value: account.id,
              child: Text(account.name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedAccountId = newValue;
            });
          },
          validator: (value) => value == null ? 'Please select an account' : null,
        );
      },
    );
  }

  Widget _buildTypeSelector(List<String> currentCategories) { // Accept currentCategories
    return SegmentedButton<TransactionType>(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Colors.deepPurple.withOpacity(0.2),
        selectedForegroundColor: Colors.deepPurple,
      ),
      segments: const [
        ButtonSegment(value: TransactionType.expense, label: Text("Expense"), icon: Icon(Icons.arrow_downward)),
        ButtonSegment(value: TransactionType.income, label: Text("Income"), icon: Icon(Icons.arrow_upward)),
      ],
      selected: {_selectedType},
      onSelectionChanged: (Set<TransactionType> newSelection) {
        setState(() {
          _selectedType = newSelection.first;
          // Reset category if it's not applicable to the new type
          List<String> updatedCategories = _selectedType == TransactionType.expense ? _expenseCategories : _incomeCategories;
          if (!updatedCategories.contains(_selectedCategory)) {
            _selectedCategory = 'Other';
          }
        });
      },
    );
  }

  Widget _buildCategorySelector(List<String> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(labelText: "Category"),
      items: categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
      onChanged: (String? newValue) { setState(() { _selectedCategory = newValue!; }); },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Date'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(DateFormat.yMMMd().format(_selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}