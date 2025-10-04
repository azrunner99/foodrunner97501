import 'database_interface.dart';
import 'database_factory.dart';
import '../models/server.dart';
import '../models/nps_feedback.dart';
import '../utils/log.dart';
import '../services/query_cache_service.dart';

/// Adapter class that provides NPSDatabase-compatible methods
/// using the platform-agnostic DatabaseInterface
/// 
/// This adapter bridges the gap between the old NPSDatabase API
/// and the new cross-platform database interface.
class NPSDatabaseAdapter {
  final DatabaseInterface _db;
  final QueryCacheService _cache = QueryCacheService();

  NPSDatabaseAdapter(this._db);

  /// Safely convert server ID from database to String format
  /// Handles both legacy int IDs and new String IDs
  String _convertToStringId(dynamic serverId) {
    if (serverId == null) return '';
    if (serverId is String) return serverId;
    if (serverId is int) return serverId.toString();
    return serverId.toString();
  }

  /// Check if this adapter is using Sqflite database
  bool get isSqfliteDatabase => DatabaseFactory.implementationType.contains('Sqflite');
  
  /// Get the correct timestamp column name based on database type
  String get timestampColumn => isSqfliteDatabase ? 'timestamp_created' : 'created_at';

  /// Get all servers from the database (with caching)
  Future<List<Map<String, dynamic>>> getAllServers({bool activeOnly = true}) async {
    try {
      final cacheKey = activeOnly ? CacheKeys.serverList() : 'servers:list:all';
      
      return await _cache.getOrExecute(
        cacheKey,
        () async {
          if (activeOnly) {
            return await _db.queryTable('servers', where: 'active = 1', orderBy: 'name ASC');
          } else {
            return await _db.queryTable('servers', orderBy: 'name ASC');
          }
        },
        ttl: const Duration(minutes: 10), // Cache server list for 10 minutes
      );
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting all servers: $e');
      rethrow;
    }
  }

  /// Insert a new server
  Future<String> insertServer(Map<String, dynamic> serverData) async {
    try {
      // For Sqflite (Android), IDs are auto-generated integers
      // For Drift (Desktop), IDs are manually provided strings
      if (isSqfliteDatabase) {
        // Remove any existing ID for auto-generation
        final dataWithoutId = Map<String, dynamic>.from(serverData);
        dataWithoutId.remove('id');
        final generatedId = await _db.insertInto('servers', dataWithoutId);
        return generatedId.toString();
      } else {
        // For Drift, ensure we have a string ID
        if (!serverData.containsKey('id') || serverData['id'] == null) {
          // Generate a unique string ID if not provided
          serverData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        }
        await _db.insertInto('servers', serverData);
        return serverData['id'] as String;
      }
    } catch (e) {
      d('[NPSDatabaseAdapter] Error inserting server: $e');
      rethrow;
    }
  }

  /// Update an existing server
  Future<int> updateServer(String id, Map<String, dynamic> serverData) async {
    try {
      return await _db.updateTable('servers', serverData, 'id = ?', [id]);
    } catch (e) {
      d('[NPSDatabaseAdapter] Error updating server: $e');
      rethrow;
    }
  }

  /// Delete a server
  Future<int> deleteServer(String id) async {
    try {
      return await _db.deleteFrom('servers', 'id = ?', [id]);
    } catch (e) {
      d('[NPSDatabaseAdapter] Error deleting server: $e');
      rethrow;
    }
  }

  /// Get feedback for a specific server
  Future<List<Map<String, dynamic>>> getFeedbackForServer(String serverId) async {
    try {
      return await _db.queryTable(
        'nps_feedback',
        where: 'server_id = ?',
        whereArgs: [serverId],
        orderBy: '$timestampColumn DESC',
      );
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting feedback for server: $e');
      rethrow;
    }
  }

  /// Get feedback for a specific server within a date range
  Future<List<Map<String, dynamic>>> getFeedbackForServerInRange(
      String serverId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      String whereClause = 'server_id = ?';
      List<dynamic> whereArgs = [serverId];

      if (startDate != null) {
        whereClause += ' AND $timestampColumn >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        whereClause += ' AND $timestampColumn <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      return await _db.queryTable(
        'nps_feedback',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '$timestampColumn DESC',
      );
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting feedback for server in range: $e');
      rethrow;
    }
  }

