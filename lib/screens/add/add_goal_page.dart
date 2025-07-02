// lib/screens/add/add_goal_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/core/models/goal_model.dart';
import '/core/services/firestore_service.dart';
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
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  String _currencySymbol = '\$';
  String? _suggestedDailyLimitText;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchCurrency();
    _targetAmountController.addListener(_updateSuggestedLimit);
  }

  Future<void> _fetchCurrency() async {
    try {
      final accounts = await _firestoreService.getAccounts(widget.user.uid).first;
      if (accounts.isNotEmpty && mounted) {
        setState(() {
          _currencySymbol = accounts.first.currency;
        });
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  void _updateSuggestedLimit() {
    final targetAmount = double.tryParse(_targetAmountController.text);
    if (targetAmount != null && targetAmount > 0) {
      final now = DateTime.now();
      final duration = _selectedEndDate.difference(now).inDays;
      if (duration > 0) {
        final dailySaving = targetAmount / duration;
        setState(() {
          _suggestedDailyLimitText = "To save ${NumberFormat.currency(symbol: _currencySymbol).format(targetAmount)} in $duration days, you should save at least ${NumberFormat.currency(symbol: _currencySymbol).format(dailySaving)} each day.";
        });
      }
    } else {
      setState(() {
        _suggestedDailyLimitText = null;
      });
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
        _updateSuggestedLimit(); // Recalculate when date changes
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
        id: '',
        goalName: _goalNameController.text,
        targetAmount: double.parse(_targetAmountController.text),
        savedAmount: 0.0,
        startDate: DateTime.now(),
        endDate: _selectedEndDate,
        dailyLimit: double.parse(_dailyLimitController.text),
        timezone: 'Africa/Dar_es_Salaam',
        createdAt: DateTime.now(),
      );

      await _firestoreService.addGoal(widget.user.uid, newGoal);
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
                decoration: InputDecoration(labelText: "Target Amount", prefixText: "$_currencySymbol "),
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
                  prefixText: "$_currencySymbol ",
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a daily limit';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              if (_suggestedDailyLimitText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _suggestedDailyLimitText!,
                            style: GoogleFonts.poppins(color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.removeListener(_updateSuggestedLimit);
    _targetAmountController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
  }
}