import 'dart:math' as math;
import '../app_state.dart';
import 'milestone_detection_service.dart';

/// Behavioral pattern analysis for deep server personalization
enum BehaviorPattern {
  speedDemon,      // Fast, frequent clicking
  steadyEddie,     // Consistent, reliable performance
  competitiveShark, // Highly competitive, rank-focused
  teamPlayer,      // Collaborative, supportive
  perfectionist,   // High accuracy, quality-focused
  hustler,         // Money-motivated, tip-focused
  nightOwl,        // Prefers late shifts
  earlyBird,       // Prefers early shifts
  socialButterfly, // Enjoys team interactions
  soloOperator,    // Prefers independent work
}

/// Personality traits that influence messaging and rewards
enum PersonalityTrait {
  achievement,     // Driven by accomplishments
  competition,     // Thrives on rivalry
  recognition,     // Wants public acknowledgment
  autonomy,        // Values independence
  mastery,         // Seeks skill improvement
  purpose,         // Mission-driven motivation
  social,          // Enjoys team dynamics
  security,        // Stability-focused
  variety,         // Craves new experiences
  challenge,       // Seeks difficult goals
}

/// Comprehensive server personality profile
class ServerPersonality {
  final String serverId;
  final List<BehaviorPattern> dominantPatterns;
  final Map<PersonalityTrait, double> traitScores; // 0.0-1.0 intensity
  final double competitiveLevel; // 0.0-1.0
  final double socialLevel; // 0.0-1.0
  final double achievementDrive; // 0.0-1.0
  final List<String> preferredShifts; // ['lunch', 'dinner', 'late']
  final Map<String, int> rivalryLevels; // serverId -> intensity (1-10)
  final DateTime lastAnalysis;
  final int analysisVersion;

  const ServerPersonality({
    required this.serverId,
    required this.dominantPatterns,
    required this.traitScores,
    required this.competitiveLevel,
    required this.socialLevel,
    required this.achievementDrive,
    required this.preferredShifts,
    required this.rivalryLevels,
    required this.lastAnalysis,
    required this.analysisVersion,
  });

  factory ServerPersonality.defaultProfile(String serverId) {
    return ServerPersonality(
      serverId: serverId,
      dominantPatterns: [BehaviorPattern.steadyEddie],
      traitScores: {
        PersonalityTrait.achievement: 0.5,
        PersonalityTrait.competition: 0.5,
        PersonalityTrait.recognition: 0.5,
        PersonalityTrait.autonomy: 0.5,
        PersonalityTrait.mastery: 0.5,
        PersonalityTrait.purpose: 0.5,
        PersonalityTrait.social: 0.5,
        PersonalityTrait.security: 0.5,
        PersonalityTrait.variety: 0.5,
        PersonalityTrait.challenge: 0.5,
      },
      competitiveLevel: 0.5,
      socialLevel: 0.5,
      achievementDrive: 0.5,
      preferredShifts: ['lunch', 'dinner'],
      rivalryLevels: {},
      lastAnalysis: DateTime.now(),
      analysisVersion: 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serverId': serverId,
      'dominantPatterns': dominantPatterns.map((p) => p.name).toList(),
      'traitScores': traitScores.map((key, value) => MapEntry(key.name, value)),
      'competitiveLevel': competitiveLevel,
      'socialLevel': socialLevel,
      'achievementDrive': achievementDrive,
      'preferredShifts': preferredShifts,
      'rivalryLevels': rivalryLevels,
      'lastAnalysis': lastAnalysis.toIso8601String(),
      'analysisVersion': analysisVersion,
    };
  }

