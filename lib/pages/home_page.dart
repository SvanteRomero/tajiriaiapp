/// The main navigation hub of the application that provides access to different sections
/// including Home, Analytics, and Advisory pages. It implements a bottom navigation bar
/// for seamless switching between these sections and includes a profile button in the app bar.
/// This page is displayed after successful authentication.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'advisory.dart';
import 'analytics.dart';
import 'home.dart';
import 'profile_page.dart';

/// A stateful widget that serves as the main container for the application's primary features.
/// It requires an authenticated user instance to function.
class HomePage extends StatefulWidget {
  /// The authenticated Firebase user instance.
  final User user;
  
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Tracks the currently selected navigation item.
  /// 0: Home, 1: Analytics, 2: Advisory
  int selectedIndex = 0;

  /// The title displayed in the app bar, changes based on selected page
  String pageTitle = "Home";

  /// Updates the selected index and corresponding page title when a navigation item is tapped.
  /// 
  /// This method:
  /// 1. Updates the selected index
  /// 2. Sets the appropriate page title based on the selected index
  /// 3. Triggers a rebuild to reflect the changes
  void setIndex(int index) {
    setState(() {
      selectedIndex = index;
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
    // List of main page widgets, each corresponding to a navigation item
    final List<Widget> pages = [
      Home(user: widget.user),
      Analytics(user: widget.user),
      Advisory(user: widget.user),
    ];

    return Scaffold(
      // Modern, clean app bar with profile button
      appBar: AppBar(
        title: Text(pageTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          // Profile button that navigates to the profile page
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilePage(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      // Bottom navigation bar for main section navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: setIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: "Advisory",
          ),
        ],
      ),
      // Display the selected page from the pages list
      body: pages[selectedIndex],
    );
  }
}
