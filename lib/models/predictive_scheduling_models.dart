/// Predictive Scheduling Models
/// Data structures for AI-powered shift scheduling and optimization

/// Represents a predicted schedule for a specific day and shift type
class PredictedSchedule {
  final DateTime date;
  final String shiftType; // 'Lunch' or 'Dinner'
  final Map<String, String> recommendedAssignments; // serverId -> stationType
  final double confidenceScore; // 0.0 to 1.0
  final List<SchedulingInsight> insights;
  final DateTime generatedAt;
  final Map<String, double> stationLoadPredictions; // stationType -> predicted load
  
  const PredictedSchedule({
    required this.date,
    required this.shiftType,
    required this.recommendedAssignments,
    required this.confidenceScore,
    required this.insights,
    required this.generatedAt,
    required this.stationLoadPredictions,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'shiftType': shiftType,
    'recommendedAssignments': recommendedAssignments,
    'confidenceScore': confidenceScore,
    'insights': insights.map((i) => i.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
    'stationLoadPredictions': stationLoadPredictions,
  };

  /// Create from JSON
  factory PredictedSchedule.fromJson(Map<String, dynamic> json) => PredictedSchedule(
    date: DateTime.parse(json['date']),
    shiftType: json['shiftType'],
    recommendedAssignments: Map<String, String>.from(json['recommendedAssignments']),
    confidenceScore: json['confidenceScore'].toDouble(),
    insights: (json['insights'] as List).map((i) => SchedulingInsight.fromJson(i)).toList(),
    generatedAt: DateTime.parse(json['generatedAt']),
    stationLoadPredictions: Map<String, double>.from(json['stationLoadPredictions']),
  );

  /// Get predicted efficiency score for this schedule
  double get predictedEfficiency {
    if (recommendedAssignments.isEmpty) return 0.0;
    
    // Calculate weighted efficiency based on station load predictions
    double totalEfficiency = 0.0;
    double totalWeight = 0.0;
    
    for (final entry in stationLoadPredictions.entries) {
      final stationType = entry.key;
      final load = entry.value;
      final serversAssigned = recommendedAssignments.values.where((s) => s == stationType).length;
      
      // Higher load requires more servers, efficiency decreases if understaffed
      final staffingRatio = serversAssigned / (load / 100.0 + 1.0);
      final efficiency = (staffingRatio * 100.0).clamp(0.0, 100.0);
      
      totalEfficiency += efficiency * load;
      totalWeight += load;
    }
    
    return totalWeight > 0 ? totalEfficiency / totalWeight : 0.0;
  }
}

/// Represents an insight or recommendation from the scheduling algorithm
class SchedulingInsight {
  final String type; // 'optimization', 'warning', 'recommendation'
  final String title;
  final String description;
  final double impact; // Expected performance impact (-100 to +100)
  final List<String> affectedServers;
  final String? suggestedAction;
  
  const SchedulingInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    required this.affectedServers,
    this.suggestedAction,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'description': description,
    'impact': impact,
    'affectedServers': affectedServers,
    'suggestedAction': suggestedAction,
  };

  /// Create from JSON
  factory SchedulingInsight.fromJson(Map<String, dynamic> json) => SchedulingInsight(
    type: json['type'],
    title: json['title'],
    description: json['description'],
    impact: json['impact'].toDouble(),
    affectedServers: List<String>.from(json['affectedServers']),
    suggestedAction: json['suggestedAction'],
  );

  /// Get insight severity level
  String get severity {
    if (impact.abs() >= 20) return 'high';
    if (impact.abs() >= 10) return 'medium';
    return 'low';
  }

  /// Get appropriate icon for this insight type
  String get iconName {
    switch (type) {
      case 'optimization': return 'trending_up';
      case 'warning': return 'warning';
      case 'recommendation': return 'lightbulb';
      default: return 'info';
    }
  }
}

/// Represents historical pattern data used for predictions
class HistoricalPattern {
  final String patternType; // 'daily', 'weekly', 'seasonal'
  final Map<String, dynamic> pattern; // Flexible pattern data
  final double confidence; // 0.0 to 1.0
  final DateTime lastUpdated;
  final int sampleSize; // Number of data points used
  
