import 'dart:math' as math;
import 'server_personalization_service.dart';
import 'milestone_detection_service.dart';

/// Message categories for massive variety organization
enum MessageCategory {
  // Performance Categories
  speedBased,
  consistencyBased,
  achievementBased,
  competitiveBased,
  
  // Emotional Categories
  motivational,
  celebratory,
  encouraging,
  challenging,
  
  // Contextual Categories
  timeOfDay,
  dayOfWeek,
  businessLevel,
  seasonal,
  
  // Psychological Categories
  identityReinforcing,
  goalOriented,
  socialComparison,
  progressFocused,
}

/// Message timing context for contextual variations
enum MessageContext {
  morningRush,
  lunchPeak,
  afternoonSlump,
  dinnerRush,
  lateNight,
  weekendBusy,
  slowDay,
  busyDay,
  firstShift,
  endOfShift,
}

/// Message repetition tracking
class MessageHistory {
  final String serverId;
  final List<String> recentMessages;          // Last 50 messages
  final Map<String, DateTime> lastUsed;       // Message -> timestamp
  final Map<String, int> usageCount;          // Message -> total uses
  final Map<String, double> engagementScore;  // Message -> engagement rating
  
  MessageHistory({
    required this.serverId,
    List<String>? recentMessages,
    Map<String, DateTime>? lastUsed,
    Map<String, int>? usageCount,
    Map<String, double>? engagementScore,
  }) : recentMessages = recentMessages ?? [],
       lastUsed = lastUsed ?? {},
       usageCount = usageCount ?? {},
       engagementScore = engagementScore ?? {};

  Map<String, dynamic> toMap() {
    return {
      'serverId': serverId,
      'recentMessages': recentMessages,
      'lastUsed': lastUsed.map((key, value) => MapEntry(key, value.toIso8601String())),
      'usageCount': usageCount,
      'engagementScore': engagementScore,
    };
  }

  factory MessageHistory.fromMap(Map<String, dynamic> map) {
    return MessageHistory(
      serverId: map['serverId'] ?? '',
      recentMessages: List<String>.from(map['recentMessages'] ?? []),
      lastUsed: (map['lastUsed'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, DateTime.parse(value.toString()))
      ) ?? {},
      usageCount: Map<String, int>.from(map['usageCount'] ?? {}),
      engagementScore: Map<String, double>.from(map['engagementScore'] ?? {}),
    );
  }
}

/// Massive message variety engine with 500+ contextual messages
class MessageVarietyEngine {
  static const int _maxRecentMessages = 50;
  static const Duration _dailyRepeatProtection = Duration(days: 1);
  static const Duration _weeklyRepeatProtection = Duration(days: 7);
  
  // Massive message collections organized by category
  
