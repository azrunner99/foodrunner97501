import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../models.dart';

class ShiftClickAnalysisScreen extends StatefulWidget {
  final Server server;

  const ShiftClickAnalysisScreen({
    Key? key,
    required this.server,
  }) : super(key: key);

  @override
  State<ShiftClickAnalysisScreen> createState() => _ShiftClickAnalysisScreenState();
}

class _ShiftClickAnalysisScreenState extends State<ShiftClickAnalysisScreen> {
  DateTime _selectedDate = DateTime.now();
  List<ClickDataPoint> _clickData = [];
  List<DateTime> _individualClicks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClickData();
  }

  // Get all dates with shift data for the current server within a date range
  Set<DateTime> _getDatesWithShiftData(AppState app, DateTime start, DateTime end) {
    final datesWithData = <DateTime>{};
    
    for (final shift in app.history) {
      final shiftDate = shift.start;
      if (shiftDate.isAfter(start.subtract(Duration(days: 1))) && 
          shiftDate.isBefore(end.add(Duration(days: 1))) &&
          (shift.counts[widget.server.id] ?? 0) > 0) {
        datesWithData.add(DateTime(shiftDate.year, shiftDate.month, shiftDate.day));
      }
    }
    
    return datesWithData;
  }

  void _loadClickData() {
    setState(() {
      _isLoading = true;
    });

    final app = Provider.of<AppState>(context, listen: false);
    
    // Use default restaurant hours (11 AM to 10 PM)
    final openingTime = TimeOfDay(hour: 11, minute: 0);
    final closingTime = TimeOfDay(hour: 22, minute: 0);
    
    // Generate 15-minute intervals for the selected date
    final clickData = _generateClickDataForDate(_selectedDate, openingTime, closingTime, app);
    
    // Load individual clicks for the day
    final individualClicks = _getIndividualClicksForDate(_selectedDate, app);
    
    setState(() {
      _clickData = clickData;
      _individualClicks = individualClicks;
      _isLoading = false;
    });
  }

  List<ClickDataPoint> _generateClickDataForDate(
    DateTime date, 
    TimeOfDay opening, 
    TimeOfDay closing, 
    AppState app
  ) {
    final List<ClickDataPoint> dataPoints = [];
    
    // Create DateTime objects for opening and closing
    final openingDateTime = DateTime(date.year, date.month, date.day, opening.hour, opening.minute);
    final closingDateTime = DateTime(date.year, date.month, date.day, closing.hour, closing.minute);
    
    // Handle overnight shifts (closing time next day)
    final actualClosingDateTime = closingDateTime.isBefore(openingDateTime) 
        ? closingDateTime.add(Duration(days: 1))
        : closingDateTime;
    
    // Generate 15-minute intervals
    DateTime currentTime = openingDateTime;
    while (currentTime.isBefore(actualClosingDateTime)) {
      final endTime = currentTime.add(Duration(minutes: 15));
      
      // Get click count for this 15-minute window
      final clickCount = _getClickCountForTimeWindow(
        app, 
        widget.server.id, 
        currentTime, 
        endTime.isBefore(actualClosingDateTime) ? endTime : actualClosingDateTime
      );
      
      dataPoints.add(ClickDataPoint(
        timeWindow: currentTime,
        clickCount: clickCount,
        label: _formatTimeLabel(currentTime),
      ));
      
      currentTime = endTime;
    }
    
    return dataPoints;
  }

  int _getClickCountForTimeWindow(AppState app, String serverId, DateTime start, DateTime end) {
    // Use the new method to get real tap data for this time window
    final clickCount = app.getTapCountForTimeWindow(serverId, start, end);
    
    print('DEBUG: Time window ${start.toString()} to ${end.toString()} has $clickCount clicks');
    return clickCount;
  }

  List<DateTime> _getIndividualClicksForDate(DateTime date, AppState app) {
    // Get start and end of the selected date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    // Use new individual timestamp method instead of artificial generation
    final clicks = app.getIndividualClickTimestamps(widget.server.id, startOfDay, endOfDay);
    
    print('DEBUG: Getting real clicks for ${widget.server.id} on $date');
    print('DEBUG: Individual clicks found: ${clicks.length}');
    
    // Sort clicks by time (newest first for display)
    clicks.sort((a, b) => b.compareTo(a));
    return clicks;
  }

  String _formatTimeLabel(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final second = time.second;
    final millisecond = time.millisecond;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.${millisecond.toString().padLeft(3, '0')} $period';
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        if (_clickData.map((d) => d.clickCount).fold(0, (a, b) => a + b) != _individualClicks.length) ...[
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
                                Icon(Icons.warning, color: Colors.orange[600], size: 20),
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
                                Icon(Icons.touch_app, size: 48, color: Colors.grey[400]),
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
                            itemCount: _individualClicks.length,
                            itemBuilder: (context, index) {
                              final clickTime = _individualClicks[index];
                              final isToday = _isToday(clickTime);
                              final timeAgo = _getTimeAgo(clickTime);
                              
                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isToday ? Colors.green[100] : Colors.blue[100],
                                    child: Icon(
                                      Icons.touch_app,
                                      color: isToday ? Colors.green[600] : Colors.blue[600],
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    _formatFullDateTime(clickTime),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    timeAgo,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: isToday
                                      ? Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green[300]!),
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
                                      : null,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
                    _clickData.map((d) => d.clickCount).fold(0, (a, b) => a + b).toString(),
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
                    (_clickData.map((d) => d.clickCount).fold(0, (a, b) => a + b) / _clickData.length).toStringAsFixed(1),
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
                  // Chart Title
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Clicks per 15-minute interval',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  
                  // Bar Chart
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxClicks > 0 ? maxClicks.toDouble() * 1.1 : 10,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              if (groupIndex < _clickData.length) {
                                final dataPoint = _clickData[groupIndex];
                                return BarTooltipItem(
                                  '${dataPoint.label}\n${dataPoint.clickCount} clicks',
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
                                color: _getBarColor(dataPoint.clickCount, maxClicks),
                                width: 8,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxClicks > 0 ? maxClicks.toDouble() * 1.1 : 10,
                                  color: Colors.grey[100],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxClicks > 10 ? (maxClicks / 5).ceilToDouble() : 2,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[200]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                      ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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

  Color _getBarColor(int clickCount, int maxClicks) {
    if (maxClicks == 0) return Colors.grey[300]!;
    
    final intensity = clickCount / maxClicks;
    if (intensity > 0.8) return Colors.red[400]!;      // High activity
    if (intensity > 0.6) return Colors.orange[400]!;   // Medium-high activity
    if (intensity > 0.4) return Colors.yellow[600]!;   // Medium activity
    if (intensity > 0.2) return Colors.blue[400]!;     // Low-medium activity
    return Colors.grey[400]!;                          // Low activity
  }

  String _getPeakPeriod() {
    if (_clickData.isEmpty) return 'N/A';
    
    final maxClicks = _clickData.map((d) => d.clickCount).reduce(max);
    final peakDataPoint = _clickData.firstWhere((d) => d.clickCount == maxClicks);
    
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
    
    return '${displayHour}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.${millisecond.toString().padLeft(3, '0')} $period';
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
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.datesWithData,
    required this.serverName,
  }) : super(key: key);

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
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
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
    return widget.datesWithData.contains(DateTime(date.year, date.month, date.day));
  }

  @override
  Widget build(BuildContext context) {
    final monthName = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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
                  onPressed: _currentMonth.isAfter(widget.firstDate) ? _previousMonth : null,
                  icon: Icon(Icons.chevron_left),
                ),
                Text(
                  '$monthName ${_currentMonth.year}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: _currentMonth.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month, 1)) ? _nextMonth : null,
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
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600]),
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
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to 0=Sunday format
    
    final days = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(Container(width: 35, height: 35));
    }
    
    // Add days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = _selectedDate.year == date.year && 
                        _selectedDate.month == date.month && 
                        _selectedDate.day == date.day;
      final hasData = _isDateWithData(date);
      final isInRange = date.isAfter(widget.firstDate.subtract(Duration(days: 1))) && 
                       date.isBefore(widget.lastDate.add(Duration(days: 1)));
      
      days.add(
        GestureDetector(
          onTap: isInRange ? () {
            setState(() {
              _selectedDate = date;
            });
          } : null,
          child: Container(
            width: 35,
            height: 35,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.blue 
                  : (isInRange ? Colors.transparent : Colors.grey[100]),
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? null : Border.all(
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        weekDays.add(Container(width: 35, height: 35));
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