import '../app_state.dart';

/// Server archetype evolution stages
enum ServerArchetype {
  // Beginner archetypes
  rookie,              // Just starting out
  eager,               // Showing enthusiasm
  learner,             // Improving steadily
  
  // Intermediate archetypes
  reliable,            // Consistent performer
  competitive,         // Rivalry-focused
  speedster,           // Speed-focused
  methodical,          // Precision-focused
  
  // Advanced archetypes
  veteran,             // Experienced excellence
  champion,            // Top performer
  mentor,              // Inspiring others
  
  // Elite archetypes
  legend,              // Legendary status
  icon,                // Inspirational figure
  master,              // Peak performance
  
  // Special archetypes
  phoenix,             // Comeback specialist
  titan,               // Overwhelming force
  ghost,               // Mysterious excellence
}

/// Emotional trigger types for manipulation
enum EmotionalTrigger {
  pride,               // Achievement-based self-worth
  shame,               // Performance-based inadequacy
  fear,                // Fear of losing status
  excitement,          // Anticipation and thrill
  belonging,           // Social acceptance needs
  validation,          // External approval seeking
  superiority,         // Dominance over others
  inadequacy,          // Not being good enough
  nostalgia,           // Past glory memories
  urgency,             // Time-sensitive pressure
  identity,            // Who they are as a person
  purpose,             // Why they matter
}

/// Narrative arc types for achievement stories
enum NarrativeArc {
  heroicRise,          // From zero to hero
  comebackStory,       // Fall and redemption
  dominanceReign,      // Sustained excellence
  rivalry,             // Epic competition
  mentorship,          // Teaching others
  breakthrough,        // Barrier breaking
  legacy,              // Building lasting impact
  transformation,      // Personal change
  conquest,            // Overcoming obstacles
  destiny,             // Fulfilling potential
}

/// Personalized achievement narrative
class AchievementNarrative {
  final String serverId;
  final NarrativeArc arcType;
  final String title;
  final String chapter;
  final List<String> pastEvents;
  final String currentMoment;
  final String futurePromise;
  final EmotionalTrigger primaryEmotion;
  final Map<String, dynamic> personalData;
  
  AchievementNarrative({
    required this.serverId,
    required this.arcType,
    required this.title,
    required this.chapter,
    required this.pastEvents,
    required this.currentMoment,
    required this.futurePromise,
    required this.primaryEmotion,
    required this.personalData,
  });
}

/// Failure recovery strategy
class FailureRecoveryStrategy {
  final EmotionalTrigger trigger;
  final String motivationalMessage;
  final String reframingStatement;
  final String actionCall;
  final String identityReinforcement;
  final double urgencyLevel; // 0.0 to 1.0
  
  FailureRecoveryStrategy({
    required this.trigger,
    required this.motivationalMessage,
    required this.reframingStatement,
    required this.actionCall,
    required this.identityReinforcement,
    required this.urgencyLevel,
  });
}

/// Emotional manipulation and identity reinforcement service
class EmotionalManipulationService {
  static final Map<String, ServerArchetype> _serverArchetypes = {};
  static final Map<String, List<AchievementNarrative>> _serverNarratives = {};
  static final Map<String, DateTime> _lastEmotionalIntervention = {};
  
