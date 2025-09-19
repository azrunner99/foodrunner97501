import 'dart:math' as math;
import '../models.dart';
import '../models/performance_models.dart';
import '../app_state.dart';
import '../utils/performance_calculator.dart';

/// Advanced gamification system integrated with performance analysis
/// Provides dynamic achievements, XP multipliers, and performance-based rewards
class PerformanceGamificationEngine {
  // Feature flags to gate new behavior.
  static const bool kEnableGamificationEnhancements = false;
  static const int _baseXpPerRun = 10;
  static const double _performanceMultiplierCap = 3.0;
  static const double _consistencyBonusMultiplier = 1.2;

  /// Calculate performance-based XP with dynamic multipliers
  static int calculatePerformanceXP({
    required String serverId,
    required int runsCompleted,
    required DateTime shiftDate,
    ServerPerformanceData? recentPerformance,
    bool isPizookieRun = false,
  }) {
    var baseXp = runsCompleted * _baseXpPerRun;

    if (isPizookieRun) {
      baseXp = (baseXp * 2.5).round(); // Pizookie bonus
    }

    // Apply performance multiplier if available
    if (recentPerformance != null) {
      final performanceMultiplier =
          _calculatePerformanceMultiplier(recentPerformance);
      baseXp = (baseXp * performanceMultiplier).round();
    }

    // Apply streak bonuses
    final streakMultiplier = _calculateStreakMultiplier(serverId);
    baseXp = (baseXp * streakMultiplier).round();

    // Apply consistency bonus
    final consistencyMultiplier = _calculateConsistencyMultiplier(serverId);
    baseXp = (baseXp * consistencyMultiplier).round();

    return baseXp;
  }

  /// Generate performance-based achievements
  static List<PerformanceAchievement> checkPerformanceAchievements(
    String serverId,
    ServerPerformanceData performance,
  ) {
    final achievements = <PerformanceAchievement>[];
    final appState = AppState();
    final profile = appState.profiles[serverId] ?? ServerProfile();

    // Elite Performer achievements
    if (performance.performanceScore >= 90.0) {
      achievements.add(PerformanceAchievement(
        id: 'elite_performer_${DateTime.now().millisecondsSinceEpoch}',
        serverId: serverId,
        type: AchievementType.performance,
        title: '🔥 Elite Performer',
        description:
            'Achieved ${performance.performanceScore.toStringAsFixed(1)}% performance score!',
        xpReward: 500,
        badgeIcon: '🏆',
        unlockedDate: DateTime.now(),
        rarity: AchievementRarity.legendary,
        category: 'Performance Excellence',
        requirements: 'Achieve 90%+ performance score',
        progressValue: performance.performanceScore,
        maxValue: 100.0,
      ));
    }

    // Consistency Master achievements
    if (performance.metrics.consistencyScore >= 85.0) {
      achievements.add(PerformanceAchievement(
        id: 'consistency_master_${DateTime.now().millisecondsSinceEpoch}',
        serverId: serverId,
        type: AchievementType.consistency,
        title: '🎯 Consistency Master',
        description:
            'Demonstrated exceptional consistency (${performance.metrics.consistencyScore.toStringAsFixed(1)}%)',
        xpReward: 300,
        badgeIcon: '🎯',
        unlockedDate: DateTime.now(),
        rarity: AchievementRarity.epic,
        category: 'Consistency',
        requirements: 'Achieve 85%+ consistency score',
        progressValue: performance.metrics.consistencyScore,
        maxValue: 100.0,
      ));
    }

    // Efficiency Expert achievements
    if (performance.metrics.rawEfficiency >= 8.0) {
      achievements.add(PerformanceAchievement(
        id: 'efficiency_expert_${DateTime.now().millisecondsSinceEpoch}',
        serverId: serverId,
        type: AchievementType.efficiency,
        title: '⚡ Efficiency Expert',
        description:
            'Outstanding efficiency: ${performance.metrics.rawEfficiency.toStringAsFixed(1)} runs per shift',
        xpReward: 250,
        badgeIcon: '⚡',
        unlockedDate: DateTime.now(),
        rarity: AchievementRarity.rare,
        category: 'Efficiency',
        requirements: 'Achieve 8+ runs per shift efficiency',
        progressValue: performance.metrics.rawEfficiency,
        maxValue: 15.0,
      ));
    }

    // Improvement achievements
    final previousPerformance = _getPreviousPerformanceScore(serverId);
    if (previousPerformance != null) {
      final improvement = performance.performanceScore - previousPerformance;
      if (improvement >= 10.0) {
        achievements.add(PerformanceAchievement(
          id: 'rapid_improvement_${DateTime.now().millisecondsSinceEpoch}',
          serverId: serverId,
          type: AchievementType.improvement,
          title: '📈 Rapid Improvement',
          description:
              'Improved performance by ${improvement.toStringAsFixed(1)} points!',
          xpReward: 200,
          badgeIcon: '📈',
          unlockedDate: DateTime.now(),
          rarity: AchievementRarity.uncommon,
          category: 'Growth',
          requirements: 'Improve performance by 10+ points',
          progressValue: improvement,
          maxValue: 50.0,
        ));
      }
    }

    // Milestone achievements
    if (profile.allTimeRuns >= 1000 &&
        !_hasAchievement(serverId, 'thousand_runs')) {
      achievements.add(PerformanceAchievement(
        id: 'thousand_runs',
        serverId: serverId,
        type: AchievementType.milestone,
        title: '🚀 Thousand Club',
        description: 'Completed 1,000 food runs!',
        xpReward: 1000,
        badgeIcon: '🚀',
        unlockedDate: DateTime.now(),
        rarity: AchievementRarity.legendary,
        category: 'Milestones',
        requirements: 'Complete 1,000 food runs',
        progressValue: profile.allTimeRuns.toDouble(),
        maxValue: 1000.0,
      ));
    }

    return achievements;
  }

