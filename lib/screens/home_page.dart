import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tajiri_ai/core/models/goal_model.dart';
import 'package:tajiri_ai/core/services/firestore_service.dart';
import 'package:tajiri_ai/screens/details/goal_details_page.dart';
import 'advisory.dart';
import 'analytics.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'package:tajiri_ai/screens/add/add_transaction_page.dart';
import 'budget_n_goals_page.dart';
import 'package:tajiri_ai/core/services/notification_service.dart';

class HomePage extends StatefulWidget {
  final User user;
  final bool isNewUser; // Flag to identify a newly registered user.

  const HomePage({
    super.key,
    required this.user,
    this.isNewUser = false, // Default to false for existing users.
  });

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
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    final notificationService = NotificationService();

    // The core logic to solve the race condition:
    // 1. Subscribe the app to its user-specific topic first.
    notificationService.subscribeToUserTopic(widget.user.uid).then((_) {
      // 2. AFTER the subscription is complete, check if this is a new user.
      if (widget.isNewUser) {
        print("New user detected. Subscribed to topic. Triggering welcome notification...");
        // 3. Call the reliable callable cloud function.
        FirebaseFunctions.instance
            .httpsCallable('triggerWelcomeNotification')
            .call()
            .catchError((error) {
              // It's good practice to log errors for debugging.
              print("Failed to trigger welcome notification: $error");
            });
      }
    });

    // Schedule other recurring local/cloud notifications as before.
    notificationService.scheduleDailyReminderNotification();

    // Set up the listener for when a notification is tapped by the user.
    _notificationTapSubscription =
        notificationService.onNotificationTap.stream.listen((payload) async {
      if (!mounted || payload == null) return;

      if (payload == 'add_transaction') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddTransactionPage(user: widget.user),
          ),
        );
      } else if (payload == 'open_chat') {
        _onItemTapped(3); // Navigate to the AI Advisor page.
      } else if (payload.startsWith('view_goal_')) {
        final goalId = payload.split('_').last;
        try {
          final Goal? goal =
              await FirestoreService().getGoalById(widget.user.uid, goalId);
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

    // Set up connectivity listener to show offline status.
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((connectivityResult) {
      final isOffline = connectivityResult.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOffline = isOffline;
        });
      }
    });

    // Check initial connectivity state on startup.
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
            const SizedBox(width: 48), // The space for the notch
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