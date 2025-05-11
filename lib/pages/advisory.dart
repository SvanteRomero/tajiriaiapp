import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_model;

class Advisory extends StatefulWidget {
  final User user;

  const Advisory({super.key, required this.user});

  @override
  State<Advisory> createState() => _AdvisoryState();
}

class _AdvisoryState extends State<Advisory> {
  List<my_model.Transaction> transactions = []; // Placeholder for user transactions

  Widget _buildPopulatedState() {
    return const Center(child: Text("Your financial advice will appear here."));
  }

  Widget _buildEmptyState() {
    return EmptyPage(
      pageIconData: Icons.lightbulb_outline_rounded,
      pageTitle: "Advisory Unavailable",
      pageDescription:
      "Please provide some financial details to get advisory",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: transactions.isEmpty ? _buildEmptyState() : _buildPopulatedState(),
    );
  }
}
