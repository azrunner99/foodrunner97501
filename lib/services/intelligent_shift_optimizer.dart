/// Intelligent Shift Optimization System
/// Comprehensive AI-powered optimization for restaurant shift scheduling

import 'dart:math' as math;
import 'package:collection/collection.dart';

import '../models.dart';
import '../models/predictive_scheduling_models.dart';
import '../services/predictive_scheduling_engine.dart';
import '../services/ai_station_recommendation_system.dart';
import '../storage.dart';

/// Advanced optimization system for complete shift scheduling
class IntelligentShiftOptimizer {
  static const String _storageKeyOptimizations = 'shift_optimizations';
  static const String _storageKeyOptimizationHistory = 'optimization_history';

  /// Generate optimized shift schedule using AI algorithms
  static Future<ShiftOptimization> optimizeShift({
    required DateTime date,
    required String shiftType,
    required List<String> availableServerIds,
    required Map<String, double> stationRequirements, // stationType -> required capacity
    SchedulingConfig? config,
  }) async {
    try {
      print('[OPTIMIZER] Starting optimization for ${shiftType} shift on ${date.toIso8601String().split('T')[0]}');
      
      final effectiveConfig = config ?? await PredictiveSchedulingEngine.getSchedulingConfig();
      
      // Step 1: Generate base predictions
      final basePrediction = await PredictiveSchedulingEngine.generateSchedule(
        date: date,
        shiftType: shiftType,
        availableServerIds: availableServerIds,
        config: effectiveConfig,
      );
      
      // Step 2: Apply AI recommendations for each server
      final aiRecommendations = await _generateAIRecommendations(
        availableServerIds,
        date,
        shiftType,
        stationRequirements.keys.toList(),
      );
      
      // Step 3: Run optimization algorithms
      final optimizedAssignments = await _runOptimizationAlgorithm(
        availableServerIds,
        stationRequirements,
        aiRecommendations,
        basePrediction,
        effectiveConfig,
      );
      
      // Step 4: Validate and score the optimization
      final optimizationScore = await _calculateOptimizationScore(
        optimizedAssignments,
        stationRequirements,
        aiRecommendations,
      );
      
      // Step 5: Generate insights and improvements
      final insights = await _generateOptimizationInsights(
        basePrediction.recommendedAssignments,
        optimizedAssignments,
        aiRecommendations,
        stationRequirements,
      );
      
      // Step 6: Calculate overall metrics
      final metrics = await _calculateOptimizationMetrics(
        optimizedAssignments,
        aiRecommendations,
        stationRequirements,
      );
      
      final optimization = ShiftOptimization(
        date: date,
        shiftType: shiftType,
        originalAssignments: basePrediction.recommendedAssignments,
        optimizedAssignments: optimizedAssignments,
        optimizationScore: optimizationScore,
        improvementPercentage: _calculateImprovementPercentage(basePrediction, optimizedAssignments, aiRecommendations),
        insights: insights,
        metrics: metrics,
        aiRecommendations: aiRecommendations,
        generatedAt: DateTime.now(),
        algorithm: 'IntelligentShiftOptimizer v2.0',
      );
      
      // Cache the optimization
      await _cacheOptimization(optimization);
      
      print('[OPTIMIZER] Optimization completed with ${optimizationScore.toStringAsFixed(1)}% score');
      
      return optimization;
    } catch (e) {
      print('[OPTIMIZER] Error during optimization: $e');
      
      // Return fallback optimization
      return ShiftOptimization(
        date: date,
        shiftType: shiftType,
        originalAssignments: {},
        optimizedAssignments: _generateFallbackAssignments(availableServerIds),
        optimizationScore: 0.0,
        improvementPercentage: 0.0,
        insights: [
          OptimizationInsight(
            type: 'error',
            title: 'Optimization Failed',
            description: 'Unable to generate optimization due to insufficient data',
            impact: -20.0,
            recommendation: 'Use manual scheduling until more historical data is available',
          ),
        ],
        metrics: {},
        aiRecommendations: {},
        generatedAt: DateTime.now(),
        algorithm: 'Fallback',
      );
    }
  }

