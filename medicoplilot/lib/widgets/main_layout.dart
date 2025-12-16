import 'package:flutter/material.dart';
import 'sidebar.dart';
import '../pages/new_encounter_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // List of pages corresponding to sidebar items
  final List<Widget> _pages = [
    const NewEncounterPage(),
    // Add more pages here as you create them
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
          // Main content area
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
