import 'package:food_runs_counter/app_state.dart';
import 'package:food_runs_counter/storage/nps_database_adapter.dart';
import 'package:food_runs_counter/storage/database_factory.dart';
import 'package:food_runs_counter/services/enhanced_error_handling_service.dart';
import 'package:food_runs_counter/utils/log.dart';

/// Fallback mechanisms service
/// 
/// This service provides fallback mechanisms when primary data sources
/// fail or return incomplete data.
class FallbackMechanismsService {
  static FallbackMechanismsService? _instance;
  static FallbackMechanismsService get instance => _instance ??= FallbackMechanismsService._();
  
  FallbackMechanismsService._();

  late NPSDatabaseAdapter _npsAdapter;
  late AppState _appState;

  /// Initialize the service
  Future<void> initialize() async {
    _npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
    _appState = AppState();
    d('[FallbackMechanismsService] Initialized');
  }

  /// Get fallback server data when primary source fails
  Future<FallbackServerData?> getFallbackServerData(String serverId) async {
    try {
      d('[FallbackMechanismsService] Getting fallback data for server $serverId');
      
      // Try to get server from AppState first
      final appStateServer = _appState.servers.firstWhere(
        (s) => s.id == serverId,
        orElse: () => throw Exception('Server not found in AppState'),
      );
      
      // Get basic shift data
      final shiftData = _getFallbackShiftData(serverId);
      
      // Get basic NPS data
      final npsData = await _getFallbackNPSData(serverId);
      
      // Calculate basic performance metrics
      final performanceMetrics = _calculateFallbackPerformanceMetrics(shiftData, npsData);
      
      return FallbackServerData(
        serverId: serverId,
        serverName: appStateServer.name,
        shiftData: shiftData,
        npsData: npsData,
        performanceMetrics: performanceMetrics,
        dataQuality: _assessDataQuality(shiftData, npsData),
        fallbackReason: 'Primary data source unavailable',
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'fallback_server_data_failed',
        'Failed to get fallback server data for $serverId',
        context: 'FallbackMechanismsService',
        metadata: {'serverId': serverId, 'error': e.toString()},
        severity: ErrorSeverity.high,
      );
      return null;
    }
  }

  /// Get fallback shift data
  FallbackShiftData _getFallbackShiftData(String serverId) {
    try {
      final recentShifts = _appState.history
          .where((shift) => shift.counts.containsKey(serverId))
          .where((shift) => shift.start.isAfter(DateTime.now().subtract(Duration(days: 30))))
          .toList();

      final totalRuns = recentShifts.fold<int>(0, (sum, shift) => 
          sum + (shift.counts[serverId] ?? 0));
      final totalPizookieRuns = recentShifts.fold<int>(0, (sum, shift) => 
          sum + (shift.pizookieCounts[serverId] ?? 0));
      final shiftsWorked = recentShifts.length;

      return FallbackShiftData(
        totalRuns: totalRuns,
        totalPizookieRuns: totalPizookieRuns,
        shiftsWorked: shiftsWorked,
        averageRunsPerShift: shiftsWorked > 0 ? totalRuns / shiftsWorked : 0.0,
        lastShiftDate: recentShifts.isNotEmpty 
            ? recentShifts.map((s) => s.start).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
        dataCompleteness: _calculateShiftDataCompleteness(recentShifts),
      );
      
    } catch (e) {
      d('[FallbackMechanismsService] Error getting fallback shift data: $e');
      return FallbackShiftData.empty();
    }
  }

  /// Get fallback NPS data
  Future<FallbackNPSData> _getFallbackNPSData(String serverId) async {
    try {
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
      
      final npsFeedback = await _npsAdapter.getFeedbackForServerInRange(
        int.parse(serverId),
        startDate: threeMonthsAgo,
        endDate: now,
      );
      
      if (npsFeedback.isEmpty) {
        return FallbackNPSData.empty();
      }
      
      // Calculate basic NPS metrics
      final scores = npsFeedback.map((f) => f['nps_score'] as int? ?? 0).toList();
      final validScores = scores.where((s) => s > 0).toList();
      
      if (validScores.isEmpty) {
        return FallbackNPSData.empty();
      }
      
      final averageScore = validScores.reduce((a, b) => a + b) / validScores.length;
      final responseCount = validScores.length;
      
      return FallbackNPSData(
        monthlyScore: averageScore,
        threeMonthAverage: averageScore,
        responseCount: responseCount,
        hasActualData: true,
        dataCompleteness: _calculateNPSDataCompleteness(npsFeedback),
        lastResponseDate: _getLastResponseDate(npsFeedback),
      );
      
    } catch (e) {
      d('[FallbackMechanismsService] Error getting fallback NPS data: $e');
      return FallbackNPSData.empty();
    }
  }

