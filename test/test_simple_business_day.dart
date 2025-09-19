void main() {
  print('Testing Business Day Model - Core Logic Only');
  print('==============================================');

  // Test the business date calculation
  print('\n1. Business Date Calculation (4:00 AM anchor):');
  testBusinessDate(DateTime(2025, 9, 14, 23, 30)); // Saturday 11:30 PM
  testBusinessDate(DateTime(2025, 9, 15, 0, 13)); // Sunday 12:13 AM
  testBusinessDate(DateTime(2025, 9, 15, 0, 30)); // Sunday 12:30 AM
  testBusinessDate(DateTime(2025, 9, 15, 3, 59)); // Sunday 3:59 AM
  testBusinessDate(DateTime(2025, 9, 15, 4, 0)); // Sunday 4:00 AM

  // Test close day offset logic
  print('\n2. Close Day Offset Calculation:');
  testCloseDayOffset(1320); // 22:00 (10 PM) - same day
  testCloseDayOffset(1440); // 24:00 (midnight) - next day
  testCloseDayOffset(1470); // 24:30 (12:30 AM) - next day

  print('\n3. Expected Overnight Behavior:');
  print('   Saturday 11:30 PM → Business Date: Saturday');
  print(
      '   Sunday 12:13 AM  → Business Date: Saturday (still in Saturday business day)');
  print(
      '   Sunday 12:30 AM  → Business Date: Saturday (end of Saturday business day)');
  print(
      '   Sunday 4:00 AM   → Business Date: Sunday (start of Sunday business day)');
}

/// Test the business date calculation (4:00 AM anchor)
void testBusinessDate(DateTime dateTime) {
  final businessDate = (dateTime.hour < 4)
      ? DateTime(dateTime.year, dateTime.month, dateTime.day - 1)
      : DateTime(dateTime.year, dateTime.month, dateTime.day);

  print(
      '   ${formatDateTime(dateTime)} → Business Date: ${formatDate(businessDate)} (${weekdayName(businessDate.weekday)})');
}

/// Test close day offset calculation
void testCloseDayOffset(int closeMinutes) {
  final offset = (closeMinutes >= 1440) ? 1 : 0;
  final timeStr =
      '${closeMinutes ~/ 60}:${(closeMinutes % 60).toString().padLeft(2, '0')}';
  print(
      '   $closeMinutes min ($timeStr) → Offset: $offset ${offset == 1 ? "(next day)" : "(same day)"}');
}

String formatDateTime(DateTime dt) {
  return '${weekdayName(dt.weekday)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String weekdayName(int weekday) {
  switch (weekday) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    case 6:
      return 'Saturday';
    case 7:
      return 'Sunday';
    default:
      return 'Unknown';
  }
}