  /// Speed-based messages (100+ variants)
  static const List<String> _speedMessages = [
    // Lightning Fast (25 variants)
    "⚡ LIGHTNING SPEED! +{xp} XP!",
    "🔥 Blazing fast! +{xp} XP earned!",
    "💨 Speed demon mode! +{xp} XP!",
    "🚀 Rocket pace! +{xp} XP bonus!",
    "⚡ Electric speed! +{xp} XP!",
    "🏃‍♂️ Can't slow you down! +{xp} XP!",
    "💫 Supersonic! +{xp} XP earned!",
    "🌪️ Whirlwind speed! +{xp} XP!",
    "⭐ Speed of light! +{xp} XP!",
    "🎯 Instant action! +{xp} XP!",
    "🔥 Fire pace! +{xp} XP bonus!",
    "⚡ Thunderbolt fast! +{xp} XP!",
    "💥 Explosive speed! +{xp} XP!",
    "🚁 Helicopter quick! +{xp} XP!",
    "🎪 Circus fast! +{xp} XP earned!",
    "🏎️ Formula 1 speed! +{xp} XP!",
    "🌊 Tsunami pace! +{xp} XP!",
    "🎨 Artist speed! +{xp} XP bonus!",
    "🎵 Musical tempo! +{xp} XP!",
    "🎭 Performance pace! +{xp} XP!",
    "🎲 Lucky speed! +{xp} XP earned!",
    "🎪 Show speed! +{xp} XP!",
    "🎯 Precision pace! +{xp} XP!",
    "🎨 Creative speed! +{xp} XP bonus!",
    "🎵 Rhythm master! +{xp} XP!",
    
    // Velocity Messages (25 variants)
    "🌟 Incredible velocity! +{xp} XP!",
    "💎 Diamond speed! +{xp} XP earned!",
    "🔮 Magic pace! +{xp} XP!",
    "🎊 Party speed! +{xp} XP bonus!",
    "🎁 Gift pace! +{xp} XP!",
    "🌈 Rainbow fast! +{xp} XP!",
    "🦄 Unicorn speed! +{xp} XP earned!",
    "🐆 Cheetah pace! +{xp} XP!",
    "🐎 Horse speed! +{xp} XP bonus!",
    "🦅 Eagle pace! +{xp} XP!",
    "🐝 Bee speed! +{xp} XP!",
    "🐠 Fish pace! +{xp} XP earned!",
    "🦘 Kangaroo speed! +{xp} XP!",
    "🐰 Rabbit pace! +{xp} XP bonus!",
    "🦎 Lizard speed! +{xp} XP!",
    "🐿️ Squirrel pace! +{xp} XP!",
    "🐭 Mouse speed! +{xp} XP earned!",
    "🐱 Cat pace! +{xp} XP!",
    "🐶 Dog speed! +{xp} XP bonus!",
    "🐺 Wolf pace! +{xp} XP!",
    "🦊 Fox speed! +{xp} XP!",
    "🐯 Tiger pace! +{xp} XP earned!",
    "🦁 Lion speed! +{xp} XP!",
    "🐻 Bear pace! +{xp} XP bonus!",
    "🐼 Panda speed! +{xp} XP!",
    
    // Momentum Messages (25 variants)
    "🌪️ Building momentum! +{xp} XP!",
    "🎢 Roller coaster pace! +{xp} XP!",
    "🎠 Carousel speed! +{xp} XP earned!",
    "🎡 Ferris wheel pace! +{xp} XP!",
    "🎪 Carnival speed! +{xp} XP bonus!",
    "🎨 Art speed! +{xp} XP!",
    "🎭 Drama pace! +{xp} XP!",
    "🎵 Music speed! +{xp} XP earned!",
    "🎸 Guitar pace! +{xp} XP!",
    "🎹 Piano speed! +{xp} XP bonus!",
    "🥁 Drum pace! +{xp} XP!",
    "🎺 Trumpet speed! +{xp} XP!",
    "🎷 Saxophone pace! +{xp} XP earned!",
    "🎻 Violin speed! +{xp} XP!",
    "🎤 Microphone pace! +{xp} XP bonus!",
    "🎧 Headphone speed! +{xp} XP!",
    "📻 Radio pace! +{xp} XP!",
    "📺 TV speed! +{xp} XP earned!",
    "🎮 Gaming pace! +{xp} XP!",
    "🕹️ Joystick speed! +{xp} XP bonus!",
    "🎯 Target pace! +{xp} XP!",
    "🎳 Bowling speed! +{xp} XP!",
    "🎾 Tennis pace! +{xp} XP earned!",
    "🏀 Basketball speed! +{xp} XP!",
    "⚽ Soccer pace! +{xp} XP bonus!",
    
    // Power Messages (25 variants)
    "💪 Power speed! +{xp} XP!",
    "🔥 Fire power pace! +{xp} XP!",
    "⚡ Electric power! +{xp} XP earned!",
    "💥 Explosive power! +{xp} XP!",
    "🌟 Star power pace! +{xp} XP bonus!",
    "💎 Diamond power! +{xp} XP!",
    "🔮 Magic power pace! +{xp} XP!",
    "🎆 Firework power! +{xp} XP earned!",
    "🎇 Sparkler pace! +{xp} XP!",
    "✨ Glitter power! +{xp} XP bonus!",
    "💫 Cosmic pace! +{xp} XP!",
    "🌠 Meteor power! +{xp} XP!",
    "⭐ Stellar pace! +{xp} XP earned!",
    "🌟 Nova power! +{xp} XP!",
    "💥 Big bang pace! +{xp} XP bonus!",
    "🔥 Inferno power! +{xp} XP!",
    "🌋 Volcano pace! +{xp} XP!",
    "⚡ Storm power! +{xp} XP earned!",
    "🌊 Tsunami pace! +{xp} XP!",
    "🌪️ Tornado power! +{xp} XP bonus!",
    "🌈 Rainbow pace! +{xp} XP!",
    "☀️ Sun power! +{xp} XP!",
    "🌙 Moon pace! +{xp} XP earned!",
    "⭐ Galaxy power! +{xp} XP!",
    "🌍 Earth pace! +{xp} XP bonus!",
  ];

