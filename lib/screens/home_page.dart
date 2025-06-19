import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'advisory.dart';
import 'analytics.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'add_transaction_page.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static const List<String> _pageTitles = ["Dashboard", "Analytics", "AI Advisor"];

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
      AdvisoryPage(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddTransactionPage(user: widget.user)),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.dashboard_rounded, "Dashboard", 0),
            _buildNavItem(Icons.pie_chart_rounded, "Analytics", 1),
            const SizedBox(width: 48), // The space for the FAB
            _buildNavItem(Icons.model_training_rounded, "AI Advisor", 2),
            // The profile button is in the AppBar now, so this space is for balance.
            const SizedBox(width: 48),
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