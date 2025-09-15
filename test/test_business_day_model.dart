import '../lib/app_state.dart';
import '../lib/models.dart';

void main() {
  print('Testing Business Day Model Implementation');
  print('==========================================');
  
  // Create test scenario: Saturday 11 AM - 12:30 AM (Sunday) shift
  final hours = WeeklyHours.defaults();
  // Saturday (weekday 6) closes at 12:30 AM = 1470 minutes
  hours.closeMinutes[6] = 1470; // 24*60 + 30 = 1470
  
  // Test times during Saturday overnight shift
  final testTimes = [
    DateTime(2025, 9, 14, 23, 30), // Saturday 11:30 PM - should be open
    DateTime(2025, 9, 15, 0, 13),  // Sunday 12:13 AM - should be open (your reported issue)
    DateTime(2025, 9, 15, 0, 30),  // Sunday 12:30 AM - should be closed
    DateTime(2025, 9, 15, 0, 45),  // Sunday 12:45 AM - should be closed
    DateTime(2025, 9, 15, 4, 0),   // Sunday 4:00 AM - business day boundary
  ];
  
  for (final testTime in testTimes) {
    print('\nTesting: ${testTime.toString()}');
    
    // Business date calculation
    final businessDate = AppState.businessDate(testTime);
    print('  Business Date: ${businessDate.toString()}');
    print('  Business Weekday: ${businessDate.weekday}');
    
    // Close day offset
    final weekday = businessDate.weekday;
    final closeDayOffset = hours.closeDayOffset[weekday] ?? 0;
    print('  Close Day Offset: $closeDayOffset');
    
    // Business hours
    final openMinutes = hours.openMinutes[weekday] ?? 11 * 60;
    final closeMinutes = hours.closeMinutes[weekday] ?? 23 * 60;
    print('  Open Minutes: $openMinutes (${openMinutes ~/ 60}:${(openMinutes % 60).toString().padLeft(2, '0')})');
    print('  Close Minutes: $closeMinutes (raw)');
    
    if (closeDayOffset == 1) {
      final actualCloseMinutes = closeMinutes - 1440;
      print('  Actual Close: $actualCloseMinutes (${actualCloseMinutes ~/ 60}:${(actualCloseMinutes % 60).toString().padLeft(2, '0')} next day)');
    }
  }
  
  print('\n==========================================');
  print('Expected Results:');
  print('- Saturday 11:30 PM: OPEN (in business day)');
  print('- Sunday 12:13 AM: OPEN (Saturday business day continues)');
  print('- Sunday 12:30 AM: CLOSED (Saturday business day ends)');
  print('- Sunday 12:45 AM: CLOSED (outside business hours)');
  print('- Sunday 4:00 AM: Business day boundary (start of Sunday business day)');
}