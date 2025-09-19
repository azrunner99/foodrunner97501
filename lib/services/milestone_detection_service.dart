import 'dart:math';
import '../app_state.dart';
import 'instant_feedback_service.dart';
import 'server_personalization_service.dart';
import 'message_variety_engine.dart';

/// Milestone types with base XP rewards
enum MilestoneType {
  // Daily Firsts (+5-15 XP) - Small bonuses for first achievements
  firstRunOfShift(5),
  firstPizookieOfDay(10),
  firstSpeedBurst(8),
  firstTimeTakingLead(15),

  // Performance Milestones (+3-20 XP) - Regular milestone bonuses
  everyFifthRun(8), // 5, 10, 15, 20, 25...
  everySecondPizookie(
      15), // 2, 4, 6, 8... (changed from 3rd to 2nd for more frequent rewards)
  pizookieStreak(8), // Consecutive pizookies bonus
  doubleTap(3), // 2+ items in 10 seconds
  steadyPace(5), // 3+ items in 5 minutes
  hotStreak(10), // 5+ items in 5 minutes

  // Competitive Achievements (+15-35 XP) - Competitive bonuses
  takingTheLead(25),
  wideningGap(30), // 3+ ahead of 2nd place
  comeback(35), // From 3+ behind to 1st
  perfectShift(50), // No breaks >2 minutes

  // Legendary Moments (+50-150 XP) - Rare special achievements
  pizookieMaster(75), // 5 pizookies in one shift
  sweetTooth(100), // 8 pizookies in one shift
  dessertDominator(150), // 12 pizookies in one shift
  personalRecord(75), // Beat personal best shift
  teamGoal(100), // Team hits collective target
  levelBreakthrough(125), // Level up achievement
  serverOfWeek(150); // Top performer recognition

  const MilestoneType(this.baseXP);
  final int baseXP;
}

/// Individual milestone achievement
class MilestoneAchievement {
  final MilestoneType type;
  final int xpReward;
  final String message;
  final String subMessage;
  final FeedbackPriority priority;
  final Map<String, dynamic> context;

  MilestoneAchievement({
    required this.type,
    required this.xpReward,
    required this.message,
    required this.subMessage,
    required this.priority,
    this.context = const {},
  });

  MilestoneAchievement copyWith({
    MilestoneType? type,
    int? xpReward,
    String? message,
    String? subMessage,
    FeedbackPriority? priority,
    Map<String, dynamic>? context,
  }) {
    return MilestoneAchievement(
      type: type ?? this.type,
      xpReward: xpReward ?? this.xpReward,
      message: message ?? this.message,
      subMessage: subMessage ?? this.subMessage,
      priority: priority ?? this.priority,
      context: context ?? this.context,
    );
  }
}

/// Service for detecting and awarding milestone achievements
class MilestoneDetectionService {
  /// Check for any milestone achievements when a server takes an action
  static MilestoneAchievement? checkForMilestones(String serverId, AppState app,
      {bool isPizookie = false}) {
    final profile = app.profiles[serverId];
    if (profile == null) return null;

    // Check daily firsts
    final dailyFirst = _checkDailyFirsts(serverId, app, isPizookie);
    if (dailyFirst != null) return dailyFirst;

    // Check performance milestones
    final performance = _checkPerformanceMilestones(serverId, app, isPizookie);
    if (performance != null) return performance;

    // Check speed achievements
    final speed = _checkSpeedMilestones(serverId, app);
    if (speed != null) return speed;

    // Check competitive achievements
    final competitive = _checkCompetitiveMilestones(serverId, app);
    if (competitive != null) return competitive;

    return null;
  }

