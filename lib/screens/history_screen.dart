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
                    int pizookieTotal = 0;
                    s.counts.forEach((key, value) {
                      pizookieTotal += app.profiles[key]?.pizookieRuns ?? 0;
                    });
                    final totalRuns = s.counts.values.fold(0, (a, b) => a + b) + pizookieTotal;
                    return ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text('${s.shiftType} • ${_hm(s.start)}'),
                      subtitle: Text('$totalRuns runs (${pizookieTotal} pizookie)'),
                      onTap: () => _showShiftDialog(context, s),
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
              ...items.map((e) {
                final pizookieRuns = app.profiles[e.key]?.pizookieRuns ?? 0;
                final totalRuns = e.value + pizookieRuns;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(app.serverById(e.key)?.name ?? 'Unknown', style: const TextStyle(fontSize: 16, color: Color(0xFF3A2D4B)))),
                          Text(totalRuns.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6D5A7C))),
                        ],
                      ),
                      if (pizookieRuns > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.cookie, size: 16, color: Color(0xFFB85C5C)),
                              const SizedBox(width: 4),
                              Text('$pizookieRuns pizookie', style: const TextStyle(fontSize: 13, color: Color(0xFFB85C5C))),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),
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
