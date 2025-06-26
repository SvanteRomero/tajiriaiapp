import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'advisory.dart';
import 'analytics.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'add_transaction_page.dart';
import 'budget_n_goals_page.dart'; // Import the MyGoalsPage

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static const List<String> _pageTitles = ["Dashboard", "Analytics", "My Goals", "AI Advisor"];

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
      MyGoalsPage(user: widget.user), // MyGoalsPage is now at index 2
      AdvisoryPage(user: widget.user), // AdvisoryPage is now at index 3
    ];

    // Determine if the FloatingActionButton should be visible
    final bool showAddTransactionButton = _selectedIndex != 3; // Hide on Advisory page (index 3)

    return Scaffold(
      appBar: AppBar(
        // Add null-aware operator to handle potential null string (defensive programming)
        title: Text(_pageTitles[_selectedIndex] ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfilePage(user: widget.user)),
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
                  MaterialPageRoute(builder: (_) => AddTransactionPage(user: widget.user)),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Use spaceBetween for even distribution
          children: <Widget>[
            // Left half of the bottom navigation bar
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.dashboard_rounded, "Dashboard", 0),
                  _buildNavItem(Icons.pie_chart_rounded, "Analytics", 1),
                ],
              ),
            ),
            // Spacer for the FloatingActionButton
            const SizedBox(width: 48), // Ensure this matches the FAB's size
            // Right half of the bottom navigation bar
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.flag_rounded, "Goals", 2), // Goals nav item at index 2
                  _buildNavItem(Icons.model_training_rounded, "AI Advisor", 3), // AI Advisor nav item at index 3
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
      icon: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade500),
      onPressed: () => _onItemTapped(index),
    );
  }
}