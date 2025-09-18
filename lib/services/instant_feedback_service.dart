import 'dart:math';
import 'package:flutter/material.dart';
import 'message_variety_engine.dart';

enum FeedbackType {
  basic,        // Regular run
  speed,        // Quick successive runs  
  milestone,    // 5, 10, 15, 20+ runs
  competitive,  // Rank changes
  pizookie,     // Special pizookie runs
  team,         // Team achievements
  achievement,  // Special unlocks
}

enum FeedbackPriority {
  low,      // Basic encouragement
  medium,   // Milestones, competition
  high,     // Achievements, special moments
  epic,     // Major accomplishments
}

class InstantFeedbackService {
  static final Random _random = Random();
  
  // Enhanced prompt collections
  static const basicRunPrompts = [
    "🔥 On fire!", "💪 Power move!", "⚡ Lightning fast!", "🏃‍♂️ Speed demon!",
    "⭐ Superstar!", "🎯 Nailed it!", "💥 BAM!", "🚀 Rocket fuel!",
    "👑 Royalty!", "🏆 Champion move!", "✨ Magic!", "🎊 Crushing it!"
  ];
  
  static const speedPrompts = [
    "🔥 UNSTOPPABLE!", "⚡ SPEED OF LIGHT!", "🏃‍♂️ USAIN BOLT MODE!",
    "🚀 WARP SPEED!", "💨 GONE IN 60 SECONDS!", "⚡ FLASH ACTIVATED!",
    "🏎️ FORMULA 1 PACE!", "🌪️ TORNADO ENERGY!", "⚡ LIGHTNING BOLT!",
    "🚄 BULLET TRAIN!", "🔥 BURNING RUBBER!", "💨 SPEED DEMON!",
    "🏁 RACE MODE ON!", "⚡ ELECTRIC ENERGY!", "🚀 HYPERDRIVE!"
  ];
  
  static const milestonePrompts = [
    "🎉 MILESTONE!\nYou're in the zone!",
    "🏆 DOUBLE DIGITS!\nCrushing it!",
    "👑 FIFTEEN!\nYou're royalty tonight!",
    "🔥 TWENTY!\nAbsolutely on fire!",
    "⭐ LEGEND STATUS!\nHall of fame!"
  ];
  
  static const competitivePrompts = [
    "📈 MOVING UP!\nYou jumped to #2!",
    "🎯 GAINING GROUND!\nOnly 2 behind!",
    "⚡ TOOK THE LEAD!\nEveryone's chasing you!",
    "👑 WIDENING THE GAP!\nDominant!",
    "🎯 LOCKED IN!\nLaser focus!"
  ];
  
  static const pizookiePrompts = [
    "🍪 PIZOOKIE POWER!\n+35 XP! Worth the effort!",
    "🔥 SWEET VICTORY!\nDessert mastery!",
    "🌟 PIZOOKIE PERFECTION!\nExtra work, extra reward!",
    "👑 DESSERT ROYALTY!\nBuilding pays off!",
    "🍦 ICE CREAM CHAMPION!\nScooping success!",
    "🏆 PIZOOKIE MASTER!\nExtra effort rewarded!",
    "💎 SWEET PREMIUM!\n3.5x regular points!",
    "🎯 DESSERT HERO!\nGoing above and beyond!"
  ];
  
  static const teamPrompts = [
    "🤝 TEAM PLAYER!\nLifting everyone up!",
    "🔥 TEAM ON FIRE!\nCollective excellence!",
    "🎯 TEAM GOAL!\nEveryone contributed!",
    "👑 SQUAD GOALS!\nPerfect teamwork!"
  ];

