// lib/screens/add_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/models/transaction_model.dart';
import 'package:logging/logging.dart';
import '../core/utils/snackbar_utils.dart';


class AddTransactionPage extends StatefulWidget {
  final User user;
  const AddTransactionPage({super.key, required this.user});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Other';
  bool _isLoading = false;
  final Logger _logger = Logger('AddTransactionPage');

  final List<String> _expenseCategories = ['Groceries', 'Shopping', 'Rent', 'Transport', 'Subscriptions', 'Dining Out', 'Other'];
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Investment', 'Other'];

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
      setState(() => _isLoading = true);

      final transaction = TransactionModel(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        category: _selectedCategory,
      );

      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('transactions').add(transaction.toJson());
        if (mounted) {
          showCustomSnackbar(context, 'Transaction saved successfully!');
          Navigator.of(context).pop();
        }
      } catch (e, s) {
        _logger.severe('Failed to save transaction', e, s);
        if (mounted) {
          showCustomSnackbar(context, 'Failed to save transaction. Please try again.', type: SnackbarType.error);
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
    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text("New Transaction")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 20),
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
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Transaction"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
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
        setState(() { _selectedType = newSelection.first; });
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
