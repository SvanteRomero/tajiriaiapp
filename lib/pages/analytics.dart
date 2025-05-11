import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_model;

class Analytics extends StatefulWidget {
  final User user;

  const Analytics({super.key, required this.user});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  List<my_model.Transaction> transactions = []; // Placeholder for transaction data

  Widget _buildEmptyState() {
    return EmptyPage(
      pageIconData: Icons.waterfall_chart,
      pageTitle: "Analytics Unavailable",
      pageDescription:
      "Add your financial details to get your statistics",
    );
  }

  Widget _buildPopulatedState() {
    return const Center(
      child: Text("Analytics will appear here."),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: transactions.isEmpty ? _buildEmptyState() : _buildPopulatedState(),
    );
  }
}
