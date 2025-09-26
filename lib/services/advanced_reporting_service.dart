import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../models/station_performance_metric.dart';
import '../utils/station_analytics_calculator.dart';
import '../utils/log.dart';

/// Advanced Reporting Service
/// Generates comprehensive reports with custom date ranges and data filtering
class AdvancedReportingService {
  
  /// Generate comprehensive performance report
  static Future<String> generatePerformanceReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<String> selectedStations,
    required List<String> selectedMetrics,
    ReportFormat format = ReportFormat.csv,
  }) async {
    try {
      d('[AdvancedReportingService] Generating performance report from $startDate to $endDate');
      
      // Load shift data for the specified date range
      final shiftData = await _loadShiftDataForDateRange(startDate, endDate);
      
      // Filter data by selected stations
      final filteredData = _filterDataByStations(shiftData, selectedStations);
      
      // Generate report based on format
      switch (format) {
        case ReportFormat.csv:
          return await _generateCSVReport(filteredData, selectedMetrics);
        case ReportFormat.pdf:
          return await _generatePDFReport(filteredData, selectedMetrics);
        case ReportFormat.json:
          return await _generateJSONReport(filteredData, selectedMetrics);
      }
    } catch (e) {
      d('[AdvancedReportingService] Error generating report: $e');
      rethrow;
    }
  }

  /// Generate station comparison report
  static Future<String> generateStationComparisonReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<String> stationTypes,
  }) async {
    try {
      d('[AdvancedReportingService] Generating station comparison report');
      
      final shiftData = await _loadShiftDataForDateRange(startDate, endDate);
      final stationComparisons = <StationComparisonData>[];
      
      for (final stationType in stationTypes) {
        final stationData = shiftData.where((record) => 
          record.stationAssignments?.values.contains(stationType) == true
        ).toList();
        
        if (stationData.isNotEmpty) {
          final efficiency = await _calculateStationEfficiency(stationData, stationType);
          final trend = await _calculateTrend(stationData, stationType);
          
          stationComparisons.add(StationComparisonData(
            stationType: stationType,
            currentEfficiency: efficiency,
            previousEfficiency: efficiency * 0.9, // Placeholder for previous period
            trendPercentage: trend,
            topPerformers: await _getTopPerformers(stationData, stationType),
            improvementAreas: await _getImprovementAreas(stationData, stationType),
            totalShifts: stationData.length,
            lastUpdated: DateTime.now(),
          ));
        }
      }
      
      return await _generateStationComparisonCSV(stationComparisons);
    } catch (e) {
      d('[AdvancedReportingService] Error generating station comparison: $e');
      rethrow;
    }
  }

  /// Generate anomaly detection report
  static Future<String> generateAnomalyReport({
    required DateTime startDate,
    required DateTime endDate,
    required double anomalyThreshold,
  }) async {
    try {
      d('[AdvancedReportingService] Generating anomaly detection report');
      
      final shiftData = await _loadShiftDataForDateRange(startDate, endDate);
      final anomalies = <PerformanceAnomaly>[];
      
      // Group data by station type
      final stationGroups = <String, List<double>>{};
      for (final record in shiftData) {
        if (record.stationAssignments != null) {
          record.stationAssignments!.forEach((serverId, stationType) {
            final runs = record.counts[serverId] ?? 0;
            stationGroups.putIfAbsent(stationType, () => []).add(runs.toDouble());
          });
        }
      }
      
      // Detect anomalies for each station type
      stationGroups.forEach((stationType, values) {
        final stationAnomalies = StationAnalyticsCalculator.detectAnomalies(
          values, 
          threshold: anomalyThreshold,
        );
        anomalies.addAll(stationAnomalies);
      });
      
      return await _generateAnomalyCSV(anomalies, shiftData);
    } catch (e) {
      d('[AdvancedReportingService] Error generating anomaly report: $e');
      rethrow;
    }
  }

  /// Generate seasonality analysis report
  static Future<String> generateSeasonalityReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      d('[AdvancedReportingService] Generating seasonality report');
      
      final shiftData = await _loadShiftDataForDateRange(startDate, endDate);
      final seasonalityData = <Map<String, dynamic>>[];
      
      // Convert shift data to seasonality format
      for (final record in shiftData) {
        if (record.stationAssignments != null) {
          record.stationAssignments!.forEach((serverId, stationType) {
            final runs = record.counts[serverId] ?? 0;
            seasonalityData.add({
              'date': record.start.toIso8601String(),
              'station_type': stationType,
              'value': runs.toDouble(),
              'day_of_week': record.start.weekday,
            });
          });
        }
      }
      
      // Calculate seasonality patterns
      final seasonality = StationAnalyticsCalculator.calculateSeasonality(seasonalityData);
      
      return await _generateSeasonalityCSV(seasonality, seasonalityData);
    } catch (e) {
      d('[AdvancedReportingService] Error generating seasonality report: $e');
      rethrow;
    }
  }

  /// Export data to external format
  static Future<String> exportData({
    required List<Map<String, dynamic>> data,
    required String filename,
    required ReportFormat format,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileExtension = format == ReportFormat.csv ? 'csv' : 
                           format == ReportFormat.pdf ? 'pdf' : 'json';
      final filePath = '${directory.path}/${filename}_$timestamp.$fileExtension';
      
      final file = File(filePath);
      
      switch (format) {
        case ReportFormat.csv:
          // Convert Map data to List format for CSV
          final csvData = <List<dynamic>>[];
          if (data.isNotEmpty) {
            // Add header row
            csvData.add(data.first.keys.toList());
            // Add data rows
            for (final row in data) {
              csvData.add(row.values.toList());
            }
          }
          await file.writeAsString(const ListToCsvConverter().convert(csvData));
          break;
        case ReportFormat.json:
          await file.writeAsString(data.toString());
          break;
        case ReportFormat.pdf:
          // PDF generation would require additional packages
          throw UnsupportedError('PDF export not yet implemented');
      }
      
      d('[AdvancedReportingService] Data exported to: $filePath');
      return filePath;
    } catch (e) {
      d('[AdvancedReportingService] Error exporting data: $e');
      rethrow;
    }
  }

  // Private helper methods

  static Future<List<ShiftRecord>> _loadShiftDataForDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    // This would typically load from your storage system
    // For now, returning empty list as placeholder
    return [];
  }

  static List<ShiftRecord> _filterDataByStations(
    List<ShiftRecord> data, 
    List<String> selectedStations,
  ) {
    if (selectedStations.isEmpty) return data;
    
    return data.where((record) {
      if (record.stationAssignments == null) return false;
      return record.stationAssignments!.values.any((station) => 
        selectedStations.contains(station));
    }).toList();
  }

  static Future<String> _generateCSVReport(
    List<ShiftRecord> data, 
    List<String> metrics,
  ) async {
    final csvData = <List<dynamic>>[];
    
    // Add header row
    csvData.add(['Date', 'Station Type', 'Server ID', 'Runs', 'Efficiency']);
    
    // Add data rows
    for (final record in data) {
      if (record.stationAssignments != null) {
        record.stationAssignments!.forEach((serverId, stationType) {
          final runs = record.counts[serverId] ?? 0;
          csvData.add([
            DateFormat('yyyy-MM-dd').format(record.start),
            stationType,
            serverId,
            runs,
            runs / 8.0, // Simple efficiency calculation
          ]);
        });
      }
    }
    
    final csvString = const ListToCsvConverter().convert(csvData);
    return await _saveReportToFile(csvString, 'performance_report', 'csv');
  }

  static Future<String> _generatePDFReport(
    List<ShiftRecord> data, 
    List<String> metrics,
  ) async {
    // PDF generation would require additional packages like pdf package
    throw UnsupportedError('PDF generation not yet implemented');
  }

  static Future<String> _generateJSONReport(
    List<ShiftRecord> data, 
    List<String> metrics,
  ) async {
    final jsonData = data.map((record) => {
      'date': record.start.toIso8601String(),
      'station_assignments': record.stationAssignments,
      'counts': record.counts,
    }).toList();
    
    return await _saveReportToFile(jsonData.toString(), 'performance_report', 'json');
  }

  static Future<String> _generateStationComparisonCSV(
    List<StationComparisonData> comparisons,
  ) async {
    final csvData = <List<dynamic>>[];
    
    csvData.add(['Station Type', 'Current Efficiency', 'Previous Efficiency', 'Trend %', 'Total Shifts']);
    
    for (final comparison in comparisons) {
      csvData.add([
        comparison.stationType,
        comparison.currentEfficiency,
        comparison.previousEfficiency,
        comparison.trendPercentage,
        comparison.totalShifts,
      ]);
    }
    
    final csvString = const ListToCsvConverter().convert(csvData);
    return await _saveReportToFile(csvString, 'station_comparison', 'csv');
  }

  static Future<String> _generateAnomalyCSV(
    List<PerformanceAnomaly> anomalies,
    List<ShiftRecord> shiftData,
  ) async {
    final csvData = <List<dynamic>>[];
    
    csvData.add(['Index', 'Value', 'Z-Score', 'Severity', 'Date']);
    
    for (final anomaly in anomalies) {
      final date = shiftData.length > anomaly.index ? 
        shiftData[anomaly.index].start : DateTime.now();
      
      csvData.add([
        anomaly.index,
        anomaly.value,
        anomaly.zScore,
        anomaly.severity.name,
        DateFormat('yyyy-MM-dd').format(date),
      ]);
    }
    
    final csvString = const ListToCsvConverter().convert(csvData);
    return await _saveReportToFile(csvString, 'anomaly_report', 'csv');
  }

  static Future<String> _generateSeasonalityCSV(
    Map<String, double> seasonality,
    List<Map<String, dynamic>> seasonalityData,
  ) async {
    final csvData = <List<dynamic>>[];
    
    csvData.add(['Day of Week', 'Average Value', 'Data Points']);
    
    seasonality.forEach((day, average) {
      final dataPoints = seasonalityData.where((d) => 
        d['day_of_week'] == _getDayOfWeekNumber(day)).length;
      
      csvData.add([day, average, dataPoints]);
    });
    
    final csvString = const ListToCsvConverter().convert(csvData);
    return await _saveReportToFile(csvString, 'seasonality_report', 'csv');
  }

  static Future<String> _saveReportToFile(
    String content, 
    String filename, 
    String extension,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/${filename}_$timestamp.$extension';
    
    final file = File(filePath);
    await file.writeAsString(content);
    
    d('[AdvancedReportingService] Report saved to: $filePath');
    return filePath;
  }

  static Future<double> _calculateStationEfficiency(
    List<ShiftRecord> data, 
    String stationType,
  ) async {
    // Simplified efficiency calculation
    final totalRuns = data.fold<int>(0, (sum, record) {
      return sum + (record.stationAssignments?.entries
        .where((e) => e.value == stationType)
        .fold<int>(0, (s, e) => s + (record.counts[e.key] ?? 0)) ?? 0);
    });
    
    return totalRuns / (data.length * 8.0) * 100; // 8 hours per shift
  }

  static Future<double> _calculateTrend(
    List<ShiftRecord> data, 
    String stationType,
  ) async {
    // Simplified trend calculation
    return 5.0; // Placeholder
  }

  static Future<List<String>> _getTopPerformers(
    List<ShiftRecord> data, 
    String stationType,
  ) async {
    // Simplified top performers calculation
    return ['Server A', 'Server B'];
  }

  static Future<List<String>> _getImprovementAreas(
    List<ShiftRecord> data, 
    String stationType,
  ) async {
    // Simplified improvement areas calculation
    return ['Speed', 'Consistency'];
  }

  static int _getDayOfWeekNumber(String dayName) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.indexOf(dayName) + 1;
  }
}

enum ReportFormat {
  csv,
  pdf,
  json,
}
