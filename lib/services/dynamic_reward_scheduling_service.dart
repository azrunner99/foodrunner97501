import 'dart:math' as math;
import '../app_state.dart';
import 'instant_feedback_service.dart';

/// Variable ratio reward triggers that create unpredictable reinforcement
enum VariableRewardTrigger {
  surpriseBonus, // Random XP multipliers (2x, 3x, 5x)
  mysteryMilestone, // Unmarked achievements that surprise users
  jackpotEvent, // Massive XP rewards (100-1000 XP)
  luckyStreak, // Bonus for unusual patterns
  perfectTiming, // Rewards for optimal timing
  hiddenCombo, // Secret combination bonuses
  rareAchievement, // Ultra-rare milestone unlocks
  flashEvent, // Brief high-reward windows
}

/// Limited time achievement windows that create urgency
enum UrgencyWindow {
  goldenHour, // 1 hour of double XP
  rushBonus, // 15 minutes of triple rewards
  perfectWindow, // 5 minutes of massive bonuses
  midnightMadness, // Late night bonus period
  powerHour, // Team coordination bonus
  flashChallenge, // Sudden mini-challenge
  streakSaver, // Limited time to save dying streak
  comboExtender, // Brief window to extend combo
}

/// Escalating reward chain types
enum RewardChainType {
  speedChain, // Faster = higher multipliers
  consistencyChain, // Sustained performance = escalating rewards
  comebackChain, // Recovery performance = increasing bonuses
  dominationChain, // Leading = exponentially higher rewards
  perfectionChain, // Flawless execution = massive escalation
  socialChain, // Team coordination = collective multipliers
  enduranceChain, // Extended performance = compound rewards
  breakthroughChain, // Personal records = breakthrough bonuses
}

/// Individual reward event
class RewardEvent {
  final String id;
  final VariableRewardTrigger trigger;
  final int baseXP;
  final double multiplier;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final String message;
  final FeedbackPriority priority;

  RewardEvent({
    required this.id,
    required this.trigger,
    required this.baseXP,
    required this.multiplier,
    required this.timestamp,
    required this.context,
    required this.message,
    required this.priority,
  });

  int get totalXP => (baseXP * multiplier).round();
}

/// Active urgency window
class ActiveUrgencyWindow {
  final String id;
  final UrgencyWindow type;
  final DateTime startTime;
  final DateTime endTime;
  final double multiplier;
  final String description;
  final List<String> eligibleServerIds;
  final Map<String, int> participantProgress;

  ActiveUrgencyWindow({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.multiplier,
    required this.description,
    required this.eligibleServerIds,
  }) : participantProgress = {};

  Duration get timeRemaining => endTime.difference(DateTime.now());
  bool get isActive =>
      DateTime.now().isBefore(endTime) && DateTime.now().isAfter(startTime);
  double get progressPercentage =>
      DateTime.now().difference(startTime).inMilliseconds /
      endTime.difference(startTime).inMilliseconds;
}

/// Escalating reward chain tracker
class RewardChain {
  final String serverId;
  final RewardChainType type;
  int currentLevel = 1;
  double currentMultiplier = 1.0;
  DateTime lastUpdate = DateTime.now();
  List<DateTime> chainEvents = [];
  bool isActive = true;

  RewardChain({
    required this.serverId,
    required this.type,
  });

  /// Calculate next level multiplier
  double get nextMultiplier {
    switch (type) {
      case RewardChainType.speedChain:
        return 1.0 + (currentLevel * 0.2); // 1.2x, 1.4x, 1.6x...
      case RewardChainType.consistencyChain:
        return 1.0 + (currentLevel * 0.15); // Slower growth for consistency
      case RewardChainType.comebackChain:
        return 1.0 + (currentLevel * 0.3); // Higher rewards for comebacks
      case RewardChainType.dominationChain:
        return math
            .pow(1.25, currentLevel)
            .toDouble(); // Exponential for domination
      case RewardChainType.perfectionChain:
        return 1.0 + (currentLevel * 0.4); // Massive rewards for perfection
      case RewardChainType.socialChain:
        return 1.0 + (currentLevel * 0.1); // Modest but team-wide
      case RewardChainType.enduranceChain:
        return 1.0 + (currentLevel * 0.05); // Small but compounds over time
      case RewardChainType.breakthroughChain:
        return 1.0 + (currentLevel * 0.5); // Huge rewards for breakthroughs
    }
  }

