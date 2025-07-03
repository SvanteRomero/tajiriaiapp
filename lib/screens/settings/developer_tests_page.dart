// lib/screens/settings/developer_tests_page.dart
import 'package:flutter/material.dart';
import 'package:tajiri_ai/core/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

class DeveloperTestsPage extends StatelessWidget {
  const DeveloperTestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: Text("Developer Tests", style: GoogleFonts.poppins()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTestButton(
            context: context,
            title: "Welcome Notification",
            subtitle: "Triggers the welcome message for new users.",
            onPressed: () {
              notificationService.showNotification(
                title: "Welcome to Tajiri AI!",
                body:
                    "We're excited to help you on your financial journey. Let's get started!",
                payload: 'open_chat',
              );
            },
          ),
          _buildTestButton(
            context: context,
            title: "Large Transaction Alert",
            subtitle:
                "Simulates an alert for a transaction over a set threshold.",
            onPressed: () {
              notificationService.showNotification(
                title: "Large Transaction Alert",
                body:
                    "A new transaction of TZS 50,000 for 'Test Expense' has been recorded.",
                payload: 'add_transaction',
              );
            },
          ),
          _buildTestButton(
            context: context,
            title: "Goal Milestone (50%)",
            subtitle: "Simulates hitting a 50% milestone on a savings goal.",
            onPressed: () {
              notificationService.showNotification(
                title: "You've hit 50% of your goal! 🎉",
                body:
                    "Amazing work on your 'Zanzibar Trip' goal. You're getting closer!",
                payload: 'view_goal_dummy_id',
              );
            },
          ),
          _buildTestButton(
            context: context,
            title: "Goal Reached (100%)",
            subtitle: "Simulates successfully completing a savings goal.",
            onPressed: () {
              notificationService.showNotification(
                title: "Goal Complete! 🏆",
                body:
                    "Congratulations! You've successfully reached your goal of saving for 'New Laptop'!",
                payload: 'view_goal_dummy_id',
              );
            },
          ),
          _buildTestButton(
            context: context,
            title: "7-Day Streak",
            subtitle: "Simulates a 7-day expense logging streak.",
            onPressed: () {
              notificationService.showNotification(
                title: "New Logging Streak! 🔥",
                body:
                    "You've logged your expenses for 7 days in a row. That's some serious dedication!",
                payload: 'open_chat',
              );
            },
          ),
          _buildTestButton(
            context: context,
            title: "Weekly Summary",
            subtitle:
                "Triggers a notification with a summary of the past week's finances.",
            onPressed: () {
              notificationService.showNotification(
                title: "Your Weekly Financial Summary",
                body: "Last week, you spent TZS 75,000 and earned TZS 200,000.",
                payload: 'open_analytics',
              );
            },
          ),
          _buildTestButton(
            context: context,
            title: "Daily Financial Tip",
            subtitle:
                "Sends a personalized financial tip to the user.",
            onPressed: () {
              notificationService.showNotification(
                title: "Your Daily Financial Tip from Tajiri! 💡",
                body:
                    "We noticed you're doing great on your 'Dining Out' budget. Keep it up!",
                payload: 'open_chat',
              );
            },
          ),
          _buildTestButton(
            context: context,
            title: "Daily Logging Reminder",
            subtitle:
                "Triggers the daily reminder to log expenses.",
            onPressed: () {
              notificationService.showNotification(
                title: "Friendly Reminder",
                body: "Don't forget to log your expenses for today!",
                payload: 'add_transaction',
              );
            },
          ),
      ],
      ),
    );
  }

  Widget _buildTestButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: GoogleFonts.poppins()),
          trailing: ElevatedButton(
            onPressed: onPressed,
            child: const Text("Trigger"),
          ),
        ),
      ),
    );
  }
}