  /// Check for daily achievement milestones
  static MilestoneAchievement? _checkDailyFirsts(
      String serverId, AppState app, bool isPizookie) {
    // First run of shift
    if (!isPizookie &&
        _isFirstOfDay(serverId, MilestoneType.firstRunOfShift, app)) {
      _markDailyFirst(serverId, MilestoneType.firstRunOfShift, app);

      final achievement = MilestoneAchievement(
        type: MilestoneType.firstRunOfShift,
        xpReward: MilestoneType.firstRunOfShift.baseXP,
        message: "🌅 FIRST RUN OF SHIFT!\nGreat start!",
        subMessage:
            "+${MilestoneType.firstRunOfShift.baseXP} XP First Run Bonus!",
        priority: FeedbackPriority.medium,
      );

      // Generate personalized message using variety engine
      final profile = app.profiles[serverId];
      if (profile != null) {
        final personality =
            ServerPersonalizationService.analyzeServerPersonality(
                serverId, profile);
        final messageHistory = MessageHistory(
          serverId: serverId,
          recentMessages: profile.recentMessages,
          lastUsed: profile.messageLastUsed,
          usageCount: profile.messageUsageCount,
          engagementScore: profile.messageEngagement,
        );
        final personalizedMessage = MessageVarietyEngine.getPersonalizedMessage(
          serverId,
          personality,
          achievement,
          MessageVarietyEngine.determineContext(
            currentTime: DateTime.now(),
            totalActiveServers: app.profiles.length,
            currentBusinessLevel: _calculateBusinessLevel(app),
          ),
          messageHistory,
        );

        // Update message history in profile
        _updateProfileMessageHistory(profile, personalizedMessage, app);

        return achievement.copyWith(message: personalizedMessage);
      }

      return achievement;
    }

    // First pizookie of day
    if (isPizookie &&
        _isFirstOfDay(serverId, MilestoneType.firstPizookieOfDay, app)) {
      _markDailyFirst(serverId, MilestoneType.firstPizookieOfDay, app);

      final achievement = MilestoneAchievement(
        type: MilestoneType.firstPizookieOfDay,
        xpReward: MilestoneType.firstPizookieOfDay.baseXP,
        message: "🍪 FIRST PIZOOKIE OF DAY!\nSweet start!",
        subMessage:
            "+${MilestoneType.firstPizookieOfDay.baseXP} XP Pizookie Bonus!",
        priority: FeedbackPriority.medium,
      );

      // Generate personalized message using variety engine
      final profile = app.profiles[serverId];
      if (profile != null) {
        final personality =
            ServerPersonalizationService.analyzeServerPersonality(
                serverId, profile);
        final messageHistory = MessageHistory(
          serverId: serverId,
          recentMessages: profile.recentMessages,
          lastUsed: profile.messageLastUsed,
          usageCount: profile.messageUsageCount,
          engagementScore: profile.messageEngagement,
        );
        final personalizedMessage = MessageVarietyEngine.getPersonalizedMessage(
          serverId,
          personality,
          achievement,
          MessageVarietyEngine.determineContext(
            currentTime: DateTime.now(),
            totalActiveServers: app.profiles.length,
            currentBusinessLevel: _calculateBusinessLevel(app),
          ),
          messageHistory,
        );

        // Update message history in profile
        _updateProfileMessageHistory(profile, personalizedMessage, app);

        return achievement.copyWith(message: personalizedMessage);
      }

      return achievement;
    }

    return null;
  }

