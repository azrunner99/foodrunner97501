import 'package:flutter/foundation.dart';
import '../models/performance_models.dart';
import '../utils/log.dart';

/// Comprehensive data validation service
/// 
/// This service provides validation for all data sources and ensures
/// data quality, consistency, and completeness across the application.
class DataValidationService {
  static DataValidationService? _instance;
  static DataValidationService get instance => _instance ??= DataValidationService._();
  
  DataValidationService._();

  /// Validate unified server data for completeness and quality
  ValidationResult validateUnifiedServerData(UnifiedServerData server) {
    final issues = <ValidationIssue>[];
    final warnings = <ValidationWarning>[];
    
    try {
      d('[DataValidationService] Validating server: ${server.serverName}');
      
      // 1. Basic Data Validation
      _validateBasicData(server, issues, warnings);
      
      // 2. Shift Data Validation
      _validateShiftData(server, issues, warnings);
      
      // 3. NPS Data Validation
      _validateNPSData(server, issues, warnings);
      
      // 4. Business Data Validation
      _validateBusinessData(server, issues, warnings);
      
      // 5. Data Consistency Validation
      _validateDataConsistency(server, issues, warnings);
      
      // 6. Performance Data Validation
      _validatePerformanceData(server, issues, warnings);
      
      final severity = _calculateValidationSeverity(issues, warnings);
      
      d('[DataValidationService] Validation complete for ${server.serverName}: $severity severity');
      
      return ValidationResult(
        serverId: server.serverId,
        serverName: server.serverName,
        isValid: issues.isEmpty,
        severity: severity,
        issues: issues,
        warnings: warnings,
        validatedAt: DateTime.now(),
      );
      
    } catch (e) {
      d('[DataValidationService] Error validating server ${server.serverName}: $e');
      
      return ValidationResult(
        serverId: server.serverId,
        serverName: server.serverName,
        isValid: false,
        severity: ValidationSeverity.critical,
        issues: [ValidationIssue(
          type: ValidationIssueType.systemError,
          severity: ValidationSeverity.critical,
          message: 'System error during validation: $e',
          field: 'system',
          suggestedAction: 'Contact system administrator',
        )],
        warnings: [],
        validatedAt: DateTime.now(),
      );
    }
  }

