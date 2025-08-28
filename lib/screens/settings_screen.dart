import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late WeeklyHours _hours;
  late int _transitionStart;
  late int _transitionEnd;

  bool _hoursExpanded = false;
  bool _transitionExpanded = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _hours = app.hours;
    _transitionStart = app.settings.transitionStartMinutes;
    _transitionEnd = app.settings.transitionEndMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                if (index == 0) _hoursExpanded = !_hoursExpanded;
                if (index == 1) _transitionExpanded = !_transitionExpanded;
              });
            },
            children: [
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => const ListTile(
                  title: Text('Hours'),
                  subtitle: Text('Open/close times by day'),
                ),
                isExpanded: _hoursExpanded,
                body: Column(
                  children: [
                    for (final d in _days)
                      ListTile(
                        title: Text(d.label),
                        subtitle: Text('Open ${_fmtMin(_hours.openMinutes[d.weekday]!)} • Close ${_fmtMin(_hours.closeMinutes[d.weekday]!)}'),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          final open = await _pickTime(context, 'Set open time for ${d.label}', _hours.openMinutes[d.weekday]!);
                          if (open == null) return;
                          final close = await _pickTime(context, 'Set close time for ${d.label}', _hours.closeMinutes[d.weekday]!);
                          if (close == null) return;
                          setState(() {
                            _hours.openMinutes[d.weekday] = open;
                            _hours.closeMinutes[d.weekday] = close;
                          });
                          app.setWeeklyHours(_hours);
                        },
                      ),
                  ],
                ),
              ),
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => const ListTile(
                  title: Text('Transition Period'),
                  subtitle: Text('Defines the transition between Lunch and Dinner'),
                ),
                isExpanded: _transitionExpanded,
                body: Column(
                  children: [
                    ListTile(
                      title: const Text('Transition Start'),
                      subtitle: Text(_fmtMin(_transitionStart)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final picked = await _pickTime(context, 'Set transition start time', _transitionStart);
                        if (picked == null) return;
                        setState(() {
                          _transitionStart = picked;
                        });
                        final newSettings = app.settings
                          ..transitionStartMinutes = _transitionStart
                          ..transitionEndMinutes = _transitionEnd;
                        await app.saveSettings(newSettings);
                      },
                    ),
                    ListTile(
                      title: const Text('Transition End'),
                      subtitle: Text(_fmtMin(_transitionEnd)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final picked = await _pickTime(context, 'Set transition end time', _transitionEnd);
                        if (picked == null) return;
                        setState(() {
                          _transitionEnd = picked;
                        });
                        final newSettings = app.settings
                          ..transitionStartMinutes = _transitionStart
                          ..transitionEndMinutes = _transitionEnd;
                        await app.saveSettings(newSettings);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          const ListTile(title: Text('Server Management')),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Manage Servers'),
            subtitle: const Text('Add, rename, or remove servers (PIN required for rename/remove)'),
            onTap: () => Navigator.pushNamed(context, '/manage'),
          ),
          const Divider(height: 1),
          const ListTile(title: Text('Manage Stations')),
          ListTile(
            leading: const Icon(Icons.table_restaurant),
            title: const Text('Manage Stations'),
            subtitle: const Text('Create, edit, or remove station types'),
            onTap: () => Navigator.pushNamed(context, '/stations'),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Dashboard'),
            subtitle: const Text('PIN required'),
            onTap: () => Navigator.pushNamed(context, '/admin'),
          ),
        ],
      ),
    );
  }

  Future<int?> _pickTime(BuildContext context, String title, int minutes) async {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final tod = TimeOfDay(hour: h % 24, minute: m);
    final picked = await showTimePicker(context: context, helpText: title, initialTime: tod);
    if (picked == null) return null;
    return picked.hour * 60 + picked.minute;
  }

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final mm = m % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString()}:${mm.toString().padLeft(2, '0')} $ampm';
  }
}

class _DayRow { final int weekday; final String label; const _DayRow(this.weekday, this.label); }
const _days = <_DayRow>[
  _DayRow(7, 'Sunday'),
  _DayRow(1, 'Monday'),
  _DayRow(2, 'Tuesday'),
  _DayRow(3, 'Wednesday'),
  _DayRow(4, 'Thursday'),
  _DayRow(5, 'Friday'),
  _DayRow(6, 'Saturday'),
];