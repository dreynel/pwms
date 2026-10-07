import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/control_provider.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/profile_dialog.dart';
import 'control_tab.dart';
import 'logs_tab.dart';
import 'schedules_tab.dart';
import 'settings_tab.dart';

class NavigationRoot extends StatefulWidget {
  const NavigationRoot({super.key});

  @override
  State<NavigationRoot> createState() => _NavigationRootState();
}

class _NavigationRootState extends State<NavigationRoot> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _tabs = [
    const ControlTab(),
    const SchedulesTab(),
    const LogsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);
    final user = provider.currentUser ??
        UserModel(
          id: 0,
          name: 'Administrator',
          username: 'admin',
          role: provider.isAdmin ? 'admin' : 'staff',
        );

    final isWide = MediaQuery.of(context).size.width >= 850;

    if (isWide) {
      // Desktop / Tablet Landscape: Permanent Pinned Sidebar
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            AppSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              isDrawer: false,
            ),
            Expanded(
              child: _tabs[_selectedIndex],
            ),
          ],
        ),
      );
    }

    // Mobile / Compact: Top Bar + Drawer + Bottom Navigation
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Hamburger Drawer Trigger
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B), size: 26),
                    tooltip: 'Open Navigation & Profile',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 4),

                  // Brand / System Title
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PWMS CONVEYOR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Waste Automation System',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: provider.isConnected
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: provider.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.isConnected ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: provider.isConnected ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Top Right User Profile Avatar Button
                  GestureDetector(
                    onTap: () => ProfileDialog.show(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: user.isAdmin
                              ? [const Color(0xFF4F46E5), const Color(0xFF3B82F6)]
                              : [const Color(0xFF0D9488), const Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: AppSidebar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          isDrawer: true,
        ),
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF2563EB),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 0 ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                ),
                label: 'HUB',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 1 ? Icons.auto_mode_rounded : Icons.auto_mode_outlined,
                ),
                label: 'PLANS',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 2 ? Icons.receipt_long_rounded : Icons.receipt_long_outlined,
                ),
                label: 'LOGS',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 3 ? Icons.tune_rounded : Icons.tune_outlined,
                ),
                label: 'CONFIG',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