  /// Generate AI recommendations for all servers
  static Future<Map<String, List<StationRecommendation>>> _generateAIRecommendations(
    List<String> serverIds,
    DateTime date,
    String shiftType,
    List<String> availableStations,
  ) async {
    final recommendations = <String, List<StationRecommendation>>{};
    
    for (final serverId in serverIds) {
      final serverRecommendations = await AIStationRecommendationSystem.getServerStationRecommendations(
        serverId: serverId,
        targetDate: date,
        shiftType: shiftType,
        availableStations: availableStations,
      );
      
      recommendations[serverId] = serverRecommendations;
    }
    
    return recommendations;
  }

  /// Run advanced optimization algorithm
  static Future<Map<String, String>> _runOptimizationAlgorithm(
    List<String> serverIds,
    Map<String, double> stationRequirements,
    Map<String, List<StationRecommendation>> aiRecommendations,
    PredictedSchedule basePrediction,
    SchedulingConfig config,
  ) async {
    // Multi-objective optimization using genetic algorithm approach
    
    // Initialize population of possible assignments
    final populationSize = math.min(100, serverIds.length * 10);
    final population = <Map<String, String>>[];
    
    // Generate initial population
    for (int i = 0; i < populationSize; i++) {
      population.add(_generateRandomAssignment(serverIds, stationRequirements.keys.toList(), aiRecommendations));
    }
    
    // Add base prediction to population
    population.add(basePrediction.recommendedAssignments);
    
    // Evolution parameters
    const generations = 50;
    const mutationRate = 0.1;
    const crossoverRate = 0.7;
    
    // Evolve population
    for (int generation = 0; generation < generations; generation++) {
      // Evaluate fitness of each individual
      final fitnessScores = <double>[];
      for (final assignment in population) {
        final fitness = await _calculateAssignmentFitness(assignment, stationRequirements, aiRecommendations);
        fitnessScores.add(fitness);
      }
      
      // Selection: keep best performers
      final sortedIndices = List.generate(population.length, (i) => i)
        ..sort((a, b) => fitnessScores[b].compareTo(fitnessScores[a]));
      
      final newPopulation = <Map<String, String>>[];
      
      // Keep top 20% (elitism)
      final eliteCount = (populationSize * 0.2).round();
      for (int i = 0; i < eliteCount; i++) {
        newPopulation.add(Map<String, String>.from(population[sortedIndices[i]]));
      }
      
      // Generate new individuals through crossover and mutation
      while (newPopulation.length < populationSize) {
        if (math.Random().nextDouble() < crossoverRate && newPopulation.length > 1) {
          // Crossover
          final parent1 = population[sortedIndices[math.Random().nextInt(eliteCount * 2)]];
          final parent2 = population[sortedIndices[math.Random().nextInt(eliteCount * 2)]];
          final child = _crossover(parent1, parent2);
          newPopulation.add(child);
        } else {
          // Mutation
          final parent = population[sortedIndices[math.Random().nextInt(eliteCount)]];
          final mutated = _mutate(parent, stationRequirements.keys.toList(), mutationRate);
          newPopulation.add(mutated);
        }
      }
      
      population.clear();
      population.addAll(newPopulation);
    }
    
    // Return best assignment
    final finalFitnessScores = <double>[];
    for (final assignment in population) {
      final fitness = await _calculateAssignmentFitness(assignment, stationRequirements, aiRecommendations);
      finalFitnessScores.add(fitness);
    }
    
    final bestIndex = finalFitnessScores.indexWhere((score) => score == finalFitnessScores.reduce(math.max));
    return population[bestIndex];
  }

