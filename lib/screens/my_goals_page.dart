// lib/screens/my_goals_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/core/models/goal_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';
import 'package:tajiri_ai/screens/add_goal_page.dart';
import 'package:tajiri_ai/screens/goal_details_page.dart'; // Import GoalDetailsPage

class MyGoalsPage extends StatefulWidget {
  final User user;
  const MyGoalsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<MyGoalsPage> createState() => _MyGoalsPageState();
}

class _MyGoalsPageState extends State<MyGoalsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    // This page acts as the body content for the HomePage's Scaffold
    return StreamBuilder<List<Goal>>(
      stream: _firestoreService.getGoals(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding( // Added Padding for better appearance in center
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No financial goals set yet.", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text("Tap 'Add New Goal' to get started!", style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                  const SizedBox(height: 30), // Increased space before the button
                  SizedBox( // Make button full width
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AddGoalPage(user: widget.user)));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        "Add New Goal",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), // Slightly larger text
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final goals = snapshot.data!;
        final activeGoals = goals.where((goal) => goal.status == GoalStatus.active).toList();
        final historicalGoals = goals.where((goal) => goal.status != GoalStatus.active).toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (activeGoals.isNotEmpty) ...[
              Text("Active Goal", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...activeGoals.map((goal) => _buildGoalCard(context, goal)).toList(),
              const SizedBox(height: 24),
            ],
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
            if (historicalGoals.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text("Goal History", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...historicalGoals.map((goal) => _buildGoalCard(context, goal)).toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final progress = goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0.0;
    final progressPercentage = (progress * 100).toStringAsFixed(1);
    final remainingDays = goal.endDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        // Tapping the goal card navigates to the GoalDetailsPage
        // where edit and delete functionalities are available.
        onTap: () async {
          final bool? result = await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GoalDetailsPage(user: widget.user, goal: goal)));

          // If GoalDetailsPage was popped with a 'true' result (indicating a change like delete)
          // then trigger a rebuild to refresh the list.
          if (result == true) {
            setState(() {
              // This triggers the StreamBuilder to re-fetch and rebuild the list
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.goalName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Progress: ${NumberFormat.currency(symbol: '\$').format(goal.savedAmount)} / ${NumberFormat.currency(symbol: '\$').format(goal.targetAmount)}",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
                  Text("$progressPercentage%", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                ],
              ),
              const SizedBox(height: 8),
              Text("Deadline: ${DateFormat.yMMMd().format(goal.endDate)} (${remainingDays > 0 ? '$remainingDays days left' : 'Expired'})",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}