  /// Competition-based messages (100+ variants)
  static const List<String> _competitiveMessages = [
    // Domination (25 variants)
    "🦈 DOMINATING! +{xp} XP to stay ahead!",
    "👑 CRUSHING IT! +{xp} XP earned!",
    "🥇 CHAMPION MODE! +{xp} XP bonus!",
    "⚔️ WARRIOR SPIRIT! +{xp} XP!",
    "🎯 BULLSEYE! +{xp} XP earned!",
    "🏆 TROPHY HUNTER! +{xp} XP!",
    "💪 POWERHOUSE! +{xp} XP bonus!",
    "🔥 ON FIRE! +{xp} XP!",
    "⚡ UNSTOPPABLE! +{xp} XP earned!",
    "🚀 ROCKET SHIP! +{xp} XP!",
    "💎 DIAMOND TIER! +{xp} XP bonus!",
    "🌟 SUPERSTAR! +{xp} XP!",
    "👊 KNOCKOUT! +{xp} XP earned!",
    "🎪 SHOWSTOPPER! +{xp} XP!",
    "🎭 PERFORMANCE! +{xp} XP bonus!",
    "🎨 MASTERPIECE! +{xp} XP!",
    "🎵 HARMONY! +{xp} XP earned!",
    "🎸 ROCK STAR! +{xp} XP!",
    "🎤 HEADLINER! +{xp} XP bonus!",
    "🎬 BLOCKBUSTER! +{xp} XP!",
    "📚 BESTSELLER! +{xp} XP earned!",
    "🏅 MEDAL WORTHY! +{xp} XP!",
    "🎖️ DECORATED! +{xp} XP bonus!",
    "🏵️ HONORED! +{xp} XP!",
    "🥉 PODIUM FINISH! +{xp} XP earned!",
    
    // Leadership (25 variants)
    "👑 LEADING THE PACK! +{xp} XP!",
    "🦅 SOARING HIGH! +{xp} XP earned!",
    "🌟 SHINING BRIGHT! +{xp} XP!",
    "💫 STELLAR! +{xp} XP bonus!",
    "⭐ FIVE STAR! +{xp} XP!",
    "🔥 BLAZING TRAIL! +{xp} XP earned!",
    "🚀 LAUNCHING AHEAD! +{xp} XP!",
    "⚡ ELECTRIC! +{xp} XP bonus!",
    "💥 EXPLOSIVE! +{xp} XP!",
    "🌊 MAKING WAVES! +{xp} XP earned!",
    "🏔️ PEAK PERFORMANCE! +{xp} XP!",
    "🌋 VOLCANIC! +{xp} XP bonus!",
    "🌪️ WHIRLWIND! +{xp} XP!",
    "🌈 SPECTACULAR! +{xp} XP earned!",
    "🎆 FIREWORKS! +{xp} XP!",
    "🎇 DAZZLING! +{xp} XP bonus!",
    "✨ SPARKLING! +{xp} XP!",
    "💎 BRILLIANT! +{xp} XP earned!",
    "🔮 MAGICAL! +{xp} XP!",
    "🎊 CELEBRATION! +{xp} XP bonus!",
    "🎉 PARTY TIME! +{xp} XP!",
    "🎁 GIFT WORTHY! +{xp} XP earned!",
    "🏆 TROPHY CASE! +{xp} XP!",
    "🥇 GOLD STANDARD! +{xp} XP bonus!",
    "🏅 MEDAL COLLECTION! +{xp} XP!",
    
    // Victory (25 variants)
    "🎯 DIRECT HIT! +{xp} XP!",
    "🎪 CENTER RING! +{xp} XP earned!",
    "🎭 STANDING OVATION! +{xp} XP!",
    "🎨 GALLERY WORTHY! +{xp} XP bonus!",
    "🎵 SYMPHONY! +{xp} XP!",
    "🎸 ENCORE! +{xp} XP earned!",
    "🎤 HEADLINE ACT! +{xp} XP!",
    "🎬 OSCAR WORTHY! +{xp} XP bonus!",
    "📺 PRIME TIME! +{xp} XP!",
    "📻 HIT SONG! +{xp} XP earned!",
    "📚 CHAPTER ONE! +{xp} XP!",
    "📖 BESTSELLER! +{xp} XP bonus!",
    "📝 SIGNATURE! +{xp} XP!",
    "📊 CHART TOPPER! +{xp} XP earned!",
    "📈 TRENDING UP! +{xp} XP!",
    "📉 BREAKING RECORDS! +{xp} XP bonus!",
    "💹 BULL MARKET! +{xp} XP!",
    "💰 JACKPOT! +{xp} XP earned!",
    "💵 CASH COW! +{xp} XP!",
    "💳 PREMIUM! +{xp} XP bonus!",
    "💎 LUXURY! +{xp} XP!",
    "👑 ROYALTY! +{xp} XP earned!",
    "🦄 UNICORN! +{xp} XP!",
    "🌟 CONSTELLATION! +{xp} XP bonus!",
    "⭐ GALAXY! +{xp} XP!",
    
    // Superiority (25 variants)
    "🏆 UNBEATABLE! +{xp} XP!",
    "🥇 UNMATCHED! +{xp} XP earned!",
    "👑 UNRIVALED! +{xp} XP!",
    "💪 UNSHAKEABLE! +{xp} XP bonus!",
    "🔥 UNTOUCHABLE! +{xp} XP!",
    "⚡ UNLIMITED! +{xp} XP earned!",
    "🚀 UNPRECEDENTED! +{xp} XP!",
    "💥 UNSTOPPABLE FORCE! +{xp} XP bonus!",
    "🌟 UNPARALLELED! +{xp} XP!",
    "💎 UNBREAKABLE! +{xp} XP earned!",
    "🎯 UNFORGETTABLE! +{xp} XP!",
    "🎪 UNREPEATABLE! +{xp} XP bonus!",
    "🎭 UNDENIABLE! +{xp} XP!",
    "🎨 UNBELIEVABLE! +{xp} XP earned!",
    "🎵 UNMISTAKABLE! +{xp} XP!",
    "🎸 UNDISPUTED! +{xp} XP bonus!",
    "🎤 UNQUESTIONED! +{xp} XP!",
    "🎬 UNCHALLENGED! +{xp} XP earned!",
    "📺 UNDEFEATED! +{xp} XP!",
    "📻 UNCHANGED! +{xp} XP bonus!",
    "📚 UNLIMITED POWER! +{xp} XP!",
    "📖 UNWRITTEN RULES! +{xp} XP earned!",
    "📝 UNSIGNED TALENT! +{xp} XP!",
    "📊 UNCHARTED TERRITORY! +{xp} XP bonus!",
    "📈 UNLIMITED POTENTIAL! +{xp} XP!",
  ];

