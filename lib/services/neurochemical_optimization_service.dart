import 'dart:math' as math;
import '../app_state.dart';
import 'instant_feedback_service.dart';

/// Neurochemical response phases for optimal dopamine release
enum DopaminePhase {
  anticipation,        // Building up to reward
  peak,               // Maximum reward delivery
  satisfaction,       // Post-reward contentment
  withdrawal,         // Slight dip to create hunger
  craving,           // Desire for next reward
}

/// Achievement clustering strategies for compound dopamine hits
enum ClusteringStrategy {
  rapidFire,          // Multiple small rewards in quick succession
  buildUp,           // Escalating rewards leading to big payoff
  sandwich,          // Big-small-big pattern
  cascade,           // Chain reaction of achievements
  surprise,          // Unexpected bonus clusters
  rhythmic,          // Predictable pattern that feels good
}

/// Intervention timing for withdrawal prevention
enum InterventionTiming {
  predictive,         // Before withdrawal starts
  immediate,          // As soon as withdrawal detected
  recovery,          // During recovery phase
  preventive,        // To maintain engagement
  emergency,         // Critical intervention needed
}

/// Dopamine timing optimization tracker
class DopamineOptimizer {
  final String serverId;
  DopaminePhase currentPhase = DopaminePhase.craving;
  DateTime lastReward = DateTime.now();
  List<DateTime> rewardHistory = [];
  double currentIntensity = 0.5; // 0.0 to 1.0
  double baselineIntensity = 0.5;
  ClusteringStrategy? activeCluster;
  int clusterPosition = 0;
  
  DopamineOptimizer({required this.serverId});
  
  /// Calculate optimal timing for next reward
  Duration get optimalNextReward {
    final timeSinceLastReward = DateTime.now().difference(lastReward);
    
    switch (currentPhase) {
      case DopaminePhase.anticipation:
        return Duration(seconds: 15); // Build anticipation
      case DopaminePhase.peak:
        return Duration(seconds: 5); // Strike while hot
      case DopaminePhase.satisfaction:
        return Duration(seconds: 45); // Let satisfaction linger
      case DopaminePhase.withdrawal:
        return Duration(seconds: 20); // Rescue from withdrawal
      case DopaminePhase.craving:
        return Duration(seconds: 10); // Satisfy the craving
    }
  }
  
  /// Calculate current addiction risk (0.0 to 1.0)
  double get addictionScore {
    final recentRewards = rewardHistory
      .where((r) => DateTime.now().difference(r).inHours < 2)
      .length;
    
    // More recent rewards = higher addiction score
    final recentScore = (recentRewards / 10.0).clamp(0.0, 1.0);
    
    // Current intensity contributes
    final intensityScore = currentIntensity;
    
    // Phase contributes (craving = higher addiction)
    final phaseScore = currentPhase == DopaminePhase.craving ? 0.8 : 0.4;
    
    return ((recentScore + intensityScore + phaseScore) / 3.0).clamp(0.0, 1.0);
  }
}

/// Achievement cluster event
class AchievementCluster {
  final String id;
  final ClusteringStrategy strategy;
  final List<String> achievementSequence;
  final List<int> xpSequence;
  final List<Duration> timingSequence;
  final DateTime startTime;
  int currentPosition = 0;
  
  AchievementCluster({
    required this.id,
    required this.strategy,
    required this.achievementSequence,
    required this.xpSequence,
    required this.timingSequence,
    required this.startTime,
  });
  
  bool get isComplete => currentPosition >= achievementSequence.length;
  String? get nextAchievement => isComplete ? null : achievementSequence[currentPosition];
  int? get nextXP => isComplete ? null : xpSequence[currentPosition];
  Duration? get nextTiming => isComplete ? null : timingSequence[currentPosition];
}

/// Withdrawal intervention event
class WithdrawalIntervention {
  final String serverId;
  final InterventionTiming timing;
  final String message;
  final FeedbackPriority priority;
  final int xpBonus;
  final Map<String, dynamic> context;
  final DateTime triggerTime;
  
  WithdrawalIntervention({
    required this.serverId,
    required this.timing,
    required this.message,
    required this.priority,
    required this.xpBonus,
    required this.context,
    required this.triggerTime,
  });
}

