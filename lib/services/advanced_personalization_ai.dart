import 'dart:math' as math;
import '../app_state.dart';
import 'server_personalization_service.dart';
import 'emotional_manipulation_service.dart';
import 'neurochemical_optimization_service.dart';

/// Behavioral prediction model types
enum PredictionModel {
  dropoutRisk,         // Likelihood of server quitting
  performanceDecline,  // Predicting performance drops
  engagementLoss,      // Loss of interest/motivation
  streakBreaker,       // Streak about to be broken
  burnoutWarning,      // Approaching burnout
  addictionPeak,       // Peak addiction moment
  competitiveSpike,    // About to become highly competitive
  mentorshipReady,     // Ready to help others
}

/// Intervention strategy types
enum InterventionStrategy {
  // Re-engagement strategies
  curiosityHook,       // Pique interest with mystery
  socialPressure,      // Use peer pressure
  fomo,               // Fear of missing out
  prideChallenge,     // Challenge their identity
  
  // Retention strategies
  personalRecord,     // Focus on beating personal bests
  teamDependency,     // Make them feel needed
  progressPath,       // Show clear advancement route
  achievementTease,   // Hint at upcoming rewards
  
  // Intensification strategies
  competitiveEscalation, // Amp up competition
  rewardAcceleration,    // Increase reward frequency
  socialValidation,      // Amplify social recognition
  identityReinforcement, // Strengthen role identity
}

/// Learning algorithm types
enum LearningAlgorithm {
  reinforcementLearning, // Trial and error optimization
  patternRecognition,    // Identify behavior patterns
  predictiveModeling,    // Forecast future behavior
  adaptivePersonalization, // Dynamic personality adjustment
  contextualBandits,     // Context-aware optimization
}

/// Behavioral prediction result
class BehaviorPrediction {
  final String serverId;
  final PredictionModel model;
  final double confidence; // 0.0 to 1.0
  final DateTime predictedTime;
  final Map<String, dynamic> factors;
  final String description;
  final InterventionStrategy? recommendedIntervention;
  
  BehaviorPrediction({
    required this.serverId,
    required this.model,
    required this.confidence,
    required this.predictedTime,
    required this.factors,
    required this.description,
    this.recommendedIntervention,
  });
}

/// Adaptive intervention event
class AdaptiveIntervention {
  final String serverId;
  final InterventionStrategy strategy;
  final String trigger;
  final String message;
  final Map<String, dynamic> parameters;
  final DateTime deployTime;
  final double expectedEffectiveness;
  bool wasEffective = false;
  double? actualEffectiveness;
  
  AdaptiveIntervention({
    required this.serverId,
    required this.strategy,
    required this.trigger,
    required this.message,
    required this.parameters,
    required this.deployTime,
    required this.expectedEffectiveness,
  });
}

/// Learning algorithm performance tracker
class LearningMetrics {
  final LearningAlgorithm algorithm;
  final Map<String, double> accuracyScores = {};
  final Map<String, int> predictionCounts = {};
  final Map<String, List<double>> recentPerformance = {};
  DateTime lastUpdate = DateTime.now();
  
  LearningMetrics({required this.algorithm});
  
  double get overallAccuracy {
    if (accuracyScores.isEmpty) return 0.0;
    return accuracyScores.values.reduce((a, b) => a + b) / accuracyScores.length;
  }
  
  void recordPrediction(String predictionType, bool wasCorrect) {
    predictionCounts[predictionType] = (predictionCounts[predictionType] ?? 0) + 1;
    
    final currentAccuracy = accuracyScores[predictionType] ?? 0.5;
    final weight = 0.1; // Learning rate
    accuracyScores[predictionType] = currentAccuracy * (1 - weight) + 
      (wasCorrect ? 1.0 : 0.0) * weight;
    
    // Track recent performance
    recentPerformance.putIfAbsent(predictionType, () => []).add(wasCorrect ? 1.0 : 0.0);
    if (recentPerformance[predictionType]!.length > 10) {
      recentPerformance[predictionType]!.removeAt(0);
    }
    
    lastUpdate = DateTime.now();
  }
}

