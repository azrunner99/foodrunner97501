import 'dart:math' as math;
import '../models.dart';
import '../app_state.dart';

/// Advanced data validation and anomaly detection engine
/// Provides statistical analysis, outlier detection, and data integrity monitoring
class DataValidationEngine {
  static const double _outlierThreshold = 2.5; // Standard deviations
  static const int _minimumDataPoints = 10;
  
  /// Comprehensive data validation report
  static Future<ValidationReport> validateAllData() async {
    final startTime = DateTime.now();
    final appState = AppState();
    final shifts = appState.history;
    final servers = appState.servers;
    
    final validationReport = ValidationReport(
      reportId: _generateValidationId(),
      validationDate: startTime,
      totalShiftsAnalyzed: shifts.length,
      totalServersAnalyzed: servers.length,
      validationCompleted: false,
    );

    try {
      // Data integrity checks
      final integrityResults = await _performDataIntegrityChecks(shifts, servers);
      validationReport.integrityResults = integrityResults;

      // Performance anomaly detection
      final anomalies = await _detectPerformanceAnomalies(shifts, servers);
      validationReport.anomalies = anomalies;

      // Statistical outlier analysis
      final outliers = await _analyzeStatisticalOutliers(shifts, servers);
      validationReport.outliers = outliers;

      // Data consistency validation
      final consistencyResults = await _validateDataConsistency(shifts, servers);
      validationReport.consistencyResults = consistencyResults;

      // Pattern recognition analysis
      final patterns = await _detectUnusualPatterns(shifts, servers);
      validationReport.unusualPatterns = patterns;

      // Generate recommendations
      final recommendations = _generateValidationRecommendations(validationReport);
      validationReport.recommendations = recommendations;

      validationReport.validationCompleted = true;
      validationReport.processingTime = DateTime.now().difference(startTime);
      
      return validationReport;
    } catch (e) {
      validationReport.validationCompleted = false;
      validationReport.errorMessage = 'Validation failed: $e';
      return validationReport;
    }
  }

  /// Detect performance anomalies using statistical methods
  static Future<List<PerformanceAnomaly>> _detectPerformanceAnomalies(
    List<ShiftRecord> shifts,
    List<Server> servers,
  ) async {
    final anomalies = <PerformanceAnomaly>[];
    
    for (final server in servers) {
      final serverShifts = shifts.where((s) => s.counts.containsKey(server.id)).toList();
      
      if (serverShifts.length < _minimumDataPoints) continue;

      // Analyze daily performance patterns
      final dailyPerformance = _calculateDailyPerformance(server.id, serverShifts);
      final runsOutliers = _detectOutliers(dailyPerformance.values.toList());
      
      for (final outlier in runsOutliers) {
        final anomaly = PerformanceAnomaly(
          serverId: server.id,
          serverName: server.name,
          anomalyType: AnomalyType.performanceSpike,
          detectedDate: DateTime.now(),
          affectedDate: dailyPerformance.keys.elementAt(outlier.index),
          value: outlier.value,
          expectedRange: ExpectedRange(
            minimum: outlier.lowerBound,
            maximum: outlier.upperBound,
            average: outlier.average,
          ),
          severity: _calculateSeverity(outlier.standardDeviations),
          confidence: _calculateConfidence(outlier.standardDeviations),
          description: _generateAnomalyDescription(outlier, server.name),
          possibleCauses: _identifyPossibleCauses(outlier, serverShifts),
        );
        anomalies.add(anomaly);
      }

      // Detect efficiency anomalies
      final efficiencyData = _calculateEfficiencyTrends(server.id, serverShifts);
      final efficiencyOutliers = _detectOutliers(efficiencyData);
      
      for (final outlier in efficiencyOutliers) {
        final anomaly = PerformanceAnomaly(
          serverId: server.id,
          serverName: server.name,
          anomalyType: AnomalyType.efficiencyDrop,
          detectedDate: DateTime.now(),
          affectedDate: DateTime.now().subtract(Duration(days: outlier.index)),
          value: outlier.value,
          expectedRange: ExpectedRange(
            minimum: outlier.lowerBound,
            maximum: outlier.upperBound,
            average: outlier.average,
          ),
          severity: _calculateSeverity(outlier.standardDeviations),
          confidence: _calculateConfidence(outlier.standardDeviations),
          description: 'Efficiency anomaly detected for ${server.name}',
          possibleCauses: ['Training needed', 'External factors', 'Personal issues'],
        );
        anomalies.add(anomaly);
      }
    }

    return anomalies;
  }