  /// Calculate fallback performance metrics
  FallbackPerformanceMetrics _calculateFallbackPerformanceMetrics(
    FallbackShiftData shiftData,
    FallbackNPSData npsData,
  ) {
    // Basic performance calculation
    double performanceScore = 0.0;
    
    // Shift performance (60% weight)
    if (shiftData.shiftsWorked > 0) {
      final shiftScore = (shiftData.averageRunsPerShift / 5.0 * 100).clamp(0.0, 100.0);
      performanceScore += shiftScore * 0.6;
    }
    
    // NPS performance (40% weight)
    if (npsData.hasActualData && npsData.monthlyScore != null) {
      final npsScore = (npsData.monthlyScore! / 10.0 * 100).clamp(0.0, 100.0);
      performanceScore += npsScore * 0.4;
    }
    
    // Determine performance rating
    PerformanceRating rating;
    if (performanceScore >= 80) {
      rating = PerformanceRating.strong;
    } else if (performanceScore >= 60) {
      rating = PerformanceRating.developing;
    } else if (performanceScore >= 40) {
      rating = PerformanceRating.needsAttention;
    } else {
      rating = PerformanceRating.critical;
    }
    
    return FallbackPerformanceMetrics(
      performanceScore: performanceScore,
      rating: rating,
      confidenceLevel: _calculateConfidenceLevel(shiftData, npsData),
      dataQuality: _assessDataQuality(shiftData, npsData),
      lastUpdated: DateTime.now(),
    );
  }

  /// Calculate shift data completeness
  double _calculateShiftDataCompleteness(List<dynamic> shifts) {
    if (shifts.isEmpty) return 0.0;
    
    // Check for missing data in shifts
    int completeShifts = 0;
    for (final shift in shifts) {
      if (shift.counts.isNotEmpty && shift.start != null) {
        completeShifts++;
      }
    }
    
    return completeShifts / shifts.length;
  }

  /// Calculate NPS data completeness
  double _calculateNPSDataCompleteness(List<Map<String, dynamic>> feedback) {
    if (feedback.isEmpty) return 0.0;
    
    int completeFeedback = 0;
    for (final f in feedback) {
      if (f['nps_score'] != null && f['server_id'] != null) {
        completeFeedback++;
      }
    }
    
    return completeFeedback / feedback.length;
  }

  /// Get last response date from NPS feedback
  DateTime? _getLastResponseDate(List<Map<String, dynamic>> feedback) {
    if (feedback.isEmpty) return null;
    
    DateTime? lastDate;
    for (final f in feedback) {
      final submissionDate = DateTime.tryParse(f['submission_date'] as String? ?? '');
      if (submissionDate != null) {
        if (lastDate == null || submissionDate.isAfter(lastDate)) {
          lastDate = submissionDate;
        }
      }
    }
    
    return lastDate;
  }

  /// Calculate confidence level
  ConfidenceLevel _calculateConfidenceLevel(
    FallbackShiftData shiftData,
    FallbackNPSData npsData,
  ) {
    double confidence = 0.0;
    
    // Shift data confidence (50% weight)
    if (shiftData.shiftsWorked > 0) {
      confidence += 0.5 * shiftData.dataCompleteness;
    }
    
    // NPS data confidence (50% weight)
    if (npsData.hasActualData) {
      confidence += 0.5 * npsData.dataCompleteness;
    }
    
    if (confidence >= 0.8) return ConfidenceLevel.high;
    if (confidence >= 0.6) return ConfidenceLevel.medium;
    if (confidence >= 0.4) return ConfidenceLevel.low;
    return ConfidenceLevel.veryLow;
  }