/// Advanced personalization AI service
class AdvancedPersonalizationAI {
  static final Map<String, List<BehaviorPrediction>> _serverPredictions = {};
  static final Map<String, List<AdaptiveIntervention>> _serverInterventions = {};
  static final Map<LearningAlgorithm, LearningMetrics> _learningMetrics = {};
  static final Map<String, Map<String, dynamic>> _serverBehaviorModels = {};
  static final math.Random _random = math.Random();
  
  /// Generate behavioral predictions for a server
  static List<BehaviorPrediction> generateBehaviorPredictions(String serverId, AppState app) {
    final predictions = <BehaviorPrediction>[];
    final profile = app.profiles[serverId];
    if (profile == null) return predictions;
    
    // Analyze current behavioral patterns
    final behaviorModel = _analyzeServerBehavior(serverId, app);
    _serverBehaviorModels[serverId] = behaviorModel;
    
    // Generate predictions for each model type
    for (final model in PredictionModel.values) {
      final prediction = _generatePrediction(serverId, model, behaviorModel, app);
      if (prediction != null && prediction.confidence > 0.3) {
        predictions.add(prediction);
      }
    }
    
    // Store predictions for tracking accuracy
    _serverPredictions[serverId] = predictions;
    
    return predictions;
  }
  
  /// Deploy adaptive intervention based on predictions
  static AdaptiveIntervention? deployAdaptiveIntervention(
    String serverId,
    BehaviorPrediction prediction,
    AppState app,
  ) {
    if (prediction.recommendedIntervention == null) return null;
    
    final strategy = prediction.recommendedIntervention!;
    final intervention = _createAdaptiveIntervention(serverId, strategy, prediction, app);
    
    // Store for effectiveness tracking
    _serverInterventions.putIfAbsent(serverId, () => []).add(intervention);
    
    // Apply intervention to server profile
    _applyInterventionEffects(intervention, app);
    
    return intervention;
  }
  
  /// Update learning algorithms based on intervention effectiveness
  static void updateLearningAlgorithms(String serverId, AppState app) {
    final interventions = _serverInterventions[serverId] ?? [];
    
    for (final intervention in interventions) {
      if (intervention.actualEffectiveness == null) {
        // Measure effectiveness based on server response
        intervention.actualEffectiveness = _measureInterventionEffectiveness(intervention, app);
        intervention.wasEffective = intervention.actualEffectiveness! > 0.6;
        
        // Update learning metrics
        _updateLearningMetrics(intervention);
      }
    }
    
    // Update prediction accuracy
    _updatePredictionAccuracy(serverId, app);
  }
  
  /// Generate personality-based addiction strategy
  static Map<String, dynamic> generateAddictionStrategy(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return {};
    
    final personality = ServerPersonalizationService.analyzeServerPersonality(serverId, profile);
    final archetype = EmotionalManipulationService.analyzeAndUpdateArchetype(serverId, app);
    final dopamineState = NeurochemicalOptimizationService.analyzeDopaminePatterns(serverId);
    
    // Create personalized addiction strategy
    final strategy = <String, dynamic>{
      'primaryHooks': _identifyPrimaryHooks(personality, archetype),
      'rewardSchedule': _optimizeRewardSchedule(dopamineState, personality),
      'emotionalTriggers': _selectEmotionalTriggers(personality, archetype),
      'socialDynamics': _configureSocialDynamics(personality, app),
      'interventionTimings': _calculateOptimalInterventions(serverId, app),
      'personalizationLevel': _calculatePersonalizationLevel(serverId, app),
    };
    
    return strategy;
  }
  
  /// Predict optimal intervention timing
  static DateTime? predictOptimalInterventionTime(String serverId, AppState app) {
    final behaviorModel = _serverBehaviorModels[serverId];
    if (behaviorModel == null) return null;
    
    // Analyze patterns to predict best intervention time
    final recentTrend = behaviorModel['recentTrend'] as double? ?? 0.0;
    
    // If performance declining, intervene sooner
    if (recentTrend < -0.1) {
      return DateTime.now().add(Duration(minutes: 10));
    }
    
    // If performance stable/improving, wait for optimal dopamine state
    final dopamineAnalysis = NeurochemicalOptimizationService.analyzeDopaminePatterns(serverId);
    final isOptimalState = dopamineAnalysis['isOptimalState'] as bool? ?? false;
    
    if (isOptimalState) {
      return DateTime.now().add(Duration(minutes: 2));
    } else {
      final optimalWait = dopamineAnalysis['optimalNextReward'] as int? ?? 300;
      return DateTime.now().add(Duration(seconds: optimalWait));
    }
  }
  
