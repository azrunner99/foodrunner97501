import 'dart:math' as math;
import '../app_state.dart';

/// Social competition events that trigger rivalry messages
enum RivalryEvent {
  overtaken, // Someone passed you in ranking
  overtaking, // You passed someone else
  leadExpanded, // You expanded your lead
  leadThreatened, // Someone is catching up to you
  streakBroken, // Your streak was broken by someone
  streakThreatened, // Someone is threatening your streak
  teamGoalProgress, // Team making progress toward goal
  speedChallenge, // Speed competition between servers
  comebackStory, // Dramatic comeback from behind
  dominationMode, // Complete dominance over others
}

/// Team challenge types for social competition
enum TeamChallengeType {
  totalRuns, // Team needs X total runs
  speedBurst, // Complete X runs in Y minutes as team
  perfectShift, // All team members maintain streak
  competitiveBalance, // Even performance across team
  recoveryChallenge, // Team comeback from poor performance
  enduranceTest, // Sustained performance over time
}

/// Social pressure messaging types
enum SocialPressureType {
  praise, // Public recognition and praise
  shaming, // Gentle competitive shaming
  encouragement, // Support after poor performance
  intimidation, // Psychological pressure tactics
  inspiration, // Motivational peer examples
  urgency, // Time-sensitive competitive pressure
}

/// Individual rivalry relationship tracking
class RivalryRelationship {
  final String serverId1;
  final String serverId2;
  int wins1 = 0;
  int wins2 = 0;
  DateTime? lastEncounter;
  List<String> recentEvents = [];
  double intensityLevel = 0.5; // 0.0 to 1.0

  RivalryRelationship({
    required this.serverId1,
    required this.serverId2,
  });

  String get winner => wins1 > wins2 ? serverId1 : serverId2;
  String get loser => wins1 > wins2 ? serverId2 : serverId1;
  int get winMargin => (wins1 - wins2).abs();
  bool get isIntenseRivalry => intensityLevel > 0.7;
}

/// Team challenge instance
class TeamChallenge {
  final String id;
  final TeamChallengeType type;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participantIds;
  final Map<String, int> progress;
  final int targetValue;
  bool isActive = true;
  bool isCompleted = false;

  TeamChallenge({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.parameters,
    required this.startTime,
    required this.endTime,
    required this.participantIds,
    required this.targetValue,
  }) : progress = {};

  double get progressPercentage => targetValue > 0
      ? (progress.values.fold(0, (a, b) => a + b) / targetValue).clamp(0.0, 1.0)
      : 0.0;

  Duration get timeRemaining => endTime.difference(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(endTime);
}

/// Social competition engine for maximum peer pressure and rivalry
class SocialCompetitionService {
  static final Map<String, RivalryRelationship> _rivalries = {};
  static final List<TeamChallenge> _activeTeamChallenges = [];
  static final Map<String, List<String>> _serverStreaks = {};

  /// Analyze current leaderboard and generate rivalry messages
  static List<String> generateRivalryMessages(String serverId, AppState app) {
    final messages = <String>[];

    // Get both current shift and all-time rankings
    final currentRanks = _calculateCurrentRanks(app);
    final allTimeRanks = _calculateAllTimeRanks(app);
    final serverRank = currentRanks[serverId] ?? 999;
    final allTimeRank = allTimeRanks[serverId] ?? 999;

    // Check for recent rank changes with career context
    final profile = app.profiles[serverId];
    if (profile != null && profile.lastKnownRank != null) {
      final rankChange = profile.lastKnownRank! - serverRank;
      final careerContext = _getCareerContext(profile);

      if (rankChange > 0) {
        // Moved up in ranking - use dual context messaging
        messages.addAll(_generateDualContextOvertakingMessages(serverId,
            rankChange, currentRanks, allTimeRanks, careerContext, app));
      } else if (rankChange < 0) {
        // Moved down in ranking - emphasize career vs current disparity
        messages.addAll(_generateDualContextOvertakenMessages(serverId,
            rankChange.abs(), currentRanks, allTimeRanks, careerContext, app));
      }
    }

    // Check for career rank vs shift rank disparities
    final rankDisparity = allTimeRank - serverRank;
    if (rankDisparity.abs() > 2) {
      messages.addAll(_generateRankDisparityMessages(
          serverId, serverRank, allTimeRank, app));
    }

    // Enhanced leadership/chase messages with career legacy
    if (serverRank == 1) {
      messages.addAll(_generateDualContextLeaderMessages(
          serverId, allTimeRank, app, currentRanks));
    } else if (serverRank <= 3) {
      messages.addAll(_generateDualContextChaseMessages(
          serverId, allTimeRank, app, currentRanks));
    }

    // Update stored rank for next comparison
    if (profile != null) {
      profile.lastKnownRank = serverRank;
    }

    return messages;
  }