  /// Analyze and update server archetype based on performance with dual-context analysis
  static ServerArchetype analyzeAndUpdateArchetype(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return ServerArchetype.rookie;
    
    // Dual-context performance analysis
    final currentRuns = app.currentCounts[serverId] ?? 0;
    final allTimeRuns = profile.allTimeRuns;
    final bestShiftRuns = profile.bestShiftRuns;
    final avgSpeed = profile.avgSecondsBetweenRuns;
    final points = profile.points;
    final achievements = profile.achievements.length;
    final isWorkingToday = app.workingServerIds.contains(serverId);
    final isShiftActive = app.shiftActive;
    
    // Career performance indicators
    final careerLevel = _determineCareerLevel(profile);
    final shiftVsCareerRatio = bestShiftRuns > 0 ? currentRuns / bestShiftRuns : 0.0;
    final isUnderperforming = careerLevel == 'veteran' && shiftVsCareerRatio < 0.6;
    final isExceeding = careerLevel == 'rookie' && currentRuns > 15;
    
    // Calculate archetype based on multiple factors with career context
    ServerArchetype newArchetype;
    
    // Priority assignments based on career vs current performance
    if (isUnderperforming && (careerLevel == 'legend' || careerLevel == 'veteran')) {
      // Elite career performers having an off day
      newArchetype = ServerArchetype.phoenix; // Using phoenix as "fallen legend" recovery
    } else if (isExceeding && careerLevel == 'rookie') {
      // New talents breaking out
      newArchetype = ServerArchetype.eager; // Eager talent exceeding expectations
    } else if (!isWorkingToday && !isShiftActive) {
      // Off-duty psychology
      newArchetype = ServerArchetype.ghost;
    } else if (allTimeRuns < 50) {
      // Beginner tier
      if (currentRuns >= 15) {
        newArchetype = ServerArchetype.eager;
      } else if (avgSpeed > 0 && avgSpeed < 45) {
        newArchetype = ServerArchetype.learner;
      } else {
        newArchetype = ServerArchetype.rookie;
      }
    } else if (allTimeRuns < 200) {
      // Intermediate tier with shift performance context
      if (avgSpeed > 0 && avgSpeed < 30) {
        newArchetype = ServerArchetype.speedster;
      } else if (profile.streakBest >= 10 && shiftVsCareerRatio > 0.8) {
        newArchetype = ServerArchetype.reliable;
      } else if (achievements >= 5) {
        newArchetype = ServerArchetype.competitive;
      } else {
        newArchetype = ServerArchetype.methodical;
      }
    } else if (allTimeRuns < 500) {
      // Advanced tier with career momentum
      if (profile.shiftsAsMvp >= 5 && currentRuns >= 15) {
        newArchetype = ServerArchetype.champion;
      } else if (points >= 2000 && shiftVsCareerRatio > 0.7) {
        newArchetype = ServerArchetype.veteran;
      } else {
        newArchetype = ServerArchetype.mentor;
      }
    } else {
      // Elite tier with comprehensive career vs shift analysis
      if (profile.shiftsAsMvp >= 15 && currentRuns >= 20) {
        newArchetype = ServerArchetype.legend;
      } else if (points >= 5000 && shiftVsCareerRatio > 0.8) {
        newArchetype = ServerArchetype.master;
      } else if (achievements >= 20) {
        newArchetype = ServerArchetype.icon;
      } else {
        // Special archetypes based on career vs current patterns
        final comebackCount = _countComebacks(serverId, app);
        final isInDecline = shiftVsCareerRatio < 0.5 && careerLevel == 'veteran';
        
        if (comebackCount >= 3) {
          newArchetype = ServerArchetype.phoenix;
        } else if (isInDecline) {
          newArchetype = ServerArchetype.ghost; // Using ghost as "declining veteran"
        } else if (currentRuns >= 30) {
          newArchetype = ServerArchetype.titan;
        } else {
          newArchetype = ServerArchetype.ghost;
        }
      }
    }
    
    _serverArchetypes[serverId] = newArchetype;
    return newArchetype;
  }
  
