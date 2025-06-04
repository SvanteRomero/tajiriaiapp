/// A comprehensive analytics page that visualizes financial data through various charts
/// and metrics. This page provides insights into spending patterns, savings progress,
/// and financial trends using interactive charts and styled cards.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_tx;

/// Data structure for category-based financial analysis.
/// Used for pie charts and category breakdowns.
class CategoryData {
  final String category;
  final double value;
  CategoryData({required this.category, required this.value});
}

/// Analytics widget that displays financial insights and visualizations.
/// Requires an authenticated user to fetch and display data.
class Analytics extends StatelessWidget {
  final User user;
  const Analytics({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // Real-time stream of user's transactions from Firestore
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const EmptyPage(
                pageIconData: Icons.bar_chart,
                pageTitle: 'No Data Yet',
                pageDescription: 'Add transactions to see analytics',
              );
            }

            // Transform Firestore documents into Transaction objects
            final txs = snapshot.data!.docs.map((doc) {
              final d = doc.data()! as Map<String, dynamic>;
              return my_tx.Transaction(
                username: d['username'],
                description: d['description'],
                amount: (d['amount'] as num).toDouble(),
                date: (d['date'] as Timestamp).toDate(),
                type: d['type'] == 'income'
                    ? my_tx.TransactionType.income
                    : my_tx.TransactionType.expense,
              );
            }).toList();

            // Calculate various analytics metrics
            final topExpenses = _topCategories(txs, isIncome: false);
            final topIncomes = _topCategories(txs, isIncome: true);
            final dailyData = _aggregateByDayOfWeek(txs);
            final weeklySavings = _calculateWeeklySavings(txs);
            final monthlySavings = _calculateMonthlySavings(txs);

            return CustomScrollView(
              slivers: [
                // Top metrics grid (Top Expense and Income)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildListDelegate([
                      _styledMetricCard(
                        'Top Expense',
                        topExpenses.isNotEmpty
                            ? topExpenses.first.value.toStringAsFixed(2)
                            : '0.00',
                        topExpenses.isNotEmpty
                            ? topExpenses.first.category
                            : 'N/A',
                        Colors.red,
                      ),
                      _styledMetricCard(
                        'Top Income',
                        topIncomes.isNotEmpty
                            ? topIncomes.first.value.toStringAsFixed(2)
                            : '0.00',
                        topIncomes.isNotEmpty
                            ? topIncomes.first.category
                            : 'N/A',
                        Colors.green,
                      ),
                    ]),
                  ),
                ),

                // Savings overview section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Overview',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSavingsCard(
                          'Weekly Savings',
                          weeklySavings['saved'] ?? 0.0,
                          weeklySavings['target'] ?? 0.0,
                          const Color(0xFF1976D2),
                        ),
                        const SizedBox(height: 12),
                        _buildSavingsCard(
                          'Monthly Savings',
                          monthlySavings['saved'] ?? 0.0,
                          monthlySavings['target'] ?? 0.0,
                          const Color(0xFF1976D2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Weekly trends chart section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Text(
                      'Weekly Trends',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Text(
                                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                      [value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Income trend line
                            LineChartBarData(
                              spots: List.generate(
                                7,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  (dailyData[index]['income'] ?? 0.0),
                                ),
                              ),
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                            // Expense trend line
                            LineChartBarData(
                              spots: List.generate(
                                7,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  (dailyData[index]['expense'] ?? 0.0),
                                ),
                              ),
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Category breakdown section with pie charts
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Text(
                      'Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildListDelegate([
                      _styledChartCard(
                        'Expenses',
                        topExpenses,
                        isExpense: true,
                      ),
                      _styledChartCard('Incomes', topIncomes, isExpense: false),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Creates a styled card for displaying key metrics with gradient background
  /// and formatted values.
  Widget _styledMetricCard(
    String title,
    String value,
    String label,
    Color accent,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.1), Colors.white],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tsh $value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a styled card containing a pie chart for category breakdown.
  /// Different colors are used for income and expense visualizations.
  Widget _styledChartCard(
    String title,
    List<CategoryData> data, {
    required bool isExpense,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: data.map((d) {
                    final color = isExpense ? Colors.red : Colors.green;
                    return PieChartSectionData(
                      value: d.value,
                      title: d.category,
                      color: color.withOpacity(0.7),
                      titleStyle: const TextStyle(fontSize: 11),
                      radius: 50,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aggregates transaction data by day of week.
  /// Returns a list of maps containing income and expense totals for each day.
  List<Map<String, double>> _aggregateByDayOfWeek(List<my_tx.Transaction> txs) {
    final result = List.generate(7, (_) => {'income': 0.0, 'expense': 0.0});
    for (var tx in txs) {
      final weekday = tx.date.weekday - 1;
      if (tx.type == my_tx.TransactionType.income) {
        result[weekday]['income'] = result[weekday]['income']! + tx.amount;
      } else {
        result[weekday]['expense'] = result[weekday]['expense']! + tx.amount;
      }
    }
    return result;
  }

  /// Calculates top categories by transaction amount.
  /// Returns a list of CategoryData objects sorted by value.
  List<CategoryData> _topCategories(
    List<my_tx.Transaction> txs, {
    required bool isIncome,
    int topN = 3,
  }) {
    final Map<String, double> totals = {};
    for (var tx in txs.where(
      (t) =>
          (isIncome && t.type == my_tx.TransactionType.income) ||
          (!isIncome && t.type == my_tx.TransactionType.expense),
    )) {
      totals[tx.description] = (totals[tx.description] ?? 0) + tx.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(topN)
        .map((e) => CategoryData(category: e.key, value: e.value))
        .toList();
  }

  /// Calculates the maximum Y value for the line chart.
  /// Adds padding and rounds up to the nearest thousand.
  double _calculateMaxY(List<Map<String, double>> dailyData) {
    double maxValue = 0;
    for (var day in dailyData) {
      maxValue = maxValue < (day['income'] ?? 0) ? (day['income'] ?? 0) : maxValue;
      maxValue = maxValue < (day['expense'] ?? 0) ? (day['expense'] ?? 0) : maxValue;
    }
    return (maxValue / 1000).ceil() * 1000 + 1000;
  }

  /// Creates a styled card for displaying savings progress with a gradient
  /// background and progress indicator.
  Widget _buildSavingsCard(
    String title,
    double saved,
    double target,
    Color color,
  ) {
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1976D2),
              const Color(0xFF1976D2).withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tsh ${saved.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Target: Tsh ${target.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: Colors.white,
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculates weekly savings metrics.
  /// Returns a map containing saved amount and target.
  Map<String, double> _calculateWeeklySavings(List<my_tx.Transaction> txs) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    double income = 0;
    double expenses = 0;

    for (var tx in txs) {
      if (tx.date.isAfter(startOfWeek) && tx.date.isBefore(endOfWeek)) {
        if (tx.type == my_tx.TransactionType.income) {
          income += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }
    }

    const weeklyTarget = 50000.0; // Example target
    return {'saved': income - expenses, 'target': weeklyTarget};
  }

  /// Calculates monthly savings metrics.
  /// Returns a map containing saved amount and target.
  Map<String, double> _calculateMonthlySavings(List<my_tx.Transaction> txs) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double income = 0;
    double expenses = 0;

    for (var tx in txs) {
      if (tx.date.isAfter(startOfMonth) && tx.date.isBefore(endOfMonth)) {
        if (tx.type == my_tx.TransactionType.income) {
          income += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }
    }

    const monthlyTarget = 200000.0; // Example target
    return {'saved': income - expenses, 'target': monthlyTarget};
  }
}