  /// Check for performance-based milestones
  static MilestoneAchievement? _checkPerformanceMilestones(
      String serverId, AppState app, bool isPizookie) {
    final currentRuns = app.currentCounts[serverId] ?? 0;
    final currentPizookies = app.currentPizookieCounts[serverId] ?? 0;

    // Every 5th run milestone
    if (!isPizookie && currentRuns % 5 == 0 && currentRuns > 0) {
      final multiplier = (currentRuns / 5).floor();
      // Much more reasonable scaling: +1 XP per milestone achieved
      final bonusXP = MilestoneType.everyFifthRun.baseXP +
          (multiplier - 1); // Start at base, +1 per milestone

      return MilestoneAchievement(
        type: MilestoneType.everyFifthRun,
        xpReward: bonusXP,
        message: _getRunMilestoneMessage(currentRuns),
        subMessage: '+$bonusXP XP Milestone Bonus!',
        priority:
            currentRuns >= 20 ? FeedbackPriority.epic : FeedbackPriority.high,
        context: {'runCount': currentRuns, 'multiplier': multiplier},
      );
    }

    // Every 2nd pizookie milestone (changed from 3rd for more frequent rewards)
    if (isPizookie && currentPizookies % 2 == 0 && currentPizookies > 0) {
      final multiplier = (currentPizookies / 2).floor();
      // Enhanced scaling for more frequent milestones: +3 XP per milestone
      final bonusXP =
          MilestoneType.everySecondPizookie.baseXP + ((multiplier - 1) * 3);

      return MilestoneAchievement(
        type: MilestoneType.everySecondPizookie,
        xpReward: bonusXP,
        message: _getPizookieMilestoneMessage(currentPizookies),
        subMessage: '+$bonusXP XP Sweet Bonus!',
        priority: currentPizookies >= 6
            ? FeedbackPriority.epic
            : FeedbackPriority.high,
        context: {'pizookieCount': currentPizookies, 'multiplier': multiplier},
      );
    }

    // Special Pizookie Achievements for high counts
    if (isPizookie) {
      // Pizookie Master - 5 pizookies in shift
      if (currentPizookies == 5) {
        return MilestoneAchievement(
          type: MilestoneType.pizookieMaster,
          xpReward: MilestoneType.pizookieMaster.baseXP,
          message: "🏆 PIZOOKIE MASTER!\nDessert expertise achieved!",
          subMessage:
              "+${MilestoneType.pizookieMaster.baseXP} XP Mastery Bonus!",
          priority: FeedbackPriority.epic,
          context: {'pizookieCount': currentPizookies},
        );
      }

      // Sweet Tooth - 8 pizookies in shift
      if (currentPizookies == 8) {
        return MilestoneAchievement(
          type: MilestoneType.sweetTooth,
          xpReward: MilestoneType.sweetTooth.baseXP,
          message: "🍭 SWEET TOOTH LEGEND!\nDessert domination complete!",
          subMessage: "+${MilestoneType.sweetTooth.baseXP} XP Sweet Bonus!",
          priority: FeedbackPriority.epic,
          context: {'pizookieCount': currentPizookies},
        );
      }

      // Dessert Dominator - 12 pizookies in shift
      if (currentPizookies == 12) {
        return MilestoneAchievement(
          type: MilestoneType.dessertDominator,
          xpReward: MilestoneType.dessertDominator.baseXP,
          message: "👑 DESSERT DOMINATOR!\nAbsolute pizookie supremacy!",
          subMessage:
              "+${MilestoneType.dessertDominator.baseXP} XP Legendary Bonus!",
          priority: FeedbackPriority.epic,
          context: {'pizookieCount': currentPizookies},
        );
      }
    }

    return null;
  }

  /// Check for speed-based achievements
  static MilestoneAchievement? _checkSpeedMilestones(
      String serverId, AppState app) {
    final profile = app.profiles[serverId]!;
    final now = DateTime.now();

    // Update recent tap times (keep last 5 minutes for realistic speed tracking)
    profile.recentTapTimes.add(now);
    profile.recentTapTimes
        .removeWhere((time) => now.difference(time).inMinutes > 5);

    // Hot Streak: 5+ runs in 5 minutes (realistic busy period)
    if (profile.recentTapTimes.length >= 5) {
      // Reset to prevent immediate re-triggering
      profile.recentTapTimes.clear();

      return MilestoneAchievement(
        type: MilestoneType.hotStreak,
        xpReward: MilestoneType.hotStreak.baseXP,
        message: "🔥 HOT STREAK!\nBusy period mastery!",
        subMessage: "+${MilestoneType.hotStreak.baseXP} XP Pace Bonus!",
        priority: FeedbackPriority.high,
      );
    }

    // Steady Pace: 3+ runs in 5 minutes (good consistent work)
    if (profile.recentTapTimes.length >= 3) {
      final firstTapTime = profile.recentTapTimes.first;
      if (now.difference(firstTapTime).inMinutes <= 5) {
        return MilestoneAchievement(
          type: MilestoneType.steadyPace,
          xpReward: MilestoneType.steadyPace.baseXP,
          message: "⚡ STEADY PACE!\nConsistent performance!",
          subMessage: "+${MilestoneType.steadyPace.baseXP} XP Pace Bonus!",
          priority: FeedbackPriority.medium,
        );
      }
    }

    return null;
  }