  /// Calculate dynamic leaderboard with performance weighting
  static List<PerformanceLeaderboardEntry> calculatePerformanceLeaderboard({
    required List<Server> servers,
    required Duration timeFrame,
    LeaderboardType type = LeaderboardType.overall,
    AppState? appState,
  }) {
    // Build a temporary collection to compute ranks and deltas first,
    // then materialize immutable leaderboard entries.
    final temp = <Map<String, dynamic>>[];
    final state = appState ?? AppState();
    final shifts = state.history;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(timeFrame);

    for (final server in servers) {
      final performance = PerformanceCalculator.calculateServerPerformance(
        serverId: server.id,
        startDate: startDate,
        endDate: endDate,
        shifts: shifts,
        businessData: null,
        hireDate: DateTime.now().subtract(const Duration(days: 90)),
      );

  final profile = state.profiles[server.id] ?? ServerProfile();

      double score;
      String metric;

      switch (type) {
        case LeaderboardType.performance:
          score = performance.performanceScore;
          metric = 'Performance Score';
          break;
        case LeaderboardType.efficiency:
          score = performance.metrics.rawEfficiency;
          metric = 'Efficiency (runs/shift)';
          break;
        case LeaderboardType.consistency:
          score = performance.metrics.consistencyScore;
          metric = 'Consistency Score';
          break;
        case LeaderboardType.xp:
          score = profile.points.toDouble();
          metric = 'Experience Points';
          break;
        case LeaderboardType.overall:
          score = _calculateOverallScore(performance, profile);
          metric = 'Overall Score';
          break;
      }

      temp.add({
        'serverId': server.id,
        'serverName': server.name,
        'score': score,
        'metric': metric,
        'performance': performance,
        'profile': profile,
        'badge': _calculatePerformanceBadge(performance),
      });
    }

    // Sort and assign ranks
    temp.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    final entries = <PerformanceLeaderboardEntry>[];
    for (int i = 0; i < temp.length; i++) {
      final t = temp[i];
      final currentRank = i + 1;
      final profile = t['profile'] as ServerProfile;

      // Rank delta under flag: positive means improved (moved up, lower number)
      int change = 0;
      if (kEnableGamificationEnhancements && profile.lastKnownRank != null) {
        change = profile.lastKnownRank! - currentRank;
      }

      // Optionally update lastKnownRank for future comparisons
      if (kEnableGamificationEnhancements) {
        profile.lastKnownRank = currentRank;
      }

      // Recent achievements: milestone-based; optionally augment with performance-based when enabled
      final recent = _getRecentAchievements(t['serverId'] as String, profiles: state.profiles);
      final perfBased = kEnableGamificationEnhancements
          ? checkPerformanceAchievements(t['serverId'] as String, t['performance'] as ServerPerformanceData)
          : <PerformanceAchievement>[];
      final achievements = <PerformanceAchievement>[...recent, ...perfBased];

      entries.add(PerformanceLeaderboardEntry(
        serverId: t['serverId'] as String,
        serverName: t['serverName'] as String,
        score: t['score'] as double,
        metric: t['metric'] as String,
        performance: t['performance'] as ServerPerformanceData,
        profile: profile,
        rank: currentRank,
        change: change,
        achievements: achievements.take(3).toList(),
        badge: t['badge'] as PerformanceBadge,
      ));
    }

    return entries;
  }

