import 'package:flutter/material.dart';

import 'advisory.dart';
import 'analytics.dart';
import 'home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  String pageTitle = "Home";
    void setIndex(int index) {
    setState(() {
      selectedIndex = index;
switch(selectedIndex){
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
  List<Widget> pages =[
Home(),
    Analytics(),
    Advisory(),
  ];
  @override
  Widget build(BuildContext context) {
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
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
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
      body: pages[selectedIndex],
    );
  }
}
