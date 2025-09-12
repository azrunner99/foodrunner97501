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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 90)), // Last 90 days
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
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
                    child: Row(
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
          // Chart Title and Stats
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