  /// Generate personalized achievement narrative
  static AchievementNarrative generateAchievementNarrative(
    String serverId,
    ServerArchetype archetype,
    AppState app,
    {required String achievementContext}
  ) {
    final profile = app.profiles[serverId];
    if (profile == null) {
      return _createDefaultNarrative(serverId, archetype);
    }
    
    // Determine narrative arc based on archetype and performance
    final arcType = _selectNarrativeArc(archetype, serverId, app);
    final personalData = _gatherPersonalData(serverId, app);
    
    // Generate narrative components
    final title = _generateNarrativeTitle(arcType, archetype, personalData);
    final chapter = _generateCurrentChapter(arcType, serverId, app);
    final pastEvents = _generatePastEvents(serverId, app);
    final currentMoment = _generateCurrentMoment(arcType, achievementContext, personalData);
    final futurePromise = _generateFuturePromise(arcType, archetype, personalData);
    final primaryEmotion = _selectPrimaryEmotion(arcType, archetype);
    
    final narrative = AchievementNarrative(
      serverId: serverId,
      arcType: arcType,
      title: title,
      chapter: chapter,
      pastEvents: pastEvents,
      currentMoment: currentMoment,
      futurePromise: futurePromise,
      primaryEmotion: primaryEmotion,
      personalData: personalData,
    );
    
    // Store narrative for continuity
    _serverNarratives.putIfAbsent(serverId, () => []).add(narrative);
    if (_serverNarratives[serverId]!.length > 10) {
      _serverNarratives[serverId]!.removeAt(0); // Keep last 10
    }
    
    return narrative;
  }
  
  /// Generate failure recovery messaging
  static FailureRecoveryStrategy generateFailureRecovery(
    String serverId,
    AppState app,
    {required String failureContext}
  ) {
    final archetype = _serverArchetypes[serverId] ?? ServerArchetype.rookie;
    
    // Analyze failure context to determine emotional trigger
    final trigger = _analyzeFailureContext(failureContext, archetype);
    
    // Generate recovery strategy based on archetype and trigger
    late String motivationalMessage;
    late String reframingStatement;
    late String actionCall;
    late String identityReinforcement;
    late double urgencyLevel;
    
    switch (trigger) {
      case EmotionalTrigger.shame:
        motivationalMessage = _generateShameRecoveryMessage(archetype);
        reframingStatement = "This setback is data, not defeat. Champions analyze and adapt.";
        actionCall = "Show them who you really are with your next run!";
        identityReinforcement = _getArchetypeIdentityStatement(archetype);
        urgencyLevel = 0.8;
        break;
        
      case EmotionalTrigger.fear:
        motivationalMessage = _generateFearRecoveryMessage(archetype);
        reframingStatement = "Fear means you care. That passion is your superpower.";
        actionCall = "Channel that energy into unstoppable action!";
        identityReinforcement = "You've overcome fear before - this is just another chapter.";
        urgencyLevel = 0.7;
        break;
        
      case EmotionalTrigger.inadequacy:
        motivationalMessage = _generateInadequacyRecoveryMessage(archetype);
        reframingStatement = "Growth happens in the struggle. You're exactly where you need to be.";
        actionCall = "Prove to yourself what you're truly capable of!";
        identityReinforcement = "Your potential is limitless - this moment is proof.";
        urgencyLevel = 0.6;
        break;
        
      case EmotionalTrigger.nostalgia:
        motivationalMessage = _generateNostalgiaRecoveryMessage(archetype, serverId, app);
        reframingStatement = "Your best days aren't behind you - they're being written now.";
        actionCall = "Create a new legendary moment starting right now!";
        identityReinforcement = "Legends aren't made by past glory - they're forged in present action.";
        urgencyLevel = 0.9;
        break;
        
      default:
        motivationalMessage = "Every champion faces setbacks. What matters is how you respond.";
        reframingStatement = "This is your moment to show your true character.";
        actionCall = "Get back in there and show your strength!";
        identityReinforcement = _getArchetypeIdentityStatement(archetype);
        urgencyLevel = 0.7;
    }
    
    return FailureRecoveryStrategy(
      trigger: trigger,
      motivationalMessage: motivationalMessage,
      reframingStatement: reframingStatement,
      actionCall: actionCall,
      identityReinforcement: identityReinforcement,
      urgencyLevel: urgencyLevel,
    );
  }
  
