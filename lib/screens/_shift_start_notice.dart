import 'package:flutter/material.dart';
import '../app_state.dart';

class ShiftStartNotice extends StatelessWidget {
  final AppState app;
  const ShiftStartNotice({required this.app});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
  final wd = AppState.weekday(now);
    final open = app.hours.openMinutes[wd] ?? 11 * 60;
    final openHour = open ~/ 60;
    final openMin = open % 60;
    final openTime = TimeOfDay(hour: openHour, minute: openMin);
    final formatted = openTime.format(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_clock, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          'Shift starts at $formatted',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
        ),
      ],
    );
  }
}