  /// Generate performance-based rewards and bonuses
  static List<PerformanceReward> generatePerformanceRewards(
    String serverId,
    ServerPerformanceData performance,
    Duration period,
  ) {
    final rewards = <PerformanceReward>[];

    // Elite performance bonus
    if (performance.performanceScore >= 95.0) {
      rewards.add(PerformanceReward(
        id: 'elite_bonus_${DateTime.now().millisecondsSinceEpoch}',
        serverId: serverId,
        type: RewardType.xpBonus,
        title: 'Elite Performance Bonus',
        description: 'Outstanding performance deserves recognition!',
        value: 1000.0,
        multiplier: 2.0,
        duration: const Duration(days: 7),
        unlockedDate: DateTime.now(),
        requirements: '95%+ performance score',
      ));
    }

    // Consistency reward
    if (performance.metrics.consistencyScore >= 90.0) {
      rewards.add(PerformanceReward(
        id: 'consistency_reward_${DateTime.now().millisecondsSinceEpoch}',
        serverId: serverId,
        type: RewardType.xpMultiplier,
        title: 'Consistency Reward',
        description: 'Reliable performance earns lasting benefits',
        value: 0.0,
        multiplier: 1.5,
        duration: const Duration(days: 3),
        unlockedDate: DateTime.now(),
        requirements: '90%+ consistency score',
      ));
    }

    // Improvement bonus
    final previousScore = _getPreviousPerformanceScore(serverId);
    if (previousScore != null &&
        performance.performanceScore > previousScore + 5) {
      rewards.add(PerformanceReward(
        id: 'improvement_bonus_${DateTime.now().millisecondsSinceEpoch}',
        serverId: serverId,
        type: RewardType.xpBonus,
        title: 'Improvement Bonus',
        description: 'Great progress! Keep up the momentum!',
        value: 500.0,
        multiplier: 1.0,
        duration: const Duration(days: 1),
        unlockedDate: DateTime.now(),
        requirements: '5+ point improvement',
      ));
    }

    return rewards;
  }

  /// Check for performance milestones and create challenges
  static List<PerformanceChallenge> generatePerformanceChallenges(
    String serverId,
    ServerPerformanceData currentPerformance,
  ) {
    final challenges = <PerformanceChallenge>[];

    // Performance improvement challenge
    if (currentPerformance.performanceScore < 80.0) {
      challenges.add(PerformanceChallenge(
        id: 'reach_80_performance',
        serverId: serverId,
        title: 'Reach 80% Performance',
        description: 'Improve your performance score to 80% or higher',
        targetValue: 80.0,
        currentValue: currentPerformance.performanceScore,
        rewardXp: 300,
        deadline: DateTime.now().add(const Duration(days: 14)),
        category: 'Performance',
        difficulty: ChallengeDifficulty.medium,
      ));
    }

    // Consistency challenge
    if (currentPerformance.metrics.consistencyScore < 75.0) {
      challenges.add(PerformanceChallenge(
        id: 'improve_consistency',
        serverId: serverId,
        title: 'Boost Consistency',
        description: 'Achieve 75% consistency score',
        targetValue: 75.0,
        currentValue: currentPerformance.metrics.consistencyScore,
        rewardXp: 250,
        deadline: DateTime.now().add(const Duration(days: 10)),
        category: 'Consistency',
        difficulty: ChallengeDifficulty.medium,
      ));
    }

    // Efficiency challenge
    if (currentPerformance.metrics.rawEfficiency < 6.0) {
      challenges.add(PerformanceChallenge(
        id: 'boost_efficiency',
        serverId: serverId,
        title: 'Efficiency Boost',
        description: 'Reach 6 runs per shift average',
        targetValue: 6.0,
        currentValue: currentPerformance.metrics.rawEfficiency,
        rewardXp: 200,
        deadline: DateTime.now().add(const Duration(days: 7)),
        category: 'Efficiency',
        difficulty: ChallengeDifficulty.easy,
      ));
    }

    return challenges;
  }

