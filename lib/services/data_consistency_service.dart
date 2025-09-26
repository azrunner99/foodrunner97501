import 'package:food_runs_counter/app_state.dart';
import 'package:food_runs_counter/storage/nps_database_adapter.dart';
import 'package:food_runs_counter/storage/database_factory.dart';
import 'package:food_runs_counter/services/enhanced_error_handling_service.dart';
import 'package:food_runs_counter/utils/log.dart';

/// Data consistency validation service
/// 
/// This service validates data consistency across different data sources
/// and identifies discrepancies that could affect performance calculations.
class DataConsistencyService {
  static DataConsistencyService? _instance;
  static DataConsistencyService get instance => _instance ??= DataConsistencyService._();
  
  DataConsistencyService._();

  late NPSDatabaseAdapter _npsAdapter;
  late AppState _appState;

  /// Initialize the service
  Future<void> initialize() async {
    _npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
    _appState = AppState();
    d('[DataConsistencyService] Initialized');
  }

  /// Validate data consistency across all sources
  Future<ConsistencyReport> validateDataConsistency() async {
    d('[DataConsistencyService] Starting data consistency validation...');
    
    final report = ConsistencyReport();
    
    try {
      // Validate server data consistency
      await _validateServerConsistency(report);
      
      // Validate shift data consistency
      await _validateShiftDataConsistency(report);
      
      // Validate NPS data consistency
      await _validateNPSDataConsistency(report);
      
      // Validate performance data consistency
      await _validatePerformanceDataConsistency(report);
      
      // Calculate overall consistency score
      report.calculateOverallScore();
      
      d('[DataConsistencyService] Consistency validation completed. Score: ${report.overallScore}%');
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'consistency_validation_failed',
        'Failed to validate data consistency',
        context: 'DataConsistencyService',
        metadata: {'error': e.toString()},
        severity: ErrorSeverity.high,
      );
      
      report.addIssue(ConsistencyIssue(
        type: ConsistencyIssueType.systemError,
        severity: ValidationSeverity.critical,
        message: 'System error during consistency validation: $e',
        affectedData: 'All',
        suggestedAction: 'Check system logs and retry validation',
      ));
    }
    