  /// Check if chain should expire
  bool get shouldExpire {
    final timeSinceUpdate = DateTime.now().difference(lastUpdate);
    switch (type) {
      case RewardChainType.speedChain:
        return timeSinceUpdate.inSeconds > 30; // Fast decay for speed
      case RewardChainType.consistencyChain:
        return timeSinceUpdate.inMinutes > 10; // Longer for consistency
      case RewardChainType.comebackChain:
        return timeSinceUpdate.inMinutes > 5; // Medium decay
      case RewardChainType.dominationChain:
        return timeSinceUpdate.inMinutes > 15; // Long decay for leaders
      case RewardChainType.perfectionChain:
        return timeSinceUpdate.inSeconds > 45; // Strict timing
      case RewardChainType.socialChain:
        return timeSinceUpdate.inMinutes > 20; // Team coordination window
      case RewardChainType.enduranceChain:
        return timeSinceUpdate.inMinutes > 2; // Requires sustained activity
      case RewardChainType.breakthroughChain:
        return timeSinceUpdate.inMinutes > 30; // Long window for breakthroughs
    }
  }
}

/// Dynamic reward scheduling service for unpredictable reinforcement
class DynamicRewardSchedulingService {
  static final List<ActiveUrgencyWindow> _activeWindows = [];
  static final Map<String, List<RewardChain>> _serverChains = {};
  static final Map<String, DateTime> _lastJackpotTimes = {};
  static final math.Random _random = math.Random();

  /// Check for variable ratio rewards on any server action
  static List<RewardEvent> checkForVariableRewards(
    String serverId,
    AppState app, {
    required String actionType,
    required int baseXP,
    Map<String, dynamic>? context,
  }) {
    final events = <RewardEvent>[];
    final profile = app.profiles[serverId];
    if (profile == null) return events;

    // Variable ratio trigger chances (deliberately unpredictable)
    final triggerChances = <VariableRewardTrigger, double>{
      VariableRewardTrigger.surpriseBonus: 0.15, // 15% chance
      VariableRewardTrigger.mysteryMilestone: 0.05, // 5% chance
      VariableRewardTrigger.jackpotEvent: 0.02, // 2% chance
      VariableRewardTrigger.luckyStreak: 0.08, // 8% chance
      VariableRewardTrigger.perfectTiming: 0.12, // 12% chance
      VariableRewardTrigger.hiddenCombo: 0.06, // 6% chance
      VariableRewardTrigger.rareAchievement: 0.01, // 1% chance
      VariableRewardTrigger.flashEvent: 0.10, // 10% chance
    };

    // Check each trigger
    for (final entry in triggerChances.entries) {
      if (_random.nextDouble() < entry.value) {
        final event = _generateVariableReward(serverId, entry.key, baseXP, app);
        if (event != null) {
          events.add(event);
        }
      }
    }

    // Check for reward chain advancement
    _updateRewardChains(serverId, actionType, baseXP, app);

    return events;
  }

