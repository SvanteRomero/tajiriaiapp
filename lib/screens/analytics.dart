// lib/screens/analytics.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CategorySpending {
  final String category;
  final double amount;
  final Color color;
  final IconData icon;
  CategorySpending(this.category, this.amount, this.color, this.icon);
}

class AnalyticsPage extends StatefulWidget {
  final User user;
  const AnalyticsPage({super.key, required this.user});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late Future<Map<String, dynamic>> _analyticsData;

  @override
  void initState() {
    super.initState();
    _analyticsData = _fetchAnalyticsData();
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      "totalSpending": 2845.60,
      "spendingByCategory": [
        CategorySpending("Groceries", 620.50, Colors.orange, Icons.local_grocery_store),
        CategorySpending("Shopping", 430.00, Colors.purple, Icons.shopping_bag),
        CategorySpending("Rent", 1200.00, Colors.red, Icons.real_estate_agent),
        CategorySpending("Transport", 185.25, Colors.blue, Icons.directions_car),
        CategorySpending("Subscriptions", 89.85, Colors.teal, Icons.subscriptions),
        CategorySpending("Dining Out", 320.00, Colors.pink, Icons.restaurant),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Could not load analytics."));
        }

        final data = snapshot.data!;
        final totalSpending = data['totalSpending'] as double;
        final spendingByCategory = data['spendingByCategory'] as List<CategorySpending>;

        return RefreshIndicator(
          onRefresh: () async { setState(() { _analyticsData = _fetchAnalyticsData(); }); },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTotalSpendingCard(totalSpending),
              const SizedBox(height: 24),
              _buildSpendingPieChartCard(spendingByCategory, totalSpending),
              const SizedBox(height: 24),
              _buildCategoryListCard(spendingByCategory, totalSpending),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalSpendingCard(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [Colors.deepPurple.shade500, Colors.deepPurple.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Spending This Month", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(NumberFormat.currency(symbol: '\$').format(total), style: GoogleFonts.poppins(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ],
      ),
    );
  }
  
  Widget _buildSpendingPieChartCard(List<CategorySpending> categories, double total) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Spending Breakdown", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categories.map((cat) => PieChartSectionData(
                    color: cat.color,
                    value: cat.amount,
                    title: '${(cat.amount / total * 100).toStringAsFixed(0)}%',
                    radius: 90,
                    titleStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, shadows: [const Shadow(blurRadius: 2, color: Colors.black26)]),
                  )).toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListCard(List<CategorySpending> categories, double total) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Details By Category", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...categories.map((cat) => _buildCategoryListItem(cat, total)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(CategorySpending category, double totalSpending) {
    final percentage = (category.amount / totalSpending);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: category.color.withOpacity(0.15), child: Icon(category.icon, color: category.color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.category, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(NumberFormat.currency(symbol: '\$').format(category.amount), style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${(percentage * 100).toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: percentage, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(category.color), minHeight: 6, borderRadius: BorderRadius.circular(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
