// lib/screens/add_goal_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/core/models/goal_model.dart';
import '/core/services/firestore_service.dart';
import '/core/services/ai_advisor_service.dart'; // For AI suggestion
import '/core/utils/snackbar_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class AddGoalPage extends StatefulWidget {
  final User user;
  const AddGoalPage({Key? key, required this.user}) : super(key: key);

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _dailyLimitController = TextEditingController();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 30)); // Default 30 days from now
  bool _isLoading = false;
  String? _suggestedDailyLimit;

  final FirestoreService _firestoreService = FirestoreService();
  final AiAdvisorService _aiAdvisorService = AiAdvisorService();

  @override
  void initState() {
    super.initState();
    _suggestDailyLimit();
  }

  Future<void> _suggestDailyLimit() async {
    try {
      final response = await _aiAdvisorService.suggestDailyLimit(); // You'll need to add this method to AiAdvisorService
      setState(() {
        _suggestedDailyLimit = response;
      });
    } catch (e) {
      showCustomSnackbar(context, "Failed to get daily limit suggestion.", type: SnackbarType.error);
    }
  }


  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newGoal = Goal(
        id: '', // Firestore will generate this
        goalName: _goalNameController.text,
        targetAmount: double.parse(_targetAmountController.text),
        savedAmount: 0.0, // Starting saved amount is 0
        startDate: DateTime.now(),
        endDate: _selectedEndDate,
        dailyLimit: double.parse(_dailyLimitController.text),
        timezone: 'Africa/Dar_es_Salaam', // This should ideally be detected or selected by the user
        createdAt: DateTime.now(),
      );

      await _firestoreService.addGoal(widget.user.uid, newGoal); // You'll need to add this method to FirestoreService
      if (mounted) {
        showCustomSnackbar(context, 'Financial goal set successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(context, 'Failed to set goal. Please try again.', type: SnackbarType.error);
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
      appBar: AppBar(title: const Text("Set New Goal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _goalNameController,
                decoration: const InputDecoration(labelText: "Goal Name (e.g., Zanzibar Trip)"),
                validator: (value) => value!.isEmpty ? 'Please enter a goal name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(labelText: "Target Amount", prefixText: "\$ "),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a target amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectEndDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Deadline'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(DateFormat.yMMMd().format(_selectedEndDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dailyLimitController,
                decoration: InputDecoration(
                  labelText: "Daily Spending Limit",
                  prefixText: "\$ ",
                  suffixIcon: _suggestedDailyLimit != null
                      ? IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("Tajiri's Suggestion", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                content: Text(_suggestedDailyLimit!),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a daily limit';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoal,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Set Goal"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}