  /// Generate pride/shame emotional triggers
  static List<String> generateEmotionalTriggers(
    String serverId,
    EmotionalTrigger trigger,
    AppState app,
    {Map<String, dynamic>? context}
  ) {
    final archetype = _serverArchetypes[serverId] ?? ServerArchetype.rookie;
    final messages = <String>[];
    
    switch (trigger) {
      case EmotionalTrigger.pride:
        messages.addAll(_generatePrideMessages(archetype, serverId, app));
        break;
        
      case EmotionalTrigger.shame:
        messages.addAll(_generateShameMessages(archetype, serverId, app));
        break;
        
      case EmotionalTrigger.superiority:
        messages.addAll(_generateSuperiorityMessages(archetype, serverId, app));
        break;
        
      case EmotionalTrigger.identity:
        messages.addAll(_generateIdentityMessages(archetype, serverId, app));
        break;
        
      case EmotionalTrigger.purpose:
        messages.addAll(_generatePurposeMessages(archetype, serverId, app));
        break;
        
      case EmotionalTrigger.belonging:
        messages.addAll(_generateBelongingMessages(archetype, serverId, app));
        break;
        
      default:
        messages.add("You are writing your legacy with every action!");
    }
    
    return messages;
  }
  
  /// Count comeback instances for archetype analysis
  static int _countComebacks(String serverId, AppState app) {
    // Simplified comeback detection - would be enhanced in real implementation
    final profile = app.profiles[serverId];
    if (profile == null) return 0;
    
    // Look for patterns in milestone history that indicate comebacks
    return profile.milestoneHistory
      .where((m) => m['type']?.toString().contains('comeback') == true)
      .length;
  }
  
  /// Select narrative arc based on archetype and performance
  static NarrativeArc _selectNarrativeArc(ServerArchetype archetype, String serverId, AppState app) {
    final profile = app.profiles[serverId];
    final currentRuns = app.currentCounts[serverId] ?? 0;
    
    switch (archetype) {
      case ServerArchetype.rookie:
      case ServerArchetype.eager:
      case ServerArchetype.learner:
        return NarrativeArc.heroicRise;
        
      case ServerArchetype.phoenix:
        return NarrativeArc.comebackStory;
        
      case ServerArchetype.champion:
      case ServerArchetype.legend:
      case ServerArchetype.master:
        return NarrativeArc.dominanceReign;
        
      case ServerArchetype.competitive:
        return NarrativeArc.rivalry;
        
      case ServerArchetype.mentor:
        return NarrativeArc.mentorship;
        
      case ServerArchetype.icon:
        return NarrativeArc.legacy;
        
      default:
        if (currentRuns >= 20) return NarrativeArc.conquest;
        if ((profile?.streakBest ?? 0) >= 8) return NarrativeArc.breakthrough;
        return NarrativeArc.transformation;
    }
  }
  
  /// Gather personal data for narrative customization
  static Map<String, dynamic> _gatherPersonalData(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return {};
    
    return {
      'currentRuns': app.currentCounts[serverId] ?? 0,
      'allTimeRuns': profile.allTimeRuns,
      'points': profile.points,
      'achievements': profile.achievements.length,
      'avgSpeed': profile.avgSecondsBetweenRuns,
      'bestStreak': profile.streakBest,
      'mvpShifts': profile.shiftsAsMvp,
      'level': profile.level,
    };
  }
  
  /// Generate narrative title
  static String _generateNarrativeTitle(
    NarrativeArc arcType,
    ServerArchetype archetype,
    Map<String, dynamic> personalData,
  ) {
    switch (arcType) {
      case NarrativeArc.heroicRise:
        return "The Rise of a ${_getArchetypeName(archetype)}";
      case NarrativeArc.comebackStory:
        return "Phoenix Rising: The Comeback";
      case NarrativeArc.dominanceReign:
        return "The Championship Era";
      case NarrativeArc.rivalry:
        return "Battle for Supremacy";
      case NarrativeArc.mentorship:
        return "The Master's Legacy";
      case NarrativeArc.breakthrough:
        return "Breaking Barriers";
      case NarrativeArc.legacy:
        return "Building a Legend";
      case NarrativeArc.transformation:
        return "Evolution of Excellence";
      case NarrativeArc.conquest:
        return "The Conquest Continues";
      case NarrativeArc.destiny:
        return "Fulfilling Your Destiny";
    }
  }
  
