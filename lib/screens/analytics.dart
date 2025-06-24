// lib/screens/analytics.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart'; // Import FirestoreService
import 'package:tajiri_ai/core/models/transaction_model.dart'; // Import TransactionModel

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
  final FirestoreService _firestoreService = FirestoreService(); // Instantiate FirestoreService

  // Define a map for category colors and icons
  static const Map<String, Map<String, dynamic>> _categoryVisuals = {
    'Groceries': {'color': Colors.orange, 'icon': Icons.local_grocery_store},
    'Shopping': {'color': Colors.purple, 'icon': Icons.shopping_bag},
    'Rent': {'color': Colors.red, 'icon': Icons.real_estate_agent},
    'Transport': {'color': Colors.blue, 'icon': Icons.directions_car},
    'Subscriptions': {'color': Colors.teal, 'icon': Icons.subscriptions},
    'Dining Out': {'color': Colors.pink, 'icon': Icons.restaurant},
    'Other': {'color': Colors.grey, 'icon': Icons.category}, // Default for 'Other' or unmapped
    'Salary': {'color': Colors.green, 'icon': Icons.attach_money},
    'Freelance': {'color': Colors.lightGreen, 'icon': Icons.work},
    'Investment': {'color': Colors.blueAccent, 'icon': Icons.trending_up},
  };

  @override
  void initState() {
    super.initState();
    _analyticsData = _fetchAnalyticsData();
  }

  // Modified to fetch real data
  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    // Get current month's start and end dates
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59); // Last day of the current month

    // Fetch all transactions and then filter in-app
    final allTransactions = await _firestoreService.getTransactions(widget.user.uid).first;

    // Filter for expenses within the current month
    final currentMonthExpenses = allTransactions.where((t) {
      return t.type == TransactionType.expense &&
             t.date.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) &&
             t.date.isBefore(endOfMonth.add(const Duration(milliseconds: 1)));
    }).toList();

    double totalSpending = 0.0;
    final Map<String, double> spendingMap = {};

    for (var transaction in currentMonthExpenses) {
      totalSpending += transaction.amount;
      spendingMap.update(transaction.category, (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount);
    }

    // Convert spending map to List<CategorySpending>
    final List<CategorySpending> spendingByCategory = spendingMap.entries.map((entry) {
      final categoryName = entry.key;
      final amount = entry.value;
      final visuals = _categoryVisuals[categoryName] ?? _categoryVisuals['Other']!; // Use 'Other' if not mapped
      return CategorySpending(
        categoryName,
        amount,
        visuals['color'] as Color,
        visuals['icon'] as IconData,
      );
    }).toList();

    // Sort by amount descending
    spendingByCategory.sort((a, b) => b.amount.compareTo(a.amount));

    return {
      "totalSpending": totalSpending,
      "spendingByCategory": spendingByCategory,
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
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!['totalSpending'] == 0) { // Check if total spending is 0
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("No spending data for this month.", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text("Add transactions to see your analytics!", style: GoogleFonts.poppins(color: Colors.grey.shade500)),
              ],
            ),
          );
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
              // Only show pie chart if there's spending by category to display
              if (spendingByCategory.isNotEmpty) ...[
                _buildSpendingPieChartCard(spendingByCategory, totalSpending),
                const SizedBox(height: 24),
                _buildCategoryListCard(spendingByCategory, totalSpending),
              ] else ...[
                 const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No categorized spending to display.", style: TextStyle(color: Colors.grey)),
                  ),
                 ),
              ],
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
    final percentage = totalSpending > 0 ? (category.amount / totalSpending) : 0.0; // Prevent division by zero
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