  /// Create surprise urgency windows
  static ActiveUrgencyWindow? createUrgencyWindow(
      UrgencyWindow type, List<String> serverIds) {
    final windowId = 'window_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    late Duration duration;
    late double multiplier;
    late String description;

    switch (type) {
      case UrgencyWindow.goldenHour:
        duration = Duration(hours: 1);
        multiplier = 2.0;
        description = "🌟 GOLDEN HOUR! Double XP for 1 hour!";
        break;

      case UrgencyWindow.rushBonus:
        duration = Duration(minutes: 15);
        multiplier = 3.0;
        description = "⚡ RUSH BONUS! Triple rewards for 15 minutes!";
        break;

      case UrgencyWindow.perfectWindow:
        duration = Duration(minutes: 5);
        multiplier = 5.0;
        description = "💎 PERFECT WINDOW! 5x XP for 5 minutes only!";
        break;

      case UrgencyWindow.midnightMadness:
        duration = Duration(hours: 2);
        multiplier = 1.5;
        description = "🌙 MIDNIGHT MADNESS! Night shift bonus!";
        break;

      case UrgencyWindow.powerHour:
        duration = Duration(hours: 1);
        multiplier = 2.5;
        description = "💪 POWER HOUR! Team coordination bonus!";
        break;

      case UrgencyWindow.flashChallenge:
        duration = Duration(minutes: 10);
        multiplier = 4.0;
        description = "⚡ FLASH CHALLENGE! 4x rewards for 10 minutes!";
        break;

      case UrgencyWindow.streakSaver:
        duration = Duration(minutes: 20);
        multiplier = 2.0;
        description = "🔥 STREAK SAVER! Save your streak with double XP!";
        break;

      case UrgencyWindow.comboExtender:
        duration = Duration(minutes: 8);
        multiplier = 3.5;
        description = "🎯 COMBO EXTENDER! Extend your combo now!";
        break;
    }

    final window = ActiveUrgencyWindow(
      id: windowId,
      type: type,
      startTime: startTime,
      endTime: startTime.add(duration),
      multiplier: multiplier,
      description: description,
      eligibleServerIds: List.from(serverIds),
    );

    _activeWindows.add(window);
    return window;
  }

  /// Check if server is eligible for any active urgency bonuses
  static double getActiveUrgencyMultiplier(String serverId) {
    double totalMultiplier = 1.0;

    for (final window in _activeWindows) {
      if (window.isActive && window.eligibleServerIds.contains(serverId)) {
        totalMultiplier *= window.multiplier;
      }
    }

    // Clean up expired windows
    _activeWindows.removeWhere((w) => !w.isActive);

    return totalMultiplier;
  }

  /// Update and advance reward chains
  static void _updateRewardChains(
      String serverId, String actionType, int baseXP, AppState app) {
    final chains = _serverChains[serverId] ?? <RewardChain>[];

    // Check for new chain triggers based on action type
    if (actionType == 'speed_run' &&
        !_hasActiveChain(serverId, RewardChainType.speedChain)) {
      chains.add(
          RewardChain(serverId: serverId, type: RewardChainType.speedChain));
    } else if (actionType == 'consistent_run' &&
        !_hasActiveChain(serverId, RewardChainType.consistencyChain)) {
      chains.add(RewardChain(
          serverId: serverId, type: RewardChainType.consistencyChain));
    } else if (actionType == 'comeback_run' &&
        !_hasActiveChain(serverId, RewardChainType.comebackChain)) {
      chains.add(
          RewardChain(serverId: serverId, type: RewardChainType.comebackChain));
    }

    // Update existing chains
    for (final chain in chains) {
      if (chain.isActive && !chain.shouldExpire) {
        chain.currentLevel++;
        chain.currentMultiplier = chain.nextMultiplier;
        chain.lastUpdate = DateTime.now();
        chain.chainEvents.add(DateTime.now());

        // Apply chain bonus to profile
        final profile = app.profiles[serverId];
        if (profile != null) {
          final chainBonus = (baseXP * (chain.currentMultiplier - 1.0)).round();
          profile.points += chainBonus;
        }
      } else if (chain.shouldExpire) {
        chain.isActive = false;
      }
    }

    // Clean up expired chains
    chains.removeWhere((c) => !c.isActive);
    _serverChains[serverId] = chains;
  }

