import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_state.dart';
import '../models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static String _weekday(DateTime d) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[d.weekday - 1];
  }
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final shiftsToday = app.shiftsOnDate(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2022, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _selectedDay,
                selectedDayPredicate: (d) => d.year == _selectedDay.year && d.month == _selectedDay.month && d.day == _selectedDay.day,
                onDaySelected: (sel, foc) => setState(() => _selectedDay = sel),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final d = DateTime(day.year, day.month, day.day);
                    final hist = app.history;
                    final daysWith = <DateTime, int>{};
                    for (final h in hist) {
                      final dd = DateTime(h.start.year, h.start.month, h.start.day);
                      daysWith[dd] = (daysWith[dd] ?? 0) + 1;
                    }
                    final count = daysWith[d] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.teal)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: Text('Shifts on ${_ymd(_selectedDay)}')),
              const SizedBox(height: 8),
              if (shiftsToday.isEmpty)
                const Text('No shifts this day.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shiftsToday.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = shiftsToday[i];
                    final app = context.read<AppState>();
                    final pizookieTotal = s.pizookieCounts.values.fold(0, (a, b) => a + b);
                    final totalRuns = s.counts.values.fold(0, (a, b) => a + b);
                    return ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text('${s.shiftType} • ${_hm(s.start)}'),
                      subtitle: Text('$totalRuns runs ($pizookieTotal pizookie)'),
                      onTap: () => _showShiftDialog(context, s),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete shift',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Shift'),
                              content: const Text('Are you sure you want to delete this shift? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final pinController = TextEditingController();
                            final pin = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Admin Pin Required'),
                                content: TextField(
                                  controller: pinController,
                                  autofocus: true,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Enter admin pin'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, null),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, pinController.text),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (pin != null && pin.isNotEmpty) {
                              final success = await app.deleteShiftWithPin(s, pin);
                              if (success) {
                                setState(() {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Incorrect admin pin. Shift not deleted.'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShiftDialog(BuildContext context, ShiftRecord s) {
    final app = context.read<AppState>();
    final items = s.counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          height: 400,
          child: Container(
            width: 340,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EDEE),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(s.shiftType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF3A2D4B))),
                const SizedBox(height: 6),
                Text('${_weekday(s.start)} - ${_hm(s.start)}', style: const TextStyle(fontSize: 18, color: Color(0xFF6D5A7C))),
                const SizedBox(height: 18),
                // Column headers
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Shift Runs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF6D5A7C))),
                                      const SizedBox(height: 2),
                                      Text(
                                        '(Includes Pizookies)',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 11,
                                          color: Color(0xFF6D5A7C),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Pizookie Runs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFB85C5C))),
                                      const SizedBox(height: 17),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ...items.map((e) {
                        final totalRuns = s.counts[e.key] ?? 0;
                        final pizookieRuns = s.pizookieCounts[e.key] ?? 0;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  app.serverById(e.key)?.name ?? 'Unknown',
                                  style: const TextStyle(fontSize: 16, color: Color(0xFF3A2D4B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          constraints: const BoxConstraints(minHeight: 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF3EAF7),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('$totalRuns runs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF6D5A7C))),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          constraints: const BoxConstraints(minHeight: 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFFF3E6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('$pizookieRuns', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFB85C5C))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB85C5C))),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  static String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  static String _hm(DateTime d) {
    int hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'pm' : 'am';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute$ampm';
  }
}

class _CalendarTab extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  const _CalendarTab({required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hist = app.history;

    final daysWith = <DateTime, int>{};
    for (final h in hist) {
      final d = DateTime(h.start.year, h.start.month, h.start.day);
      daysWith[d] = (daysWith[d] ?? 0) + 1;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2022, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: selectedDay,
            selectedDayPredicate: (d) => d.year == selectedDay.year && d.month == selectedDay.month && d.day == selectedDay.day,
            onDaySelected: (sel, foc) => onDaySelected(sel),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final d = DateTime(day.year, day.month, day.day);
                final count = daysWith[d] ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.teal)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hist = app.history;
    if (hist.isEmpty) return const Center(child: Text('No shifts yet.'));
    return ListView.separated(
      itemCount: hist.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final s = hist[i];
        final total = s.counts.values.fold<int>(0, (a, b) => a + b);
        return ListTile(
          leading: const Icon(Icons.event_note),
          title: Text('${s.shiftType} • ${_ymd(s.start)} ${_hm(s.start)}'),
          subtitle: Text('Total runs: $total • ${s.counts.length} servers'),
          onTap: () {
            final host = context.findAncestorStateOfType<_HistoryScreenState>();
            host?._showShiftDialog(context, s);
          },
        );
      },
    );
  }

  static String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  static String _hm(DateTime d) => '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
