import 'package:flutter/material.dart';
import 'models.dart';
import 'utils/log.dart';
import 'app_state.dart';

/// Standalone helper: determine open state for a given WeeklyHours and DateTime
bool isOpenAtFor(WeeklyHours hours, DateTime t) {
  // local version of businessDayInterval using specified hours
  DateTimeRange businessDayIntervalFor(DateTime businessDate, int weekday) {
    final openMinutes = hours.openMinutes[weekday] ?? 11 * 60;
    final closeMinutes = hours.closeMinutes[weekday] ?? 23 * 60;
    final closeDayOffset = hours.closeDayOffset[weekday] ?? 0;

    // If the open time is before the 4:00 business-date anchor, the opening
    // occurs on the next calendar day relative to the businessDate.
    final startDate = (openMinutes < 4 * 60)
        ? businessDate.add(const Duration(days: 1))
        : businessDate;
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      openMinutes ~/ 60,
      openMinutes % 60,
    );

    final endDate = closeDayOffset == 1
        ? businessDate.add(const Duration(days: 1))
        : businessDate;
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      closeMinutes ~/ 60,
      closeMinutes % 60,
    );
    return DateTimeRange(start: start, end: end);
  }

  final businessDate = AppState.businessDate(t);
  final weekday = businessDate.weekday;
  final todayInterval = businessDayIntervalFor(businessDate, weekday);
  // Debug logging to help diagnose edge cases in tests
  d(
      '[DEBUG isOpenAtFor] t=$t, businessDate=$businessDate, weekday=$weekday');
  d(
      '[DEBUG isOpenAtFor] todayInterval: start=${todayInterval.start}, end=${todayInterval.end}');
  if (!t.isBefore(todayInterval.start) && t.isBefore(todayInterval.end))
    return true;

  final yesterdayBusinessDate = businessDate.subtract(const Duration(days: 1));
  final yesterdayWeekday = yesterdayBusinessDate.weekday;
  final yesterdayInterval =
      businessDayIntervalFor(yesterdayBusinessDate, yesterdayWeekday);
  d('[DEBUG isOpenAtFor] yesterdayBusinessDate=$yesterdayBusinessDate');
  d(
      '[DEBUG isOpenAtFor] yesterdayInterval: start=${yesterdayInterval.start}, end=${yesterdayInterval.end}');
  if (!t.isBefore(yesterdayInterval.start) && t.isBefore(yesterdayInterval.end))
    return true;

  return false;
}