  /// Get contextual instant feedback message with XP amount
  static String getInstantMessage(FeedbackType type, {
    int? runCount,
    int? rank,
    String? context,
    int? xpAmount,
  }) {
    // Use the MessageVarietyEngine for massive variety (500+ unique messages)
    final xp = xpAmount ?? 10; // Default XP if not provided
    
    switch (type) {
      case FeedbackType.basic:
        // Mix of all message types for maximum variety in basic runs
        return MessageVarietyEngine.getSimpleVarietyMessage('mixed', xp);
      case FeedbackType.speed:
        return MessageVarietyEngine.getSimpleVarietyMessage('speed', xp);
      case FeedbackType.milestone:
        if (runCount != null) {
          // Special milestone messages with XP
          if (runCount == 5) return "🎉 FIRST MILESTONE!\nYou're in the zone! +$xp XP!";
          if (runCount == 10) return "🏆 DOUBLE DIGITS!\nYou're crushing it! +$xp XP!";
          if (runCount == 15) return "👑 FIFTEEN!\nYou're royalty tonight! +$xp XP!";
          if (runCount == 20) return "🔥 TWENTY!\nAbsolutely on fire! +$xp XP!";
          if (runCount >= 25) return "⭐ LEGEND STATUS!\nHall of fame night! +$xp XP!";
        }
        return MessageVarietyEngine.getSimpleVarietyMessage('achievement', xp);
      case FeedbackType.competitive:
        return MessageVarietyEngine.getSimpleVarietyMessage('competitive', xp);
      case FeedbackType.pizookie:
        // Use specific pizookie prompts with XP amount
        final prompt = pizookiePrompts[_random.nextInt(pizookiePrompts.length)];
        // Replace the XP amount in the message with actual amount
        return prompt.replaceAll('+35 XP', '+$xp XP').replaceAll('3.5x', '${(xp/10).toStringAsFixed(1)}x');
      case FeedbackType.team:
        return MessageVarietyEngine.getSimpleVarietyMessage('achievement', xp);
      case FeedbackType.achievement:
        return MessageVarietyEngine.getSimpleVarietyMessage('achievement', xp);
    }
  }
  
  /// Get feedback priority for UI styling
  static FeedbackPriority getPriority(FeedbackType type, {int? runCount}) {
    switch (type) {
      case FeedbackType.basic:
        return FeedbackPriority.low;
      case FeedbackType.speed:
        return FeedbackPriority.medium;
      case FeedbackType.milestone:
        if (runCount != null && runCount >= 20) return FeedbackPriority.epic;
        return FeedbackPriority.medium;
      case FeedbackType.competitive:
        return FeedbackPriority.medium;
      case FeedbackType.pizookie:
        return FeedbackPriority.medium;
      case FeedbackType.team:
        return FeedbackPriority.high;
      case FeedbackType.achievement:
        return FeedbackPriority.epic;
    }
  }
  
  /// Enhanced feedback styling based on priority
  static TextStyle getTextStyle(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
          shadows: [
            Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2)),
          ],
        );
      case FeedbackPriority.medium:
        return const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: Colors.orange,
          shadows: [
            Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 0)),
            Shadow(blurRadius: 16, color: Colors.black87, offset: Offset(2, 2)),
          ],
        );
      case FeedbackPriority.high:
        return const TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w900,
          color: Colors.red,
          letterSpacing: 1.2,
          shadows: [
            Shadow(blurRadius: 12, color: Colors.black, offset: Offset(0, 0)),
            Shadow(blurRadius: 20, color: Colors.black87, offset: Offset(3, 3)),
          ],
        );
      case FeedbackPriority.epic:
        return const TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.w900,
          color: Colors.purple,
          letterSpacing: 1.5,
          shadows: [
            Shadow(blurRadius: 15, color: Colors.black, offset: Offset(0, 0)),
            Shadow(blurRadius: 25, color: Colors.purpleAccent, offset: Offset(0, 0)),
            Shadow(blurRadius: 35, color: Colors.black54, offset: Offset(-2, -2)),
          ],
        );
    }
  }
  
  /// Get animation duration based on priority
  static Duration getAnimationDuration(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return const Duration(milliseconds: 1000);
      case FeedbackPriority.medium:
        return const Duration(milliseconds: 1300);
      case FeedbackPriority.high:
        return const Duration(milliseconds: 1600);
      case FeedbackPriority.epic:
        return const Duration(milliseconds: 2000);
    }
  }
}