  /// Generate team challenge
  static TeamChallenge createTeamChallenge(
    List<String> serverIds,
    TeamChallengeType type,
    AppState app,
  ) {
    final challengeId = 'team_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(hours: 2)); // 2-hour challenges

    late String name;
    late String description;
    late int targetValue;
    late Map<String, dynamic> parameters;

    switch (type) {
      case TeamChallengeType.totalRuns:
        targetValue = serverIds.length * 15; // 15 runs per person
        name = "Team Sprint Challenge";
        description = "Team needs $targetValue total runs in 2 hours!";
        parameters = {'runsPerPerson': 15};
        break;

      case TeamChallengeType.speedBurst:
        targetValue = serverIds.length * 8; // 8 runs in 30 minutes
        name = "Lightning Team Burst";
        description = "Complete $targetValue runs as a team in 30 minutes!";
        parameters = {'timeLimit': 30, 'runsPerPerson': 8};
        break;

      case TeamChallengeType.perfectShift:
        targetValue = serverIds.length; // All must maintain streak
        name = "Perfect Harmony Challenge";
        description =
            "Every team member must maintain their streak for 2 hours!";
        parameters = {'streakRequired': true};
        break;

      case TeamChallengeType.competitiveBalance:
        targetValue = 100; // Balance score
        name = "Balanced Excellence";
        description = "Achieve balanced performance across all team members!";
        parameters = {'balanceThreshold': 0.8};
        break;

      case TeamChallengeType.recoveryChallenge:
        targetValue = serverIds.length * 20; // Recovery runs
        name = "Comeback Kings Challenge";
        description = "Team comeback with $targetValue total runs!";
        parameters = {'recoveryMode': true};
        break;

      case TeamChallengeType.enduranceTest:
        targetValue = serverIds.length * 25; // Endurance runs
        name = "Endurance Legends Challenge";
        description = "Sustain excellence with $targetValue runs over 2 hours!";
        parameters = {'sustainedRate': true};
        break;
    }

    final challenge = TeamChallenge(
      id: challengeId,
      type: type,
      name: name,
      description: description,
      parameters: parameters,
      startTime: startTime,
      endTime: endTime,
      participantIds: List.from(serverIds),
      targetValue: targetValue,
    );

    _activeTeamChallenges.add(challenge);
    return challenge;
  }

  /// Generate social pressure messages based on context
  static List<String> generateSocialPressureMessages(
      String serverId, SocialPressureType type, AppState app,
      {Map<String, dynamic>? context}) {
    final profile = app.profiles[serverId];
    if (profile == null) return [];

    switch (type) {
      case SocialPressureType.praise:
        return [
          "🌟 EVERYONE'S WATCHING! You're absolutely dominating!",
          "👑 TEAM HERO! Your performance is inspiring everyone!",
          "🔥 LEGENDARY STATUS! Other servers are taking notes!",
          "⚡ UNSTOPPABLE FORCE! You're setting the standard!",
        ];

      case SocialPressureType.shaming:
        return [
          "😤 Sarah just passed you! Time to show her who's boss!",
          "🏃‍♀️ Mike is gaining ground... Don't let him catch you!",
          "⏰ You're falling behind the pack! Rally time!",
          "🎯 The team is counting on you to step up!",
        ];

      case SocialPressureType.encouragement:
        return [
          "💪 Your team believes in you! One run at a time!",
          "🤝 Everyone has rough patches - you've got this!",
          "🔄 Comeback stories are the best stories! Start yours now!",
          "⭐ Champions are made in moments like this!",
        ];

      case SocialPressureType.intimidation:
        return [
          "👀 EVERYONE'S WATCHING! Don't choke under pressure!",
          "🎯 PROVE YOUR WORTH! Show them you belong at the top!",
          "⚔️ BATTLE MODE! Crush the competition now!",
          "🔥 NO MERCY! This is your moment to dominate!",
        ];

      case SocialPressureType.inspiration:
        return [
          "🌟 Remember when Jessica came back from 5th to 1st? Your turn!",
          "💪 Mike's legendary 20-run streak started with one tap!",
          "🏆 Sarah's perfect shift record is within your reach!",
          "⚡ Channel that competitive fire that got you here!",
        ];

      case SocialPressureType.urgency:
        return [
          "⏰ 10 MINUTES LEFT! Make every second count!",
          "🚨 FINAL PUSH! The team needs you NOW!",
          "⚡ CLOSING TIME! This is your last chance to shine!",
          "🎯 NOW OR NEVER! Prove your championship heart!",
        ];
    }
  }

