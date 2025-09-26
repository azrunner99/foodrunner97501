import 'package:flutter/material.dart';
import 'package:food_runs_counter/models/server.dart';
import 'package:food_runs_counter/models/performance_models.dart';
import 'package:food_runs_counter/utils/performance_calculator.dart';
import 'package:food_runs_counter/services/performance_flags.dart';

class ServerPerformanceScreen extends StatefulWidget {
  @override
  _ServerPerformanceScreenState createState() => _ServerPerformanceScreenState();
}

class _ServerPerformanceScreenState extends State<ServerPerformanceScreen> {
  List<ServerPerformanceData> _performanceData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading data
    await Future.delayed(Duration(seconds: 1));

    // Create sample data
    _performanceData = [
      ServerPerformanceData(
        serverId: '1',
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now(),
        totalFoodRuns: 45,
        shiftsWorked: 12,
        daysEmployed: 30,
        totalGuestCount: 120,
        totalSales: 2500.0,
        shiftTypes: [],
        metrics: PerformanceMetrics(
          rawEfficiency: 3.75,
          guestEfficiency: 0.375,
          salesEfficiency: 0.018,
          consistencyScore: 85.0,
          experienceFactor: 0.8,
          adjustedPerformance: 90.0,
          npsScore: 85.0,
          npsThreeMonth: 82.0,
          npsOneMonth: 88.0,
        ),
        performanceScore: 87.5,
        rating: PerformanceRating.developing,
        flags: [],
        insights: [],
        calculatedDate: DateTime.now(),
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Server Performance'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _performanceData.isEmpty
              ? Center(child: Text('No performance data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _performanceData.length,
                  itemBuilder: (context, index) {
                    final performance = _performanceData[index];
                    return _buildPerformanceCard(performance, index + 1);
                  },
                ),
    );
  }

  Widget _buildPerformanceCard(ServerPerformanceData performance, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 8,
      child: InkWell(
        onTap: () => _showPerformanceDetails(performance),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Simple Rank Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Server Name
                  Expanded(
                    child: Text(
                      'Server $performance.serverId',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Performance Score
                  Text(
                    '${performance.performanceScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Simple metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Runs: ${performance.totalFoodRuns}'),
                  Text('Shifts: ${performance.shiftsWorked}'),
                  Text('Rating: ${performance.rating.displayName}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPerformanceDetails(ServerPerformanceData performance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Performance Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: ${performance.performanceScore.toStringAsFixed(1)}%'),
            Text('Runs: ${performance.totalFoodRuns}'),
            Text('Shifts: ${performance.shiftsWorked}'),
            Text('Rating: ${performance.rating.displayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
