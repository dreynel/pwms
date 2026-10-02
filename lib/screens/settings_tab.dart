import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';
import 'login_screen.dart';
import 'users_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);
    final ipController = TextEditingController(text: provider.ipAddress);
    final currentUser = provider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ACCOUNT & ACCESS SECTION
                    _buildSectionHeader('ACCOUNT & ACCESS CONTROL'),
                    _buildUserAccountCard(context, provider, currentUser),
                    const SizedBox(height: 30),

                    // CLOUD & NETWORK CONFIGURATION
                    _buildSectionHeader('CLOUD & NETWORK CONFIGURATION'),
                    _buildSettingCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: ipController,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'CLOUD API / SERVER URL',
                              hintText: 'https://pwms-9jkw.onrender.com or 192.168.1.1',
                              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.cloud_sync_rounded, color: Colors.blueAccent),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.save_rounded, color: Colors.blueAccent),
                                onPressed: () {
                                  provider.setIpAddress(ipController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Server configuration saved.')),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // HARDWARE SPECIFICATIONS
                    _buildSectionHeader('HARDWARE SPECIFICATIONS'),
                    _buildSettingCard(
                      child: Column(
                        children: [
                          _buildSpecRow(Icons.bolt, 'Relay Power', '12V / 10A'),
                          const Divider(color: Color(0xFFF1F5F9), height: 32),
                          _buildSpecRow(Icons.settings_input_component, 'GPIO Pin', 'Pin 12 (D12)'),
                          const Divider(color: Color(0xFFF1F5F9), height: 32),
                          _buildSpecRow(Icons.precision_manufacturing_rounded, 'Motor Load', 'Conveyor Drive'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ABOUT
                    _buildSectionHeader('ABOUT SYSTEM'),
                    _buildSettingCard(
                      child: const Center(
                        child: Column(
                          children: [
                            Text('CONVEYOR CONTROL v1.3', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            SizedBox(height: 4),
                            Text('Waste Conveyor & Automation Management', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREFERENCES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.blueAccent,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'System Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildUserAccountCard(BuildContext context, ControlProvider provider, dynamic currentUser) {
    final String username = currentUser?.username ?? 'admin';
    final String role = currentUser?.roleDisplay ?? 'Administrator';
    final bool isAdmin = provider.isAdmin;

    final Color roleBadgeColor = isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF0284C7);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Current User Profile Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: roleBadgeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAdmin ? Icons.shield_rounded : Icons.badge_rounded,
                    color: roleBadgeColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleBadgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: roleBadgeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                  tooltip: 'Sign Out',
                  onPressed: () => _confirmLogout(context, provider),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Edit Profile & Change Password Tile
          InkWell(
            onTap: () => _showEditProfileDialog(context, provider),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, size: 20, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Settings & Password',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Change username, display name, or password',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          if (isAdmin) ...[
            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // User Management Tile (Interactive)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersScreen()),
                );
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_alt_rounded, size: 20, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage System Users',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Add, edit, and configure staff/admin roles',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ControlProvider provider) {
    final user = provider.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');
    final usernameController = TextEditingController(text: user?.username ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscurePassword = true;
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
                  SizedBox(width: 10),
                  Text('Edit Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name / Display Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. System Administrator',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. admin',
                        prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('New Password (leave blank to keep unchanged)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter new password...',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                          onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Confirm new password...',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    if (errorText != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          final newUsername = usernameController.text.trim();
                          final newPassword = passwordController.text;
                          final confirmPassword = confirmPasswordController.text;

                          if (newUsername.isEmpty) {
                            setDialogState(() => errorText = 'Username cannot be empty.');
                            return;
                          }
                          if (newPassword.isNotEmpty && newPassword.length < 4) {
                            setDialogState(() => errorText = 'Password must be at least 4 characters.');
                            return;
                          }
                          if (newPassword.isNotEmpty && newPassword != confirmPassword) {
                            setDialogState(() => errorText = 'Passwords do not match.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          try {
                            final uid = user?.id ?? 1;
                            await provider.updateUser(
                              uid,
                              name: newName.isNotEmpty ? newName : newUsername,
                              username: newUsername,
                              password: newPassword.isNotEmpty ? newPassword : null,
                              role: user?.role ?? 'admin',
                            );
                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              errorText = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, ControlProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of the Conveyor Control hub?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      ],
    );
  }
}