  /// Update team challenge progress
  static void updateTeamChallengeProgress(
      String serverId, int newRuns, AppState app) {
    for (final challenge in _activeTeamChallenges) {
      if (challenge.participantIds.contains(serverId) &&
          challenge.isActive &&
          !challenge.isExpired) {
        challenge.progress[serverId] =
            (challenge.progress[serverId] ?? 0) + newRuns;

        // Check if challenge completed
        final totalProgress =
            challenge.progress.values.fold(0, (a, b) => a + b);
        if (totalProgress >= challenge.targetValue) {
          challenge.isCompleted = true;
          challenge.isActive = false;

          // Award team completion bonuses
          _awardTeamCompletionBonuses(challenge, app);
        }
      }
    }
  }

  /// Track streak competitions between servers
  static void updateStreakCompetition(
      String serverId, int currentStreak, AppState app) {
    _serverStreaks[serverId] = [
      ...(_serverStreaks[serverId] ?? []),
      currentStreak.toString(),
    ].take(10).toList(); // Keep last 10 streaks

    // Check for streak-based rivalry events
    final messages =
        _generateStreakRivalryMessages(serverId, currentStreak, app);

    // Trigger streak competition messages if significant
    if (messages.isNotEmpty) {
      // These would be displayed through the existing message system
    }
  }

  /// Calculate current ranking of all servers
  static Map<String, int> _calculateCurrentRanks(AppState app) {
    final serverScores = <String, int>{};

    // Calculate scores (current runs + bonus for consistency)
    for (final entry in app.profiles.entries) {
      final serverId = entry.key;
      final currentRuns = app.currentCounts[serverId] ?? 0;
      final avgSpeed = entry.value.avgSecondsBetweenRuns;
      final bonusPoints = avgSpeed > 0 ? (60 / avgSpeed * 2).round() : 0;

      serverScores[serverId] = currentRuns + bonusPoints;
    }

    // Sort by score and assign ranks
    final sortedEntries = serverScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final ranks = <String, int>{};
    for (int i = 0; i < sortedEntries.length; i++) {
      ranks[sortedEntries[i].key] = i + 1;
    }

    return ranks;
  }

  /// Calculate all-time ranking of all servers
  static Map<String, int> _calculateAllTimeRanks(AppState app) {
    final serverScores = <String, int>{};

    // Calculate all-time scores (total career runs + career points + achievements)
    for (final entry in app.profiles.entries) {
      final serverId = entry.key;
      final profile = entry.value;
      final allTimeScore = profile.allTimeRuns * 10 +
          profile.points +
          profile.achievements.length * 50 +
          profile.bestShiftRuns * 5;

      serverScores[serverId] = allTimeScore;
    }

    // Sort by score and assign ranks
    final sortedEntries = serverScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final ranks = <String, int>{};
    for (int i = 0; i < sortedEntries.length; i++) {
      ranks[sortedEntries[i].key] = i + 1;
    }

    return ranks;
  }

