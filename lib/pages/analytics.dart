import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_tx;

class CategoryData {
  final String category;
  final double value;
  CategoryData({required this.category, required this.value});
}

class Analytics extends StatelessWidget {
  final User user;
  const Analytics({Key? key, required this.user}) : super(key: key);

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

            return CustomScrollView(
              slivers: [
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
                          'Top Expense', topExpenses.isNotEmpty ? topExpenses.first.value.toStringAsFixed(2) : '0.00',
                          topExpenses.isNotEmpty ? topExpenses.first.category : 'N/A', Colors.red),
                      _styledMetricCard(
                          'Top Income', topIncomes.isNotEmpty ? topIncomes.first.value.toStringAsFixed(2) : '0.00',
                          topIncomes.isNotEmpty ? topIncomes.first.category : 'N/A', Colors.green),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Text('Weekly Trends', style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Text(
                                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(7, (index) => FlSpot(index.toDouble(), (dailyData[index]['income'] ?? 0.0))),
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                            LineChartBarData(
                              spots: List.generate(7, (index) => FlSpot(index.toDouble(), (dailyData[index]['expense'] ?? 0.0))),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1),
                    delegate: SliverChildListDelegate([
                      _styledChartCard('Expenses', topExpenses, isExpense: true),
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

  Widget _styledMetricCard(String title, String value, String label, Color accent) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [accent.withOpacity(0.1), Colors.white])),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('Tsh $value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _styledChartCard(String title, List<CategoryData> data, {required bool isExpense}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: data.map((d) {
                    final color = isExpense ? Colors.red : Colors.green;
                    return PieChartSectionData(
                      value: d.value,
                      title: d.category,
                      color: color.withOpacity(0.7),
                      titleStyle: const TextStyle(fontSize: 12),
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

  List<CategoryData> _topCategories(List<my_tx.Transaction> txs, {required bool isIncome, int topN = 3}) {
    final Map<String, double> totals = {};
    for (var tx in txs.where((t) =>
    (isIncome && t.type == my_tx.TransactionType.income) ||
        (!isIncome && t.type == my_tx.TransactionType.expense))) {
      totals[tx.description] = (totals[tx.description] ?? 0) + tx.amount;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topN).map((e) => CategoryData(category: e.key, value: e.value)).toList();
  }
}