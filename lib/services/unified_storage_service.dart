import 'dart:convert';
import '../storage/unified_database.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../utils/log.dart';

/// Unified Storage Service
/// 
/// This service provides a single interface to access all application data
/// through the unified Drift database. It replaces the previous multi-storage
/// architecture (Hive + SQLite + Enhanced Business Data) with a single solution.
class UnifiedStorageService {
  static UnifiedStorageService? _instance;
  static UnifiedStorageService get instance => _instance ??= UnifiedStorageService._();
  
  UnifiedStorageService._();
  
  late UnifiedDatabase _db;
  bool _isInitialized = false;
  
  /// Initialize the unified storage service
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _db = UnifiedDatabase();
      await _db.init();
      _isInitialized = true;
      d('[UnifiedStorageService] Initialized successfully');
    } catch (e) {
      d('[UnifiedStorageService] Error initializing: $e');
      rethrow;
    }
  }
  
  /// Ensure database is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }
  
  // ============================================================================
  // SERVER OPERATIONS
  // ============================================================================
  
  /// Get all servers
  Future<List<Server>> getAllServers() async {
    await _ensureInitialized();
    
    try {
      final rows = await _db.select(_db.servers);
      return rows.map((row) => Server(
        id: row.originalId ?? row.id.toString(),
        name: row.name,
        teamColor: row.teamColor,
        stationType: row.stationType,
        hireDate: DateTime.tryParse(row.hireDate),
      )).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting servers: $e');
      return [];
    }
  }
  
  /// Save a server
  Future<void> saveServer(Server server) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.servers).insertOnConflictUpdate(ServersCompanion(
        originalId: Value(server.id),
        name: Value(server.name),
        teamColor: Value(server.teamColor),
        stationType: Value(server.stationType),
        hireDate: Value(server.hireDate?.toIso8601String() ?? ''),
        active: Value(true),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
      d('[UnifiedStorageService] Server saved: ${server.name}');
    } catch (e) {
      d('[UnifiedStorageService] Error saving server: $e');
      rethrow;
    }
  }
  
  /// Delete a server
  Future<void> deleteServer(String serverId) async {
    await _ensureInitialized();
    
    try {
      await (_db.delete(_db.servers)
        ..where((tbl) => tbl.originalId.equals(serverId))).go();
      d('[UnifiedStorageService] Server deleted: $serverId');
    } catch (e) {
      d('[UnifiedStorageService] Error deleting server: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // SHIFT OPERATIONS
  // ============================================================================
  
  /// Get all shift records
  Future<List<ShiftRecord>> getAllShifts() async {
    await _ensureInitialized();
    
    try {
      final rows = await _db.select(_db.shiftRecords);
      return rows.map((row) => ShiftRecord(
        id: row.id,
        label: row.label,
        shiftType: row.shiftType,
        start: DateTime.parse(row.startDate),
        counts: Map<String, int>.from(jsonDecode(row.counts)),
        pizookieCounts: row.pizookieCounts != null 
          ? Map<String, int>.from(jsonDecode(row.pizookieCounts!))
          : <String, int>{},
        stationAssignments: row.stationAssignments != null 
          ? Map<String, String>.from(jsonDecode(row.stationAssignments!))
          : <String, String>{},
        sectionAssignments: row.sectionAssignments != null 
          ? Map<String, String>.from(jsonDecode(row.sectionAssignments!))
          : <String, String>{},
      )).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting shifts: $e');
      return [];
    }
  }
  
  /// Save a shift record
  Future<void> saveShift(ShiftRecord shift) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.shiftRecords).insertOnConflictUpdate(ShiftRecordsCompanion(
        id: Value(shift.id),
        label: Value(shift.label),
        shiftType: Value(shift.shiftType),
        startDate: Value(shift.start.toIso8601String()),
        counts: Value(jsonEncode(shift.counts)),
        pizookieCounts: Value(shift.pizookieCounts.isNotEmpty ? jsonEncode(shift.pizookieCounts) : null),
        stationAssignments: Value(shift.stationAssignments?.isNotEmpty == true ? jsonEncode(shift.stationAssignments!) : null),
        sectionAssignments: Value(shift.sectionAssignments?.isNotEmpty == true ? jsonEncode(shift.sectionAssignments!) : null),
      ));
      d('[UnifiedStorageService] Shift saved: ${shift.id}');
    } catch (e) {
      d('[UnifiedStorageService] Error saving shift: $e');
      rethrow;
    }
  }
  
  /// Delete a shift record
  Future<void> deleteShift(String shiftId) async {
    await _ensureInitialized();
    
    try {
      await (_db.delete(_db.shiftRecords)
        ..where((tbl) => tbl.id.equals(shiftId))).go();
      d('[UnifiedStorageService] Shift deleted: $shiftId');
    } catch (e) {
      d('[UnifiedStorageService] Error deleting shift: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // SERVER PROFILE OPERATIONS
  // ============================================================================
  
  /// Get all server profiles
  Future<List<ServerProfile>> getAllServerProfiles() async {
    await _ensureInitialized();
    
    try {
      final rows = await _db.select(_db.serverProfiles);
      return rows.map((row) => ServerProfile(
        serverId: row.serverId,
        avatarPath: row.avatarPath,
        birthday: row.birthday,
        hireDate: row.hireDate != null ? DateTime.tryParse(row.hireDate!) : null,
        teamColor: row.teamColor,
        stationType: row.stationType,
        performanceData: row.performanceData != null 
          ? Map<String, dynamic>.from(jsonDecode(row.performanceData!))
          : <String, dynamic>{},
      )).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting server profiles: $e');
      return [];
    }
  }
  
  /// Save a server profile
  Future<void> saveServerProfile(String serverId, ServerProfile profile) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.serverProfiles).insertOnConflictUpdate(ServerProfilesCompanion(
        serverId: Value(serverId),
        avatarPath: Value(profile.avatarPath),
        birthday: Value(profile.birthday),
        hireDate: Value(profile.hireDate?.toIso8601String()),
        teamColor: Value(profile.teamColor),
        stationType: Value(profile.stationType),
        performanceData: Value(profile.performanceData.isNotEmpty ? jsonEncode(profile.performanceData) : null),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
      d('[UnifiedStorageService] Server profile saved: $serverId');
    } catch (e) {
      d('[UnifiedStorageService] Error saving server profile: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // NPS OPERATIONS
  // ============================================================================
  
  /// Save NPS feedback
  Future<void> saveNPSFeedback(Map<String, dynamic> feedback) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.nPSFeedback).insert(NPSFeedbackCompanion(
        serverId: Value(feedback['server_id'] as String),
        feedbackType: Value(feedback['feedback_type'] as String),
        feedbackDate: Value(feedback['feedback_date'] as String),
        salesAmount: Value(feedback['sales_amount'] as double?),
        tableNumber: Value(feedback['table_number'] as int?),
        shiftPeriod: Value(feedback['shift_period'] as String?),
        guestCount: Value(feedback['guest_count'] as int?),
        notes: Value(feedback['notes'] as String?),
      ));
      d('[UnifiedStorageService] NPS feedback saved');
    } catch (e) {
      d('[UnifiedStorageService] Error saving NPS feedback: $e');
      rethrow;
    }
  }
  
  /// Get NPS feedback for a server
  Future<List<Map<String, dynamic>>> getNPSFeedback(String serverId) async {
    await _ensureInitialized();
    
    try {
      final rows = await (_db.select(_db.nPSFeedback)
        ..where((tbl) => tbl.serverId.equals(serverId)));
      return rows.map((row) => {
        'id': row.id,
        'server_id': row.serverId,
        'feedback_type': row.feedbackType,
        'feedback_date': row.feedbackDate,
        'sales_amount': row.salesAmount,
        'table_number': row.tableNumber,
        'shift_period': row.shiftPeriod,
        'guest_count': row.guestCount,
        'notes': row.notes,
        'created_at': row.createdAt,
      }).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting NPS feedback: $e');
      return [];
    }
  }
  
  /// Get all NPS feedback
  Future<List<Map<String, dynamic>>> getAllNPSFeedback() async {
    await _ensureInitialized();
    
    try {
      final rows = await _db.select(_db.nPSFeedback);
      return rows.map((row) => {
        'id': row.id,
        'server_id': row.serverId,
        'feedback_type': row.feedbackType,
        'feedback_date': row.feedbackDate,
        'sales_amount': row.salesAmount,
        'table_number': row.tableNumber,
        'shift_period': row.shiftPeriod,
        'guest_count': row.guestCount,
        'notes': row.notes,
        'created_at': row.createdAt,
      }).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting all NPS feedback: $e');
      return [];
    }
  }
  
  /// Save monthly NPS report
  Future<void> saveMonthlyReport(Map<String, dynamic> report) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.nPSMonthlyReports).insertOnConflictUpdate(NPSMonthlyReportsCompanion(
        serverId: Value(report['server_id'] as String),
        monthYear: Value(report['month_year'] as String),
        allTimeNpsPercentage: Value(report['all_time_nps_percentage'] as double?),
        threeMonthNpsPercentage: Value(report['three_month_nps_percentage'] as double?),
        oneMonthNpsPercentage: Value(report['one_month_nps_percentage'] as double?),
        allTimeSales: Value(report['all_time_sales'] as double? ?? 0.0),
        allTimeTableCount: Value(report['all_time_table_count'] as int? ?? 0),
        monthFeedbackYes: Value(report['month_feedback_yes'] as int? ?? 0),
        monthFeedbackMaybe: Value(report['month_feedback_maybe'] as int? ?? 0),
        monthFeedbackNo: Value(report['month_feedback_no'] as int? ?? 0),
        threeMonthFeedbackYes: Value(report['three_month_feedback_yes'] as int? ?? 0),
        threeMonthFeedbackMaybe: Value(report['three_month_feedback_maybe'] as int? ?? 0),
        threeMonthFeedbackNo: Value(report['three_month_feedback_no'] as int? ?? 0),
        allTimeFeedbackYes: Value(report['all_time_feedback_yes'] as int? ?? 0),
        allTimeFeedbackMaybe: Value(report['all_time_feedback_maybe'] as int? ?? 0),
        allTimeFeedbackNo: Value(report['all_time_feedback_no'] as int? ?? 0),
        dataAsOfDate: Value(report['data_as_of_date'] as String),
      ));
      d('[UnifiedStorageService] Monthly report saved');
    } catch (e) {
      d('[UnifiedStorageService] Error saving monthly report: $e');
      rethrow;
    }
  }
  
  /// Get monthly reports for a server
  Future<List<Map<String, dynamic>>> getMonthlyReports(String serverId) async {
    await _ensureInitialized();
    
    try {
      final rows = await (_db.select(_db.nPSMonthlyReports)
        ..where((tbl) => tbl.serverId.equals(serverId)));
      return rows.map((row) => {
        'id': row.id,
        'server_id': row.serverId,
        'month_year': row.monthYear,
        'all_time_nps_percentage': row.allTimeNpsPercentage,
        'three_month_nps_percentage': row.threeMonthNpsPercentage,
        'one_month_nps_percentage': row.oneMonthNpsPercentage,
        'all_time_sales': row.allTimeSales,
        'all_time_table_count': row.allTimeTableCount,
        'month_feedback_yes': row.monthFeedbackYes,
        'month_feedback_maybe': row.monthFeedbackMaybe,
        'month_feedback_no': row.monthFeedbackNo,
        'three_month_feedback_yes': row.threeMonthFeedbackYes,
        'three_month_feedback_maybe': row.threeMonthFeedbackMaybe,
        'three_month_feedback_no': row.threeMonthFeedbackNo,
        'all_time_feedback_yes': row.allTimeFeedbackYes,
        'all_time_feedback_maybe': row.allTimeFeedbackMaybe,
        'all_time_feedback_no': row.allTimeFeedbackNo,
        'generated_at': row.generatedAt,
        'data_as_of_date': row.dataAsOfDate,
      }).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting monthly reports: $e');
      return [];
    }
  }
  
  // ============================================================================
  // SETTINGS OPERATIONS
  // ============================================================================
  
  /// Get a setting value
  Future<T?> getSetting<T>(String key) async {
    await _ensureInitialized();
    
    try {
      final row = await (_db.select(_db.appSettings)
        ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
      return row?.value as T?;
    } catch (e) {
      d('[UnifiedStorageService] Error getting setting $key: $e');
      return null;
    }
  }
  
  /// Set a setting value
  Future<void> setSetting(String key, dynamic value) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
        key: Value(key),
        value: Value(value.toString()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
      d('[UnifiedStorageService] Setting saved: $key');
    } catch (e) {
      d('[UnifiedStorageService] Error saving setting: $e');
      rethrow;
    }
  }
  
  /// Get all settings
  Future<Map<String, dynamic>> getAllSettings() async {
    await _ensureInitialized();
    
    try {
      final rows = await _db.select(_db.appSettings);
      return Map.fromEntries(rows.map((row) => MapEntry(row.key, row.value)));
    } catch (e) {
      d('[UnifiedStorageService] Error getting all settings: $e');
      return {};
    }
  }
  
  // ============================================================================
  // PERFORMANCE DATA OPERATIONS
  // ============================================================================
  
  /// Save performance data
  Future<void> savePerformanceData(String serverId, String dataType, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.performanceData).insert(PerformanceDataCompanion(
        serverId: Value(serverId),
        dataType: Value(dataType),
        dataContent: Value(jsonEncode(data)),
      ));
      d('[UnifiedStorageService] Performance data saved: $serverId/$dataType');
    } catch (e) {
      d('[UnifiedStorageService] Error saving performance data: $e');
      rethrow;
    }
  }
  
  /// Get performance data for a server
  Future<List<Map<String, dynamic>>> getPerformanceData(String serverId, String dataType) async {
    await _ensureInitialized();
    
    try {
      final rows = await (_db.select(_db.performanceData)
        ..where((tbl) => tbl.serverId.equals(serverId) & tbl.dataType.equals(dataType)));
      return rows.map((row) => jsonDecode(row.dataContent)).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting performance data: $e');
      return [];
    }
  }
  
  // ============================================================================
  // BUSINESS DATA OPERATIONS
  // ============================================================================
  
  /// Save business data
  Future<void> saveBusinessData(String monthYear, String dataType, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.businessData).insert(BusinessDataCompanion(
        monthYear: Value(monthYear),
        dataType: Value(dataType),
        dataContent: Value(jsonEncode(data)),
      ));
      d('[UnifiedStorageService] Business data saved: $monthYear/$dataType');
    } catch (e) {
      d('[UnifiedStorageService] Error saving business data: $e');
      rethrow;
    }
  }
  
  /// Get business data for a month
  Future<List<Map<String, dynamic>>> getBusinessData(String monthYear, String dataType) async {
    await _ensureInitialized();
    
    try {
      final rows = await (_db.select(_db.businessData)
        ..where((tbl) => tbl.monthYear.equals(monthYear) & tbl.dataType.equals(dataType)));
      return rows.map((row) => jsonDecode(row.dataContent)).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting business data: $e');
      return [];
    }
  }
  
  // ============================================================================
  // STATION ASSIGNMENT OPERATIONS
  // ============================================================================
  
  /// Save station assignment
  Future<void> saveStationAssignment(String serverId, String shiftDate, String shiftType, String? stationType, String? sectionAssignment) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.stationAssignments).insert(StationAssignmentsCompanion(
        serverId: Value(serverId),
        shiftDate: Value(shiftDate),
        shiftType: Value(shiftType),
        stationType: Value(stationType),
        sectionAssignment: Value(sectionAssignment),
      ));
      d('[UnifiedStorageService] Station assignment saved: $serverId');
    } catch (e) {
      d('[UnifiedStorageService] Error saving station assignment: $e');
      rethrow;
    }
  }
  
  /// Get station assignments for a server
  Future<List<Map<String, dynamic>>> getStationAssignments(String serverId) async {
    await _ensureInitialized();
    
    try {
      final rows = await (_db.select(_db.stationAssignments)
        ..where((tbl) => tbl.serverId.equals(serverId)));
      return rows.map((row) => {
        'id': row.id,
        'server_id': row.serverId,
        'shift_date': row.shiftDate,
        'shift_type': row.shiftType,
        'station_type': row.stationType,
        'section_assignment': row.sectionAssignment,
        'created_at': row.createdAt,
      }).toList();
    } catch (e) {
      d('[UnifiedStorageService] Error getting station assignments: $e');
      return [];
    }
  }
  
  // ============================================================================
  // TAP LOG OPERATIONS
  // ============================================================================
  
  /// Save tap log data
  Future<void> saveTapLogData(String key, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.tapLogs).insertOnConflictUpdate(TapLogsCompanion(
        key: Value(key),
        data: Value(jsonEncode(data)),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
      d('[UnifiedStorageService] Tap log data saved: $key');
    } catch (e) {
      d('[UnifiedStorageService] Error saving tap log data: $e');
      rethrow;
    }
  }
  
  /// Get tap log data
  Future<Map<String, dynamic>?> getTapLogData(String key) async {
    await _ensureInitialized();
    
    try {
      final row = await (_db.select(_db.tapLogs)
        ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
      return row != null ? jsonDecode(row.data) : null;
    } catch (e) {
      d('[UnifiedStorageService] Error getting tap log data: $e');
      return null;
    }
  }
  
  // ============================================================================
  // DAY PLAN OPERATIONS
  // ============================================================================
  
  /// Save day plan data
  Future<void> saveDayPlanData(String date, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.dayPlans).insertOnConflictUpdate(DayPlansCompanion(
        date: Value(date),
        data: Value(jsonEncode(data)),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
      d('[UnifiedStorageService] Day plan data saved: $date');
    } catch (e) {
      d('[UnifiedStorageService] Error saving day plan data: $e');
      rethrow;
    }
  }
  
  /// Get day plan data
  Future<Map<String, dynamic>?> getDayPlanData(String date) async {
    await _ensureInitialized();
    
    try {
      final row = await (_db.select(_db.dayPlans)
        ..where((tbl) => tbl.date.equals(date)))
        .getSingleOrNull();
      return row != null ? jsonDecode(row.data) : null;
    } catch (e) {
      d('[UnifiedStorageService] Error getting day plan data: $e');
      return null;
    }
  }
  
  // ============================================================================
  // ASSET OPERATIONS
  // ============================================================================
  
  /// Save asset data
  Future<void> saveAssetData(String key, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      await _db.into(_db.assets).insertOnConflictUpdate(AssetsCompanion(
        key: Value(key),
        data: Value(jsonEncode(data)),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
      d('[UnifiedStorageService] Asset data saved: $key');
    } catch (e) {
      d('[UnifiedStorageService] Error saving asset data: $e');
      rethrow;
    }
  }
  
  /// Get asset data
  Future<Map<String, dynamic>?> getAssetData(String key) async {
    await _ensureInitialized();
    
    try {
      final row = await (_db.select(_db.assets)
        ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
      return row != null ? jsonDecode(row.data) : null;
    } catch (e) {
      d('[UnifiedStorageService] Error getting asset data: $e');
      return null;
    }
  }
  
  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================
  
  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    await _ensureInitialized();
    
    try {
      final serverCount = await _db.select(_db.servers).get().length;
      final shiftCount = await _db.select(_db.shiftRecords).get().length;
      final npsCount = await _db.select(_db.nPSFeedback).get().length;
      final reportCount = await _db.select(_db.nPSMonthlyReports).get().length;
      
      return {
        'servers': serverCount,
        'shifts': shiftCount,
        'nps_feedback': npsCount,
        'monthly_reports': reportCount,
      };
    } catch (e) {
      d('[UnifiedStorageService] Error getting database stats: $e');
      return {};
    }
  }
  
  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    await _ensureInitialized();
    
    try {
      await _db.delete(_db.assets).go();
      await _db.delete(_db.dayPlans).go();
      await _db.delete(_db.tapLogs).go();
      await _db.delete(_db.stationAssignments).go();
      await _db.delete(_db.businessData).go();
      await _db.delete(_db.performanceData).go();
      await _db.delete(_db.appSettings).go();
      await _db.delete(_db.nPSMonthlyReports).go();
      await _db.delete(_db.nPSFeedback).go();
      await _db.delete(_db.serverProfiles).go();
      await _db.delete(_db.shiftRecords).go();
      await _db.delete(_db.servers).go();
      d('[UnifiedStorageService] All data cleared');
    } catch (e) {
      d('[UnifiedStorageService] Error clearing data: $e');
      rethrow;
    }
  }
}
