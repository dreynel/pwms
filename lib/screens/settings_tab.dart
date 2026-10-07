import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/control_provider.dart';
import '../widgets/profile_dialog.dart';
import 'users_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late TextEditingController _ipController;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ControlProvider>(context, listen: false);
    _ipController = TextEditingController(text: provider.ipAddress);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(ControlProvider provider) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final targetUrl = _ipController.text.trim();
    provider.setIpAddress(targetUrl);

    final stopwatch = Stopwatch()..start();
    try {
      await provider.refreshStatus();
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = provider.isConnected;
          _testResult = provider.isConnected
              ? 'Connected successfully (${stopwatch.elapsedMilliseconds} ms)'
              : 'Failed to reach server at $targetUrl';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Connection error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ACCOUNT & PROFILE SECTION
                    _buildSectionHeader('ACCOUNT & ACCESS CONTROL'),
                    _buildUserAccountCard(context, provider, currentUser),
                    const SizedBox(height: 24),

                    // CLOUD & NETWORK CONFIGURATION
                    _buildSectionHeader('CLOUD & NETWORK CONFIGURATION'),
                    _buildSettingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _ipController,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'CLOUD API / SERVER URL',
                              hintText: 'https://pwms-9jkw.onrender.com',
                              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                              prefixIcon: const Icon(Icons.cloud_sync_rounded, color: Colors.blueAccent),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  icon: _isTesting
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.network_check_rounded, size: 16),
                                  label: const Text('Test Connection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: _isTesting ? null : () => _testConnection(provider),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.save_rounded, size: 16),
                                  label: const Text('Save URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    provider.setIpAddress(_ipController.text);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Server endpoint saved.')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_testResult != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (_testSuccess ?? false)
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (_testSuccess ?? false)
                                      ? const Color(0xFF6EE7B7)
                                      : const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    (_testSuccess ?? false) ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                    size: 16,
                                    color: (_testSuccess ?? false) ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _testResult!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: (_testSuccess ?? false) ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // HARDWARE SPECIFICATIONS
                    _buildSectionHeader('HARDWARE SPECIFICATIONS'),
                    _buildSettingCard(
                      child: Column(
                        children: [
                          _buildSpecRow(Icons.bolt_rounded, 'Relay Power', '12V / 10A High Load'),
                          const Divider(color: Color(0xFFF1F5F9), height: 24),
                          _buildSpecRow(Icons.settings_input_component_rounded, 'GPIO Pin', 'Pin 12 / D12 Relay Driver'),
                          const Divider(color: Color(0xFFF1F5F9), height: 24),
                          _buildSpecRow(Icons.precision_manufacturing_rounded, 'Motor Load', 'Conveyor Drive Motor'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ABOUT
                    _buildSectionHeader('ABOUT SYSTEM'),
                    _buildSettingCard(
                      child: const Center(
                        child: Column(
                          children: [
                            Text(
                              'PWMS CONVEYOR CONTROL v1.4',
                              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Plastic Waste Management & Automation System',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREFERENCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueAccent,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'System Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUserAccountCard(BuildContext context, ControlProvider provider, UserModel? currentUser) {
    final String username = currentUser?.username ?? 'admin';
    final String role = currentUser?.roleDisplay ?? 'Administrator';
    final bool isAdmin = provider.isAdmin;

    final Color roleBadgeColor = isAdmin ? const Color(0xFF4F46E5) : const Color(0xFF0D9488);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          // Profile Details Header
          InkWell(
            onTap: () => ProfileDialog.show(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAdmin
                            ? [const Color(0xFF4F46E5), const Color(0xFF3B82F6)]
                            : [const Color(0xFF0D9488), const Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentUser?.initials ?? 'AD',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.displayName ?? username,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
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
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '@$username',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
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
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Edit Profile & Change Password Tile
          InkWell(
            onTap: () => ProfileDialog.show(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, size: 18, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Profile & Security',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Manage profile, permissions, and passwords',
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_alt_rounded, size: 18, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workforce & Access Management',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Add, edit, and configure staff/admin credentials',
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

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 13)),
      ],
    );
  }
}
