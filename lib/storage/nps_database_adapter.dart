import 'database_interface.dart';
import '../models/server.dart';
import '../models/nps_feedback.dart';
import '../utils/log.dart';

/// Adapter class that provides NPSDatabase-compatible methods
/// using the platform-agnostic DatabaseInterface
/// 
/// This adapter bridges the gap between the old NPSDatabase API
/// and the new cross-platform database interface.
class NPSDatabaseAdapter {
  final DatabaseInterface _db;

  NPSDatabaseAdapter(this._db);

  /// Get all servers from the database
  Future<List<Map<String, dynamic>>> getAllServers({bool activeOnly = true}) async {
    try {
      if (activeOnly) {
        return await _db.queryTable('servers', where: 'active = 1', orderBy: 'name ASC');
      } else {
        return await _db.queryTable('servers', orderBy: 'name ASC');
      }
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting all servers: $e');
      rethrow;
    }
  }

  /// Insert a new server
  Future<int> insertServer(Map<String, dynamic> serverData) async {
    try {
      return await _db.insertInto('servers', serverData);
    } catch (e) {
      d('[NPSDatabaseAdapter] Error inserting server: $e');
      rethrow;
    }
  }

  /// Update an existing server
  Future<int> updateServer(int id, Map<String, dynamic> serverData) async {
    try {
      return await _db.updateTable('servers', serverData, 'id = ?', [id]);
    } catch (e) {
      d('[NPSDatabaseAdapter] Error updating server: $e');
      rethrow;
    }
  }

  /// Delete a server
  Future<int> deleteServer(int id) async {
    try {
      return await _db.deleteFrom('servers', 'id = ?', [id]);
    } catch (e) {
      d('[NPSDatabaseAdapter] Error deleting server: $e');
      rethrow;
    }
  }

  /// Get feedback for a specific server
  Future<List<Map<String, dynamic>>> getFeedbackForServer(int serverId) async {
    try {
      return await _db.queryTable(
        'nps_feedback',
        where: 'server_id = ?',
        whereArgs: [serverId],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting feedback for server: $e');
      rethrow;
    }
  }

  /// Get feedback in a date range
  Future<List<Map<String, dynamic>>> getFeedbackInDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      return await _db.queryTable(
        'nps_feedback',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting feedback in date range: $e');
      rethrow;
    }
  }

  /// Insert feedback
  Future<int> insertFeedback(Map<String, dynamic> feedbackData) async {
    try {
      return await _db.insertInto('nps_feedback', feedbackData);
    } catch (e) {
      d('[NPSDatabaseAdapter] Error inserting feedback: $e');
      rethrow;
    }
  }

  /// Get server NPS data for a specific month
  Future<List<Map<String, dynamic>>> getServerNPSDataForMonth(
      int reportMonth, int reportYear) async {
    try {
      final startDate = DateTime(reportYear, reportMonth, 1);
      final endDate = DateTime(reportYear, reportMonth + 1, 0, 23, 59, 59);
      
      final feedback = await getFeedbackInDateRange(startDate, endDate);
      
      return feedback;
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting server NPS data for month: $e');
      rethrow;
    }
  }

  /// Get monthly report for a server
  Future<Map<String, dynamic>?> getMonthlyReport(int serverId, int reportMonth) async {
    try {
      final currentYear = DateTime.now().year;
      final feedback = await _db.queryTable(
        'nps_feedback',
        where: 'server_id = ? AND strftime("%Y-%m", created_at) = ?',
        whereArgs: [serverId, '$currentYear-${reportMonth.toString().padLeft(2, '0')}'],
      );
      
      if (feedback.isEmpty) return null;
      
      return {
        'server_id': serverId,
        'month': '$currentYear-$reportMonth',
        'feedback_count': feedback.length,
        'feedback': feedback,
      };
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting monthly report: $e');
      rethrow;
    }
  }

  /// Get available report months that have feedback data
  Future<List<String>> getAvailableReportMonths() async {
    try {
      final result = await _db.queryTable(
        'nps_feedback',
        columns: ['strftime("%Y-%m", created_at) as month'],
        groupBy: 'strftime("%Y-%m", created_at)',
        orderBy: 'strftime("%Y-%m", created_at) DESC',
      );
      
      return result.map((row) => row['month'] as String).toList();
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting available report months: $e');
      return [];
    }
  }
}