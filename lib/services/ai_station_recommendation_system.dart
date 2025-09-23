/// AI-Powered Station Recommendation System
/// Machine learning algorithms for optimal server-to-station assignments

import 'dart:math' as math;
import 'package:collection/collection.dart';

import '../models.dart';
import '../models/predictive_scheduling_models.dart';
import '../services/predictive_scheduling_engine.dart';
import '../storage.dart';

/// Advanced ML-based recommendation system for station assignments
class AIStationRecommendationSystem {
  static const String _storageKeyMLModels = 'ml_models';
  static const String _storageKeyTrainingData = 'training_data';
  
  /// Generate AI-powered station recommendations for a server
  static Future<List<StationRecommendation>> getServerStationRecommendations({
    required String serverId,
    required DateTime targetDate,
    required String shiftType,
    required List<String> availableStations,
  }) async {
    try {
      // Load server performance profile
      final profiles = await PredictiveSchedulingEngine.getServerPerformanceProfiles();
      final serverProfile = profiles.firstWhereOrNull((p) => p.serverId == serverId);
      
      // Load ML models
      final models = await _loadMLModels();
      
      // Generate recommendations for each available station
      final recommendations = <StationRecommendation>[];
      
      for (final stationType in availableStations) {
        final recommendation = await _generateStationRecommendation(
          serverId,
          stationType,
          serverProfile,
          models,
          targetDate,
          shiftType,
        );
        recommendations.add(recommendation);
      }
      
      // Sort by performance score (highest first)
      recommendations.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
      
      return recommendations;
    } catch (e) {
      print('[AI-RECOMMEND] Error generating recommendations: $e');
      return [];
    }
  }

  /// Train ML models using historical shift data
  static Future<void> trainMLModels() async {
    try {
      print('[AI-RECOMMEND] Starting ML model training...');
      
      // Load historical data
      final trainingData = await _prepareTrainingData();
      
      if (trainingData.isEmpty) {
        print('[AI-RECOMMEND] Insufficient training data');
        return;
      }
      
      // Train different ML models
      final models = <String, dynamic>{};
      
      // 1. Performance Prediction Model
      models['performance_predictor'] = await _trainPerformancePredictionModel(trainingData);
      
      // 2. Compatibility Model (server-station fit)
      models['compatibility_model'] = await _trainCompatibilityModel(trainingData);
      
      // 3. Workload Distribution Model
      models['workload_model'] = await _trainWorkloadDistributionModel(trainingData);
      
      // 4. Time-based Performance Model
      models['time_performance_model'] = await _trainTimePerformanceModel(trainingData);
      
      // Save trained models
      await _saveMLModels(models);
      
      print('[AI-RECOMMEND] ML model training completed successfully');
    } catch (e) {
      print('[AI-RECOMMEND] Error training ML models: $e');
    }
  }

  /// Generate recommendation for a specific server-station combination
  static Future<StationRecommendation> _generateStationRecommendation(
    String serverId,
    String stationType,
    ServerPerformanceProfile? profile,
    Map<String, dynamic> models,
    DateTime targetDate,
    String shiftType,
  ) async {
    // Base scores
    double performanceScore = 50.0;
    double confidenceScore = 0.5;
    String reasoning = 'Basic assignment';
    
    if (profile != null) {
      // Historical efficiency at this station
      final historicalEfficiency = profile.getStationEfficiency(stationType);
      performanceScore = historicalEfficiency;
      
      // Experience factor
      final experience = profile.getStationExperience(stationType);
      final experienceMultiplier = _calculateExperienceMultiplier(experience);
      performanceScore *= experienceMultiplier;
      
      // Time-based adjustment
      final timeMultiplier = profile.getTimePerformanceMultiplier(targetDate);
      performanceScore *= timeMultiplier;
      
      // Apply ML model predictions if available
      if (models.containsKey('performance_predictor')) {
        final mlScore = await _applyPerformancePredictionModel(
          models['performance_predictor'],
          serverId,
          stationType,
          profile,
          targetDate,
          shiftType,
        );
        
        // Blend historical data with ML prediction
        performanceScore = performanceScore * 0.7 + mlScore * 0.3;
      }
      
      if (models.containsKey('compatibility_model')) {
        final compatibilityScore = await _applyCompatibilityModel(
          models['compatibility_model'],
          serverId,
          stationType,
          profile,
        );
        
        performanceScore = performanceScore * 0.8 + compatibilityScore * 0.2;
      }
      
      // Calculate confidence based on data quality
      confidenceScore = _calculateConfidenceScore(profile, stationType);
      
      // Generate reasoning
      reasoning = _generateRecommendationReasoning(
        profile,
        stationType,
        performanceScore,
        experience,
      );
    }
    
    // Clamp scores to valid ranges
    performanceScore = performanceScore.clamp(0.0, 100.0);
    confidenceScore = confidenceScore.clamp(0.0, 1.0);
    
    return StationRecommendation(
      serverId: serverId,
      stationType: stationType,
      performanceScore: performanceScore,
      confidenceScore: confidenceScore,
      reasoning: reasoning,
      factors: _extractPerformanceFactors(profile, stationType),
      risks: _identifyPotentialRisks(profile, stationType, performanceScore),
      alternatives: [], // Could be populated with alternative station suggestions
    );
  }

