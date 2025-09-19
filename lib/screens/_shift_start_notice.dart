import 'package:flutter/material.dart';
import '../app_state.dart';

class ShiftStartNotice extends StatelessWidget {
  final AppState app;
  const ShiftStartNotice({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final businessDate = AppState.businessDate(now);
    final wd = businessDate.weekday;
    final interval = app.businessDayInterval(businessDate, wd);
    final openTime = TimeOfDay(hour: interval.start.hour, minute: interval.start.minute);
    final formatted = openTime.format(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_clock, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          'Shift starts at $formatted',
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.blueGrey),
        ),
      ],
    );
  }
}
