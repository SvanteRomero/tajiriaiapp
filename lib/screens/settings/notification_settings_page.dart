// lib/screens/settings/notification_settings_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tajiri_ai/core/models/user_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _userFuture = _firestoreService.getUser(_user!.uid).first;
    } else {
      _userFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Settings", style: GoogleFonts.poppins()),
        elevation: 1,
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Could not load user settings."));
          }

          final userModel = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            children: [
              _buildSectionHeader("Activity Alerts"),
              _buildSwitchTile(
                title: "Transactional Alerts",
                subtitle: "For large transactions and new income.",
                value: userModel.transactionalNotifications,
                onChanged: (value) {
                  _updateSetting('transactionalNotifications', value);
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              _buildSectionHeader("Motivation & Summaries"),
              _buildSwitchTile(
                title: "Goal Updates",
                subtitle: "Progress updates and deadline reminders.",
                value: userModel.goalNotifications,
                onChanged: (value) {
                  _updateSetting('goalNotifications', value);
                },
              ),
              _buildSwitchTile(
                title: "Financial Summaries",
                subtitle: "Receive weekly and monthly reports.",
                value: userModel.financialSummaries,
                onChanged: (value) {
                  _updateSetting('financialSummaries', value);
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              _buildSectionHeader("Tips & Insights"),
              _buildSwitchTile(
                title: "Personalized Insights",
                subtitle: "AI-powered alerts for subscriptions and savings.",
                value: userModel.personalizedAlerts,
                onChanged: (value) {
                  _updateSetting('personalizedAlerts', value);
                },
              ),
              _buildFinancialTipsTile(context, userModel.financialTips),
            ],
          );
        },
      ),
    );
  }

  void _updateSetting(String key, dynamic value) {
    if (_user != null) {
      _firestoreService
          .updateUserNotificationSettings(_user!.uid, {key: value});
      setState(() {
        _userFuture = _firestoreService.getUser(_user!.uid).first;
      });
    }
  }

  Widget _buildFinancialTipsTile(BuildContext context, FinancialTipsFrequency currentValue) {
    return ListTile(
      title: Text("Financial Tips", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text("Frequency: ${currentValue.name}", style: GoogleFonts.poppins(color: Colors.grey.shade700)),
      onTap: () => _showFrequencyDialog(context, currentValue),
    );
  }

  void _showFrequencyDialog(BuildContext context, FinancialTipsFrequency currentValue) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Financial Tips Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: FinancialTipsFrequency.values.map((frequency) {
              return RadioListTile<FinancialTipsFrequency>(
                title: Text(frequency.name),
                value: frequency,
                groupValue: currentValue,
                onChanged: (FinancialTipsFrequency? value) {
                  if (value != null) {
                    _updateSetting('financialTips', value.name);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title,
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(color: Colors.grey.shade700)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}