  /// Prepare training data from historical shifts
  static Future<List<TrainingDataPoint>> _prepareTrainingData() async {
    final trainingData = <TrainingDataPoint>[];
    
    // Load shift records
    final List<Map> rawRecords = 
        (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
    
    final records = rawRecords.map((json) => ShiftRecord.fromMap(Map<String, dynamic>.from(json))).toList();
    
    // Extract training examples
    for (final record in records) {
      if (record.stationAssignments == null) continue;
      
      for (final entry in record.stationAssignments!.entries) {
        final serverId = entry.key;
        final stationType = entry.value;
        final performance = record.counts[serverId]?.toDouble() ?? 0.0;
        
        // Create training data point
        final dataPoint = TrainingDataPoint(
          serverId: serverId,
          stationType: stationType,
          shiftType: record.shiftType,
          date: record.start,
          performance: performance,
          timeOfDay: record.start.hour,
          dayOfWeek: record.start.weekday,
          month: record.start.month,
          features: _extractFeatures(record, serverId, stationType),
        );
        
        trainingData.add(dataPoint);
      }
    }
    
    return trainingData;
  }

  /// Train performance prediction model
  static Future<Map<String, dynamic>> _trainPerformancePredictionModel(
    List<TrainingDataPoint> trainingData,
  ) async {
    // Simple linear regression model for performance prediction
    final model = <String, dynamic>{};
    
    // Group by station type
    final stationGroups = groupBy(trainingData, (TrainingDataPoint d) => d.stationType);
    
    for (final entry in stationGroups.entries) {
      final stationType = entry.key;
      final data = entry.value;
      
      if (data.length < 10) continue; // Need sufficient data
      
      // Calculate correlations between features and performance
      final correlations = <String, double>{};
      
      // Time of day correlation
      correlations['time_of_day'] = _calculateCorrelation(
        data.map((d) => d.timeOfDay.toDouble()).toList(),
        data.map((d) => d.performance).toList(),
      );
      
      // Day of week correlation
      correlations['day_of_week'] = _calculateCorrelation(
        data.map((d) => d.dayOfWeek.toDouble()).toList(),
        data.map((d) => d.performance).toList(),
      );
      
      // Month correlation (seasonality)
      correlations['month'] = _calculateCorrelation(
        data.map((d) => d.month.toDouble()).toList(),
        data.map((d) => d.performance).toList(),
      );
      
      // Performance statistics
      final performances = data.map((d) => d.performance).toList();
      final avgPerformance = performances.reduce((a, b) => a + b) / performances.length;
      final stdDev = _calculateStandardDeviation(performances);
      
      model[stationType] = {
        'correlations': correlations,
        'avg_performance': avgPerformance,
        'std_dev': stdDev,
        'sample_size': data.length,
      };
    }
    
    return model;
  }

  /// Train compatibility model
  static Future<Map<String, dynamic>> _trainCompatibilityModel(
    List<TrainingDataPoint> trainingData,
  ) async {
    final model = <String, dynamic>{};
    
    // Create server-station performance matrix
    final serverStationPerformance = <String, Map<String, List<double>>>{};
    
    for (final data in trainingData) {
      serverStationPerformance[data.serverId] ??= {};
      serverStationPerformance[data.serverId]![data.stationType] ??= [];
      serverStationPerformance[data.serverId]![data.stationType]!.add(data.performance);
    }
    
    // Calculate compatibility scores
    final compatibilityMatrix = <String, Map<String, double>>{};
    
    for (final serverEntry in serverStationPerformance.entries) {
      final serverId = serverEntry.key;
      final stationPerformances = serverEntry.value;
      
      compatibilityMatrix[serverId] = {};
      
      for (final stationEntry in stationPerformances.entries) {
        final stationType = stationEntry.key;
        final performances = stationEntry.value;
        
        if (performances.isNotEmpty) {
          final avgPerformance = performances.reduce((a, b) => a + b) / performances.length;
          final consistency = 1.0 - (_calculateStandardDeviation(performances) / avgPerformance);
          
          // Compatibility score combines performance and consistency
          compatibilityMatrix[serverId]![stationType] = 
              avgPerformance * 0.7 + consistency * 100 * 0.3;
        }
      }
    }
    
    model['compatibility_matrix'] = compatibilityMatrix;
    return model;
  }

  /// Train workload distribution model
  static Future<Map<String, dynamic>> _trainWorkloadDistributionModel(
    List<TrainingDataPoint> trainingData,
  ) async {
    final model = <String, dynamic>{};
    
    // Analyze optimal workload distribution patterns
    final shiftGroups = groupBy(trainingData, (d) => '${d.date.toIso8601String().split('T')[0]}_${d.shiftType}');
    
    final distributionPatterns = <String, List<double>>{}; // stationType -> distribution ratios
    
    for (final shiftData in shiftGroups.values) {
      final stationCounts = <String, int>{};
      double totalPerformance = 0;
      
      // Count servers per station and total performance
      for (final data in shiftData) {
        stationCounts[data.stationType] = (stationCounts[data.stationType] ?? 0) + 1;
        totalPerformance += data.performance;
      }
      
      // Calculate distribution ratios
      for (final entry in stationCounts.entries) {
        final stationType = entry.key;
        final count = entry.value;
        final ratio = count / shiftData.length.toDouble();
        
        distributionPatterns[stationType] ??= [];
        distributionPatterns[stationType]!.add(ratio);
      }
    }
    
    // Calculate optimal ratios
    final optimalRatios = <String, double>{};
    for (final entry in distributionPatterns.entries) {
      final stationType = entry.key;
      final ratios = entry.value;
      
      if (ratios.isNotEmpty) {
        optimalRatios[stationType] = ratios.reduce((a, b) => a + b) / ratios.length;
      }
    }
    
    model['optimal_ratios'] = optimalRatios;
    return model;
  }

  /// Train time-based performance model
  static Future<Map<String, dynamic>> _trainTimePerformanceModel(
    List<TrainingDataPoint> trainingData,
  ) async {
    final model = <String, dynamic>{};
    
    // Group by hour of day
    final hourlyPerformance = <int, List<double>>{};
    
    for (final data in trainingData) {
      hourlyPerformance[data.timeOfDay] ??= [];
      hourlyPerformance[data.timeOfDay]!.add(data.performance);
    }
    
    // Calculate average performance for each hour
    final hourlyAverages = <int, double>{};
    for (final entry in hourlyPerformance.entries) {
      final hour = entry.key;
      final performances = entry.value;
      
      if (performances.isNotEmpty) {
        hourlyAverages[hour] = performances.reduce((a, b) => a + b) / performances.length;
      }
    }
    
    model['hourly_averages'] = hourlyAverages;
    
    // Day of week patterns
    final dailyPerformance = <int, List<double>>{};
    for (final data in trainingData) {
      dailyPerformance[data.dayOfWeek] ??= [];
      dailyPerformance[data.dayOfWeek]!.add(data.performance);
    }
    
    final dailyAverages = <int, double>{};
    for (final entry in dailyPerformance.entries) {
      final day = entry.key;
      final performances = entry.value;
      
      if (performances.isNotEmpty) {
        dailyAverages[day] = performances.reduce((a, b) => a + b) / performances.length;
      }
    }
    
    model['daily_averages'] = dailyAverages;
    return model;
  }

  /// Apply performance prediction model
  static Future<double> _applyPerformancePredictionModel(
    Map<String, dynamic> model,
    String serverId,
    String stationType,
    ServerPerformanceProfile profile,
    DateTime targetDate,
    String shiftType,
  ) async {
    final stationModel = model[stationType] as Map<String, dynamic>?;
    if (stationModel == null) return profile.getStationEfficiency(stationType);
    
    final correlations = Map<String, double>.from(stationModel['correlations']);
    final avgPerformance = stationModel['avg_performance'] as double;
    
    // Apply correlations
    double predictedPerformance = avgPerformance;
    
    // Time of day adjustment
    final timeCorr = correlations['time_of_day'] ?? 0.0;
    predictedPerformance += timeCorr * targetDate.hour;
    
    // Day of week adjustment
    final dayCorr = correlations['day_of_week'] ?? 0.0;
    predictedPerformance += dayCorr * targetDate.weekday;
    
    // Month adjustment
    final monthCorr = correlations['month'] ?? 0.0;
    predictedPerformance += monthCorr * targetDate.month;
    
    return predictedPerformance.clamp(0.0, 100.0);
  }

  /// Apply compatibility model
  static Future<double> _applyCompatibilityModel(
    Map<String, dynamic> model,
    String serverId,
    String stationType,
    ServerPerformanceProfile profile,
  ) async {
    final compatibilityMatrix = model['compatibility_matrix'] as Map<String, dynamic>?;
    if (compatibilityMatrix == null) return profile.getStationEfficiency(stationType);
    
    final serverMatrix = compatibilityMatrix[serverId] as Map<String, dynamic>?;
    if (serverMatrix == null) return profile.getStationEfficiency(stationType);
    
    return (serverMatrix[stationType] as double?) ?? profile.getStationEfficiency(stationType);
  }

  /// Calculate experience multiplier
  static double _calculateExperienceMultiplier(int experience) {
    // Diminishing returns on experience
    return 1.0 + (math.log(experience + 1) * 0.1);
  }

  /// Calculate confidence score
  static double _calculateConfidenceScore(ServerPerformanceProfile profile, String stationType) {
    final experience = profile.getStationExperience(stationType);
    final dataPoints = experience;
    
    // More data points = higher confidence
    final confidenceFromData = (dataPoints / 20.0).clamp(0.0, 1.0);
    
    // Recent data is more reliable
    final daysSinceUpdate = DateTime.now().difference(profile.lastUpdated).inDays;
    final recencyFactor = math.max(0.0, 1.0 - (daysSinceUpdate / 30.0));
    
    return confidenceFromData * 0.7 + recencyFactor * 0.3;
  }

  /// Generate reasoning for recommendation
  static String _generateRecommendationReasoning(
    ServerPerformanceProfile profile,
    String stationType,
    double performanceScore,
    int experience,
  ) {
    final efficiency = profile.getStationEfficiency(stationType);
    final isPreferred = profile.preferredStations.contains(stationType);
    
    if (performanceScore >= 80) {
      if (isPreferred) {
        return 'Excellent choice - server\'s preferred station with ${efficiency.toStringAsFixed(1)}% efficiency';
      } else {
        return 'Strong performance expected based on ${efficiency.toStringAsFixed(1)}% historical efficiency';
      }
    } else if (performanceScore >= 60) {
      if (experience >= 10) {
        return 'Solid choice - experienced server with consistent performance';
      } else {
        return 'Good fit based on historical data, room for improvement';
      }
    } else {
      if (experience < 5) {
        return 'Limited experience at this station, consider training or alternative assignment';
      } else {
        return 'Below average performance historically, monitor closely';
      }
    }
  }

  /// Extract performance factors
  static List<String> _extractPerformanceFactors(ServerPerformanceProfile? profile, String stationType) {
    final factors = <String>[];
    
    if (profile == null) return ['Insufficient data'];
    
    final efficiency = profile.getStationEfficiency(stationType);
    final experience = profile.getStationExperience(stationType);
    
    if (efficiency >= 80) factors.add('High efficiency (${efficiency.toStringAsFixed(1)}%)');
    if (experience >= 15) factors.add('Very experienced (${experience} shifts)');
    if (profile.preferredStations.contains(stationType)) factors.add('Preferred station');
    if (profile.overallPerformance >= 75) factors.add('Top performer overall');
    
    if (factors.isEmpty) factors.add('Standard assignment');
    
    return factors;
  }

  /// Identify potential risks
  static List<String> _identifyPotentialRisks(ServerPerformanceProfile? profile, String stationType, double score) {
    final risks = <String>[];
    
    if (profile == null) {
      risks.add('No historical data available');
      return risks;
    }
    
    final efficiency = profile.getStationEfficiency(stationType);
    final experience = profile.getStationExperience(stationType);
    
    if (efficiency < 60) risks.add('Below average efficiency');
    if (experience < 3) risks.add('Limited experience at this station');
    if (score < 50) risks.add('Low predicted performance');
    if (!profile.preferredStations.contains(stationType) && profile.preferredStations.isNotEmpty) {
      risks.add('Not server\'s preferred station');
    }
    
    return risks;
  }

  /// Extract features for ML training
  static Map<String, double> _extractFeatures(ShiftRecord record, String serverId, String stationType) {
    return {
      'time_of_day': record.start.hour.toDouble(),
      'day_of_week': record.start.weekday.toDouble(),
      'month': record.start.month.toDouble(),
      'performance': record.counts[serverId]?.toDouble() ?? 0.0,
    };
  }

  /// Calculate correlation between two datasets
  static double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);
    