/// Neurochemical response optimization service
class NeurochemicalOptimizationService {
  static final Map<String, DopamineOptimizer> _serverOptimizers = {};
  static final List<AchievementCluster> _activeClusters = [];
  static final Map<String, DateTime> _lastInterventions = {};
  static final math.Random _random = math.Random();
  
  /// Update dopamine state after reward delivery
  static void updateDopamineState(String serverId, int xpReward, AppState app) {
    final optimizer = _getOrCreateOptimizer(serverId);
    
    // Update reward history
    optimizer.rewardHistory.add(DateTime.now());
    if (optimizer.rewardHistory.length > 20) {
      optimizer.rewardHistory.removeAt(0); // Keep last 20 rewards
    }
    
    // Calculate new intensity based on reward magnitude
    final normalizedReward = (xpReward / 100.0).clamp(0.0, 2.0);
    optimizer.currentIntensity = (optimizer.currentIntensity * 0.7 + normalizedReward * 0.3).clamp(0.0, 1.0);
    
    // Advance dopamine phase
    _advanceDopaminePhase(optimizer, xpReward);
    
    optimizer.lastReward = DateTime.now();
  }
  
  /// Build anticipation before reward delivery
  static List<String> buildAnticipation(String serverId, AppState app) {
    final optimizer = _getOrCreateOptimizer(serverId);
    final messages = <String>[];
    
    // Create anticipation based on current state
    if (optimizer.currentPhase == DopaminePhase.craving) {
      messages.addAll([
        "⚡ Something BIG is building... Can you feel it?",
        "🎯 The energy is electric! One more push!",
        "🔥 Your next achievement could be LEGENDARY!",
        "⭐ The stars are aligning for something special!",
      ]);
    } else if (optimizer.currentPhase == DopaminePhase.anticipation) {
      messages.addAll([
        "🌟 YES! The momentum is building perfectly!",
        "💎 This is it! The moment you've been creating!",
        "🚀 Launch sequence initiated! Prepare for greatness!",
        "⚡ The universe is conspiring for your success!",
      ]);
    }
    
    // Update phase to anticipation
    optimizer.currentPhase = DopaminePhase.anticipation;
    
    return messages;
  }
  
  /// Create achievement clusters for compound dopamine hits
  static AchievementCluster? createAchievementCluster(
    String serverId,
    ClusteringStrategy strategy,
    AppState app,
  ) {
    final clusterId = 'cluster_${DateTime.now().millisecondsSinceEpoch}';
    
    late List<String> achievements;
    late List<int> xpValues;
    late List<Duration> timings;
    
    switch (strategy) {
      case ClusteringStrategy.rapidFire:
        achievements = [
          "⚡ RAPID FIRE! First hit!",
          "🔥 RAPID FIRE! Double tap!",
          "💥 RAPID FIRE! Triple threat!",
          "🌟 RAPID FIRE! Quadruple kill!",
          "👑 RAPID FIRE! QUINTUPLE LEGEND!",
        ];
        xpValues = [25, 30, 40, 55, 75];
        timings = [
          Duration(seconds: 3),
          Duration(seconds: 2),
          Duration(seconds: 2),
          Duration(seconds: 1),
          Duration(seconds: 1),
        ];
        break;
        
      case ClusteringStrategy.buildUp:
        achievements = [
          "🎯 Building momentum...",
          "⚡ Energy rising...",
          "🔥 Power accumulating...",
          "💥 EXPLOSIVE RELEASE!",
        ];
        xpValues = [20, 35, 55, 100];
        timings = [
          Duration(seconds: 8),
          Duration(seconds: 6),
          Duration(seconds: 4),
          Duration(seconds: 2),
        ];
        break;
        
      case ClusteringStrategy.sandwich:
        achievements = [
          "🌟 MASSIVE OPENER!",
          "⚡ Quick follow-up!",
          "💎 LEGENDARY FINISHER!",
        ];
        xpValues = [80, 25, 120];
        timings = [
          Duration(seconds: 5),
          Duration(seconds: 3),
          Duration(seconds: 4),
        ];
        break;
        
      case ClusteringStrategy.cascade:
        achievements = [
          "🎯 CASCADE! First wave!",
          "⚡ CASCADE! Chain reaction!",
          "🔥 CASCADE! Amplifying!",
          "💥 CASCADE! Chain complete!",
        ];
        xpValues = [30, 45, 65, 90];
        timings = [
          Duration(seconds: 4),
          Duration(seconds: 3),
          Duration(seconds: 3),
          Duration(seconds: 2),
        ];
        break;
        
      case ClusteringStrategy.surprise:
        achievements = [
          "❓ Surprise bonus incoming...",
          "🎁 SURPRISE! Unexpected gift!",
          "💎 SURPRISE! Another one!",
          "🌟 SURPRISE! The surprises never end!",
        ];
        xpValues = [40, 60, 50, 80];
        timings = [
          Duration(seconds: 6),
          Duration(seconds: 4),
          Duration(seconds: 5),
          Duration(seconds: 3),
        ];
        break;
        
      case ClusteringStrategy.rhythmic:
        achievements = [
          "🎵 Perfect rhythm! Beat 1!",
          "🎶 Perfect rhythm! Beat 2!",
          "🎵 Perfect rhythm! Beat 3!",
          "🎶 Perfect rhythm! Beat 4!",
          "🎼 SYMPHONY COMPLETE!",
        ];
        xpValues = [35, 35, 35, 35, 70];
        timings = [
          Duration(seconds: 5),
          Duration(seconds: 5),
          Duration(seconds: 5),
          Duration(seconds: 5),
          Duration(seconds: 3),
        ];
        break;
    }
    
    final cluster = AchievementCluster(
      id: clusterId,
      strategy: strategy,
      achievementSequence: achievements,
      xpSequence: xpValues,
      timingSequence: timings,
      startTime: DateTime.now(),
    );
    
    _activeClusters.add(cluster);
    
    // Update optimizer
    final optimizer = _getOrCreateOptimizer(serverId);
    optimizer.activeCluster = strategy;
    optimizer.clusterPosition = 0;
    
    return cluster;
  }
  
