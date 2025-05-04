import 'package:flutter/material.dart';
import 'package:tajiri_ai/components/empty_page.dart';

import 'package:tajiri_ai/models/transaction.dart';


class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  Widget _buildEmptyState() {
    return EmptyPage(pageIconData: Icons.waterfall_chart, pageTitle: "Analytics Unavailable", pageDescription: "Add your financial details to get your statistics");
  }

  Widget _buildPopulatedState() {
    return Placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: transactions.isEmpty ? _buildEmptyState() : _buildPopulatedState(),
    );
  }
}