  /// Perform comprehensive data integrity checks
  static Future<DataIntegrityResults> _performDataIntegrityChecks(
    List<ShiftRecord> shifts,
    List<Server> servers,
  ) async {
    final results = DataIntegrityResults();
    
    // Check for missing data
    results.missingDataIssues = _checkMissingData(shifts, servers);
    
    // Check for duplicate entries
    results.duplicateEntries = _checkDuplicateEntries(shifts);
    
    // Check data consistency
    results.inconsistencyIssues = _checkDataConsistency(shifts);
    
    // Check for impossible values
    results.impossibleValues = _checkImpossibleValues(shifts);
    
    // Check timestamp integrity
    results.timestampIssues = _checkTimestampIntegrity(shifts);
    
    return results;
  }

  /// Detect statistical outliers using Z-score and IQR methods
  static Future<List<StatisticalOutlier>> _analyzeStatisticalOutliers(
    List<ShiftRecord> shifts,
    List<Server> servers,
  ) async {
    final outliers = <StatisticalOutlier>[];
    
    for (final server in servers) {
      final serverData = _extractServerPerformanceData(server.id, shifts);
      
      if (serverData.length < _minimumDataPoints) continue;

      // Z-score analysis
      final zScoreOutliers = _detectZScoreOutliers(serverData, server);
      outliers.addAll(zScoreOutliers);
      
      // IQR analysis
      final iqrOutliers = _detectIQROutliers(serverData, server);
      outliers.addAll(iqrOutliers);
      
      // Modified Z-score analysis (more robust)
      final modifiedZOutliers = _detectModifiedZScoreOutliers(serverData, server);
      outliers.addAll(modifiedZOutliers);
    }

    return outliers;
  }

  /// Validate data consistency across different metrics
  static Future<ConsistencyResults> _validateDataConsistency(
    List<ShiftRecord> shifts,
    List<Server> servers,
  ) async {
    final results = ConsistencyResults();
    
    // Check consistency between shift data and calculated metrics
    for (final server in servers) {
      final serverShifts = shifts.where((s) => s.counts.containsKey(server.id)).toList();
      
      if (serverShifts.isEmpty) continue;

      // Calculate expected vs actual totals
      final expectedTotal = serverShifts.fold<int>(0, (sum, shift) => sum + (shift.counts[server.id] ?? 0));
      final profile = AppState().profiles[server.id] ?? ServerProfile();
      
      final discrepancy = (profile.allTimeRuns - expectedTotal).abs();
      if (discrepancy > 5) { // Allow for small discrepancies
        results.totalDiscrepancies.add(DataDiscrepancy(
          serverId: server.id,
          serverName: server.name,
          metric: 'Total Runs',
          expected: expectedTotal.toDouble(),
          actual: profile.allTimeRuns.toDouble(),
          discrepancy: discrepancy.toDouble(),
          severity: discrepancy > 20 ? 'high' : 'medium',
        ));
      }
    }

    return results;
  }

  /// Detect unusual patterns in performance data
  static Future<List<UnusualPattern>> _detectUnusualPatterns(
    List<ShiftRecord> shifts,
    List<Server> servers,
  ) async {
    final patterns = <UnusualPattern>[];
    
    for (final server in servers) {
      final serverShifts = shifts.where((s) => s.counts.containsKey(server.id)).toList();
      
      if (serverShifts.length < 14) continue; // Need at least 2 weeks of data

      // Detect weekly patterns
      final weeklyPatterns = _analyzeWeeklyPatterns(server.id, serverShifts);
      patterns.addAll(weeklyPatterns);

      // Detect sudden performance changes
      final performanceChanges = _detectPerformanceChanges(server.id, serverShifts);
      patterns.addAll(performanceChanges);

      // Detect unusual shift patterns
      final shiftPatterns = _analyzeShiftPatterns(server.id, serverShifts);
      patterns.addAll(shiftPatterns);
    }

    return patterns;
  }