  /// Analyze learning algorithm performance
  static Map<String, dynamic> analyzeLearningPerformance() {
    final analysis = <String, dynamic>{};
    
    for (final entry in _learningMetrics.entries) {
      final algorithm = entry.key;
      final metrics = entry.value;
      
      analysis[algorithm.toString()] = {
        'overallAccuracy': metrics.overallAccuracy,
        'totalPredictions': metrics.predictionCounts.values.fold(0, (a, b) => a + b),
        'recentTrend': _calculateRecentTrend(metrics),
        'confidence': _calculateConfidence(metrics),
      };
    }
    
    return analysis;
  }
  
  /// Generate adaptive personality profile adjustments
  static Map<String, double> generatePersonalityAdjustments(String serverId, AppState app) {
    final currentPersonality = _serverBehaviorModels[serverId];
    if (currentPersonality == null) return {};
    
    final interventions = _serverInterventions[serverId] ?? [];
    final adjustments = <String, double>{};
    
    // Analyze which personality aspects led to successful interventions
    for (final intervention in interventions) {
      if (intervention.wasEffective) {
        // Strengthen traits that led to success
        final strategy = intervention.strategy;
        switch (strategy) {
          case InterventionStrategy.competitiveEscalation:
            adjustments['competitiveness'] = (adjustments['competitiveness'] ?? 0.0) + 0.1;
            break;
          case InterventionStrategy.socialValidation:
            adjustments['social_motivation'] = (adjustments['social_motivation'] ?? 0.0) + 0.1;
            break;
          case InterventionStrategy.personalRecord:
            adjustments['achievement_drive'] = (adjustments['achievement_drive'] ?? 0.0) + 0.1;
            break;
          default:
            break;
        }
      }
    }
    
    // Normalize adjustments
    for (final key in adjustments.keys) {
      adjustments[key] = adjustments[key]!.clamp(-0.5, 0.5);
    }
    
    return adjustments;
  }
  
  /// Analyze server behavior patterns
  static Map<String, dynamic> _analyzeServerBehavior(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return {};
    
    // Dual-context data gathering
    final currentRuns = app.currentCounts[serverId] ?? 0;
    final allTimeRuns = profile.allTimeRuns;
    final bestShiftRuns = profile.bestShiftRuns;
    final recentTapTimes = profile.recentTapTimes;
    final isShiftActive = app.shiftActive;
    final isWorkingToday = app.workingServerIds.contains(serverId);
    
    // Calculate behavioral metrics with career context
    final consistencyScore = _calculateConsistency(recentTapTimes);
    final speedTrend = _calculateSpeedTrend(recentTapTimes);
    final performanceTrend = _calculateDualContextPerformanceTrend(serverId, app);
    final engagementLevel = _calculateDualContextEngagementLevel(serverId, app);
    final careerMomentum = _calculateCareerMomentum(profile);
    final shiftVsCareerRatio = bestShiftRuns > 0 ? currentRuns / bestShiftRuns : 0.0;
    
    return {
      'consistencyScore': consistencyScore,
      'speedTrend': speedTrend,
      'performanceTrend': performanceTrend,
      'engagementLevel': engagementLevel,
      'careerMomentum': careerMomentum,
      'shiftVsCareerRatio': shiftVsCareerRatio,
      'averagePerformance': currentRuns / 20.0, // Normalize current
      'careerAveragePerformance': allTimeRuns > 0 ? allTimeRuns / 1000.0 : 0.0, // Normalize career
      'recentTrend': performanceTrend,
      'lastActivity': profile.lastTapIso != null ? 
        DateTime.parse(profile.lastTapIso!) : DateTime.now(),
      'isShiftActive': isShiftActive,
      'isWorkingToday': isWorkingToday,
      'currentRuns': currentRuns,
      'allTimeRuns': allTimeRuns,
      'bestShiftRuns': bestShiftRuns,
      'careerLevel': _determineCareerLevel(profile),
    };
  }
  
