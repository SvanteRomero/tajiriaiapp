import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_tx;

/// Data model for category-based financial analysis
class CategoryData {
  final String category;
  final double value;
  final Color color;
  CategoryData({
    required this.category, 
    required this.value, 
    required this.color
  });
}

/// Analytics screen displays financial insights and visualizations
class Analytics extends StatelessWidget {
  final User user;
  final _currencyFormat = NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);
  
  Analytics({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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

            final topExpenses = _topCategories(txs, isIncome: false);
            final topIncomes = _topCategories(txs, isIncome: true);
            final dailyData = _aggregateByDayOfWeek(txs);
            final monthlyData = _aggregateByMonth(txs);
            final weeklySavings = _calculateWeeklySavings(txs);
            final monthlySavings = _calculateMonthlySavings(txs);
            final spendingTrends = _analyzeSpendingTrends(txs);

            return CustomScrollView(
              slivers: [
                // Summary Cards
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCards(txs),
                      ],
                    ),
                  ),
                ),

                // Spending Trends
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Trends',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTrendAnalysis(spendingTrends),
                      ],
                    ),
                  ),
                ),

                // Monthly Overview Chart
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Overview',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildMonthlyChart(monthlyData),
                        ),
                      ],
                    ),
                  ),
                ),

                // Weekly Analysis
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Analysis',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildWeeklyChart(dailyData),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Breakdown
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Breakdown',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCategoryChart(
                                'Expenses',
                                topExpenses,
                                Colors.red.shade400,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCategoryChart(
                                'Income',
                                topIncomes,
                                Colors.green.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Savings Goals
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSavingsCard(
                          'Weekly Target',
                          weeklySavings['saved']!,
                          weeklySavings['target']!,
                          Colors.blue.shade700,
                        ),
                        const SizedBox(height: 12),
                        _buildSavingsCard(
                          'Monthly Target',
                          monthlySavings['saved']!,
                          monthlySavings['target']!,
                          Colors.indigo.shade700,
                        ),
                      ],
                    ),
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

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Income',
            _currencyFormat.format(totalIncome),
            Icons.arrow_upward,
            Colors.green.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Total Expense',
            _currencyFormat.format(totalExpense),
            Icons.arrow_downward,
            Colors.red.shade400,
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, double>> dailyData) {
    return LineChart(
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
                dailyData[index]['income'] ?? 0.0,
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
                dailyData[index]['expense'] ?? 0.0,
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
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade900,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(List<Map<String, double>> monthlyData) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: monthlyData.fold(0.0, (max, data) => 
          math.max(max, math.max(data['income'] ?? 0, data['expense'] ?? 0))
        ) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade900,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                _currencyFormat.format(rod.toY),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart(String title, List<CategoryData> data, Color baseColor) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final total = data.fold(0.0, (sum, item) => sum + item.value);
                      return PieChartSectionData(
                        color: baseColor.withOpacity(1 - (index * 0.2)),
                        value: item.value,
                        title: '${(item.value / total * 100).toStringAsFixed(1)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(1 - (index * 0.2)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.category,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(item.value),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsCard(
    String title,
    double saved,
    double target,
    Color color,
  ) {
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(saved),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(target),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis(Map<String, dynamic> trends) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trends['trend'] == 'up'
                      ? Icons.trending_up
                      : trends['trend'] == 'down'
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  color: trends['trend'] == 'up'
                      ? Colors.red.shade400
                      : trends['trend'] == 'down'
                          ? Colors.green.shade400
                          : Colors.blue.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spending Trend',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              trends['message'],
              style: const TextStyle(fontSize: 14),
            ),
            if (trends['recommendations'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...trends['recommendations'].map<Widget>((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
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

  List<CategoryData> _topCategories(
    List<my_tx.Transaction> txs, {
    required bool isIncome,
    int topN = 5,
  }) {
    final Map<String, double> totals = {};
    for (var tx in txs.where(
      (t) => (isIncome && t.type == my_tx.TransactionType.income) ||
          (!isIncome && t.type == my_tx.TransactionType.expense),
    )) {
      totals[tx.description] = (totals[tx.description] ?? 0) + tx.amount;
    }
    
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted
        .take(topN)
        .map((e) => CategoryData(
          category: e.key,
          value: e.value,
          color: isIncome ? Colors.green.shade400 : Colors.red.shade400,
        ))
        .toList();
  }

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

    const weeklyTarget = 50000.0;
    return {'saved': income - expenses, 'target': weeklyTarget};
  }

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

    const monthlyTarget = 200000.0;
    return {'saved': income - expenses, 'target': monthlyTarget};
  }

  double _calculateAverageDailySpending(List<my_tx.Transaction> txs) {
    if (txs.isEmpty) return 0.0;
    
    final expenses = txs
        .where((tx) => tx.type == my_tx.TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    
    return expenses / txs.length;
  }

  Map<String, dynamic> _analyzeSpendingTrends(List<my_tx.Transaction> txs) {
    // Sort transactions by date
    final sortedTxs = List<my_tx.Transaction>.from(txs)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedTxs.length < 2) {
      return {
        'trend': 'neutral',
        'message': 'Not enough data to analyze spending trends.',
      };
    }

    // Calculate average daily spending for first and last week
    final firstWeekSpending = _calculateAverageDailySpending(
      sortedTxs.take(7).toList(),
    );
    final lastWeekSpending = _calculateAverageDailySpending(
      sortedTxs.skip(sortedTxs.length - 7).toList(),
    );

    final percentageChange = ((lastWeekSpending - firstWeekSpending) / 
                            firstWeekSpending * 100).abs();

    String trend;
    String message;
    List<String> recommendations = [];

    if (lastWeekSpending > firstWeekSpending * 1.1) {
      trend = 'up';
      message = 'Your spending has increased by ${percentageChange.toStringAsFixed(1)}% '
               'compared to your usual pattern.';
      recommendations = [
        'Review your recent expenses to identify non-essential spending',
        'Consider setting up category-specific budgets',
        'Look for areas where you can reduce discretionary spending',
        'Try to maintain your previous spending levels to improve savings',
      ];
    } else if (lastWeekSpending < firstWeekSpending * 0.9) {
      trend = 'down';
      message = 'Your spending has decreased by ${percentageChange.toStringAsFixed(1)}% '
               'compared to your usual pattern. Great job!';
      recommendations = [
        'Consider allocating the extra savings towards your financial goals',
        'Maintain these positive spending habits',
        'Look for additional ways to optimize your regular expenses',
      ];
    } else {
      trend = 'neutral';
      message = 'Your spending pattern has remained stable.';
      recommendations = [
        'Continue monitoring your expenses regularly',
        'Look for opportunities to optimize your spending',
        'Consider setting more ambitious savings goals',
      ];
    }

    return {
      'trend': trend,
      'message': message,
      'recommendations': recommendations,
    };