  /// Check for competitive achievements
  static MilestoneAchievement? _checkCompetitiveMilestones(
      String serverId, AppState app) {
    final profile = app.profiles[serverId]!;
    final currentRank = _getCurrentRank(serverId, app);
    final previousRank = profile.lastKnownRank ?? currentRank;

    // Update rank tracking
    profile.lastKnownRank = currentRank;

    // Taking the lead
    if (currentRank == 1 && previousRank > 1) {
      return MilestoneAchievement(
        type: MilestoneType.takingTheLead,
        xpReward: MilestoneType.takingTheLead.baseXP,
        message: "👑 TOOK THE LEAD!\nEveryone's chasing you!",
        subMessage:
            "+${MilestoneType.takingTheLead.baseXP} XP Leadership Bonus!",
        priority: FeedbackPriority.epic,
        context: {'previousRank': previousRank, 'currentRank': currentRank},
      );
    }

    // Epic comeback achievement
    if (currentRank == 1 && previousRank >= 4) {
      return MilestoneAchievement(
        type: MilestoneType.comeback,
        xpReward: MilestoneType.comeback.baseXP,
        message: "🚀 EPIC COMEBACK!\nFrom last to first!",
        subMessage: "+${MilestoneType.comeback.baseXP} XP Comeback Bonus!",
        priority: FeedbackPriority.epic,
        context: {'comeback': true, 'fromRank': previousRank},
      );
    }

    return null;
  }

  /// Check if this is the first achievement of this type today
  static bool _isFirstOfDay(String serverId, MilestoneType type, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return true;

    final today =
        DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final lastAchieved = profile.dailyFirsts[type.name];

    if (lastAchieved == null) return true;
    return !lastAchieved.toIso8601String().startsWith(today);
  }

  /// Mark that this daily achievement was earned today
  static void _markDailyFirst(
      String serverId, MilestoneType type, AppState app) {
    final profile = app.profiles[serverId];
    if (profile != null) {
      profile.dailyFirsts[type.name] = DateTime.now();
    }
  }

  /// Get current rank for a server
  static int _getCurrentRank(String serverId, AppState app) {
    final servers = app.servers;
    final counts = app.currentCounts;

    // Sort servers by run count (descending)
    final sortedServers = List<String>.from(servers.map((s) => s.id))
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    return sortedServers.indexOf(serverId) + 1;
  }

  /// Generate dynamic messages for run milestones
  static String _getRunMilestoneMessage(int runCount) {
    final messages = {
      5: [
        "🎯 FIRST MILESTONE!\nYou're in the zone!",
        "⚡ FIVE AND ALIVE!\nMomentum building!",
        "🔥 HEATING UP!\nJust getting started!",
      ],
      10: [
        "🏆 DOUBLE DIGITS!\nYou're crushing it!",
        "💎 PERFECT TEN!\nDiamond performance!",
        "👑 ROYAL STATUS!\nMajesty in motion!",
      ],
      15: [
        "🌟 FIFTEEN STRONG!\nUnstoppable force!",
        "⚡ ELECTRIC!\nPure energy!",
        "🚀 ROCKET FUEL!\nBlasting off!",
      ],
      20: [
        "🔥 TWENTY THUNDER!\nAbsolutely on fire!",
        "⭐ LEGEND MODE!\nHall of fame night!",
        "💥 EXPLOSIVE!\nBreaking barriers!",
      ],
      25: [
        "🌟 QUARTER CENTURY!\nInto the history books!",
        "🔥 BLAZING TRAIL!\nLeaving everyone behind!",
        "👑 EPIC MASTERY!\nThis is legendary!",
      ],
    };

    final categoryMessages = messages[runCount] ??
        [
          "🏆 MILESTONE MASTER!\nKeep the streak alive!",
        ];

    return categoryMessages[Random().nextInt(categoryMessages.length)];
  }