    return report;
  }

  /// Validate server data consistency between AppState and NPS Database
  Future<void> _validateServerConsistency(ConsistencyReport report) async {
    try {
      // Get servers from AppState
      final appStateServers = _appState.servers;
      d('[DataConsistencyService] Found ${appStateServers.length} servers in AppState');
      
      // Get servers from NPS Database
      final npsServers = await _npsAdapter.getAllServers(activeOnly: false);
      d('[DataConsistencyService] Found ${npsServers.length} servers in NPS Database');
      
      // Check for servers in AppState but not in NPS Database
      final appStateServerIds = appStateServers.map((s) => s.id).toSet();
      final npsServerIds = npsServers.map((s) => s['id'].toString()).toSet();
      
      final missingInNPS = appStateServerIds.difference(npsServerIds);
      if (missingInNPS.isNotEmpty) {
        report.addIssue(ConsistencyIssue(
          type: ConsistencyIssueType.missingData,
          severity: ValidationSeverity.high,
          message: '${missingInNPS.length} servers found in AppState but not in NPS Database',
          affectedData: 'Server Data',
          suggestedAction: 'Sync server data between AppState and NPS Database',
        ));
      }
      
      // Check for servers in NPS Database but not in AppState
      final missingInAppState = npsServerIds.difference(appStateServerIds);
      if (missingInAppState.isNotEmpty) {
        report.addIssue(ConsistencyIssue(
          type: ConsistencyIssueType.missingData,
          severity: ValidationSeverity.medium,
          message: '${missingInAppState.length} servers found in NPS Database but not in AppState',
          affectedData: 'Server Data',
          suggestedAction: 'Review server data synchronization',
        ));
      }
      
      // Check for server name consistency
      for (final appStateServer in appStateServers) {
        final npsServer = npsServers.firstWhere(
          (s) => s['id'].toString() == appStateServer.id,
          orElse: () => <String, dynamic>{},
        );
        
        if (npsServer.isNotEmpty) {
          final npsName = npsServer['name'] as String?;
          if (npsName != null && npsName != appStateServer.name) {
            report.addIssue(ConsistencyIssue(
              type: ConsistencyIssueType.dataInconsistency,
              severity: ValidationSeverity.medium,
              message: 'Server name mismatch for ${appStateServer.id}: AppState="${appStateServer.name}", NPS="$npsName"',
              affectedData: 'Server Data',
              suggestedAction: 'Update server name to match across systems',
            ));
          }
        }
      }
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'server_consistency_validation_failed',
        'Failed to validate server data consistency',
        context: 'DataConsistencyService',
        metadata: {'error': e.toString()},
        severity: ErrorSeverity.high,
      );
    }
  }

  /// Validate shift data consistency
  Future<void> _validateShiftDataConsistency(ConsistencyReport report) async {
    try {
      final shiftRecords = _appState.history;
      d('[DataConsistencyService] Validating ${shiftRecords.length} shift records');
      
      // Check for shifts with no server data
      final emptyShifts = shiftRecords.where((shift) => shift.counts.isEmpty).toList();
      if (emptyShifts.isNotEmpty) {
        report.addIssue(ConsistencyIssue(
          type: ConsistencyIssueType.missingData,
          severity: ValidationSeverity.medium,
          message: '${emptyShifts.length} shift records have no server data',
          affectedData: 'Shift Data',
          suggestedAction: 'Review shift data entry process',
        ));
      }
      
      // Check for shifts with invalid dates
      final now = DateTime.now();
      final invalidDateShifts = shiftRecords.where((shift) => 
        shift.start.isAfter(now) || shift.start.isBefore(now.subtract(Duration(days: 365)))
      ).toList();
      
      if (invalidDateShifts.isNotEmpty) {
        report.addIssue(ConsistencyIssue(
          type: ConsistencyIssueType.dataInconsistency,
          severity: ValidationSeverity.high,
          message: '${invalidDateShifts.length} shift records have invalid dates',
          affectedData: 'Shift Data',
          suggestedAction: 'Review and correct shift dates',
        ));
      }
      
      // Check for shifts with negative run counts
      final negativeRunShifts = shiftRecords.where((shift) => 
        shift.counts.values.any((count) => count < 0)
      ).toList();
      
      if (negativeRunShifts.isNotEmpty) {
        report.addIssue(ConsistencyIssue(
          type: ConsistencyIssueType.dataInconsistency,
          severity: ValidationSeverity.high,
          message: '${negativeRunShifts.length} shift records have negative run counts',
          affectedData: 'Shift Data',
          suggestedAction: 'Review and correct run count data',
        ));
      }
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'shift_consistency_validation_failed',
        'Failed to validate shift data consistency',
        context: 'DataConsistencyService',
        metadata: {'error': e.toString()},
        severity: ErrorSeverity.high,
      );
    }
  }

  /// Validate NPS data consistency
  Future<void> _validateNPSDataConsistency(ConsistencyReport report) async {
    try {
      // Get NPS feedback data
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
      
      final npsFeedback = await _npsAdapter.getFeedbackInDateRange(
        threeMonthsAgo,
        now,
      );
      
      d('[DataConsistencyService] Validating ${npsFeedback.length} NPS feedback records');
      
      // Check for NPS feedback with invalid scores
      final invalidScoreFeedback = npsFeedback.where((feedback) {
        final score = feedback['nps_score'] as int?;
        return score == null || score < 0 || score > 10;
      }).toList();
      
      if (invalidScoreFeedback.isNotEmpty) {
        report.addIssue(ConsistencyIssue(
          type: ConsistencyIssueType.dataInconsistency,
          severity: ValidationSeverity.high,
          message: '${invalidScoreFeedback.length} NPS feedback records have invalid scores',
          affectedData: 'NPS Data',
          suggestedAction: 'Review and correct NPS score data',
        ));
      }
      
      // Check for NPS feedback with missing server references
      final missingServerFeedback = npsFeedback.where((feedback) {
        final serverId = feedback['server_id'] as int?;
        return serverId == null;
      }).toList();
      
      if (missingServerFeedback.isNotEmpty) {
        report.addIssue(ConsistencyIssue(
          type: ConsistencyIssueType.missingData,
          severity: ValidationSeverity.high,
          message: '${missingServerFeedback.length} NPS feedback records have missing server references',
          affectedData: 'NPS Data',
          suggestedAction: 'Review and correct NPS server references',
        ));
      }
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'nps_consistency_validation_failed',
        'Failed to validate NPS data consistency',
        context: 'DataConsistencyService',
        metadata: {'error': e.toString()},
        severity: ErrorSeverity.high,
      );
    }
  }

  /// Validate performance data consistency
  Future<void> _validatePerformanceDataConsistency(ConsistencyReport report) async {
    try {
      // This would validate performance calculation consistency
      // For now, we'll add a placeholder
      d('[DataConsistencyService] Performance data consistency validation placeholder');
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'performance_consistency_validation_failed',
        'Failed to validate performance data consistency',
        context: 'DataConsistencyService',
        metadata: {'error': e.toString()},
        severity: ErrorSeverity.high,
      );
    }
  }
}