  /// Calculate performance multiplier based on current performance
  static double _calculatePerformanceMultiplier(
      ServerPerformanceData performance) {
    final baseMultiplier = 1.0;
    final performanceBonus =
        (performance.performanceScore - 50.0) / 100.0; // 0-0.5 bonus
    final efficiencyBonus = math.min(
        performance.metrics.rawEfficiency / 10.0, 0.3); // Up to 0.3 bonus
    final consistencyBonus =
        performance.metrics.consistencyScore / 500.0; // Up to 0.2 bonus

    final totalMultiplier =
        baseMultiplier + performanceBonus + efficiencyBonus + consistencyBonus;
    return math.min(totalMultiplier, _performanceMultiplierCap);
  }

  /// Calculate streak multiplier
  static double _calculateStreakMultiplier(String serverId) {
    // Calculate recent consistency and apply bonus
    final recentPerformance = _getRecentPerformanceData(serverId);
    if (recentPerformance != null &&
        recentPerformance.metrics.consistencyScore > 80.0) {
      return _consistencyBonusMultiplier;
    }
    return 1.0;
  }

  /// Calculate consistency multiplier
  static double _calculateConsistencyMultiplier(String serverId) {
    // Implement streak calculation based on recent performance
    // This would need to track daily/weekly streaks
    return 1.0; // Placeholder - would implement streak tracking
  }

  /// Get previous performance score for comparison
  static double? _getPreviousPerformanceScore(String serverId) {
    // This would implement historical performance tracking
    // For now, return null to indicate no previous data
    return null;
  }

  /// Check if server has specific achievement
  static bool _hasAchievement(String serverId, String achievementId) {
    // This would check achievement database
    // For now, return false to allow new achievements
    return false;
  }

  /// Get recent performance data
  static ServerPerformanceData? _getRecentPerformanceData(String serverId, {AppState? appState}) {
    final state = appState ?? AppState();
    final shifts = state.history;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));

    return PerformanceCalculator.calculateServerPerformance(
      serverId: serverId,
      startDate: startDate,
      endDate: endDate,
      shifts: shifts,
      businessData: null,
      hireDate: DateTime.now().subtract(const Duration(days: 90)),
    );
  }

  /// Calculate overall performance score combining multiple metrics
  static double _calculateOverallScore(
      ServerPerformanceData performance, ServerProfile profile) {
    final performanceWeight = 0.4;
    final efficiencyWeight = 0.3;
    final consistencyWeight = 0.2;
    final xpWeight = 0.1;

    final normalizedXp =
        math.min(profile.points / 10000.0, 1.0) * 100; // Normalize XP to 0-100

    return (performance.performanceScore * performanceWeight) +
        (performance.metrics.rawEfficiency *
            10 *
            efficiencyWeight) + // Scale efficiency to 0-100
        (performance.metrics.consistencyScore * consistencyWeight) +
        (normalizedXp * xpWeight);
  }

  /// Calculate rank change for leaderboard
  static int _calculateRankChange(String serverId, LeaderboardType type, {Map<String, ServerProfile>? profiles}) {
    if (!kEnableGamificationEnhancements || profiles == null) return 0;
    final profile = profiles[serverId];
    if (profile == null) return 0;
    final last = profile.lastKnownRank;
    if (last == null) return 0;
    // Positive change means moved up (lower rank number)
    // Assume current rank will be set after sorting; here we can't know it yet.
    // Return 0 now; callers can recompute change post ranking if desired.
    return 0;
  }

  /// Get recent achievements for a server
  static List<PerformanceAchievement> _getRecentAchievements(String serverId, {Map<String, ServerProfile>? profiles}) {
    if (!kEnableGamificationEnhancements || profiles == null) return [];
    final profile = profiles[serverId];
    if (profile == null) return [];
    // Surface the 3 most recent milestoneHistory items as achievements, if present
    final recent = profile.milestoneHistory
        .map((m) => PerformanceAchievement(
              id: m['id']?.toString() ?? 'milestone_${DateTime.now().millisecondsSinceEpoch}',
              serverId: serverId,
              type: AchievementType.milestone,
              title: m['title']?.toString() ?? 'Milestone',
              description: m['description']?.toString() ?? 'Recent milestone achieved',
              xpReward: (m['xp'] as int?) ?? 0,
              badgeIcon: m['icon']?.toString() ?? '⭐',
              unlockedDate: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
              rarity: AchievementRarity.common,
              category: m['category']?.toString() ?? 'Milestones',
              requirements: m['requirements']?.toString() ?? '',
              progressValue: 1.0,
              maxValue: 1.0,
            ))
        .toList();
    recent.sort((a, b) => b.unlockedDate.compareTo(a.unlockedDate));
    return recent.take(3).toList();
  }

  /// Calculate performance badge based on current metrics
  static PerformanceBadge _calculatePerformanceBadge(
      ServerPerformanceData performance) {
    if (performance.performanceScore >= 95.0) {
      return PerformanceBadge.legendary;
    } else if (performance.performanceScore >= 85.0) {
      return PerformanceBadge.epic;
    } else if (performance.performanceScore >= 75.0) {
      return PerformanceBadge.rare;
    } else if (performance.performanceScore >= 65.0) {
      return PerformanceBadge.uncommon;
    } else {
      return PerformanceBadge.common;
    }
  }
}