  /// Check for withdrawal and create intervention if needed
  static WithdrawalIntervention? checkWithdrawalIntervention(String serverId, AppState app) {
    final optimizer = _getOrCreateOptimizer(serverId);
    final timeSinceLastReward = DateTime.now().difference(optimizer.lastReward);
    
    // Determine if intervention needed
    InterventionTiming? timing;
    
    if (timeSinceLastReward.inMinutes >= 10 && optimizer.currentPhase != DopaminePhase.withdrawal) {
      timing = InterventionTiming.predictive; // Predict withdrawal
    } else if (optimizer.currentPhase == DopaminePhase.withdrawal) {
      timing = InterventionTiming.immediate; // In withdrawal
    } else if (optimizer.addictionScore < 0.3) {
      timing = InterventionTiming.emergency; // Low engagement
    }
    
    if (timing == null) return null;
    
    // Check if we've intervened recently (don't overwhelm)
    final lastIntervention = _lastInterventions[serverId];
    if (lastIntervention != null && DateTime.now().difference(lastIntervention).inMinutes < 5) {
      return null; // Too soon for another intervention
    }
    
    // Create intervention
    final intervention = _createIntervention(serverId, timing, optimizer, app);
    _lastInterventions[serverId] = DateTime.now();
    
    return intervention;
  }
  
  /// Get optimal reward timing for maximum dopamine impact
  static Duration getOptimalRewardTiming(String serverId) {
    final optimizer = _getOrCreateOptimizer(serverId);
    return optimizer.optimalNextReward;
  }
  
  /// Check if server is in optimal state for reward delivery
  static bool isOptimalRewardState(String serverId) {
    final optimizer = _getOrCreateOptimizer(serverId);
    
    // Check if in peak dopamine phases
    if (optimizer.currentPhase == DopaminePhase.anticipation ||
        optimizer.currentPhase == DopaminePhase.craving) {
      return true;
    }
    
    // Check if enough time has passed for good timing
    final timeSinceLastReward = DateTime.now().difference(optimizer.lastReward);
    return timeSinceLastReward >= optimizer.optimalNextReward;
  }
  
