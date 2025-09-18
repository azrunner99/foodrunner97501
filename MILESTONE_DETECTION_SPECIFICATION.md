# 🎯 MILESTONE DETECTION SERVICE SPECIFICATION

**Purpose**: Detect achievements in real-time and award actual XP bonuses to server profiles  
**File Location**: `lib/services/milestone_detection_service.dart` (TO BE CREATED)

## 📋 SERVICE ARCHITECTURE

### **Core Data Structures**
```dart
enum MilestoneType {
  // Daily Firsts (+25-50 XP)
  firstRunOfShift(25),
  firstPizookieOfDay(35), 
  firstSpeedBurst(30),
  firstTimeTakingLead(50),
  
  // Performance Milestones (+50-100 XP)
  everyFifthRun(50),        // 5, 10, 15, 20, 25...
  everyThirdPizookie(75),   // 3, 6, 9, 12...
  doubleTap(12),            // 2+ items in 10 seconds
  tripleThreat(25),         // 3+ items in 30 seconds
  speedDemon(40),           // 5+ items in 60 seconds
  
  // Competitive Achievements (+100-200 XP)
  takingTheLead(100),
  wideningGap(150),         // 3+ ahead of 2nd place
  comeback(200),            // From 3+ behind to 1st
  perfectShift(300),        // No breaks >2 minutes
  
  // Legendary Moments (+200-500 XP)
  personalRecord(250),      // Beat personal best shift
  teamGoal(400),           // Team hits collective target
  levelBreakthrough(500),   // Level up achievement
  serverOfWeek(1000);       // Top performer recognition
  
  const MilestoneType(this.baseXP);
  final int baseXP;
}

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
}
```

### **Detection Methods**

#### **Daily Achievement Tracking**
```dart
class MilestoneDetectionService {
  static bool isFirstOfDay(String serverId, MilestoneType type, AppState app) {
    final profile = app.profiles[serverId];
    if (profile == null) return true;
    
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final lastAchieved = profile.dailyFirsts[type.name];
    
    if (lastAchieved == null) return true;
    return !lastAchieved.toIso8601String().startsWith(today);
  }
  
  static void markDailyFirst(String serverId, MilestoneType type, AppState app) {
    final profile = app.profiles[serverId];
    if (profile != null) {
      profile.dailyFirsts[type.name] = DateTime.now();
    }
  }
}
```

#### **Performance Milestone Detection**
```dart
static MilestoneAchievement? checkRunMilestone(String serverId, int newRunCount, AppState app) {
  // Every 5th run milestone
  if (newRunCount % 5 == 0 && newRunCount > 0) {
    final multiplier = (newRunCount / 5).floor();
    final bonusXP = MilestoneType.everyFifthRun.baseXP + (multiplier * 10); // Scaling bonus
    
    return MilestoneAchievement(
      type: MilestoneType.everyFifthRun,
      xpReward: bonusXP,
      message: _getRunMilestoneMessage(newRunCount),
      subMessage: '+$bonusXP XP Milestone Bonus!',
      priority: newRunCount >= 20 ? FeedbackPriority.epic : FeedbackPriority.high,
      context: {'runCount': newRunCount, 'multiplier': multiplier},
    );
  }
  return null;
}
```

#### **Speed Detection Integration**
```dart
static MilestoneAchievement? checkSpeedMilestone(String serverId, DateTime tapTime, AppState app) {
  final profile = app.profiles[serverId];
  if (profile == null) return null;
  
  // Track recent taps (last 60 seconds)
  final recentTaps = profile.recentTapTimes
      .where((time) => tapTime.difference(time).inSeconds < 60)
      .toList();
  
  if (recentTaps.length >= 5) {
    // Speed Demon: 5+ taps in 60 seconds
    return MilestoneAchievement(
      type: MilestoneType.speedDemon,
      xpReward: MilestoneType.speedDemon.baseXP,
      message: "⚡ SPEED DEMON!\nLightning fast!",
      subMessage: "+${MilestoneType.speedDemon.baseXP} XP Speed Bonus!",
      priority: FeedbackPriority.high,
    );
  }
  
  if (recentTaps.length >= 3 && tapTime.difference(recentTaps.first).inSeconds <= 30) {
    // Triple Threat: 3+ taps in 30 seconds
    return MilestoneAchievement(
      type: MilestoneType.tripleThreat,
      xpReward: MilestoneType.tripleThreat.baseXP,
      message: "🔥 TRIPLE THREAT!\nUnstoppable!",
      subMessage: "+${MilestoneType.tripleThreat.baseXP} XP Speed Bonus!",
      priority: FeedbackPriority.medium,
    );
  }
  
  return null;
}
```

#### **Competitive Achievement Detection**
```dart
static MilestoneAchievement? checkCompetitiveMilestone(String serverId, AppState app) {
  final currentRank = _getCurrentRank(serverId, app);
  final previousRank = app.profiles[serverId]?.lastKnownRank ?? currentRank;
  
  // Taking the lead
  if (currentRank == 1 && previousRank > 1) {
    return MilestoneAchievement(
      type: MilestoneType.takingTheLead,
      xpReward: MilestoneType.takingTheLead.baseXP,
      message: "👑 TOOK THE LEAD!\nEveryone's chasing you!",
      subMessage: "+${MilestoneType.takingTheLead.baseXP} XP Leadership Bonus!",
      priority: FeedbackPriority.epic,
      context: {'previousRank': previousRank, 'currentRank': currentRank},
    );
  }
  
  // Comeback achievement
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
```

## 🎨 MESSAGE VARIETY ENGINE

### **Dynamic Message Generation**
```dart
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
  };
  
  final categoryMessages = messages[runCount] ?? [
    "🏆 MILESTONE MASTER!\nKeep the streak alive!",
  ];
  
  return categoryMessages[Random().nextInt(categoryMessages.length)];
}
```

## 🔄 INTEGRATION POINTS

### **App State Integration**
```dart
// In lib/app_state.dart increment() method:
final milestone = MilestoneDetectionService.checkForMilestones(id, this);
if (milestone != null) {
  // Award actual XP to profile
  final profile = _profiles[id] ?? ServerProfile();
  profile.points += milestone.xpReward;
  
  // Mark achievement if it's a daily first
  if (milestone.type.name.contains('first')) {
    MilestoneDetectionService.markDailyFirst(id, milestone.type, this);
  }
  
  // Update competitive tracking
  profile.lastKnownRank = _getCurrentRank(id);
  
  // Persist immediately
  _profiles[id] = profile;
  await _persistProfiles();
  
  return milestone; // Return to UI for celebration
}
```

### **UI Integration**
```dart
// In lib/screens/home_screen.dart click handler:
final milestone = await app.increment(id);
if (milestone != null) {
  _showEnhancedFlash(
    milestone.message,
    milestone.priority,
    subText: milestone.subMessage,
  );
  
  // Special effects for epic achievements
  if (milestone.priority == FeedbackPriority.epic) {
    _triggerEpicCelebration(milestone);
  }
}
```

## 🎯 SUCCESS METRICS

### **Immediate Validation**
- [ ] Milestone detection triggers in <10ms
- [ ] XP bonuses actually added to persistent profiles  
- [ ] Daily achievements only trigger once per day
- [ ] Competitive milestones detect rank changes accurately

### **Engagement Impact**
- [ ] Increased average taps per shift (+40% target)
- [ ] Higher retention between shifts (95%+ target)
- [ ] Accelerated level progression (milestone XP impact)
- [ ] Reduced message staleness (variety engine effectiveness)

**IMPLEMENTATION READY**: All specifications complete for milestone detection service creation and integration.