  /// Generate prediction for specific model
  static BehaviorPrediction? _generatePrediction(
    String serverId,
    PredictionModel model,
    Map<String, dynamic> behaviorModel,
    AppState app,
  ) {
    final profile = app.profiles[serverId];
    if (profile == null) return null;
    
    double confidence = 0.0;
    DateTime predictedTime = DateTime.now();
    Map<String, dynamic> factors = {};
    String description = '';
    InterventionStrategy? intervention;
    
    switch (model) {
      case PredictionModel.dropoutRisk:
        final engagementLevel = behaviorModel['engagementLevel'] as double? ?? 0.5;
        final recentTrend = behaviorModel['recentTrend'] as double? ?? 0.0;
        final isWorkingToday = behaviorModel['isWorkingToday'] as bool? ?? false;
        final careerMomentum = behaviorModel['careerMomentum'] as double? ?? 0.5;
        
        // Higher risk if not working today or low career momentum
        final workingBonus = isWorkingToday ? 0.0 : 0.3;
        final careerPenalty = careerMomentum < 0.3 ? 0.2 : 0.0;
        
        confidence = (1.0 - engagementLevel) * 0.7 + 
                    (recentTrend < -0.2 ? 0.3 : 0.0) + 
                    workingBonus + careerPenalty;
        predictedTime = DateTime.now().add(Duration(hours: isWorkingToday ? 1 : 4));
        description = isWorkingToday ? 
          'Server showing signs of shift disengagement' : 
          'Server not working today - high dropout risk';
        intervention = InterventionStrategy.curiosityHook;
        factors = {
          'engagement': engagementLevel, 
          'trend': recentTrend, 
          'workingToday': isWorkingToday,
          'careerMomentum': careerMomentum,
        };
        break;
        
      case PredictionModel.performanceDecline:
        final performanceTrend = behaviorModel['performanceTrend'] as double? ?? 0.0;
        final consistencyScore = behaviorModel['consistencyScore'] as double? ?? 0.5;
        final shiftVsCareerRatio = behaviorModel['shiftVsCareerRatio'] as double? ?? 0.5;
        final careerLevel = behaviorModel['careerLevel'] as String? ?? 'rookie';
        
        // Veterans underperforming their standards should get higher confidence
        final veteranUnderperformance = (careerLevel == 'veteran' || careerLevel == 'legend') && shiftVsCareerRatio < 0.5;
        
        confidence = performanceTrend < -0.1 ? 0.8 : 0.2;
        if (veteranUnderperformance) confidence += 0.3;
        
        predictedTime = DateTime.now().add(Duration(minutes: veteranUnderperformance ? 15 : 30));
        description = veteranUnderperformance ? 
          'Veteran performer underperforming career standards' : 
          'Performance metrics indicate upcoming decline';
        intervention = veteranUnderperformance ? InterventionStrategy.prideChallenge : InterventionStrategy.personalRecord;
        factors = {
          'trend': performanceTrend, 
          'consistency': consistencyScore,
          'shiftVsCareer': shiftVsCareerRatio,
          'careerLevel': careerLevel,
        };
        break;
        
      case PredictionModel.addictionPeak:
        final dopamineAnalysis = NeurochemicalOptimizationService.analyzeDopaminePatterns(serverId);
        final addictionScore = dopamineAnalysis['addictionScore'] as double? ?? 0.0;
        final isShiftActive = behaviorModel['isShiftActive'] as bool? ?? false;
        final currentRuns = behaviorModel['currentRuns'] as int? ?? 0;
        
        // Higher addiction peaks during active shifts with good performance
        final shiftBonus = isShiftActive && currentRuns > 5 ? 0.2 : 0.0;
        
        confidence = (addictionScore + shiftBonus).clamp(0.0, 1.0);
        predictedTime = DateTime.now().add(Duration(minutes: isShiftActive ? 3 : 8));
        description = isShiftActive ? 
          'Server approaching peak addiction state during active shift' : 
          'Server showing addiction patterns while off-shift';
        intervention = InterventionStrategy.rewardAcceleration;
        factors = {
          'addictionScore': addictionScore,
          'shiftActive': isShiftActive,
          'currentRuns': currentRuns,
        };
        break;
        
      default:
        confidence = 0.3;
        predictedTime = DateTime.now().add(Duration(hours: 1));
        description = 'General behavioral prediction';
        factors = {};
    }
    
    if (confidence < 0.1) return null;
    
    return BehaviorPrediction(
      serverId: serverId,
      model: model,
      confidence: confidence.clamp(0.0, 1.0),
      predictedTime: predictedTime,
      factors: factors,
      description: description,
      recommendedIntervention: intervention,
    );
  }
  