  /// Get feedback in a date range
  Future<List<Map<String, dynamic>>> getFeedbackInDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      return await _db.queryTable(
        'nps_feedback',
        where: '$timestampColumn >= ? AND $timestampColumn <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: '$timestampColumn DESC',
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
      print('[NPSDatabaseAdapter] getServerNPSDataForMonth called with month: $reportMonth, year: $reportYear');
      print('[NPSDatabaseAdapter] isSqfliteDatabase: $isSqfliteDatabase');
      
      List<Map<String, dynamic>> monthlyReports;
      
      // Handle different database schemas
      if (isSqfliteDatabase) {
        // Sqflite uses month_year field in YYYYMM format
        // Convert separate month/year to YYYYMM format
        final monthYearStr = '${reportYear}${reportMonth.toString().padLeft(2, '0')}';
        print('[NPSDatabaseAdapter] Querying Sqflite with month_year = $monthYearStr');
        monthlyReports = await _db.queryTable(
          'nps_monthly_reports',
          where: 'month_year = ?',
          whereArgs: [monthYearStr],
        );
      } else {
        // Drift uses separate report_month and report_year columns
        print('[NPSDatabaseAdapter] Querying Drift with report_month = $reportMonth, report_year = $reportYear');
        monthlyReports = await _db.queryTable(
          'nps_monthly_reports',
          where: 'report_month = ? AND report_year = ?',
          whereArgs: [reportMonth, reportYear],
        );
      }
      
      print('[NPSDatabaseAdapter] Found ${monthlyReports.length} monthly reports');
      for (int i = 0; i < monthlyReports.length; i++) {
        print('[NPSDatabaseAdapter] Report $i: ${monthlyReports[i]}');
      }
      
      if (monthlyReports.isEmpty) {
        d('[NPSDatabaseAdapter] No monthly reports found for $reportMonth/$reportYear');
        return [];
      }
      
      // Get server names for each report and combine the data
      final serverData = <Map<String, dynamic>>[];
      for (final report in monthlyReports) {
        final serverId = _convertToStringId(report['server_id']);
        print('[NPSDatabaseAdapter] Looking up server with ID: $serverId');
        
        // Try to find server by original_id first (matches admin-entered data), then by id
        var servers = await _db.queryTable(
          'servers',
          where: 'original_id = ?',
          whereArgs: [serverId],
        );
        
        // If not found by original_id, try by id (for backward compatibility)
        if (servers.isEmpty) {
          servers = await _db.queryTable(
            'servers',
            where: 'id = ?',
            whereArgs: [serverId],
          );
        }
        
        print('[NPSDatabaseAdapter] Found ${servers.length} servers for ID $serverId');
        if (servers.isNotEmpty) {
          final server = servers.first;
          print('[NPSDatabaseAdapter] Server name: ${server['name']}');
          final serverReport = {
            'server_name': server['name'],
            'server_id': serverId,
            'all_time_nps_percentage': report['all_time_nps_percentage'],
            'three_month_nps_percentage': report['three_month_nps_percentage'],
            'one_month_nps_percentage': report['one_month_nps_percentage'],
            'all_time_sales': report['all_time_sales'],
            'all_time_table_count': report['all_time_table_count'],
            'month_feedback_yes': report['month_feedback_yes'],
            'month_feedback_maybe': report['month_feedback_maybe'],
            'month_feedback_no': report['month_feedback_no'],
            'three_month_feedback_yes': report['three_month_feedback_yes'],
            'three_month_feedback_maybe': report['three_month_feedback_maybe'],
            'three_month_feedback_no': report['three_month_feedback_no'],
            'all_time_feedback_yes': report['all_time_feedback_yes'],
            'all_time_feedback_maybe': report['all_time_feedback_maybe'],
            'all_time_feedback_no': report['all_time_feedback_no'],
          };
          serverData.add(serverReport);
          print('[NPSDatabaseAdapter] Added server report: $serverReport');
        }
      }
      
      // Sort by server name
      serverData.sort((a, b) => (a['server_name'] as String).compareTo(b['server_name'] as String));
      
      d('[NPSDatabaseAdapter] Retrieved NPS data for ${serverData.length} servers for $reportMonth/$reportYear');
      return serverData;
    } catch (e) {
      print('[NPSDatabaseAdapter] Error getting server NPS data for month: $e');
      d('[NPSDatabaseAdapter] Error getting server NPS data for month: $e');
      rethrow;
    }
  }

  /// Get monthly report for a server (with caching)
  Future<Map<String, dynamic>?> getMonthlyReport(String serverId, int reportMonth) async {
    try {
      final cacheKey = CacheKeys.monthlyReport(serverId, reportMonth);
      
      return await _cache.getOrExecute(
        cacheKey,
        () async {
          // Query the nps_monthly_reports table for saved data
          final reports = await _db.queryTable(
            'nps_monthly_reports',
            where: 'server_id = ? AND month_year = ?',
            whereArgs: [serverId, '${reportMonth.toString().padLeft(6, '0')}'],
          );
          
          return reports.isNotEmpty ? reports.first : null;
        },
        ttl: const Duration(minutes: 5), // Cache for 5 minutes
      );
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting monthly report: $e');
      rethrow;
    }
  }

  /// Get available report months (legacy-compatible shape)
  ///
  /// Returns a list of maps each containing:
  ///   report_month (int)  -> numeric month (1-12)
  ///   report_year  (int)  -> 4-digit year
  ///   server_count (int)  -> number of servers with a report for that month
  ///
  /// Tries to source from the modern nps_monthly_reports table first. If none
  /// are found, falls back to deriving distinct months from raw feedback.
  Future<List<Map<String, dynamic>>> getAvailableReportMonths() async {
    try {
      // Attempt to build from monthly reports table (preferred – structured summaries)
      final monthlyReports = await _db.queryTable(
        'nps_monthly_reports',
        columns: ['month_year', 'server_id'],
        orderBy: 'month_year DESC',
      );

      if (monthlyReports.isNotEmpty) {
        final Map<String, Set<String>> monthToServers = {};
        for (final row in monthlyReports) {
          final monthYear = (row['month_year'] as String?)?.trim();
          if (monthYear == null || monthYear.isEmpty) continue;
          final serverId = _convertToStringId(row['server_id']);
          monthToServers.putIfAbsent(monthYear, () => <String>{}).add(serverId);
        }

        final List<Map<String, dynamic>> result = [];
        for (final entry in monthToServers.entries) {
          // Expect format YYYY-MM; parse defensively
          final parts = entry.key.split('-');
            int year = 0;
            int month = 0;
            if (parts.length == 2) {
              year = int.tryParse(parts[0]) ?? 0;
              month = int.tryParse(parts[1]) ?? 0;
            } else if (entry.key.length == 6) { // e.g. YYYYMM
              year = int.tryParse(entry.key.substring(0,4)) ?? 0;
              month = int.tryParse(entry.key.substring(4,6)) ?? 0;
            }
          if (year > 0 && month > 0) {
            result.add({
              'report_year': year,
              'report_month': month,
              'server_count': entry.value.length,
            });
          }
        }

        // Sort descending by year then month
        result.sort((a,b){
          final ay = a['report_year'] as int; final by = b['report_year'] as int;
          if (ay != by) return by.compareTo(ay);
          final am = a['report_month'] as int; final bm = b['report_month'] as int;
          return bm.compareTo(am);
        });

        if (result.isNotEmpty) {
          d('[NPSDatabaseAdapter] getAvailableReportMonths -> ${result.length} months from nps_monthly_reports');
          return result;
        }
      }

      // Fallback: derive from feedback timestamps (earliest schema)
      final feedbackRows = await _db.queryTable(
        'nps_feedback',
        columns: ['timestamp_created', 'server_id'],
        orderBy: 'timestamp_created DESC',
      );

      final Map<String, Set<String>> monthToServersFromFeedback = {};
      for (final row in feedbackRows) {
        final ts = row['timestamp_created'] as String?;
        if (ts == null || ts.isEmpty) continue;
        DateTime? dt;
        try { dt = DateTime.tryParse(ts); } catch (_) {}
        if (dt == null) continue;
        final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
        final serverId = _convertToStringId(row['server_id']);
        monthToServersFromFeedback.putIfAbsent(key, () => <String>{}).add(serverId);
      }

      final List<Map<String, dynamic>> derived = [];
      for (final entry in monthToServersFromFeedback.entries) {
        final parts = entry.key.split('-');
        if (parts.length == 2) {
          final year = int.tryParse(parts[0]) ?? 0;
          final month = int.tryParse(parts[1]) ?? 0;
          if (year > 0 && month > 0) {
            derived.add({
              'report_year': year,
              'report_month': month,
              'server_count': entry.value.length,
            });
          }
        }
      }
      derived.sort((a,b){
        final ay = a['report_year'] as int; final by = b['report_year'] as int;
        if (ay != by) return by.compareTo(ay);
        final am = a['report_month'] as int; final bm = b['report_month'] as int;
        return bm.compareTo(am);
      });
      d('[NPSDatabaseAdapter] getAvailableReportMonths -> ${derived.length} months derived from feedback');
      return derived;
    } catch (e) {
      d('[NPSDatabaseAdapter] Error getting available report months: $e');
      return [];
    }
  }

  /// Insert or update a monthly report
  Future<int> insertOrUpdateMonthlyReport(Map<String, dynamic> report) async {
    try {
      final serverId = report['server_id'];
      final monthYear = report['month_year'];
      
      // Try to insert first
      try {
        final id = await _db.insertInto('nps_monthly_reports', report);
        d('[NPSDatabaseAdapter] Inserted monthly report with ID: $id');
        
        // Invalidate related cache entries
        _cache.invalidate(CacheKeys.monthlyReport(serverId, int.parse(monthYear.replaceAll('-', ''))));
        _cache.invalidatePattern('monthly_reports:month:');
        
        return id;
      } catch (e) {
        // If insertion fails (likely due to unique constraint), update instead
        final rowsAffected = await _db.updateTable(
          'nps_monthly_reports',
          report,
          'server_id = ? AND month_year = ?',
          [serverId, monthYear],
        );
        d('[NPSDatabaseAdapter] Updated existing monthly report, rows affected: $rowsAffected');
        
        // Invalidate related cache entries
        _cache.invalidate(CacheKeys.monthlyReport(serverId, int.parse(monthYear.replaceAll('-', ''))));
        _cache.invalidatePattern('monthly_reports:month:');
        
        return rowsAffected;
      }
    } catch (e) {
      d('[NPSDatabaseAdapter] Error inserting/updating monthly report: $e');
      rethrow;
    }
  }
}