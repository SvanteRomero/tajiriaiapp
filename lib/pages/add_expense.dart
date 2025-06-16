import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_creation.dart';

class AddExpense extends StatefulWidget {
  final String userId;
  const AddExpense({super.key, required this.userId});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  String? selectedCategoryName;
  Color? selectedCategoryColor;
  String? selectedCategoryIcon;
  DateTime selectedDate = DateTime.now();
  String transactionType = 'expense'; // Default to expense
  String? _description;

  final List<CategoryInfo> categories = [
    CategoryInfo(name: 'Entertainment', icon: 'entertainment', color: Colors.purple.shade200),
    CategoryInfo(name: 'Food', icon: 'food', color: Colors.orange.shade200),
    CategoryInfo(name: 'Home', icon: 'home', color: Colors.blue.shade200),
    CategoryInfo(name: 'Pet', icon: 'pet', color: Colors.green.shade200),
    CategoryInfo(name: 'Shopping', icon: 'shopping', color: Colors.pink.shade200),
    CategoryInfo(name: 'Tech', icon: 'tech', color: Colors.cyan.shade200),
    CategoryInfo(name: 'Travel', icon: 'travel', color: Colors.teal.shade200),
  ];

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
  }

  void _selectDate() async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null) {
      setState(() {
        selectedDate = newDate;
        dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Add Expenses',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Colors.black,
              )),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Transaction Type Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: transactionType,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          transactionType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: expenseController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(
                    FontAwesomeIcons.dollarSign,
                    size: 18,
                    color: Colors.grey,
                  ),
                  hintText: 'Amount',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: TextEditingController(),
                keyboardType: TextInputType.text,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(
                    FontAwesomeIcons.pen,
                    size: 18,
                    color: Colors.grey,
                  ),
                  hintText: 'Description',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                onChanged: (value) {
                  // Store description value in a variable
                  _description = value;
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: categoryController,
                      readOnly: true,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => Container(
                            padding: const EdgeInsets.all(16),
                            height: 320,
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1,
                              ),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final cat = categories[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategoryName = cat.name;
                                      selectedCategoryIcon = cat.icon;
                                      selectedCategoryColor = cat.color;
                                      categoryController.text = selectedCategoryName ?? '';
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        cat.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      style: TextStyle(color: selectedCategoryColor != null ? Colors.black : Colors.grey.shade700),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: selectedCategoryColor ?? Colors.grey.shade100,
                        prefixIcon: selectedCategoryIcon == null
                            ? const Icon(FontAwesomeIcons.list, size: 18, color: Colors.grey)
                            : Image.asset('assets/$selectedCategoryIcon.png', scale: 1.8),
                        hintText: 'Select Category',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
SizedBox(
  height: 56,
  width: 56,
  child: ElevatedButton(
    onPressed: () {
      getCategoryCreation(context);
    },
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: EdgeInsets.zero,
      backgroundColor: Colors.black,
    ),
    child: const Icon(Icons.add, color: Colors.white),
  ),
),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: dateController,
                readOnly: true,
                onTap: _selectDate,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(FontAwesomeIcons.clock, size: 18, color: Colors.grey),
                  hintText: 'Date',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () async {
                    if (expenseController.text.isEmpty || selectedCategoryName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    try {
                      final amount = double.parse(expenseController.text);
                      
                      // Save transaction to Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userId)
                          .collection('transactions')
                          .add({
                        'username': '', // Will be populated from user data
                        'description': _description ?? 'Transaction',
                        'amount': amount,
                        'type': transactionType,
                        'category': selectedCategoryName,
                        'categoryColor': selectedCategoryColor?.value,
                        'categoryIcon': selectedCategoryIcon,
                        'date': Timestamp.fromDate(selectedDate),
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction saved successfully')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryInfo {
  final String name;
  final String icon;
  final Color color;

  CategoryInfo({required this.name, required this.icon, required this.color});
}