    final numerator = n * sumXY - sumX * sumY;
    final denominator = math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    
    return denominator != 0 ? numerator / denominator : 0.0;
  }

  /// Calculate standard deviation
  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    
    return math.sqrt(variance);
  }

  /// Load ML models from storage
  static Future<Map<String, dynamic>> _loadMLModels() async {
    try {
      final box = Storage.settingsBox;
      final data = await box.get(_storageKeyMLModels);
      
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('[AI-RECOMMEND] Error loading ML models: $e');
    }
    
    return {};
  }

  /// Save ML models to storage
  static Future<void> _saveMLModels(Map<String, dynamic> models) async {
    try {
      final box = Storage.settingsBox;
      await box.put(_storageKeyMLModels, models);
    } catch (e) {
      print('[AI-RECOMMEND] Error saving ML models: $e');
    }
  }
}

/// Training data point for ML algorithms
class TrainingDataPoint {
  final String serverId;
  final String stationType;
  final String shiftType;
  final DateTime date;
  final double performance;
  final int timeOfDay;
  final int dayOfWeek;
  final int month;
  final Map<String, double> features;
  
  const TrainingDataPoint({
    required this.serverId,
    required this.stationType,
    required this.shiftType,
    required this.date,
    required this.performance,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.month,
    required this.features,
  });
}