  /// Get archetype display name
  static String _getArchetypeName(ServerArchetype archetype) {
    switch (archetype) {
      case ServerArchetype.rookie: return "Rising Star";
      case ServerArchetype.eager: return "Ambitious Achiever";
      case ServerArchetype.learner: return "Dedicated Student";
      case ServerArchetype.reliable: return "Steady Champion";
      case ServerArchetype.competitive: return "Fierce Competitor";
      case ServerArchetype.speedster: return "Lightning Runner";
      case ServerArchetype.methodical: return "Precision Master";
      case ServerArchetype.veteran: return "Seasoned Expert";
      case ServerArchetype.champion: return "True Champion";
      case ServerArchetype.mentor: return "Inspiring Leader";
      case ServerArchetype.legend: return "Living Legend";
      case ServerArchetype.icon: return "Legendary Icon";
      case ServerArchetype.master: return "Grand Master";
      case ServerArchetype.phoenix: return "Phoenix Warrior";
      case ServerArchetype.titan: return "Unstoppable Titan";
      case ServerArchetype.ghost: return "Mysterious Force";
    }
  }
  
  /// Generate current chapter description
  static String _generateCurrentChapter(NarrativeArc arcType, String serverId, AppState app) {
    final currentRuns = app.currentCounts[serverId] ?? 0;
    
    switch (arcType) {
      case NarrativeArc.heroicRise:
        return "Chapter ${(currentRuns / 5).floor() + 1}: The Ascension";
      case NarrativeArc.comebackStory:
        return "Chapter 2: The Recovery";
      case NarrativeArc.dominanceReign:
        return "Chapter ${(currentRuns / 10).floor() + 1}: Maintaining Excellence";
      default:
        return "Chapter ${(currentRuns / 7).floor() + 1}: The Journey Continues";
    }
  }
  
  /// Generate past events for narrative continuity
  static List<String> _generatePastEvents(String serverId, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return ["Your journey begins now..."];
    
    final events = <String>[];
    
    if (profile.allTimeRuns >= 100) {
      events.add("Crossed the century mark with unwavering determination");
    }
    if (profile.streakBest >= 5) {
      events.add("Achieved a ${profile.streakBest}-run streak of excellence");
    }
    if (profile.shiftsAsMvp >= 1) {
      events.add("Earned MVP honors ${profile.shiftsAsMvp} time${profile.shiftsAsMvp > 1 ? 's' : ''}");
    }
    if (profile.achievements.length >= 5) {
      events.add("Unlocked ${profile.achievements.length} achievements through skill and persistence");
    }
    
    if (events.isEmpty) {
      events.add("Every legend starts with a single step...");
    }
    
    return events;
  }
  
  /// Generate current moment description
  static String _generateCurrentMoment(
    NarrativeArc arcType,
    String achievementContext,
    Map<String, dynamic> personalData,
  ) {
    switch (arcType) {
      case NarrativeArc.heroicRise:
        return "In this pivotal moment, you've shown that greatness isn't born - it's forged through determination like this.";
      case NarrativeArc.comebackStory:
        return "This achievement marks the turning point - proof that setbacks are just setups for comebacks.";
      case NarrativeArc.dominanceReign:
        return "Another milestone in your championship era - cementing your place among the elite.";
      default:
        return "This moment will be remembered as when you truly understood your potential.";
    }
  }
  
