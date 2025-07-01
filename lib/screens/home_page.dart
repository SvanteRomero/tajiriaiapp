// lib/screens/home_page.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tajiri_ai/core/models/goal_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';
import '/screens/details/goal_details_page.dart';
import 'advisory.dart';
import 'analytics.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import '/screens/add/add_transaction_page.dart';
import 'budget_n_goals_page.dart';
import '/core/services/notification_service.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static const List<String> _pageTitles = [
    "Dashboard",
    "Analytics",
    "Goals and Budgets",
    "Tajiri Wangu"
  ];
  late final StreamSubscription<String?> _notificationTapSubscription;
  late final StreamSubscription<List<ConnectivityResult>>
      _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    final notificationService = NotificationService();
    final firestoreService = FirestoreService();

    // Schedule the local daily reminder to log expenses
    notificationService.scheduleDailyReminderNotification();

    // Listen for notification taps
    _notificationTapSubscription =
        notificationService.onNotificationTap.stream.listen((payload) async {
      if (!mounted || payload == null) return;

      // --- Handle "Add Transaction" payload ---
      if (payload == 'add_transaction') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddTransactionPage(user: widget.user),
          ),
        );
      }

      // --- Handle "Open Chat" payload ---
      if (payload == 'open_chat') {
        _onItemTapped(3); // Navigate to the Advisory page (index 3)
      }

      // --- Handle "View Goal" payload ---
      if (payload.startsWith('view_goal_')) {
        final goalId = payload.split('_').last;
        try {
          // Fetch the specific goal from Firestore
          final Goal? goal =
              await firestoreService.getGoalById(widget.user.uid, goalId);
          if (goal != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GoalDetailsPage(user: widget.user, goal: goal),
              ),
            );
          }
        } catch (e) {
          print("Error fetching goal for notification: $e");
        }
      }
    });

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((connectivityResult) {
      final isOffline = connectivityResult.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOffline = isOffline;
        });
      }
    });

    // Initial connectivity check
    Connectivity().checkConnectivity().then((connectivityResult) {
       final isOffline = connectivityResult.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOffline = isOffline;
        });
      }
    });
  }


  @override
  void dispose() {
    _notificationTapSubscription.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(user: widget.user),
      AnalyticsPage(user: widget.user),
      MyGoalsPage(user: widget.user),
      AdvisoryPage(user: widget.user),
    ];

    final bool showAddTransactionButton = _selectedIndex != 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_sharp),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ProfilePage(user: widget.user)),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: showAddTransactionButton
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => AddTransactionPage(user: widget.user)),
                );
              },
              backgroundColor: Colors.deepPurple,
              elevation: 4.0,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.dashboard_rounded, "Dashboard", 0),
                  _buildNavItem(Icons.pie_chart_rounded, "Analytics", 1),
                ],
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.flag_rounded, "Goals", 2),
                  _buildNavItem(Icons.model_training_rounded, "AI Advisor", 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return IconButton(
      tooltip: label,
      icon: Icon(icon,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade500),
      onPressed: () => _onItemTapped(index),
    );
  }
}