  factory ServerPersonality.fromMap(Map<String, dynamic> map) {
    return ServerPersonality(
      serverId: map['serverId'] ?? '',
      dominantPatterns: (map['dominantPatterns'] as List<dynamic>?)
          ?.map((name) => BehaviorPattern.values.firstWhere((p) => p.name == name))
          .toList() ?? [BehaviorPattern.steadyEddie],
      traitScores: Map<PersonalityTrait, double>.fromEntries(
        (map['traitScores'] as Map<String, dynamic>?)?.entries.map(
          (entry) => MapEntry(
            PersonalityTrait.values.firstWhere((t) => t.name == entry.key),
            (entry.value as num).toDouble(),
          ),
        ) ?? PersonalityTrait.values.map((t) => MapEntry(t, 0.5)),
      ),
      competitiveLevel: (map['competitiveLevel'] as num?)?.toDouble() ?? 0.5,
      socialLevel: (map['socialLevel'] as num?)?.toDouble() ?? 0.5,
      achievementDrive: (map['achievementDrive'] as num?)?.toDouble() ?? 0.5,
      preferredShifts: List<String>.from(map['preferredShifts'] ?? ['lunch', 'dinner']),
      rivalryLevels: Map<String, int>.from(map['rivalryLevels'] ?? {}),
      lastAnalysis: DateTime.tryParse(map['lastAnalysis'] ?? '') ?? DateTime.now(),
      analysisVersion: map['analysisVersion'] ?? 1,
    );
  }
}

/// Advanced server personalization and behavioral analysis service
class ServerPersonalizationService {
  static const int _analysisHistoryDays = 30;
  static const int _minDataPointsForAnalysis = 10;
  static const double _patternConfidenceThreshold = 0.7;

  /// Analyze server behavior and generate personality profile
  static ServerPersonality analyzeServerPersonality(String serverId, ServerProfile profile) {
    final now = DateTime.now();
    
    // Behavioral pattern analysis
    final patterns = _analyzeBehaviorPatterns(profile);
    
    // Personality trait scoring
    final traitScores = _calculateTraitScores(profile, patterns);
    
    // Competitive analysis
    final competitiveLevel = _calculateCompetitiveLevel(profile);
    
    // Social analysis
    final socialLevel = _calculateSocialLevel(profile);
    
    // Achievement drive analysis
    final achievementDrive = _calculateAchievementDrive(profile);
    
    // Shift preference analysis
    final preferredShifts = _analyzeShiftPreferences(profile);
    
    // Rivalry detection (placeholder - needs multi-server data)
    final rivalryLevels = <String, int>{};

    return ServerPersonality(
      serverId: serverId,
      dominantPatterns: patterns,
      traitScores: traitScores,
      competitiveLevel: competitiveLevel,
      socialLevel: socialLevel,
      achievementDrive: achievementDrive,
      preferredShifts: preferredShifts,
      rivalryLevels: rivalryLevels,
      lastAnalysis: now,
      analysisVersion: 1,
    );
  }

  /// Generate personalized milestone message based on server personality
  static String generatePersonalizedMessage(
    MilestoneAchievement achievement,
    ServerPersonality personality,
    ServerProfile profile,
  ) {
    final dominant = personality.dominantPatterns.isNotEmpty 
        ? personality.dominantPatterns.first 
        : BehaviorPattern.steadyEddie;
    
    final topTrait = personality.traitScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return _selectPersonalizedMessage(achievement, dominant, topTrait, personality, profile);
  }

  /// Predict optimal reward timing for maximum psychological impact
  static Duration predictOptimalRewardDelay(ServerPersonality personality) {
    // Speed demons prefer immediate feedback
    if (personality.dominantPatterns.contains(BehaviorPattern.speedDemon)) {
      return Duration(milliseconds: 100);
    }
    
    // Perfectionists appreciate slight delay for anticipation
    if (personality.dominantPatterns.contains(BehaviorPattern.perfectionist)) {
      return Duration(milliseconds: 800);
    }
    
    // Default balanced timing
    return Duration(milliseconds: 400);
  }

