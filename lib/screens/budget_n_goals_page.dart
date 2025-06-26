// lib/screens/my_goals_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tajiri_ai/core/models/budget_model.dart';
import 'package:tajiri_ai/core/models/goal_model.dart';
import 'package:tajiri_ai/core/models/transaction_model.dart';
import 'package:tajiri_ai/core/models/user_category_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';
import 'package:tajiri_ai/core/utils/snackbar_utils.dart';
import 'package:tajiri_ai/screens/add_budget_page.dart';
import 'package:tajiri_ai/screens/add_goal_page.dart';
import 'package:tajiri_ai/screens/goal_details_page.dart';

class MyGoalsPage extends StatefulWidget {
  final User user;
  const MyGoalsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<MyGoalsPage> createState() => _MyGoalsPageState();
}

class _MyGoalsPageState extends State<MyGoalsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _reactivateGoal(Goal goal) async {
    final reactivatedGoal = Goal(
      id: goal.id,
      goalName: goal.goalName,
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      startDate: goal.startDate,
      endDate: goal.endDate,
      dailyLimit: goal.dailyLimit,
      timezone: goal.timezone,
      status: GoalStatus.active,
      goalVersion: goal.goalVersion,
      streakCount: goal.streakCount,
      graceDaysUsed: goal.graceDaysUsed,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
      abandonedAt: null,
    );
    await _firestoreService.updateGoal(widget.user.uid, reactivatedGoal);
    showCustomSnackbar(context, 'Goal reactivated!');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: CombineLatestStream.list([
        _firestoreService.getGoals(widget.user.uid),
        _firestoreService.getBudgets(widget.user.uid),
        _firestoreService.getTransactions(widget.user.uid),
        _firestoreService.getUserCategories(widget.user.uid),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("No data available."));
        }

        final goals = snapshot.data![0] as List<Goal>;
        final budgets = snapshot.data![1] as List<Budget>;
        final transactions = snapshot.data![2] as List<TransactionModel>;
        final categories = snapshot.data![3] as List<UserCategory>;

        final activeGoals =
            goals.where((goal) => goal.status == GoalStatus.active).toList();
        final abandonedGoals =
            goals.where((goal) => goal.status == GoalStatus.abandoned).toList();
        final historicalGoals = goals
            .where((goal) =>
                goal.status != GoalStatus.active &&
                goal.status != GoalStatus.abandoned)
            .toList();
        final hasActiveGoal = activeGoals.isNotEmpty;

        if (goals.isEmpty && budgets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No financial goals or budgets set yet.",
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text("Tap a button below to get started!",
                      style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AddGoalPage(user: widget.user)));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        "Add New Goal",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AddBudgetPage(user: widget.user)));
                      },
                      icon: const Icon(Icons.add_chart),
                      label: Text(
                        "Add New Budget",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (activeGoals.isNotEmpty) ...[
              Text("Active Goal",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...activeGoals.map((goal) => _buildGoalCard(context, goal)).toList(),
              const SizedBox(height: 24),
            ],
            if (budgets.isNotEmpty) ...[
              Text("This Month's Budgets",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...budgets
                  .map((budget) =>
                      _buildBudgetCard(context, budget, transactions, categories))
                  .toList(),
              const SizedBox(height: 24),
            ],
            if (abandonedGoals.isNotEmpty) ...[
              Text("Abandoned Goals",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...abandonedGoals
                  .map((goal) => _buildAbandonedGoalCard(context, goal))
                  .toList(),
              const SizedBox(height: 24),
            ],
            if (!hasActiveGoal)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddGoalPage(user: widget.user)));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Goal"),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddBudgetPage(user: widget.user)));
                },
                icon: const Icon(Icons.add_chart),
                label: const Text("Add New Budget"),
              ),
            ),
            if (historicalGoals.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text("Goal History",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...historicalGoals
                  .map((goal) => _buildGoalCard(context, goal))
                  .toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget,
      List<TransactionModel> transactions, List<UserCategory> categories) {
    final category = categories.firstWhere(
      (cat) => cat.name == budget.category,
      orElse: () =>
          UserCategory(name: '', type: TransactionType.expense), // Fallback
    );
    final categoryColor = category.id != null ? category.color : Colors.deepPurple;

    final spent = transactions
        .where((t) =>
            t.category == budget.category &&
            t.type == TransactionType.expense &&
            t.date.month == DateTime.now().month &&
            t.date.year == DateTime.now().year)
        .fold(0.0, (prev, e) => prev + e.amount);

    final progress = budget.amount > 0 ? spent / budget.amount : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  AddBudgetPage(user: widget.user, budget: budget)));
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(budget.category,
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: categoryColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 1 ? Colors.red : categoryColor),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "Spent: ${NumberFormat.currency(symbol: '\$').format(spent)} / ${NumberFormat.currency(symbol: '\$').format(budget.amount)}",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey.shade700)),
                  Text("${(progress * 100).toStringAsFixed(1)}%",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: progress > 1 ? Colors.red : categoryColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbandonedGoalCard(BuildContext context, Goal goal) {
    return Card(
      color: Colors.grey.shade300,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.goalName,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text("This goal was abandoned. It will be deleted in 3 days.",
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _reactivateGoal(goal),
                icon: const Icon(Icons.refresh),
                label: const Text("Reactivate Goal"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final progress =
        goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0.0;
    final progressPercentage = (progress * 100).toStringAsFixed(1);
    final remainingDays = goal.endDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GoalDetailsPage(user: widget.user, goal: goal)));
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.goalName,
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "Progress: ${NumberFormat.currency(symbol: '\$').format(goal.savedAmount)} / ${NumberFormat.currency(symbol: '\$').format(goal.targetAmount)}",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey.shade700)),
                  Text("$progressPercentage%",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  "Deadline: ${DateFormat.yMMMd().format(goal.endDate)} (${remainingDays > 0 ? '$remainingDays days left' : 'Expired'})",
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}