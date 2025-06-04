import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'advisory.dart';
import 'analytics.dart';
import 'home.dart';
import 'profile_page.dart';

/// HomePage serves as the main container and navigation hub for the application
/// Manages bottom navigation and page switching between main sections
class HomePage extends StatefulWidget {
  /// Currently authenticated user
  final User user;
  
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Currently selected navigation index
  /// 0: Home, 1: Analytics, 2: Advisory
  int selectedIndex = 0;

  /// Title displayed in app bar
  /// Updates based on selected page
  String pageTitle = "Home";

  /// Updates the selected page index and corresponding page title
  /// 
  /// Parameters:
  /// - [index]: New navigation index to set
  void setIndex(int index) {
    setState(() {
      selectedIndex = index;
      // Update page title based on selected index
      switch (selectedIndex) {
        case 0:
          pageTitle = "Home";
          break;
        case 1:
          pageTitle = "Analytics";
          break;
        case 2:
          pageTitle = "Advisory";
          break;
        case 3:
          pageTitle = "Profile";
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// List of main page widgets
    /// Each page receives the current user for context
    final List<Widget> pages = [
      Home(user: widget.user),
      Analytics(user: widget.user),
      Advisory(user: widget.user),
    ];

    return Scaffold(
      // App bar with dynamic title and profile button
      appBar: AppBar(
        title: Text(pageTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          // Profile button in app bar
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilePage(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      // Bottom navigation bar for main sections
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: setIndex,
        items: const [
          // Home section
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home"
          ),
          // Analytics section
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Analytics",
          ),
          // Advisory section
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: "Advisory",
          ),
        ],
      ),
      // Display current page based on selected index
      body: pages[selectedIndex],
    );
  }
}
