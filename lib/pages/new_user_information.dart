import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tajiri_ai/models/goal_model.dart';
import 'home_page.dart';

/// NewUserInformation collects additional user data after registration
/// Gathers personal details, income information, and initial savings goals
class NewUserInformation extends StatefulWidget {
  /// Currently authenticated user
  final User user;
  
  const NewUserInformation({Key? key, required this.user}) : super(key: key);

  @override
  _NewUserInformationState createState() => _NewUserInformationState();
}

class _NewUserInformationState extends State<NewUserInformation> {
  /// Key for form validation
  final _formKey = GlobalKey<FormState>();

  /// Personal information fields
  String? _gender;
  int? _age;
  final TextEditingController _collegeController = TextEditingController();

  /// Fixed income information fields
  final TextEditingController _incomeDescriptionController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();
  String _incomeDuration = 'Monthly';

  /// Goal setting fields
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();
  DateTime? _goalDeadline;

  /// Savings target fields
  final TextEditingController _weeklyGoalController = TextEditingController();
  final TextEditingController _monthlyGoalController = TextEditingController();

  /// Loading state for form submission
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up controllers
    _goalTitleController.dispose();
    _goalAmountController.dispose();
    _weeklyGoalController.dispose();
    _monthlyGoalController.dispose();
    _collegeController.dispose();
    _incomeDescriptionController.dispose();
    _incomeAmountController.dispose();
    super.dispose();
  }

  /// Handles form submission and data storage
  /// 
  /// Validates form data, saves to Firestore, and creates initial goal
  Future<void> _submit() async {
    // Validate all required fields
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
      // Save user information to Firestore
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

      // Create initial savings goal
      final goal = Goal(
        title: _goalTitleController.text.trim(),
        target: int.parse(_goalAmountController.text.trim()),
        deadline: _goalDeadline!,
      );
      await FirebaseFirestore.instance.collection('goals').add({
        ...goal.toMap(),
        'userId': uid,
      });

      // Navigate to home page on success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
        );
      }
    } catch (e) {
      // Show error message if save fails
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

  /// Opens date picker for goal deadline selection
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
                // Personal Information Card
                Card(
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
                        // Section header
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
                                Icons.person_outline,
                                color: Colors.blue[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Personal Information',
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

                        // Gender selection chips
                        const Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
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
                        ),
                        if (_gender == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Please select a gender',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),

                        const SizedBox(height: 16),
                        // Age input field
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Age',
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
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Age is required';
                            }
                            final age = int.tryParse(val);
                            if (age == null || age < 13 || age > 120) {
                              return 'Enter a valid age (13-120)';
                            }
                            return null;
                          },
                          onSaved: (val) => _age = int.parse(val!),
                        ),

                        const SizedBox(height: 16),
                        // College/University input field
                        TextFormField(
                          controller: _collegeController,
                          decoration: InputDecoration(
                            labelText: 'College/University',
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
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'College/University is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Fixed Income Card
                Card(
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
                        // Section header
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
                                Icons.attach_money,
                                color: Colors.blue[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fixed Income',
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

                        // Income description field
                        TextFormField(
                          controller: _incomeDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Income Description (e.g., Allowance, Part-time job)',
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
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Income description is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        // Income amount field
                        TextFormField(
                          controller: _incomeAmountController,
                          decoration: InputDecoration(
                            labelText: 'Amount (Tsh)',
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
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Amount is required';
                            }
                            if (double.tryParse(val) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        // Income duration dropdown
                        DropdownButtonFormField<String>(
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
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Savings Goals Card
                Card(
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
                        // Section header
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
                                Icons.savings_outlined,
                                color: Colors.blue[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Savings Goals',
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

                        // Weekly savings goal field
                        TextFormField(
                          controller: _weeklyGoalController,
                          decoration: InputDecoration(
                            labelText: 'Weekly Savings Goal (Tsh)',
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
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Weekly goal is required';
                            }
                            if (double.tryParse(val) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        // Monthly savings goal field
                        TextFormField(
                          controller: _monthlyGoalController,
                          decoration: InputDecoration(
                            labelText: 'Monthly Savings Goal (Tsh)',
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
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Monthly goal is required';
                            }
                            if (double.tryParse(val) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // First Goal Card
                Card(
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
                        // Section header
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
                                Icons.flag_outlined,
                                color: Colors.blue[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Set Your First Goal',
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

                        // Goal title field
                        TextFormField(
                          controller: _goalTitleController,
                          decoration: InputDecoration(
                            labelText: 'Goal Title',
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
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Goal title is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        // Goal amount field
                        TextFormField(
                          controller: _goalAmountController,
                          decoration: InputDecoration(
                            labelText: 'Target Amount',
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
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Target amount is required';
                            }
                            if (int.tryParse(val) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        // Goal deadline picker
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
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Submit button
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
}
