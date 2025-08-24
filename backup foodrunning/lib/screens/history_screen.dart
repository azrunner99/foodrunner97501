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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final shiftsToday = app.shiftsOnDate(_selectedDay);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Calendar'),
              Tab(text: 'List'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CalendarTab(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              onDaySelected: (d) => setState(() => _selectedDay = d),
            ),
            const _ListTab(),
          ],
        ),
        bottomNavigationBar: Material(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Shifts on ${_ymd(_selectedDay)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                if (shiftsToday.isEmpty)
                  const Text('No shifts this day.')
                else
                  Column(
                    children: shiftsToday
                        .map((s) => ListTile(
                              leading: const Icon(Icons.event_available),
                              title: Text('${s.shiftType} • ${s.label} • ${_hm(s.start)}'),
                              subtitle: Text('${s.counts.length} participants'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    final ok = await _confirmDelete(context);
                                    if (ok == true) {
                                      await context.read<AppState>().deleteShift(s.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Shift deleted')),
                                        );
                                      }
                                    }
                                  } else {
                                    _showShiftDialog(context, s);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'view', child: Text('View')),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                              onTap: () => _showShiftDialog(context, s),
                              onLongPress: () async {
                                final ok = await _confirmDelete(context);
                                if (ok == true) {
                                  await context.read<AppState>().deleteShift(s.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Shift deleted')),
                                    );
                                  }
                                }
                              },
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete shift'),
        content: const Text('This will remove the shift and recompute totals. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
  }

  void _showShiftDialog(BuildContext context, ShiftRecord s) {
    final app = context.read<AppState>();
    final items = s.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${s.shiftType} • ${s.label} • ${_ymd(s.start)} ${_hm(s.start)}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items
                .map((e) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(app.serverById(e.key)?.name ?? 'Unknown')),
                        Text(e.value.toString()),
                      ],
                    ))
                .toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _CalendarTab extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarTab({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hist = app.history;

    final daysWithShifts = <DateTime, int>{};
    for (final h in hist) {
      final d = DateTime(h.start.year, h.start.month, h.start.day);
      daysWithShifts[d] = (daysWithShifts[d] ?? 0) + 1;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2022, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: selectedDay,
            selectedDayPredicate: (d) =>
                d.year == selectedDay.year && d.month == selectedDay.month && d.day == selectedDay.day,
            onDaySelected: (sel, foc) => onDaySelected(sel),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final d = DateTime(day.year, day.month, day.day);
                final count = daysWithShifts[d] ?? 0;
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
  const _ListTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hist = app.history;

    if (hist.isEmpty) return const Center(child: Text('No shifts yet.'));

    return ListView.separated(
      itemCount: hist.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = hist[i];
        final total = s.counts.values.fold<int>(0, (a, b) => a + b);
        return ListTile(
          leading: const Icon(Icons.event_note),
          title: Text('${s.shiftType} • ${s.label} • ${_ymd(s.start)} ${_hm(s.start)}'),
          subtitle: Text('Total runs: $total • ${s.counts.length} servers'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final ok = await _confirmDelete(context);
                if (ok == true) {
                  await context.read<AppState>().deleteShift(s.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shift deleted')),
                    );
                  }
                }
              } else {
                final host = context.findAncestorStateOfType<_HistoryScreenState>();
                host?._showShiftDialog(context, s);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'view', child: Text('View')),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
          onTap: () {
            final host = context.findAncestorStateOfType<_HistoryScreenState>();
            host?._showShiftDialog(context, s);
          },
          onLongPress: () async {
            final ok = await _confirmDelete(context);
            if (ok == true) {
              await context.read<AppState>().deleteShift(s.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shift deleted')),
                );
              }
            }
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete shift'),
        content: const Text('This will remove the shift and recompute totals. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
