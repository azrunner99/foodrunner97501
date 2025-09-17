import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Future<List<Map<String, dynamic>>> _fetchAnalyticsData() async {
    final dbService = DatabaseService();
    return await dbService.query('monthly_reports');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics and Reporting'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAnalyticsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching analytics data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No analytics data available'));
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final report = data[index];
                return ListTile(
                  title: Text('Server ID: ${report['server_id']}'),
                  subtitle: Text('Month: ${report['month']}\nNPS Score: ${report['nps_score']}\nFeedback Count: ${report['feedback_count']}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}