  /// Generate dynamic messages for pizookie milestones
  static String _getPizookieMilestoneMessage(int pizookieCount) {
    final messages = {
      2: [
        "🍪 DOUBLE DELIGHT!\nSweet momentum!",
        "🔥 PIZOOKIE PAIR!\nOn a roll!",
        "✨ SWEET START!\nKeep building!",
      ],
      3: [
        "🍪 TRIPLE TREAT!\nAmazing streak!",
        "🔥 PIZOOKIE POWER!\nDominating desserts!",
        "✨ SWEET TRIO!\nUnstoppable!",
      ],
      4: [
        "🍪 FANTASTIC FOUR!\nPizookie mastery!",
        "💎 QUAD SQUAD!\nPerfect precision!",
        "🌟 SWEET SUCCESS!\nIncredible!",
      ],
      5: [
        "🍪 HIGH FIVE!\nPizookie champion!",
        "👑 SWEET ROYALTY!\nRuling desserts!",
        "🔥 BLAZING BAKER!\nLegendary status!",
      ],
      6: [
        "🍪 HALF DOZEN!\nSweet mastery!",
        "💎 DIAMOND DOZEN!\nPerfect precision!",
        "🌟 SWEET SIXTEEN!\nWait, that's six!",
      ],
      8: [
        "🍪 OCTO-LICIOUS!\nPizookie perfection!",
        "👑 SWEET EMPEROR!\nRuling the kitchen!",
        "🔥 DESSERT DEITY!\nUnstoppable force!",
      ],
      10: [
        "🍪 PERFECT TEN!\nPizookie legend!",
        "👑 DESSERT OVERLORD!\nTotal domination!",
        "🔥 SWEET SUPREMACY!\nUnbeatable!",
      ],
    };

    final categoryMessages = messages[pizookieCount] ??
        [
          "🍪 PIZOOKIE LEGEND!\nSweet domination!",
        ];

    return categoryMessages[Random().nextInt(categoryMessages.length)];
  }

  /// Update ServerProfile with new message history after displaying a message
  static void _updateProfileMessageHistory(
      ServerProfile profile, String message, AppState app) {
    // Add to recent messages (keep last 50)
    profile.recentMessages.add(message);
    if (profile.recentMessages.length > 50) {
      profile.recentMessages.removeAt(0);
    }

    // Update last used timestamp
    profile.messageLastUsed[message] = DateTime.now();

    // Increment usage count
    profile.messageUsageCount[message] =
        (profile.messageUsageCount[message] ?? 0) + 1;

    // Initialize engagement score if not present (will be updated based on user interaction)
    if (!profile.messageEngagement.containsKey(message)) {
      profile.messageEngagement[message] = 1.0; // Default engagement
    }

    // Note: AppState will handle notifying listeners when profiles are updated
  }

  /// Calculate current business level based on server activity
  static double _calculateBusinessLevel(AppState app) {
    final now = DateTime.now();
    final totalActiveServers = app.profiles.length;

    // If no servers, consider it slow
    if (totalActiveServers == 0) return 0.0;

    // Count recent activity (last 15 minutes)
    int recentlyActiveServers = 0;
    int totalRecentRuns = 0;

    for (final entry in app.profiles.entries) {
      final serverId = entry.key;
      final profile = entry.value;
      final currentRuns = app.currentCounts[serverId] ?? 0;
      final lastTap = profile.lastTapIso != null
          ? DateTime.tryParse(profile.lastTapIso!)
          : null;

      if (lastTap != null) {
        final timeSinceLastTap = now.difference(lastTap).inMinutes;
        if (timeSinceLastTap <= 15) {
          recentlyActiveServers++;
          totalRecentRuns += currentRuns;
        }
      }
    }

    // Calculate business level based on:
    // 1. Percentage of servers active recently
    // 2. Average runs per active server
    final activePercentage = recentlyActiveServers / totalActiveServers;
    final avgRunsPerActive = recentlyActiveServers > 0
        ? totalRecentRuns / recentlyActiveServers
        : 0.0;

    // Normalize to 0.0-1.0 scale
    // Active percentage contributes 60%, run rate contributes 40%
    final businessLevel = (activePercentage * 0.6) +
        ((avgRunsPerActive / 20.0).clamp(0.0, 1.0) * 0.4);

    return businessLevel.clamp(0.0, 1.0);
  }
}
