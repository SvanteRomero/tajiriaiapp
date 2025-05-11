import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'advisory.dart';
import 'analytics.dart';
import 'home.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  String pageTitle = "Home";

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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Home(user: widget.user),
      Analytics(user: widget.user),
      Advisory(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Implement profile action
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: setIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: "Advisory"),
        ],
      ),
      body: pages[selectedIndex],
    );
  }
}