  /// Generate perfectly timed motivational messages
  static List<String> generateTimedMotivation(String serverId, AppState app) {
    final optimizer = _getOrCreateOptimizer(serverId);
    final messages = <String>[];
    
    switch (optimizer.currentPhase) {
      case DopaminePhase.anticipation:
        messages.addAll([
          "🌟 The energy is building! You can feel it happening!",
          "⚡ This is your moment! Everything is aligning perfectly!",
          "🎯 The tension is electric! Release it with your next move!",
        ]);
        break;
        
      case DopaminePhase.craving:
        messages.addAll([
          "🔥 Your body knows what it wants! Feed that hunger!",
          "💎 That feeling you have? That's excellence calling!",
          "⚡ The craving for greatness is your superpower!",
        ]);
        break;
        
      case DopaminePhase.withdrawal:
        messages.addAll([
          "🌈 Every champion has valleys before peaks! Climb!",
          "💪 This dip is temporary! Your comeback is permanent!",
          "🚀 Use this energy to launch into your next victory!",
        ]);
        break;
        
      default:
        messages.addAll([
          "⭐ Your neurochemistry is primed for greatness!",
          "🎯 Perfect timing for your next achievement!",
        ]);
    }
    
    return messages;
  }
  
  /// Analyze dopamine patterns for optimization with shift and career context
  static Map<String, dynamic> analyzeDopaminePatterns(String serverId, {AppState? app}) {
    final optimizer = _getOrCreateOptimizer(serverId);
    
    // Basic dopamine analysis
    final baseAnalysis = {
      'currentPhase': optimizer.currentPhase.toString(),
      'currentIntensity': optimizer.currentIntensity,
      'addictionScore': optimizer.addictionScore,
      'recentRewards': optimizer.rewardHistory.length,
      'timeSinceLastReward': DateTime.now().difference(optimizer.lastReward).inMinutes,
      'optimalNextReward': optimizer.optimalNextReward.inSeconds,
      'isOptimalState': isOptimalRewardState(serverId),
    };
    
    // Enhanced analysis with shift and career context
    if (app != null) {
      final profile = app.profiles[serverId];
      final isShiftActive = app.shiftActive;
      final isWorkingToday = app.workingServerIds.contains(serverId);
      final currentRuns = app.currentCounts[serverId] ?? 0;
      
      if (profile != null) {
        // Career momentum analysis
        final careerMomentum = _calculateCareerMomentum(profile);
        final shiftVsCareerRatio = profile.bestShiftRuns > 0 ? currentRuns / profile.bestShiftRuns : 0.0;
        
        // Context-aware timing adjustments
        final contextualAdjustments = _calculateContextualTimingAdjustments(
          isShiftActive, isWorkingToday, careerMomentum, shiftVsCareerRatio, optimizer.currentPhase
        );
        
        baseAnalysis.addAll({
          'isShiftActive': isShiftActive,
          'isWorkingToday': isWorkingToday,
          'careerMomentum': careerMomentum,
          'shiftVsCareerRatio': shiftVsCareerRatio,
          'contextualMultiplier': contextualAdjustments['multiplier'],
          'contextualUrgency': contextualAdjustments['urgency'],
          'careerBasedTiming': contextualAdjustments['optimalTiming'],
          'workStatusBonus': isWorkingToday ? 1.2 : 0.8,
          'shiftStateBonus': isShiftActive ? 1.3 : 0.9,
        });
      }
    }
    
    return baseAnalysis;
  }
  
  /// Get or create optimizer for server
  static DopamineOptimizer _getOrCreateOptimizer(String serverId) {
    return _serverOptimizers.putIfAbsent(
      serverId, 
      () => DopamineOptimizer(serverId: serverId),
    );
  }
  
  /// Advance dopamine phase based on reward
  static void _advanceDopaminePhase(DopamineOptimizer optimizer, int xpReward) {
    switch (optimizer.currentPhase) {
      case DopaminePhase.craving:
        optimizer.currentPhase = DopaminePhase.peak;
        break;
      case DopaminePhase.anticipation:
        optimizer.currentPhase = DopaminePhase.peak;
        break;
      case DopaminePhase.peak:
        optimizer.currentPhase = DopaminePhase.satisfaction;
        break;
      case DopaminePhase.satisfaction:
        // Large rewards maintain satisfaction, small rewards create slight withdrawal
        optimizer.currentPhase = xpReward >= 50 ? DopaminePhase.satisfaction : DopaminePhase.withdrawal;
        break;
      case DopaminePhase.withdrawal:
        optimizer.currentPhase = DopaminePhase.craving;
        break;
    }
  }
  