  const HistoricalPattern({
    required this.patternType,
    required this.pattern,
    required this.confidence,
    required this.lastUpdated,
    required this.sampleSize,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'patternType': patternType,
    'pattern': pattern,
    'confidence': confidence,
    'lastUpdated': lastUpdated.toIso8601String(),
    'sampleSize': sampleSize,
  };

  /// Create from JSON
  factory HistoricalPattern.fromJson(Map<String, dynamic> json) => HistoricalPattern(
    patternType: json['patternType'],
    pattern: Map<String, dynamic>.from(json['pattern']),
    confidence: json['confidence'].toDouble(),
    lastUpdated: DateTime.parse(json['lastUpdated']),
    sampleSize: json['sampleSize'],
  );

  /// Check if pattern is still relevant (not too old)
  bool get isRelevant {
    final daysSinceUpdate = DateTime.now().difference(lastUpdated).inDays;
    switch (patternType) {
      case 'daily': return daysSinceUpdate <= 30;
      case 'weekly': return daysSinceUpdate <= 90;
      case 'seasonal': return daysSinceUpdate <= 365;
      default: return daysSinceUpdate <= 30;
    }
  }
}

/// Represents server performance metrics for prediction algorithms
class ServerPerformanceProfile {
  final String serverId;
  final Map<String, double> stationEfficiency; // stationType -> average efficiency
  final Map<String, int> stationExperience; // stationType -> shifts worked
  final double overallPerformance; // 0.0 to 100.0
  final List<String> preferredStations; // Stations where server performs best
  final Map<String, double> timeOfDayPerformance; // hour -> performance multiplier
  final DateTime lastUpdated;
  
  const ServerPerformanceProfile({
    required this.serverId,
    required this.stationEfficiency,
    required this.stationExperience,
    required this.overallPerformance,
    required this.preferredStations,
    required this.timeOfDayPerformance,
    required this.lastUpdated,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'stationEfficiency': stationEfficiency,
    'stationExperience': stationExperience,
    'overallPerformance': overallPerformance,
    'preferredStations': preferredStations,
    'timeOfDayPerformance': timeOfDayPerformance,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  /// Create from JSON
  factory ServerPerformanceProfile.fromJson(Map<String, dynamic> json) => ServerPerformanceProfile(
    serverId: json['serverId'],
    stationEfficiency: Map<String, double>.from(json['stationEfficiency']),
    stationExperience: Map<String, int>.from(json['stationExperience']),
    overallPerformance: json['overallPerformance'].toDouble(),
    preferredStations: List<String>.from(json['preferredStations']),
    timeOfDayPerformance: Map<String, double>.from(json['timeOfDayPerformance']),
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );

  /// Get server's efficiency for a specific station type
  double getStationEfficiency(String stationType) {
    return stationEfficiency[stationType] ?? overallPerformance;
  }

  /// Get server's experience level for a station type
  int getStationExperience(String stationType) {
    return stationExperience[stationType] ?? 0;
  }

  /// Check if server is experienced at a station type
  bool isExperiencedAt(String stationType) {
    return getStationExperience(stationType) >= 10; // 10+ shifts = experienced
  }

  /// Get performance multiplier for a specific time
  double getTimePerformanceMultiplier(DateTime time) {
    final hour = time.hour.toString();
    return timeOfDayPerformance[hour] ?? 1.0;
  }
}

/// Configuration for the predictive scheduling system
class SchedulingConfig {
  final double minConfidenceThreshold; // Minimum confidence to show predictions
  final int maxPredictionDays; // How far ahead to predict
  final Map<String, double> stationWeights; // Station importance weights
  final double experienceWeight; // How much to weight server experience
  final double performanceWeight; // How much to weight historical performance
  final bool enableAutoScheduling; // Whether to automatically apply high-confidence schedules
  
  const SchedulingConfig({
    this.minConfidenceThreshold = 0.7,
    this.maxPredictionDays = 14,
    this.stationWeights = const {},
    this.experienceWeight = 0.3,
    this.performanceWeight = 0.7,
    this.enableAutoScheduling = false,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'minConfidenceThreshold': minConfidenceThreshold,
    'maxPredictionDays': maxPredictionDays,
    'stationWeights': stationWeights,
    'experienceWeight': experienceWeight,
    'performanceWeight': performanceWeight,
    'enableAutoScheduling': enableAutoScheduling,
  };

  /// Create from JSON
  factory SchedulingConfig.fromJson(Map<String, dynamic> json) => SchedulingConfig(
    minConfidenceThreshold: json['minConfidenceThreshold']?.toDouble() ?? 0.7,
    maxPredictionDays: json['maxPredictionDays'] ?? 14,
    stationWeights: Map<String, double>.from(json['stationWeights'] ?? {}),
    experienceWeight: json['experienceWeight']?.toDouble() ?? 0.3,
    performanceWeight: json['performanceWeight']?.toDouble() ?? 0.7,
    enableAutoScheduling: json['enableAutoScheduling'] ?? false,
  );

  /// Get weight for a specific station type
  double getStationWeight(String stationType) {
    return stationWeights[stationType] ?? 1.0;
  }
}