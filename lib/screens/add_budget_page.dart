// lib/screens/add_budget_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tajiri_ai/core/models/budget_model.dart';
import 'package:tajiri_ai/core/models/user_category_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';
import 'package:tajiri_ai/core/utils/snackbar_utils.dart';

class AddBudgetPage extends StatefulWidget {
  final User user;
  final Budget? budget;
  const AddBudgetPage({Key? key, required this.user, this.budget})
      : super(key: key);

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  final _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedCategory = widget.budget!.category;
      _amountController.text = widget.budget!.amount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Budget' : 'Add Budget'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Budget?'),
                    content: const Text(
                        'Are you sure you want to delete this budget?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _firestoreService.deleteBudget(
                      widget.user.uid, widget.budget!.id!);
                  Navigator.of(context).pop();
                }
              },
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              StreamBuilder<List<UserCategory>>(
                  stream: _firestoreService.getUserCategories(widget.user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final categories = snapshot.data!
                        .map((category) => category.name)
                        .toList();
                    return DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: const Text('Select Category'),
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    );
                  }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Budget Amount'),
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
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final now = DateTime.now();
                    final budget = Budget(
                      id: _isEditing ? widget.budget!.id : null,
                      category: _selectedCategory!,
                      amount: double.parse(_amountController.text),
                      month: now.month,
                      year: now.year,
                    );
                    if (_isEditing) {
                      await _firestoreService.updateBudget(
                          widget.user.uid, budget);
                      showCustomSnackbar(context, "Budget updated!");
                    } else {
                      await _firestoreService.addBudget(widget.user.uid, budget);
                      showCustomSnackbar(context, "Budget added!");
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text(_isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}