  /// Create adaptive intervention
  static AdaptiveIntervention _createAdaptiveIntervention(
    String serverId,
    InterventionStrategy strategy,
    BehaviorPrediction prediction,
    AppState app,
  ) {
    late String message;
    late Map<String, dynamic> parameters;
    late double expectedEffectiveness;
    
    switch (strategy) {
      case InterventionStrategy.curiosityHook:
        message = "🔮 Something mysterious is happening... Are you ready to discover what?";
        parameters = {'mystery_level': 0.8, 'urgency': 0.6};
        expectedEffectiveness = 0.7;
        break;
        
      case InterventionStrategy.socialPressure:
        message = "👀 Everyone is watching to see what you'll do next...";
        parameters = {'social_intensity': 0.9, 'competitive_edge': 0.8};
        expectedEffectiveness = 0.8;
        break;
        
      case InterventionStrategy.fomo:
        message = "⏰ LIMITED TIME! This opportunity won't last forever!";
        parameters = {'urgency': 1.0, 'scarcity': 0.9};
        expectedEffectiveness = 0.6;
        break;
        
      case InterventionStrategy.prideChallenge:
        message = "🏆 A true champion wouldn't let this moment pass by...";
        parameters = {'identity_challenge': 0.9, 'pride_trigger': 0.8};
        expectedEffectiveness = 0.9;
        break;
        
      case InterventionStrategy.personalRecord:
        message = "📈 Your personal best is within reach! One more push!";
        parameters = {'goal_proximity': 0.8, 'personal_relevance': 1.0};
        expectedEffectiveness = 0.7;
        break;
        
      default:
        message = "⚡ Perfect timing for something amazing!";
        parameters = {'general_motivation': 0.6};
        expectedEffectiveness = 0.5;
    }
    
    return AdaptiveIntervention(
      serverId: serverId,
      strategy: strategy,
      trigger: prediction.description,
      message: message,
      parameters: parameters,
      deployTime: DateTime.now(),
      expectedEffectiveness: expectedEffectiveness,
    );
  }
  
  /// Apply intervention effects to server profile
  static void _applyInterventionEffects(AdaptiveIntervention intervention, AppState app) {
    final profile = app.profiles[intervention.serverId];
    if (profile == null) return;
    
    // Immediate XP bonus based on intervention strength
    final bonusXP = (intervention.expectedEffectiveness * 50).round();
    profile.points += bonusXP;
    
    // Adjust personality traits based on intervention type
    switch (intervention.strategy) {
      case InterventionStrategy.competitiveEscalation:
        profile.competitiveLevel = (profile.competitiveLevel + 0.1).clamp(0.0, 1.0);
        break;
      case InterventionStrategy.socialValidation:
        profile.socialLevel = (profile.socialLevel + 0.1).clamp(0.0, 1.0);
        break;
      case InterventionStrategy.personalRecord:
        profile.achievementDrive = (profile.achievementDrive + 0.1).clamp(0.0, 1.0);
        break;
      default:
        break;
    }
  }
  
  /// Measure intervention effectiveness
  static double _measureInterventionEffectiveness(AdaptiveIntervention intervention, AppState app) {
    final profile = app.profiles[intervention.serverId];
    if (profile == null) return 0.0;
    
    final timeSinceIntervention = DateTime.now().difference(intervention.deployTime);
    if (timeSinceIntervention.inMinutes > 30) return 0.0; // Too late to measure
    
    // Check for positive response indicators
    final currentRuns = app.currentCounts[intervention.serverId] ?? 0;
    final recentActivity = profile.lastTapIso != null ? 
      DateTime.now().difference(DateTime.parse(profile.lastTapIso!)).inMinutes : 999;
    
    double effectiveness = 0.0;
    
    // Recent activity indicates engagement
    if (recentActivity < 10) effectiveness += 0.4;
    
    // Current runs indicate response
    if (currentRuns > 0) effectiveness += 0.3;
    
    // Add randomness to simulate varied human responses
    effectiveness += _random.nextDouble() * 0.3;
    
    return effectiveness.clamp(0.0, 1.0);
  }
  
