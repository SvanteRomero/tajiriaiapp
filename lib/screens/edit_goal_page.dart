// lib/screens/edit_goal_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/core/models/goal_model.dart';
import '/core/services/firestore_service.dart';
import '/core/utils/snackbar_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class EditGoalPage extends StatefulWidget {
  final User user;
  final Goal goal; // The goal to be edited

  const EditGoalPage({Key? key, required this.user, required this.goal}) : super(key: key);

  @override
  State<EditGoalPage> createState() => _EditGoalPageState();
}

class _EditGoalPageState extends State<EditGoalPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _goalNameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _dailyLimitController;
  late DateTime _selectedEndDate;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _goalNameController = TextEditingController(text: widget.goal.goalName);
    _targetAmountController = TextEditingController(text: widget.goal.targetAmount.toStringAsFixed(2));
    _dailyLimitController = TextEditingController(text: widget.goal.dailyLimit.toStringAsFixed(2));
    _selectedEndDate = widget.goal.endDate;
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedGoal = Goal(
        id: widget.goal.id,
        goalName: _goalNameController.text.trim(),
        targetAmount: double.parse(_targetAmountController.text),
        savedAmount: widget.goal.savedAmount, // Keep current saved amount
        startDate: widget.goal.startDate, // Keep original start date
        endDate: _selectedEndDate,
        dailyLimit: double.parse(_dailyLimitController.text),
        timezone: widget.goal.timezone, // Keep original timezone
        status: widget.goal.status, // Keep original status
        goalVersion: widget.goal.goalVersion, // Keep original version
        streakCount: widget.goal.streakCount, // Keep original streak count
        graceDaysUsed: widget.goal.graceDaysUsed, // Keep original grace days
        createdAt: widget.goal.createdAt, // Keep original creation date
        updatedAt: DateTime.now(), // Update modification date
      );

      await _firestoreService.updateGoal(widget.user.uid, updatedGoal);
      if (mounted) {
        showCustomSnackbar(context, 'Goal updated successfully!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // Debugging print
        print('Error updating goal: $e');
        showCustomSnackbar(context, 'Failed to update goal. Please try again.', type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteGoal() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Goal?"),
        content: Text("Are you sure you want to delete '${widget.goal.goalName}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      try {
        // Debugging print: Check the goal ID being passed
        print('Attempting to delete goal with ID: ${widget.goal.id} for user ${widget.user.uid}');
        await _firestoreService.deleteGoal(widget.user.uid, widget.goal.id);
        if (mounted) {
          showCustomSnackbar(context, 'Goal deleted successfully!');
          Navigator.of(context).pop(true); // Pop with true to indicate success
        }
      } catch (e) {
        // Debugging print: Print the actual error to console
        print('Error deleting goal: $e');
        if (mounted) {
          showCustomSnackbar(context, 'Failed to delete goal. Please try again.', type: SnackbarType.error);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Goal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Delete Goal",
            onPressed: _isLoading ? null : _deleteGoal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Goal Details", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextFormField(
                controller: _goalNameController,
                decoration: const InputDecoration(labelText: "Goal Name"),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(labelText: "Target Amount", prefixText: "\$ "),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a target amount';
                  if (double.tryParse(value) == null) return 'Invalid number';
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
                decoration: const InputDecoration(labelText: "Daily Spending Limit", prefixText: "\$ "),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a daily limit';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}