  /// Calculate daily performance for a server
  static Map<DateTime, double> _calculateDailyPerformance(String serverId, List<ShiftRecord> shifts) {
    final dailyPerformance = <DateTime, double>{};
    
    for (final shift in shifts) {
      final date = DateTime(shift.start.year, shift.start.month, shift.start.day);
      final runs = shift.counts[serverId] ?? 0;
      
      if (dailyPerformance.containsKey(date)) {
        dailyPerformance[date] = dailyPerformance[date]! + runs;
      } else {
        dailyPerformance[date] = runs.toDouble();
      }
    }
    
    return dailyPerformance;
  }

  /// Calculate efficiency trends for a server
  static List<double> _calculateEfficiencyTrends(String serverId, List<ShiftRecord> shifts) {
    final weeklyEfficiency = <double>[];
    const weekDuration = Duration(days: 7);
    
    if (shifts.isEmpty) return weeklyEfficiency;
    
    final startDate = shifts.first.start;
    final endDate = shifts.last.start;
    
    var currentWeekStart = startDate;
    while (currentWeekStart.isBefore(endDate)) {
      final weekEnd = currentWeekStart.add(weekDuration);
      final weekShifts = shifts.where((s) => 
        s.start.isAfter(currentWeekStart) && s.start.isBefore(weekEnd)
      ).toList();
      
      if (weekShifts.isNotEmpty) {
        final totalRuns = weekShifts.fold<int>(0, (sum, shift) => sum + (shift.counts[serverId] ?? 0));
        final efficiency = totalRuns / weekShifts.length;
        weeklyEfficiency.add(efficiency);
      }
      
      currentWeekStart = weekEnd;
    }
    
    return weeklyEfficiency;
  }

  /// Detect outliers using statistical methods
  static List<DataOutlier> _detectOutliers(List<double> data) {
    if (data.length < _minimumDataPoints) return [];
    
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    final standardDeviation = math.sqrt(variance);
    
    final outliers = <DataOutlier>[];
    
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final zScore = (value - mean) / standardDeviation;
      
      if (zScore.abs() > _outlierThreshold) {
        outliers.add(DataOutlier(
          index: i,
          value: value,
          average: mean,
          standardDeviations: zScore.abs(),
          lowerBound: mean - (_outlierThreshold * standardDeviation),
          upperBound: mean + (_outlierThreshold * standardDeviation),
        ));
      }
    }
    