  /// Create withdrawal intervention
  static WithdrawalIntervention _createIntervention(
    String serverId,
    InterventionTiming timing,
    DopamineOptimizer optimizer,
    AppState app,
  ) {
    late String message;
    late FeedbackPriority priority;
    late int xpBonus;
    late Map<String, dynamic> context;
    
    switch (timing) {
      case InterventionTiming.predictive:
        message = "🎯 PERFECT TIMING! Your brain is ready for something amazing!";
        priority = FeedbackPriority.medium;
        xpBonus = 25;
        context = {'type': 'predictive', 'phase': 'pre-withdrawal'};
        break;
        
      case InterventionTiming.immediate:
        message = "🚀 RESCUE MISSION! Time to rocket back to the top!";
        priority = FeedbackPriority.high;
        xpBonus = 40;
        context = {'type': 'immediate', 'phase': 'withdrawal'};
        break;
        
      case InterventionTiming.emergency:
        message = "🆘 EMERGENCY BOOST! Your greatness needs immediate fuel!";
        priority = FeedbackPriority.epic;
        xpBonus = 60;
        context = {'type': 'emergency', 'phase': 'critical'};
        break;
        
      case InterventionTiming.preventive:
        message = "💡 PREVENTIVE STRIKE! Stay ahead of the game!";
        priority = FeedbackPriority.medium;
        xpBonus = 30;
        context = {'type': 'preventive', 'phase': 'maintenance'};
        break;
    }
    
    return WithdrawalIntervention(
      serverId: serverId,
      timing: timing,
      message: message,
      xpBonus: xpBonus,
      triggerTime: DateTime.now(),
      priority: priority,
      context: context,
    );
  }
  
  /// Calculate career momentum for neurochemical timing
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
  
  /// Calculate contextual timing adjustments based on shift state and career
  static Map<String, dynamic> _calculateContextualTimingAdjustments(
    bool isShiftActive,
    bool isWorkingToday,
    double careerMomentum,
    double shiftVsCareerRatio,
    DopaminePhase currentPhase,
  ) {
    // Base multiplier
    double multiplier = 1.0;
    double urgency = 0.5;
    int optimalTiming = 300; // 5 minutes default
    
    // Shift state adjustments
    if (isShiftActive && isWorkingToday) {
      multiplier += 0.3; // Active shift = higher responsiveness
      urgency += 0.2;
      optimalTiming = (optimalTiming * 0.7).round(); // Faster timing
    } else if (!isWorkingToday) {
      multiplier -= 0.2; // Off duty = lower responsiveness
      urgency -= 0.3;
      optimalTiming = (optimalTiming * 1.5).round(); // Slower timing
    }
    
    // Career momentum adjustments
    if (careerMomentum > 0.7) {
      multiplier += 0.2; // High momentum = more receptive
      urgency += 0.1;
    } else if (careerMomentum < 0.3) {
      multiplier -= 0.1; // Low momentum = less receptive
      urgency -= 0.1;
    }
    
    // Performance vs career ratio adjustments
    if (shiftVsCareerRatio < 0.5) {
      // Underperforming = need more aggressive intervention
      multiplier += 0.3;
      urgency += 0.4;
      optimalTiming = (optimalTiming * 0.5).round();
    } else if (shiftVsCareerRatio > 1.2) {
      // Overperforming = maintain momentum
      multiplier += 0.1;
      urgency += 0.1;
    }
    
    // Phase-specific adjustments
    switch (currentPhase) {
      case DopaminePhase.craving:
        multiplier += 0.4; // Craving = highly receptive
        urgency += 0.5;
        optimalTiming = (optimalTiming * 0.3).round();
        break;
      case DopaminePhase.withdrawal:
        multiplier += 0.3; // Withdrawal = need intervention
        urgency += 0.4;
        optimalTiming = (optimalTiming * 0.4).round();
        break;
      case DopaminePhase.satisfaction:
        multiplier -= 0.1; // Satisfied = less urgent
        urgency -= 0.2;
        optimalTiming = (optimalTiming * 1.2).round();
        break;
      default:
        break;
    }
    
    return {
      'multiplier': multiplier.clamp(0.3, 2.0),
      'urgency': urgency.clamp(0.0, 1.0),
      'optimalTiming': optimalTiming.clamp(30, 1800), // 30 seconds to 30 minutes
    };
  }
  
  /// Cleanup expired clusters and optimizers
  static void cleanupExpiredData() {
    final now = DateTime.now();
    
    // Remove completed clusters
    _activeClusters.removeWhere((c) => c.isComplete || 
      now.difference(c.startTime).inMinutes > 10);
    
    // Clean old intervention records
    _lastInterventions.removeWhere((key, value) => 
      now.difference(value).inHours > 1);
  }
}