  /// Calculate fitness score for an assignment
  static Future<double> _calculateAssignmentFitness(
    Map<String, String> assignment,
    Map<String, double> stationRequirements,
    Map<String, List<StationRecommendation>> aiRecommendations,
  ) async {
    double totalFitness = 0.0;
    
    // 1. Server satisfaction (40% weight)
    double serverSatisfaction = 0.0;
    for (final entry in assignment.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final recommendations = aiRecommendations[serverId] ?? [];
      final recommendation = recommendations.firstWhereOrNull((r) => r.stationType == stationType);
      
      if (recommendation != null) {
        serverSatisfaction += recommendation.performanceScore;
      } else {
        serverSatisfaction += 50.0; // Default score
      }
    }
    
    if (assignment.isNotEmpty) {
      serverSatisfaction /= assignment.length;
      totalFitness += serverSatisfaction * 0.4;
    }
    
    // 2. Station coverage (30% weight)
    double stationCoverage = 0.0;
    final stationCounts = <String, int>{};
    
    for (final stationType in assignment.values) {
      stationCounts[stationType] = (stationCounts[stationType] ?? 0) + 1;
    }
    
    for (final entry in stationRequirements.entries) {
      final stationType = entry.key;
      final required = entry.value;
      final assigned = stationCounts[stationType] ?? 0;
      
      // Perfect coverage = 100, under/over staffing reduces score
      final coverage = 100.0 - (assigned - required).abs() * 10.0;
      stationCoverage += coverage.clamp(0.0, 100.0);
    }
    
    if (stationRequirements.isNotEmpty) {
      stationCoverage /= stationRequirements.length;
      totalFitness += stationCoverage * 0.3;
    }
    
    // 3. Experience distribution (20% weight)
    double experienceDistribution = _calculateExperienceDistribution(assignment, aiRecommendations);
    totalFitness += experienceDistribution * 0.2;
    
    // 4. Risk mitigation (10% weight)
    double riskMitigation = _calculateRiskMitigation(assignment, aiRecommendations);
    totalFitness += riskMitigation * 0.1;
    
    return totalFitness.clamp(0.0, 100.0);
  }

  /// Generate random assignment for genetic algorithm
  static Map<String, String> _generateRandomAssignment(
    List<String> serverIds,
    List<String> stationTypes,
    Map<String, List<StationRecommendation>> aiRecommendations,
  ) {
    final assignment = <String, String>{};
    final random = math.Random();
    
    for (final serverId in serverIds) {
      final recommendations = aiRecommendations[serverId] ?? [];
      
      if (recommendations.isNotEmpty && random.nextDouble() < 0.7) {
        // 70% chance to use AI recommendation
        final topRecommendations = recommendations.take(3).toList();
        assignment[serverId] = topRecommendations[random.nextInt(topRecommendations.length)].stationType;
      } else {
        // Random assignment
        assignment[serverId] = stationTypes[random.nextInt(stationTypes.length)];
      }
    }
    
    return assignment;
  }

  /// Crossover operation for genetic algorithm
  static Map<String, String> _crossover(Map<String, String> parent1, Map<String, String> parent2) {
    final child = <String, String>{};
    final random = math.Random();
    
    for (final serverId in parent1.keys) {
      if (parent2.containsKey(serverId)) {
        // Randomly choose from either parent
        child[serverId] = random.nextBool() ? parent1[serverId]! : parent2[serverId]!;
      } else {
        child[serverId] = parent1[serverId]!;
      }
    }
    
    return child;
  }

  /// Mutation operation for genetic algorithm
  static Map<String, String> _mutate(
    Map<String, String> assignment,
    List<String> stationTypes,
    double mutationRate,
  ) {
    final mutated = Map<String, String>.from(assignment);
    final random = math.Random();
    
    for (final serverId in mutated.keys) {
      if (random.nextDouble() < mutationRate) {
        mutated[serverId] = stationTypes[random.nextInt(stationTypes.length)];
      }
    }
    
    return mutated;
  }

