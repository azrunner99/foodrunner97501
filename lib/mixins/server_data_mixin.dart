import '../models.dart';
import '../models/server.dart';
import '../models/monthly_report.dart';
import '../services/server_data_service.dart';
import '../services/server_id_resolver.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import '../utils/log.dart';

/// Standardized data access mixin for widgets
/// 
/// Provides consistent, type-safe data access methods that automatically:
/// - Resolve server IDs (handles both String and numeric formats)
/// - Filter out orphaned/invalid data
/// - Use caching where available
/// - Provide consistent error handling
/// 
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with ServerDataMixin {
///   Future<void> _loadData() async {
///     // Automatic ID resolution, filtering, and typing
///     final servers = await getAllServers();
///     
///     for (final server in servers) {
///       final reports = await getServerNPSHistory(server.id);
///       // `reports` is typed List<NPSMonthlyReport>
///     }
///   }
/// }
/// ```
/// 
/// Benefits:
/// - ✅ Eliminates manual ID filtering (RegExp checks)
/// - ✅ Eliminates direct database access
/// - ✅ Provides type-safe return values (no raw Maps)
/// - ✅ Consistent error handling across all widgets
/// - ✅ Automatic caching via ServerDataService
mixin ServerDataMixin {
  final NPSDatabaseAdapter _adapter = NPSDatabaseAdapter(DatabaseFactory.instance);
  
  /// Get server by any ID format
  /// 
  /// Automatically resolves numeric IDs, string IDs, and UUIDs to the
  /// canonical server. Returns null if server doesn't exist.
  /// 
  /// Example:
  /// ```dart
  /// final server1 = await getServerById('1');
  /// final server2 = await getServerById('server_001');
  /// // Both return the same server
  /// ```
  Future<Server?> getServerById(String id) async {
    try {
      return await ServerDataService.instance.getServer(id);
    } catch (e) {
      d('[ServerDataMixin] Error getting server $id: $e');
      return null;
    }
  }
  
  /// Get all servers with automatic filtering
  /// 
  /// Returns deduplicated list of servers, automatically filtering out:
  /// - Orphaned numeric IDs (e.g., "1", "2", "3" without proper names)
  /// - Duplicate entries across storage systems
  /// 
  /// Note: Server archiving is handled at the AppState level via ServerProfile.
  /// This method returns all servers from AppState regardless of archive status.
  /// 
  /// Example:
  /// ```dart
  /// final servers = await getAllServers();
  /// ```
  Future<List<Server>> getAllServers() async {
    try {
      return await ServerDataService.instance.getAllServers();
    } catch (e) {
      d('[ServerDataMixin] Error getting all servers: $e');
      return [];
    }
  }
  
  /// Get NPS monthly reports for a server
  /// 
  /// Automatically resolves server ID and returns typed list of reports.
  /// Filters out invalid/orphaned data.
  /// 
  /// Example:
  /// ```dart
  /// final reports = await getServerNPSHistory('server_001');
  /// for (final report in reports) {
  ///   print('${report.monthYear}: ${report.oneMonthNpsPercentage}%');
  /// }
  /// ```
  Future<List<NPSMonthlyReport>> getServerNPSHistory(String serverId) async {
    try {
      // Resolve canonical ID
      final canonicalId = ServerIdResolver.instance.getCanonicalId(serverId);
      
      // Query monthly reports
      final results = await _adapter.queryTable(
        'nps_monthly_reports',
        where: 'server_id = ?',
        whereArgs: [canonicalId],
        orderBy: 'report_year DESC, report_month DESC',
      );
      
      // Convert to typed objects
      return results.map((row) => NPSMonthlyReport.fromMap(row)).toList();
    } catch (e) {
      d('[ServerDataMixin] Error getting NPS history for $serverId: $e');
      return [];
    }
  }
  
  /// Get NPS feedback for a server within a date range
  /// 
  /// Example:
  /// ```dart
  /// final feedback = await getServerNPSFeedback(
  ///   'server_001',
  ///   startDate: DateTime(2025, 1, 1),
  ///   endDate: DateTime(2025, 12, 31),
  /// );
  /// ```
  // REMOVED: Individual feedback tracking no longer used
  /* Future<List<NPSFeedback>> getServerNPSFeedback(
    String serverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Individual feedback no longer tracked
    return [];
  } */
  
  /// Get all NPS monthly reports (across all servers)
  /// 
  /// Automatically filters out orphaned numeric server IDs.
  /// Useful for dashboard/analytics widgets that show data for all servers.
  /// 
  /// Example:
  /// ```dart
  /// final allReports = await getAllNPSMonthlyReports();
  /// // Returns only reports for valid servers (no "Server #1" orphans)
  /// ```
  Future<List<NPSMonthlyReport>> getAllNPSMonthlyReports({
    int? year,
    int? month,
  }) async {
    try {
      // Build where clause
      String? where;
      List<dynamic>? whereArgs;
      
      if (year != null || month != null) {
        where = '';
        whereArgs = [];
        
        if (year != null) {
          where = 'report_year = ?';
          whereArgs.add(year);
        }
        
        if (month != null) {
          if (where.isNotEmpty) where += ' AND ';
          where += 'report_month = ?';
          whereArgs.add(month);
        }
      }
      
      // Query all reports
      final results = await _adapter.queryTable(
        'nps_monthly_reports',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'report_year DESC, report_month DESC',
      );
      
      // Filter out orphaned numeric server IDs
      // This prevents "Server #1" phantom entries from appearing in widgets
      final filteredResults = results.where((row) {
        final serverId = row['server_id']?.toString() ?? '';
        final isOrphanedNumericId = RegExp(r'^\d+$').hasMatch(serverId);
        
        if (isOrphanedNumericId) {
          d('[ServerDataMixin] Filtering out orphaned numeric server_id: $serverId');
        }
        
        return !isOrphanedNumericId;
      }).toList();
      
      // Convert to typed objects
      return filteredResults.map((row) => NPSMonthlyReport.fromMap(row)).toList();
    } catch (e) {
      d('[ServerDataMixin] Error getting all NPS monthly reports: $e');
      return [];
    }
  }
  
  /// Check if server exists by any ID format
  /// 
  /// Useful for validation before performing operations.
  /// 
  /// Example:
  /// ```dart
  /// if (await serverExists('server_001')) {
  ///   // Safe to proceed
  /// }
  /// ```
  Future<bool> serverExists(String id) async {
    try {
      final server = await getServerById(id);
      return server != null;
    } catch (e) {
      d('[ServerDataMixin] Error checking if server exists: $e');
      return false;
    }
  }
  
  /// Get server name by ID (convenience method)
  /// 
  /// Returns server name or a fallback string if not found.
  /// 
  /// Example:
  /// ```dart
  /// final name = await getServerName('server_001'); // "John Doe"
  /// final unknown = await getServerName('invalid'); // "Unknown Server"
  /// ```
  Future<String> getServerName(String id, {String fallback = 'Unknown Server'}) async {
    try {
      final server = await getServerById(id);
      return server?.name ?? fallback;
    } catch (e) {
      d('[ServerDataMixin] Error getting server name: $e');
      return fallback;
    }
  }
  
  /// Invalidate the server data cache
  /// 
  /// Call this after adding/updating/deleting servers to ensure
  /// widgets see the latest data.
  /// 
  /// Example:
  /// ```dart
  /// await _saveNewServer(server);
  /// invalidateServerCache(); // Force refresh
  /// await _loadData(); // Will fetch fresh data
  /// ```
  void invalidateServerCache() {
    ServerDataService.instance.invalidateCache();
    d('[ServerDataMixin] Cache invalidated');
  }
}

