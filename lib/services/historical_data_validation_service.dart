import 'dart:math' as math;
import '../models/historical_nps_data.dart';
import '../services/historical_nps_aggregation_service.dart';
import '../utils/log.dart';

/// Service for validating historical NPS data integrity and completeness
class HistoricalDataValidationService {
  static final HistoricalDataValidationService _instance = HistoricalDataValidationService._internal();
  factory HistoricalDataValidationService() => _instance;
  HistoricalDataValidationService._internal();

  static HistoricalDataValidationService get instance => _instance;

  late HistoricalNPSAggregationService _aggregationService;

  Future<void> initialize() async {
    _aggregationService = HistoricalNPSAggregationService.instance;
    await _aggregationService.initialize();
    d('[HistoricalDataValidationService] Initialized');
  }

  /// Validate all historical data for completeness and integrity
  Future<ValidationReport> validateAllHistoricalData() async {
    try {
      d('[HistoricalDataValidationService] Starting comprehensive validation');
      
      final allHistoricalData = await _aggregationService.getAllHistoricalData();
      final validationResults = <ServerValidationResult>[];
      
      for (final historicalData in allHistoricalData) {
        final result = await _validateServerHistoricalData(historicalData);
        validationResults.add(result);
      }
      
      final report = ValidationReport(
        totalServers: allHistoricalData.length,
        validationResults: validationResults,
        generatedAt: DateTime.now(),
        overallHealthScore: _calculateOverallHealthScore(validationResults),
      );
      
      d('[HistoricalDataValidationService] Validation completed: ${report.overallHealthScore.toStringAsFixed(1)}% health score');
      return report;
    } catch (e) {
      d('[HistoricalDataValidationService] Error during validation: $e');
      return ValidationReport(
        totalServers: 0,
        validationResults: [],
        generatedAt: DateTime.now(),
        overallHealthScore: 0.0,
        errors: [e.toString()],
      );
    }
  }