  /// Get career context for psychological messaging
  static Map<String, dynamic> _getCareerContext(ServerProfile profile) {
    final isVeteran = profile.allTimeRuns > 1000;
    final isElite = profile.points > 5000;
    final isConsistent = profile.bestShiftRuns > 0 &&
        profile.allTimeRuns / (profile.bestShiftRuns * 50) > 0.6;
    final achievementLevel = profile.achievements.length;

    String careerTier;
    if (isVeteran && isElite) {
      careerTier = 'legend';
    } else if (isVeteran || isElite) {
      careerTier = 'veteran';
    } else if (profile.allTimeRuns > 500) {
      careerTier = 'experienced';
    } else if (profile.allTimeRuns > 100) {
      careerTier = 'developing';
    } else {
      careerTier = 'rookie';
    }

    return {
      'tier': careerTier,
      'isVeteran': isVeteran,
      'isElite': isElite,
      'isConsistent': isConsistent,
      'achievementLevel': achievementLevel,
      'allTimeRuns': profile.allTimeRuns,
      'bestShiftRuns': profile.bestShiftRuns,
      'totalPoints': profile.points,
    };
  }

  /// Generate messages for overtaking other servers
  static List<String> _generateOvertakingMessages(
    String serverId,
    int rankImprovement,
    Map<String, int> currentRanks,
    AppState app,
  ) {
    final messages = <String>[];
    final newRank = currentRanks[serverId] ?? 999;

    if (rankImprovement == 1) {
      messages.addAll([
        "💨 OVERTAKE! You just passed someone! Keep climbing!",
        "🏃‍♀️ MOVING UP! One more spot claimed! Who's next?",
        "⚡ SURGE! You're on the move! Don't stop now!",
        "🎯 PROGRESS! Another competitor left in the dust!",
      ]);
    } else if (rankImprovement >= 2) {
      messages.addAll([
        "🚀 ROCKET CLIMB! +$rankImprovement spots! You're unstoppable!",
        "⚡ LIGHTNING RISE! Jumped $rankImprovement places! Incredible!",
        "🏆 POWER SURGE! $rankImprovement rivals conquered! Legendary!",
        "🔥 EXPLOSIVE CLIMB! +$rankImprovement ranks! Pure domination!",
      ]);
    }

    if (newRank <= 3) {
      messages.addAll([
        "👑 TOP 3! You're in elite territory now!",
        "🥉 PODIUM POSITION! The pressure is real!",
        "🎖️ MEDAL CONTENTION! Championship level!",
      ]);
    }

    return messages;
  }

  /// Generate messages for being overtaken
  static List<String> _generateOvertakenMessages(
    String serverId,
    int rankLoss,
    Map<String, int> currentRanks,
    AppState app,
  ) {
    final messages = <String>[];

    if (rankLoss == 1) {
      messages.addAll([
        "😤 OVERTAKEN! Someone just passed you! Fight back!",
        "🚨 ALERT! You dropped a spot! Time to respond!",
        "⚔️ CHALLENGE! Your position is under attack!",
        "🔥 REVENGE TIME! Show them who's really boss!",
      ]);
    } else if (rankLoss >= 2) {
      messages.addAll([
        "🚨 FREEFALL! Down $rankLoss spots! EMERGENCY RESPONSE!",
        "💥 WAKE UP CALL! -$rankLoss ranks! Time to dominate!",
        "⚡ COMEBACK MODE! $rankLoss places lost! Unleash everything!",
        "🔥 RALLY TIME! Down $rankLoss! Show your championship heart!",
      ]);
    }

    return messages;
  }

  /// Generate messages for current leader
  static List<String> _generateLeaderMessages(
    String serverId,
    AppState app,
    Map<String, int> currentRanks,
  ) {
    final messages = <String>[];
    final secondPlaceId = currentRanks.entries
        .where((e) => e.value == 2)
        .map((e) => e.key)
        .firstOrNull;

    if (secondPlaceId != null) {
      final gap = (app.currentCounts[serverId] ?? 0) -
          (app.currentCounts[secondPlaceId] ?? 0);

      if (gap >= 5) {
        messages.addAll([
          "👑 COMMANDING LEAD! +$gap ahead! Total domination!",
          "🏆 UNTOUCHABLE! $gap run cushion! Legendary!",
          "⚡ ELITE DISTANCE! +$gap separation! Championship form!",
        ]);
      } else if (gap <= 2) {
        messages.addAll([
          "🚨 TIGHT RACE! Only +$gap ahead! Maintain pressure!",
          "⚔️ BATTLE ZONE! $gap run lead! Every tap counts!",
          "🔥 HEATED COMPETITION! +$gap! Don't let up!",
        ]);
      }
    }

    return messages;
  }

