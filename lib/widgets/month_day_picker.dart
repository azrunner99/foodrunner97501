import 'package:flutter/material.dart';

/// Custom month and day picker for birthdays
/// Returns a Future<DateTime?> with only month and day set (year will be current year)
Future<DateTime?> showMonthDayPicker({
  required BuildContext context,
  DateTime? initialDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) async {
  final now = DateTime.now();
  final initial = initialDate ?? DateTime(now.year, 1, 1);

  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return _MonthDayPickerDialog(
        initialDate: initial,
        helpText: helpText ?? 'Select Birthday',
        cancelText: cancelText ?? 'Cancel',
        confirmText: confirmText ?? 'Save',
      );
    },
  );
}

class _MonthDayPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final String helpText;
  final String cancelText;
  final String confirmText;

  const _MonthDayPickerDialog({
    required this.initialDate,
    required this.helpText,
    required this.cancelText,
    required this.confirmText,
  });

  @override
  State<_MonthDayPickerDialog> createState() => _MonthDayPickerDialogState();
}

class _MonthDayPickerDialogState extends State<_MonthDayPickerDialog> {
  late int selectedMonth;
  late int selectedDay;

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;
    _validateDay();
  }

  void _validateDay() {
    final daysInMonth = DateTime(2024, selectedMonth + 1, 0)
        .day; // Use 2024 (leap year) for February
    if (selectedDay > daysInMonth) {
      selectedDay = daysInMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.helpText,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Month/Day Display - more compact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthNames[selectedMonth - 1],
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    selectedDay.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Month Selector - taller
            Text(
              'Month',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = month == selectedMonth;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedMonth = month;
                          _validateDay();
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: colorScheme.primary)
                              : null,
                        ),
                        child: Text(
                          monthNames[index],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Day Selector
            Text(
              'Day',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: DateTime(2024, selectedMonth + 1, 0)
                    .day, // Days in selected month
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isSelected = day == selectedDay;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(widget.cancelText),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    final result =
                        DateTime(now.year, selectedMonth, selectedDay);
                    Navigator.of(context).pop(result);
                  },
                  child: Text(widget.confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
