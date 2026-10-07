import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/control_provider.dart';
import '../screens/login_screen.dart';
import '../screens/users_screen.dart';
import 'profile_dialog.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isDrawer;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isDrawer = false,
  });

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

    final isAdmin = user.isAdmin;
    final primaryGradient = isAdmin
        ? const [Color(0xFF4F46E5), Color(0xFF3B82F6)]
        : const [Color(0xFF0D9488), Color(0xFF06B6D4)];

    return Container(
      width: isDrawer ? 320 : 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate aesthetic
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top App Brand & Profile Header
            _buildProfileHeader(context, user, primaryGradient, provider),

            const SizedBox(height: 12),

            // Live Telemetry / Status Pill
            _buildStatusStrip(context, provider),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 12),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
                    child: Text(
                      'MAIN NAVIGATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.grid_view_rounded,
                    label: 'Control Hub',
                    badgeText: provider.isMotorOn ? 'ON' : null,
                    badgeColor: provider.isMotorOn ? const Color(0xFF10B981) : null,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.auto_mode_rounded,
                    label: 'Automated Plans',
                    badgeText: provider.schedules.isNotEmpty ? '${provider.schedules.length}' : null,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: Icons.receipt_long_rounded,
                    label: 'Activity Logs',
                    badgeText: provider.logs.isNotEmpty ? '${provider.logs.length}' : null,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.tune_rounded,
                    label: 'Configuration',
                  ),

                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
                    child: Text(
                      'ACCESS & TEAM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),

                  // Direct User Management Item (Accessible by Admins)
                  _buildActionItem(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    label: 'User Management',
                    badgeText: isAdmin ? 'Admin' : 'Restricted',
                    badgeColor: isAdmin ? const Color(0xFF6366F1) : const Color(0xFF475569),
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      if (isAdmin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UsersScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User Management is restricted to Administrators.')),
                        );
                      }
                    },
                  ),

                  // Profile Details Dialog Action
                  _buildActionItem(
                    context: context,
                    icon: Icons.badge_outlined,
                    label: 'My Profile & Security',
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      ProfileDialog.show(context);
                    },
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF1E293B), height: 1),

            // Bottom Footer (Server info & Sign Out)
            _buildFooter(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    UserModel user,
    List<Color> gradientColors,
    ControlProvider provider,
  ) {
    return InkWell(
      onTap: () {
        if (isDrawer) Navigator.pop(context);
        ProfileDialog.show(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                // Connection indicator badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: provider.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E293B), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isAdmin
                              ? const Color(0xFF4F46E5).withValues(alpha: 0.3)
                              : const Color(0xFF0D9488).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: user.isAdmin ? const Color(0xFF6366F1) : const Color(0xFF14B8A6),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          user.roleDisplay.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: user.isAdmin ? const Color(0xFF818CF8) : const Color(0xFF2DD4BF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '@${user.username}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStrip(BuildContext context, ControlProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Motor Indicator
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: provider.isMotorOn ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isMotorOn ? 'MOTOR RUNNING' : 'MOTOR IDLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: provider.isMotorOn ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),

            // Cloud Pulse
            Row(
              children: [
                Icon(
                  Icons.cloud_done_rounded,
                  size: 13,
                  color: provider.isConnected ? const Color(0xFF38BDF8) : const Color(0xFFF87171),
                ),
                const SizedBox(width: 5),
                Text(
                  provider.isConnected ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: provider.isConnected ? const Color(0xFF38BDF8) : const Color(0xFFF87171),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onDestinationSelected(index);
            if (isDrawer) Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1)
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ControlProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PWMS ENTERPRISE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Conveyor OS v1.4',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 20),
                tooltip: 'Sign Out',
                onPressed: () => _confirmSignOut(context, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, ControlProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (isDrawer) Navigator.pop(context);
              provider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

