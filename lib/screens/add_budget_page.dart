// lib/screens/add_budget_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/models/budget_model.dart';
import '/core/models/transaction_model.dart';
import '/core/models/user_category_model.dart';
import '/core/services/firestore_service.dart';
import '/core/utils/snackbar_utils.dart';
import '/screens/manage_categories_page.dart';

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
                  type: TransactionType.expense),
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
                        const Text('No expense categories found.'),
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
              _buildCategorySelector(),
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
                      await _firestoreService.addBudget(
                          widget.user.uid, budget);
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