import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);
    final ipController = TextEditingController(text: provider.ipAddress);

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
                    _buildSectionHeader('NETWORK CONFIGURATION'),
                    _buildSettingCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: ipController,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'ESP32 NODE IP',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.language_rounded, color: Colors.blueAccent),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.save_rounded, color: Colors.blueAccent),
                                onPressed: () {
                                  provider.setIpAddress(ipController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Configuration saved.')),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
                    _buildSectionHeader('ABOUT'),
                    _buildSettingCard(
                      child: const Center(
                        child: Column(
                          children: [
                            Text('CONVEYOR CONTROL v1.2', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            SizedBox(height: 4),
                            Text('Agentic Engineering Lab', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
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
            color: Colors.black.withOpacity(0.03),
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

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