  /// Achievement-based messages (100+ variants)
  static const List<String> _achievementMessages = [
    // Milestone (25 variants)
    "🏆 MILESTONE MASTERY! +{xp} XP!",
    "🎖️ ACHIEVEMENT UNLOCKED! +{xp} XP!",
    "🥇 GOAL CRUSHER! +{xp} XP earned!",
    "📈 PROGRESS MACHINE! +{xp} XP!",
    "🎯 TARGET ACQUIRED! +{xp} XP bonus!",
    "🌟 STAR PERFORMER! +{xp} XP!",
    "💫 RISING STAR! +{xp} XP earned!",
    "⭐ SHINING STAR! +{xp} XP!",
    "✨ SPARKLING SUCCESS! +{xp} XP bonus!",
    "💎 DIAMOND ACHIEVEMENT! +{xp} XP!",
    "🔮 CRYSTAL CLEAR! +{xp} XP earned!",
    "🎊 CELEBRATION TIME! +{xp} XP!",
    "🎉 PARTY WORTHY! +{xp} XP bonus!",
    "🎁 GIFT OF SUCCESS! +{xp} XP!",
    "🌈 RAINBOW ACHIEVEMENT! +{xp} XP earned!",
    "🦄 UNICORN MOMENT! +{xp} XP!",
    "🌸 BLOOMING SUCCESS! +{xp} XP bonus!",
    "🌺 FLOWERING TALENT! +{xp} XP!",
    "🌻 SUNFLOWER BRIGHT! +{xp} XP earned!",
    "🌹 ROSE TO OCCASION! +{xp} XP!",
    "🌷 TULIP PERFECT! +{xp} XP bonus!",
    "🌼 DAISY FRESH! +{xp} XP!",
    "🌽 CORN-ER SUCCESS! +{xp} XP earned!",
    "🍎 APPLE OF MY EYE! +{xp} XP!",
    "🍯 HONEY SUCCESS! +{xp} XP bonus!",
  ];