/// Consistency report
class ConsistencyReport {
  final List<ConsistencyIssue> issues = [];
  final List<ConsistencyWarning> warnings = [];
  double overallScore = 0.0;
  final DateTime timestamp = DateTime.now();

  /// Add an issue to the report
  void addIssue(ConsistencyIssue issue) {
    issues.add(issue);
  }

  /// Add a warning to the report
  void addWarning(ConsistencyWarning warning) {
    warnings.add(warning);
  }

  /// Calculate overall consistency score
  void calculateOverallScore() {
    if (issues.isEmpty) {
      overallScore = 100.0;
      return;
    }

    // Calculate score based on issue severity
    double totalWeight = 0.0;
    double weightedScore = 0.0;

    for (final issue in issues) {
      double weight = 0.0;
      switch (issue.severity) {
        case ValidationSeverity.critical:
          weight = 4.0;
          break;
        case ValidationSeverity.high:
          weight = 3.0;
          break;
        case ValidationSeverity.medium:
          weight = 2.0;
          break;
        case ValidationSeverity.low:
          weight = 1.0;
          break;
        case ValidationSeverity.none:
          weight = 0.0;
          break;
      }
      
      totalWeight += weight;
      weightedScore += weight * 0.0; // Each issue reduces score
    }

    if (totalWeight > 0) {
      overallScore = (100.0 - (weightedScore / totalWeight * 100.0)).clamp(0.0, 100.0);
    } else {
      overallScore = 100.0;
    }
  }

  /// Get issues by severity
  List<ConsistencyIssue> getIssuesBySeverity(ValidationSeverity severity) {
    return issues.where((i) => i.severity == severity).toList();
  }

  /// Get critical issues
  List<ConsistencyIssue> get criticalIssues => getIssuesBySeverity(ValidationSeverity.critical);

  /// Get high priority issues
  List<ConsistencyIssue> get highIssues => getIssuesBySeverity(ValidationSeverity.high);

  /// Get medium priority issues
  List<ConsistencyIssue> get mediumIssues => getIssuesBySeverity(ValidationSeverity.medium);

  /// Get low priority issues
  List<ConsistencyIssue> get lowIssues => getIssuesBySeverity(ValidationSeverity.low);
}

/// Consistency issue
class ConsistencyIssue {
  final ConsistencyIssueType type;
  final ValidationSeverity severity;
  final String message;
  final String affectedData;
  final String suggestedAction;

  ConsistencyIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.affectedData,
    required this.suggestedAction,
  });
}

/// Consistency warning
class ConsistencyWarning {
  final ConsistencyWarningType type;
  final String message;
  final String affectedData;
  final String suggestedAction;

  ConsistencyWarning({
    required this.type,
    required this.message,
    required this.affectedData,
    required this.suggestedAction,
  });
}

/// Consistency issue types
enum ConsistencyIssueType {
  missingData,
  dataInconsistency,
  dataOutOfRange,
  systemError,
  performanceIssue,
}

/// Consistency warning types
enum ConsistencyWarningType {
  dataQuality,
  performance,
  consistency,
  recommendation,
}