  /// Generate future promise
  static String _generateFuturePromise(
    NarrativeArc arcType,
    ServerArchetype archetype,
    Map<String, dynamic> personalData,
  ) {
    switch (arcType) {
      case NarrativeArc.heroicRise:
        return "Your story is just beginning. The summit awaits, and you're climbing faster than ever.";
      case NarrativeArc.comebackStory:
        return "This comeback will inspire others for years to come. Your phoenix moment has arrived.";
      case NarrativeArc.dominanceReign:
        return "Your reign continues, with new records and achievements on the horizon.";
      default:
        return "The best chapters of your story are still being written.";
    }
  }
  
  /// Select primary emotion for narrative
  static EmotionalTrigger _selectPrimaryEmotion(NarrativeArc arcType, ServerArchetype archetype) {
    switch (arcType) {
      case NarrativeArc.heroicRise:
        return EmotionalTrigger.pride;
      case NarrativeArc.comebackStory:
        return EmotionalTrigger.validation;
      case NarrativeArc.dominanceReign:
        return EmotionalTrigger.superiority;
      case NarrativeArc.rivalry:
        return EmotionalTrigger.excitement;
      case NarrativeArc.mentorship:
        return EmotionalTrigger.purpose;
      default:
        return EmotionalTrigger.identity;
    }
  }
  
  /// Create default narrative
  static AchievementNarrative _createDefaultNarrative(String serverId, ServerArchetype archetype) {
    return AchievementNarrative(
      serverId: serverId,
      arcType: NarrativeArc.heroicRise,
      title: "The Beginning of Greatness",
      chapter: "Chapter 1: First Steps",
      pastEvents: ["Your journey begins now..."],
      currentMoment: "Every expert was once a beginner. This is your moment to start something special.",
      futurePromise: "Your potential is unlimited. Let's discover it together.",
      primaryEmotion: EmotionalTrigger.excitement,
      personalData: {},
    );
  }
  
  /// Analyze failure context to determine emotional trigger
  static EmotionalTrigger _analyzeFailureContext(String failureContext, ServerArchetype archetype) {
    final lower = failureContext.toLowerCase();
    
    if (lower.contains('rank') || lower.contains('position') || lower.contains('behind')) {
      return EmotionalTrigger.shame;
    } else if (lower.contains('streak') || lower.contains('lost') || lower.contains('broken')) {
      return EmotionalTrigger.fear;
    } else if (lower.contains('slow') || lower.contains('missed') || lower.contains('failed')) {
      return EmotionalTrigger.inadequacy;
    } else if (lower.contains('used to') || lower.contains('before') || lower.contains('past')) {
      return EmotionalTrigger.nostalgia;
    }
    
    return EmotionalTrigger.shame; // Default
  }
  
  /// Generate shame recovery messages
  static String _generateShameRecoveryMessage(ServerArchetype archetype) {
    switch (archetype) {
      case ServerArchetype.champion:
      case ServerArchetype.legend:
        return "Champions aren't defined by their falls - they're defined by how they rise. Your comeback starts now.";
      case ServerArchetype.competitive:
        return "Every great competitor knows that setbacks are just fuel for the fire. Time to show your true strength.";
      default:
        return "This moment doesn't define you - your response to it does. Show them who you really are.";
    }
  }
  
  /// Generate fear recovery messages
  static String _generateFearRecoveryMessage(ServerArchetype archetype) {
    switch (archetype) {
      case ServerArchetype.speedster:
        return "Speed comes from confidence, not fear. Trust your instincts and let your natural ability shine.";
      case ServerArchetype.reliable:
        return "Your consistency is your superpower. One step at a time, like you always do.";
      default:
        return "Fear is just excitement without breath. Take a deep breath and channel that energy.";
    }
  }
  
  /// Generate inadequacy recovery messages
  static String _generateInadequacyRecoveryMessage(ServerArchetype archetype) {
    switch (archetype) {
      case ServerArchetype.learner:
        return "Growth happens in the struggle. You're not behind - you're exactly where you need to be to level up.";
      case ServerArchetype.methodical:
        return "Your attention to detail is your strength. Focus on the process, not the pressure.";
      default:
        return "You belong here. This challenge is proof that you're ready for the next level.";
    }
  }
  