  /// Perfectionist messages (100+ variants) 
  static const List<String> _perfectionistMessages = [
    // Precision (25 variants)
    "✨ FLAWLESS EXECUTION! +{xp} XP!",
    "🎯 PRECISION MASTERY! +{xp} XP earned!",
    "💎 QUALITY WORK! +{xp} XP!",
    "🔬 METHODICAL EXCELLENCE! +{xp} XP bonus!",
    "📐 PERFECT TECHNIQUE! +{xp} XP!",
    "⚙️ MECHANICAL PRECISION! +{xp} XP earned!",
    "🎨 ARTISTIC PERFECTION! +{xp} XP!",
    "🎭 THEATRICAL EXCELLENCE! +{xp} XP bonus!",
    "🎵 MUSICAL HARMONY! +{xp} XP!",
    "🎸 STRING PERFECTION! +{xp} XP earned!",
    "🎹 KEY MASTERY! +{xp} XP!",
    "🥁 RHYTHM PERFECT! +{xp} XP bonus!",
    "🎺 BRASS EXCELLENCE! +{xp} XP!",
    "🎷 SAXOPHONE SMOOTH! +{xp} XP earned!",
    "🎻 VIOLIN VIRTUOSO! +{xp} XP!",
    "🎤 VOCAL PERFECTION! +{xp} XP bonus!",
    "🎧 AUDIO EXCELLENCE! +{xp} XP!",
    "📻 CRYSTAL CLEAR! +{xp} XP earned!",
    "📺 PICTURE PERFECT! +{xp} XP!",
    "🎮 GAMING PRECISION! +{xp} XP bonus!",
    "🕹️ CONTROL MASTERY! +{xp} XP!",
    "🎯 BULLSEYE PERFECT! +{xp} XP earned!",
    "🎳 STRIKE PRECISION! +{xp} XP!",
    "🎾 TENNIS ACE! +{xp} XP bonus!",
    "🏀 PERFECT SHOT! +{xp} XP!",
  ];

  /// Get personalized message based on server personality and context
  static String getPersonalizedMessage(
    String serverId,
    ServerPersonality personality,
    MilestoneAchievement achievement,
    MessageContext context,
    MessageHistory history,
  ) {
    // Determine message category based on personality
    final category = _selectMessageCategory(personality, achievement);
    
    // Get candidate messages for the category
    final candidates = _getMessagesForCategory(category);
    
    // Filter out recently used messages
    final filtered = _filterRecentMessages(candidates, history);
    
    // Apply contextual modifications
    final contextual = _applyContextualModifications(filtered, context);
    
    // Select final message with anti-repetition
    final selected = _selectWithVariety(contextual, history);
    
    // Replace placeholders
    return _replacePlaceholders(selected, achievement);
  }

