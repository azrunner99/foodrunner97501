/// Multi-Variable Correlation Analysis Engine
/// Advanced analytics for discovering relationships between performance variables

import 'dart:math' as math;
import 'package:collection/collection.dart';

import '../models/comprehensive_shift_data.dart';
import '../models/nps_feedback.dart';
import '../providers/nps_provider.dart';
import 'comprehensive_shift_capture_service.dart';

/// Results of correlation analysis
class CorrelationAnalysisResult {
  final String analysisType;
  final DateTime analysisDate;
  final List<VariableCorrelation> significantCorrelations;
  final List<PerformanceInsight> insights;
  final Map<String, ServerCorrelationProfile> serverProfiles;
  final List<PredictiveModel> predictiveModels;

  CorrelationAnalysisResult({
    required this.analysisType,
    required this.analysisDate,
    required this.significantCorrelations,
    required this.insights,
    required this.serverProfiles,
    required this.predictiveModels,
  });
}

/// Individual variable correlation with statistical significance
class VariableCorrelation {
  final String variable1;
  final String variable2;
  final double correlation;
  final double pValue;
  final double rSquared;
  final int sampleSize;
  final String interpretation;
  final List<DataPoint> dataPoints;

  VariableCorrelation({
    required this.variable1,
    required this.variable2,
    required this.correlation,
    required this.pValue,
    required this.rSquared,
    required this.sampleSize,
    required this.interpretation,
    required this.dataPoints,
  });

  bool get isSignificant => pValue < 0.05;
  bool get isStrongCorrelation => correlation.abs() > 0.7;
  bool get isModerateCorrelation => correlation.abs() > 0.5;
}

/// Data point for correlation scatter plots
class DataPoint {
  final double x;
  final double y;
  final String? label;
  final Map<String, dynamic> metadata;

  DataPoint({
    required this.x,
    required this.y,
    this.label,
    required this.metadata,
  });
}

/// Performance insight derived from correlation analysis
class PerformanceInsight {
  final String title;
  final String description;
  final String category; // 'correlation', 'pattern', 'anomaly', 'optimization'
  final double confidence;
  final String recommendation;
  final List<String> supportingData;

  PerformanceInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.confidence,
    required this.recommendation,
    required this.supportingData,
  });
}

/// Server-specific correlation profile
class ServerCorrelationProfile {
  final String serverId;
  final String serverName;
  final Map<String, double> variableAverages;
  final Map<String, double> correlationStrengths;
  final List<String> strongestCorrelations;
  final double overallPerformanceScore;
  final List<String> improvementAreas;

  ServerCorrelationProfile({
    required this.serverId,
    required this.serverName,
    required this.variableAverages,
    required this.correlationStrengths,
    required this.strongestCorrelations,
    required this.overallPerformanceScore,
    required this.improvementAreas,
  });
}

/// Predictive model based on correlations
class PredictiveModel {
  final String modelName;
  final String targetVariable;
  final List<String> predictorVariables;
  final Map<String, double> coefficients;
  final double accuracy;
  final String formula;

  PredictiveModel({
    required this.modelName,
    required this.targetVariable,
    required this.predictorVariables,
    required this.coefficients,
    required this.accuracy,
    required this.formula,
  });

  double predict(Map<String, double> inputs) {
    double result = coefficients['intercept'] ?? 0;
    for (final variable in predictorVariables) {
      result += (coefficients[variable] ?? 0) * (inputs[variable] ?? 0);
    }
    return result;
  }
}

class MultiVariableCorrelationEngine {
  
