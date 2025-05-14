import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tajiri_ai/models/goal_model.dart';

import 'home_page.dart';

class NewUserInformation extends StatefulWidget {
  final User user;
  const NewUserInformation({Key? key, required this.user}) : super(key: key);

  @override
  _NewUserInformationState createState() => _NewUserInformationState();
}

class _NewUserInformationState extends State<NewUserInformation> {
  final _formKey = GlobalKey<FormState>();
  String? _gender;
  int? _age;
  String _occupation = 'Student';

  // Goal fields
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();
  DateTime? _goalDeadline;

  // New savings goal inputs
  final TextEditingController _weeklyGoalController = TextEditingController();
  final TextEditingController _monthlyGoalController = TextEditingController();

  @override
  void dispose() {
    _goalTitleController.dispose();
    _goalAmountController.dispose();
    _weeklyGoalController.dispose();
    _monthlyGoalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _gender == null || _goalDeadline == null) return;
    _formKey.currentState!.save();
    final uid = widget.user.uid;
    // Save user info including new goals
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'gender': _gender,
      'age': _age,
      'occupation': _occupation,
      'weeklyGoal': double.parse(_weeklyGoalController.text.trim()),
      'monthlyGoal': double.parse(_monthlyGoalController.text.trim()),
    });
    // Save first goal entry if desired
    final goal = Goal(
      title: _goalTitleController.text.trim(),
      target: int.parse(_goalAmountController.text.trim()),
      deadline: _goalDeadline!,
    );
    await FirebaseFirestore.instance.collection('goals').add({
      ...goal.toMap(),
      'userId': uid,
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
    );
  }

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
      appBar: AppBar(title: const Text('Welcome! Tell Us About You')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Styled Gender Selection
              const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Male', 'Female', 'Other'].map((label) {
                  final selected = _gender == label;
                  return ChoiceChip(
                    label: Text(label,
                        style: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                    selected: selected,
                    onSelected: (_) => setState(() => _gender = label),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  );
                }).toList(),
              ),
              if (_gender == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Please select a gender', style: TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 24),
              // Age Input
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) {
                  final age = int.tryParse(val ?? '');
                  if (age == null || age < 13 || age > 120) return 'Enter a valid age';
                  return null;
                },
                onSaved: (val) => _age = int.parse(val!),
              ),

              const SizedBox(height: 16),
              // Occupation Dropdown
              Text('Occupation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _occupation,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['Student', 'Employed', 'Entrepreneur']
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (val) => setState(() => _occupation = val!),
              ),

              const SizedBox(height: 24),
              // New weekly/monthly goal inputs
              const Text('Savings Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weeklyGoalController,
                decoration: const InputDecoration(labelText: 'Weekly Savings Goal (Tsh)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter a valid number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthlyGoalController,
                decoration: const InputDecoration(labelText: 'Monthly Savings Goal (Tsh)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter a valid number' : null,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Set Your First Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Goal Title
              TextFormField(
                controller: _goalTitleController,
                decoration: const InputDecoration(labelText: 'Goal Title', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),
              // Goal Amount
              TextFormField(
                controller: _goalAmountController,
                decoration: const InputDecoration(labelText: 'Target Amount', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Enter a number';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              // Deadline Picker
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
                  child: Text('Please pick a deadline', style: TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 24),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Finish Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
