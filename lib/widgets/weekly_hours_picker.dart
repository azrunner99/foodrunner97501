import 'package:flutter/material.dart';

import '../models.dart';

/// A weekly business-hours picker presented as a 7xN timeline grid.
///
/// Data model contract
/// - Inputs: WeeklyHours (maps weekday 1..7 -> open/close minutes since midnight)
/// - Output: WeeklyHours via onChanged callback or parent screen save.
/// - Overnight: Supported by setting closeMinutes > 1440 (next day). UI shows a 30h row.
/// - Granularity: slotMinutes (default 15).
class WeeklyHoursPicker extends StatefulWidget {
  final WeeklyHours hours;
  final ValueChanged<WeeklyHours>? onChanged;
  final int slotMinutes;
  final double rowHeight;
  final EdgeInsetsGeometry padding;

  const WeeklyHoursPicker({
    super.key,
    required this.hours,
    this.onChanged,
    this.slotMinutes = 15,
    this.rowHeight = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  State<WeeklyHoursPicker> createState() => _WeeklyHoursPickerState();
}

class _WeeklyHoursPickerState extends State<WeeklyHoursPicker> {
  late Map<int, int> _open; // weekday -> minutes
  late Map<int, int> _close; // weekday -> minutes (can be > 1440)

  // Grid config: show 0:00..30:00 to visualize modest overnight closes.
  static const int _totalMinutes = 24 * 60 + 6 * 60; // 30 hours
  static const double _labelWidth = 64;
  static const double _headerHeight = 24;

  // Drag state
  int? _dragDay; // weekday
  bool _draggingStart = false; // true if dragging left handle

  @override
  void initState() {
    super.initState();
    _open = Map<int, int>.from(widget.hours.openMinutes);
    _close = Map<int, int>.from(widget.hours.closeMinutes);
  }

  @override
  void didUpdateWidget(covariant WeeklyHoursPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hours != widget.hours) {
      _open = Map<int, int>.from(widget.hours.openMinutes);
      _close = Map<int, int>.from(widget.hours.closeMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _weekdayRows;
    return Padding(
      padding: widget.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth = constraints.maxWidth - _labelWidth;
          final colWidthPerMinute = gridWidth / _totalMinutes;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(gridWidth, colWidthPerMinute),
              for (final r in rows)
                _DayRowWidget(
                  labelWidth: _labelWidth,
                  height: widget.rowHeight,
                  label: r.label,
                  child: _RowGrid(
                    weekday: r.weekday,
                    openMinutes: _open[r.weekday] ?? 11 * 60,
                    closeMinutes: _close[r.weekday] ?? 23 * 60,
                    totalMinutes: _totalMinutes,
                    slotMinutes: widget.slotMinutes,
                    colWidthPerMinute: colWidthPerMinute,
                    onDragStart: _onDragStart,
                    onDragUpdate: _onDragUpdate,
                    onDragEnd: _onDragEnd,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(double gridWidth, double colWidthPerMinute) {
    // Render time ticks every 3 hours across 0..30h
    const tickHours = [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30];
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          const SizedBox(width: _labelWidth),
          SizedBox(
            width: gridWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HeaderPainter(
                      tickPositionsPx: tickHours
                          .map((h) => (h * 60) * colWidthPerMinute)
                          .toList(),
                      labels: tickHours.map((h) => _fmtHour(h)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDragStart(int weekday, DragStartDetails d, double colWidthPerMinute) {
    setState(() {
      _dragDay = weekday;
      final x = d.localPosition.dx;
      final openX = (_open[weekday] ?? 11 * 60) * colWidthPerMinute;
      final closeX = (_close[weekday] ?? 23 * 60) * colWidthPerMinute;
      _draggingStart = (x - openX).abs() <= (x - closeX).abs();
    });
  }

  void _onDragUpdate(
      int weekday, DragUpdateDetails d, double colWidthPerMinute, int total) {
    if (_dragDay != weekday) return;
    final dxMin = d.localPosition.dx.clamp(0.0, total * colWidthPerMinute);
    final minutesRaw = (dxMin / colWidthPerMinute).round();
    final minutes = _snap(minutesRaw, widget.slotMinutes);

    setState(() {
      final minSpan = widget.slotMinutes; // ensure non-zero span
      if (_draggingStart) {
        final newOpen = minutes.clamp(0, _totalMinutes - minSpan);
        final newClose = _close[weekday] ?? 23 * 60;
        _open[weekday] = newOpen;
        _close[weekday] = newClose < newOpen + minSpan
            ? newOpen + minSpan
            : newClose.clamp(0, _totalMinutes);
      } else {
        final newClose = minutes.clamp(widget.slotMinutes, _totalMinutes);
        final newOpen = _open[weekday] ?? 11 * 60;
        _close[weekday] = newClose;
        _open[weekday] = newOpen > newClose - minSpan
            ? (newClose - minSpan).clamp(0, _totalMinutes - minSpan)
            : newOpen.clamp(0, _totalMinutes - minSpan);
      }
    });
  }

  void _onDragEnd(int weekday) {
    setState(() {
      _dragDay = null;
    });

    // Persist in model terms: allow close > 1440 for overnight
    // The UI already stores minutes in the 0..1800 range, so this is direct.
    final newHours = WeeklyHours(
      openMinutes: Map.of(_open),
      closeMinutes: Map.of(_close),
    );
    widget.onChanged?.call(newHours);
  }

  static int _snap(int minutes, int slot) {
    if (slot <= 1) return minutes;
    final r = minutes % slot;
    return r >= slot / 2 ? minutes + (slot - r) : minutes - r;
  }

  static String _fmtHour(int h) {
    // 0..30
    final base = h % 24;
    final ampm = base >= 12 ? 'PM' : 'AM';
    final h12 = base == 0 ? 12 : (base > 12 ? base - 12 : base);
    final suffix = h >= 24 ? '+' : '';
    return '$h12$ampm$suffix';
  }

  List<_DayRow> get _weekdayRows => const [
        _DayRow(1, 'Mon'),
        _DayRow(2, 'Tue'),
        _DayRow(3, 'Wed'),
        _DayRow(4, 'Thu'),
        _DayRow(5, 'Fri'),
        _DayRow(6, 'Sat'),
        _DayRow(7, 'Sun'),
      ];
}

class _DayRow {
  final int weekday;
  final String label;
  const _DayRow(this.weekday, this.label);
}

class _DayRowWidget extends StatelessWidget {
  final String label;
  final double labelWidth;
  final double height;
  final Widget child;
  const _DayRowWidget({
    required this.label,
    required this.child,
    required this.labelWidth,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RowGrid extends StatelessWidget {
  final int weekday;
  final int openMinutes;
  final int closeMinutes;
  final int totalMinutes;
  final int slotMinutes;
  final double colWidthPerMinute;
  final void Function(int weekday, DragStartDetails, double colWidthPerMinute)
      onDragStart;
  final void Function(int weekday, DragUpdateDetails, double colWidthPerMinute,
      int totalMinutes) onDragUpdate;
  final void Function(int weekday) onDragEnd;

  const _RowGrid({
    required this.weekday,
    required this.openMinutes,
    required this.closeMinutes,
    required this.totalMinutes,
    required this.slotMinutes,
    required this.colWidthPerMinute,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('whp_row_\$weekday'),
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => onDragStart(weekday, d, colWidthPerMinute),
      onPanUpdate: (d) => onDragUpdate(
          weekday, d, colWidthPerMinute, totalMinutes),
      onPanEnd: (_) => onDragEnd(weekday),
      child: CustomPaint(
        painter: _RowPainter(
          openMinutes: openMinutes,
          closeMinutes: closeMinutes,
          totalMinutes: totalMinutes,
          slotMinutes: slotMinutes,
          colWidthPerMinute: colWidthPerMinute,
          theme: Theme.of(context),
        ),
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  final List<double> tickPositionsPx;
  final List<String> labels;

  _HeaderPainter({required this.tickPositionsPx, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var i = 0; i < tickPositionsPx.length; i++) {
      final x = tickPositionsPx[i].clamp(0.0, size.width.toDouble());
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final label = labels[i];
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      );
      textPainter.layout(minWidth: 0, maxWidth: 48);
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, 2));
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderPainter oldDelegate) => false;
}

class _RowPainter extends CustomPainter {
  final int openMinutes;
  final int closeMinutes; // can be > 1440
  final int totalMinutes; // 1800
  final int slotMinutes;
  final double colWidthPerMinute;
  final ThemeData theme;

  _RowPainter({
    required this.openMinutes,
    required this.closeMinutes,
    required this.totalMinutes,
    required this.slotMinutes,
    required this.colWidthPerMinute,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid lines (subtle)
    final bg = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bg);

    final border = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, border);

    // Selection bar
    final startX = (openMinutes.clamp(0, totalMinutes)) * colWidthPerMinute;
    final endX = (closeMinutes.clamp(0, totalMinutes)) * colWidthPerMinute;
    final barRect = Rect.fromLTWH(startX, 4, (endX - startX).clamp(4.0, size.width),
        size.height - 8);

    final barPaint = Paint()
      ..color = theme.colorScheme.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      barPaint,
    );

    // Handles
    final handlePaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;
    const handleW = 6.0;
    final leftHandle = Rect.fromLTWH(barRect.left - handleW / 2, 4, handleW,
        size.height - 8);
    final rightHandle = Rect.fromLTWH(barRect.right - handleW / 2, 4, handleW,
        size.height - 8);
    canvas.drawRRect(
        RRect.fromRectAndRadius(leftHandle, const Radius.circular(3)),
        handlePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rightHandle, const Radius.circular(3)),
        handlePaint);
  }

  @override
  bool shouldRepaint(covariant _RowPainter oldDelegate) {
    return openMinutes != oldDelegate.openMinutes ||
        closeMinutes != oldDelegate.closeMinutes ||
        colWidthPerMinute != oldDelegate.colWidthPerMinute ||
        theme.colorScheme.primary != oldDelegate.theme.colorScheme.primary;
  }
}