  /// Calculate experience distribution score
  static double _calculateExperienceDistribution(
    Map<String, String> assignment,
    Map<String, List<StationRecommendation>> aiRecommendations,
  ) {
    final stationExperience = <String, List<double>>{};
    
    for (final entry in assignment.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final recommendations = aiRecommendations[serverId] ?? [];
      final recommendation = recommendations.firstWhereOrNull((r) => r.stationType == stationType);
      
      stationExperience[stationType] ??= [];
      stationExperience[stationType]!.add(recommendation?.performanceScore ?? 50.0);
    }
    
    // Calculate variance in experience levels for each station
    double totalVariance = 0.0;
    int stationCount = 0;
    
    for (final scores in stationExperience.values) {
      if (scores.length > 1) {
        final mean = scores.reduce((a, b) => a + b) / scores.length;
        final variance = scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
        totalVariance += variance;
        stationCount++;
      }
    }
    
    // Lower variance = better distribution = higher score
    final avgVariance = stationCount > 0 ? totalVariance / stationCount : 0.0;
    return math.max(0.0, 100.0 - avgVariance);
  }

  /// Calculate risk mitigation score
  static double _calculateRiskMitigation(
    Map<String, String> assignment,
    Map<String, List<StationRecommendation>> aiRecommendations,
  ) {
    double totalRisk = 0.0;
    int assignmentCount = 0;
    
    for (final entry in assignment.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final recommendations = aiRecommendations[serverId] ?? [];
      final recommendation = recommendations.firstWhereOrNull((r) => r.stationType == stationType);
      
      if (recommendation != null) {
        final riskScore = recommendation.risks.length * 10.0; // 10 points per risk
        totalRisk += riskScore;
        assignmentCount++;
      }
    }
    
    // Lower risk = higher score
    final avgRisk = assignmentCount > 0 ? totalRisk / assignmentCount : 0.0;
    return math.max(0.0, 100.0 - avgRisk);
  }

  /// Calculate optimization score
  static Future<double> _calculateOptimizationScore(
    Map<String, String> assignments,
    Map<String, double> stationRequirements,
    Map<String, List<StationRecommendation>> aiRecommendations,
  ) async {
    return _calculateAssignmentFitness(assignments, stationRequirements, aiRecommendations);
  }

  /// Generate optimization insights
  static Future<List<OptimizationInsight>> _generateOptimizationInsights(
    Map<String, String> originalAssignments,
    Map<String, String> optimizedAssignments,
    Map<String, List<StationRecommendation>> aiRecommendations,
    Map<String, double> stationRequirements,
  ) async {
    final insights = <OptimizationInsight>[];
    
    // Compare original vs optimized
    final changedAssignments = <String>[];
    for (final entry in optimizedAssignments.entries) {
      final serverId = entry.key;
      final newStation = entry.value;
      final oldStation = originalAssignments[serverId];
      
      if (oldStation != newStation) {
        changedAssignments.add(serverId);
      }
    }
    
    if (changedAssignments.isNotEmpty) {
      insights.add(OptimizationInsight(
        type: 'optimization',
        title: 'Assignment Improvements',
        description: 'Optimized assignments for ${changedAssignments.length} servers',
        impact: changedAssignments.length * 5.0,
        recommendation: 'Review changes and consider implementing optimized assignments',
      ));
    }
    
    // Check for high-risk assignments
    final highRiskAssignments = <String>[];
    for (final entry in optimizedAssignments.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final recommendations = aiRecommendations[serverId] ?? [];
      final recommendation = recommendations.firstWhereOrNull((r) => r.stationType == stationType);
      
      if (recommendation != null && recommendation.hasSignificantRisks) {
        highRiskAssignments.add(serverId);
      }
    }
    
    if (highRiskAssignments.isNotEmpty) {
      insights.add(OptimizationInsight(
        type: 'warning',
        title: 'High-Risk Assignments',
        description: '${highRiskAssignments.length} assignments have elevated risk factors',
        impact: -highRiskAssignments.length * 3.0,
        recommendation: 'Monitor these assignments closely and consider alternatives',
      ));
    }
    
    // Check station coverage
    final stationCounts = <String, int>{};
    for (final stationType in optimizedAssignments.values) {
      stationCounts[stationType] = (stationCounts[stationType] ?? 0) + 1;
    }
    
    for (final entry in stationRequirements.entries) {
      final stationType = entry.key;
      final required = entry.value;
      final assigned = stationCounts[stationType] ?? 0;
      
      if (assigned < required) {
        insights.add(OptimizationInsight(
          type: 'warning',
          title: 'Understaffed Station',
          description: '$stationType needs ${required.toInt()} servers but only has $assigned assigned',
          impact: -(required - assigned) * 8.0,
          recommendation: 'Consider reassigning servers to $stationType or hiring additional staff',
        ));
      }
    }
    
    return insights;
  }

