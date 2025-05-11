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
      body: StreamBuilder<QuerySnapshot>(
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
              pageIconData: Icons.waterfall_chart,
              pageTitle: 'Analytics Unavailable',
              pageDescription: 'Add your financial details to get your statistics',
            );
          }
          final txs = snapshot.data!.docs.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            return my_tx.Transaction(
              username: data['username'] as String,
              description: data['description'] as String,
              amount: (data['amount'] as num).toDouble(),
              date: (data['date'] as Timestamp).toDate(),
              type: data['type'] == 'income'
                  ? my_tx.TransactionType.income
                  : my_tx.TransactionType.expense,
            );
          }).toList();
          final incomeData = _aggregateByMonth(txs, isIncome: true);
          final expenseData = _aggregateByMonth(txs, isIncome: false);
          final topExpenses = _topCategories(txs, isIncome: false);
          final topIncomes = _topCategories(txs, isIncome: true);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _metricCard('Top Expense', topExpenses)),
                    const SizedBox(width: 16),
                    Expanded(child: _metricCard('Top Income', topIncomes)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Monthly Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    legend: Legend(isVisible: true),
                    series: <LineSeries<MonthData, String>>[
                      LineSeries<MonthData, String>(
                        name: 'Income',
                        dataSource: incomeData,
                        xValueMapper: (d, _) => d.month,
                        yValueMapper: (d, _) => d.total,
                      ),
                      LineSeries<MonthData, String>(
                        name: 'Expense',
                        dataSource: expenseData,
                        xValueMapper: (d, _) => d.month,
                        yValueMapper: (d, _) => d.total,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: SfCircularChart(
                    legend: Legend(isVisible: true),
                    series: <PieSeries<CategoryData, String>>[
                      PieSeries<CategoryData, String>(
                        dataSource: topExpenses,
                        xValueMapper: (d, _) => d.category,
                        yValueMapper: (d, _) => d.value,
                        dataLabelSettings: const DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Income Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: SfCircularChart(
                    legend: Legend(isVisible: true),
                    series: <PieSeries<CategoryData, String>>[
                      PieSeries<CategoryData, String>(
                        dataSource: topIncomes,
                        xValueMapper: (d, _) => d.category,
                        yValueMapper: (d, _) => d.value,
                        dataLabelSettings: const DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, List<CategoryData> list) {
    final value = list.isNotEmpty ? list.first.value.toStringAsFixed(2) : '0.00';
    final label = list.isNotEmpty ? list.first.category : 'N/A';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text('\\$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label),
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
    final list = totals.entries
        .map((e) => MonthData(month: e.key, total: e.value))
        .toList();
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
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topN).map((e) => CategoryData(category: e.key, value: e.value)).toList();
  }
}
