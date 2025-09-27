import 'package:flutter/foundation.dart';
import '../app_state.dart';
import '../storage.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import '../models/server.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../utils/performance_calculator.dart';
import '../utils/log.dart';

/// Unified data service that bridges all data sources
/// 
/// This service provides a single interface to access data from:
/// - AppState (Hive storage) - shift records, server profiles, food runs
/// - NPS Database (Sqflite/Drift) - NPS feedback, monthly reports
/// - Enhanced Business Data (Hive) - sales, guest counts
class UnifiedDataService {
  static UnifiedDataService? _instance;
  static UnifiedDataService get instance => _instance ??= UnifiedDataService._();
  
  UnifiedDataService._();

  final NPSDatabaseAdapter _npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
  
  /// Get all servers with unified data from all sources
  Future<List<UnifiedServerData>> getAllServersWithData() async {
    try {
      d('[UnifiedDataService] Loading servers from all sources...');
      
      // Get servers from NPS Database (primary source)
      final serversData = await _npsAdapter.getAllServers(activeOnly: true);
      final servers = serversData.map((data) => NPSServer.fromMap(data)).toList();
      // Convert all IDs to non-nullable strings during initialization
      final unifiedServers = servers.map((server) => server.copyWith(id: server.id ?? 'unknown')).toList();
      d('[UnifiedDataService] Found ${unifiedServers.length} servers in NPS Database');
      
      // Get servers from AppState (secondary source)
      final appState = AppState();
      final appStateServers = appState.servers;
      d('[UnifiedDataService] Found ${appStateServers.length} servers in AppState');
      
      // Create unified server data
      final unifiedServersList = <UnifiedServerData>[];
      
      for (final npsServer in unifiedServers) {
        final serverId = npsServer.id;
        final serverName = npsServer.name as String;
        
        // Ensure IDs are non-nullable strings
        final String serverId = 'unknown';
        
        // Find matching server in AppState
        final appStateServer = appStateServers.firstWhere(
          (s) => s.id == serverId,
          orElse: () => Server(
            id: serverId,
            name: serverName,
            teamColor: null,
            stationType: null,
            hireDate: DateTime.tryParse(npsServer.hireDate as String? ?? ''),
          ),
        );
        
        // Get shift data for this server
        final shiftData = await _getShiftDataForServer(serverId, appState);
        
        // Get NPS data for this server
        final npsData = await _getNPSDataForServer(serverId);
        
        // Get business data for this server
        final businessData = await _getBusinessDataForServer(serverId);
        
        // Create unified server data
        final unifiedServer = UnifiedServerData(
          serverId: serverId,
          serverName: serverName,
          hireDate: appStateServer.hireDate ?? DateTime.now().subtract(Duration(days: 30)),
          shiftData: shiftData,
          npsData: npsData,
          businessData: businessData,
        );
        
        unifiedServersList.add(unifiedServer);
        d('[UnifiedDataService] Created unified data for server $serverName (ID: $serverId)');
      }
      
      d('[UnifiedDataService] Successfully loaded ${unifiedServersList.length} unified servers');
      return unifiedServersList;
      
    } catch (e) {
      d('[UnifiedDataService] Error loading unified server data: $e');
      rethrow;
    }
  }
  
  /// Get shift data for a specific server from AppState
  Future<UnifiedShiftData> _getShiftDataForServer(String serverId, AppState appState) async {
    try {
      // Get all shift records for this server
      final serverShifts = appState.history
          .where((shift) => shift.counts.containsKey(serverId))
          .where((shift) => shift.start.isAfter(DateTime.now().subtract(Duration(days: 30))))
          .toList();
      
      // Calculate totals
      final totalRuns = serverShifts.fold<int>(0, (sum, shift) => 
          sum + (shift.counts[serverId] ?? 0));
      final totalPizookieRuns = serverShifts.fold<int>(0, (sum, shift) => 
          sum + (shift.pizookieCounts[serverId] ?? 0));
      final shiftsWorked = serverShifts.length;
      
      // Get server profile for additional data
      final profile = appState.profiles[serverId];
      final allTimeRuns = profile?.allTimeRuns ?? 0;
      final allTimePizookieRuns = profile?.pizookieRuns ?? 0;
      
      return UnifiedShiftData(
        totalRuns: totalRuns,
        totalPizookieRuns: totalPizookieRuns,
        shiftsWorked: shiftsWorked,
        allTimeRuns: allTimeRuns,
        allTimePizookieRuns: allTimePizookieRuns,
        recentShifts: serverShifts,
      );
      
    } catch (e) {
      d('[UnifiedDataService] Error loading shift data for server $serverId: $e');
      return UnifiedShiftData.empty();
    }
  }
  
  /// Get NPS data for a specific server
  Future<UnifiedNPSData> _getNPSDataForServer(String serverId) async {
    try {
      // Get NPS history for the last 3 months
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
      
      final npsHistory = await _npsAdapter.getFeedbackForServerInRange(
        int.parse(serverId),
        startDate: threeMonthsAgo,
        endDate: now,
      );
      
      // Calculate NPS scores
      double? monthlyScore;
      double? threeMonthAverage;
      int responseCount = 0;
      
      if (npsHistory.isNotEmpty) {
        // Calculate monthly score (most recent month)
        final currentMonth = DateTime(now.year, now.month, 1);
        final currentMonthFeedback = npsHistory
            .where((f) {
              final submissionDate = DateTime.tryParse(f['submission_date'] as String? ?? '');
              return submissionDate != null && submissionDate.isAfter(currentMonth);
            })
            .toList();
        
        if (currentMonthFeedback.isNotEmpty) {
          monthlyScore = _calculateNPSScore(currentMonthFeedback);
          responseCount = currentMonthFeedback.length;
        }
        
        // Calculate three-month average
        threeMonthAverage = _calculateNPSScore(npsHistory);
      }
      
      return UnifiedNPSData(
        monthlyScore: monthlyScore,
        threeMonthAverage: threeMonthAverage,
        responseCount: responseCount,
        hasActualData: npsHistory.isNotEmpty,
      );
      
    } catch (e) {
      d('[UnifiedDataService] Error loading NPS data for server $serverId: $e');
      return UnifiedNPSData.empty();
    }
  }
  
