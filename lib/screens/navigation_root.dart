import 'package:flutter/material.dart';
import 'control_tab.dart';
import 'schedules_tab.dart';
import 'logs_tab.dart';
import 'settings_tab.dart';

class NavigationRoot extends StatefulWidget {
  const NavigationRoot({super.key});

  @override
  State<NavigationRoot> createState() => _NavigationRootState();
}

class _NavigationRootState extends State<NavigationRoot> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const ControlTab(),
    const SchedulesTab(),
    const LogsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.hub_rounded), label: 'HUB'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_mode_rounded), label: 'PLANS'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'LOGS'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_rounded), label: 'CONFIG'),
          ],
        ),
      ),
    );
  }
}
