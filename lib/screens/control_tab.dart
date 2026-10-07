import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';

class ControlTab extends StatefulWidget {
  const ControlTab({super.key});

  @override
  State<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends State<ControlTab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildControlHub(context),
                      const SizedBox(height: 36),
                      _buildQuickStats(context),
                      const SizedBox(height: 24),
                      _buildSystemInfo(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTROL CENTER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueAccent,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Waste Conveyor 01',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 22),
                tooltip: 'Refresh Status',
                onPressed: () => provider.refreshStatus(),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: provider.isConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlHub(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Pulse Rings
            if (provider.isMotorOn)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 240 + (40 * _pulseController.value),
                    height: 240 + (40 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12 * (1 - _pulseController.value)),
                    ),
                  );
                },
              ),

            // Tactile Button
            GestureDetector(
              onTap: () async {
                if (!provider.canControlMotor) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔒 Read-Only: Account cannot control the conveyor motor.'),
                      backgroundColor: Color(0xFF1E293B),
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sending command to cloud server...'),
                    duration: Duration(milliseconds: 700),
                  ),
                );
                await provider.toggleMotor();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.isMotorOn
                            ? '✅ Conveyor Motor is now RUNNING'
                            : '🔴 Conveyor Motor is now STOPPED',
                      ),
                      backgroundColor: provider.isMotorOn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: provider.isMotorOn
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 28,
                      spreadRadius: provider.isMotorOn ? 6 : 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 156,
                    height: 156,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: provider.isMotorOn
                            ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                      ),
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      size: 72,
                      color: provider.isMotorOn ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: provider.isMotorOn
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : const Color(0xFF64748B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            provider.isMotorOn ? '● CONVEYOR ACTIVE (RUNNING)' : '○ CONVEYOR STANDBY (IDLE)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: provider.isMotorOn ? const Color(0xFF059669) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.precision_manufacturing_rounded,
                label: 'Motor State',
                value: provider.isMotorOn ? 'RUNNING' : 'STOPPED',
                color: provider.isMotorOn ? const Color(0xFF10B981) : const Color(0xFF64748B),
                bgTint: provider.isMotorOn ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                icon: Icons.bolt_rounded,
                label: 'Supply Power',
                value: '12V DC Relay',
                color: const Color(0xFFF59E0B),
                bgTint: const Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgTint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM TELEMETRY & HARDWARE',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          _buildTelemetryRow('Connection Protocol', 'ESP32 Wi-Fi Node (HTTPS)'),
          const Divider(color: Color(0xFF334155), height: 20),
          _buildTelemetryRow('Hardware Interface', 'Pin 12 / D12 Relay Driver'),
          const Divider(color: Color(0xFF334155), height: 20),
          _buildTelemetryRow('Sync Frequency', 'Every 5s (Heartbeat)'),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
