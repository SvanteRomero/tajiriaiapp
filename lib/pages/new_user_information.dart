/// A comprehensive onboarding page that collects additional user information
/// after registration. This includes personal details, financial information,
/// savings goals, and initial financial goals. The collected data is stored
/// in Firestore and used throughout the app for personalized experiences.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tajiri_ai/models/goal_model.dart';
import 'home_page.dart';

/// A form-based widget for collecting new user information.
/// Requires an authenticated user instance to function.
class NewUserInformation extends StatefulWidget {
  final User user;
  const NewUserInformation({Key? key, required this.user}) : super(key: key);

  @override
  _NewUserInformationState createState() => _NewUserInformationState();
}

class _NewUserInformationState extends State<NewUserInformation> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Personal information fields
  String? _gender;
  int? _age;
  bool _isLoading = false;
  final TextEditingController _collegeController = TextEditingController();

  // Fixed Income fields
  final TextEditingController _incomeDescriptionController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();
  String _incomeDuration = 'Monthly';

  // Goal fields
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();
  DateTime? _goalDeadline;

  // Savings goal inputs
  final TextEditingController _weeklyGoalController = TextEditingController();
  final TextEditingController _monthlyGoalController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    _goalTitleController.dispose();
    _goalAmountController.dispose();
    _weeklyGoalController.dispose();
    _monthlyGoalController.dispose();
    _collegeController.dispose();
    _incomeDescriptionController.dispose();
    _incomeAmountController.dispose();
    super.dispose();
  }

  /// Handles form submission and data storage in Firestore.
  /// 
  /// This method:
  /// 1. Validates all form inputs
  /// 2. Updates user information in Firestore
  /// 3. Creates initial financial goal
  /// 4. Navigates to home page on success
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _gender == null ||
        _goalDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    _formKey.currentState!.save();
    final uid = widget.user.uid;

    try {
      // Save user information including goals and fixed income
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gender': _gender,
        'age': _age,
        'college': _collegeController.text.trim(),
        'weeklyGoal': double.parse(_weeklyGoalController.text.trim()),
        'monthlyGoal': double.parse(_monthlyGoalController.text.trim()),
        'fixedIncome': {
          'description': _incomeDescriptionController.text.trim(),
          'amount': double.parse(_incomeAmountController.text.trim()),
          'duration': _incomeDuration,
        },
      });

      // Create initial financial goal
      final goal = Goal(
        title: _goalTitleController.text.trim(),
        target: int.parse(_goalAmountController.text.trim()),
        deadline: _goalDeadline!,
      );
      await FirebaseFirestore.instance.collection('goals').add({
        ...goal.toMap(),
        'userId': uid,
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows a date picker for selecting goal deadline.
  /// Updates state with selected date.
  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _goalDeadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome! Tell Us About You',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Personal Information Section
                _buildSectionCard(
                  'Personal Information',
                  Icons.person_outline,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gender Selection
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGenderSelection(),
                      if (_gender == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Please select a gender',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      // Age Input
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: null,
                        label: 'Age',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Age is required';
                          final age = int.tryParse(val);
                          if (age == null || age < 13 || age > 120) {
                            return 'Enter a valid age (13-120)';
                          }
                          return null;
                        },
                        onSaved: (val) => _age = int.parse(val!),
                      ),

                      // College Input
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _collegeController,
                        label: 'College/University',
                        validator: (val) => val?.isEmpty ?? true
                            ? 'College/University is required'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Fixed Income Section
                _buildSectionCard(
                  'Fixed Income',
                  Icons.attach_money,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _incomeDescriptionController,
                        label: 'Income Description (e.g., Allowance, Part-time job)',
                        validator: (val) => val?.isEmpty ?? true
                            ? 'Income description is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _incomeAmountController,
                        label: 'Amount (Tsh)',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty ?? true) return 'Amount is required';
                          if (double.tryParse(val!) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDurationDropdown(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Savings Goals Section
                _buildSectionCard(
                  'Savings Goals',
                  Icons.savings_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _weeklyGoalController,
                        label: 'Weekly Savings Goal (Tsh)',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty ?? true) return 'Weekly goal is required';
                          if (double.tryParse(val!) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _monthlyGoalController,
                        label: 'Monthly Savings Goal (Tsh)',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty ?? true) return 'Monthly goal is required';
                          if (double.tryParse(val!) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // First Goal Section
                _buildSectionCard(
                  'Set Your First Goal',
                  Icons.flag_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _goalTitleController,
                        label: 'Goal Title',
                        validator: (val) => val?.isEmpty ?? true
                            ? 'Goal title is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _goalAmountController,
                        label: 'Target Amount',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty ?? true) return 'Target amount is required';
                          if (int.tryParse(val!) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDeadlinePicker(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Finish Setup',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a styled card for each section with consistent styling
  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.blue[400]!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.blue[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  /// Builds a consistent text field with styling
  Widget _buildTextField({
    required TextEditingController? controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.blue[400]!,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  /// Builds the gender selection chips
  Widget _buildGenderSelection() {
    return Wrap(
      spacing: 8,
      children: ['Male', 'Female', 'Other'].map((label) {
        final selected = _gender == label;
        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[600],
            ),
          ),
          selected: selected,
          onSelected: (_) => setState(() => _gender = label),
          selectedColor: Colors.blue[400],
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        );
      }).toList(),
    );
  }

  /// Builds the income duration dropdown
  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: _incomeDuration,
      decoration: InputDecoration(
        labelText: 'Duration',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      items: ['Weekly', 'Monthly', 'Yearly']
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o),
              ))
          .toList(),
      onChanged: (val) => setState(() => _incomeDuration = val!),
    );
  }

  /// Builds the deadline picker tile
  Widget _buildDeadlinePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            _goalDeadline == null
                ? 'Select Deadline'
                : 'Deadline: ${_goalDeadline!.toLocal()}'.split(' ')[0],
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickDeadline,
          contentPadding: EdgeInsets.zero,
        ),
        if (_goalDeadline == null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please pick a deadline',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
