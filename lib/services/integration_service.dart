import 'database_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IntegrationService {
  final String apiUrl = 'https://example.com/api';

  Future<void> syncMonthlyReports() async {
    final response = await http.get(Uri.parse('$apiUrl/monthly_reports'));

    if (response.statusCode == 200) {
      final List<dynamic> reports = json.decode(response.body);

      for (var report in reports) {
        // Process and save each report locally
        // Assuming DatabaseService is already implemented
        await DatabaseService().insert('monthly_reports', {
          'server_id': report['server_id'],
          'month': report['month'],
          'nps_score': report['nps_score'],
          'feedback_count': report['feedback_count'],
        });
      }
    } else {
      throw Exception('Failed to fetch monthly reports');
    }
  }

  Future<void> pushLocalReports() async {
    final localReports = await DatabaseService().query('monthly_reports');

    for (var report in localReports) {
      final response = await http.post(
        Uri.parse('$apiUrl/monthly_reports'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(report),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to push report: ${report['id']}');
      }
    }
  }
}