  /// Calculate optimization metrics
  static Future<Map<String, double>> _calculateOptimizationMetrics(
    Map<String, String> assignments,
    Map<String, List<StationRecommendation>> aiRecommendations,
    Map<String, double> stationRequirements,
  ) async {
    final metrics = <String, double>{};
    
    // Average performance score
    double totalPerformance = 0.0;
    int count = 0;
    
    for (final entry in assignments.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final recommendations = aiRecommendations[serverId] ?? [];
      final recommendation = recommendations.firstWhereOrNull((r) => r.stationType == stationType);
      
      if (recommendation != null) {
        totalPerformance += recommendation.performanceScore;
        count++;
      }
    }
    
    metrics['averagePerformanceScore'] = count > 0 ? totalPerformance / count : 0.0;
    
    // Station coverage efficiency
    final stationCounts = <String, int>{};
    for (final stationType in assignments.values) {
      stationCounts[stationType] = (stationCounts[stationType] ?? 0) + 1;
    }
    
    double coverageEfficiency = 0.0;
    for (final entry in stationRequirements.entries) {
      final required = entry.value;
      final assigned = stationCounts[entry.key] ?? 0;
      
      if (required > 0) {
        coverageEfficiency += math.min(assigned / required, 1.0);
      }
    }
    
    metrics['stationCoverageEfficiency'] = stationRequirements.isNotEmpty ? 
        (coverageEfficiency / stationRequirements.length) * 100 : 0.0;
    
    // Risk assessment
    int totalRisks = 0;
    for (final entry in assignments.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final recommendations = aiRecommendations[serverId] ?? [];
      final recommendation = recommendations.firstWhereOrNull((r) => r.stationType == stationType);
      
      totalRisks += recommendation?.risks.length ?? 0;
    }
    
    metrics['totalRiskFactors'] = totalRisks.toDouble();
    metrics['riskPerAssignment'] = assignments.isNotEmpty ? totalRisks / assignments.length : 0.0;
    
    return metrics;
  }

  /// Calculate improvement percentage
  static double _calculateImprovementPercentage(
    PredictedSchedule basePrediction,
    Map<String, String> optimizedAssignments,
    Map<String, List<StationRecommendation>> aiRecommendations,
  ) {
    // Simplified improvement calculation
    final baseScore = basePrediction.predictedEfficiency;
    
    // Calculate optimized score (simplified)
    double optimizedScore = 0.0;
    int count = 0;
    
    for (final entry in optimizedAssignments.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final recommendations = aiRecommendations[serverId] ?? [];
      final recommendation = recommendations.firstWhereOrNull((r) => r.stationType == stationType);
      
      if (recommendation != null) {
        optimizedScore += recommendation.performanceScore;
        count++;
      }
    }
    
    if (count > 0) {
      optimizedScore /= count;
    }
    
    return baseScore > 0 ? ((optimizedScore - baseScore) / baseScore) * 100 : 0.0;
  }

  /// Generate fallback assignments
  static Map<String, String> _generateFallbackAssignments(List<String> serverIds) {
    final assignments = <String, String>{};
    final stations = ['Server', 'Host', 'Busser', 'Runner'];
    
    for (int i = 0; i < serverIds.length; i++) {
      assignments[serverIds[i]] = stations[i % stations.length];
    }
    
    return assignments;
  }

  /// Cache optimization result
  static Future<void> _cacheOptimization(ShiftOptimization optimization) async {
    try {
      final box = Storage.settingsBox;
      final key = 'optimization_${optimization.date.toIso8601String().split('T')[0]}_${optimization.shiftType}';
      await box.put(key, optimization.toJson());
    } catch (e) {
      print('[OPTIMIZER] Error caching optimization: $e');
    }
  }