  /// Validate basic server data
  void _validateBasicData(UnifiedServerData server, List<ValidationIssue> issues, List<ValidationWarning> warnings) {
    // Server ID validation
    if (server.serverId.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.missingData,
        severity: ValidationSeverity.critical,
        message: 'Server ID is missing',
        field: 'serverId',
        suggestedAction: 'Check server registration',
      ));
    }
    
    // Server name validation
    if (server.serverName.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.missingData,
        severity: ValidationSeverity.critical,
        message: 'Server name is missing',
        field: 'serverName',
        suggestedAction: 'Update server profile',
      ));
    } else if (server.serverName.length < 2) {
      warnings.add(ValidationWarning(
        type: ValidationWarningType.dataQuality,
        message: 'Server name is very short',
        field: 'serverName',
        suggestedAction: 'Verify server name is correct',
      ));
    }
    
    // Hire date validation
    if (server.hireDate.isAfter(DateTime.now())) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.dataInconsistency,
        severity: ValidationSeverity.high,
        message: 'Hire date is in the future',
        field: 'hireDate',
        suggestedAction: 'Check hire date accuracy',
      ));
    }
    
    // Days employed validation
    if (server.daysEmployed < 0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.dataInconsistency,
        severity: ValidationSeverity.high,
        message: 'Days employed is negative',
        field: 'daysEmployed',
        suggestedAction: 'Check hire date calculation',
      ));
    } else if (server.daysEmployed > 3650) { // 10 years
      warnings.add(ValidationWarning(
        type: ValidationWarningType.dataQuality,
        message: 'Days employed seems unusually high',
        field: 'daysEmployed',
        suggestedAction: 'Verify hire date accuracy',
      ));
    }
  }

  /// Validate shift data
  void _validateShiftData(UnifiedServerData server, List<ValidationIssue> issues, List<ValidationWarning> warnings) {
    final shiftData = server.shiftData;
    
    // Total runs validation
    if (shiftData.totalRuns < 0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.dataInconsistency,
        severity: ValidationSeverity.critical,
        message: 'Total runs cannot be negative',
        field: 'totalRuns',
        suggestedAction: 'Check shift data calculation',
      ));
    }
    
    // Shifts worked validation
    if (shiftData.shiftsWorked < 0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.dataInconsistency,
        severity: ValidationSeverity.critical,
        message: 'Shifts worked cannot be negative',
        field: 'shiftsWorked',
        suggestedAction: 'Check shift data calculation',
      ));
    }
    
    // Efficiency validation
    if (shiftData.shiftsWorked > 0) {
      final avgRunsPerShift = shiftData.totalRuns / shiftData.shiftsWorked;
      
      if (avgRunsPerShift > 20) {
        warnings.add(ValidationWarning(
          type: ValidationWarningType.dataQuality,
          message: 'Average runs per shift is unusually high ($avgRunsPerShift)',
          field: 'efficiency',
          suggestedAction: 'Verify run count accuracy',
        ));
      } else if (avgRunsPerShift < 0.5 && shiftData.shiftsWorked > 5) {
        warnings.add(ValidationWarning(
          type: ValidationWarningType.performance,
          message: 'Low average runs per shift ($avgRunsPerShift)',
          field: 'efficiency',
          suggestedAction: 'Review server performance',
        ));
      }
    }
    
    // Recent shifts validation
    if (shiftData.recentShifts.isEmpty && shiftData.shiftsWorked > 0) {
      warnings.add(ValidationWarning(
        type: ValidationWarningType.dataQuality,
        message: 'No recent shift records found despite having shifts worked',
        field: 'recentShifts',
        suggestedAction: 'Check shift data synchronization',
      ));
    }
  }

  /// Validate NPS data
  void _validateNPSData(UnifiedServerData server, List<ValidationIssue> issues, List<ValidationWarning> warnings) {
    final npsData = server.npsData;
    
    // NPS score validation
    if (npsData.monthlyScore != null) {
      if (npsData.monthlyScore! < 0 || npsData.monthlyScore! > 100) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.dataInconsistency,
          severity: ValidationSeverity.high,
          message: 'Monthly NPS score is out of range (${npsData.monthlyScore})',
          field: 'monthlyNpsScore',
          suggestedAction: 'Check NPS data entry',
        ));
      }
    }
    
    if (npsData.threeMonthAverage != null) {
      if (npsData.threeMonthAverage! < 0 || npsData.threeMonthAverage! > 100) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.dataInconsistency,
          severity: ValidationSeverity.high,
          message: 'Three-month NPS average is out of range (${npsData.threeMonthAverage})',
          field: 'threeMonthNpsAverage',
          suggestedAction: 'Check NPS data calculation',
        ));
      }
    }
    
    // Response count validation
    if (npsData.responseCount < 0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.dataInconsistency,
        severity: ValidationSeverity.high,
        message: 'NPS response count cannot be negative',
        field: 'npsResponseCount',
        suggestedAction: 'Check NPS data calculation',
      ));
    }
    
    // Data availability validation
    if (!npsData.hasActualData && npsData.responseCount > 0) {
      warnings.add(ValidationWarning(
        type: ValidationWarningType.dataQuality,
        message: 'NPS data marked as unavailable but response count > 0',
        field: 'npsDataAvailability',
        suggestedAction: 'Check NPS data synchronization',
      ));
    }
  }

  /// Validate business data
  void _validateBusinessData(UnifiedServerData server, List<ValidationIssue> issues, List<ValidationWarning> warnings) {
    final businessData = server.businessData;
    
    // Sales validation
    if (businessData.estimatedSales < 0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.dataInconsistency,
        severity: ValidationSeverity.high,
        message: 'Estimated sales cannot be negative',
        field: 'estimatedSales',
        suggestedAction: 'Check sales data calculation',
      ));
    }
    
    // Guest count validation
    if (businessData.estimatedGuests < 0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.dataInconsistency,
        severity: ValidationSeverity.high,
        message: 'Estimated guest count cannot be negative',
        field: 'estimatedGuests',
        suggestedAction: 'Check guest count calculation',
      ));
    }
    
    // Business data consistency
    if (businessData.estimatedSales > 0 && businessData.estimatedGuests == 0) {
      warnings.add(ValidationWarning(
        type: ValidationWarningType.dataQuality,
        message: 'Sales data exists but no guest count',
        field: 'businessDataConsistency',
        suggestedAction: 'Check business data calculation',
      ));
    }
  }

  /// Validate data consistency across sources
  void _validateDataConsistency(UnifiedServerData server, List<ValidationIssue> issues, List<ValidationWarning> warnings) {
    // Check for data source conflicts
    if (server.shiftData.shiftsWorked > 0 && server.shiftData.totalRuns == 0) {
      warnings.add(ValidationWarning(
        type: ValidationWarningType.dataQuality,
        message: 'Shifts worked but no runs recorded',
        field: 'dataConsistency',
        suggestedAction: 'Check shift data accuracy',
      ));
    }
    
    // Check for unrealistic performance metrics
    if (server.shiftData.shiftsWorked > 0) {
      final avgRunsPerShift = server.shiftData.totalRuns / server.shiftData.shiftsWorked;
      final estimatedGuestsPerShift = server.totalGuestCount / server.shiftData.shiftsWorked;
      
      if (avgRunsPerShift > 0 && estimatedGuestsPerShift > 0) {
        final runsToGuestsRatio = estimatedGuestsPerShift / avgRunsPerShift;
        
        if (runsToGuestsRatio < 0.5 || runsToGuestsRatio > 5.0) {
          warnings.add(ValidationWarning(
            type: ValidationWarningType.dataQuality,
            message: 'Unusual ratio between runs and guest count ($runsToGuestsRatio)',
            field: 'dataConsistency',
            suggestedAction: 'Verify business data calculations',
          ));
        }
      }
    }
  }

  /// Validate performance data
  void _validatePerformanceData(UnifiedServerData server, List<ValidationIssue> issues, List<ValidationWarning> warnings) {
    // This would validate calculated performance metrics
    // For now, we'll add basic validation
    
    if (server.shiftData.shiftsWorked == 0 && server.daysEmployed > 30) {
      warnings.add(ValidationWarning(
        type: ValidationWarningType.performance,
        message: 'No shifts worked in recent period despite being employed',
        field: 'performance',
        suggestedAction: 'Check shift scheduling and attendance',
      ));
    }
  }

  /// Calculate validation severity based on issues and warnings
  ValidationSeverity _calculateValidationSeverity(List<ValidationIssue> issues, List<ValidationWarning> warnings) {
    if (issues.any((issue) => issue.severity == ValidationSeverity.critical)) {
      return ValidationSeverity.critical;
    }
    
    if (issues.any((issue) => issue.severity == ValidationSeverity.high)) {
      return ValidationSeverity.high;
    }
    
    if (issues.isNotEmpty) {
      return ValidationSeverity.medium;
    }
    
    if (warnings.length > 5) {
      return ValidationSeverity.low;
    }
    
    return ValidationSeverity.none;
  }

  /// Get validation summary for multiple servers
  ValidationSummary validateMultipleServers(List<UnifiedServerData> servers) {
    final results = servers.map((server) => validateUnifiedServerData(server)).toList();
    
    final totalServers = servers.length;
    final validServers = results.where((r) => r.isValid).length;
    final criticalIssues = results.where((r) => r.severity == ValidationSeverity.critical).length;
    final highIssues = results.where((r) => r.severity == ValidationSeverity.high).length;
    final totalIssues = results.fold(0, (sum, r) => sum + r.issues.length);
    final totalWarnings = results.fold(0, (sum, r) => sum + r.warnings.length);
    
    return ValidationSummary(
      totalServers: totalServers,
      validServers: validServers,
      criticalIssues: criticalIssues,
      highIssues: highIssues,
      totalIssues: totalIssues,
      totalWarnings: totalWarnings,
      validationResults: results,
      validatedAt: DateTime.now(),
    );
  }
}