  /// Generate messages for servers chasing the leader
  static List<String> _generateChaseMessages(
    String serverId,
    AppState app,
    Map<String, int> currentRanks,
  ) {
    final messages = <String>[];
    final leaderId = currentRanks.entries
        .where((e) => e.value == 1)
        .map((e) => e.key)
        .firstOrNull;

    if (leaderId != null) {
      final gap = (app.currentCounts[leaderId] ?? 0) -
          (app.currentCounts[serverId] ?? 0);

      if (gap <= 3) {
        messages.addAll([
          "🎯 STRIKING DISTANCE! Only $gap behind! Attack mode!",
          "⚡ CLOSING IN! $gap runs to go! Feel the pressure building!",
          "🔥 HUNTING SEASON! $gap back! Time to make your move!",
        ]);
      } else if (gap >= 8) {
        messages.addAll([
          "🚀 COMEBACK STORY! $gap behind! Legendary rallies start now!",
          "💪 MOUNTAIN TO CLIMB! -$gap! Champions rise to challenges!",
          "⚡ MIRACLE MODE! $gap deficit! Show your warrior spirit!",
        ]);
      }
    }

    return messages;
  }

  /// Generate streak-based rivalry messages
  static List<String> _generateStreakRivalryMessages(
    String serverId,
    int currentStreak,
    AppState app,
  ) {
    final messages = <String>[];

    // Find other servers with notable streaks
    final otherStreaks = <String, int>{};
    for (final entry in app.profiles.entries) {
      if (entry.key != serverId) {
        final otherStreak = _calculateCurrentStreak(entry.key, app);
        if (otherStreak >= 3) {
          otherStreaks[entry.key] = otherStreak;
        }
      }
    }

    // Generate competitive streak messages
    final maxOtherStreak = otherStreaks.values.isNotEmpty
        ? otherStreaks.values.reduce(math.max)
        : 0;

    if (currentStreak > maxOtherStreak && currentStreak >= 5) {
      messages.addAll([
        "🔥 STREAK KING! $currentStreak in a row! Streak domination!",
        "⚡ CONSISTENCY CHAMPION! $currentStreak straight! Untouchable!",
        "👑 STREAK ROYALTY! $currentStreak consecutive! Legendary discipline!",
      ]);
    } else if (currentStreak < maxOtherStreak) {
      messages.addAll([
        "🎯 STREAK CHALLENGE! Someone has $maxOtherStreak! Chase them down!",
        "🔥 STREAK RACE! Behind by ${maxOtherStreak - currentStreak}! Catch up!",
        "⚡ CONSISTENCY BATTLE! $maxOtherStreak vs your $currentStreak! Fight!",
      ]);
    }

    return messages;
  }

  /// Calculate current streak for a server
  static int _calculateCurrentStreak(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return 0;

    // Simple streak calculation based on recent consistent performance
    // This would be enhanced with actual streak tracking in a real implementation
    final currentRuns = app.currentCounts[serverId] ?? 0;
    return currentRuns >= 3 ? (currentRuns / 2).floor() : 0;
  }

  /// Award bonuses for completing team challenges
  static void _awardTeamCompletionBonuses(
      TeamChallenge challenge, AppState app) {
    final bonusXP = 100 * challenge.participantIds.length; // Team multiplier

    for (final serverId in challenge.participantIds) {
      final profile = app.profiles[serverId];
      if (profile != null) {
        profile.points += bonusXP;

        // Add team achievement
        if (!profile.achievements.contains('team_${challenge.type.name}')) {
          profile.achievements.add('team_${challenge.type.name}');
        }
      }
    }
  }