  /// Generate variable reward event with dual-timeline context
  static RewardEvent? _generateVariableReward(
    String serverId,
    VariableRewardTrigger trigger,
    int baseXP,
    AppState app,
  ) {
    final eventId = 'reward_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now();
    final profile = app.profiles[serverId];

    // Dual-context analysis
    final currentRuns = app.currentCounts[serverId] ?? 0;
    final isShiftActive = app.shiftActive;
    final careerLevel =
        profile != null ? _determineCareerLevel(profile.allTimeRuns) : 'rookie';
    final shiftVsCareerRatio = profile != null && profile.bestShiftRuns > 0
        ? currentRuns / profile.bestShiftRuns
        : 0.0;

    late double multiplier;
    late String message;
    late FeedbackPriority priority;
    late Map<String, dynamic> context;

    switch (trigger) {
      case VariableRewardTrigger.surpriseBonus:
        multiplier = [1.5, 2.0, 2.5, 3.0][_random.nextInt(4)];

        // Career-contextual messaging
        if (careerLevel == 'legend' || careerLevel == 'veteran') {
          message =
              "👑 VETERAN BONUS! Your ${profile?.allTimeRuns ?? 0} career runs earn ${multiplier}x XP!";
        } else if (shiftVsCareerRatio > 1.2) {
          message =
              "🚀 BREAKTHROUGH BONUS! Exceeding your standards! ${multiplier}x XP!";
        } else {
          message = "🎁 SURPRISE BONUS! ${multiplier}x XP reward!";
        }

        priority = FeedbackPriority.high;
        context = {
          'type': 'surprise',
          'rarity': 'common',
          'careerLevel': careerLevel,
          'shiftVsCareer': shiftVsCareerRatio,
        };
        break;

      case VariableRewardTrigger.mysteryMilestone:
        multiplier = [2.0, 3.0, 4.0][_random.nextInt(3)];

        if (careerLevel == 'legend' && currentRuns > 20) {
          message =
              "🏆 LEGENDARY MILESTONE! Your mastery unlocks ${multiplier}x secret achievement!";
        } else if (careerLevel == 'rookie' && currentRuns > 10) {
          message =
              "✨ RISING STAR MILESTONE! Building your legacy! ${multiplier}x secret achievement!";
        } else {
          message = "❓ MYSTERY MILESTONE! ${multiplier}x secret achievement!";
        }

        priority = FeedbackPriority.epic;
        context = {
          'type': 'mystery',
          'rarity': 'uncommon',
          'careerLevel': careerLevel,
          'isCareerMoment': careerLevel != 'rookie',
        };
        break;

      case VariableRewardTrigger.jackpotEvent:
        // Prevent jackpots too frequently
        final lastJackpot = _lastJackpotTimes[serverId];
        if (lastJackpot != null &&
            DateTime.now().difference(lastJackpot).inHours < 2) {
          return null; // Too soon for another jackpot
        }

        multiplier = [5.0, 8.0, 10.0, 15.0][_random.nextInt(4)];

        // Career-specific jackpot messaging
        if (profile != null && profile.allTimeRuns > 1000) {
          message =
              "💎 CAREER JACKPOT! ${profile.allTimeRuns} runs of experience pays off! ${multiplier}x MEGA REWARD!";
        } else if (isShiftActive && currentRuns > 15) {
          message =
              "⚡ SHIFT JACKPOT! Peak performance unlocks ${multiplier}x MEGA REWARD!";
        } else {
          message = "🎰 JACKPOT! ${multiplier}x MEGA REWARD!";
        }

        priority = FeedbackPriority.epic;
        context = {
          'type': 'jackpot',
          'rarity': 'legendary',
          'careerMoment': profile?.allTimeRuns ?? 0 > 1000,
          'shiftPeak': isShiftActive && currentRuns > 15,
        };
        _lastJackpotTimes[serverId] = timestamp;
        break;

      case VariableRewardTrigger.luckyStreak:
        multiplier = 1.5 + (_random.nextDouble() * 2.0); // 1.5x to 3.5x
        message =
            "🍀 LUCKY STREAK! ${multiplier.toStringAsFixed(1)}x fortune bonus!";
        priority = FeedbackPriority.high;
        context = {'type': 'lucky', 'rarity': 'common'};
        break;

      case VariableRewardTrigger.perfectTiming:
        multiplier = [1.8, 2.2, 2.6][_random.nextInt(3)];
        message = "⏰ PERFECT TIMING! ${multiplier}x precision bonus!";
        priority = FeedbackPriority.medium;
        context = {'type': 'timing', 'rarity': 'common'};
        break;

      case VariableRewardTrigger.hiddenCombo:
        multiplier = [2.5, 3.5, 4.5][_random.nextInt(3)];
        message = "🎯 HIDDEN COMBO! ${multiplier}x secret sequence!";
        priority = FeedbackPriority.high;
        context = {'type': 'combo', 'rarity': 'rare'};
        break;

      case VariableRewardTrigger.rareAchievement:
        multiplier = [8.0, 12.0, 20.0][_random.nextInt(3)];
        message = "💎 RARE ACHIEVEMENT! ${multiplier}x legendary feat!";
        priority = FeedbackPriority.epic;
        context = {'type': 'rare', 'rarity': 'legendary'};
        break;

      case VariableRewardTrigger.flashEvent:
        multiplier = 2.0 + (_random.nextDouble() * 1.5); // 2.0x to 3.5x
        message =
            "⚡ FLASH EVENT! ${multiplier.toStringAsFixed(1)}x lightning bonus!";
        priority = FeedbackPriority.high;
        context = {'type': 'flash', 'rarity': 'uncommon'};
        break;
    }

    return RewardEvent(
      id: eventId,
      trigger: trigger,
      baseXP: baseXP,
      multiplier: multiplier,
      timestamp: timestamp,
      context: context,
      message: message,
      priority: priority,
    );
  }

