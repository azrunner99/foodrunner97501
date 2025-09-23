/// Predictive Scheduling Engine
/// Core AI system for generating intelligent shift schedules and station assignments

import 'dart:math' as math;
import 'package:collection/collection.dart';

import '../models.dart';
import '../models/predictive_scheduling_models.dart';
import '../storage.dart';

class PredictiveSchedulingEngine {
  static const String _storageKeyProfiles = 'server_performance_profiles';
  static const String _storageKeyPatterns = 'historical_patterns';
  static const String _storageKeyConfig = 'scheduling_config';
  static const String _storageKeyPredictions = 'schedule_predictions';

  /// Generate a predicted schedule for a specific date and shift type
  static Future<PredictedSchedule> generateSchedule({
    required DateTime date,
    required String shiftType,
    required List<String> availableServerIds,
    SchedulingConfig? config,
  }) async {
    try {
      final effectiveConfig = config ?? await getSchedulingConfig();
      
      // Load historical data and server profiles
      final profiles = await getServerPerformanceProfiles();
      final patterns = await getHistoricalPatterns();
      
      // Predict station load for the target date/shift
      final stationLoadPredictions = await _predictStationLoad(date, shiftType, patterns);
      
      // Generate optimal server assignments
      final assignments = await _generateOptimalAssignments(
        availableServerIds,
        stationLoadPredictions,
        profiles,
        effectiveConfig,
        date,
        shiftType,
      );
      
      // Calculate confidence score
      final confidence = _calculateConfidenceScore(
        assignments,
        profiles,
        patterns,
        stationLoadPredictions,
      );
      
      // Generate insights and recommendations
      final insights = await _generateSchedulingInsights(
        assignments,
        profiles,
        stationLoadPredictions,
        effectiveConfig,
      );
      
      final prediction = PredictedSchedule(
        date: date,
        shiftType: shiftType,
        recommendedAssignments: assignments,
        confidenceScore: confidence,
        insights: insights,
        generatedAt: DateTime.now(),
        stationLoadPredictions: stationLoadPredictions,
      );
      
      // Cache the prediction
      await _cachePrediction(prediction);
      
      return prediction;
    } catch (e) {
      print('[PREDICTION] Error generating schedule: $e');
      
      // Return fallback schedule
      return PredictedSchedule(
        date: date,
        shiftType: shiftType,
        recommendedAssignments: _generateFallbackAssignments(availableServerIds),
        confidenceScore: 0.1,
        insights: [
          SchedulingInsight(
            type: 'warning',
            title: 'Prediction Failed',
            description: 'Using fallback assignments due to insufficient data',
            impact: -10.0,
            affectedServers: availableServerIds,
            suggestedAction: 'Collect more historical data for better predictions',
          ),
        ],
        generatedAt: DateTime.now(),
        stationLoadPredictions: {},
      );
    }
  }

  /// Predict station load based on historical patterns
  static Future<Map<String, double>> _predictStationLoad(
    DateTime date,
    String shiftType,
    List<HistoricalPattern> patterns,
  ) async {
    final stationLoad = <String, double>{};
    
    // Get day of week patterns
    final dayOfWeek = date.weekday;
    final weeklyPattern = patterns.firstWhereOrNull(
      (p) => p.patternType == 'weekly' && p.isRelevant,
    );
    
    // Get seasonal patterns
    final monthOfYear = date.month;
    final seasonalPattern = patterns.firstWhereOrNull(
      (p) => p.patternType == 'seasonal' && p.isRelevant,
    );
    
    // Default station types
    final defaultStations = ['Server', 'Host', 'Busser', 'Runner'];
    
    for (final stationType in defaultStations) {
      double load = 50.0; // Base load
      
      // Apply weekly pattern
      if (weeklyPattern != null) {
        final weeklyData = weeklyPattern.pattern['stations'] as Map<String, dynamic>?;
        if (weeklyData != null && weeklyData.containsKey(stationType)) {
          final dayData = weeklyData[stationType] as Map<String, dynamic>?;
          if (dayData != null && dayData.containsKey(dayOfWeek.toString())) {
            load *= (dayData[dayOfWeek.toString()] as num).toDouble();
          }
        }
      }
      
      // Apply seasonal pattern
      if (seasonalPattern != null) {
        final seasonalData = seasonalPattern.pattern['stations'] as Map<String, dynamic>?;
        if (seasonalData != null && seasonalData.containsKey(stationType)) {
          final monthData = seasonalData[stationType] as Map<String, dynamic>?;
          if (monthData != null && monthData.containsKey(monthOfYear.toString())) {
            load *= (monthData[monthOfYear.toString()] as num).toDouble();
          }
        }
      }
      
      // Apply shift type multiplier
      if (shiftType == 'Dinner') {
        load *= 1.3; // Dinner is typically busier
      }
      
      stationLoad[stationType] = load.clamp(10.0, 100.0);
    }
    
    return stationLoad;
  }