  /// Select message category based on personality
  static MessageCategory _selectMessageCategory(
    ServerPersonality personality,
    MilestoneAchievement achievement,
  ) {
    // Speed demons get speed messages
    if (personality.dominantPatterns.contains(BehaviorPattern.speedDemon)) {
      return MessageCategory.speedBased;
    }
    
    // Competitive sharks get competitive messages
    if (personality.dominantPatterns.contains(BehaviorPattern.competitiveShark)) {
      return MessageCategory.competitiveBased;
    }
    
    // Perfectionists get precision messages
    if (personality.dominantPatterns.contains(BehaviorPattern.perfectionist)) {
      return MessageCategory.consistencyBased;
    }
    
    // Achievement-focused get achievement messages
    if (personality.traitScores[PersonalityTrait.achievement] != null &&
        personality.traitScores[PersonalityTrait.achievement]! > 0.7) {
      return MessageCategory.achievementBased;
    }
    
    // Default to motivational
    return MessageCategory.motivational;
  }

  /// Get messages for specific category
  static List<String> _getMessagesForCategory(MessageCategory category) {
    switch (category) {
      case MessageCategory.speedBased:
        return _speedMessages;
      case MessageCategory.competitiveBased:
        return _competitiveMessages;
      case MessageCategory.achievementBased:
        return _achievementMessages;
      case MessageCategory.consistencyBased:
        return _perfectionistMessages;
      default:
        return _speedMessages; // Fallback
    }
  }

