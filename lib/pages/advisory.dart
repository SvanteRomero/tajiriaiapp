import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_model;

/// Advisory screen provides financial advice and recommendations
/// Based on user's transaction history and financial patterns
class Advisory extends StatefulWidget {
  /// Currently authenticated user
  final User user;

  const Advisory({super.key, required this.user});

  @override
  State<Advisory> createState() => _AdvisoryState();
}

class _AdvisoryState extends State<Advisory> {
  /// List of user's transactions for analysis
  /// Currently a placeholder for future implementation
  List<my_model.Transaction> transactions = [];

  /// Builds the main content when user has transaction data
  /// Currently displays a placeholder message
  /// TODO: Implement actual financial advice generation
  Widget _buildPopulatedState() {
    return const Center(
      child: Text("Your financial advice will appear here.")
    );
  }

  /// Builds empty state when no transaction data is available
  /// Prompts user to add financial details
  Widget _buildEmptyState() {
    return EmptyPage(
      pageIconData: Icons.lightbulb_outline_rounded,
      pageTitle: "Advisory Unavailable",
      pageDescription: "Please provide some financial details to get advisory",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: transactions.isEmpty ? _buildEmptyState() : _buildPopulatedState(),
    );
  }
}