  /// Validate historical data for a specific server
  Future<ServerValidationResult> _validateServerHistoricalData(HistoricalNPSData historicalData) async {
    final issues = <ValidationIssue>[];
    final warnings = <ValidationWarning>[];
    
    // Basic data presence validation
    if (historicalData.monthlyData.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.noData,
        severity: ValidationSeverity.critical,
        message: 'No monthly performance data available',
        serverId: historicalData.serverId,
        serverName: historicalData.serverName,
      ));
    }
    
    // Data completeness validation
    final completenessScore = _calculateDataCompleteness(historicalData);
    if (completenessScore < 0.5) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.incompleteData,
        severity: ValidationSeverity.high,
        message: 'Data completeness is ${(completenessScore * 100).toStringAsFixed(1)}% - below threshold',
        serverId: historicalData.serverId,
        serverName: historicalData.serverName,
      ));
    } else if (completenessScore < 0.8) {
      warnings.add(ValidationWarning(
        type: ValidationWarningType.lowCompleteness,
        message: 'Data completeness is ${(completenessScore * 100).toStringAsFixed(1)}% - consider improving data collection',
        serverId: historicalData.serverId,
        serverName: historicalData.serverName,
      ));
    }
    
    // Data consistency validation
    final consistencyIssues = _validateDataConsistency(historicalData);
    issues.addAll(consistencyIssues);
    
    // Trend validation
    final trendIssues = _validateTrendData(historicalData);
    issues.addAll(trendIssues);
    
    // Seasonal pattern validation
    final seasonalWarnings = _validateSeasonalPattern(historicalData);
    warnings.addAll(seasonalWarnings);
    
    // Performance classification validation
    final classificationIssues = _validatePerformanceClassification(historicalData);
    issues.addAll(classificationIssues);
    
    return ServerValidationResult(
      serverId: historicalData.serverId,
      serverName: historicalData.serverName,
      issues: issues,
      warnings: warnings,
      dataQualityScore: _calculateDataQualityScore(historicalData, issues, warnings),
      lastUpdated: historicalData.lastUpdated,
    );
  }

  /// Calculate data completeness score (0.0 to 1.0)
  double _calculateDataCompleteness(HistoricalNPSData historicalData) {
    if (historicalData.monthlyData.isEmpty) return 0.0;
    
    double completeness = 0.0;
    final totalFields = 7; // Number of fields we check for completeness
    int completeFields = 0;
    
    for (final monthlyData in historicalData.monthlyData) {
      // Check if essential fields have data
      if (monthlyData.oneMonthNPS > 0) completeFields++;
      if (monthlyData.threeMonthNPS > 0) completeFields++;
      if (monthlyData.allTimeNPS > 0) completeFields++;
      if (monthlyData.responseCount > 0) completeFields++;
      if (monthlyData.sales > 0) completeFields++;
      if (monthlyData.tableCount > 0) completeFields++;
      if (monthlyData.context.notes.isNotEmpty) completeFields++;
    }
    
    completeness = completeFields / (historicalData.monthlyData.length * totalFields);
    return completeness.clamp(0.0, 1.0);
  }

  /// Validate data consistency across time periods
  List<ValidationIssue> _validateDataConsistency(HistoricalNPSData historicalData) {
    final issues = <ValidationIssue>[];
    
    if (historicalData.monthlyData.length < 2) return issues;
    
    // Check for impossible NPS score progressions
    for (int i = 0; i < historicalData.monthlyData.length - 1; i++) {
      final current = historicalData.monthlyData[i];
      final previous = historicalData.monthlyData[i + 1];
      
      // All-time NPS should generally be more stable than monthly NPS
      final allTimeChange = (current.allTimeNPS - previous.allTimeNPS).abs();
      if (allTimeChange > 20.0) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.inconsistentData,
          severity: ValidationSeverity.medium,
          message: 'All-time NPS changed by ${allTimeChange.toStringAsFixed(1)} points between ${previous.month.month}/${previous.month.year} and ${current.month.month}/${current.month.year}',
          serverId: historicalData.serverId,
          serverName: historicalData.serverName,
        ));
      }
      
      // Three-month NPS should be between one-month and all-time
      if (current.threeMonthNPS < math.min(current.oneMonthNPS, current.allTimeNPS) - 5.0 ||
          current.threeMonthNPS > math.max(current.oneMonthNPS, current.allTimeNPS) + 5.0) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.inconsistentData,
          severity: ValidationSeverity.low,
          message: 'Three-month NPS (${current.threeMonthNPS.toStringAsFixed(1)}%) appears inconsistent with one-month (${current.oneMonthNPS.toStringAsFixed(1)}%) and all-time (${current.allTimeNPS.toStringAsFixed(1)}%)',
          serverId: historicalData.serverId,
          serverName: historicalData.serverName,
        ));
      }
    }
    
    return issues;
  }

  /// Validate trend data for reasonableness
  List<ValidationIssue> _validateTrendData(HistoricalNPSData historicalData) {
    final issues = <ValidationIssue>[];
    
    // Check for unrealistic trend slopes
    if (historicalData.trend.slope.abs() > 10.0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.unrealisticTrend,
        severity: ValidationSeverity.medium,
        message: 'Trend slope of ${historicalData.trend.slope.toStringAsFixed(2)} points per month seems unrealistic',
        serverId: historicalData.serverId,
        serverName: historicalData.serverName,
      ));
    }
    
    // Check for impossible volatility values
    if (historicalData.volatility > 50.0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.highVolatility,
        severity: ValidationSeverity.medium,
        message: 'Volatility of ${historicalData.volatility.toStringAsFixed(1)} points is extremely high',
        serverId: historicalData.serverId,
        serverName: historicalData.serverName,
      ));
    }
    
    return issues;
  }

  /// Validate seasonal pattern data
  List<ValidationWarning> _validateSeasonalPattern(HistoricalNPSData historicalData) {
    final warnings = <ValidationWarning>[];
    
    if (historicalData.seasonalPattern == null) {
      if (historicalData.monthlyData.length >= 12) {
        warnings.add(ValidationWarning(
          type: ValidationWarningType.noSeasonalPattern,
          message: 'No seasonal pattern detected despite having ${historicalData.monthlyData.length} months of data',
          serverId: historicalData.serverId,
          serverName: historicalData.serverName,
        ));
      }
    } else {
      // Check if seasonal pattern strength is reasonable
      if (historicalData.seasonalPattern!.seasonalityStrength > 0.5) {
        warnings.add(ValidationWarning(
          type: ValidationWarningType.strongSeasonality,
          message: 'Very strong seasonal pattern detected (${(historicalData.seasonalPattern!.seasonalityStrength * 100).toStringAsFixed(1)}% variation)',
          serverId: historicalData.serverId,
          serverName: historicalData.serverName,
        ));
      }
    }
    
    return warnings;
  }

  /// Validate performance classification
  List<ValidationIssue> _validatePerformanceClassification(HistoricalNPSData historicalData) {
    final issues = <ValidationIssue>[];
    
    // Check if classification matches the data
    final recentAvg = historicalData.monthlyData.take(3).map((m) => m.oneMonthNPS).reduce((a, b) => a + b) / 3;
    final allTimeAvg = historicalData.monthlyData.map((m) => m.allTimeNPS).reduce((a, b) => a + b) / historicalData.monthlyData.length;
    
    switch (historicalData.classification) {
      case PerformanceClassification.elite:
        if (allTimeAvg < 85.0 || recentAvg < 80.0) {
          issues.add(ValidationIssue(
            type: ValidationIssueType.misclassifiedPerformance,
            severity: ValidationSeverity.medium,
            message: 'Elite classification may be incorrect: all-time avg ${allTimeAvg.toStringAsFixed(1)}%, recent avg ${recentAvg.toStringAsFixed(1)}%',
            serverId: historicalData.serverId,
            serverName: historicalData.serverName,
          ));
        }
        break;
      case PerformanceClassification.critical:
        if (allTimeAvg > 60.0 || recentAvg > 55.0) {
          issues.add(ValidationIssue(
            type: ValidationIssueType.misclassifiedPerformance,
            severity: ValidationSeverity.medium,
            message: 'Critical classification may be incorrect: all-time avg ${allTimeAvg.toStringAsFixed(1)}%, recent avg ${recentAvg.toStringAsFixed(1)}%',
            serverId: historicalData.serverId,
            serverName: historicalData.serverName,
          ));
        }
        break;
      default:
        break;
    }
    
    return issues;
  }

  /// Calculate overall data quality score
  double _calculateDataQualityScore(
    HistoricalNPSData historicalData,
    List<ValidationIssue> issues,
    List<ValidationWarning> warnings,
  ) {
    double score = 1.0;
    
    // Deduct points for issues
    for (final issue in issues) {
      switch (issue.severity) {
        case ValidationSeverity.critical:
          score -= 0.3;
          break;
        case ValidationSeverity.high:
          score -= 0.2;
          break;
        case ValidationSeverity.medium:
          score -= 0.1;
          break;
        case ValidationSeverity.low:
          score -= 0.05;
          break;
      }
    }
    
    // Deduct points for warnings
    score -= warnings.length * 0.02;
    
    // Bonus for data completeness
    final completeness = _calculateDataCompleteness(historicalData);
    score += completeness * 0.2;
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate overall health score for all servers
  double _calculateOverallHealthScore(List<ServerValidationResult> results) {
    if (results.isEmpty) return 0.0;
    
    final totalScore = results.fold<double>(0.0, (sum, result) => sum + result.dataQualityScore);
    return totalScore / results.length;
  }
}