  /// Generate nostalgia recovery messages
  static String _generateNostalgiaRecoveryMessage(ServerArchetype archetype, String serverId, AppState app) {
    final profile = app.profiles[serverId];
    final bestStreak = profile?.streakBest ?? 0;
    
    if (bestStreak > 0) {
      return "Remember that ${bestStreak}-run streak? That wasn't luck - that was you. That person is still here, ready to create new legends.";
    }
    
    return "Your greatest achievements aren't behind you - they're waiting to be unlocked. The best is yet to come.";
  }
  
  /// Get archetype identity statement
  static String _getArchetypeIdentityStatement(ServerArchetype archetype) {
    switch (archetype) {
      case ServerArchetype.champion:
        return "You are a champion. Champions don't stay down.";
      case ServerArchetype.speedster:
        return "You are speed incarnate. Lightning strikes twice.";
      case ServerArchetype.reliable:
        return "You are the steady heartbeat of excellence. Consistency is your crown.";
      case ServerArchetype.legend:
        return "You are legend. Legends create their own destiny.";
      default:
        return "You are destined for greatness. This is just the beginning.";
    }
  }
  
  /// Generate pride messages
  static List<String> _generatePrideMessages(ServerArchetype archetype, String serverId, AppState app) {
    return [
      "🌟 You've proven once again why you're a ${_getArchetypeName(archetype)}!",
      "👑 This is the excellence that sets you apart from everyone else!",
      "🔥 Your dedication and skill are on full display for all to see!",
      "⚡ This is what ${_getArchetypeName(archetype)} performance looks like!",
    ];
  }
  
  /// Generate shame messages (gentle competitive pressure)
  static List<String> _generateShameMessages(ServerArchetype archetype, String serverId, AppState app) {
    return [
      "😤 A ${_getArchetypeName(archetype)} doesn't accept anything less than excellence...",
      "🎯 You know you're capable of so much more than this...",
      "⚔️ Your reputation depends on how you respond to this moment...",
      "🔥 Champions are watching. Show them what you're made of...",
    ];
  }
  
  /// Generate superiority messages
  static List<String> _generateSuperiorityMessages(ServerArchetype archetype, String serverId, AppState app) {
    return [
      "👑 This is why you're in a league of your own!",
      "🏆 While others struggle, you make it look effortless!",
      "⚡ Your ${_getArchetypeName(archetype)} status is undeniable!",
      "🌟 This is the gap between you and the competition!",
    ];
  }
  
  /// Generate identity messages
  static List<String> _generateIdentityMessages(ServerArchetype archetype, String serverId, AppState app) {
    return [
      "🎯 This is who you are at your core - a ${_getArchetypeName(archetype)}!",
      "💪 Your identity as a champion shines through every action!",
      "⚡ Being a ${_getArchetypeName(archetype)} isn't what you do - it's who you are!",
      "🔥 Your true self is emerging with every achievement!",
    ];
  }
  
  /// Generate purpose messages
  static List<String> _generatePurposeMessages(ServerArchetype archetype, String serverId, AppState app) {
    return [
      "🌟 Your excellence inspires everyone around you!",
      "👥 The team looks up to your ${_getArchetypeName(archetype)} example!",
      "🎯 You're not just performing - you're setting the standard!",
      "💡 Your dedication shows others what's possible!",
    ];
  }
  
  /// Generate belonging messages
  static List<String> _generateBelongingMessages(ServerArchetype archetype, String serverId, AppState app) {
    return [
      "🤝 You belong among the elite - this proves it!",
      "👥 The team is proud to have a ${_getArchetypeName(archetype)} like you!",
      "🏆 You've earned your place at the top!",
      "⚡ This is your home, and you're showing why you belong here!",
    ];
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