// lib/screens/add_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/core/models/account_model.dart';
import '/core/models/transaction_model.dart';
import '/core/utils/snackbar_utils.dart';
import '/core/services/firestore_service.dart';
import '/core/models/user_category_model.dart';
import 'manage_categories_page.dart'
;

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
  Account? _selectedFromAccount;
  Account? _selectedToAccount;
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

    try {
      if (_selectedType == TransactionType.transfer) {
        if (_selectedFromAccount == null || _selectedToAccount == null) {
          showCustomSnackbar(context, 'Please select both accounts.', type: SnackbarType.error);
          return;
        }
        if (_selectedFromAccount!.currency != _selectedToAccount!.currency) {
          showCustomSnackbar(context, 'Accounts must have the same currency for transfers.', type: SnackbarType.error);
          return;
        }
        await _firestoreService.addTransferTransaction(
          widget.user.uid,
          _selectedFromAccount!.id,
          _selectedToAccount!.id,
          double.parse(_amountController.text),
          _descriptionController.text,
        );
      } else {
        if (_selectedFromAccount == null || _selectedCategory == null) {
          showCustomSnackbar(context, 'Please select an account and category.', type: SnackbarType.error);
          return;
        }
        final transaction = TransactionModel(
          accountId: _selectedFromAccount!.id,
          description: _descriptionController.text,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          type: _selectedType,
          category: _selectedCategory!,
          currency: _selectedFromAccount!.currency,
        );
        await _firestoreService.addTransaction(widget.user.uid, transaction);
      }
      if (mounted) {
        showCustomSnackbar(context, 'Transaction saved successfully!');
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      _logger.severe('Failed to save transaction', e, s);
      if (mounted) {
        showCustomSnackbar(context, 'Error: ${e.toString()}', type: SnackbarType.error);
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
              _buildAccountSelectors(),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: "Amount", 
                  prefixText: _selectedFromAccount != null 
                    ? '${_selectedFromAccount!.currency} ' 
                    : '\$ '
                ),
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
              if (_selectedType != TransactionType.transfer) ...[
                const SizedBox(height: 16),
                _buildCategorySelector(),
              ],
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

  Widget _buildAccountSelectors() {
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

        List<Account> toAccounts = (_selectedFromAccount != null)
            ? accounts.where((acc) => acc.currency == _selectedFromAccount!.currency && acc.id != _selectedFromAccount!.id).toList()
            : [];

        if (_selectedType == TransactionType.transfer) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAccountDropdown(accounts, true)),
              const SizedBox(width: 16),
              Expanded(child: _buildAccountDropdown(toAccounts, false)),
            ],
          );
        } else {
          return _buildAccountDropdown(accounts, true);
        }
      },
    );
  }

  Widget _buildAccountDropdown(List<Account> accounts, bool isFrom) {
    return DropdownButtonFormField<Account>(
      value: isFrom ? _selectedFromAccount : _selectedToAccount,
      hint: Text(isFrom ? "From Account" : "To Account"),
      decoration: InputDecoration(labelText: isFrom ? "From" : "To"),
      isExpanded: true,
      items: accounts.map((Account account) {
        return DropdownMenuItem<Account>(
          value: account,
          child: Text(
            '${account.name} (${account.currency})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (Account? newValue) {
        setState(() {
          if (isFrom) {
            _selectedFromAccount = newValue;
            _selectedToAccount = null; 
          } else {
            _selectedToAccount = newValue;
          }
        });
      },
      validator: (value) => value == null ? 'Please select an account' : null,
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
        ButtonSegment(
            value: TransactionType.transfer,
            label: Text("Transfer"),
            icon: Icon(Icons.swap_horiz)),
      ],
      selected: {_selectedType},
      onSelectionChanged: (Set<TransactionType> newSelection) {
        setState(() {
          _selectedType = newSelection.first;
          _selectedCategory = null;
          _selectedFromAccount = null;
          _selectedToAccount = null;
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
        if (_selectedType != TransactionType.transfer &&
            _selectedCategory == null) {
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