  /// Get cached optimization
  static Future<ShiftOptimization?> getCachedOptimization(DateTime date, String shiftType) async {
    try {
      final box = Storage.settingsBox;
      final key = 'optimization_${date.toIso8601String().split('T')[0]}_$shiftType';
      final data = await box.get(key);
      
      if (data != null) {
        return ShiftOptimization.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      print('[OPTIMIZER] Error loading cached optimization: $e');
    }
    
    return null;
  }
}

/// Complete shift optimization result
class ShiftOptimization {
  final DateTime date;
  final String shiftType;
  final Map<String, String> originalAssignments;
  final Map<String, String> optimizedAssignments;
  final double optimizationScore; // 0-100
  final double improvementPercentage; // -100 to +100
  final List<OptimizationInsight> insights;
  final Map<String, double> metrics;
  final Map<String, List<StationRecommendation>> aiRecommendations;
  final DateTime generatedAt;
  final String algorithm;
  
  const ShiftOptimization({
    required this.date,
    required this.shiftType,
    required this.originalAssignments,
    required this.optimizedAssignments,
    required this.optimizationScore,
    required this.improvementPercentage,
    required this.insights,
    required this.metrics,
    required this.aiRecommendations,
    required this.generatedAt,
    required this.algorithm,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'shiftType': shiftType,
    'originalAssignments': originalAssignments,
    'optimizedAssignments': optimizedAssignments,
    'optimizationScore': optimizationScore,
    'improvementPercentage': improvementPercentage,
    'insights': insights.map((i) => i.toJson()).toList(),
    'metrics': metrics,
    'aiRecommendations': aiRecommendations.map(
      (k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()),
    ),
    'generatedAt': generatedAt.toIso8601String(),
    'algorithm': algorithm,
  };

  /// Create from JSON
  factory ShiftOptimization.fromJson(Map<String, dynamic> json) => ShiftOptimization(
    date: DateTime.parse(json['date']),
    shiftType: json['shiftType'],
    originalAssignments: Map<String, String>.from(json['originalAssignments']),
    optimizedAssignments: Map<String, String>.from(json['optimizedAssignments']),
    optimizationScore: json['optimizationScore'].toDouble(),
    improvementPercentage: json['improvementPercentage'].toDouble(),
    insights: (json['insights'] as List).map((i) => OptimizationInsight.fromJson(i)).toList(),
    metrics: Map<String, double>.from(json['metrics']),
    aiRecommendations: (json['aiRecommendations'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).map((r) => StationRecommendation.fromJson(r)).toList()),
    ),
    generatedAt: DateTime.parse(json['generatedAt']),
    algorithm: json['algorithm'],
  );

  /// Get optimization grade
  String get grade {
    if (optimizationScore >= 90) return 'A';
    if (optimizationScore >= 80) return 'B';
    if (optimizationScore >= 70) return 'C';
    if (optimizationScore >= 60) return 'D';
    return 'F';
  }

  /// Check if optimization is highly effective
  bool get isHighlyEffective => optimizationScore >= 85 && improvementPercentage >= 5;

  /// Get number of changes made
  int get numberOfChanges {
    int changes = 0;
    for (final entry in optimizedAssignments.entries) {
      if (originalAssignments[entry.key] != entry.value) {
        changes++;
      }
    }
    return changes;
  }
}

/// Optimization insight or recommendation
class OptimizationInsight {
  final String type; // 'optimization', 'warning', 'error', 'info'
  final String title;
  final String description;
  final double impact; // Expected impact (-100 to +100)
  final String recommendation;
  
  const OptimizationInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    required this.recommendation,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'description': description,
    'impact': impact,
    'recommendation': recommendation,
  };

  /// Create from JSON
  factory OptimizationInsight.fromJson(Map<String, dynamic> json) => OptimizationInsight(
    type: json['type'],
    title: json['title'],
    description: json['description'],
    impact: json['impact'].toDouble(),
    recommendation: json['recommendation'],
  );

  /// Get insight severity
  String get severity {
    if (impact.abs() >= 20) return 'high';
    if (impact.abs() >= 10) return 'medium';
    return 'low';
  }

  /// Check if this is a positive insight
  bool get isPositive => impact > 0;
}