/// Validation report containing results for all servers
class ValidationReport {
  final int totalServers;
  final List<ServerValidationResult> validationResults;
  final DateTime generatedAt;
  final double overallHealthScore;
  final List<String> errors;

  ValidationReport({
    required this.totalServers,
    required this.validationResults,
    required this.generatedAt,
    required this.overallHealthScore,
    this.errors = const [],
  });

  /// Get servers with critical issues
  List<ServerValidationResult> get serversWithCriticalIssues {
    return validationResults.where((result) => 
      result.issues.any((issue) => issue.severity == ValidationSeverity.critical)
    ).toList();
  }

  /// Get servers with high data quality
  List<ServerValidationResult> get highQualityServers {
    return validationResults.where((result) => result.dataQualityScore >= 0.8).toList();
  }

  /// Get summary statistics
  Map<String, int> get summaryStats {
    return {
      'totalServers': totalServers,
      'criticalIssues': serversWithCriticalIssues.length,
      'highQuality': highQualityServers.length,
      'totalIssues': validationResults.fold(0, (sum, result) => sum + result.issues.length),
      'totalWarnings': validationResults.fold(0, (sum, result) => sum + result.warnings.length),
    };
  }
}

/// Validation result for a single server
class ServerValidationResult {
  final String serverId;
  final String serverName;
  final List<ValidationIssue> issues;
  final List<ValidationWarning> warnings;
  final double dataQualityScore;
  final DateTime lastUpdated;

  ServerValidationResult({
    required this.serverId,
    required this.serverName,
    required this.issues,
    required this.warnings,
    required this.dataQualityScore,
    required this.lastUpdated,
  });
}

/// Validation issue with severity
class ValidationIssue {
  final ValidationIssueType type;
  final ValidationSeverity severity;
  final String message;
  final String serverId;
  final String serverName;

  ValidationIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.serverId,
    required this.serverName,
  });
}

/// Validation warning
class ValidationWarning {
  final ValidationWarningType type;
  final String message;
  final String serverId;
  final String serverName;

  ValidationWarning({
    required this.type,
    required this.message,
    required this.serverId,
    required this.serverName,
  });
}

/// Types of validation issues
enum ValidationIssueType {
  noData,
  incompleteData,
  inconsistentData,
  unrealisticTrend,
  highVolatility,
  misclassifiedPerformance,
}

/// Types of validation warnings
enum ValidationWarningType {
  lowCompleteness,
  noSeasonalPattern,
  strongSeasonality,
}

/// Severity levels for validation issues
enum ValidationSeverity {
  low,
  medium,
  high,
  critical,
}
