import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_tx;
import 'package:tajiri_ai/widgets/category_analysis.dart';

/// Analytics screen displays financial insights and visualizations
class Analytics extends StatefulWidget {
  final User user;
  
  const Analytics({Key? key, required this.user}) : super(key: key);

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
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

            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Income'),
                    Tab(text: 'Expenses'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Overview Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(txs),
                            const SizedBox(height: 24),
                            _buildMonthlyOverview(txs),
                            const SizedBox(height: 24),
                            _buildWeeklyTrends(txs),
                          ],
                        ),
                      ),

                      // Income Categories Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: CategoryAnalysis(
                          transactions: txs,
                          isIncome: true,
                        ),
                      ),

                      // Expense Categories Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: CategoryAnalysis(
                          transactions: txs,
                          isIncome: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<my_tx.Transaction> txs) {
    final totalIncome = txs
        .where((tx) => tx.type == my_tx.TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    
    final totalExpense = txs
        .where((tx) => tx.type == my_tx.TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final balance = totalIncome - totalExpense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Income',
                _currencyFormat.format(totalIncome),
                Icons.arrow_upward,
                Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Expenses',
                _currencyFormat.format(totalExpense),
                Icons.arrow_downward,
                Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Balance',
                _currencyFormat.format(balance),
                Icons.account_balance_wallet,
                Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOverview(List<my_tx.Transaction> txs) {
    final monthlyData = _aggregateByMonth(txs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Overview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: monthlyData.fold(0.0, (max, data) => 
                math.max(max, math.max(data['income'] ?? 0, data['expense'] ?? 0))
              ) * 1.2,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      _currencyFormat.format(value).split(' ')[1],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final month = DateFormat('MMM').format(
                        DateTime(2024, value.toInt() + 1),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          month,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                monthlyData.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: monthlyData[index]['income'] ?? 0,
                      color: Colors.green.shade400,
                      width: 12,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: monthlyData[index]['expense'] ?? 0,
                      color: Colors.red.shade400,
                      width: 12,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrends(List<my_tx.Transaction> txs) {
    final weeklyData = _aggregateByDayOfWeek(txs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Trends',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      _currencyFormat.format(value).split(' ')[1],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt()],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    7,
                    (index) => FlSpot(
                      index.toDouble(),
                      weeklyData[index]['income'] ?? 0.0,
                    ),
                  ),
                  isCurved: true,
                  color: Colors.green.shade400,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.shade400.withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots: List.generate(
                    7,
                    (index) => FlSpot(
                      index.toDouble(),
                      weeklyData[index]['expense'] ?? 0.0,
                    ),
                  ),
                  isCurved: true,
                  color: Colors.red.shade400,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.shade400.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  List<Map<String, double>> _aggregateByMonth(List<my_tx.Transaction> txs) {
    final result = List.generate(12, (_) => {'income': 0.0, 'expense': 0.0});
    for (var tx in txs) {
      final month = tx.date.month - 1;
      if (tx.type == my_tx.TransactionType.income) {
        result[month]['income'] = result[month]['income']! + tx.amount;
      } else {
        result[month]['expense'] = result[month]['expense']! + tx.amount;
      }
    }
    return result;
  }
}