  /// Generate optimal server assignments using AI algorithms
  static Future<Map<String, String>> _generateOptimalAssignments(
    List<String> serverIds,
    Map<String, double> stationLoad,
    List<ServerPerformanceProfile> profiles,
    SchedulingConfig config,
    DateTime date,
    String shiftType,
  ) async {
    final assignments = <String, String>{};
    
    if (serverIds.isEmpty || stationLoad.isEmpty) {
      return assignments;
    }
    
    // Create server-station compatibility matrix
    final compatibility = <String, Map<String, double>>{};
    
    for (final serverId in serverIds) {
      final profile = profiles.firstWhereOrNull((p) => p.serverId == serverId);
      compatibility[serverId] = {};
      
      for (final stationType in stationLoad.keys) {
        double score = 50.0; // Base compatibility
        
        if (profile != null) {
          // Factor in efficiency at this station
          final efficiency = profile.getStationEfficiency(stationType);
          score = efficiency * config.performanceWeight;
          
          // Factor in experience
          final experience = profile.getStationExperience(stationType);
          final experienceBonus = math.min(experience * 2.0, 20.0);
          score += experienceBonus * config.experienceWeight;
          
          // Factor in time of day performance
          final timeMultiplier = profile.getTimePerformanceMultiplier(date);
          score *= timeMultiplier;
        }
        
        // Factor in station weight from config
        score *= config.getStationWeight(stationType);
        
        compatibility[serverId]![stationType] = score;
      }
    }
    
    // Use greedy assignment algorithm with load balancing
    final remainingServers = List<String>.from(serverIds);
    final stationAssignmentCounts = <String, int>{};
    
    // Initialize assignment counts
    for (final stationType in stationLoad.keys) {
      stationAssignmentCounts[stationType] = 0;
    }
    
    // Assign servers to stations
    while (remainingServers.isNotEmpty) {
      String? bestServer;
      String? bestStation;
      double bestScore = -1;
      
      for (final serverId in remainingServers) {
        for (final stationType in stationLoad.keys) {
          // Calculate need for this station based on load and current assignments
          final load = stationLoad[stationType]!;
          final currentAssignments = stationAssignmentCounts[stationType]!;
          final targetAssignments = (load / 25.0).ceil(); // Rough staffing calculation
          
          // Skip if station is already adequately staffed
          if (currentAssignments >= targetAssignments) continue;
          
          // Get compatibility score
          final compatibilityScore = compatibility[serverId]?[stationType] ?? 0.0;
          
          // Factor in urgency (how understaffed this station is)
          final urgency = (targetAssignments - currentAssignments) / targetAssignments.toDouble();
          final finalScore = compatibilityScore * (1.0 + urgency);
          
          if (finalScore > bestScore) {
            bestScore = finalScore;
            bestServer = serverId;
            bestStation = stationType;
          }
        }
      }
      
      // Make assignment
      if (bestServer != null && bestStation != null) {
        assignments[bestServer] = bestStation;
        stationAssignmentCounts[bestStation] = stationAssignmentCounts[bestStation]! + 1;
        remainingServers.remove(bestServer);
      } else {
        // Fallback: assign to least loaded station
        final leastLoadedStation = stationLoad.entries
            .map((e) => MapEntry(e.key, stationAssignmentCounts[e.key]! / e.value))
            .reduce((a, b) => a.value < b.value ? a : b)
            .key;
        
        assignments[remainingServers.removeAt(0)] = leastLoadedStation;
        stationAssignmentCounts[leastLoadedStation] = stationAssignmentCounts[leastLoadedStation]! + 1;
      }
    }
    
    return assignments;
  }

