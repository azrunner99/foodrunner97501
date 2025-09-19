import 'package:flutter/material.dart';
import 'dart:async';

class LiveCountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final String? prefix;
  final VoidCallback? onExpired;
  final bool showLargeDisplay;

  const LiveCountdownTimer({
    super.key,
    required this.endTime,
    this.textStyle,
    this.prefix,
    this.onExpired,
    this.showLargeDisplay = false,
  });

  @override
  State<LiveCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<LiveCountdownTimer> {
  Timer? _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final remaining = widget.endTime.difference(DateTime.now());

    if (remaining.isNegative) {
      setState(() {
        _timeRemaining = '0:00';
      });
      widget.onExpired?.call();
      _timer?.cancel();
      return;
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    String newTime;
    if (hours > 0) {
      newTime = '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      newTime = '${minutes}m ${seconds}s';
    } else {
      newTime = '${seconds}s';
    }

    if (_timeRemaining != newTime) {
      setState(() {
        _timeRemaining = newTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLargeDisplay) {
      return _buildLargeDisplay();
    }

    return Text(
      '${widget.prefix ?? ''}$_timeRemaining',
      style: widget.textStyle,
    );
  }

  Widget _buildLargeDisplay() {
    final remaining = widget.endTime.difference(DateTime.now());
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.deepOrange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.orange, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TIME: ',
            style: TextStyle(
              color: Colors.orange[800],
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          if (hours > 0) ...[
            _buildTimeUnit(hours.toString().padLeft(2, '0'), 'H'),
            SizedBox(width: 4),
          ],
          _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'M'),
          SizedBox(width: 4),
          _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'S'),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 2,
                spreadRadius: 0,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  blurRadius: 1,
                  color: Colors.black.withOpacity(0.5),
                  offset: Offset(0.5, 0.5),
                ),
              ],
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.w600,
            fontSize: 9,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
