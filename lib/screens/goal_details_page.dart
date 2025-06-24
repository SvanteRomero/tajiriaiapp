// lib/screens/goal_details_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/core/models/goal_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';

// Daily Log model for subcollection
class DailyLog {
  final DateTime date;
  final double spentAmount;
  final double savedAmount;
  final String status;
  final String comment;

  DailyLog({
    required this.date,
    required this.spentAmount,
    required this.savedAmount,
    required this.status,
    required this.comment,
  });

  factory DailyLog.fromFirestore(Map<String, dynamic> data) {
    return DailyLog(
      date: (data['date'] as Timestamp).toDate(),
      spentAmount: (data['spent_amount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (data['saved_amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'unknown',
      comment: data['comment'] ?? '',
    );
  }
}

class GoalDetailsPage extends StatefulWidget {
  final User user;
  final Goal goal;
  const GoalDetailsPage({Key? key, required this.user, required this.goal}) : super(key: key);

  @override
  State<GoalDetailsPage> createState() => _GoalDetailsPageState();
}

class _GoalDetailsPageState extends State<GoalDetailsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Goal _currentGoal;

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentGoal.savedAmount / _currentGoal.targetAmount;
    final progressPercentage = (progress * 100).toStringAsFixed(1);
    final remainingDays = _currentGoal.endDate.difference(DateTime.now()).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentGoal.goalName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalSummaryCard(progress, progressPercentage, remainingDays),
            const SizedBox(height: 24),
            _buildGoalDetails(),
            const SizedBox(height: 24),
            Text("Daily Log", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _buildDailyLogList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSummaryCard(double progress, String progressPercentage, int remainingDays) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [Colors.green.shade500, Colors.green.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Current Progress", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(NumberFormat.currency(symbol: '\$').format(_currentGoal.savedAmount),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Target: ${NumberFormat.currency(symbol: '\$').format(_currentGoal.targetAmount)}",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              Text("$progressPercentage%", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Days Left: ${remainingDays > 0 ? remainingDays : 'Goal Ended'}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGoalDetails() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Goal Details", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _buildDetailRow("Daily Limit:", NumberFormat.currency(symbol: '\$').format(_currentGoal.dailyLimit)),
            _buildDetailRow("Start Date:", DateFormat.yMMMd().format(_currentGoal.startDate)),
            _buildDetailRow("End Date:", DateFormat.yMMMd().format(_currentGoal.endDate)),
            _buildDetailRow("Current Streak:", "${_currentGoal.streakCount} days"),
            _buildDetailRow("Grace Days Used:", "${_currentGoal.graceDaysUsed}"),
            _buildDetailRow("Status:", _currentGoal.status.name.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade700)),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDailyLogList() {
    return StreamBuilder<List<DailyLog>>(
      stream: _firestoreService.getDailyLogs(widget.user.uid, _currentGoal.id), // You'll need to add this method to FirestoreService
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No daily logs available yet."));
        }

        final dailyLogs = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // To prevent nested scrolling
          itemCount: dailyLogs.length,
          itemBuilder: (context, index) {
            final log = dailyLogs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: log.status == 'success' ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(log.status == 'success' ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: log.status == 'success' ? Colors.green : Colors.red),
                ),
                title: Text(DateFormat.yMMMd().format(log.date)),
                subtitle: Text(log.comment),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Spent: \$${log.spentAmount.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 13)),
                    Text("Saved: \$${log.savedAmount.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 13, color: Colors.green)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}