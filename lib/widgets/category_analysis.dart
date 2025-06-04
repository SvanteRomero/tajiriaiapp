import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/hive/transaction_model.dart';
import 'package:intl/intl.dart';

class CategoryAnalysis extends StatelessWidget {
  final List<HiveTransaction> transactions;
  final bool isIncome;
  final _currencyFormat = NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);

  CategoryAnalysis({
    Key? key,
    required this.transactions,
    required this.isIncome,
  }) : super(key: key);

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> totals = {};
    
    for (var tx in transactions.where((t) => 
      (isIncome && t.type == 'income') || (!isIncome && t.type == 'expense'))) {
      totals[tx.mainCategory] = (totals[tx.mainCategory] ?? 0) + tx.amount;
    }
    
    return Map.fromEntries(
      totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  Map<String, Map<String, double>> _calculateSubcategoryTotals() {
    final Map<String, Map<String, double>> totals = {};
    
    for (var tx in transactions.where((t) => 
      (isIncome && t.type == 'income') || (!isIncome && t.type == 'expense'))) {
      totals[tx.mainCategory] ??= {};
      totals[tx.mainCategory]![tx.subCategory] = 
        (totals[tx.mainCategory]![tx.subCategory] ?? 0) + tx.amount;
    }
    
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _calculateCategoryTotals();
    final subcategoryTotals = _calculateSubcategoryTotals();
    final baseColor = isIncome ? Colors.green : Colors.red;
    final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    if (categoryTotals.isEmpty) {
      return Center(
        child: Text(
          'No ${isIncome ? 'income' : 'expense'} data available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      children: [
        // Pie Chart
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: categoryTotals.entries.map((entry) {
                final index = categoryTotals.keys.toList().indexOf(entry.key);
                final percentage = (entry.value / total * 100);
                
                return PieChartSectionData(
                  color: baseColor.withOpacity(1 - (index * 0.1)),
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 100,
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

        // Category List
        ...categoryTotals.entries.map((entry) {
          final index = categoryTotals.keys.toList().indexOf(entry.key);
          final subcategories = subcategoryTotals[entry.key] ?? {};
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Category
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(1 - (index * 0.1)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _currencyFormat.format(entry.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subcategories
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  children: subcategories.entries.map((sub) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sub.key,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            _currencyFormat.format(sub.value),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
            ],
          );
        }).toList(),
      ],
    );
  }
}