  /// Generate dual-context overtaking messages combining career and shift data
  static List<String> _generateDualContextOvertakingMessages(
    String serverId,
    int rankImprovement,
    Map<String, int> currentRanks,
    Map<String, int> allTimeRanks,
    Map<String, dynamic> careerContext,
    AppState app,
  ) {
    final messages = <String>[];
    final newRank = currentRanks[serverId] ?? 999;
    final allTimeRank = allTimeRanks[serverId] ?? 999;
    final careerTier = careerContext['tier'] as String;
    final allTimeRuns = careerContext['allTimeRuns'] as int;

    if (rankImprovement == 1) {
      switch (careerTier) {
        case 'legend':
          messages.addAll([
            "👑 LEGEND RISES! $allTimeRuns+ career runs backing this climb!",
            "⚡ VETERAN POWER! Your experience is showing! +1 rank!",
            "🔥 ELITE DOMINANCE! They should know better than to challenge you!",
          ]);
          break;
        case 'veteran':
          messages.addAll([
            "💪 EXPERIENCE PAYS! Your $allTimeRuns career runs prove it!",
            "🎯 VETERAN MOVE! Steady climb from a seasoned pro!",
            "⚔️ OLD SCHOOL POWER! +1 rank with classic dominance!",
          ]);
          break;
        default:
          messages.addAll([
            "🚀 RISING STAR! Building your legacy one rank at a time!",
            "⚡ HUNGER! Each climb brings you closer to greatness!",
            "💨 MOMENTUM! Your potential is starting to show!",
          ]);
      }
    } else if (rankImprovement >= 2) {
      if (allTimeRank <= 3 && newRank > 5) {
        messages.addAll([
          "😤 AWAKENING! Top 3 all-time talent activated! +$rankImprovement spots!",
          "🔥 REMEMBER WHO YOU ARE! Career rank #$allTimeRank doesn't stay down!",
          "👑 LEGEND MODE! Your $allTimeRuns runs weren't for nothing!",
        ]);
      } else {
        messages.addAll([
          "🚀 EXPLOSIVE! +$rankImprovement ranks! Pure $careerTier power!",
          "⚡ SURGE! Career momentum unleashed! $rankImprovement spots claimed!",
          "💥 BREAKTHROUGH! This is what $allTimeRuns career runs taught you!",
        ]);
      }
    }

    // Add rank disparity awareness
    if (allTimeRank < newRank) {
      final disparity = newRank - allTimeRank;
      messages.add(
          "📈 CLOSING GAP! Career rank #$allTimeRank vs current #$newRank - $disparity spots to claim your legacy!");
    }

    return messages;
  }

  /// Generate dual-context overtaken messages emphasizing career vs current performance
  static List<String> _generateDualContextOvertakenMessages(
    String serverId,
    int rankLoss,
    Map<String, int> currentRanks,
    Map<String, int> allTimeRanks,
    Map<String, dynamic> careerContext,
    AppState app,
  ) {
    final messages = <String>[];
    final newRank = currentRanks[serverId] ?? 999;
    final allTimeRank = allTimeRanks[serverId] ?? 999;
    final careerTier = careerContext['tier'] as String;
    final allTimeRuns = careerContext['allTimeRuns'] as int;

    if (allTimeRank <= 3 && newRank > 5) {
      // Elite career performer underperforming
      messages.addAll([
        "🚨 LEGACY ALERT! Career rank #$allTimeRank sitting at #$newRank!",
        "👑 WAKE UP CALL! Your $allTimeRuns runs demand better!",
        "🔥 REPUTATION ON THE LINE! Time to defend your legend status!",
        "⚡ REMEMBER YOUR GREATNESS! This isn't the real you!",
      ]);
    } else if (careerTier == 'legend' || careerTier == 'veteran') {
      messages.addAll([
        "😤 VETERAN PRIDE! -$rankLoss spots? Your $allTimeRuns runs say NO!",
        "⚔️ EXPERIENCE MATTERS! Time to show them what ${careerTier}s do!",
        "🔥 LEGACY DEFENSE! Career rank #$allTimeRank doesn't back down!",
        "💪 PROVE THE DOUBTERS WRONG! Your track record speaks volumes!",
      ]);
    } else {
      messages.addAll([
        "🚨 SETBACK ALERT! -$rankLoss spots, but your potential remains!",
        "⚡ LEARNING MOMENT! Each challenge builds your legacy!",
        "🎯 COMEBACK TIME! Show them this $careerTier has fight!",
      ]);
    }

    return messages;
  }

