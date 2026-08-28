import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';

class SchedulesTab extends StatefulWidget {
  const SchedulesTab({super.key});

  @override
  State<SchedulesTab> createState() => _SchedulesTabState();
}

class _SchedulesTabState extends State<SchedulesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ControlProvider>(context, listen: false).fetchSchedules();
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
            _buildStickyHeader(context),
            Expanded(
              child: provider.schedules.isEmpty
                  ? _buildEmptyState()
                  : _buildScheduleList(context),
            ),
            _buildAddAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
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
          const Text(
            'SCHEDULER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.blueAccent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Automation Plans',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 40,
                )
              ],
            ),
            child: const Icon(Icons.event_note_rounded, size: 60, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Schedules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a recurring or calendar-based automation below',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      itemCount: provider.schedules.length,
      itemBuilder: (context, index) {
        final schedule = provider.schedules[index];
        final bool isCalendar = schedule['type'] == 'calendar' || schedule.containsKey('date');
        final bool isEnabled = schedule['enabled'] ?? true;
        final String time = schedule['time'] ?? '12:00 PM';
        final int duration = schedule['duration'] ?? 1;
        final String? dateStr = schedule['date'];
        final List<dynamic> days = schedule['days'] ?? ['Daily'];

        String dateFormatted = '';
        if (isCalendar && dateStr != null) {
          try {
            final parsedDate = DateTime.parse(dateStr);
            dateFormatted = DateFormat('EEE, MMM d, yyyy').format(parsedDate);
          } catch (_) {
            dateFormatted = dateStr;
          }
        }

        return GestureDetector(
          onTap: () => _showScheduleDialog(context, existing: schedule, index: index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isEnabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isCalendar
                        ? Colors.deepPurpleAccent.withValues(alpha: 0.1)
                        : Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCalendar ? Icons.calendar_month_rounded : Icons.repeat_rounded,
                    color: isCalendar ? Colors.deepPurpleAccent : Colors.blueAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isEnabled ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCalendar
                                  ? Colors.deepPurpleAccent.withValues(alpha: 0.1)
                                  : Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isCalendar ? 'CALENDAR' : 'RECURRING',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isCalendar ? Colors.deepPurpleAccent : Colors.blueAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCalendar
                            ? 'Date: $dateFormatted\nDuration: $duration min'
                            : 'Days: ${days.join(', ')}\nDuration: $duration min',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (val) => provider.toggleSchedule(index),
                ),
                IconButton(
                  onPressed: () => provider.deleteSchedule(index),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: 'Delete schedule',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () => _showScheduleDialog(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded),
                  SizedBox(width: 8),
                  Text(
                    'NEW AUTOMATION',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, {Map<String, dynamic>? existing, int? index}) async {
    final provider = Provider.of<ControlProvider>(context, listen: false);

    TimeOfDay initialTime = TimeOfDay.now();
    DateTime initialDate = DateTime.now();
    String scheduleType = 'recurring';

    if (existing != null) {
      if (existing['type'] == 'calendar' || existing.containsKey('date')) {
        scheduleType = 'calendar';
        if (existing['date'] != null) {
          try {
            initialDate = DateTime.parse(existing['date']);
          } catch (_) {}
        }
      }

      try {
        final timeParts = (existing['time'] as String).split(' ');
        final hm = timeParts[0].split(':');
        int h = int.parse(hm[0]);
        int m = int.parse(hm[1]);
        if (timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM' && h != 12) h += 12;
        if (timeParts.length > 1 && timeParts[1].toUpperCase() == 'AM' && h == 12) h = 0;
        initialTime = TimeOfDay(hour: h, minute: m);
      } catch (_) {}
    }

    int duration = existing != null ? (existing['duration'] ?? 1) : 1;
    List<String> selectedDays = existing != null && existing['days'] != null
        ? List<String>.from(existing['days'])
        : ['Daily'];
    final allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (selectedDays.contains('Daily')) {
      selectedDays = List<String>.from(allDays);
    }

    TimeOfDay selectedTime = initialTime;
    DateTime selectedDate = initialDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final hour = selectedTime.hour;
            final minute = selectedTime.minute;
            final period = hour >= 12 ? 'PM' : 'AM';
            final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            final timeDisplayStr =
                '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(
                    existing == null ? Icons.add_alarm_rounded : Icons.edit_calendar_rounded,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    existing == null ? 'New Automation' : 'Edit Automation',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Type Segmented Selector
                    const Text('Schedule Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => scheduleType = 'recurring'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: scheduleType == 'recurring' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: scheduleType == 'recurring'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 5,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.repeat_rounded,
                                      size: 16,
                                      color: scheduleType == 'recurring' ? Colors.blueAccent : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Recurring',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: scheduleType == 'recurring'
                                            ? const Color(0xFF1E293B)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => scheduleType = 'calendar'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: scheduleType == 'calendar' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: scheduleType == 'calendar'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 5,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                      color: scheduleType == 'calendar'
                                          ? Colors.deepPurpleAccent
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Calendar Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: scheduleType == 'calendar'
                                            ? const Color(0xFF1E293B)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Time Picker Tile
                    const Text('Trigger Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() => selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  timeDisplayStr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Change Time',
                              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Calendar Date or Recurring Days Selector
                    if (scheduleType == 'calendar') ...[
                      const Text('Select Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: Colors.deepPurpleAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Pick Date',
                                style: TextStyle(
                                  color: Colors.deepPurpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ActionChip(
                            label: const Text('Today', style: TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => selectedDate = DateTime.now()),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            label: const Text('Tomorrow', style: TextStyle(fontSize: 11)),
                            onPressed: () =>
                                setState(() => selectedDate = DateTime.now().add(const Duration(days: 1))),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Days:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedDays.length == allDays.length) {
                                  selectedDays.clear();
                                } else {
                                  selectedDays = List<String>.from(allDays);
                                }
                              });
                            },
                            child: Text(
                              selectedDays.length == allDays.length ? 'Clear All' : 'Select All',
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: allDays.map((day) {
                          final isSelected = selectedDays.contains(day);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blueAccent : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 18),
                    const Text('Motor Run Duration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: duration,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: [1, 2, 5, 10, 15, 30].map((int val) {
                        return DropdownMenuItem<int>(
                          value: val,
                          child: Text('$val Minute${val > 1 ? 's' : ''}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => duration = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheduleType == 'calendar' ? Colors.deepPurpleAccent : Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    final hour = selectedTime.hour;
                    final minute = selectedTime.minute;
                    final period = hour >= 12 ? 'PM' : 'AM';
                    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                    final timeStr =
                        '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

                    if (scheduleType == 'calendar') {
                      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                      if (existing == null) {
                        provider.addSchedule(
                          time: timeStr,
                          type: 'calendar',
                          date: dateStr,
                          duration: duration,
                        );
                      } else {
                        provider.updateSchedule(
                          index!,
                          time: timeStr,
                          type: 'calendar',
                          date: dateStr,
                          duration: duration,
                        );
                      }
                    } else {
                      List<String> finalDays =
                          selectedDays.length == 7 ? ['Daily'] : selectedDays.toList();
                      if (finalDays.isEmpty) finalDays = ['Daily'];

                      if (existing == null) {
                        provider.addSchedule(
                          time: timeStr,
                          type: 'recurring',
                          days: finalDays,
                          duration: duration,
                        );
                      } else {
                        provider.updateSchedule(
                          index!,
                          time: timeStr,
                          type: 'recurring',
                          days: finalDays,
                          duration: duration,
                        );
                      }
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