  /// Check if server has an active chain of specific type
  static bool _hasActiveChain(String serverId, RewardChainType type) {
    final chains = _serverChains[serverId] ?? [];
    return chains.any((c) => c.type == type && c.isActive);
  }

  /// Get active chains for a server
  static List<RewardChain> getActiveChains(String serverId) {
    final chains = _serverChains[serverId] ?? [];
    return chains.where((c) => c.isActive && !c.shouldExpire).toList();
  }

  /// Generate anticipation messages for upcoming rewards
  static List<String> generateAnticipationMessages(
      String serverId, AppState app) {
    final messages = <String>[];

    // Check for near-jackpot conditions
    final profile = app.profiles[serverId];
    if (profile != null) {
      final currentRuns = app.currentCounts[serverId] ?? 0;

      // Jackpot tease messages
      if (currentRuns > 0 && currentRuns % 7 == 6) {
        // One before lucky 7 multiple
        messages
            .add("🎰 JACKPOT BUILDING! One more for a chance at MEGA rewards!");
      }

      // Chain advancement teases
      final activeChains = getActiveChains(serverId);
      for (final chain in activeChains) {
        if (chain.currentLevel % 3 == 2) {
          // About to hit a milestone
          messages.add(
              "🔥 CHAIN LEVEL ${chain.currentLevel + 1} INCOMING! Keep the momentum!");
        }
      }

      // Mystery milestone teases
      if (currentRuns > 0 && currentRuns % 11 == 10) {
        // Prime number patterns
        messages.add("❓ Something mysterious is building... Keep going!");
      }
    }

    return messages;
  }

  /// Cleanup expired windows and chains
  static void cleanupExpiredRewards() {
    _activeWindows.removeWhere((w) => !w.isActive);

    for (final chains in _serverChains.values) {
      chains.removeWhere((c) => !c.isActive);
    }
  }

  /// Determine career level based on all-time runs
  static String _determineCareerLevel(int allTimeRuns) {
    if (allTimeRuns >= 10000) return 'legend';
    if (allTimeRuns >= 5000) return 'veteran';
    if (allTimeRuns >= 2000) return 'experienced';
    if (allTimeRuns >= 500) return 'developing';
    return 'rookie';
  }
}
