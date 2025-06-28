// lib/screens/analytics.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/core/models/account_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';
import 'package:tajiri_ai/core/models/transaction_model.dart';
import 'package:tajiri_ai/core/models/user_category_model.dart';

class CategoryData {
  final String category;
  final double amount;
  final Color color;
  final IconData icon;
  final String currency;

  CategoryData(this.category, this.amount, this.color, this.icon, this.currency);
}

class MonthlyAnalytics {
  final double income;
  final double expense;
  final String month;

  MonthlyAnalytics({required this.income, required this.expense, required this.month});
}

enum DateRange { last7Days, last30Days, last90Days, allTime }

extension DateRangeExtension on DateRange {
  String get displayName {
    switch (this) {
      case DateRange.last7Days:
        return 'Last 7 Days';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.last90Days:
        return 'Last 90 Days';
      case DateRange.allTime:
        return 'All Time';
    }
  }
}

class AnalyticsPage extends StatefulWidget {
  final User user;
  const AnalyticsPage({super.key, required this.user});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late Future<Map<String, dynamic>> _analyticsData;
  final FirestoreService _firestoreService = FirestoreService();
  DateRange _selectedDateRange = DateRange.last30Days;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _analyticsData = _fetchAnalyticsData();
    Connectivity().checkConnectivity().then(_updateConnectionStatus);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResult) {
    if (!mounted) return;
    setState(() {
      _isOffline = connectivityResult.contains(ConnectivityResult.none);
    });
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedDateRange) {
        case DateRange.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case DateRange.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case DateRange.last90Days:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case DateRange.allTime:
          startDate = DateTime(2000);
          break;
      }

      final allTransactions = (await _firestoreService.getTransactions(widget.user.uid).first)
          .where((t) => t.date.isAfter(startDate))
          .toList();
      final userCategories = await _firestoreService.getUserCategories(widget.user.uid).first;
      final accounts = await _firestoreService.getAccounts(widget.user.uid).first;
      final Map<String, UserCategory> categoryMap = {for (var cat in userCategories) cat.name: cat};
      final Map<String, Account> accountMap = {for (var acc in accounts) acc.id: acc};

      // Monthly analytics for the last 6 months
      final monthlyAnalytics = <String, MonthlyAnalytics>{};
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormat('MMM').format(monthDate);
        monthlyAnalytics[monthKey] = MonthlyAnalytics(income: 0, expense: 0, month: monthKey);
      }

      // Filter transactions for the last 6 months for monthly analytics
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final monthlyTransactions = allTransactions.where((t) => t.date.isAfter(sixMonthsAgo.subtract(const Duration(days: 1)))).toList();

      for (var transaction in monthlyTransactions) {
        final monthKey = DateFormat('MMM').format(transaction.date);
        if (monthlyAnalytics.containsKey(monthKey)) {
          final currentAnalytics = monthlyAnalytics[monthKey]!;
          if (transaction.type == TransactionType.income) {
            monthlyAnalytics[monthKey] = MonthlyAnalytics(
              income: currentAnalytics.income + transaction.amount,
              expense: currentAnalytics.expense,
              month: monthKey,
            );
          } else {
            monthlyAnalytics[monthKey] = MonthlyAnalytics(
              income: currentAnalytics.income,
              expense: currentAnalytics.expense + transaction.amount,
              month: monthKey,
            );
          }
        }
      }

      // Current period's data (based on selected date range)
      final currentPeriodTransactions = allTransactions;

      // Expenses
      final currentPeriodExpenses = currentPeriodTransactions.where((t) => t.type == TransactionType.expense).toList();
      double totalSpending = 0.0;
      final Map<String, double> spendingMap = {};
      for (var transaction in currentPeriodExpenses) {
        totalSpending += transaction.amount;
        spendingMap.update(transaction.category, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
      }
      final List<CategoryData> spendingByCategory = spendingMap.entries.map((entry) {
        final categoryName = entry.key;
        final amount = entry.value;
        final UserCategory? customCategory = categoryMap[categoryName];
        final Color categoryColor = customCategory?.color ?? Colors.grey;
        final IconData categoryIcon = customCategory?.icon ?? Icons.category;
        final account = accountMap[currentPeriodExpenses.firstWhere((t) => t.category == categoryName).accountId];
        final currency = account?.currency ?? '\$';
        return CategoryData(categoryName, amount, categoryColor, categoryIcon, currency);
      }).toList();
      spendingByCategory.sort((a, b) => b.amount.compareTo(a.amount));

      // Income
      final currentPeriodIncome = currentPeriodTransactions.where((t) => t.type == TransactionType.income).toList();
      double totalIncome = 0.0;
      final Map<String, double> incomeMap = {};
      for (var transaction in currentPeriodIncome) {
        totalIncome += transaction.amount;
        incomeMap.update(transaction.category, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
      }
      final List<CategoryData> incomeByCategory = incomeMap.entries.map((entry) {
        final categoryName = entry.key;
        final amount = entry.value;
        final UserCategory? customCategory = categoryMap[categoryName];
        final Color categoryColor = customCategory?.color ?? Colors.grey;
        final IconData categoryIcon = customCategory?.icon ?? Icons.category;
        final account = accountMap[currentPeriodIncome.firstWhere((t) => t.category == categoryName).accountId];
        final currency = account?.currency ?? '\$';
        return CategoryData(categoryName, amount, categoryColor, categoryIcon, currency);
      }).toList();
      incomeByCategory.sort((a, b) => b.amount.compareTo(a.amount));

      return {
        "totalSpending": totalSpending,
        "spendingByCategory": spendingByCategory,
        "totalIncome": totalIncome,
        "incomeByCategory": incomeByCategory,
        "monthlyAnalytics": monthlyAnalytics.values.toList(),
        "accounts": accounts,
      };
    } catch (e) {
      print('Error fetching analytics data: $e');
      rethrow;
    }
  }

  String _getPeriodTitle() {
    switch (_selectedDateRange) {
      case DateRange.last7Days:
        return 'Last 7 Days';
      case DateRange.last30Days:
        return 'This Month';
      case DateRange.last90Days:
        return 'Last 3 Months';
      case DateRange.allTime:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<DateRange>(
            value: _selectedDateRange,
            onChanged: (DateRange? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDateRange = newValue;
                  _analyticsData = _fetchAnalyticsData();
                });
              }
            },
            items: DateRange.values.map((DateRange range) {
              return DropdownMenuItem<DateRange>(
                value: range,
                child: Text(range.displayName),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _analyticsData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text("Error loading analytics", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text("${snapshot.error}", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || (snapshot.data!['totalSpending'] == 0 && snapshot.data!['totalIncome'] == 0)) {
                if (_isOffline) {
                   return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded,
                                size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text("You are Offline",
                                style: GoogleFonts.poppins(
                                    fontSize: 18, color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text(
                              "Your analytics will appear here once you're back online.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("No financial data for this period.", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text("Add transactions to see your analytics!", style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;
              final totalSpending = data['totalSpending'] as double;
              final totalIncome = data['totalIncome'] as double;
              final spendingByCategory = data['spendingByCategory'] as List<CategoryData>;
              final incomeByCategory = data['incomeByCategory'] as List<CategoryData>;
              final monthlyAnalytics = data['monthlyAnalytics'] as List<MonthlyAnalytics>;
              final accounts = data['accounts'] as List<Account>;
              final currencySymbol = accounts.isNotEmpty ? accounts.first.currency : '\$';

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _analyticsData = _fetchAnalyticsData();
                  });
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSummaryCard(totalSpending, totalIncome, currencySymbol),
                    const SizedBox(height: 24),
                    if (monthlyAnalytics.isNotEmpty && monthlyAnalytics.any((m) => m.income > 0 || m.expense > 0)) ...[
                      _buildIncomeExpenditureBarChart(monthlyAnalytics),
                      const SizedBox(height: 24),
                    ],
                    if (totalSpending > 0 && spendingByCategory.isNotEmpty) ...[
                      _buildPieChartCard(spendingByCategory, totalSpending, "Spending Breakdown"),
                      const SizedBox(height: 24),
                      _buildCategoryListCard(spendingByCategory, totalSpending, "Spending Details By Category"),
                      const SizedBox(height: 24),
                    ],
                    if (totalIncome > 0 && incomeByCategory.isNotEmpty) ...[
                      _buildPieChartCard(incomeByCategory, totalIncome, "Income Breakdown"),
                      const SizedBox(height: 24),
                      _buildCategoryListCard(incomeByCategory, totalIncome, "Income Details By Category"),
                    ],
                    if (totalSpending == 0 && totalIncome == 0) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No transactions to display for this period.", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double totalSpending, double totalIncome, String currencySymbol) {
    final periodTitle = _getPeriodTitle();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade500, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Spending - $periodTitle",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: currencySymbol).format(totalSpending),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Total Income - $periodTitle",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: currencySymbol).format(totalIncome),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(List<CategoryData> categories, double total, String title) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
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
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [const Shadow(blurRadius: 2, color: Colors.black26)],
                    ),
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

  Widget _buildCategoryListCard(List<CategoryData> categories, double total, String title) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...categories.map((cat) => _buildCategoryListItem(cat, total)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(CategoryData category, double total) {
    final percentage = total > 0 ? (category.amount / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: category.color.withOpacity(0.15),
            child: Icon(category.icon, color: category.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.category,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormat.currency(symbol: category.currency).format(category.amount),
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${(percentage * 100).toStringAsFixed(1)}%",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenditureBarChart(List<MonthlyAnalytics> monthlyAnalytics) {
    // Calculate max value for better chart scaling
    double maxValue = 0;
    for (var data in monthlyAnalytics) {
      if (data.income > maxValue) maxValue = data.income;
      if (data.expense > maxValue) maxValue = data.expense;
    }
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Monthly Summary (Last 6 Months)",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.grey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (group.x.toInt() >= monthlyAnalytics.length) return null;
                        final monthlyData = monthlyAnalytics[group.x.toInt()];
                        String text;
                        if (rodIndex == 0) {
                          text = 'Income: \$${monthlyData.income.toStringAsFixed(2)}';
                        } else {
                          text = 'Expense: \$${monthlyData.expense.toStringAsFixed(2)}';
                        }
                        return BarTooltipItem(
                          text,
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthlyAnalytics.length) {
                            return const SizedBox.shrink();
                          }
                          const style = TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(monthlyAnalytics[index].month, style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyAnalytics.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.income,
                          color: Colors.green,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: data.expense,
                          color: Colors.red,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                      barsSpace: 4,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Income', style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(width: 24),
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Expense', style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}