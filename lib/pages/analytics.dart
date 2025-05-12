import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tajiri_ai/components/empty_page.dart';
import 'package:tajiri_ai/models/transaction.dart' as my_tx;

class MonthData {
  final String month;
  final double total;
  MonthData({required this.month, required this.total});
}

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

            final incomeData = _aggregateByMonth(txs, isIncome: true);
            final expenseData = _aggregateByMonth(txs, isIncome: false);
            final topExpenses = _topCategories(txs, isIncome: false);
            final topIncomes = _topCategories(txs, isIncome: true);

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
                    child: Text('Monthly Trends', style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 250,
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SfCartesianChart(
                          primaryXAxis: CategoryAxis(
                              majorGridLines: const MajorGridLines(width: 0)),
                          primaryYAxis: NumericAxis(
                              axisLine: const AxisLine(width: 0),
                              majorTickLines: const MajorTickLines(size: 0)),
                          legend: Legend(isVisible: true, position: LegendPosition.bottom),
                          series: <LineSeries<MonthData, String>>[
                            LineSeries<MonthData, String>(
                                name: 'Income',
                                color: Colors.green,
                                dataSource: incomeData,
                                xValueMapper: (d, _) => d.month,
                                yValueMapper: (d, _) => d.total),
                            LineSeries<MonthData, String>(
                                name: 'Expense',
                                color: Colors.red,
                                dataSource: expenseData,
                                xValueMapper: (d, _) => d.month,
                                yValueMapper: (d, _) => d.total),
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
              child: SfCircularChart(
                legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                series: <PieSeries<CategoryData, String>>[
                  PieSeries<CategoryData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.category,
                    yValueMapper: (d, _) => d.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MonthData> _aggregateByMonth(List<my_tx.Transaction> txs, {required bool isIncome}) {
    final Map<String, double> totals = {};
    for (var tx in txs.where((t) =>
    (isIncome && t.type == my_tx.TransactionType.income) ||
        (!isIncome && t.type == my_tx.TransactionType.expense))) {
      final label = '${tx.date.month}/${tx.date.year}';
      totals[label] = (totals[label] ?? 0) + tx.amount;
    }
    final list = totals.entries.map((e) => MonthData(month: e.key, total: e.value)).toList();
    list.sort((a, b) => a.month.compareTo(b.month));
    return list;
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
