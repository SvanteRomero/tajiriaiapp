// lib/screens/notification_settings_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // These boolean values would typically be saved to a user's profile in Firestore
  // to persist their choices across sessions. For now, they are local state.
  bool _transactionalNotifications = true;
  bool _goalNotifications = true;
  bool _financialSummaries = true;
  bool _financialTips = true;
  bool _personalizedAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Settings", style: GoogleFonts.poppins()),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildSectionHeader("Activity Alerts"),
          _buildSwitchTile(
            title: "Transactional Alerts",
            subtitle: "For large transactions and new income.",
            value: _transactionalNotifications,
            onChanged: (value) {
              setState(() => _transactionalNotifications = value);
              // Here you would save the preference to your backend
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          _buildSectionHeader("Motivation & Summaries"),
          _buildSwitchTile(
            title: "Goal Updates",
            subtitle: "Progress updates and deadline reminders.",
            value: _goalNotifications,
            onChanged: (value) {
              setState(() => _goalNotifications = value);
            },
          ),
          _buildSwitchTile(
            title: "Financial Summaries",
            subtitle: "Receive weekly and monthly reports.",
            value: _financialSummaries,
            onChanged: (value) {
              setState(() => _financialSummaries = value);
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          _buildSectionHeader("Tips & Insights"),
          _buildSwitchTile(
            title: "Personalized Insights",
            subtitle: "AI-powered alerts for subscriptions and savings.",
            value: _personalizedAlerts,
            onChanged: (value) {
              setState(() => _personalizedAlerts = value);
            },
          ),
          _buildSwitchTile(
            title: "Financial Tips",
            subtitle: "Periodic tips to improve financial habits.",
            value: _financialTips,
            onChanged: (value) {
              setState(() => _financialTips = value);
            },
          ),
        ],
      ),
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