  /// Update learning metrics
  static void _updateLearningMetrics(AdaptiveIntervention intervention) {
    final algorithm = LearningAlgorithm.reinforcementLearning; // Default algorithm
    final metrics = _learningMetrics.putIfAbsent(algorithm, () => LearningMetrics(algorithm: algorithm));
    
    final wasSuccessful = intervention.actualEffectiveness! > intervention.expectedEffectiveness * 0.8;
    metrics.recordPrediction(intervention.strategy.toString(), wasSuccessful);
  }
  
  /// Update prediction accuracy
  static void _updatePredictionAccuracy(String serverId, AppState app) {
    final predictions = _serverPredictions[serverId] ?? [];
    
    for (final prediction in predictions) {
      final timeSincePrediction = DateTime.now().difference(prediction.predictedTime).abs();
      if (timeSincePrediction.inHours < 1) { // Within prediction window
        // Check if prediction came true
        final cameTrue = _checkPredictionAccuracy(prediction, app);
        
        final algorithm = LearningAlgorithm.predictiveModeling;
        final metrics = _learningMetrics.putIfAbsent(algorithm, () => LearningMetrics(algorithm: algorithm));
        metrics.recordPrediction(prediction.model.toString(), cameTrue);
      }
    }
  }
  
  /// Check if prediction was accurate
  static bool _checkPredictionAccuracy(BehaviorPrediction prediction, AppState app) {
    final profile = app.profiles[prediction.serverId];
    if (profile == null) return false;
    
    switch (prediction.model) {
      case PredictionModel.dropoutRisk:
        final lastActivity = profile.lastTapIso != null ? 
          DateTime.parse(profile.lastTapIso!) : DateTime.now().subtract(Duration(days: 1));
        return DateTime.now().difference(lastActivity).inHours > 1;
        
      case PredictionModel.performanceDecline:
        final currentRuns = app.currentCounts[prediction.serverId] ?? 0;
        return currentRuns < 5; // Simple decline indicator
        
      case PredictionModel.addictionPeak:
        final dopamineAnalysis = NeurochemicalOptimizationService.analyzeDopaminePatterns(prediction.serverId);
        return (dopamineAnalysis['addictionScore'] as double? ?? 0.0) > 0.8;
        
      default:
        return false;
    }
  }
  
  /// Calculate behavioral consistency
  static double _calculateConsistency(List<DateTime> tapTimes) {
    if (tapTimes.length < 3) return 0.5;
    
    final intervals = <double>[];
    for (int i = 1; i < tapTimes.length; i++) {
      intervals.add(tapTimes[i].difference(tapTimes[i-1]).inSeconds.toDouble());
    }
    
    if (intervals.isEmpty) return 0.5;
    
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / intervals.length;
    final standardDeviation = math.sqrt(variance);
    
    // Lower standard deviation = higher consistency
    return (1.0 / (1.0 + standardDeviation / mean)).clamp(0.0, 1.0);
  }
  
  /// Calculate speed trend
  static double _calculateSpeedTrend(List<DateTime> tapTimes) {
    if (tapTimes.length < 4) return 0.0;
    
    final recentIntervals = <double>[];
    final olderIntervals = <double>[];
    
    final midpoint = tapTimes.length ~/ 2;
    
    for (int i = 1; i < midpoint; i++) {
      olderIntervals.add(tapTimes[i].difference(tapTimes[i-1]).inSeconds.toDouble());
    }
    
    for (int i = midpoint; i < tapTimes.length; i++) {
      recentIntervals.add(tapTimes[i].difference(tapTimes[i-1]).inSeconds.toDouble());
    }
    
    if (olderIntervals.isEmpty || recentIntervals.isEmpty) return 0.0;
    
    final oldAvg = olderIntervals.reduce((a, b) => a + b) / olderIntervals.length;
    final recentAvg = recentIntervals.reduce((a, b) => a + b) / recentIntervals.length;
    
    // Negative trend = getting faster (lower intervals)
    return (oldAvg - recentAvg) / oldAvg;
  }
  