  /// Calculate confidence score for predictions
  static double _calculateConfidenceScore(
    Map<String, String> assignments,
    List<ServerPerformanceProfile> profiles,
    List<HistoricalPattern> patterns,
    Map<String, double> stationLoad,
  ) {
    if (assignments.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int count = 0;
    
    // Factor in server profile confidence
    for (final entry in assignments.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final profile = profiles.firstWhereOrNull((p) => p.serverId == serverId);
      if (profile != null) {
        final efficiency = profile.getStationEfficiency(stationType);
        final experience = profile.getStationExperience(stationType);
        
        // Higher efficiency and experience = higher confidence
        final profileConfidence = (efficiency / 100.0) * 0.7 + 
                                 (math.min(experience, 20) / 20.0) * 0.3;
        
        totalConfidence += profileConfidence;
        count++;
      }
    }
    
    // Factor in pattern confidence
    final patternConfidence = patterns.isEmpty ? 0.5 : 
        patterns.map((p) => p.confidence).reduce((a, b) => a + b) / patterns.length;
    
    // Calculate overall confidence
    final profileConfidence = count > 0 ? totalConfidence / count : 0.5;
    final overallConfidence = profileConfidence * 0.8 + patternConfidence * 0.2;
    
    return overallConfidence.clamp(0.0, 1.0);
  }

  /// Generate insights and recommendations for the schedule
  static Future<List<SchedulingInsight>> _generateSchedulingInsights(
    Map<String, String> assignments,
    List<ServerPerformanceProfile> profiles,
    Map<String, double> stationLoad,
    SchedulingConfig config,
  ) async {
    final insights = <SchedulingInsight>[];
    
    // Check for understaffed stations
    final stationCounts = <String, int>{};
    for (final stationType in assignments.values) {
      stationCounts[stationType] = (stationCounts[stationType] ?? 0) + 1;
    }
    
    for (final entry in stationLoad.entries) {
      final stationType = entry.key;
      final load = entry.value;
      final assigned = stationCounts[stationType] ?? 0;
      final recommended = (load / 25.0).ceil();
      
      if (assigned < recommended) {
        insights.add(SchedulingInsight(
          type: 'warning',
          title: 'Understaffed Station',
          description: '$stationType station may be understaffed (${assigned} assigned, ${recommended} recommended)',
          impact: -15.0 * (recommended - assigned),
          affectedServers: assignments.entries
              .where((e) => e.value == stationType)
              .map((e) => e.key)
              .toList(),
          suggestedAction: 'Consider assigning more servers to $stationType',
        ));
      } else if (assigned > recommended + 1) {
        insights.add(SchedulingInsight(
          type: 'optimization',
          title: 'Overstaffed Station',
          description: '$stationType station may be overstaffed (${assigned} assigned, ${recommended} recommended)',
          impact: -5.0 * (assigned - recommended),
          affectedServers: assignments.entries
              .where((e) => e.value == stationType)
              .map((e) => e.key)
              .toList(),
          suggestedAction: 'Consider reassigning servers from $stationType',
        ));
      }
    }
    
    // Check for servers assigned to non-preferred stations
    for (final entry in assignments.entries) {
      final serverId = entry.key;
      final stationType = entry.value;
      
      final profile = profiles.firstWhereOrNull((p) => p.serverId == serverId);
      if (profile != null && profile.preferredStations.isNotEmpty) {
        if (!profile.preferredStations.contains(stationType)) {
          final efficiency = profile.getStationEfficiency(stationType);
          
          if (efficiency < 70.0) {
            insights.add(SchedulingInsight(
              type: 'recommendation',
              title: 'Non-Optimal Assignment',
              description: 'Server may perform better at ${profile.preferredStations.first} (current efficiency: ${efficiency.toStringAsFixed(1)}%)',
              impact: 10.0,
              affectedServers: [serverId],
              suggestedAction: 'Consider assigning to preferred station if possible',
            ));
          }
        }
      }
    }
    
    return insights;
  }

  /// Generate fallback assignments when prediction fails
  static Map<String, String> _generateFallbackAssignments(List<String> serverIds) {
    final assignments = <String, String>{};
    final stations = ['Server', 'Host', 'Busser', 'Runner'];
    
    for (int i = 0; i < serverIds.length; i++) {
      assignments[serverIds[i]] = stations[i % stations.length];
    }
    
    return assignments;
  }

  /// Cache prediction for future reference
  static Future<void> _cachePrediction(PredictedSchedule prediction) async {
    try {
      final box = Storage.settingsBox;
      final key = 'prediction_${prediction.date.toIso8601String().split('T')[0]}_${prediction.shiftType}';
      await box.put(key, prediction.toJson());
    } catch (e) {
      print('[PREDICTION] Error caching prediction: $e');
    }
  }

  /// Get cached prediction if available
  static Future<PredictedSchedule?> getCachedPrediction(DateTime date, String shiftType) async {
    try {
      final box = Storage.settingsBox;
      final key = 'prediction_${date.toIso8601String().split('T')[0]}_$shiftType';
      final data = await box.get(key);
      
      if (data != null) {
        return PredictedSchedule.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      print('[PREDICTION] Error loading cached prediction: $e');
    }
    
    return null;
  }

  /// Update server performance profiles based on recent shift data
  static Future<void> updateServerPerformanceProfiles() async {
    try {
      // Load recent shift records
      final List<Map> rawRecords = 
          (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
      
      final allRecords = rawRecords.map((json) => ShiftRecord.fromMap(Map<String, dynamic>.from(json))).toList();
      
      // Filter to recent records (last 90 days)
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final recentRecords = allRecords.where((r) => r.start.isAfter(cutoffDate)).toList();
      
      final profiles = <String, ServerPerformanceProfile>{};
      
      // Analyze each server's performance
      final allServerIds = recentRecords
          .expand((r) => r.counts.keys)
          .toSet();
      
      for (final serverId in allServerIds) {
        final serverRecords = recentRecords.where((r) => r.counts.containsKey(serverId)).toList();
        
        if (serverRecords.isNotEmpty) {
          profiles[serverId] = await _buildServerProfile(serverId, serverRecords);
        }
      }
      
      // Save updated profiles
      final box = Storage.settingsBox;
      await box.put(_storageKeyProfiles, profiles.values.map((p) => p.toJson()).toList());
      
      print('[PREDICTION] Updated ${profiles.length} server performance profiles');
    } catch (e) {
      print('[PREDICTION] Error updating server profiles: $e');
    }
  }

  /// Build performance profile for a specific server
  static Future<ServerPerformanceProfile> _buildServerProfile(
    String serverId,
    List<ShiftRecord> records,
  ) async {
    final stationEfficiency = <String, double>{};
    final stationExperience = <String, int>{};
    final timePerformance = <String, double>{};
    
    // Analyze station performance
    for (final record in records) {
      if (record.stationAssignments?.containsKey(serverId) == true) {
        final stationType = record.stationAssignments![serverId]!;
        
        // Count experience
        stationExperience[stationType] = (stationExperience[stationType] ?? 0) + 1;
        
        // Calculate efficiency (simplified - could be more sophisticated)
        final serverTotal = record.counts[serverId] ?? 0;
        // Assume 4-hour shift as default since we don't have end time
        const shiftDuration = 4;
        final runsPerHour = serverTotal / shiftDuration.toDouble();
        
        // Normalize to 0-100 scale (assuming 5 runs/hour is 100%)
        final efficiency = (runsPerHour / 5.0 * 100.0).clamp(0.0, 100.0);
        
        final currentEfficiency = stationEfficiency[stationType] ?? 0.0;
        final currentCount = stationExperience[stationType]!;
        
        // Running average
        stationEfficiency[stationType] = 
            (currentEfficiency * (currentCount - 1) + efficiency) / currentCount;
      }
      
      // Analyze time of day performance
      final hour = record.start.hour.toString();
      final serverTotal = record.counts[serverId] ?? 0;
      // Assume 4-hour shift as default since we don't have end time
      const shiftDuration = 4;
      final performance = serverTotal / shiftDuration.toDouble();
      
      final currentPerf = timePerformance[hour] ?? 0.0;
      final hourRecords = records.where((r) => r.start.hour.toString() == hour).length;
      timePerformance[hour] = (currentPerf * (hourRecords - 1) + performance) / hourRecords;
    }
    
    // Calculate overall performance
    final avgEfficiency = stationEfficiency.values.isEmpty ? 50.0 :
        stationEfficiency.values.reduce((a, b) => a + b) / stationEfficiency.values.length;
    
    // Determine preferred stations (top 2 by efficiency)
    final sortedStations = stationEfficiency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredStations = sortedStations.take(2).map((e) => e.key).toList();
    
    return ServerPerformanceProfile(
      serverId: serverId,
      stationEfficiency: stationEfficiency,
      stationExperience: stationExperience,
      overallPerformance: avgEfficiency,
      preferredStations: preferredStations,
      timeOfDayPerformance: timePerformance,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get all server performance profiles
  static Future<List<ServerPerformanceProfile>> getServerPerformanceProfiles() async {
    try {
      final box = Storage.settingsBox;
      final data = await box.get(_storageKeyProfiles) as List?;
      
      if (data != null) {
        return data.map((json) => ServerPerformanceProfile.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      print('[PREDICTION] Error loading server profiles: $e');
    }
    
    return [];
  }

  /// Get historical patterns
  static Future<List<HistoricalPattern>> getHistoricalPatterns() async {
    try {
      final box = Storage.settingsBox;
      final data = await box.get(_storageKeyPatterns) as List?;
      
      if (data != null) {
        return data.map((json) => HistoricalPattern.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      print('[PREDICTION] Error loading historical patterns: $e');
    }
    
    return [];
  }

  /// Get scheduling configuration
  static Future<SchedulingConfig> getSchedulingConfig() async {
    try {
      final box = Storage.settingsBox;
      final data = await box.get(_storageKeyConfig);
      
      if (data != null) {
        return SchedulingConfig.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      print('[PREDICTION] Error loading scheduling config: $e');
    }
    
    return const SchedulingConfig();
  }

  /// Save scheduling configuration
  static Future<void> saveSchedulingConfig(SchedulingConfig config) async {
    try {
      final box = Storage.settingsBox;
      await box.put(_storageKeyConfig, config.toJson());
    } catch (e) {
      print('[PREDICTION] Error saving scheduling config: $e');
    }
  }
}