    return outliers;
  }

  /// Check for missing data issues
  static List<DataIssue> _checkMissingData(List<ShiftRecord> shifts, List<Server> servers) {
    final issues = <DataIssue>[];
    
    // Check for servers with no recent data
    final recentDate = DateTime.now().subtract(const Duration(days: 7));
    for (final server in servers) {
      final recentShifts = shifts.where((s) => 
        s.start.isAfter(recentDate) && s.counts.containsKey(server.id)
      ).toList();
      
      if (recentShifts.isEmpty) {
        issues.add(DataIssue(
          type: 'missing_recent_data',
          serverId: server.id,
          serverName: server.name,
          description: 'No data found for ${server.name} in the last 7 days',
          severity: 'medium',
          detectedDate: DateTime.now(),
        ));
      }
    }
    
    return issues;
  }

  /// Check for duplicate entries
  static List<DataIssue> _checkDuplicateEntries(List<ShiftRecord> shifts) {
    final issues = <DataIssue>[];
    final seenShifts = <String>{};
    
    for (final shift in shifts) {
      final shiftKey = '${shift.start.toIso8601String()}_${shift.id}';
      if (seenShifts.contains(shiftKey)) {
        issues.add(DataIssue(
          type: 'duplicate_entry',
          description: 'Duplicate shift entry detected for ${shift.start}',
          severity: 'high',
          detectedDate: DateTime.now(),
        ));
      } else {
        seenShifts.add(shiftKey);
      }
    }
    
    return issues;
  }

  /// Check for data consistency issues
  static List<DataIssue> _checkDataConsistency(List<ShiftRecord> shifts) {
    final issues = <DataIssue>[];
    
    for (final shift in shifts) {
      // Check for negative values
      for (final entry in shift.counts.entries) {
        if (entry.value < 0) {
          issues.add(DataIssue(
            type: 'negative_value',
            serverId: entry.key,
            description: 'Negative run count detected: ${entry.value}',
            severity: 'high',
            detectedDate: DateTime.now(),
          ));
        }
      }
      
      // Check for unreasonably high values
      for (final entry in shift.counts.entries) {
        if (entry.value > 100) { // Assuming 100+ runs in a shift is unusual
          issues.add(DataIssue(
            type: 'unusually_high_value',
            serverId: entry.key,
            description: 'Unusually high run count: ${entry.value}',
            severity: 'medium',
            detectedDate: DateTime.now(),
          ));
        }
      }
    }
    
    return issues;
  }

  /// Check for impossible values
  static List<DataIssue> _checkImpossibleValues(List<ShiftRecord> shifts) {
    final issues = <DataIssue>[];
    
    for (final shift in shifts) {
      // Check for future dates
      if (shift.start.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        issues.add(DataIssue(
          type: 'future_date',
          description: 'Shift date is in the future: ${shift.start}',
          severity: 'high',
          detectedDate: DateTime.now(),
        ));
      }
      
      // Check for very old dates (more than 2 years)
      if (shift.start.isBefore(DateTime.now().subtract(const Duration(days: 730)))) {
        issues.add(DataIssue(
          type: 'very_old_date',
          description: 'Shift date is very old: ${shift.start}',
          severity: 'low',
          detectedDate: DateTime.now(),
        ));
      }
    }
    
    return issues;
  }

  /// Check timestamp integrity
  static List<DataIssue> _checkTimestampIntegrity(List<ShiftRecord> shifts) {
    final issues = <DataIssue>[];
    
    final sortedShifts = List<ShiftRecord>.from(shifts)
      ..sort((a, b) => a.start.compareTo(b.start));
    
    for (int i = 1; i < sortedShifts.length; i++) {
      final current = sortedShifts[i];
      final previous = sortedShifts[i - 1];
      
      // Check for shifts less than 1 hour apart (unusual)
      if (current.start.difference(previous.start).inHours < 1) {
        issues.add(DataIssue(
          type: 'rapid_succession',
          description: 'Shifts very close together: ${previous.start} and ${current.start}',
          severity: 'medium',
          detectedDate: DateTime.now(),
        ));
      }
    }
    
    return issues;
  }

  /// Extract server performance data for analysis
  static List<double> _extractServerPerformanceData(String serverId, List<ShiftRecord> shifts) {
    return shifts
        .where((s) => s.counts.containsKey(serverId))
        .map((s) => (s.counts[serverId] ?? 0).toDouble())
        .toList();
  }

  /// Detect Z-score outliers
  static List<StatisticalOutlier> _detectZScoreOutliers(List<double> data, Server server) {
    final outliers = <StatisticalOutlier>[];
    
    if (data.length < _minimumDataPoints) return outliers;
    
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    final standardDeviation = math.sqrt(variance);
    
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final zScore = (value - mean) / standardDeviation;
      
      if (zScore.abs() > _outlierThreshold) {
        outliers.add(StatisticalOutlier(
          serverId: server.id,
          serverName: server.name,
          method: 'Z-Score',
          value: value,
          threshold: _outlierThreshold,
          score: zScore.abs(),
          index: i,
          detectedDate: DateTime.now(),
        ));
      }
    }
    
    return outliers;
  }

  /// Detect IQR outliers
  static List<StatisticalOutlier> _detectIQROutliers(List<double> data, Server server) {
    final outliers = <StatisticalOutlier>[];
    
    if (data.length < _minimumDataPoints) return outliers;
    
    final sortedData = List<double>.from(data)..sort();
    final q1Index = (sortedData.length * 0.25).floor();
    final q3Index = (sortedData.length * 0.75).floor();
    
    final q1 = sortedData[q1Index];
    final q3 = sortedData[q3Index];
    final iqr = q3 - q1;
    final lowerBound = q1 - (1.5 * iqr);
    final upperBound = q3 + (1.5 * iqr);
    
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      
      if (value < lowerBound || value > upperBound) {
        outliers.add(StatisticalOutlier(
          serverId: server.id,
          serverName: server.name,
          method: 'IQR',
          value: value,
          threshold: 1.5,
          score: value < lowerBound ? (lowerBound - value) / iqr : (value - upperBound) / iqr,
          index: i,
          detectedDate: DateTime.now(),
        ));
      }
    }
    
    return outliers;
  }

  /// Detect modified Z-score outliers (more robust)
  static List<StatisticalOutlier> _detectModifiedZScoreOutliers(List<double> data, Server server) {
    final outliers = <StatisticalOutlier>[];
    
    if (data.length < _minimumDataPoints) return outliers;
    
    final sortedData = List<double>.from(data)..sort();
    final median = sortedData[sortedData.length ~/ 2];
    
    // Calculate MAD (Median Absolute Deviation)
    final deviations = data.map((x) => (x - median).abs()).toList()..sort();
    final mad = deviations[deviations.length ~/ 2];
    
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final modifiedZScore = 0.6745 * (value - median) / mad;
      
      if (modifiedZScore.abs() > 3.5) { // Modified Z-score threshold
        outliers.add(StatisticalOutlier(
          serverId: server.id,
          serverName: server.name,
          method: 'Modified Z-Score',
          value: value,
          threshold: 3.5,
          score: modifiedZScore.abs(),
          index: i,
          detectedDate: DateTime.now(),
        ));
      }
    }
    
    return outliers;
  }

  /// Analyze weekly patterns for unusual behaviors
  static List<UnusualPattern> _analyzeWeeklyPatterns(String serverId, List<ShiftRecord> shifts) {
    final patterns = <UnusualPattern>[];
    
    // Group shifts by day of week
    final weeklyData = <int, List<int>>{};
    for (int day = 1; day <= 7; day++) {
      weeklyData[day] = [];
    }
    
    for (final shift in shifts) {
      final dayOfWeek = shift.start.weekday;
      final runs = shift.counts[serverId] ?? 0;
      weeklyData[dayOfWeek]!.add(runs);
    }
    
    // Analyze each day for consistency
    for (final entry in weeklyData.entries) {
      if (entry.value.length < 4) continue; // Need at least 4 data points
      
      final dayName = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][entry.key];
      final data = entry.value.map((x) => x.toDouble()).toList();
      final mean = data.reduce((a, b) => a + b) / data.length;
      final variance = data.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
      final cv = math.sqrt(variance) / mean; // Coefficient of variation
      
      if (cv > 0.8) { // High variability
        patterns.add(UnusualPattern(
          serverId: serverId,
          patternType: 'high_variability',
          description: 'High performance variability on $dayName (CV: ${cv.toStringAsFixed(2)})',
          severity: cv > 1.2 ? 'high' : 'medium',
          confidence: _calculatePatternConfidence(cv),
          detectedDate: DateTime.now(),
          affectedPeriod: 'Weekly pattern',
        ));
      }
    }
    
    return patterns;
  }

  /// Detect sudden performance changes
  static List<UnusualPattern> _detectPerformanceChanges(String serverId, List<ShiftRecord> shifts) {
    final patterns = <UnusualPattern>[];
    
    final dailyPerformance = _calculateDailyPerformance(serverId, shifts);
    final sortedDates = dailyPerformance.keys.toList()..sort();
    
    if (sortedDates.length < 10) return patterns;
    
    // Calculate rolling averages and detect sudden changes
    const windowSize = 5;
    for (int i = windowSize; i < sortedDates.length - windowSize; i++) {
      final beforeWindow = sortedDates.sublist(i - windowSize, i);
      final afterWindow = sortedDates.sublist(i + 1, i + 1 + windowSize);
      
      final beforeAvg = beforeWindow.map((d) => dailyPerformance[d]!).reduce((a, b) => a + b) / windowSize;
      final afterAvg = afterWindow.map((d) => dailyPerformance[d]!).reduce((a, b) => a + b) / windowSize;
      
      final changePercent = ((afterAvg - beforeAvg) / beforeAvg * 100).abs();
      
      if (changePercent > 50) { // 50% change threshold
        patterns.add(UnusualPattern(
          serverId: serverId,
          patternType: changePercent > 0 ? 'sudden_improvement' : 'sudden_decline',
          description: 'Sudden ${changePercent > 0 ? 'improvement' : 'decline'} of ${changePercent.toStringAsFixed(1)}% detected',
          severity: changePercent > 75 ? 'high' : 'medium',
          confidence: math.min(changePercent / 100, 1.0),
          detectedDate: DateTime.now(),
          affectedPeriod: '${sortedDates[i].toString().split(' ')[0]} onwards',
        ));
      }
    }
    
    return patterns;
  }

  /// Analyze shift patterns for unusual behaviors
  static List<UnusualPattern> _analyzeShiftPatterns(String serverId, List<ShiftRecord> shifts) {
    final patterns = <UnusualPattern>[];
    
    // Check for unusual shift timing patterns
    final shiftHours = shifts.map((s) => s.start.hour).toList();
    final hourCounts = <int, int>{};
    
    for (final hour in shiftHours) {
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    // Look for shifts at unusual hours
    for (final entry in hourCounts.entries) {
      if ((entry.key < 6 || entry.key > 23) && entry.value > 2) {
        patterns.add(UnusualPattern(
          serverId: serverId,
          patternType: 'unusual_shift_timing',
          description: 'Multiple shifts at unusual hour: ${entry.key}:00 (${entry.value} shifts)',
          severity: 'medium',
          confidence: 0.8,
          detectedDate: DateTime.now(),
          affectedPeriod: 'Historical',
        ));
      }
    }
    
    return patterns;
  }

  /// Calculate severity based on standard deviations
  static String _calculateSeverity(double standardDeviations) {
    if (standardDeviations > 4.0) return 'critical';
    if (standardDeviations > 3.0) return 'high';
    if (standardDeviations > 2.5) return 'medium';
    return 'low';
  }

  /// Calculate confidence based on standard deviations
  static double _calculateConfidence(double standardDeviations) {
    return math.min(standardDeviations / 5.0, 1.0);
  }

  /// Calculate pattern confidence
  static double _calculatePatternConfidence(double coefficient) {
    return math.min(coefficient / 2.0, 1.0);
  }

  /// Generate anomaly description
  static String _generateAnomalyDescription(DataOutlier outlier, String serverName) {
    final direction = outlier.value > outlier.average ? 'spike' : 'drop';
    return 'Performance $direction detected for $serverName: ${outlier.value.toStringAsFixed(1)} runs (${outlier.standardDeviations.toStringAsFixed(1)}σ from average)';
  }

  /// Identify possible causes for anomalies
  static List<String> _identifyPossibleCauses(DataOutlier outlier, List<ShiftRecord> shifts) {
    final causes = <String>[];
    
    if (outlier.value > outlier.average) {
      causes.addAll([
        'Exceptional performance day',
        'Special event or promotion',
        'Extra motivation or incentive',
        'Optimal working conditions',
      ]);
    } else {
      causes.addAll([
        'Training or onboarding period',
        'Personal factors affecting performance',
        'Technical issues or equipment problems',
        'Understaffing or high stress day',
        'Illness or fatigue',
      ]);
    }
    
    return causes;
  }

  /// Generate validation recommendations
  static List<ValidationRecommendation> _generateValidationRecommendations(ValidationReport report) {
    final recommendations = <ValidationRecommendation>[];
    
    // High severity anomalies
    final criticalAnomalies = report.anomalies.where((a) => a.severity == 'critical').length;
    if (criticalAnomalies > 0) {
      recommendations.add(ValidationRecommendation(
        priority: 'high',
        category: 'data_quality',
        title: 'Critical Anomalies Detected',
        description: '$criticalAnomalies critical performance anomalies require immediate attention',
        actionItems: [
          'Review data entry processes for affected dates',
          'Verify server performance calculations',
          'Investigate external factors that may have caused anomalies',
          'Consider excluding anomalous data from reports',
        ],
        estimatedImpact: 'high',
      ));
    }
    
    // Data integrity issues
    if (report.integrityResults.duplicateEntries.isNotEmpty) {
      recommendations.add(ValidationRecommendation(
        priority: 'high',
        category: 'data_integrity',
        title: 'Duplicate Entries Found',
        description: '${report.integrityResults.duplicateEntries.length} duplicate entries detected',
        actionItems: [
          'Remove duplicate entries from database',
          'Implement unique constraints to prevent future duplicates',
          'Review data entry procedures',
        ],
        estimatedImpact: 'medium',
      ));
    }
    
    // Consistency issues
    if (report.consistencyResults.totalDiscrepancies.isNotEmpty) {
      recommendations.add(ValidationRecommendation(
        priority: 'medium',
        category: 'consistency',
        title: 'Data Consistency Issues',
        description: '${report.consistencyResults.totalDiscrepancies.length} data discrepancies found',
        actionItems: [
          'Reconcile total run counts with individual shift data',
          'Update server profiles with correct totals',
          'Implement automated consistency checks',
        ],
        estimatedImpact: 'medium',
      ));
    }
    
    return recommendations;
  }

  /// Generate unique validation ID
  static String _generateValidationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'VAL_${timestamp.toRadixString(36).toUpperCase()}';
  }
}

