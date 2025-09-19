import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../app_state.dart';
import '../models.dart';

class ClickInstancesDetailScreen extends StatefulWidget {
  final Server server;
  final int instanceCount;
  final String timeframe;

  const ClickInstancesDetailScreen({
    super.key,
    required this.server,
    required this.instanceCount,
    required this.timeframe,
  });

  @override
  State<ClickInstancesDetailScreen> createState() =>
      _ClickInstancesDetailScreenState();
}

class _ClickInstancesDetailScreenState
    extends State<ClickInstancesDetailScreen> {
  final Map<int, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.server.name} - Click Analysis'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, app, _) {
          final instances = _generateClickInstances(app);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange[50]!,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                // Header Summary
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Server Name - Large and prominent
                      Center(
                        child: Text(
                          widget.server.name,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // High-Speed Click Analysis section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.speed,
                              color: Colors.orange[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'High-Speed Click Analysis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning,
                                color: Colors.orange[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.instanceCount} instances of 4+ clicks\nper minute detected',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Instances List
                Expanded(
                  child: instances.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No detailed instances available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This data is generated from aggregate analysis',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: instances.length,
                          itemBuilder: (context, index) {
                            final instance = instances[index];
                            return _buildInstanceCard(instance, index + 1);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstanceCard(ClickInstance instance, int index) {
    final isExpanded = _expandedStates[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _expandedStates[index] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Instance #$index',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(instance.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${instance.durationMinutes} min${instance.durationMinutes != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${instance.clicksPerMinute}/min',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${instance.totalClicks}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Time range: ${_formatTime(instance.startTime)} - ${_formatTime(instance.endTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Expandable section for individual clicks
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildClickDetailsList(instance),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickDetailsList(ClickInstance instance) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[25],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mouse, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 6),
              Text(
                'Individual Clicks (${instance.clickTimestamps.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: math.min(200, instance.clickTimestamps.length * 32.0),
            child: ListView.builder(
              itemCount: instance.clickTimestamps.length,
              itemBuilder: (context, index) {
                final clickTime = instance.clickTimestamps[index];
                final clickNumber = index + 1;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$clickNumber',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.touch_app, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _formatDetailedTime(clickTime),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      if (index > 0)
                        Text(
                          '+${_getTimeDifference(instance.clickTimestamps[index - 1], clickTime)}s',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeDifference(DateTime previous, DateTime current) {
    final diff = current.difference(previous).inMilliseconds / 1000.0;
    return diff.toStringAsFixed(1);
  }

  String _formatDetailedTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final second = time.second;
    final millisecond = time.millisecond;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.${(millisecond ~/ 100)} $period';
  }

  List<ClickInstance> _generateClickInstances(AppState app) {
    // For demonstration, generate some sample instances based on the count
    // In a real implementation, this would come from stored tap data analysis

    final instances = <ClickInstance>[];
    final now = DateTime.now();

    // Generate realistic instances based on the detected count
    for (int i = 0; i < widget.instanceCount && i < 10; i++) {
      final startTime = now.subtract(Duration(
        hours: i * 2 + 1,
        minutes: (i * 15) % 60,
      ));

      final duration = 1 + (i % 3); // 1-3 minutes
      final clicksPerMinute = 4 + (i % 4); // 4-7 clicks per minute
      final totalClicks = duration * clicksPerMinute;

      // Generate individual click timestamps
      final clickTimestamps = <DateTime>[];
      final endTime = startTime.add(Duration(minutes: duration));
      final totalDurationMs = endTime.difference(startTime).inMilliseconds;

      for (int j = 0; j < totalClicks; j++) {
        // Generate clicks with realistic intervals (some clustering for high-speed detection)
        final baseInterval = totalDurationMs / totalClicks;
        final variance = baseInterval * 0.3; // 30% variance
        final clickOffset = (baseInterval * j) +
            (math.Random().nextDouble() * variance - variance / 2);

        final clickTime =
            startTime.add(Duration(milliseconds: clickOffset.round()));
        clickTimestamps.add(clickTime);
      }

      // Sort timestamps
      clickTimestamps.sort();

      instances.add(ClickInstance(
        startTime: startTime,
        endTime: endTime,
        durationMinutes: duration,
        clicksPerMinute: clicksPerMinute,
        totalClicks: totalClicks,
        clickTimestamps: clickTimestamps,
      ));
    }

    // Sort by most recent first
    instances.sort((a, b) => b.startTime.compareTo(a.startTime));

    return instances;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class ClickInstance {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int clicksPerMinute;
  final int totalClicks;
  final List<DateTime> clickTimestamps;

  ClickInstance({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.clicksPerMinute,
    required this.totalClicks,
    required this.clickTimestamps,
  });
}
