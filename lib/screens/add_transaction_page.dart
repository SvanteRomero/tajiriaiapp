// lib/screens/add_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/core/models/account_model.dart';
import '../core/models/transaction_model.dart';
import 'package:logging/logging.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/services/firestore_service.dart';
import 'package:tajiri_ai/core/models/user_category_model.dart';
import 'package:tajiri_ai/screens/manage_categories_page.dart';

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
  String? _selectedAccountId;
  String? _selectedCategory;
  bool _isLoading = false;
  final Logger _logger = Logger('AddTransactionPage');
  final FirestoreService _firestoreService = FirestoreService();

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final transaction = TransactionModel(
      accountId: _selectedAccountId!,
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      type: _selectedType,
      category: _selectedCategory!,
    );

    try {
      await _firestoreService.addTransaction(widget.user.uid, transaction);
      if (mounted) {
        showCustomSnackbar(context, 'Transaction saved successfully!');
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      _logger.severe('Failed to save transaction', e, s);
      if (mounted) {
        showCustomSnackbar(
            context, 'Failed to save transaction. Please try again.',
            type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildAccountSelector(),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration:
                    const InputDecoration(labelText: "Amount", prefixText: "\$ "),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Transaction"),
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
          return const Text(
              "Please create an account first on your profile page.");
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
          validator: (value) =>
              value == null ? 'Please select an account' : null,
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<TransactionType>(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Colors.deepPurple.withOpacity(0.2),
        selectedForegroundColor: Colors.deepPurple,
      ),
      segments: const [
        ButtonSegment(
            value: TransactionType.expense,
            label: Text("Expense"),
            icon: Icon(Icons.arrow_downward)),
        ButtonSegment(
            value: TransactionType.income,
            label: Text("Income"),
            icon: Icon(Icons.arrow_upward)),
      ],
      selected: {_selectedType},
      onSelectionChanged: (Set<TransactionType> newSelection) {
        setState(() {
          _selectedType = newSelection.first;
          _selectedCategory = null;
        });
      },
    );
  }

  Future<void> _showCategoryPickerDialog() async {
    final selectedCategory = await showDialog<UserCategory>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<UserCategory>>(
              stream: _firestoreService.getUserCategories(widget.user.uid,
                  type: _selectedType),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = snapshot.data!;
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No categories found.'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  ManageCategoriesPage(user: widget.user),
                            ));
                          },
                          child: const Text('Add Category'),
                        )
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop(category);
                      },
                      borderRadius: BorderRadius.circular(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: category.color.withOpacity(0.2),
                            child: Icon(
                              category.icon,
                              color: category.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              category.name,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedCategory != null) {
      setState(() {
        _selectedCategory = selectedCategory.name;
      });
    }
  }

  Widget _buildCategorySelector() {
    return FormField<String>(
      validator: (value) {
        if (_selectedCategory == null) {
          return 'Please select a category';
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _showCategoryPickerDialog,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category',
                  errorText: state.hasError ? state.errorText : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(_selectedCategory ?? 'Select a category'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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