  /// Run comprehensive correlation analysis
  static Future<CorrelationAnalysisResult> runFullCorrelationAnalysis({
    DateTime? startDate,
    DateTime? endDate,
    int? minimumShifts = 5,
  }) async {
    
    // Load comprehensive shift data
    final shiftData = await ComprehensiveShiftCaptureService.getStoredShiftData();
    
    // Filter by date range if specified
    List<ComprehensiveShiftData> filteredData = shiftData;
    if (startDate != null || endDate != null) {
      filteredData = shiftData.where((shift) {
        if (startDate != null && shift.shiftDate.isBefore(startDate)) return false;
        if (endDate != null && shift.shiftDate.isAfter(endDate)) return false;
        return true;
      }).toList();
    }
    
    if (filteredData.length < (minimumShifts ?? 5)) {
      return CorrelationAnalysisResult(
        analysisType: 'insufficient_data',
        analysisDate: DateTime.now(),
        significantCorrelations: [],
        insights: [
          PerformanceInsight(
            title: 'Insufficient Data',
            description: 'Need at least $minimumShifts shifts for meaningful correlation analysis',
            category: 'pattern',
            confidence: 1.0,
            recommendation: 'Continue collecting data from completed shifts',
            supportingData: ['Current shifts: ${filteredData.length}'],
          ),
        ],
        serverProfiles: {},
        predictiveModels: [],
      );
    }
    
    // Extract all server performances across shifts
    final allServerPerformances = <ServerShiftPerformance>[];
    for (final shift in filteredData) {
      allServerPerformances.addAll(shift.serverPerformances);
    }
    
    // Run correlation analyses
    final correlations = await _analyzeVariableCorrelations(allServerPerformances);
    final insights = _generatePerformanceInsights(correlations, allServerPerformances);
    final serverProfiles = _buildServerCorrelationProfiles(allServerPerformances);
    final predictiveModels = _buildPredictiveModels(correlations, allServerPerformances);
    
    return CorrelationAnalysisResult(
      analysisType: 'full_analysis',
      analysisDate: DateTime.now(),
      significantCorrelations: correlations.where((c) => c.isSignificant).toList(),
      insights: insights,
      serverProfiles: serverProfiles,
      predictiveModels: predictiveModels,
    );
  }

  /// Analyze correlations between all performance variables
  static Future<List<VariableCorrelation>> _analyzeVariableCorrelations(
    List<ServerShiftPerformance> performances,
  ) async {
    final correlations = <VariableCorrelation>[];
    
    if (performances.length < 3) return correlations;
    
    // Define variable extractors
    final variables = {
      'Total Runs': (ServerShiftPerformance p) => p.totalRuns.toDouble(),
      'Runs per Hour': (ServerShiftPerformance p) => p.runsPerHour,
      'Hours Worked': (ServerShiftPerformance p) => p.hoursWorked,
      'Tips Amount': (ServerShiftPerformance p) => p.tipAmount ?? 0.0,
      'Sales Generated': (ServerShiftPerformance p) => p.salesGenerated ?? 0.0,
      'Tables Served': (ServerShiftPerformance p) => (p.tablesServed ?? 0).toDouble(),
      'Average Ticket': (ServerShiftPerformance p) => p.averageTicketSize ?? 0.0,
      'Tips per Hour': (ServerShiftPerformance p) => p.tipsPerHour,
      'Sales per Hour': (ServerShiftPerformance p) => p.salesPerHour,
      'Sales per Run': (ServerShiftPerformance p) => p.salesPerRun,
      'Efficiency Score': (ServerShiftPerformance p) => p.efficiencyScore,
    };
    
    // Calculate correlations between all variable pairs
    final variableNames = variables.keys.toList();
    for (int i = 0; i < variableNames.length; i++) {
      for (int j = i + 1; j < variableNames.length; j++) {
        final var1Name = variableNames[i];
        final var2Name = variableNames[j];
        final var1Extractor = variables[var1Name]!;
        final var2Extractor = variables[var2Name]!;
        
        final x = performances.map(var1Extractor).toList();
        final y = performances.map(var2Extractor).toList();
        
        final correlation = _calculatePearsonCorrelation(x, y);
        if (correlation != null) {
          correlations.add(correlation);
        }
      }
    }
    
    // Add station-specific correlations
    final stationCorrelations = await _analyzeStationSpecificCorrelations(performances);
    correlations.addAll(stationCorrelations);
    
    // Add NPS correlations
    final npsCorrelations = await _analyzeNPSCorrelations(performances);
    correlations.addAll(npsCorrelations);
    
    return correlations;
  }

  /// Calculate Pearson correlation with statistical significance
  static VariableCorrelation? _calculatePearsonCorrelation(
    List<double> x,
    List<double> y, {
    String? var1Name,
    String? var2Name,
  }) {
    if (x.length != y.length || x.length < 3) return null;
    
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0;
    double sumXSquared = 0;
    double sumYSquared = 0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = x[i] - meanX;
      final yDiff = y[i] - meanY;
      numerator += xDiff * yDiff;
      sumXSquared += xDiff * xDiff;
      sumYSquared += yDiff * yDiff;
    }
    