/// AI-generated station recommendation
class StationRecommendation {
  final String serverId;
  final String stationType;
  final double performanceScore; // 0-100
  final double confidenceScore; // 0-1
  final String reasoning;
  final List<String> factors; // Positive factors
  final List<String> risks; // Potential issues
  final List<String> alternatives; // Alternative station suggestions
  
  const StationRecommendation({
    required this.serverId,
    required this.stationType,
    required this.performanceScore,
    required this.confidenceScore,
    required this.reasoning,
    required this.factors,
    required this.risks,
    required this.alternatives,
  });

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'stationType': stationType,
    'performanceScore': performanceScore,
    'confidenceScore': confidenceScore,
    'reasoning': reasoning,
    'factors': factors,
    'risks': risks,
    'alternatives': alternatives,
  };

  /// Create from JSON
  factory StationRecommendation.fromJson(Map<String, dynamic> json) => StationRecommendation(
    serverId: json['serverId'],
    stationType: json['stationType'],
    performanceScore: json['performanceScore'].toDouble(),
    confidenceScore: json['confidenceScore'].toDouble(),
    reasoning: json['reasoning'],
    factors: List<String>.from(json['factors']),
    risks: List<String>.from(json['risks']),
    alternatives: List<String>.from(json['alternatives']),
  );

  /// Get recommendation grade (A, B, C, D, F)
  String get grade {
    if (performanceScore >= 90) return 'A';
    if (performanceScore >= 80) return 'B';
    if (performanceScore >= 70) return 'C';
    if (performanceScore >= 60) return 'D';
    return 'F';
  }

  /// Check if this is a high-confidence recommendation
  bool get isHighConfidence => confidenceScore >= 0.8;
  
  /// Check if this recommendation has significant risks
  bool get hasSignificantRisks => risks.isNotEmpty && performanceScore < 60;
}