  /// Generate rank disparity messages when career rank differs significantly from current rank
  static List<String> _generateRankDisparityMessages(
    String serverId,
    int currentRank,
    int allTimeRank,
    AppState app,
  ) {
    final messages = <String>[];
    final profile = app.profiles[serverId];
    if (profile == null) return messages;

    final disparity = currentRank - allTimeRank;

    if (disparity > 3) {
      // Underperforming compared to career rank
      messages.addAll([
        "📉 DISPARITY ALERT! Career rank #$allTimeRank vs current #$currentRank!",
        "🎯 LEGACY CHALLENGE! Your ${profile.allTimeRuns} runs deserve better!",
        "⚡ POTENTIAL UNLEASHED! Time to match your career performance!",
        "👑 RANK RECOVERY MISSION! Climb back to where you belong!",
      ]);
    } else if (disparity < -3) {
      // Overperforming compared to career rank
      messages.addAll([
        "🚀 BREAKTHROUGH! Current #$currentRank vs career #$allTimeRank!",
        "⚡ EXCEEDING EXPECTATIONS! This could be your best shift ever!",
        "🔥 PEAK PERFORMANCE! Surpassing your own standards!",
        "💫 LEGENDARY SHIFT! Setting new personal records!",
      ]);
    }

    return messages;
  }

  /// Generate dual-context leader messages
  static List<String> _generateDualContextLeaderMessages(
    String serverId,
    int allTimeRank,
    AppState app,
    Map<String, int> currentRanks,
  ) {
    final messages = <String>[];
    final profile = app.profiles[serverId]!;

    if (allTimeRank == 1) {
      messages.addAll([
        "👑 ABSOLUTE DOMINANCE! #1 career, #1 shift - pure perfection!",
        "🏆 LEGENDARY STATUS! Defending your throne with ${profile.allTimeRuns} career runs!",
        "⚡ TOTAL SUPREMACY! Career and shift leadership united!",
      ]);
    } else if (allTimeRank <= 3) {
      messages.addAll([
        "🔥 ELITE LEADING! Career top 3 showing current dominance!",
        "👑 PROVEN LEADER! Your ${profile.allTimeRuns} runs prepared you for this!",
        "⚡ EXPERIENCE LEADS! Career rank #$allTimeRank knowledge paying off!",
      ]);
    } else {
      messages.addAll([
        "🚀 BREAKTHROUGH LEADERSHIP! Exceeding career rank #$allTimeRank!",
        "⚡ PEAK PERFORMANCE! Leading despite career rank #$allTimeRank!",
        "💫 LEGENDARY SHIFT! This could redefine your career standing!",
      ]);
    }

    return messages;
  }

  /// Generate dual-context chase messages
  static List<String> _generateDualContextChaseMessages(
    String serverId,
    int allTimeRank,
    AppState app,
    Map<String, int> currentRanks,
  ) {
    final messages = <String>[];
    final profile = app.profiles[serverId]!;
    final currentRank = currentRanks[serverId] ?? 999;

    if (allTimeRank == 1 && currentRank > 1) {
      messages.addAll([
        "👑 THRONE RECOVERY! Career #1 climbing back to rightful position!",
        "🔥 LEGEND AWAKENING! Your ${profile.allTimeRuns} runs demand the lead!",
        "⚡ INEVITABLE RISE! #1 career talent can't be denied!",
      ]);
    } else if (allTimeRank <= 3) {
      messages.addAll([
        "💪 ELITE PURSUIT! Career top 3 in striking distance!",
        "🎯 VETERAN HUNT! Your experience level belongs at the top!",
        "⚔️ PROVEN THREAT! Career rank #$allTimeRank knowledge activated!",
      ]);
    } else {
      messages.addAll([
        "🚀 EXCEEDING LIMITS! Outperforming career rank #$allTimeRank!",
        "⚡ POTENTIAL REALIZED! This could be your career-defining shift!",
        "💫 BREAKTHROUGH MOMENT! Proving you belong with the elite!",
      ]);
    }

    return messages;
  }
}

/// Extension for nullable iteration
extension on Iterable<String> {
  String? get firstOrNull => isNotEmpty ? first : null;
}
