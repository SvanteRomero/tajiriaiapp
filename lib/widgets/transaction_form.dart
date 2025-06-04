import 'package:flutter/material.dart';
import 'package:tajiri_ai/models/category_model.dart';
import 'package:uuid/uuid.dart';
import '../models/hive/transaction_model.dart';

class TransactionForm extends StatefulWidget {
  final Function(HiveTransaction) onSubmit;
  final String userId;
  final String username;

  const TransactionForm({
    Key? key,
    required this.onSubmit,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _type = 'expense';
  String _mainCategory = 'Other';
  String _subCategory = 'Miscellaneous';
  DateTime _selectedDate = DateTime.now();
  List<String> _subCategories = [];

  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  void _updateCategories() {
    final isIncome = _type == 'income';
    final mainCategories = TransactionCategories.getMainCategories(isIncome);
    
    if (!mainCategories.contains(_mainCategory)) {
      _mainCategory = mainCategories.first;
    }
    
    _subCategories = TransactionCategories.getSubcategories(_mainCategory, isIncome);
    if (!_subCategories.contains(_subCategory)) {
      _subCategory = _subCategories.first;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final transaction = HiveTransaction(
        id: const Uuid().v4(),
        username: widget.username,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _type,
        userId: widget.userId,
        mainCategory: _mainCategory,
        subCategory: _subCategory,
      );

      widget.onSubmit(transaction);
      
      // Reset form
      _descriptionController.clear();
      _amountController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _type = 'expense';
        _mainCategory = TransactionCategories.getMainCategories(false).first;
        _updateCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == 'income';
    final mainCategories = TransactionCategories.getMainCategories(isIncome);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Transaction Type Switch
          Row(
            children: [
              const Text('Type:'),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Expense'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text('Income'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                    _updateCategories();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Field
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Category Dropdowns
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _mainCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: mainCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _mainCategory = value;
                        _subCategories = TransactionCategories.getSubcategories(value, isIncome);
                        _subCategory = _subCategories.first;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _subCategory,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory',
                    prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  ),
                  items: _subCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _subCategory = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Picker
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.save),
            label: const Text('Save Transaction'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