  /// Calculate addiction score (how hooked the server is)
  static double calculateAddictionScore(ServerProfile profile, ServerPersonality personality) {
    double score = 0.0;
    
    // Frequency factor (0.0-0.3)
    final recentActivity = profile.recentTapTimes.length;
    score += math.min(recentActivity / 100.0, 0.3);
    
    // Engagement streak factor (0.0-0.2)
    final milestoneCount = profile.milestoneHistory.length;
    score += math.min(milestoneCount / 50.0, 0.2);
    
    // Competitive engagement factor (0.0-0.2)
    score += personality.competitiveLevel * 0.2;
    
    // Achievement drive factor (0.0-0.15)
    score += personality.achievementDrive * 0.15;
    
    // Pattern consistency factor (0.0-0.15)
    final patternCount = personality.dominantPatterns.length;
    score += math.min(patternCount / 5.0, 0.15);
    
    return math.min(score, 1.0);
  }

  // Private analysis methods
  
  static List<BehaviorPattern> _analyzeBehaviorPatterns(ServerProfile profile) {
    final patterns = <BehaviorPattern>[];
    
    // Speed analysis
    final avgSpeed = _calculateAverageClickSpeed(profile);
    if (avgSpeed > 2.0) patterns.add(BehaviorPattern.speedDemon);
    else if (avgSpeed > 0.5 && avgSpeed <= 1.0) patterns.add(BehaviorPattern.steadyEddie);
    
    // Competitive analysis
    final competitiveness = _analyzeCompetitiveness(profile);
    if (competitiveness > 0.7) patterns.add(BehaviorPattern.competitiveShark);
    
    // Perfectionist analysis
    final consistency = _analyzeConsistency(profile);
    if (consistency > 0.8) patterns.add(BehaviorPattern.perfectionist);
    
    // Default pattern if none detected
    if (patterns.isEmpty) patterns.add(BehaviorPattern.steadyEddie);
    
    return patterns;
  }

  static Map<PersonalityTrait, double> _calculateTraitScores(
    ServerProfile profile, 
    List<BehaviorPattern> patterns,
  ) {
    final scores = <PersonalityTrait, double>{};
    
    // Initialize all traits
    for (final trait in PersonalityTrait.values) {
      scores[trait] = 0.5; // Neutral baseline
    }
    
    // Achievement scoring
    final milestoneCount = profile.milestoneHistory.length;
    scores[PersonalityTrait.achievement] = math.min(milestoneCount / 20.0, 1.0);
    
    // Competition scoring
    final rankFocus = profile.lastKnownRank != null ? 0.8 : 0.3;
    scores[PersonalityTrait.competition] = rankFocus;
    
    // Mastery scoring (based on consistency)
    final consistency = _analyzeConsistency(profile);
    scores[PersonalityTrait.mastery] = consistency;
    
    // Variety scoring (based on shift diversity)
    final shiftVariety = _calculateShiftVariety(profile);
    scores[PersonalityTrait.variety] = shiftVariety;
    
    return scores;
  }

  static double _calculateCompetitiveLevel(ServerProfile profile) {
    double level = 0.5;
    
    // Rank awareness boosts competitiveness
    if (profile.lastKnownRank != null) level += 0.3;
    
    // Milestone focus indicates competitiveness
    final milestoneCount = profile.milestoneHistory.length;
    level += math.min(milestoneCount / 30.0, 0.2);
    
    return math.min(level, 1.0);
  }

  static double _calculateSocialLevel(ServerProfile profile) {
    // Placeholder - would need team interaction data
    return 0.5;
  }

  static double _calculateAchievementDrive(ServerProfile profile) {
    final milestoneCount = profile.milestoneHistory.length;
    final activityLevel = profile.recentTapTimes.length;
    
    return math.min((milestoneCount + activityLevel) / 50.0, 1.0);
  }

  static List<String> _analyzeShiftPreferences(ServerProfile profile) {
    // Placeholder - would analyze timing patterns
    return ['lunch', 'dinner'];
  }

  static double _calculateAverageClickSpeed(ServerProfile profile) {
    if (profile.recentTapTimes.length < 2) return 0.5;
    
    final times = profile.recentTapTimes;
    double totalInterval = 0;
    for (int i = 1; i < times.length; i++) {
      totalInterval += times[i].difference(times[i-1]).inMilliseconds;
    }
    
    final avgInterval = totalInterval / (times.length - 1);
    return 1000.0 / avgInterval; // clicks per second
  }