  /// Assess overall data quality
  DataQuality _assessDataQuality(
    FallbackShiftData shiftData,
    FallbackNPSData npsData,
  ) {
    final shiftQuality = shiftData.dataCompleteness;
    final npsQuality = npsData.dataCompleteness;
    final overallQuality = (shiftQuality + npsQuality) / 2.0;
    
    if (overallQuality >= 0.9) return DataQuality.complete;
    if (overallQuality >= 0.7) return DataQuality.partial;
    if (overallQuality >= 0.4) return DataQuality.sparse;
    return DataQuality.missing;
  }

  /// Get fallback performance data for all servers
  Future<List<FallbackServerData>> getAllFallbackServerData() async {
    try {
      d('[FallbackMechanismsService] Getting fallback data for all servers');
      
      final fallbackData = <FallbackServerData>[];
      
      for (final server in _appState.servers) {
        final data = await getFallbackServerData(server.id);
        if (data != null) {
          fallbackData.add(data);
        }
      }
      
      d('[FallbackMechanismsService] Retrieved fallback data for ${fallbackData.length} servers');
      return fallbackData;
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'fallback_all_servers_failed',
        'Failed to get fallback data for all servers',
        context: 'FallbackMechanismsService',
        metadata: {'error': e.toString()},
        severity: ErrorSeverity.high,
      );
      return [];
    }
  }
}

/// Fallback server data
class FallbackServerData {
  final String serverId;
  final String serverName;
  final FallbackShiftData shiftData;
  final FallbackNPSData npsData;
  final FallbackPerformanceMetrics performanceMetrics;
  final DataQuality dataQuality;
  final String fallbackReason;
  final DateTime timestamp;

  FallbackServerData({
    required this.serverId,
    required this.serverName,
    required this.shiftData,
    required this.npsData,
    required this.performanceMetrics,
    required this.dataQuality,
    required this.fallbackReason,
    required this.timestamp,
  });
}

/// Fallback shift data
class FallbackShiftData {
  final int totalRuns;
  final int totalPizookieRuns;
  final int shiftsWorked;
  final double averageRunsPerShift;
  final DateTime? lastShiftDate;
  final double dataCompleteness;

  FallbackShiftData({
    required this.totalRuns,
    required this.totalPizookieRuns,
    required this.shiftsWorked,
    required this.averageRunsPerShift,
    this.lastShiftDate,
    required this.dataCompleteness,
  });

  factory FallbackShiftData.empty() {
    return FallbackShiftData(
      totalRuns: 0,
      totalPizookieRuns: 0,
      shiftsWorked: 0,
      averageRunsPerShift: 0.0,
      dataCompleteness: 0.0,
    );
  }
}

/// Fallback NPS data
class FallbackNPSData {
  final double? monthlyScore;
  final double? threeMonthAverage;
  final int responseCount;
  final bool hasActualData;
  final double dataCompleteness;
  final DateTime? lastResponseDate;

  FallbackNPSData({
    this.monthlyScore,
    this.threeMonthAverage,
    required this.responseCount,
    required this.hasActualData,
    required this.dataCompleteness,
    this.lastResponseDate,
  });

  factory FallbackNPSData.empty() {
    return FallbackNPSData(
      responseCount: 0,
      hasActualData: false,
      dataCompleteness: 0.0,
    );
  }
}

/// Fallback performance metrics
class FallbackPerformanceMetrics {
  final double performanceScore;
  final PerformanceRating rating;
  final ConfidenceLevel confidenceLevel;
  final DataQuality dataQuality;
  final DateTime lastUpdated;

  FallbackPerformanceMetrics({
    required this.performanceScore,
    required this.rating,
    required this.confidenceLevel,
    required this.dataQuality,
    required this.lastUpdated,
  });
}

/// Performance rating enum (imported from performance_models.dart)
enum PerformanceRating {
  critical,
  needsAttention,
  developing,
  strong,
  elite,
}

/// Data quality enum (imported from performance_models.dart)
enum DataQuality {
  missing,
  sparse,
  partial,
  complete,
}

/// Confidence level enum (imported from performance_models.dart)
enum ConfidenceLevel {
  veryLow,
  low,
  medium,
  high,
}

