import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../models.dart';
import '../providers/nps_provider.dart';

class ShiftClickAnalysisScreen extends StatefulWidget {
  final Server server;

  const ShiftClickAnalysisScreen({
    super.key,
    required this.server,
  });

  @override
  State<ShiftClickAnalysisScreen> createState() =>
      _ShiftClickAnalysisScreenState();
}

class _ShiftClickAnalysisScreenState extends State<ShiftClickAnalysisScreen> {
  DateTime _selectedDate = DateTime.now();
  List<ClickDataPoint> _clickData = [];
  List<DateTime> _individualClicks = [];
  List<int> _restaurantActivityData =
      []; // Restaurant-wide activity for underlay
  bool _isLoading = true;

  // Chart interaction state
  int? _selectedBarIndex;
  final ScrollController _clicksScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadClickData();
  }

  @override
  void dispose() {
    _clicksScrollController.dispose();
    super.dispose();
  }

  // Get all dates with shift data for the current server within a date range
  Set<DateTime> _getDatesWithShiftData(
      AppState app, DateTime start, DateTime end) {
    final datesWithData = <DateTime>{};

    for (final shift in app.history) {
      final shiftDate = shift.start;
      if (shiftDate.isAfter(start.subtract(Duration(days: 1))) &&
          shiftDate.isBefore(end.add(Duration(days: 1))) &&
          (shift.counts[widget.server.id] ?? 0) > 0) {
        datesWithData
            .add(DateTime(shiftDate.year, shiftDate.month, shiftDate.day));
      }
    }

    return datesWithData;
  }

  void _loadClickData() {
    setState(() {
      _isLoading = true;
      _selectedBarIndex = null; // Reset selection
    });

    final app = Provider.of<AppState>(context, listen: false);
    final npsProvider = context.read<NPSProvider>();

    print('DEBUG: Starting _loadClickData for date: $_selectedDate');
    print('DEBUG: NPS Provider initialized: ${npsProvider.isInitialized}');

    // Calculate dynamic timeframe based on actual clicks
    final dynamicTimeframe = _calculateDynamicTimeframe(_selectedDate, app);
    final startTime = dynamicTimeframe['start']!;
    final endTime = dynamicTimeframe['end']!;

    print('DEBUG: Dynamic timeframe calculated: $startTime to $endTime');

    // Generate 15-minute intervals for the dynamic timeframe
    final clickData = _generateClickDataForDynamicRange(
        _selectedDate, startTime, endTime, app);

    // Generate restaurant-wide activity data for the same timeframe
    final restaurantActivity =
        _generateRestaurantActivityData(startTime, endTime, app);

    // Load individual clicks for the day
    final individualClicks = _getIndividualClicksForDate(_selectedDate, app);

    print(
        'DEBUG: Generated ${clickData.length} click data points and ${restaurantActivity.length} restaurant activity points');

    setState(() {
      _clickData = clickData;
      _restaurantActivityData = restaurantActivity;
      _individualClicks = individualClicks;
      _isLoading = false;
    });
  }

  List<ClickDataPoint> _generateClickDataForDynamicRange(
      DateTime date, DateTime startTime, DateTime endTime, AppState app) {
    final List<ClickDataPoint> dataPoints = [];

    print('DEBUG: Generating chart data from $startTime to $endTime');

    // Calculate the total time span in seconds for precision
    final totalSeconds = endTime.difference(startTime).inSeconds;
    final totalMinutes = totalSeconds / 60.0;
    print(
        'DEBUG: Total time span: $totalSeconds seconds ($totalMinutes minutes)');

    // Determine optimal interval and number of bars
    Duration intervalDuration;
    int targetBars = 8; // Ideal number of bars for good visualization

    if (totalSeconds <= 30) {
      // Very short time span (≤30 seconds) - use 5-second intervals
      intervalDuration = Duration(seconds: 5);
    } else if (totalSeconds <= 120) {
      // Short time span (≤2 minutes) - use 10-second intervals
      intervalDuration = Duration(seconds: 10);
    } else if (totalSeconds <= 300) {
      // Medium-short time span (≤5 minutes) - use 30-second intervals
      intervalDuration = Duration(seconds: 30);
    } else if (totalMinutes <= 30) {
      // Medium time span - use 1-5 minute intervals
      final intervalMinutes = (totalMinutes / targetBars).ceil().clamp(1, 5);
      intervalDuration = Duration(minutes: intervalMinutes);
    } else if (totalMinutes <= 120) {
      // Medium time span - use 5-15 minute intervals
      final intervalMinutes = (totalMinutes / targetBars).ceil().clamp(5, 15);
      intervalDuration = Duration(minutes: intervalMinutes);
    } else {
      // Long time span - use 15-30 minute intervals
      final intervalMinutes = (totalMinutes / targetBars).ceil().clamp(15, 30);
      intervalDuration = Duration(minutes: intervalMinutes);
    }

    print(
        'DEBUG: Using ${intervalDuration.inSeconds} second intervals (${intervalDuration.inMinutes} minutes) for optimal visualization');

    // Generate intervals using the calculated interval size
    DateTime currentTime = startTime;
    int intervalCount = 0;
    while (currentTime.isBefore(endTime)) {
      final intervalEnd = currentTime.add(intervalDuration);
      final actualEnd = intervalEnd.isBefore(endTime) ? intervalEnd : endTime;

      // Get click count for this window
      final clickCount = _getClickCountForTimeWindow(
          app, widget.server.id, currentTime, actualEnd);

      print(
          'DEBUG: Interval $intervalCount: ${currentTime.toString()} to ${actualEnd.toString()} = $clickCount clicks');

      dataPoints.add(ClickDataPoint(
        timeWindow: currentTime,
        clickCount: clickCount,
        label: _formatTimeLabel(currentTime),
      ));

      currentTime = intervalEnd;
      intervalCount++;
    }

    print('DEBUG: Generated ${dataPoints.length} data points for chart');
    return dataPoints;
  }

  // Generate restaurant-wide activity data for the same time intervals
  List<int> _generateRestaurantActivityData(
      DateTime startTime, DateTime endTime, AppState app) {
    final List<int> activityData = [];

    print(
        'DEBUG: Generating restaurant activity data from $startTime to $endTime');

    // Calculate the same interval size as the main chart
    final totalSeconds = endTime.difference(startTime).inSeconds;
    final totalMinutes = totalSeconds / 60.0;

    Duration intervalDuration;
    int targetBars = 8;

    if (totalSeconds <= 30) {
      intervalDuration = Duration(seconds: 5);
    } else if (totalSeconds <= 120) {
      intervalDuration = Duration(seconds: 10);
    } else if (totalSeconds <= 300) {
      intervalDuration = Duration(seconds: 30);
    } else if (totalMinutes <= 30) {
      final intervalMinutes = (totalMinutes / targetBars).ceil().clamp(1, 5);
      intervalDuration = Duration(minutes: intervalMinutes);
    } else if (totalMinutes <= 120) {
      final intervalMinutes = (totalMinutes / targetBars).ceil().clamp(5, 15);
      intervalDuration = Duration(minutes: intervalMinutes);
    } else {
      final intervalMinutes = (totalMinutes / targetBars).ceil().clamp(15, 30);
      intervalDuration = Duration(minutes: intervalMinutes);
    }

    // Generate intervals using the same interval size as main chart
    DateTime currentTime = startTime;
    while (currentTime.isBefore(endTime)) {
      final intervalEnd = currentTime.add(intervalDuration);
      final actualEnd = intervalEnd.isBefore(endTime) ? intervalEnd : endTime;

      // Get total click count from ALL servers for this window
      int totalClicks = 0;
      for (final server in app.servers) {
        final serverClicks =
            app.getTapCountForTimeWindow(server.id, currentTime, actualEnd);
        totalClicks += serverClicks;
      }

      activityData.add(totalClicks);
      currentTime = intervalEnd;
    }

    print(
        'DEBUG: Generated ${activityData.length} restaurant activity data points');
    return activityData;
  }

  int _getClickCountForTimeWindow(
      AppState app, String serverId, DateTime start, DateTime end) {
    // Use the same individual timestamps method to ensure data consistency
    final individualClicks =
        app.getIndividualClickTimestamps(serverId, start, end);
    final clickCount = individualClicks.length;

    print(
        'DEBUG: Time window ${start.toString()} to ${end.toString()} has $clickCount clicks (from individual timestamps)');
    return clickCount;
  }

  // Calculate dynamic timeframe based on actual first and last clicks for the day
  Map<String, DateTime> _calculateDynamicTimeframe(
      DateTime date, AppState app) {
    // Get all clicks for the selected date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    final clicks = app.getIndividualClickTimestamps(
        widget.server.id, startOfDay, endOfDay);

    print(
        'DEBUG: Found ${clicks.length} total clicks for timeframe calculation');
    if (clicks.isNotEmpty) {
      clicks.sort((a, b) => a.compareTo(b));
      print('DEBUG: Clicks range from ${clicks.first} to ${clicks.last}');
    }

    if (clicks.isEmpty) {
      // No clicks found, use default restaurant hours
      return {
        'start': DateTime(date.year, date.month, date.day, 11, 0), // 11 AM
        'end': DateTime(date.year, date.month, date.day, 22, 0), // 10 PM
      };
    }

    // Sort clicks to find first and last
    clicks.sort((a, b) => a.compareTo(b));
    final firstClick = clicks.first;
    final lastClick = clicks.last;

    // Use the actual first and last click times with minimal padding
    final adjustedFirstClick = firstClick
        .subtract(Duration(seconds: 5)); // 5 seconds before first click
    final adjustedLastClick =
        lastClick.add(Duration(seconds: 5)); // 5 seconds after last click

    final totalSpan = adjustedLastClick.difference(adjustedFirstClick);
    print(
        'DEBUG: Dynamic timeframe - First click: $firstClick -> $adjustedFirstClick');
    print(
        'DEBUG: Dynamic timeframe - Last click: $lastClick -> $adjustedLastClick');
    print(
        'DEBUG: Total span: ${totalSpan.inSeconds} seconds (${totalSpan.inMinutes} minutes)');

    return {
      'start': adjustedFirstClick,
      'end': adjustedLastClick,
    };
  }

  List<DateTime> _getIndividualClicksForDate(DateTime date, AppState app) {
    // Get start and end of the selected date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    // Use new individual timestamp method instead of artificial generation
    final clicks = app.getIndividualClickTimestamps(
        widget.server.id, startOfDay, endOfDay);

    print('DEBUG: Getting real clicks for ${widget.server.id} on $date');
    print('DEBUG: Individual clicks found: ${clicks.length}');

    // Sort clicks by time (newest first for display)
    clicks.sort((a, b) => b.compareTo(a));
    return clicks;
  }

  // Handle bar selection in chart
  void _onBarTapped(int barIndex) {
    if (barIndex < 0 || barIndex >= _clickData.length) return;

    setState(() {
      _selectedBarIndex = barIndex;
    });

    // Scroll to the corresponding clicks in the list
    _scrollToClicksInInterval(barIndex);
  }

  // Helper method to get the interval duration being used
  Duration _getIntervalDuration() {
    if (_clickData.length <= 1) return Duration(minutes: 1);

    // Calculate based on the time difference between first two data points
    final firstInterval = _clickData[0].timeWindow;
    final secondInterval = _clickData[1].timeWindow;
    return secondInterval.difference(firstInterval);
  }

  // Generate dynamic chart title based on interval duration
  String _getChartTitle() {
    final duration = _getIntervalDuration();
    final seconds = duration.inSeconds;
    final minutes = duration.inMinutes;

    if (seconds < 60) {
      return 'Clicks per $seconds-second interval';
    } else if (minutes == 1) {
      return 'Clicks per minute';
    } else if (minutes < 60) {
      return 'Clicks per $minutes-minute interval';
    } else {
      final hours = (minutes / 60).round();
      return 'Clicks per $hours-hour interval';
    }
  }

  // Scroll to clicks that fall within the selected time interval
  void _scrollToClicksInInterval(int barIndex) {
    if (_individualClicks.isEmpty || barIndex >= _clickData.length) return;

    final selectedDataPoint = _clickData[barIndex];
    final intervalStart = selectedDataPoint.timeWindow;
    final intervalDuration = _getIntervalDuration();
    final intervalEnd = intervalStart.add(intervalDuration);

    // Find the first click that falls within this interval
    int firstClickIndex = -1;
    for (int i = 0; i < _individualClicks.length; i++) {
      final clickTime = _individualClicks[i];
      if (clickTime.isAfter(intervalStart.subtract(Duration(seconds: 1))) &&
          clickTime.isBefore(intervalEnd)) {
        firstClickIndex = i;
        break;
      }
    }

    if (firstClickIndex != -1) {
      // Calculate scroll position (each list item is approximately 80 pixels)
      final scrollPosition = firstClickIndex * 80.0;

      _clicksScrollController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Check if a click falls within the selected interval
  bool _isClickInSelectedInterval(DateTime clickTime) {
    if (_selectedBarIndex == null || _selectedBarIndex! >= _clickData.length) {
      return false;
    }

    final selectedDataPoint = _clickData[_selectedBarIndex!];
    final intervalStart = selectedDataPoint.timeWindow;
    final intervalDuration = _getIntervalDuration();
    final intervalEnd = intervalStart.add(intervalDuration);

    return clickTime.isAfter(intervalStart.subtract(Duration(seconds: 1))) &&
        clickTime.isBefore(intervalEnd);
  }

  String _formatTimeLabel(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final second = time.second;
    final millisecond = time.millisecond;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.${millisecond.toString().padLeft(3, '0')} $period';
  }

  Future<void> _selectDate() async {
    final app = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();
    final firstDate = now.subtract(Duration(days: 90));
    final lastDate = now;

    final datesWithData = _getDatesWithShiftData(app, firstDate, lastDate);

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _CustomCalendarDialog(
          initialDate: _selectedDate,
          firstDate: firstDate,
          lastDate: lastDate,
          datesWithData: datesWithData,
          serverName: widget.server.name,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadClickData();
    }
  }

  // Build NPS data display widget to show check counts and performance metrics
  Widget _buildNPSDataDisplay() {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        if (!npsProvider.isInitialized) {
          return Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[600]),
                SizedBox(width: 12),
                Text(
                  'NPS data is loading...',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Get current report for admin data
        final currentReport = npsProvider.currentReport;
        final checkCount = currentReport?.allTimeTableCount ?? 0;
        final totalSales = currentReport?.allTimeSales ?? 0.0;

        return Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.green[700]),
                  SizedBox(width: 8),
                  Text(
                    'NPS Performance Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Checks',
                      '$checkCount',
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Sales',
                      '\$${totalSales.toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              if (checkCount > 0) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Avg Check',
                        '\$${(totalSales / checkCount).toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.purple,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Click Efficiency',
                        '${(_individualClicks.length / checkCount).toStringAsFixed(2)} clicks/check',
                        Icons.speed,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Helper method to build metric cards
  Widget _buildMetricCard(
      String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color[700]),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.server.name} - Shift Click Analysis'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700]),
                SizedBox(width: 12),
                Text(
                  'Analysis Date:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue[50],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _formatDateLabel(_selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NPS Performance Data Display
          _buildNPSDataDisplay(),

          // Chart Area - 40% height in a styled container
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.blue.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue[700]),
                        SizedBox(height: 16),
                        Text(
                          'Loading click data...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildChart(),
          ),

          // Individual Clicks List
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list, color: Colors.blue[600], size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Individual Clicks (${_individualClicks.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        // Show data discrepancy warning if exists
                        if (_clickData
                                .map((d) => d.clickCount)
                                .fold(0, (a, b) => a + b) !=
                            _individualClicks.length) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning,
                                    color: Colors.orange[600], size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Data Discrepancy: Chart shows ${_clickData.map((d) => d.clickCount).fold(0, (a, b) => a + b)} total clicks, but only ${_individualClicks.length} individual timestamps found. This suggests data is stored in different formats.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Clicks List
                  Expanded(
                    child: _individualClicks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app,
                                    size: 48, color: Colors.grey[400]),
                                SizedBox(height: 12),
                                Text(
                                  'No clicks recorded for this date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _clicksScrollController,
                            itemCount: _individualClicks.length,
                            itemBuilder: (context, index) {
                              final clickTime = _individualClicks[index];
                              final isToday = _isToday(clickTime);
                              final timeAgo = _getTimeAgo(clickTime);
                              final isInSelectedInterval =
                                  _isClickInSelectedInterval(clickTime);

                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                elevation: isInSelectedInterval ? 4 : 2,
                                color: isInSelectedInterval
                                    ? Colors.blue[50]
                                    : null,
                                child: Container(
                                  decoration: isInSelectedInterval
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.blue[300]!,
                                            width: 2,
                                          ),
                                        )
                                      : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isInSelectedInterval
                                          ? Colors.blue[200]
                                          : (isToday
                                              ? Colors.green[100]
                                              : Colors.blue[100]),
                                      child: Icon(
                                        Icons.touch_app,
                                        color: isInSelectedInterval
                                            ? Colors.blue[800]
                                            : (isToday
                                                ? Colors.green[600]
                                                : Colors.blue[600]),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      _formatFullDateTime(clickTime),
                                      style: TextStyle(
                                        fontWeight: isInSelectedInterval
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 14,
                                        color: isInSelectedInterval
                                            ? Colors.blue[800]
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      timeAgo,
                                      style: TextStyle(
                                        color: isInSelectedInterval
                                            ? Colors.blue[600]
                                            : Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: isInSelectedInterval
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isToday
                                        ? Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.green[300]!),
                                            ),
                                            child: Text(
                                              'TODAY',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : (isInSelectedInterval
                                            ? Icon(Icons.star,
                                                color: Colors.blue[600],
                                                size: 20)
                                            : null),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildChart() {
    if (_clickData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No click data available for this date',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final maxClicks = _clickData.map((d) => d.clickCount).reduce(max);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Metrics above the chart
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Clicks',
                    _clickData
                        .map((d) => d.clickCount)
                        .fold(0, (a, b) => a + b)
                        .toString(),
                    Icons.touch_app,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Peak Period',
                    _getPeakPeriod(),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Avg/15min',
                    (_clickData
                                .map((d) => d.clickCount)
                                .fold(0, (a, b) => a + b) /
                            _clickData.length)
                        .toStringAsFixed(1),
                    Icons.analytics,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Professional Bar Chart using fl_chart
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chart Title with Legend
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Text(
                          _getChartTitle(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Y-axis shows ${widget.server.name} click counts • Orange line shows scaled restaurant activity',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Server legend
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[400],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.server.name,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            // Restaurant legend
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[400],
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'All servers',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Composite Chart - Line chart underlay with bar chart overlay
                  Expanded(
                    child: Stack(
                      children: [
                        // Background Line Chart (restaurant activity) - FIRST so it's underneath
                        Positioned.fill(
                          child: _buildRestaurantActivityLineChart(maxClicks),
                        ),
                        // Foreground Bar Chart (server-specific clicks) - moved down to align baselines
                        Transform.translate(
                          offset: const Offset(0,
                              40), // Move the entire bar chart down by 40 pixels total
                          child: _buildServerBarChart(maxClicks),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getBarColor(int clickCount, int maxClicks, int index) {
    // If this bar is selected, use a distinctive color
    if (_selectedBarIndex == index) {
      return Colors.purple[600]!
          .withOpacity(0.95); // High opacity for selected bar
    }

    if (maxClicks == 0) return Colors.grey[300]!.withOpacity(0.8);

    final intensity = clickCount / maxClicks;
    if (intensity > 0.8)
      return Colors.red[400]!.withOpacity(0.9); // High activity - high opacity
    if (intensity > 0.6)
      return Colors.orange[400]!.withOpacity(0.9); // Medium-high activity
    if (intensity > 0.4)
      return Colors.yellow[600]!.withOpacity(0.9); // Medium activity
    if (intensity > 0.2)
      return Colors.blue[400]!.withOpacity(0.9); // Low-medium activity
    return Colors.grey[400]!.withOpacity(0.8); // Low activity
  }

  // Build the background line chart showing restaurant-wide activity
  Widget _buildRestaurantActivityLineChart(int maxClicks) {
    if (_restaurantActivityData.isEmpty) {
      print(
          'DEBUG: Restaurant activity data is empty, returning empty container');
      return Container();
    }

    print(
        'DEBUG: Building line chart with ${_restaurantActivityData.length} data points: $_restaurantActivityData');
    print('DEBUG: Server max clicks: $maxClicks');

    // Calculate max value for better scaling
    final maxRestaurantActivity = _restaurantActivityData.reduce(max);
    print('DEBUG: Restaurant max activity: $maxRestaurantActivity');

    // Use 0-based Y-axis range that matches the server bar chart
    final chartMaxY = maxClicks > 0 ? maxClicks.toDouble() * 1.1 : 10.0;
    print('DEBUG: Line chart using 0-based Y-axis, maxY: $chartMaxY');

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_restaurantActivityData.length - 1).toDouble(),
        minY: 0, // Start from 0 baseline
        maxY: chartMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: _restaurantActivityData.asMap().entries.map((entry) {
              // Use original restaurant data, scaled down to fit within server max
              final maxRestaurantValue = _restaurantActivityData.isEmpty
                  ? 1
                  : _restaurantActivityData.reduce((a, b) => a > b ? a : b);
              final maxServerValue = maxClicks > 0 ? maxClicks : 1;

              // Simple proportional scaling - restaurant data scaled to 85% of server max (increased for more prominence)
              final scaledValue =
                  (entry.value.toDouble() / maxRestaurantValue) *
                      maxServerValue *
                      0.85;

              return FlSpot(entry.key.toDouble(), scaledValue);
            }).toList(),
            isCurved: true,
            color: Colors.orange[300]!.withOpacity(0.3), // Much lighter line
            barWidth: 2, // Thinner line
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2, // Smaller dots
                  color: Colors.orange[400]!.withOpacity(0.4),
                  strokeWidth: 1,
                  strokeColor: Colors.white.withOpacity(0.8),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true, // Bring back the nice orange shading
              color: Colors.orange[100]!.withOpacity(0.2), // Very light shading
            ),
          ),
        ],
        lineTouchData: LineTouchData(enabled: false),
      ),
    );
  }

  // Build the foreground bar chart showing server-specific clicks
  Widget _buildServerBarChart(int maxClicks) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0, // Reset to normal baseline since we're moving the whole widget
        maxY: maxClicks > 0 ? maxClicks.toDouble() * 1.1 : 10.0,
        backgroundColor: Colors.transparent,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              _onBarTapped(touchedIndex);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < _clickData.length) {
                final dataPoint = _clickData[groupIndex];
                final restaurantTotal =
                    groupIndex < _restaurantActivityData.length
                        ? _restaurantActivityData[groupIndex]
                        : 0;
                return BarTooltipItem(
                  '${dataPoint.label}\n${widget.server.name}: ${dataPoint.clickCount} clicks\nRestaurant: $restaurantTotal total',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= 0 && index < _clickData.length) {
                  // Show every 4th label to avoid crowding
                  if (index % 4 == 0) {
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        _clickData[index].label,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }
                }
                return Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxClicks > 10 ? (maxClicks / 5).ceilToDouble() : 2,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
            left: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        barGroups: _clickData.asMap().entries.map((entry) {
          final index = entry.key;
          final dataPoint = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dataPoint.clickCount.toDouble(),
                color: _getBarColor(dataPoint.clickCount, maxClicks, index),
                width: 8,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                // Remove background bars to show line chart underneath
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              maxClicks > 10 ? (maxClicks / 5).ceilToDouble() : 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  String _getPeakPeriod() {
    if (_clickData.isEmpty) return 'N/A';

    final maxClicks = _clickData.map((d) => d.clickCount).reduce(max);
    final peakDataPoint =
        _clickData.firstWhere((d) => d.clickCount == maxClicks);

    return peakDataPoint.label;
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inSeconds > 0) {
      return '${difference.inSeconds} second${difference.inSeconds == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final second = dateTime.second;
    final millisecond = dateTime.millisecond;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.${millisecond.toString().padLeft(3, '0')} $period';
  }
}

class ClickDataPoint {
  final DateTime timeWindow;
  final int clickCount;
  final String label;

  ClickDataPoint({
    required this.timeWindow,
    required this.clickCount,
    required this.label,
  });
}

class _CustomCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> datesWithData;
  final String serverName;

  const _CustomCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.datesWithData,
    required this.serverName,
  });

  @override
  State<_CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  bool _isDateWithData(DateTime date) {
    return widget.datesWithData
        .contains(DateTime(date.year, date.month, date.day));
  }

  @override
  Widget build(BuildContext context) {
    final monthName = [
      '',
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
    ][_currentMonth.month];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select date',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current selection display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')} ${monthName.substring(0, 3)}, ${_selectedDate.year}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.edit, color: Colors.blue[600], size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentMonth.isAfter(widget.firstDate)
                      ? _previousMonth
                      : null,
                  icon: Icon(Icons.chevron_left),
                ),
                Text(
                  '$monthName ${_currentMonth.year}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: _currentMonth.isBefore(DateTime(
                          widget.lastDate.year, widget.lastDate.month, 1))
                      ? _nextMonth
                      : null,
                  icon: Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Day headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => Container(
                        width: 35,
                        height: 35,
                        alignment: Alignment.center,
                        child: Text(
                          day,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Calendar grid
            _buildCalendarGrid(),

            const SizedBox(height: 20),

            // Legend
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dates with shift data for ${widget.serverName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No shift data available',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday =
        firstDayOfMonth.weekday % 7; // Convert to 0=Sunday format

    final days = <Widget>[];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(SizedBox(width: 35, height: 35));
    }

    // Add days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final hasData = _isDateWithData(date);
      final isInRange =
          date.isAfter(widget.firstDate.subtract(Duration(days: 1))) &&
              date.isBefore(widget.lastDate.add(Duration(days: 1)));

      days.add(
        GestureDetector(
          onTap: isInRange
              ? () {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              : null,
          child: Container(
            width: 35,
            height: 35,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue
                  : (isInRange ? Colors.transparent : Colors.grey[100]),
              borderRadius: BorderRadius.circular(18),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Colors.transparent,
                      width: 1,
                    ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isInRange ? Colors.black : Colors.grey[400]),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasData && isInRange)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.green[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Group days into weeks
    final weeks = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      final weekDays = days.skip(i).take(7).toList();
      while (weekDays.length < 7) {
        weekDays.add(SizedBox(width: 35, height: 35));
      }
      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekDays,
        ),
      );
    }

    return Column(children: weeks);
  }
}