/// Data classes for gamification integration

class PerformanceAchievement {
  final String id;
  final String serverId;
  final AchievementType type;
  final String title;
  final String description;
  final int xpReward;
  final String badgeIcon;
  final DateTime unlockedDate;
  final AchievementRarity rarity;
  final String category;
  final String requirements;
  final double progressValue;
  final double maxValue;

  PerformanceAchievement({
    required this.id,
    required this.serverId,
    required this.type,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.badgeIcon,
    required this.unlockedDate,
    required this.rarity,
    required this.category,
    required this.requirements,
    required this.progressValue,
    required this.maxValue,
  });

  double get progress =>
      maxValue > 0 ? math.min(progressValue / maxValue, 1.0) : 1.0;
}

enum AchievementType {
  performance,
  efficiency,
  consistency,
  improvement,
  milestone,
  streak,
  teamwork,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class PerformanceLeaderboardEntry {
  final String serverId;
  final String serverName;
  final double score;
  final String metric;
  final ServerPerformanceData performance;
  final ServerProfile profile;
  int rank;
  final int change;
  final List<PerformanceAchievement> achievements;
  final PerformanceBadge badge;

  PerformanceLeaderboardEntry({
    required this.serverId,
    required this.serverName,
    required this.score,
    required this.metric,
    required this.performance,
    required this.profile,
    required this.rank,
    required this.change,
    required this.achievements,
    required this.badge,
  });
}

enum LeaderboardType {
  overall,
  performance,
  efficiency,
  consistency,
  xp,
}

enum PerformanceBadge {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

extension PerformanceBadgeExtension on PerformanceBadge {
  String get displayName {
    switch (this) {
      case PerformanceBadge.common:
        return 'Bronze';
      case PerformanceBadge.uncommon:
        return 'Silver';
      case PerformanceBadge.rare:
        return 'Gold';
      case PerformanceBadge.epic:
        return 'Platinum';
      case PerformanceBadge.legendary:
        return 'Diamond';
    }
  }

  String get icon {
    switch (this) {
      case PerformanceBadge.common:
        return '🥉';
      case PerformanceBadge.uncommon:
        return '🥈';
      case PerformanceBadge.rare:
        return '🥇';
      case PerformanceBadge.epic:
        return '💎';
      case PerformanceBadge.legendary:
        return '👑';
    }
  }

  String get color {
    switch (this) {
      case PerformanceBadge.common:
        return '#CD7F32'; // Bronze
      case PerformanceBadge.uncommon:
        return '#C0C0C0'; // Silver
      case PerformanceBadge.rare:
        return '#FFD700'; // Gold
      case PerformanceBadge.epic:
        return '#E5E4E2'; // Platinum
      case PerformanceBadge.legendary:
        return '#B9F2FF'; // Diamond
    }
  }
}

class PerformanceReward {
  final String id;
  final String serverId;
  final RewardType type;
  final String title;
  final String description;
  final double value;
  final double multiplier;
  final Duration duration;
  final DateTime unlockedDate;
  final String requirements;

  PerformanceReward({
    required this.id,
    required this.serverId,
    required this.type,
    required this.title,
    required this.description,
    required this.value,
    required this.multiplier,
    required this.duration,
    required this.unlockedDate,
    required this.requirements,
  });
}

enum RewardType {
  xpBonus,
  xpMultiplier,
  badge,
  title,
  privilege,
}

class PerformanceChallenge {
  final String id;
  final String serverId;
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final int rewardXp;
  final DateTime deadline;
  final String category;
  final ChallengeDifficulty difficulty;

  PerformanceChallenge({
    required this.id,
    required this.serverId,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.rewardXp,
    required this.deadline,
    required this.category,
    required this.difficulty,
  });

  double get progress =>
      targetValue > 0 ? math.min(currentValue / targetValue, 1.0) : 1.0;
  bool get isCompleted => currentValue >= targetValue;
  bool get isExpired => DateTime.now().isAfter(deadline);
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert,
}