  static double _analyzeCompetitiveness(ServerProfile profile) {
    // High milestone count + rank tracking = competitive
    final milestoneScore = math.min(profile.milestoneHistory.length / 20.0, 0.7);
    final rankScore = profile.lastKnownRank != null ? 0.3 : 0.0;
    return milestoneScore + rankScore;
  }

  static double _analyzeConsistency(ServerProfile profile) {
    if (profile.recentTapTimes.isEmpty) return 0.5;
    
    // Analyze timing consistency (lower variance = higher consistency)
    final times = profile.recentTapTimes;
    if (times.length < 3) return 0.5;
    
    final intervals = <double>[];
    for (int i = 1; i < times.length; i++) {
      intervals.add(times[i].difference(times[i-1]).inMilliseconds.toDouble());
    }
    
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((x) => math.pow(x - mean, 2).toDouble()).reduce((a, b) => a + b) / intervals.length;
    final standardDeviation = math.sqrt(variance);
    
    // Lower standard deviation = higher consistency
    return math.max(0.0, 1.0 - (standardDeviation / mean));
  }

  static double _calculateShiftVariety(ServerProfile profile) {
    // Placeholder - would analyze timing patterns across shifts
    return 0.5;
  }

  static String _selectPersonalizedMessage(
    MilestoneAchievement achievement,
    BehaviorPattern pattern,
    PersonalityTrait trait,
    ServerPersonality personality,
    ServerProfile profile,
  ) {
    final random = math.Random();
    
    // Speed demon messages
    if (pattern == BehaviorPattern.speedDemon) {
      final speedMessages = [
        "🔥 Lightning fast! +${achievement.xpReward} XP for that speed!",
        "⚡ SPEED DEMON! +${achievement.xpReward} XP earned!",
        "🚀 Blazing fast clicks! +${achievement.xpReward} XP bonus!",
        "💨 You're on fire! +${achievement.xpReward} XP for that pace!",
        "🏃‍♂️ Can't slow you down! +${achievement.xpReward} XP!",
      ];
      return speedMessages[random.nextInt(speedMessages.length)];
    }
    
    // Competitive shark messages
    if (pattern == BehaviorPattern.competitiveShark) {
      final competitiveMessages = [
        "🦈 DOMINATING! +${achievement.xpReward} XP to stay ahead!",
        "👑 Leader mentality! +${achievement.xpReward} XP earned!",
        "🥇 Champion moves! +${achievement.xpReward} XP bonus!",
        "⚔️ Crushing the competition! +${achievement.xpReward} XP!",
        "🎯 Target acquired! +${achievement.xpReward} XP for excellence!",
      ];
      return competitiveMessages[random.nextInt(competitiveMessages.length)];
    }
    
    // Perfectionist messages
    if (pattern == BehaviorPattern.perfectionist) {
      final perfectionistMessages = [
        "✨ Flawless execution! +${achievement.xpReward} XP for perfection!",
        "🎯 Precision mastery! +${achievement.xpReward} XP earned!",
        "💎 Quality work! +${achievement.xpReward} XP bonus!",
        "🔬 Methodical excellence! +${achievement.xpReward} XP!",
        "📐 Perfect technique! +${achievement.xpReward} XP reward!",
      ];
      return perfectionistMessages[random.nextInt(perfectionistMessages.length)];
    }
    
    // Achievement-focused messages
    if (trait == PersonalityTrait.achievement) {
      final achievementMessages = [
        "🏆 Achievement unlocked! +${achievement.xpReward} XP earned!",
        "🎖️ Goal crusher! +${achievement.xpReward} XP bonus!",
        "🥇 Another milestone! +${achievement.xpReward} XP for progress!",
        "📈 Level up mindset! +${achievement.xpReward} XP!",
        "🎪 Success streak! +${achievement.xpReward} XP reward!",
      ];
      return achievementMessages[random.nextInt(achievementMessages.length)];
    }
    
    // Default personalized message
    return "🌟 Great work! +${achievement.xpReward} XP earned!";
  }
}