/// Data classes for validation results

class ValidationReport {
  final String reportId;
  final DateTime validationDate;
  final int totalShiftsAnalyzed;
  final int totalServersAnalyzed;
  bool validationCompleted;
  Duration? processingTime;
  String? errorMessage;
  
  late DataIntegrityResults integrityResults;
  late List<PerformanceAnomaly> anomalies;
  late List<StatisticalOutlier> outliers;
  late ConsistencyResults consistencyResults;
  late List<UnusualPattern> unusualPatterns;
  late List<ValidationRecommendation> recommendations;

  ValidationReport({
    required this.reportId,
    required this.validationDate,
    required this.totalShiftsAnalyzed,
    required this.totalServersAnalyzed,
    required this.validationCompleted,
    this.processingTime,
    this.errorMessage,
  });
}

class DataIntegrityResults {
  List<DataIssue> missingDataIssues = [];
  List<DataIssue> duplicateEntries = [];
  List<DataIssue> inconsistencyIssues = [];
  List<DataIssue> impossibleValues = [];
  List<DataIssue> timestampIssues = [];
}

class PerformanceAnomaly {
  final String serverId;
  final String serverName;
  final AnomalyType anomalyType;
  final DateTime detectedDate;
  final DateTime affectedDate;
  final double value;
  final ExpectedRange expectedRange;
  final String severity;
  final double confidence;
  final String description;
  final List<String> possibleCauses;