/// Validation result for a single server
class ValidationResult {
  final String serverId;
  final String serverName;
  final bool isValid;
  final ValidationSeverity severity;
  final List<ValidationIssue> issues;
  final List<ValidationWarning> warnings;
  final DateTime validatedAt;

  ValidationResult({
    required this.serverId,
    required this.serverName,
    required this.isValid,
    required this.severity,
    required this.issues,
    required this.warnings,
    required this.validatedAt,
  });
}

/// Validation summary for multiple servers
class ValidationSummary {
  final int totalServers;
  final int validServers;
  final int criticalIssues;
  final int highIssues;
  final int totalIssues;
  final int totalWarnings;
  final List<ValidationResult> validationResults;
  final DateTime validatedAt;

  ValidationSummary({
    required this.totalServers,
    required this.validServers,
    required this.criticalIssues,
    required this.highIssues,
    required this.totalIssues,
    required this.totalWarnings,
    required this.validationResults,
    required this.validatedAt,
  });

  double get validationScore => totalServers > 0 ? validServers / totalServers : 0.0;
  bool get hasCriticalIssues => criticalIssues > 0;
  bool get hasHighIssues => highIssues > 0;
}

/// Validation issue
class ValidationIssue {
  final ValidationIssueType type;
  final ValidationSeverity severity;
  final String message;
  final String field;
  final String suggestedAction;

  ValidationIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.field,
    required this.suggestedAction,
  });
}

/// Validation warning
class ValidationWarning {
  final ValidationWarningType type;
  final String message;
  final String field;
  final String suggestedAction;

  ValidationWarning({
    required this.type,
    required this.message,
    required this.field,
    required this.suggestedAction,
  });
}

/// Validation issue types
enum ValidationIssueType {
  missingData,
  dataInconsistency,
  dataOutOfRange,
  systemError,
  performanceIssue,
}

/// Validation warning types
enum ValidationWarningType {
  dataQuality,
  performance,
  consistency,
  recommendation,
}

/// Validation severity levels
enum ValidationSeverity {
  none,
  low,
  medium,
  high,
  critical,
}

