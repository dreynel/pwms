import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ControlProvider>(context, listen: false).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(context, provider),
            if (!provider.isAdmin) _buildStaffBanner(provider),
            Expanded(
              child: provider.logs.isEmpty
                  ? _buildEmptyState(provider)
                  : _buildLogsList(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context, ControlProvider provider) {
    final isAdmin = provider.isAdmin;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAdmin ? 'SYSTEM AUDIT TRAIL' : 'PERSONAL ACTIVITY',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueAccent,
                  letterSpacing: 2,
                ),
              ),
              if (provider.logs.isNotEmpty && provider.canClearLogs)
                GestureDetector(
                  onTap: () => _confirmClearLogs(context, provider),
                  child: const Text(
                    'CLEAR LOGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAdmin ? 'All System Event Logs' : 'My Activity Logs',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                onPressed: () => provider.fetchLogs(),
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
                tooltip: 'Refresh Logs',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffBanner(ControlProvider provider) {
    final name = provider.currentUser?.displayName ?? 'Staff';
    final username = provider.currentUser?.username ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing personal actions for $name (@$username)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0369A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ControlProvider provider) {
    final isAdmin = provider.isAdmin;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                )
              ],
            ),
            child: const Icon(Icons.history_rounded, size: 60, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          Text(
            isAdmin ? 'No System Events Recorded' : 'No Personal Activity Yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'All hardware and user actions will be listed here.'
                : 'Your motor controls and session activities will be recorded here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, ControlProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: provider.logs.length,
      itemBuilder: (context, index) {
        final log = provider.logs[index];
        final eventStr = log['event']?.toString() ?? 'Unknown Event';
        final isStart = eventStr.contains('ON');
        final isLogin = eventStr.toLowerCase().contains('login');
        final isUserManage = eventStr.toLowerCase().contains('user') ||
            eventStr.toLowerCase().contains('worker');

        Color iconBg;
        Color iconColor;
        IconData iconData;

        if (isLogin) {
          iconBg = const Color(0xFF3B82F6).withValues(alpha: 0.1);
          iconColor = const Color(0xFF3B82F6);
          iconData = Icons.login_rounded;
        } else if (isUserManage) {
          iconBg = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
          iconColor = const Color(0xFF8B5CF6);
          iconData = Icons.manage_accounts_rounded;
        } else if (isStart) {
          iconBg = Colors.green.withValues(alpha: 0.1);
          iconColor = Colors.green;
          iconData = Icons.play_arrow_rounded;
        } else {
          iconBg = Colors.red.withValues(alpha: 0.1);
          iconColor = Colors.red;
          iconData = Icons.stop_rounded;
        }

        final author = log['user_name'] ?? log['username'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          log['time'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (author != null && author.toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              author.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearLogs(BuildContext context, ControlProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Clear All Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently clear all hardware and system event logs from the database?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.clearLogs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All logs cleared.')),
                );
              },
              child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