  PerformanceAnomaly({
    required this.serverId,
    required this.serverName,
    required this.anomalyType,
    required this.detectedDate,
    required this.affectedDate,
    required this.value,
    required this.expectedRange,
    required this.severity,
    required this.confidence,
    required this.description,
    required this.possibleCauses,
  });
}

enum AnomalyType {
  performanceSpike,
  performanceDrop,
  efficiencyDrop,
  consistencyIssue,
  dataQualityIssue,
}

class ExpectedRange {
  final double minimum;
  final double maximum;
  final double average;

  ExpectedRange({
    required this.minimum,
    required this.maximum,
    required this.average,
  });
}

class StatisticalOutlier {
  final String serverId;
  final String serverName;
  final String method;
  final double value;
  final double threshold;
  final double score;
  final int index;
  final DateTime detectedDate;

  StatisticalOutlier({
    required this.serverId,
    required this.serverName,
    required this.method,
    required this.value,
    required this.threshold,
    required this.score,
    required this.index,
    required this.detectedDate,
  });
}

class ConsistencyResults {
  List<DataDiscrepancy> totalDiscrepancies = [];
  List<DataDiscrepancy> metricDiscrepancies = [];
}

class DataDiscrepancy {
  final String? serverId;
  final String? serverName;
  final String metric;
  final double expected;
  final double actual;
  final double discrepancy;
  final String severity;