    final denominator = math.sqrt(sumXSquared * sumYSquared);
    if (denominator == 0) return null;
    
    final correlation = numerator / denominator;
    final rSquared = correlation * correlation;
    
    // Calculate t-statistic and p-value
    final tStat = correlation * math.sqrt((n - 2) / (1 - rSquared));
    final pValue = _calculatePValue(tStat.abs(), n - 2);
    
    // Generate interpretation
    String interpretation;
    if (pValue > 0.05) {
      interpretation = 'No significant relationship detected';
    } else {
      final strength = correlation.abs() > 0.7 ? 'Strong' :
                     correlation.abs() > 0.5 ? 'Moderate' : 'Weak';
      final direction = correlation > 0 ? 'positive' : 'negative';
      interpretation = '$strength $direction correlation (r=${correlation.toStringAsFixed(3)}, p=${pValue.toStringAsFixed(3)})';
    }
    
    // Create data points for visualization
    final dataPoints = <DataPoint>[];
    for (int i = 0; i < n; i++) {
      dataPoints.add(DataPoint(
        x: x[i],
        y: y[i],
        label: 'Point ${i + 1}',
        metadata: {'index': i},
      ));
    }
    
    return VariableCorrelation(
      variable1: var1Name ?? 'Variable 1',
      variable2: var2Name ?? 'Variable 2',
      correlation: correlation,
      pValue: pValue,
      rSquared: rSquared,
      sampleSize: n,
      interpretation: interpretation,
      dataPoints: dataPoints,
    );
  }

  /// Analyze station-specific correlations
  static Future<List<VariableCorrelation>> _analyzeStationSpecificCorrelations(
    List<ServerShiftPerformance> performances,
  ) async {
    final correlations = <VariableCorrelation>[];
    
    // Group by station
    final stationGroups = groupBy(
      performances.where((p) => p.assignedStation != null),
      (ServerShiftPerformance p) => p.assignedStation!,
    );
    
    for (final entry in stationGroups.entries) {
      final stationType = entry.key;
      final stationPerformances = entry.value;
      
      if (stationPerformances.length < 3) continue;
      
      // Analyze runs vs sales for this station
      final runs = stationPerformances.map((p) => p.totalRuns.toDouble()).toList();
      final sales = stationPerformances.map((p) => p.salesGenerated ?? 0.0).toList();
      
      final correlation = _calculatePearsonCorrelation(
        runs, 
        sales,
        var1Name: 'Runs ($stationType)',
        var2Name: 'Sales ($stationType)',
      );
      
      if (correlation != null) {
        correlations.add(correlation);
      }
    }
    
    return correlations;
  }

  /// Analyze NPS correlations with performance metrics
  static Future<List<VariableCorrelation>> _analyzeNPSCorrelations(
    List<ServerShiftPerformance> performances,
  ) async {
    final correlations = <VariableCorrelation>[];
    
    try {
      final npsProvider = NPSProvider();
      await npsProvider.initialize();
      
      // Get NPS scores for servers
      final serverNPSScores = <String, double>{};
      final serverPerformanceMetrics = <String, Map<String, double>>{};
      
      for (final perf in performances) {
        final feedback = await npsProvider.getServerFeedback(perf.serverId);
        if (feedback.isNotEmpty) {
          final avgImpact = feedback.map((f) => f.feedbackType.npsImpact).reduce((a, b) => a + b) / feedback.length;
          serverNPSScores[perf.serverId] = avgImpact;
          
          serverPerformanceMetrics.putIfAbsent(perf.serverId, () => {});
          serverPerformanceMetrics[perf.serverId]!.addAll({
            'runs': perf.totalRuns.toDouble(),
            'sales': perf.salesGenerated ?? 0.0,
            'tips': perf.tipAmount ?? 0.0,
            'efficiency': perf.efficiencyScore,
          });
        }
      }
      
      if (serverNPSScores.length > 2) {
        final npsValues = serverNPSScores.values.toList();
        
        // Correlate NPS with each performance metric
        final metrics = ['runs', 'sales', 'tips', 'efficiency'];
        for (final metric in metrics) {
          final metricValues = serverNPSScores.keys
              .map((serverId) => serverPerformanceMetrics[serverId]?[metric] ?? 0.0)
              .toList();
          
          final correlation = _calculatePearsonCorrelation(
            npsValues,
            metricValues,
            var1Name: 'NPS Impact Score',
            var2Name: metric.toUpperCase(),
          );
          
          if (correlation != null) {
            correlations.add(correlation);
          }
        }
      }
    } catch (e) {
      print('[CORRELATION_ENGINE] Error analyzing NPS correlations: $e');
    }
    
    return correlations;
  }

  /// Generate performance insights from correlations
  static List<PerformanceInsight> _generatePerformanceInsights(
    List<VariableCorrelation> correlations,
    List<ServerShiftPerformance> performances,
  ) {
    final insights = <PerformanceInsight>[];
    
    // Find strongest correlations
    final strongCorrelations = correlations
        .where((c) => c.isSignificant && c.isStrongCorrelation)
        .toList()
        ..sort((a, b) => b.correlation.abs().compareTo(a.correlation.abs()));
    
    if (strongCorrelations.isNotEmpty) {
      final strongest = strongCorrelations.first;
      insights.add(PerformanceInsight(
        title: 'Strongest Performance Correlation',
        description: 'Strong relationship found between ${strongest.variable1} and ${strongest.variable2}',
        category: 'correlation',
        confidence: 1 - strongest.pValue,
        recommendation: strongest.correlation > 0 
            ? 'Focus on improving ${strongest.variable1} to increase ${strongest.variable2}'
            : 'Monitor ${strongest.variable1} as it may negatively impact ${strongest.variable2}',
        supportingData: [
          'Correlation: ${strongest.correlation.toStringAsFixed(3)}',
          'R²: ${strongest.rSquared.toStringAsFixed(3)}',
          'Sample size: ${strongest.sampleSize}',
        ],
      ));
    }
    
    // Analyze efficiency patterns
    final efficiencyScores = performances.map((p) => p.efficiencyScore).toList();
    if (efficiencyScores.isNotEmpty) {
      final avgEfficiency = efficiencyScores.reduce((a, b) => a + b) / efficiencyScores.length;
      final topPerformers = performances.where((p) => p.efficiencyScore > avgEfficiency + 10).length;
      
      if (topPerformers > 0) {
        insights.add(PerformanceInsight(
          title: 'High Performance Pattern',
          description: '$topPerformers servers show consistently high efficiency scores',
          category: 'pattern',
          confidence: 0.8,
          recommendation: 'Study the practices of top performers and share best practices',
          supportingData: [
            'Average efficiency: ${avgEfficiency.toStringAsFixed(1)}%',
            'Top performers: $topPerformers servers',
          ],
        ));
      }
    }
    
    // Sales optimization insights
    final salesCorrelations = correlations
        .where((c) => c.variable2.contains('Sales') && c.isSignificant)
        .toList();
    
    if (salesCorrelations.isNotEmpty) {
      final bestSalesCorrelation = salesCorrelations
          .reduce((a, b) => a.correlation.abs() > b.correlation.abs() ? a : b);
      
      insights.add(PerformanceInsight(
        title: 'Sales Optimization Opportunity',
        description: '${bestSalesCorrelation.variable1} shows strong correlation with sales performance',
        category: 'optimization',
        confidence: 1 - bestSalesCorrelation.pValue,
        recommendation: 'Optimize ${bestSalesCorrelation.variable1} to maximize sales impact',
        supportingData: [
          'Correlation with sales: ${bestSalesCorrelation.correlation.toStringAsFixed(3)}',
          'Potential impact: ${(bestSalesCorrelation.rSquared * 100).toStringAsFixed(1)}%',
        ],
      ));
    }
    
    return insights;
  }

  /// Build server-specific correlation profiles
  static Map<String, ServerCorrelationProfile> _buildServerCorrelationProfiles(
    List<ServerShiftPerformance> performances,
  ) {
    final profiles = <String, ServerCorrelationProfile>{};
    
    // Group performances by server
    final serverGroups = groupBy(performances, (ServerShiftPerformance p) => p.serverId);
    
    for (final entry in serverGroups.entries) {
      final serverId = entry.key;
      final serverPerformances = entry.value;
      
      if (serverPerformances.isEmpty) continue;
      
      final serverName = serverPerformances.first.serverName;
      
      // Calculate variable averages
      final variableAverages = {
        'runs': serverPerformances.map((p) => p.totalRuns.toDouble()).reduce((a, b) => a + b) / serverPerformances.length,
        'runsPerHour': serverPerformances.map((p) => p.runsPerHour).reduce((a, b) => a + b) / serverPerformances.length,
        'sales': serverPerformances.map((p) => p.salesGenerated ?? 0.0).reduce((a, b) => a + b) / serverPerformances.length,
        'tips': serverPerformances.map((p) => p.tipAmount ?? 0.0).reduce((a, b) => a + b) / serverPerformances.length,
        'efficiency': serverPerformances.map((p) => p.efficiencyScore).reduce((a, b) => a + b) / serverPerformances.length,
      };
      
      // Calculate overall performance score
      final overallScore = (
        variableAverages['efficiency']! * 0.4 +
        (variableAverages['runsPerHour']! / 10 * 100) * 0.3 +
        (variableAverages['sales']! / 200 * 100) * 0.3
      ).clamp(0, 100);
      
      // Identify improvement areas
      final improvementAreas = <String>[];
      if (variableAverages['runsPerHour']! < 8) improvementAreas.add('Run efficiency');
      if (variableAverages['sales']! < 150) improvementAreas.add('Sales generation');
      if (variableAverages['tips']! < 20) improvementAreas.add('Tip performance');
      if (variableAverages['efficiency']! < 70) improvementAreas.add('Overall efficiency');
      
      profiles[serverId] = ServerCorrelationProfile(
        serverId: serverId,
        serverName: serverName,
        variableAverages: variableAverages,
        correlationStrengths: {}, // Would need more complex analysis
        strongestCorrelations: [], // Would need cross-server analysis
        overallPerformanceScore: overallScore.toDouble(),
        improvementAreas: improvementAreas,
      );
    }
    
    return profiles;
  }

  /// Build predictive models based on correlations
  static List<PredictiveModel> _buildPredictiveModels(
    List<VariableCorrelation> correlations,
    List<ServerShiftPerformance> performances,
  ) {
    final models = <PredictiveModel>[];
    
    // Sales prediction model
    final salesCorrelations = correlations
        .where((c) => c.variable2.contains('Sales') && c.isSignificant && c.correlation > 0.5)
        .toList();
    
    if (salesCorrelations.isNotEmpty) {
      final bestPredictor = salesCorrelations
          .reduce((a, b) => a.correlation.abs() > b.correlation.abs() ? a : b);
      
      // Simple linear regression coefficients
      final x = performances.map((p) => p.totalRuns.toDouble()).toList();
      final y = performances.map((p) => p.salesGenerated ?? 0.0).toList();
      
      final meanX = x.reduce((a, b) => a + b) / x.length;
      final meanY = y.reduce((a, b) => a + b) / y.length;
      
      double numerator = 0;
      double denominator = 0;
      for (int i = 0; i < x.length; i++) {
        numerator += (x[i] - meanX) * (y[i] - meanY);
        denominator += (x[i] - meanX) * (x[i] - meanX);
      }
      
      final slope = denominator > 0 ? numerator / denominator : 0;
      final intercept = meanY - slope * meanX;
      
      models.add(PredictiveModel(
        modelName: 'Sales Prediction Model',
        targetVariable: 'Sales Generated',
        predictorVariables: ['Total Runs'],
        coefficients: {
          'intercept': intercept.toDouble(),
          'Total Runs': slope.toDouble(),
        },
        accuracy: bestPredictor.rSquared,
        formula: 'Sales = ${intercept.toStringAsFixed(2)} + ${slope.toStringAsFixed(2)} × Runs',
      ));
    }
    
    return models;
  }

  /// Calculate p-value approximation
  static double _calculatePValue(double tStat, int degreesOfFreedom) {
    // Very rough approximation - in practice, you'd use a proper t-distribution
    if (degreesOfFreedom < 1) return 1.0;
    if (tStat < 1.0) return 0.5;
    if (tStat < 2.0) return 0.1;
    if (tStat < 3.0) return 0.02;
    if (tStat < 4.0) return 0.005;
    return 0.001;
  }
}