  /// Get business data for a specific server
  Future<UnifiedBusinessData> _getBusinessDataForServer(String serverId) async {
    try {
      // Get current month's business data
      final now = DateTime.now();
      final monthKey = Storage.generateMonthKey(now);
      final businessData = await Storage.getMonthlyBusinessData(monthKey);
      
      if (businessData != null) {
        // Estimate server-specific data based on runs
        final totalSales = (businessData['totalSales'] as num?)?.toDouble() ?? 0.0;
        final totalGuests = (businessData['totalGuestCount'] as num?)?.toDouble() ?? 0.0;
        
        // For now, estimate based on server performance
        // In a real implementation, this would be more sophisticated
        final estimatedSales = totalSales * 0.1; // Assume 10% of total sales
        final estimatedGuests = totalGuests * 0.1; // Assume 10% of total guests
        
        return UnifiedBusinessData(
          estimatedSales: estimatedSales,
          estimatedGuests: estimatedGuests,
          totalRestaurantSales: totalSales,
          totalRestaurantGuests: totalGuests,
        );
      }
      
      return UnifiedBusinessData.empty();
      
    } catch (e) {
      d('[UnifiedDataService] Error loading business data for server $serverId: $e');
      return UnifiedBusinessData.empty();
    }
  }
  
  /// Calculate NPS score from feedback data
  double _calculateNPSScore(List<dynamic> feedback) {
    if (feedback.isEmpty) return 0.0;
    
    int promoters = 0;
    int detractors = 0;
    
    for (final f in feedback) {
      final score = f['score'] as int? ?? 0;
      if (score >= 9) {
        promoters++;
      } else if (score <= 6) {
        detractors++;
      }
    }
    
    if (feedback.length == 0) return 0.0;
    
    final percentage = ((promoters - detractors) / feedback.length) * 100;
    return percentage.clamp(0.0, 100.0);
  }
  
  /// Generate month key for storage
  String _generateMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}

/// Unified server data containing all information from all sources
class UnifiedServerData {
  final String serverId;
  final String serverName;
  final DateTime hireDate;
  final UnifiedShiftData shiftData;
  final UnifiedNPSData npsData;
  final UnifiedBusinessData businessData;
  
  UnifiedServerData({
    required this.serverId,
    required this.serverName,
    required this.hireDate,
    required this.shiftData,
    required this.npsData,
    required this.businessData,
  });
  
  /// Calculate days employed
  int get daysEmployed => DateTime.now().difference(hireDate).inDays;
  
  /// Get total guest count (estimated)
  double get totalGuestCount => businessData.estimatedGuests;
  
  /// Get total sales (estimated)
  double get totalSales => businessData.estimatedSales;
  
  /// Get shift types from recent shifts
  List<ShiftComplexity> get shiftTypes {
    // For now, return empty list - could be enhanced to analyze shift patterns
    return [];
  }
}

/// Unified shift data from AppState
class UnifiedShiftData {
  final int totalRuns;
  final int totalPizookieRuns;
  final int shiftsWorked;
  final int allTimeRuns;
  final int allTimePizookieRuns;
  final List<ShiftRecord> recentShifts;
  
  UnifiedShiftData({
    required this.totalRuns,
    required this.totalPizookieRuns,
    required this.shiftsWorked,
    required this.allTimeRuns,
    required this.allTimePizookieRuns,
    required this.recentShifts,
  });
  
  factory UnifiedShiftData.empty() => UnifiedShiftData(
    totalRuns: 0,
    totalPizookieRuns: 0,
    shiftsWorked: 0,
    allTimeRuns: 0,
    allTimePizookieRuns: 0,
    recentShifts: [],
  );
}

/// Unified NPS data from NPS Database
class UnifiedNPSData {
  final double? monthlyScore;
  final double? threeMonthAverage;
  final int responseCount;
  final bool hasActualData;
  
  UnifiedNPSData({
    required this.monthlyScore,
    required this.threeMonthAverage,
    required this.responseCount,
    required this.hasActualData,
  });
  
  factory UnifiedNPSData.empty() => UnifiedNPSData(
    monthlyScore: null,
    threeMonthAverage: null,
    responseCount: 0,
    hasActualData: false,
  );
}

/// Unified business data from Enhanced Business Data
class UnifiedBusinessData {
  final double estimatedSales;
  final double estimatedGuests;
  final double totalRestaurantSales;
  final double totalRestaurantGuests;
  
  UnifiedBusinessData({
    required this.estimatedSales,
    required this.estimatedGuests,
    required this.totalRestaurantSales,
    required this.totalRestaurantGuests,
  });
  
  factory UnifiedBusinessData.empty() => UnifiedBusinessData(
    estimatedSales: 0.0,
    estimatedGuests: 0.0,
    totalRestaurantSales: 0.0,
    totalRestaurantGuests: 0.0,
  );
}