  DataDiscrepancy({
    this.serverId,
    this.serverName,
    required this.metric,
    required this.expected,
    required this.actual,
    required this.discrepancy,
    required this.severity,
  });
}

class UnusualPattern {
  final String serverId;
  final String patternType;
  final String description;
  final String severity;
  final double confidence;
  final DateTime detectedDate;
  final String affectedPeriod;

  UnusualPattern({
    required this.serverId,
    required this.patternType,
    required this.description,
    required this.severity,
    required this.confidence,
    required this.detectedDate,
    required this.affectedPeriod,
  });
}

class DataIssue {
  final String type;
  final String? serverId;
  final String? serverName;
  final String description;
  final String severity;
  final DateTime detectedDate;

  DataIssue({
    required this.type,
    this.serverId,
    this.serverName,
    required this.description,
    required this.severity,
    required this.detectedDate,
  });
}

class DataOutlier {
  final int index;
  final double value;
  final double average;
  final double standardDeviations;
  final double lowerBound;
  final double upperBound;

  DataOutlier({
    required this.index,
    required this.value,
    required this.average,
    required this.standardDeviations,
    required this.lowerBound,
    required this.upperBound,
  });
}

class ValidationRecommendation {
  final String priority;
  final String category;
  final String title;
  final String description;
  final List<String> actionItems;
  final String estimatedImpact;

  ValidationRecommendation({
    required this.priority,
    required this.category,
    required this.title,
    required this.description,
    required this.actionItems,
    required this.estimatedImpact,
  });
}
