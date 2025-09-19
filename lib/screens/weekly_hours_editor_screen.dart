import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/weekly_hours_picker.dart';

class WeeklyHoursEditorScreen extends StatefulWidget {
  const WeeklyHoursEditorScreen({super.key});

  @override
  State<WeeklyHoursEditorScreen> createState() => _WeeklyHoursEditorScreenState();
}

class _WeeklyHoursEditorScreenState extends State<WeeklyHoursEditorScreen> {
  late WeeklyHours _hours;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _hours = app.hours;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Hours'),
        actions: [
          TextButton(
            onPressed: () {
              app.setWeeklyHours(_hours);
              Navigator.of(context).pop();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: WeeklyHoursPicker(
              hours: _hours,
              onChanged: (h) => setState(() => _hours = h),
              slotMinutes: 15,
              rowHeight: 48,
            ),
          ),
          _Legend(hours: _hours),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final WeeklyHours hours;
  const _Legend({required this.hours});

  @override
  Widget build(BuildContext context) {
    final rows = const [
      _DayRow(1, 'Mon'),
      _DayRow(2, 'Tue'),
      _DayRow(3, 'Wed'),
      _DayRow(4, 'Thu'),
      _DayRow(5, 'Fri'),
      _DayRow(6, 'Sat'),
      _DayRow(7, 'Sun'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          for (final r in rows)
            Row(
              children: [
                SizedBox(width: 48, child: Text(r.label)),
                Expanded(
                  child: Text(
                    'Open ${_fmtMin(hours.openMinutes[r.weekday] ?? 0)} • Close ${_fmtMin(hours.closeMinutes[r.weekday] ?? 0)}',
                    textAlign: TextAlign.right,
                  ),
                )
              ],
            )
        ],
      ),
    );
  }

  static String _fmtMin(int m) {
    final dayOffset = m ~/ 1440;
    final within = m % 1440;
    final h = within ~/ 60;
    final mm = within % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final plus = dayOffset > 0 ? ' (+$dayOffset)' : '';
    return '${h12.toString()}:${mm.toString().padLeft(2, '0')} $ampm$plus';
  }
}

class _DayRow {
  final int weekday;
  final String label;
  const _DayRow(this.weekday, this.label);
}