  /// Calculate recent trend for learning metrics
  static double _calculateRecentTrend(LearningMetrics metrics) {
    double totalTrend = 0.0;
    int trendCount = 0;
    
    for (final recent in metrics.recentPerformance.values) {
      if (recent.length >= 3) {
        final first = recent.take(recent.length ~/ 2).reduce((a, b) => a + b) / (recent.length ~/ 2);
        final second = recent.skip(recent.length ~/ 2).reduce((a, b) => a + b) / (recent.length - recent.length ~/ 2);
        totalTrend += second - first;
        trendCount++;
      }
    }
    
    return trendCount > 0 ? totalTrend / trendCount : 0.0;
  }
  
  /// Calculate confidence for learning metrics
  static double _calculateConfidence(LearningMetrics metrics) {
    if (metrics.predictionCounts.isEmpty) return 0.0;
    
    final totalPredictions = metrics.predictionCounts.values.reduce((a, b) => a + b);
    final confidence = metrics.overallAccuracy * (1.0 - math.exp(-totalPredictions / 10.0));
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Identify primary psychological hooks
  static List<String> _identifyPrimaryHooks(ServerPersonality personality, ServerArchetype archetype) {
    final hooks = <String>[];
    
    // Based on dominant patterns
    for (final pattern in personality.dominantPatterns) {
      switch (pattern) {
        case BehaviorPattern.competitiveShark:
          hooks.add('competition');
          hooks.add('ranking');
          break;
        case BehaviorPattern.speedDemon:
          hooks.add('speed_challenges');
          hooks.add('time_pressure');
          break;
        case BehaviorPattern.steadyEddie:
          hooks.add('streak_maintenance');
          hooks.add('reliability_rewards');
          break;
        default:
          break;
      }
    }
    
    return hooks.isNotEmpty ? hooks : ['general_achievement'];
  }
  
  /// Optimize reward schedule
  static Map<String, dynamic> _optimizeRewardSchedule(
    Map<String, dynamic> dopamineState, 
    ServerPersonality personality,
  ) {
    final currentPhase = dopamineState['currentPhase']?.toString() ?? '';
    final addictionScore = dopamineState['addictionScore'] as double? ?? 0.0;
    
    return {
      'frequency': addictionScore > 0.7 ? 'high' : 'medium',
      'variability': 'high', // Always keep variability high
      'magnitude': currentPhase.contains('peak') ? 'large' : 'medium',
      'timing': dopamineState['optimalNextReward'] ?? 300,
    };
  }
  
  /// Select emotional triggers
  static List<String> _selectEmotionalTriggers(ServerPersonality personality, ServerArchetype archetype) {
    final triggers = <String>[];
    
    // Based on personality traits
    for (final trait in personality.traitScores.keys) {
      switch (trait) {
        case PersonalityTrait.competition:
          triggers.add('pride');
          triggers.add('superiority');
          break;
        case PersonalityTrait.social:
          triggers.add('belonging');
          triggers.add('validation');
          break;
        case PersonalityTrait.achievement:
          triggers.add('identity');
          triggers.add('purpose');
          break;
        default:
          break;
      }
    }
    
    return triggers.isNotEmpty ? triggers : ['general_motivation'];
  }
  
  /// Configure social dynamics
  static Map<String, dynamic> _configureSocialDynamics(ServerPersonality personality, AppState app) {
    return {
      'peer_pressure_sensitivity': (personality.traitScores[PersonalityTrait.social] ?? 0.5) > 0.7 ? 0.8 : 0.4,
      'competitive_messaging': personality.dominantPatterns.contains(BehaviorPattern.competitiveShark) ? 0.9 : 0.5,
      'team_dependency': (personality.traitScores[PersonalityTrait.social] ?? 0.5) > 0.6 ? 0.8 : 0.3,
      'social_validation_need': (personality.traitScores[PersonalityTrait.recognition] ?? 0.5) > 0.7 ? 0.9 : 0.4,
    };
  }
  
  /// Calculate optimal interventions
  static List<Map<String, dynamic>> _calculateOptimalInterventions(String serverId, AppState app) {
    return [
      {
        'type': 'predictive',
        'timing': DateTime.now().add(Duration(minutes: 15)),
        'confidence': 0.7,
      },
      {
        'type': 'preventive',
        'timing': DateTime.now().add(Duration(hours: 1)),
        'confidence': 0.5,
      },
    ];
  }
  
  /// Calculate personalization level
  static double _calculatePersonalizationLevel(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return 0.0;
    
    // Higher personalization based on data richness
    final dataPoints = profile.milestoneHistory.length + 
                      profile.recentTapTimes.length + 
                      profile.behaviorPatterns.length;
    
    return (dataPoints / 50.0).clamp(0.0, 1.0);
  }
  
  /// Calculate dual-context performance trend
  static double _calculateDualContextPerformanceTrend(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return 0.0;
    
    final currentRuns = app.currentCounts[serverId] ?? 0;
    final bestShiftRuns = profile.bestShiftRuns;
    final allTimeAvg = profile.allTimeRuns > 0 ? profile.allTimeRuns / 100.0 : 10.0; // Estimated shifts
    
    // Compare current performance to both personal best and career average
    final vsBestRatio = bestShiftRuns > 0 ? currentRuns / bestShiftRuns : 0.5;
    final vsCareerAvgRatio = currentRuns / allTimeAvg;
    
    // Weight recent performance more heavily, but consider career context
    return (vsBestRatio * 0.6 + vsCareerAvgRatio * 0.4 - 0.5).clamp(-1.0, 1.0);
  }
  
  /// Calculate dual-context engagement level
  static double _calculateDualContextEngagementLevel(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return 0.0;
    
    final currentRuns = app.currentCounts[serverId] ?? 0;
    final recentTaps = profile.recentTapTimes.length;
    final points = profile.points;
    final allTimeRuns = profile.allTimeRuns;
    final isWorkingToday = app.workingServerIds.contains(serverId);
    
    // Current shift engagement indicators
    final currentEngagement = [
      (currentRuns / 20.0).clamp(0.0, 1.0),
      (recentTaps / 10.0).clamp(0.0, 1.0),
      isWorkingToday ? 1.0 : 0.0,
    ].reduce((a, b) => a + b) / 3.0;
    
    // Career engagement indicators
    final careerEngagement = [
      (points / 5000.0).clamp(0.0, 1.0),
      (allTimeRuns / 2000.0).clamp(0.0, 1.0),
      (profile.achievements.length / 20.0).clamp(0.0, 1.0),
    ].reduce((a, b) => a + b) / 3.0;
    
    // Weighted combination emphasizing current engagement with career context
    return currentEngagement * 0.7 + careerEngagement * 0.3;
  }
  
  /// Calculate career momentum
  static double _calculateCareerMomentum(ServerProfile profile) {
    final recentPerformance = profile.performanceHistory.isNotEmpty ? 
      profile.performanceHistory.last['runs'] as int? ?? 0 : 0;
    final allTimeAvg = profile.allTimeRuns > 0 ? profile.allTimeRuns / 100.0 : 10.0;
    
    // Recent achievements and point gains indicate momentum
    final recentAchievements = profile.achievements.length;
    final pointMomentum = profile.points > 1000 ? 0.8 : 0.4;
    
    // Performance trajectory
    final performanceMomentum = recentPerformance > allTimeAvg ? 0.8 : 0.3;
    
    return ((pointMomentum + performanceMomentum) / 2.0 + recentAchievements / 50.0).clamp(0.0, 1.0);
  }
  
  /// Determine career level for psychological messaging
  static String _determineCareerLevel(ServerProfile profile) {
    if (profile.allTimeRuns > 2000 && profile.points > 10000) {
      return 'legend';
    } else if (profile.allTimeRuns > 1000 && profile.points > 5000) {
      return 'veteran';
    } else if (profile.allTimeRuns > 500 && profile.points > 2000) {
      return 'experienced';
    } else if (profile.allTimeRuns > 100) {
      return 'developing';
    } else {
      return 'rookie';
    }
  }
}