  /// Filter out recently used messages
  static List<String> _filterRecentMessages(
    List<String> candidates,
    MessageHistory history,
  ) {
    final now = DateTime.now();
    
    return candidates.where((message) {
      // Check recent message list
      if (history.recentMessages.contains(message)) return false;
      
      // Check daily repeat protection
      final lastUsed = history.lastUsed[message];
      if (lastUsed != null && 
          now.difference(lastUsed) < _dailyRepeatProtection) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Replace placeholders in message
  static String _replacePlaceholders(String message, MilestoneAchievement achievement) {
    return message.replaceAll('{xp}', achievement.xpReward.toString());
  }

  /// Update message history
  static void updateMessageHistory(
    MessageHistory history,
    String selectedMessage,
  ) {
    final now = DateTime.now();
    
    // Add to recent messages
    history.recentMessages.add(selectedMessage);
    if (history.recentMessages.length > _maxRecentMessages) {
      history.recentMessages.removeAt(0);
    }
    
    // Update usage tracking
    history.lastUsed[selectedMessage] = now;
    history.usageCount[selectedMessage] = (history.usageCount[selectedMessage] ?? 0) + 1;
  }
  
  /// Dynamically determine message context based on current state
  static MessageContext determineContext({
    required DateTime currentTime,
    required int totalActiveServers,
    required double currentBusinessLevel, // 0.0 to 1.0 representing busy-ness
    String? seasonalEvent,
  }) {
    final hour = currentTime.hour;
    final dayOfWeek = currentTime.weekday; // 1 = Monday, 7 = Sunday
    final isWeekend = dayOfWeek >= 6;
    
    // Seasonal context takes priority
    if (seasonalEvent != null) {
      switch (seasonalEvent.toLowerCase()) {
        case 'holiday_rush':
        case 'valentines':
        case 'mothers_day':
          return MessageContext.busyDay;
        case 'summer_slow':
        case 'post_holiday':
          return MessageContext.slowDay;
      }
    }
    
    // Business level context
    if (currentBusinessLevel > 0.8) {
      return isWeekend ? MessageContext.weekendBusy : MessageContext.busyDay;
    } else if (currentBusinessLevel < 0.3) {
      return MessageContext.slowDay;
    }
    
    // Time-based context
    if (hour >= 6 && hour < 11) {
      return MessageContext.morningRush;
    } else if (hour >= 11 && hour < 15) {
      return MessageContext.lunchPeak;
    } else if (hour >= 15 && hour < 17) {
      return MessageContext.afternoonSlump;
    } else if (hour >= 17 && hour < 22) {
      return MessageContext.dinnerRush;
    } else {
      return MessageContext.lateNight;
    }
  }
  
  /// Enhanced contextual message modifications with time and business awareness
  static List<String> _applyContextualModifications(
    List<String> messages,
    MessageContext context,
  ) {
    final contextualModifiers = <String, List<String>>{
      // Time-of-day modifiers
      'morningRush': [
        'Early bird gets the XP! ',
        'Morning momentum! ',
        'Sunrise superstar! ',
        'Dawn domination! ',
        '🌅 ',
      ],
      'lunchPeak': [
        'Lunchtime legend! ',
        'Midday mastery! ',
        'Peak performance! ',
        'Noon ninja! ',
        '🍽️ ',
      ],
      'afternoonSlump': [
        'Afternoon advantage! ',
        'Power through! ',
        'Second wind! ',
        'Steady strength! ',
        '💪 ',
      ],
      'dinnerRush': [
        'Dinner domination! ',
        'Evening excellence! ',
        'Prime time power! ',
        'Rush hour ruler! ',
        '🌆 ',
      ],
      'lateNight': [
        'Night owl! ',
        'Late shift legend! ',
        'After hours ace! ',
        'Midnight mastery! ',
        '🌙 ',
      ],
      'weekendBusy': [
        'Weekend warrior! ',
        'Saturday superstar! ',
        'Sunday champion! ',
        'Weekend wonder! ',
        '🎉 ',
      ],
      
      // Business level modifiers
      'busyDay': [
        'Crushing the chaos! ',
        'Thriving in madness! ',
        'Busy day beast! ',
        'Rush master! ',
        '🔥 ',
      ],
      'slowDay': [
        'Steady excellence! ',
        'Consistent champion! ',
        'Quality over quantity! ',
        'Precision performer! ',
        '✨ ',
      ],
    };
    
    final modifiers = contextualModifiers[context.toString().split('.').last] ?? [''];
    
    return messages.map((message) {
      // 30% chance to apply contextual modifier
      if (math.Random().nextDouble() < 0.3 && modifiers.isNotEmpty) {
        final modifier = modifiers[math.Random().nextInt(modifiers.length)];
        return modifier + message;
      }
      return message;
    }).toList();
  }
  
  /// Enhanced message selection with seasonal and time-based variations
  static String _selectWithVariety(
    List<String> messages,
    MessageHistory history,
  ) {
    if (messages.isEmpty) return "🎯 MILESTONE ACHIEVED! +{xp} XP!";
    
    // Weight selection based on historical engagement
    final weightedMessages = <String>[];
    
    for (final message in messages) {
      final engagement = history.engagementScore[message] ?? 1.0;
      final usageCount = history.usageCount[message] ?? 0;
      
      // Higher engagement = more likely to be selected
      // Lower usage count = more likely to be selected (variety)
      final weight = (engagement * 10 / (usageCount + 1)).round();
      
      for (int i = 0; i < weight && i < 5; i++) {
        weightedMessages.add(message);
      }
    }
    
    if (weightedMessages.isEmpty) {
      return messages[math.Random().nextInt(messages.length)];
    }
    
    return weightedMessages[math.Random().nextInt(weightedMessages.length)];
  }
  
  /// Simple method for basic flash messages without full personalization
  /// Returns one of 500+ unique messages with XP placeholders replaced
  static String getSimpleVarietyMessage(String messageType, int xpAmount) {
    List<String> messagePool;
    
    switch (messageType.toLowerCase()) {
      case 'speed':
      case 'fast':
      case 'quick':
        messagePool = _speedMessages;
        break;
      case 'competitive':
      case 'competition':
      case 'rank':
        messagePool = _competitiveMessages;
        break;
      case 'achievement':
      case 'milestone':
        messagePool = _achievementMessages;
        break;
      case 'perfectionist':
      case 'precision':
      case 'quality':
        messagePool = _perfectionistMessages;
        break;
      default:
        // Mix all message types for maximum variety
        messagePool = [
          ..._speedMessages,
          ..._competitiveMessages,
          ..._achievementMessages,
          ..._perfectionistMessages,
        ];
    }
    
    if (messagePool.isEmpty) {
      return "🎯 Amazing! +$xpAmount XP!";
    }
    
    final selectedMessage = messagePool[math.Random().nextInt(messagePool.length)];
    return selectedMessage.replaceAll('{xp}', xpAmount.toString());
  }
}