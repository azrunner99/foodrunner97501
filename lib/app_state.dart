/// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'utils/log.dart';
import 'package:collection/collection.dart';
import 'package:clock/clock.dart';
import 'models.dart';
import 'storage.dart';
import 'gamification.dart';
import 'services/milestone_detection_service.dart';
import 'services/stations_repository.dart';

String _randId() {
  final r = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
}

/// Rounds XP to "nice" round numbers that end in 0, 1, or 5
/// Examples: 12 -> 10, 16 -> 15, 23 -> 25, 47 -> 50
int _roundXP(int xp) {
  if (xp <= 1) return xp; // Keep small values as-is

  final lastDigit = xp % 10;

  // If already ends in 0, 1, or 5, keep it
  if (lastDigit == 0 || lastDigit == 1 || lastDigit == 5) {
    return xp;
  }

  // Round to nearest "nice" number
  if (lastDigit <= 3) {
    return xp - lastDigit + 1; // Round down to X1
  } else if (lastDigit <= 7) {
    return xp - lastDigit + 5; // Round to X5
  } else {
    return xp - lastDigit + 10; // Round up to (X+1)0
  }
}

class ServerProfile {
  double get avgSecondsBetweenRuns => tapIntervalsCount == 0
      ? 0
      : tapIntervalsMsSum / tapIntervalsCount / 1000.0;
  int get level => levelForPoints(points);
  int get nextLevelAt => nextLevelTarget(points);
  int allTimeRuns;
  int pizookieRuns;
  int bestShiftRuns;
  int streakBest;
  int shiftsAsMvp;
  List<String> achievements;
  List<String> repeatEarnedDates;
  int points;
  int tapIntervalsMsSum;
  int tapIntervalsCount;
  String? lastTapIso;
  String? avatarPath;
  String? bannerPath;
  List<Map<String, dynamic>> avatarHistory;
  String hireDate;
  String birthday;
  bool isArchived;
  String archiveNotes;

  // Milestone tracking fields
  Map<String, DateTime> dailyFirsts; // Track daily achievement firsts
  List<DateTime> recentTapTimes; // Track recent taps for speed detection
  int? lastKnownRank; // Track rank changes for competitive milestones
  List<Map<String, dynamic>> milestoneHistory; // Track earned milestones

  // Personality tracking fields
  Map<String, double>
      behaviorPatterns; // Pattern name -> confidence score (0.0-1.0)
  Map<String, double>
      personalityTraits; // Trait name -> intensity score (0.0-1.0)
  List<Map<String, dynamic>> performanceHistory; // Historical performance data
  List<String> preferredShifts; // ['lunch', 'dinner', 'late']
  double competitiveLevel; // 0.0-1.0 competitive intensity
  double socialLevel; // 0.0-1.0 social engagement
  double achievementDrive; // 0.0-1.0 achievement motivation
  DateTime? lastPersonalityAnalysis; // Last analysis timestamp
  int personalityAnalysisVersion; // Analysis version for migrations

  // Message variety tracking fields
  List<String> recentMessages; // Last 50 messages shown (anti-repetition)
  Map<String, DateTime> messageLastUsed; // Message -> last used timestamp
  Map<String, int> messageUsageCount; // Message -> total usage count
  Map<String, double>
      messageEngagement; // Message -> engagement score (0.0-1.0)

  ServerProfile({
    this.allTimeRuns = 0,
    this.pizookieRuns = 0,
    this.bestShiftRuns = 0,
    this.streakBest = 0,
    this.shiftsAsMvp = 0,
    List<String>? achievements,
    List<String>? repeatEarnedDates,
    this.points = 0,
    this.tapIntervalsMsSum = 0,
    this.tapIntervalsCount = 0,
    this.lastTapIso,
    this.avatarPath,
    this.bannerPath,
    this.avatarHistory = const [],
    this.hireDate = '',
    this.birthday = '',
    this.isArchived = false,
    this.archiveNotes = '',
    Map<String, DateTime>? dailyFirsts,
    List<DateTime>? recentTapTimes,
    this.lastKnownRank,
    List<Map<String, dynamic>>? milestoneHistory,
    Map<String, double>? behaviorPatterns,
    Map<String, double>? personalityTraits,
    List<Map<String, dynamic>>? performanceHistory,
    List<String>? preferredShifts,
    this.competitiveLevel = 0.5,
    this.socialLevel = 0.5,
    this.achievementDrive = 0.5,
    this.lastPersonalityAnalysis,
    this.personalityAnalysisVersion = 1,
    List<String>? recentMessages,
    Map<String, DateTime>? messageLastUsed,
    Map<String, int>? messageUsageCount,
    Map<String, double>? messageEngagement,
  })  : achievements = achievements ?? [],
        repeatEarnedDates = repeatEarnedDates ?? [],
        dailyFirsts = dailyFirsts ?? {},
        recentTapTimes = recentTapTimes ?? [],
        milestoneHistory = milestoneHistory ?? [],
        behaviorPatterns = behaviorPatterns ?? {},
        personalityTraits = personalityTraits ?? {},
        performanceHistory = performanceHistory ?? [],
        preferredShifts = preferredShifts ?? ['lunch', 'dinner'],
        recentMessages = recentMessages ?? [],
        messageLastUsed = messageLastUsed ?? {},
        messageUsageCount = messageUsageCount ?? {},
        messageEngagement = messageEngagement ?? {};

  ServerProfile copyWith({
    int? allTimeRuns,
    int? pizookieRuns,
    int? bestShiftRuns,
    int? streakBest,
    int? shiftsAsMvp,
    List<String>? achievements,
    List<String>? repeatEarnedDates,
    int? points,
    int? tapIntervalsMsSum,
    int? tapIntervalsCount,
    String? lastTapIso,
    String? avatarPath,
    String? bannerPath,
    List<Map<String, dynamic>>? avatarHistory,
    String? hireDate,
    String? birthday,
    bool? isArchived,
    String? archiveNotes,
    Map<String, DateTime>? dailyFirsts,
    List<DateTime>? recentTapTimes,
    int? lastKnownRank,
    List<Map<String, dynamic>>? milestoneHistory,
    Map<String, double>? behaviorPatterns,
    Map<String, double>? personalityTraits,
    List<Map<String, dynamic>>? performanceHistory,
    List<String>? preferredShifts,
    double? competitiveLevel,
    double? socialLevel,
    double? achievementDrive,
    DateTime? lastPersonalityAnalysis,
    int? personalityAnalysisVersion,
    List<String>? recentMessages,
    Map<String, DateTime>? messageLastUsed,
    Map<String, int>? messageUsageCount,
    Map<String, double>? messageEngagement,
  }) {
    return ServerProfile(
      allTimeRuns: allTimeRuns ?? this.allTimeRuns,
      pizookieRuns: pizookieRuns ?? this.pizookieRuns,
      bestShiftRuns: bestShiftRuns ?? this.bestShiftRuns,
      streakBest: streakBest ?? this.streakBest,
      shiftsAsMvp: shiftsAsMvp ?? this.shiftsAsMvp,
      achievements: achievements ?? this.achievements,
      repeatEarnedDates: repeatEarnedDates ?? this.repeatEarnedDates,
      points: points ?? this.points,
      tapIntervalsMsSum: tapIntervalsMsSum ?? this.tapIntervalsMsSum,
      tapIntervalsCount: tapIntervalsCount ?? this.tapIntervalsCount,
      lastTapIso: lastTapIso ?? this.lastTapIso,
      avatarPath: avatarPath ?? this.avatarPath,
      bannerPath: bannerPath ?? this.bannerPath,
      avatarHistory: avatarHistory ?? this.avatarHistory,
      hireDate: hireDate ?? this.hireDate,
      birthday: birthday ?? this.birthday,
      isArchived: isArchived ?? this.isArchived,
      archiveNotes: archiveNotes ?? this.archiveNotes,
      dailyFirsts: dailyFirsts ?? this.dailyFirsts,
      recentTapTimes: recentTapTimes ?? this.recentTapTimes,
      lastKnownRank: lastKnownRank ?? this.lastKnownRank,
      milestoneHistory: milestoneHistory ?? this.milestoneHistory,
      behaviorPatterns: behaviorPatterns ?? this.behaviorPatterns,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      performanceHistory: performanceHistory ?? this.performanceHistory,
      preferredShifts: preferredShifts ?? this.preferredShifts,
      competitiveLevel: competitiveLevel ?? this.competitiveLevel,
      socialLevel: socialLevel ?? this.socialLevel,
      achievementDrive: achievementDrive ?? this.achievementDrive,
      lastPersonalityAnalysis:
          lastPersonalityAnalysis ?? this.lastPersonalityAnalysis,
      personalityAnalysisVersion:
          personalityAnalysisVersion ?? this.personalityAnalysisVersion,
      recentMessages: recentMessages ?? this.recentMessages,
      messageLastUsed: messageLastUsed ?? this.messageLastUsed,
      messageUsageCount: messageUsageCount ?? this.messageUsageCount,
      messageEngagement: messageEngagement ?? this.messageEngagement,
    );
  }

  static ServerProfile fromMap(Map m) => ServerProfile(
        allTimeRuns: (m['allTimeRuns'] ?? 0) as int,
        pizookieRuns: (m['pizookieRuns'] ?? 0) as int,
        bestShiftRuns: (m['bestShiftRuns'] ?? 0) as int,
        streakBest: (m['streakBest'] ?? 0) as int,
        shiftsAsMvp: (m['shiftsAsMvp'] ?? 0) as int,
        achievements:
            (m['achievements'] as List?)?.cast<String>() ?? <String>[],
        repeatEarnedDates:
            (m['repeatEarnedDates'] as List?)?.cast<String>() ?? <String>[],
        points: (m['points'] ?? 0) as int,
        tapIntervalsMsSum: (m['tapIntervalsMsSum'] ?? 0) as int,
        tapIntervalsCount: (m['tapIntervalsCount'] ?? 0) as int,
        lastTapIso: m['lastTapIso'] as String?,
        avatarPath: m['avatarPath'] as String?,
        bannerPath: m['bannerPath'] as String?,
        avatarHistory: (m['avatarHistory'] as List?)?.map((e) {
              if (e is String) {
                return {'path': e, 'timestamp': null};
              } else if (e is Map) {
                return Map<String, dynamic>.from(
                    e.map((key, value) => MapEntry(key.toString(), value)));
              } else {
                return <String, dynamic>{};
              }
            }).toList() ??
            <Map<String, dynamic>>[],
        hireDate: (m['hireDate'] ?? '') as String,
        birthday: (m['birthday'] ?? '') as String,
        isArchived: (m['isArchived'] ?? false) as bool,
        archiveNotes: (m['archiveNotes'] ?? '') as String,
        dailyFirsts: (m['dailyFirsts'] as Map?)?.map((key, value) =>
                MapEntry(key.toString(), DateTime.parse(value.toString()))) ??
            <String, DateTime>{},
        recentTapTimes: (m['recentTapTimes'] as List?)
                ?.map((e) => DateTime.parse(e.toString()))
                .toList() ??
            <DateTime>[],
        lastKnownRank: m['lastKnownRank'] as int?,
        milestoneHistory: (m['milestoneHistory'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            <Map<String, dynamic>>[],
        behaviorPatterns: (m['behaviorPatterns'] as Map?)?.map((key, value) =>
                MapEntry(key.toString(), (value as num).toDouble())) ??
            <String, double>{},
        personalityTraits: (m['personalityTraits'] as Map?)?.map((key, value) =>
                MapEntry(key.toString(), (value as num).toDouble())) ??
            <String, double>{},
        performanceHistory: (m['performanceHistory'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            <Map<String, dynamic>>[],
        preferredShifts: (m['preferredShifts'] as List?)?.cast<String>() ??
            ['lunch', 'dinner'],
        competitiveLevel: (m['competitiveLevel'] as num?)?.toDouble() ?? 0.5,
        socialLevel: (m['socialLevel'] as num?)?.toDouble() ?? 0.5,
        achievementDrive: (m['achievementDrive'] as num?)?.toDouble() ?? 0.5,
        lastPersonalityAnalysis: m['lastPersonalityAnalysis'] != null
            ? DateTime.parse(m['lastPersonalityAnalysis'].toString())
            : null,
        personalityAnalysisVersion:
            (m['personalityAnalysisVersion'] ?? 1) as int,
        recentMessages:
            (m['recentMessages'] as List?)?.cast<String>() ?? <String>[],
        messageLastUsed: (m['messageLastUsed'] as Map?)?.map((key, value) =>
                MapEntry(key.toString(), DateTime.parse(value.toString()))) ??
            <String, DateTime>{},
        messageUsageCount: (m['messageUsageCount'] as Map?)?.map((key, value) =>
                MapEntry(key.toString(), (value as num).toInt())) ??
            <String, int>{},
        messageEngagement: (m['messageEngagement'] as Map?)?.map((key, value) =>
                MapEntry(key.toString(), (value as num).toDouble())) ??
            <String, double>{},
      );

  Map<String, dynamic> toMap() => {
        'allTimeRuns': allTimeRuns,
        'pizookieRuns': pizookieRuns,
        'bestShiftRuns': bestShiftRuns,
        'streakBest': streakBest,
        'shiftsAsMvp': shiftsAsMvp,
        'achievements': achievements,
        'repeatEarnedDates': repeatEarnedDates,
        'points': points,
        'tapIntervalsMsSum': tapIntervalsMsSum,
        'tapIntervalsCount': tapIntervalsCount,
        'lastTapIso': lastTapIso,
        'avatarPath': avatarPath,
        'bannerPath': bannerPath,
        'avatarHistory': avatarHistory,
        'hireDate': hireDate,
        'birthday': birthday,
        'isArchived': isArchived,
        'archiveNotes': archiveNotes,
        'dailyFirsts': dailyFirsts
            .map((key, value) => MapEntry(key, value.toIso8601String())),
        'recentTapTimes':
            recentTapTimes.map((time) => time.toIso8601String()).toList(),
        'lastKnownRank': lastKnownRank,
        'milestoneHistory': milestoneHistory,
        'behaviorPatterns': behaviorPatterns,
        'personalityTraits': personalityTraits,
        'performanceHistory': performanceHistory,
        'preferredShifts': preferredShifts,
        'competitiveLevel': competitiveLevel,
        'socialLevel': socialLevel,
        'achievementDrive': achievementDrive,
        'lastPersonalityAnalysis': lastPersonalityAnalysis?.toIso8601String(),
        'personalityAnalysisVersion': personalityAnalysisVersion,
        'recentMessages': recentMessages,
        'messageLastUsed': messageLastUsed
            .map((key, value) => MapEntry(key, value.toIso8601String())),
        'messageUsageCount': messageUsageCount,
        'messageEngagement': messageEngagement,
      };
}

class AppState extends ChangeNotifier {
  final Clock _clock;

  final Future<String?> Function(List<String>) _exportBoxes;

  AppState(
      {Clock? clock, Future<String?> Function(List<String>)? exportBoxesFn})
      : _clock = clock ?? const Clock(),
        _exportBoxes = exportBoxesFn ?? Storage.exportBoxes;

  DateTime get _now => _clock.now();

  // When true, a manually-started shift should not be auto-switched by clock logic
  bool _manualShiftOverride = false;

  // Debug logging now handled by utils/log.dart:d()

  String? _lastRunServerId;
  String? get lastRunServerId => _lastRunServerId;
  set lastRunServerId(String? id) {
    _lastRunServerId = id;
    notifyListeners();
  }

  Map<String, int> get currentPizookieCounts =>
      Map.unmodifiable(Map<String, int>.from(_currentPizookieCounts));

  /// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
  /// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
  // Tracks per-shift pizookie runs for each server
  final Map<String, int> _currentPizookieCounts = {};
  MilestoneAchievement? incrementPizookie(String id) {
    d('[DEBUG] incrementPizookie called for server $id');
    d('[DEBUG] _shiftActive=$_shiftActive');
    d('[DEBUG] _workingServerIds=$_workingServerIds');
    d('[DEBUG] _workingServerIds.contains($id)=${_workingServerIds.contains(id)}');
    d('[DEBUG] _todayPlan?.lunchRoster=${_todayPlan?.lunchRoster}');
    d('[DEBUG] _todayPlan?.dinnerRoster=${_todayPlan?.dinnerRoster}');

    // Defensive gating: must be open, shift active, and server working
    if (!isOpenNow || !_shiftActive || !_workingServerIds.contains(id)) {
      d('[DEBUG] incrementPizookie blocked for $id: isOpenNow=$isOpenNow, _shiftActive=$_shiftActive, contains=${_workingServerIds.contains(id)}');
      return null;
    }

    final now = _now;
    const delta = 1;
    const basePizookiePoints =
        35; // Increased from 25 to promote pizookie running

    _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
    lastRunServerId = id;
    _teamTotalThisShift += delta;

    // Increment per-shift pizookie count
    _currentPizookieCounts[id] = (_currentPizookieCounts[id] ?? 0) + delta;

    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;
    final prof = _profiles[id] ?? ServerProfile();
    final serverName = serverById(id)?.name ?? 'Server';

    checkBoostExpiry(); // Check if boost has expired
    final rawBoostedPoints = (_boostActive
        ? (basePizookiePoints * _boostMultiplier).round()
        : basePizookiePoints);
    final boostedPizookiePoints = _roundXP(rawBoostedPoints);
    prof.points += boostedPizookiePoints;

    // Track actual XP earned this shift
    _currentEarnedXP[id] = (_currentEarnedXP[id] ?? 0) + boostedPizookiePoints;

    // Track XP from this specific pizookie action
    int actionXP = boostedPizookiePoints;

    prof.allTimeRuns += delta;
    prof.pizookieRuns += delta;
    d('[DEBUG] Server $id ran a Pizookie: +$boostedPizookiePoints XP (base: $basePizookiePoints, boost: ${_boostActive ? "${_boostMultiplier}x" : "none"}), total now: ${prof.points}');

    final prevIso = prof.lastTapIso;
    prof.lastTapIso = now.toIso8601String();
    if (prevIso != null) {
      final prev = DateTime.tryParse(prevIso);
      if (prev != null) {
        final ms = now.difference(prev).inMilliseconds;
        if (ms > 0 && ms < 20 * 60 * 1000) {
          prof.tapIntervalsMsSum += ms;
          prof.tapIntervalsCount += 1;
        }
      }
    }

    if (settings.gamificationEnabled) {
      if (_currentStreaks[id]! > prof.streakBest) {
        prof.streakBest = _currentStreaks[id]!;
      }
      if (prof.streakBest >= 3) _awardOnce(prof, 'three_streak', serverName);
      if (prof.streakBest >= 5) _awardOnce(prof, 'five_streak', serverName);

      if (sCount >= 10) _awardOnce(prof, 'ten_in_shift', serverName);
      if (sCount >= 20) _awardOnce(prof, 'twenty_in_shift', serverName);
      if (now.hour >= 23) _awardOnce(prof, 'night_owl', serverName);

      _awardOnce(prof, 'first_run_today', serverName);
      if (prof.allTimeRuns == 0 &&
          !_profiles.containsKey('first_run_\\${id}_awarded')) {
        _awardOnce(prof, 'first_run', serverName);
      }

      if (isLunchPeak(now)) {
        _lunchPeakCount[id] = (_lunchPeakCount[id] ?? 0) + delta;
        if (_lunchPeakCount[id]! >= 10)
          _awardOnce(prof, 'lunch_peak_10', serverName);
      }
      if (isDinnerPeak(now)) {
        _dinnerPeakCount[id] = (_dinnerPeakCount[id] ?? 0) + delta;
        if (_dinnerPeakCount[id]! >= 10)
          _awardOnce(prof, 'dinner_peak_10', serverName);
      }
      if (isLunchCloser(now)) {
        _lunchCloserCount[id] = (_lunchCloserCount[id] ?? 0) + delta;
        if (_lunchCloserCount[id]! >= 8)
          _awardOnce(prof, 'lunch_closer_8', serverName);
      }
      if (isDinnerCloser(now)) {
        _dinnerCloserCount[id] = (_dinnerCloserCount[id] ?? 0) + delta;
        if (_dinnerCloserCount[id]! >= 8)
          _awardOnce(prof, 'dinner_closer_8', serverName);
      }
    }

    _profiles[id] = prof;

    final minuteEpoch =
        DateTime(now.year, now.month, now.day, now.hour, now.minute)
            .millisecondsSinceEpoch;
    _tapPerMinute.putIfAbsent(id, () => <int, int>{});
    _tapPerMinute[id]![minuteEpoch] =
        (_tapPerMinute[id]![minuteEpoch] ?? 0) + 1;
    _tapTimestamps
        .putIfAbsent(id, () => <int>[])
        .add(now.millisecondsSinceEpoch);
    _pizookieTimestamps
        .putIfAbsent(id, () => <int>[])
        .add(now.millisecondsSinceEpoch);
    _persistTapLog();
    _persistTapTimestamps();
    _persistPizookieTimestamps();
    _persistProfiles();
    _persistTotals();

    // Check for milestone achievements and award XP
    final milestone = MilestoneDetectionService.checkForMilestones(id, this,
        isPizookie: true);
    if (milestone != null) {
      // Award the milestone XP to the profile
      final updatedProf = _profiles[id] ?? ServerProfile();
      final roundedMilestoneXP = _roundXP(milestone.xpReward);
      updatedProf.points += roundedMilestoneXP;

      // Add milestone bonus XP to current shift tracking
      _currentBonusXP[id] = (_currentBonusXP[id] ?? 0) + roundedMilestoneXP;
      _currentEarnedXP[id] = (_currentEarnedXP[id] ?? 0) + roundedMilestoneXP;

      // Add milestone XP to this action's total
      actionXP += roundedMilestoneXP;

      // Store milestone details for notification display
      _lastMilestoneDetails[id] = {
        'type': milestone.type.name,
        'xpReward': roundedMilestoneXP,
        'message': milestone.message,
        'subMessage': milestone.subMessage,
        'priority': milestone.priority.name,
        'context': milestone.context,
        'timestamp': _now.toIso8601String(),
        'actionType': 'pizookie',
      };

      // Add milestone to history
      updatedProf.milestoneHistory.add({
        'type': milestone.type.name,
        'xpReward': roundedMilestoneXP,
        'timestamp': _now.toIso8601String(),
        'message': milestone.message,
      });

      _profiles[id] = updatedProf;
      _persistProfiles(); // Persist immediately

      d('[DEBUG] Pizookie milestone earned by $id: ${milestone.type.name} (+${milestone.xpReward} XP)');
      d('[DEBUG] Current shift bonus XP for $id: ${_currentBonusXP[id]}');
    }

    // Store the total XP gained from this specific pizookie action
    _lastActionXP[id] = actionXP;

    notifyListeners();
    return milestone;
  }

  // For Full Hands! achievement: not persisted, just for session
  final Map<String, List<DateTime>> _recentTapTimes = {};
  // Removed legacy hardcoded switch minutes. All timing is user-defined via
  // WeeklyHours (open/close) and DayPlan (transitionStart/End).

  // Admin PIN Management
  Future<String> get adminPin async => await Storage.getAdminPin();

  Future<bool> isValidAdminPin(String pin) async {
    final storedPin = await Storage.getAdminPin();
    return pin == storedPin;
  }

  Future<void> setAdminPin(String newPin) async {
    if (newPin.length == 4 && RegExp(r'^\d{4}$').hasMatch(newPin)) {
      await Storage.setAdminPin(newPin);
      notifyListeners();
    } else {
      throw ArgumentError('PIN must be exactly 4 digits');
    }
  }

  // Transition Checkpoint Management
  Future<Map<String, dynamic>?> _getTransitionCheckpoint() async {
    return await Storage.settingsBox.get('transition_checkpoint')
        as Map<String, dynamic>?;
  }

  Future<void> _setTransitionCheckpoint(Map<String, dynamic> checkpoint) async {
    checkpoint['timestamp'] = _now.toIso8601String();
    await Storage.settingsBox.put('transition_checkpoint', checkpoint);
    d('[CHECKPOINT] Saved: $checkpoint');
  }

  Future<void> _clearTransitionCheckpoint() async {
    await Storage.settingsBox.delete('transition_checkpoint');
    d('[CHECKPOINT] Cleared');
  }

  /// Check for incomplete transitions on app startup and handle recovery
  Future<void> _checkStartupTransitionRecovery() async {
    // Read transition checkpoint on startup for recovery.
    final checkpoint = await _getTransitionCheckpoint();
    if (checkpoint == null) {
      d('[STARTUP] No transition checkpoint found');
      return; // No incomplete transition
    }

    final now = _clock.now();
    final timestampValue = checkpoint['timestamp'];
    final lastTime = timestampValue is String 
        ? DateTime.parse(timestampValue)
        : DateTime.fromMillisecondsSinceEpoch(timestampValue as int);
    final lastShift = checkpoint['from_shift'] as String?;
    final targetShift = checkpoint['to_shift'] as String?;

    d('[STARTUP] Found checkpoint: $lastShift → $targetShift at $lastTime');

    // Skip if checkpoint doesn't have shift information
    if (lastShift == null || targetShift == null) {
      d('[STARTUP] Checkpoint missing shift information, clearing');
      await _clearTransitionCheckpoint();
      return;
    }

    // If checkpoint is very old (>24 hours), clear it as stale
    if (now.difference(lastTime).inHours > 24) {
      d('[STARTUP] Checkpoint too old, clearing');
      await _clearTransitionCheckpoint();
      return;
    }

    // If checkpoint is recent (within last few minutes), let normal flow handle it
    if (now.difference(lastTime).inMinutes < 5) {
      d('[STARTUP] Recent checkpoint, letting normal flow handle');
      return;
    }

    // For checkpoints between 5 minutes and 24 hours old, check if transition should complete
    final currentShift = currentIntendedShiftType(now);
    if (currentShift.toLowerCase() == targetShift.toLowerCase()) {
      d('[STARTUP] Completing interrupted transition to $targetShift');
      // Transition should have happened - complete it now
      if (_todayPlan != null) {
        if (currentShift.toLowerCase() == 'dinner' &&
            lastShift.toLowerCase() == 'lunch') {
          _beginShift('Dinner', _todayPlan!.dinnerRoster,
              preserveCounts: false);
        } else if (currentShift.toLowerCase() == 'lunch') {
          _beginShift('Lunch', _todayPlan!.lunchRoster);
        }
      }
      await _clearTransitionCheckpoint();
    } else {
      d('[STARTUP] Current shift ($currentShift) != target ($targetShift), clearing stale checkpoint');
      await _clearTransitionCheckpoint();
    }
  }

  final List<Server> _servers = [];
  final Map<String, int> _totals = {};
  Map<String, ServerProfile> _profiles = {};
  WeeklyHours _hours = WeeklyHours.defaults();

  GamificationSettings settings = GamificationSettings();

  DayPlan? _todayPlan;

  bool _shiftActive = false;
  bool _shiftPaused = false;
  String _shiftType = 'Lunch';
  DateTime? _shiftStart;
  final Map<String, int> _currentCounts = {};
  final Map<String, int> _currentStreaks = {};
  final Map<String, int> _currentBonusXP =
      {}; // Track milestone bonus XP for current shift
  final Map<String, int> _currentEarnedXP =
      {}; // Track actual XP earned this shift (including boosts)
  final Map<String, String> _lastFlashMessages =
      {}; // Track last flash message for each server
  final Map<String, int> _lastActionXP =
      {}; // Track XP gained from most recent action
  final Map<String, Map<String, dynamic>> _lastMilestoneDetails =
      {}; // Track details of last milestone/achievement
  final Set<String> _workingServerIds = {};
  int _teamGoal = 0;
  int _teamTotalThisShift = 0;

  final Map<String, int> _lunchPeakCount = {};
  final Map<String, int> _dinnerPeakCount = {};
  final Map<String, int> _lunchCloserCount = {};
  final Map<String, int> _dinnerCloserCount = {};

  final Map<String, Map<int, int>> _tapPerMinute = {};
  final Map<String, List<int>> _tapTimestamps =
      {}; // Individual timestamp storage
  
  // Store pizookie click timestamps separately for visual distinction
  final Map<String, List<int>> _pizookieTimestamps =
      {}; // Individual pizookie click timestamps
      
  String? _recentBadgeBubble;
  Timer? _ticker;

  // Roster toggle state: 'auto', 'lunch', 'dinner'
  String _activeRosterView = 'auto';

  // Boost mode for high-volume periods
  bool _boostActive = false;
  double _boostMultiplier = 1.0;
  DateTime? _boostEndTime;
  String _boostDescription = '';

  // expose
  List<Server> get servers => List.unmodifiable(_servers
      .sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
  Map<String, int> get totals => Map.unmodifiable(_totals);
  Map<String, ServerProfile> get profiles => Map.unmodifiable(_profiles);
  WeeklyHours get hours => _hours;

  bool get shiftActive => _shiftActive;
  bool get shiftPaused => _shiftPaused;
  String get shiftType => _shiftType;
  DateTime? get shiftStart => _shiftStart;
  Map<String, int> get currentCounts => Map<String, int>.from(_currentCounts);
  Map<String, int> get currentBonusXP => Map.unmodifiable(_currentBonusXP);
  Map<String, int> get currentEarnedXP => Map.unmodifiable(_currentEarnedXP);
  
  /// Get current station assignments for real-time analytics
  Map<String, String> get currentStationAssignments {
    // Return current station assignments based on working server IDs
    // This is a simplified implementation for real-time monitoring
    final assignments = <String, String>{};
    
    // For now, return a map with working servers mapped to their shift type
    // In a full implementation, this would query the current station configuration
    for (final serverId in _workingServerIds) {
      assignments[serverId] = _shiftType; // Simplified: use shift type as station
    }
    
    return assignments;
  }
  Map<String, String> get lastFlashMessages =>
      Map.unmodifiable(_lastFlashMessages);
  Map<String, int> get lastActionXP => Map.unmodifiable(_lastActionXP);
  Map<String, Map<String, dynamic>> get lastMilestoneDetails =>
      Map.unmodifiable(_lastMilestoneDetails);
  Set<String> get workingServerIds => Set.unmodifiable(_workingServerIds);
  int get teamGoal => _teamGoal;
  int get teamTotalThisShift => _teamTotalThisShift;
  DayPlan? get todayPlan => _todayPlan;

  String? get recentBadgeBubble => _recentBadgeBubble;
  void clearRecentBadgeBubble() {
    _recentBadgeBubble = null;
  }

  // Roster toggle logic
  String get activeRosterView => _activeRosterView;

  // Boost mode getters
  bool get boostActive => _boostActive;
  double get boostMultiplier => _boostMultiplier;
  DateTime? get boostEndTime => _boostEndTime;
  String get boostDescription => _boostDescription;

  String get boostTimeRemaining {
    if (!_boostActive || _boostEndTime == null) return '';

    final remaining = _boostEndTime!.difference(_now);
    if (remaining.isNegative) return '0:00';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Track the last flash message for a server
  void setLastFlashMessage(String serverId, String message) {
    _lastFlashMessages[serverId] = message;
    notifyListeners();
  }

  /// Get effective transition times - uses plan values if set, otherwise calculates dynamic defaults
  Map<String, int> getEffectiveTransitionTimes([DateTime? forTime]) {
    final now = forTime ?? _now;
    final dynamicTransitions = _calculateDynamicTransitions(now);

    return {
      'start':
          _todayPlan?.transitionStartMinutes ?? dynamicTransitions['lunchEnd']!,
      'end': _todayPlan?.transitionEndMinutes ??
          dynamicTransitions['dinnerStart']!,
    };
  }

  void toggleRosterView() {
    d('[DEBUG] toggleRosterView: Current view = $_activeRosterView');
    final plan = _todayPlan;
    if (_activeRosterView == 'lunch') {
      _activeRosterView = 'dinner';
      d('[DEBUG] toggleRosterView: Switching to dinner view');
      if (plan != null) {
        final now = _now;
        final m = now.hour * 60 + now.minute;
        final start = plan.transitionStartMinutes;
        final end = plan.transitionEndMinutes;
        if (m >= start && m < end) {
          // During transition, ensure all dinner servers (including dinner-only) are added and tracked
          updateActiveRoster(plan.dinnerRoster, preserveExistingCounts: true);
        } else {
          // At the end of transition, only reset counts for servers who are in both lunch and dinner rosters
          final lunchSet = plan.lunchRoster.toSet();
          final dinnerSet = plan.dinnerRoster.toSet();
          final both = lunchSet.intersection(dinnerSet);
          // First, preserve counts for dinner-only servers and keep them in workingServerIds
          updateActiveRoster(plan.dinnerRoster, preserveExistingCounts: true);
          // Then, reset counts for servers in both lunch and dinner
          for (final id in both) {
            _currentCounts[id] = 0;
            _currentStreaks[id] = 0;
            _lunchPeakCount[id] = 0;
            _dinnerPeakCount[id] = 0;
            _lunchCloserCount[id] = 0;
            _dinnerCloserCount[id] = 0;
          }
          // Dinner-only servers keep their counts
          notifyListeners();
        }
      }
    } else if (_activeRosterView == 'dinner') {
      _activeRosterView = 'lunch';
      d('[DEBUG] toggleRosterView: Switching to lunch view');
      if (plan != null) {
        final now = _now;
        final m = now.hour * 60 + now.minute;
        final start = plan.transitionStartMinutes;
        final end = plan.transitionEndMinutes;
        if (m >= start && m < end) {
          updateActiveRoster(plan.lunchRoster, preserveExistingCounts: true);
        } else {
          updateActiveRoster(plan.lunchRoster);
        }
      }
    } else {
      // Auto mode default view based on today's transition window
      final now = _now;
      final start =
          plan?.transitionStartMinutes ?? settings.transitionStartMinutes;
      final end = plan?.transitionEndMinutes ?? settings.transitionEndMinutes;
      final m = now.hour * 60 + now.minute;
      _activeRosterView = (m >= end) ? 'dinner' : 'lunch';
    }
    notifyListeners();
  }

  void resetRosterView() {
    _activeRosterView = 'auto';
    notifyListeners();
  }

  List<String> get currentRoster {
    final now = _now;
    final m = now.hour * 60 + now.minute;
    final start =
        _todayPlan?.transitionStartMinutes ?? settings.transitionStartMinutes;
    final end =
        _todayPlan?.transitionEndMinutes ?? settings.transitionEndMinutes;
    if (_activeRosterView == 'lunch') {
      return _todayPlan?.lunchRoster ?? [];
    }
    if (_activeRosterView == 'dinner') {
      return _todayPlan?.dinnerRoster ?? [];
    }
    // 'auto' mode
    if (m < start) return _todayPlan?.lunchRoster ?? [];
    if (m < end) return _todayPlan?.lunchRoster ?? []; // transition
    return _todayPlan?.dinnerRoster ?? [];
  }

  // Boost mode methods
  Future<void> activateBoost(double multiplier, int durationMinutes,
      String description, String pin) async {
    if (!(await isValidAdminPin(pin))) return;

    _boostActive = true;
    _boostMultiplier = multiplier;
    _boostEndTime = _now.add(Duration(minutes: durationMinutes));
    _boostDescription = description;
    notifyListeners();

    // Auto-deactivate when time expires
    Timer(Duration(minutes: durationMinutes), () {
      if (_boostActive &&
          _boostEndTime != null &&
          _now.isAfter(_boostEndTime!)) {
        deactivateBoost();
      }
    });
  }

  void deactivateBoost() {
    _boostActive = false;
    _boostMultiplier = 1.0;
    _boostEndTime = null;
    _boostDescription = '';
    notifyListeners();
  }

  void checkBoostExpiry() {
    if (_boostActive && _boostEndTime != null && _now.isAfter(_boostEndTime!)) {
      deactivateBoost();
    }
  }

  final List<ShiftRecord> _history = [];
  List<ShiftRecord> get history {
    final raw = (_history..sort((a, b) => b.start.compareTo(a.start)));
    return List.unmodifiable(raw);
  }

  int allTimeFor(String id) => (_totals[id] ?? 0) + (_currentCounts[id] ?? 0);
  Server? serverById(String id) => _servers.firstWhereOrNull((s) => s.id == id);

  bool _schemaNewerDetected = false;
  bool get schemaNewerDetected => _schemaNewerDetected;

  Future<void> load() async {
    // Schema version check & migrations (atomic bump after success)
    final storedVersion = await Storage.getSchemaVersion();
    if (storedVersion < Storage.currentSchemaVersion) {
      d('[SCHEMA] Detected older schemaVersion=$storedVersion, current=${Storage.currentSchemaVersion}. Preparing backup and running migrations...');
      // Best-effort snapshot
      await _exportBoxes([
        'servers',
        'totals',
        'shifts',
        'profiles',
        'settings',
        'dayplan',
        'taplog'
      ]);
      // Run migrations; any error bubbles up and prevents bump
      await _runMigrations(
          from: storedVersion, to: Storage.currentSchemaVersion);
      // Only after successful migrations do we bump the stored version
      await Storage.setSchemaVersion(Storage.currentSchemaVersion);
      d('[SCHEMA] Migration complete. Updated schemaVersion=${Storage.currentSchemaVersion}');
    } else if (storedVersion > Storage.currentSchemaVersion) {
      // Newer schema detected — set flag and proceed
      _schemaNewerDetected = true;
      d('[SCHEMA] Warning: Stored schemaVersion=$storedVersion is newer than app (${Storage.currentSchemaVersion}). Proceeding in read-only posture.');
    } else {
      d('[SCHEMA] Schema up-to-date at version ${Storage.currentSchemaVersion}.');
    }

    final sl =
        (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
    final loadedServers =
        sl.map((m) => Server.fromMap(Map<String, dynamic>.from(m))).toList();
    final loadedTotals =
        (await Storage.totalsBox.get('totals') as Map?)?.cast<String, int>() ??
            {};
    final histList =
        (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
    final loadedProfiles = <String, ServerProfile>{};
    for (final s in loadedServers) {
      final m = (await Storage.profilesBox.get(s.id) as Map?) ?? {};
      if (m.isEmpty) {
        // Preserve existing profile if it exists, otherwise create new one
        loadedProfiles[s.id] = _profiles[s.id] ?? ServerProfile();
      } else {
        loadedProfiles[s.id] = ServerProfile.fromMap(m);
      }
    }

    // Merge with any in-memory data (shouldn't be needed, but extra safe)
    for (final entry in _totals.entries) {
      loadedTotals.putIfAbsent(entry.key, () => entry.value);
    }
    for (final entry in _profiles.entries) {
      loadedProfiles.putIfAbsent(entry.key, () => entry.value);
    }

    _servers
      ..clear()
      ..addAll(loadedServers);
    _totals
      ..clear()
      ..addAll(loadedTotals);
    _history
      ..clear()
      ..addAll(histList
          .map((m) => ShiftRecord.fromMap(Map<String, dynamic>.from(m))));
    _profiles
      ..clear()
      ..addAll(loadedProfiles);

    final hm = (await Storage.settingsBox.get('weekly_hours') as Map?) ?? {};
    _hours = hm.isEmpty
        ? WeeklyHours.defaults()
        : WeeklyHours.fromMap(Map<String, dynamic>.from(hm));
    // Debug: log loaded weekly hours so we can verify persisted settings
    d('[DEBUG] Loaded weekly_hours from storage: ${_hours.toMap()}');

    // Temporary debug override: if settingsBox contains 'debug_force_test_hours' = true,
    // force hours to 01:10–04:00 for all weekdays so we can test opening-time behavior.
    final force =
        (await Storage.settingsBox.get('debug_force_test_hours') as bool?) ??
            false;
    if (force) {
      final open = <int, int>{for (var d = 1; d <= 7; d++) d: 1 * 60 + 10};
      final close = <int, int>{for (var d = 1; d <= 7; d++) d: 4 * 60};
      final closeDayOffset = {for (var d = 1; d <= 7; d++) d: 1};
      _hours = WeeklyHours(
          openMinutes: open,
          closeMinutes: close,
          closeDayOffset: closeDayOffset);
      d('[DEBUG] Forced test weekly_hours applied: ${_hours.toMap()}');
    }

    final ymd = _ymd(_now);
    final dp = (await Storage.dayPlanBox.get(ymd) as Map?) ?? {};
    _todayPlan =
        dp.isEmpty ? null : DayPlan.fromMap(Map<String, dynamic>.from(dp));

    final tapRaw = (await Storage.tapBox.get('per_minute') as Map?) ?? {};
    _tapPerMinute
      ..clear()
      ..addAll(tapRaw.map((sid, m) => MapEntry(
          sid as String,
          Map<int, int>.from((m as Map)
              .map((k, v) => MapEntry(int.parse(k as String), v as int))))));

    // Load individual timestamps
    final timestamps =
        (await Storage.tapTimestampsBox.get('timestamps') as Map?) ?? {};
    _tapTimestamps
      ..clear()
      ..addAll(timestamps.map((serverId, timestampList) =>
          MapEntry(serverId as String, List<int>.from(timestampList as List))));

    // Load individual pizookie timestamps
    final pizookieTimestamps =
        (await Storage.tapTimestampsBox.get('pizookie_timestamps') as Map?) ?? {};
    _pizookieTimestamps
      ..clear()
      ..addAll(pizookieTimestamps.map((serverId, timestampList) =>
          MapEntry(serverId as String, List<int>.from(timestampList as List))));

    // Reconstruct allTimeRuns from historical tap data if needed
    reconstructAllTimeRuns();

    final sm = (await Storage.settingsBox.get('gamification') as Map?) ?? {};
    // MIGRATION: Ensure encouragementFlashEnabled is always set in the map
    if (!sm.containsKey('encouragementFlashEnabled')) {
      sm['encouragementFlashEnabled'] = true;
      await Storage.settingsBox.put('gamification', sm);
    }
    settings = sm.isEmpty
        ? GamificationSettings()
        : GamificationSettings.fromMap(Map<String, dynamic>.from(sm));

    // Load wallpaper settings
    _selectedWallpaper =
        (await Storage.settingsBox.get('selectedWallpaper') as String?) ??
            'none';
    _autoRotateWallpaper =
        (await Storage.settingsBox.get('autoRotateWallpaper') as bool?) ??
            false;

    _teamGoal = _computeGoalFromHistory();

    // Check for incomplete transitions on startup
    await _checkStartupTransitionRecovery();

    _startTicker();
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  // Save a partial shift record for only a subset of servers (e.g., lunch at transition)
  void _savePartialShift(
      String type, Map<String, int> counts, Map<String, int> pizookieCounts) {
    // If saving a Lunch shift, filter out dinner-only servers from counts
    Map<String, int> filteredCounts = counts;
    Map<String, int> filteredPizookieCounts = pizookieCounts;
    if (type == 'Lunch' && _todayPlan != null) {
      final lunchSet = _todayPlan!.lunchRoster.toSet();
      filteredCounts = Map.fromEntries(
          counts.entries.where((e) => lunchSet.contains(e.key)));
      filteredPizookieCounts = Map.fromEntries(
          pizookieCounts.entries.where((e) => lunchSet.contains(e.key)));
    }
    final rec = ShiftRecord(
      id: _randId(),
      label: type,
      shiftType: type,
      start: _shiftStart ?? _now,
      counts: filteredCounts,
      pizookieCounts: filteredPizookieCounts,
    );
    _history.add(rec);
    // Update totals and profiles for just these servers
    String? mvpId;
    int mvpScore = -1;
    filteredCounts.forEach((id, n) {
      _totals[id] = (_totals[id] ?? 0) + n;
      final prof = _profiles[id] ?? ServerProfile();
      if (n > prof.bestShiftRuns) prof.bestShiftRuns = n;
      // Use _totals[id] for all-time achievements
      final allTime = _totals[id] ?? 0;
      if (settings.gamificationEnabled) {
        if (allTime >= 50 && !prof.achievements.contains('fifty_all_time')) {
          prof.achievements.add('fifty_all_time');
          prof.points += _pointsFor('fifty_all_time');
        }
        if (allTime >= 100 && !prof.achievements.contains('hundred_all_time')) {
          prof.achievements.add('hundred_all_time');
          prof.points += _pointsFor('hundred_all_time');
        }
      }
      if (n > mvpScore) {
        mvpScore = n;
        mvpId = id;
      }
      _profiles[id] = prof;
    });
    if (settings.gamificationEnabled && mvpId != null) {
      final p = _profiles[mvpId]!;
      p.shiftsAsMvp += 1;
      if (!p.achievements.contains('mvp')) {
        p.achievements.add('mvp');
        p.points += _pointsFor('mvp');
      }
    }
    final teamTotal = counts.values.fold<int>(0, (a, b) => a + b);
    if (settings.gamificationEnabled && teamTotal >= _teamGoal) {
      for (final id in counts.keys) {
        final prof = _profiles[id]!;
        if (!prof.achievements.contains('team_goal')) {
          prof.achievements.add('team_goal');
          prof.points += _pointsFor('team_goal');
        }
      }
    }
    _persistTotals();
    _persistProfiles();
    _persistHistory();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      d('[DEBUG] Timer tick: checking shift activation');
      _maybeActivateShiftByClock();
      _pruneOldTapBuckets();

      // Check boost expiry frequently
      checkBoostExpiry();

      // Notify listeners to update any time-dependent UI elements
      notifyListeners();
    });
  }

  Future<void> _persistServers() async =>
      Storage.serversBox.put('list', _servers.map((s) => s.toMap()).toList());
  Future<void> _persistTotals() async =>
      Storage.totalsBox.put('totals', _totals);
  Future<void> _persistHistory() async =>
      Storage.shiftsBox.put('list', _history.map((h) => h.toMap()).toList());
  Future<void> _persistProfiles() async {
    for (final e in _profiles.entries) {
      await Storage.profilesBox.put(e.key, e.value.toMap());
    }
  }

  Future<void> _persistHours() async =>
      Storage.settingsBox.put('weekly_hours', _hours.toMap());

  /// Storage migration entry point. Extend this when bumping schema versions.
  Future<void> _runMigrations({required int from, required int to}) async {
    if (from >= to) {
      d('[SCHEMA] No migrations necessary (from v$from to v$to).');
      return;
    }
    for (var v = from; v < to; v++) {
      d('[SCHEMA] Migrating from v$v to v${v + 1}');
      await _migrate_v(v, v + 1);
    }
  }

  Future<void> _migrate_v(int from, int to) async {
    if (from == 0 && to == 1) {
      await _migrate_v0_to_v1();
      return;
    }
    // Unknown step: by default no-op to avoid throwing in forward-only sequence
    d('[SCHEMA] No-op migrate step from v$from to v$to');
  }

  /// Idempotent migration from schema v0 to v1.
  Future<void> _migrate_v0_to_v1() async {
    // v1 establishes the schemaVersion key only; ensure it's present if not already
    final current = await Storage.getSchemaVersion();
    if (current >= 1) {
      d('[SCHEMA] v0->v1 already applied (schemaVersion=$current).');
      return; // idempotent
    }
    d('[SCHEMA] Applying v0->v1 migration (establish schemaVersion key).');
    // Nothing else to transform yet.
  }

  /// Debug-only convenience to re-run migrations without bumping unless all succeed.
  Future<void> adminReRunMigrations() async {
    final stored = await Storage.getSchemaVersion();
    d('[SCHEMA] Admin requested re-run migrations from v$stored to v${Storage.currentSchemaVersion}');
    await Storage.exportBoxes([
      'servers',
      'totals',
      'shifts',
      'profiles',
      'settings',
      'dayplan',
      'taplog'
    ]);
    await _runMigrations(from: stored, to: Storage.currentSchemaVersion);
    await Storage.setSchemaVersion(Storage.currentSchemaVersion);
    d('[SCHEMA] Admin migration complete. Updated schemaVersion=${Storage.currentSchemaVersion}');
  }

  // Public save method to persist all data changes
  Future<void> save() async {
    await _persistServers();
    await _persistProfiles();
    await _persistTotals();
    await _persistHistory();
    await _persistHours();
    await _persistDayPlan();
    await _persistTapLog();
  }

  // Recalculate MVP awards from all historical shifts
  void recalculateMVPAwards() {
    // Reset all MVP awards to 0
    for (final profile in _profiles.values) {
      profile.shiftsAsMvp = 0;
    }

    // Go through each shift in history and determine MVP
    for (final shift in _history) {
      String? mvpId;
      int highestXP = 0;

      // Calculate XP for each server in this shift
      for (final entry in shift.counts.entries) {
        final serverId = entry.key;
        final runs = entry.value;
        final pizookieRuns = shift.pizookieCounts[serverId] ??
            0; // Use shift-specific pizookie data

        final xp = (runs * 10) + (pizookieRuns * 15);

        if (xp > highestXP) {
          highestXP = xp;
          mvpId = serverId;
        }
      }

      // Award MVP to the highest XP earner (if any XP was earned)
      if (mvpId != null && highestXP > 0) {
        final profile = _profiles[mvpId];
        if (profile != null) {
          profile.shiftsAsMvp += 1;
        }
      }
    }

    // Persist the updated profiles
    _persistProfiles();
    notifyListeners();
  }

  // Update a server profile and notify listeners
  Future<void> updateServerProfile(
      String serverId, ServerProfile profile) async {
    _profiles[serverId] = profile;
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> _persistDayPlan() async {
    if (_todayPlan != null) {
      await Storage.dayPlanBox.put(_todayPlan!.ymd, _todayPlan!.toMap());
    }
  }

  Future<void> _persistTapLog() async {
    final map = _tapPerMinute.map(
        (sid, m) => MapEntry(sid, m.map((k, v) => MapEntry(k.toString(), v))));
    await Storage.tapBox.put('per_minute', map);
  }

  Future<void> _persistTapTimestamps() async {
    await Storage.tapTimestampsBox.put('timestamps', _tapTimestamps);
  }

  Future<void> _persistPizookieTimestamps() async {
    await Storage.tapTimestampsBox.put('pizookie_timestamps', _pizookieTimestamps);
  }

  Future<void> saveSettings(GamificationSettings s) async {
    settings = s;
    await Storage.settingsBox.put('gamification', s.toMap());
    // If today's plan exists, update its transition times and persist
    if (_todayPlan != null) {
      _todayPlan = DayPlan(
        ymd: _todayPlan!.ymd,
        lunchRoster: List.of(_todayPlan!.lunchRoster),
        dinnerRoster: List.of(_todayPlan!.dinnerRoster),
        transitionStartMinutes: s.transitionStartMinutes,
        transitionEndMinutes: s.transitionEndMinutes,
      );
      await _persistDayPlan();
    }
    // Clear any previous transition checkpoint since timing changed
    await _clearTransitionCheckpoint();
    // Clear manual override so new timings take effect
    _manualShiftOverride = false;
    notifyListeners();
  }

  void setWeeklyHours(WeeklyHours h) {
    _hours = h;
    _persistHours();
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  void setTodayPlan(List<String> lunch, List<String> dinner) {
    final ymd = _ymd(_now);
    _todayPlan = DayPlan(
      ymd: ymd,
      lunchRoster: List.of(lunch),
      dinnerRoster: List.of(dinner),
      transitionStartMinutes: settings.transitionStartMinutes,
      transitionEndMinutes: settings.transitionEndMinutes,
    );
    _persistDayPlan();
    // Clear any previous transition checkpoint since plan changed
    _clearTransitionCheckpoint();
    // Clear manual override when plan changes
    _manualShiftOverride = false;
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  bool forceStartCurrentShift() {
    final now = _now;
    if (_todayPlan == null) return false;
    final intended = currentIntendedShiftType(now);
    final roster = intended == 'Lunch'
        ? _todayPlan!.lunchRoster
        : _todayPlan!.dinnerRoster;
    if (roster.isEmpty) return false;
    _beginShift(intended, roster);
    return true;
  }

  Future<void> startNewShift({
    required String label, // UI may pass text; we override based on clock
    required List<String> workingIds,
    DateTime? start,
  }) async {
    _shiftActive = true;
    final now = start ?? _now;
    // If caller specifies a known shift label, honor it; otherwise fall back to clock heuristic
    if (label == 'Lunch' || label == 'Dinner') {
      _shiftType = label;
      // Engage manual override to prevent immediate auto-switch
      _manualShiftOverride = true;
    } else {
      _shiftType = currentIntendedShiftType(now);
      _manualShiftOverride = false;
    }
    _shiftStart = now;

    _workingServerIds
      ..clear()
      ..addAll(workingIds);
    _currentCounts
      ..clear()
      ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
    _currentStreaks
      ..clear()
      ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
    _lunchPeakCount
      ..clear()
      ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
    _dinnerPeakCount
      ..clear()
      ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
    _lunchCloserCount
      ..clear()
      ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
    _dinnerCloserCount
      ..clear()
      ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
    _currentPizookieCounts
      ..clear()
      ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));

    _teamTotalThisShift = 0;
    _teamGoal = _computeGoalFromHistory();
    notifyListeners();
  }

  bool get isOpenNow {
    final now = _now;
    final wd = AppState.weekday(now);
    final open = _hours.openMinutes[wd] ?? 11 * 60;
    final close = _hours.closeMinutes[wd] ?? 23 * 60;

    // Validate business hours data
    assert(open >= 0 && open < 1440,
        'Open time must be between 0-1439 minutes, got $open');
    // Allow close==1440 (exactly midnight next day); treat as 0 with offset logic elsewhere.
    assert(close >= 0 && close <= 1440,
        'Close time must be between 0-1440 minutes, got $close');

    final currentMinutes = now.hour * 60 + now.minute;

    d('DEBUG isOpenNow: currentMinutes=$currentMinutes, open=$open, close=$close');

    if (close > open) {
      // Normal day operation: open=9:00(540), close=17:00(1020)
      final isOpen = currentMinutes >= open && currentMinutes < close;
      d('DEBUG isOpenNow: Normal hours, isOpen=$isOpen');
      return isOpen;
    } else {
      // Overnight operation: open=17:00(1020), close=01:00(60) next day
      // Open if: current >= open OR current < close
      final isOpen = currentMinutes >= open || currentMinutes < close;
      d('DEBUG isOpenNow: Overnight hours, isOpen=$isOpen');
      return isOpen;
    }
  }

  /// Helper to test business hours logic at an arbitrary DateTime (used in tests)
  bool isOpenAt(DateTime t) {
    final businessDate = AppState.businessDate(t);
    final weekday = businessDate.weekday;

    final todayInterval = businessDayInterval(businessDate, weekday);
    if (!t.isBefore(todayInterval.start) && t.isBefore(todayInterval.end))
      return true;

    final yesterdayBusinessDate =
        businessDate.subtract(const Duration(days: 1));
    final yesterdayWeekday = yesterdayBusinessDate.weekday;
    final yesterdayInterval =
        businessDayInterval(yesterdayBusinessDate, yesterdayWeekday);
    if (!t.isBefore(yesterdayInterval.start) &&
        t.isBefore(yesterdayInterval.end)) return true;

    return false;
  }

  /// Standalone helper: determine open state for a given WeeklyHours and DateTime
  bool isOpenAtFor(WeeklyHours hours, DateTime t) {
    // local version of businessDayInterval using specified hours
    DateTimeRange businessDayIntervalFor(DateTime businessDate, int weekday) {
      final openMinutes = hours.openMinutes[weekday] ?? 11 * 60;
      final closeMinutes = hours.closeMinutes[weekday] ?? 23 * 60;
      final closeDayOffset = hours.closeDayOffset[weekday] ?? 0;

      final start = DateTime(
        businessDate.year,
        businessDate.month,
        businessDate.day,
        openMinutes ~/ 60,
        openMinutes % 60,
      );

      final endDate = closeDayOffset == 1
          ? businessDate.add(const Duration(days: 1))
          : businessDate;
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        closeMinutes ~/ 60,
        closeMinutes % 60,
      );
      return DateTimeRange(start: start, end: end);
    }

    final businessDate = AppState.businessDate(t);
    final weekday = businessDate.weekday;

    final todayInterval = businessDayIntervalFor(businessDate, weekday);
    if (!t.isBefore(todayInterval.start) && t.isBefore(todayInterval.end))
      return true;

    final yesterdayBusinessDate =
        businessDate.subtract(const Duration(days: 1));
    final yesterdayWeekday = yesterdayBusinessDate.weekday;
    final yesterdayInterval =
        businessDayIntervalFor(yesterdayBusinessDate, yesterdayWeekday);
    if (!t.isBefore(yesterdayInterval.start) &&
        t.isBefore(yesterdayInterval.end)) return true;

    return false;
  }

  String currentIntendedShiftType(DateTime now) {
    final wd = AppState.weekday(now);
    final m = now.hour * 60 + now.minute;
    final open = _hours.openMinutes[wd]!;

    // Use dynamic transition times based on actual business hours
    final transitions = _calculateDynamicTransitions(now);
    final lunchEnd = transitions['lunchEnd']!;
    final dinnerStart = transitions['dinnerStart']!;

    d('[DEBUG] currentIntendedShiftType: m=$m, open=$open, lunchEnd=$lunchEnd, dinnerStart=$dinnerStart');

    if (m < open) {
      d('[DEBUG] currentIntendedShiftType: Before open, returning Lunch');
      return 'Lunch';
    }
    if (m < lunchEnd) {
      d('[DEBUG] currentIntendedShiftType: Before lunch end, returning Lunch');
      return 'Lunch';
    }
    d('[DEBUG] currentIntendedShiftType: After lunch end, returning Dinner');
    return 'Dinner';
  }

  /// Calculate dynamic transition times based on business hours
  /// Returns minutes-since-midnight for transition points
  Map<String, int> _calculateDynamicTransitions(DateTime now) {
    final wd = AppState.weekday(now);
    final open = _hours.openMinutes[wd]!;
    final close = _hours.closeMinutes[wd] ?? 23 * 60;
    final closeDayOffset = _hours.closeDayOffset[wd] ?? 0;

    // Calculate total business duration in minutes
    int totalMinutes;
    if (closeDayOffset == 1) {
      // Overnight close: close time is on next day
      totalMinutes = (24 * 60 - open) +
          close; // Minutes until midnight + minutes after midnight
    } else {
      // Same-day close
      totalMinutes = close - open;
    }

    // Default transition point: 70% through the business day
    // This ensures adequate lunch period and transition to dinner
    final transitionPoint = (totalMinutes * 0.7).round();
    final transitionMinutes = open + transitionPoint;

    // Handle overnight business hours
    int lunchEnd, dinnerStart;
    if (transitionMinutes >= 24 * 60) {
      // Transition point crosses midnight
      lunchEnd = transitionMinutes - (24 * 60);
      dinnerStart = lunchEnd;
    } else {
      lunchEnd = transitionMinutes;
      dinnerStart = transitionMinutes;
    }

    d('[DEBUG] _calculateDynamicTransitions: open=$open, close=$close, totalMinutes=$totalMinutes');
    d('[DEBUG] _calculateDynamicTransitions: lunchEnd=$lunchEnd, dinnerStart=$dinnerStart');

    return {
      'lunchEnd': lunchEnd,
      'dinnerStart': dinnerStart,
    };
  }

  /// Improved shift transition logic with reliability features:
  /// - Uses injected Clock instead of DateTime.now()
  /// - Persists transition checkpoints to prevent double execution
  /// - Adds idempotent guards for reliable state transitions
  /// - Enhanced debug logging with kDebugMode guard
  Future<void> _maybeActivateShiftByClock() async {
    final now = _now;
    final ymd = _ymd(now);
    d('[DEBUG] _maybeActivateShiftByClock called at $now');

    // FIRST: Check if we need to close the restaurant - this overrides everything
    // BUT NOT during transition period - transition should be allowed to complete
    final plan = _todayPlan;
    if (plan != null) {
      final currentMinutes = now.hour * 60 + now.minute;
      final tStart = plan.transitionStartMinutes;
      final tEnd = plan.transitionEndMinutes;
      final isInTransition = currentMinutes >= tStart && currentMinutes < tEnd;
      
      if (!isOpenNow && _shiftActive && !isInTransition) {
        d('[DEBUG] _maybeActivateShiftByClock: Restaurant closed (not in transition), finalizing active shift');
        await _setTransitionCheckpoint({
          'action': 'close_end_of_day',
          'state': {'shiftType': _shiftType, 'shiftActive': false}
        });
        await _finalizeAndSaveShift(_shiftType);
        _shiftActive = false;
        _shiftPaused = false;
        _shiftType = '';  // Clear shift type to fully reset
        _workingServerIds.clear();
        _currentCounts.clear();
        _currentStreaks.clear();
        _currentBonusXP.clear();
        _currentEarnedXP.clear();
        _currentPizookieCounts.clear();
        _lunchPeakCount.clear();
        _dinnerPeakCount.clear();
        _lunchCloserCount.clear();
        _dinnerCloserCount.clear();
        await _clearTransitionCheckpoint();
        d('[DEBUG] _maybeActivateShiftByClock: Restaurant closed, all state cleared, returning to roster selection');
        print('RESTAURANT CLOSED: Clearing all UI state, should return to who is working today screen');
        notifyListeners();
        return;
      }
    }

    // Check for existing checkpoint to prevent double execution
    final checkpoint = await _getTransitionCheckpoint();
    String? lastCheckpointAction;
    DateTime? lastCheckpointTime;
    if (checkpoint != null) {
      final checkpointTime = DateTime.parse(checkpoint['timestamp']);
      final checkpointYmd = _ymd(checkpointTime);
      final timeDiff = now.difference(checkpointTime).inMinutes;
      lastCheckpointAction = checkpoint['action'] as String?;
      lastCheckpointTime = checkpointTime;

      // If checkpoint is from same day and recent (within 5 minutes), skip to prevent double execution
      if (checkpointYmd == ymd && timeDiff < 5) {
        final lastAction = checkpoint['action'];
        final lastState = checkpoint['state'];
        
        // CRITICAL FIX: Clear start_lunch checkpoint if it's blocking transition logic
        if (lastAction == 'start_lunch') {
          d('[TRANSITION FIX] Clearing start_lunch checkpoint to allow transition logic to proceed');
          await _clearTransitionCheckpoint();
          // Don't return - let transition logic continue
        } else {
          d('[DEBUG] Recent checkpoint found: $lastAction at ${checkpoint['timestamp']}, skipping duplicate transition');

          // Validate current state matches checkpoint expectation
          if (lastState != null) {
            final expectedShiftType = lastState['shiftType'];
            final expectedShiftActive = lastState['shiftActive'];

            if (_shiftType == expectedShiftType &&
                _shiftActive == expectedShiftActive) {
              d('[DEBUG] Current state matches checkpoint, transition already completed');
              return;
            } else {
              d('[WARNING] State mismatch detected - expected: $lastState, actual: {shiftType: $_shiftType, shiftActive: $_shiftActive}');
            }
          }
        }
      } else {
        // Clear old checkpoint if it's from a different day or too old
        await _clearTransitionCheckpoint();
      }
    }

    if (_todayPlan == null || _todayPlan!.ymd != ymd) {
      // Even without a plan we must still enforce open/closed boundaries
      final wd = AppState.weekday(now);
      final bDate = AppState.businessDate(now);
      final todayInterval = businessDayInterval(bDate, wd);
      final yBDate = bDate.subtract(const Duration(days: 1));
      final yW = yBDate.weekday;
      final yesterdayInterval = businessDayInterval(yBDate, yW);

      final inToday =
          !now.isBefore(todayInterval.start) && now.isBefore(todayInterval.end);
      final inYesterday = !now.isBefore(yesterdayInterval.start) &&
          now.isBefore(yesterdayInterval.end);

      // If outside any active business interval, ensure we are fully closed
      if (!inToday && !inYesterday) {
        d('[DEBUG] _maybeActivateShiftByClock: No plan and outside business hours — enforcing closed state');
        if (_shiftActive) {
          await _setTransitionCheckpoint({
            'action': 'close_no_plan',
            'state': {'shiftType': _shiftType, 'shiftActive': false}
          });
          await _finalizeAndSaveShift(_shiftType);
        }
        _shiftActive = false;
        _shiftPaused = false;
        _workingServerIds.clear();
        _currentCounts.clear();
        _currentStreaks.clear();
        _currentBonusXP.clear();
        _currentEarnedXP.clear();
        _currentPizookieCounts.clear();
        _lunchPeakCount.clear();
        _dinnerPeakCount.clear();
        _lunchCloserCount.clear();
        _dinnerCloserCount.clear();
        await _clearTransitionCheckpoint();
        d('[DEBUG] _maybeActivateShiftByClock: Restaurant closed, all state cleared');
        notifyListeners();
        _lastFlashMessages.clear();
        _lastActionXP.clear();
        _lastMilestoneDetails.clear();
        _currentStreaks.clear();
        resetRosterView();
        return;
      }

      // Within business hours but no plan: don't start/switch shifts automatically,
      // just leave current state as-is (gating via increment() will still require isOpenNow & working set)
      d('[WARNING] _maybeActivateShiftByClock: _todayPlan missing or date mismatch during business hours. Not starting/switching shifts.');
      return;
    }

    final lunchRoster = _todayPlan!.lunchRoster;
    final dinnerRoster = _todayPlan!.dinnerRoster;

    final wd = AppState.weekday(now);
    final m = now.hour * 60 + now.minute;

    // Compute both today's and yesterday's business intervals and choose the one that contains 'now'.
    // This prevents false "before open" clears for overnight/always-open setups where
    // the active interval might be yesterday's (for times after midnight but before the 4 AM anchor).
    final bDate = AppState.businessDate(now);
    final todayInterval = businessDayInterval(bDate, wd);
    final yesterdayBusinessDate = bDate.subtract(const Duration(days: 1));
    final yesterdayWeekday = yesterdayBusinessDate.weekday;
    final yesterdayInterval =
        businessDayInterval(yesterdayBusinessDate, yesterdayWeekday);

    bool inToday =
        !now.isBefore(todayInterval.start) && now.isBefore(todayInterval.end);
    bool inYesterday = !now.isBefore(yesterdayInterval.start) &&
        now.isBefore(yesterdayInterval.end);

    final currentInterval = inToday
        ? todayInterval
        : (inYesterday ? yesterdayInterval : todayInterval);

    final startDT = currentInterval.start;
    final endDT = currentInterval.end;
    final beforeOpen =
        !inToday && !inYesterday && now.isBefore(todayInterval.start);
    final atOrAfterClose = now.isAtSameMomentAs(endDT) || now.isAfter(endDT);

    // Use dynamic transitions instead of static dinnerSwitchMinutes
    final transitions = _calculateDynamicTransitions(now);
    final lunchEnd = transitions['lunchEnd']!;
    final dinnerStart = transitions['dinnerStart']!;

    // Resolve transition window: prefer explicit plan, then settings, else dynamic
    final int transitionStart =
        _todayPlan?.transitionStartMinutes ?? settings.transitionStartMinutes;
    final int transitionEnd =
        _todayPlan?.transitionEndMinutes ?? settings.transitionEndMinutes;
    d('[DEBUG] _maybeActivateShiftByClock: Plan details:');
    d('[DEBUG]   transitionStart=$transitionStart');
    d('[DEBUG]   transitionEnd=$transitionEnd');
    d('[DEBUG]   calculated lunchEnd=$lunchEnd, dinnerStart=$dinnerStart');
    d('[DEBUG]   lunchRoster=${_todayPlan?.lunchRoster}');
    d('[DEBUG]   dinnerRoster=${_todayPlan?.dinnerRoster}');

    // CRITICAL FIX: Proper transition and closing logic
    // Enforce pre-open: must be closed before businessInterval.start
    if (beforeOpen) {
      d('[DEBUG] _maybeActivateShiftByClock: Before open — enforcing closed state');
      if (_shiftActive) {
        d('[DEBUG] _maybeActivateShiftByClock: Finalizing lingering shift before open');
        await _setTransitionCheckpoint({
          'action': 'close_before_open',
          'state': {'shiftType': _shiftType, 'shiftActive': false}
        });
        await _finalizeAndSaveShift(_shiftType);
      }
      _shiftActive = false;
      _shiftPaused = false;
      _workingServerIds.clear();
      _currentCounts.clear();
      _currentStreaks.clear();
      _currentBonusXP.clear();
      _currentEarnedXP.clear();
      _currentPizookieCounts.clear();
      _lunchPeakCount.clear();
      _dinnerPeakCount.clear();
      _lunchCloserCount.clear();
      _dinnerCloserCount.clear();
      await _clearTransitionCheckpoint();
      d('[DEBUG] _maybeActivateShiftByClock: Before open, all state cleared');
      notifyListeners();
      _lastFlashMessages.clear();
      _lastActionXP.clear();
      _lastMilestoneDetails.clear();
      _currentStreaks.clear();
      resetRosterView();
      notifyListeners();
      return;
    }

    // Lunch should be active: businessInterval.start → transition end
    final open = _hours.openMinutes[wd]!;
    final shouldBeActiveLunch = !beforeOpen &&
        m < transitionEnd &&
        lunchRoster.isNotEmpty &&
        !_shiftPaused;
    // Dinner should be active: transition end → businessInterval.end
    final shouldBeActiveDinner = m >= transitionEnd &&
        !(atOrAfterClose) &&
        dinnerRoster.isNotEmpty &&
        !_shiftPaused;
        
    // Also trigger transition logic if we're exactly at transition time (not just after)
    final shouldTriggerTransition = (m >= transitionEnd || (m >= transitionEnd - 1 && m < transitionEnd + 5)) &&
        !(atOrAfterClose) &&
        dinnerRoster.isNotEmpty &&
        !_shiftPaused;
    // Restaurant should be closed: at or after businessInterval.end
    final shouldBeClosed = atOrAfterClose;

    d('[DEBUG] _maybeActivateShiftByClock: m=$m, open(min)=$open, businessStart=$startDT, businessEnd=$endDT, transitionEnd=$transitionEnd');
    d('[DEBUG] _maybeActivateShiftByClock: shiftType=$_shiftType, _shiftActive=$_shiftActive, manualOverride=$_manualShiftOverride, lastCheckpoint=$lastCheckpointAction at ${lastCheckpointTime?.toIso8601String()}');
    d('[DEBUG] _maybeActivateShiftByClock: shouldBeActiveLunch=$shouldBeActiveLunch, shouldBeActiveDinner=$shouldBeActiveDinner, shouldBeClosed=$shouldBeClosed');
    d('[DEBUG] _maybeActivateShiftByClock: _workingServerIds=$_workingServerIds');

    // CRITICAL FIX: Detect transition based on time, not intended shift type
    final isTransitionEnd = !_manualShiftOverride &&
        m >= transitionEnd &&
        _shiftType == 'Lunch' &&
        _shiftActive;
    final switchingToDinner = isTransitionEnd;

    // If we're already in Dinner but we have just crossed into/are in dinner window
    // and no transition checkpoint was recorded today, perform the transition logic
    // to preserve dinner-only counts and reset both-shift counts exactly once.
  // If device restarts or manual overrides skip the lunch→dinner boundary,
  // run the transition once post hoc so dinner-only is preserved and both-shift resets.
  final needsPosthocDinnerTransition = m >= transitionEnd &&
        _shiftType == 'Dinner' &&
        _shiftActive &&
        lastCheckpointAction != 'transition_to_dinner' &&
        _todayPlan?.ymd == ymd;
    if (needsPosthocDinnerTransition) {
      d('[DEBUG] _maybeActivateShiftByClock: Performing posthoc dinner transition (no checkpoint present)');
      final lunchSet = lunchRoster.toSet();
      final dinnerSet = dinnerRoster.toSet();
      final dinnerOnly = dinnerSet.difference(lunchSet);
      final bothShifts = dinnerSet.intersection(lunchSet);

      // Preserve dinner-only counts
      final dinnerOnlyCounts = <String, int>{};
      final dinnerOnlyPizookieCounts = <String, int>{};
      for (final id in dinnerOnly) {
        dinnerOnlyCounts[id] = _currentCounts[id] ?? 0;
        dinnerOnlyPizookieCounts[id] = _currentPizookieCounts[id] ?? 0;
        d('[DEBUG] _maybeActivateShiftByClock: Preserving dinner-only server $id: ${dinnerOnlyCounts[id]} counts');
      }

      // Transition checkpoint to prevent double-run across hot restarts.
      await _setTransitionCheckpoint({
        'action': 'transition_to_dinner',
        'preservedCounts': dinnerOnlyCounts,
        'preservedPizookieCounts': dinnerOnlyPizookieCounts,
        'state': {'shiftType': 'Dinner', 'shiftActive': true}
      });

      // Set UI state to dinner mode
      _activeRosterView = 'dinner';

      // Finalize lunch period workers if any counts exist
      final lunchOnlyWorkers = lunchSet.difference(dinnerSet);
      final lunchPeriodWorkers = [...lunchOnlyWorkers, ...bothShifts].toList();
      await _finalizeAndSaveShift('Lunch', lunchPeriodWorkers);

      // Reset working set to dinner roster but preserve dinner-only
      _beginShift('Dinner', dinnerRoster, preserveCounts: false);
      for (final id in dinnerOnly) {
        _currentCounts[id] = dinnerOnlyCounts[id]!;
        _currentPizookieCounts[id] = dinnerOnlyPizookieCounts[id]!;
        d('[DEBUG] _maybeActivateShiftByClock: Restored dinner-only server $id to ${_currentCounts[id]} counts');
      }
      for (final id in bothShifts) {
        _currentCounts[id] = 0;
        _currentPizookieCounts[id] = 0;
        d('[DEBUG] _maybeActivateShiftByClock: Reset both-shift server $id to 0 for dinner');
      }
      _manualShiftOverride = false;
      notifyListeners();
      return;
    }

    if (switchingToDinner) {
      // CRITICAL FIX: Transition end logic
      d('[DEBUG] _maybeActivateShiftByClock: Transition end detected - switching to dinner shift');

      // Save lunch counts and finalize lunch shift
      final lunchSet = lunchRoster.toSet();
      final dinnerSet = dinnerRoster.toSet();
      final dinnerOnly = dinnerSet.difference(lunchSet);
      final bothShifts = dinnerSet.intersection(lunchSet);

      // Save dinner-only server counts before switching shifts
      final dinnerOnlyCounts = <String, int>{};
      final dinnerOnlyPizookieCounts = <String, int>{};
      for (final id in dinnerOnly) {
        dinnerOnlyCounts[id] = _currentCounts[id] ?? 0;
        dinnerOnlyPizookieCounts[id] = _currentPizookieCounts[id] ?? 0;
        d('[DEBUG] _maybeActivateShiftByClock: Preserving dinner-only server $id: ${dinnerOnlyCounts[id]} counts');
      }

      // Transition checkpoint to prevent double-run across hot restarts.
      await _setTransitionCheckpoint({
        'action': 'transition_to_dinner',
        'preservedCounts': dinnerOnlyCounts,
        'preservedPizookieCounts': dinnerOnlyPizookieCounts,
        'state': {'shiftType': 'Dinner', 'shiftActive': true}
      });

      // Finalize lunch shift and save records - include lunch-only + both-shift workers
      final lunchOnlyWorkers = lunchSet.difference(dinnerSet);
      final lunchPeriodWorkers = [...lunchOnlyWorkers, ...bothShifts].toList();
      await _finalizeAndSaveShift('Lunch', lunchPeriodWorkers);

      // Start dinner shift normally (this clears all counts)
      _beginShift('Dinner', dinnerRoster, preserveCounts: false);

      // Restore dinner-only server counts
      for (final id in dinnerOnly) {
        _currentCounts[id] = dinnerOnlyCounts[id]!;
        _currentPizookieCounts[id] = dinnerOnlyPizookieCounts[id]!;
        d('[DEBUG] _maybeActivateShiftByClock: Restored dinner-only server $id to ${_currentCounts[id]} counts');
      }

      // Reset both-shift servers to 0 for fresh dinner start
      for (final id in bothShifts) {
        _currentCounts[id] = 0;
        _currentPizookieCounts[id] = 0;
        d('[DEBUG] _maybeActivateShiftByClock: Reset both-shift server $id to 0 for dinner');
      }

      _shiftActive = true;
      // After an automatic transition, manual override is no longer applicable
      _manualShiftOverride = false;
      notifyListeners();
      return;
    }

    // CRITICAL FIX: Restaurant closing logic
    if (shouldBeClosed) {
      d('[DEBUG] _maybeActivateShiftByClock: Restaurant closed - finalizing shift and clearing state');
      if (_shiftActive) {
        await _setTransitionCheckpoint({
          'action': 'close_restaurant',
          'state': {'shiftType': _shiftType, 'shiftActive': false}
        });
        await _finalizeAndSaveShift(_shiftType);
      }
      _shiftActive = false;
      _shiftPaused = false;
      _workingServerIds.clear();
      _currentCounts.clear();
      _currentBonusXP.clear();
      _currentEarnedXP.clear();
      _lastFlashMessages.clear();
      _lastActionXP.clear();
      _lastMilestoneDetails.clear();
      _currentStreaks.clear();
      _todayPlan = null;
      resetRosterView();
      notifyListeners();
      return;
    }

    // During transition, keep lunch shift active and do not reset
    if (shouldBeActiveLunch) {
      if (!_shiftActive || _shiftType != 'Lunch') {
        d('[DEBUG] _maybeActivateShiftByClock: Starting lunch shift with roster: $lunchRoster');
        await _setTransitionCheckpoint({
          'action': 'start_lunch',
          'state': {'shiftType': 'Lunch', 'shiftActive': true}
        });
        _beginShift('Lunch', lunchRoster);
        _shiftActive = true;
        // Starting a shift via clock clears manual override
        _manualShiftOverride = false;
        notifyListeners();
      } else {
        // CRITICAL FIX: During transition period, add dinner-only servers to working set
        // Use resolved transitionStart to respect plan/settings overrides
        if (m >= transitionStart && m < transitionEnd) {
          final lunchSet = lunchRoster.toSet();
          final dinnerSet = dinnerRoster.toSet();
          final dinnerOnly = dinnerSet.difference(lunchSet);

          // Add dinner-only servers to working set if not already present
          for (final id in dinnerOnly) {
            if (!_workingServerIds.contains(id)) {
              _workingServerIds.add(id);
              _currentCounts[id] ??= 0;
              _currentStreaks[id] ??= 0;
              _currentPizookieCounts[id] ??= 0;
              d('[DEBUG] _maybeActivateShiftByClock: Added dinner-only server $id to working set during transition');
            }
          }
        }

        d('[DEBUG] _maybeActivateShiftByClock: Lunch shift already active, workingServerIds: $_workingServerIds');
      }
      return;
    }
    print('DINNER TIMING: shouldBeActiveDinner=$shouldBeActiveDinner, shouldTriggerTransition=$shouldTriggerTransition, _manualShiftOverride=$_manualShiftOverride');
    print('TIMING DEBUG: m=$m, transitionEnd=$transitionEnd, atOrAfterClose=$atOrAfterClose, dinnerRoster.length=${dinnerRoster.length}');
    
    // FORCE clear manual override during automatic dinner transition time
    if (shouldTriggerTransition && _shiftActive && _shiftType == 'Lunch') {
      print('FORCE AUTO TRANSITION: Clearing manual override for automatic lunch->dinner transition');
      // Clear any existing checkpoint that might block the transition
      await _clearTransitionCheckpoint();
      _manualShiftOverride = false;
    }
    if (shouldTriggerTransition && !_manualShiftOverride) {
      print('DINNER CHECK: shouldTriggerTransition=true, _manualShiftOverride=$_manualShiftOverride');
      if (!_shiftActive || _shiftType != 'Dinner') {
        print('DINNER CHECK: _shiftActive=$_shiftActive, _shiftType=$_shiftType');
        // If we are switching from an active Lunch to Dinner because the time window passed
        // transitionEnd, run the full transition logic (preserve dinner-only, reset both-shift).
        if (_shiftActive && _shiftType == 'Lunch') {
          print('TRANSITION STARTING: Lunch to Dinner transition beginning now!');
          d('[DEBUG] _maybeActivateShiftByClock: Transition to dinner via shouldBeActiveDinner branch');
          final lunchSet = lunchRoster.toSet();
          final dinnerSet = dinnerRoster.toSet();
          final dinnerOnly = dinnerSet.difference(lunchSet);
          final bothShifts = dinnerSet.intersection(lunchSet);
          print('TRANSITION ROSTERS: Lunch=$lunchSet, Dinner=$dinnerSet, BothShifts=$bothShifts, DinnerOnly=$dinnerOnly');
          
          // Debug: Check which servers should be reset vs preserved
          print('SERVER ACTIONS: Reset both-shift servers: $bothShifts');
          print('SERVER ACTIONS: Preserve dinner-only servers: $dinnerOnly');

          // Preserve dinner-only counts
          final dinnerOnlyCounts = <String, int>{};
          final dinnerOnlyPizookieCounts = <String, int>{};
          for (final id in dinnerOnly) {
            dinnerOnlyCounts[id] = _currentCounts[id] ?? 0;
            dinnerOnlyPizookieCounts[id] = _currentPizookieCounts[id] ?? 0;
            d('[DEBUG] _maybeActivateShiftByClock: Preserving dinner-only server $id: ${dinnerOnlyCounts[id]} counts');
          }

          await _setTransitionCheckpoint({
            'action': 'transition_to_dinner',
            'preservedCounts': dinnerOnlyCounts,
            'preservedPizookieCounts': dinnerOnlyPizookieCounts,
            'state': {'shiftType': 'Dinner', 'shiftActive': true}
          });

          // Finalize lunch shift (save lunch-only + both-shift workers)
          final lunchOnlyWorkers = lunchSet.difference(dinnerSet);
          final lunchPeriodWorkers =
              [...lunchOnlyWorkers, ...bothShifts].toList();
          await _finalizeAndSaveShift('Lunch', lunchPeriodWorkers);

          // Reset both-shift servers BEFORE starting dinner
          d('[DEBUG] _maybeActivateShiftByClock: About to reset ${bothShifts.length} both-shift servers: $bothShifts');
          for (final id in bothShifts) {
            final oldCount = _currentCounts[id] ?? 0;
            _currentCounts[id] = 0;
            _currentPizookieCounts[id] = 0;
            d('[DEBUG] _maybeActivateShiftByClock: Reset both-shift server $id from $oldCount to 0 BEFORE dinner start');
            print('TRANSITION RESET: Server $id reset from $oldCount to 0 for dinner start');
          }

          // Start dinner fresh
          _beginShift('Dinner', dinnerRoster, preserveCounts: false);

          // Restore preserved dinner-only counts
          for (final id in dinnerOnly) {
            _currentCounts[id] = dinnerOnlyCounts[id]!;
            _currentPizookieCounts[id] = dinnerOnlyPizookieCounts[id]!;
            d('[DEBUG] _maybeActivateShiftByClock: Restored dinner-only server $id to ${_currentCounts[id]} counts');
          }

          _shiftActive = true;
          _manualShiftOverride = false;
          notifyListeners();
        } else {
          d('[DEBUG] _maybeActivateShiftByClock: Starting dinner shift, roster: $dinnerRoster');
          await _setTransitionCheckpoint({
            'action': 'start_dinner',
            'state': {'shiftType': 'Dinner', 'shiftActive': true}
          });
          _beginShift('Dinner', dinnerRoster, preserveCounts: false);
          _shiftActive = true;
          notifyListeners();
        }
      } else {
        d('[DEBUG] _maybeActivateShiftByClock: Dinner shift already active, workingServerIds: $_workingServerIds');
      }
      return;
    }
  }

  void _beginShift(String type, List<String> roster,
      {bool preserveCounts = false}) {
    d('[DEBUG] _beginShift: type=$type, roster=$roster, preserveCounts=$preserveCounts');
    _shiftActive = true;
    _shiftPaused = false;
    _shiftType = type;
    _shiftStart = _now;

    // CRITICAL FIX: Set activeRosterView to match the shift type
    _activeRosterView = type.toLowerCase();
    d('[DEBUG] _beginShift: Set _activeRosterView to $_activeRosterView');

    _workingServerIds
      ..clear()
      ..addAll(roster);

    d('[DEBUG] _beginShift: _workingServerIds updated to $_workingServerIds');

    if (preserveCounts) {
      // PRESERVE MODE: Don't clear any existing counts, only add missing servers with 0
      // This is critical for transition period - we must NOT remove dinner-only server counts
      for (final id in roster) {
        if (!_currentCounts.containsKey(id)) _currentCounts[id] = 0;
        if (!_currentStreaks.containsKey(id)) _currentStreaks[id] = 0;
        if (!_lunchPeakCount.containsKey(id)) _lunchPeakCount[id] = 0;
        if (!_dinnerPeakCount.containsKey(id)) _dinnerPeakCount[id] = 0;
        if (!_lunchCloserCount.containsKey(id)) _lunchCloserCount[id] = 0;
        if (!_dinnerCloserCount.containsKey(id)) _dinnerCloserCount[id] = 0;
        if (!_currentPizookieCounts.containsKey(id))
          _currentPizookieCounts[id] = 0;
      }

      // DO NOT remove any existing counts when preserving - this was the bug!
      // The manual restoration logic will handle preserving dinner-only counts
      d('[DEBUG] _beginShift: Preserved existing counts, no data removed');
    } else {
      // Normal shift start: clear and reset all per-shift data
      _currentCounts
        ..clear()
        ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
      _currentStreaks
        ..clear()
        ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
      _lunchPeakCount
        ..clear()
        ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
      _dinnerPeakCount
        ..clear()
        ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
      _lunchCloserCount
        ..clear()
        ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
      _dinnerCloserCount
        ..clear()
        ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
      _currentPizookieCounts
        ..clear()
        ..addEntries(_workingServerIds.map((id) => MapEntry(id, 0)));
    }
  }

  Future<void> _finalizeAndSaveShift(String type, [List<String>? roster]) async {
    // Filter counts to only include servers assigned to this shift
    final filteredCounts = <String, int>{};
    final pizookieCounts = <String, int>{};

    final keysToSave = roster != null
        ? roster.where((id) => _currentCounts.containsKey(id))
        : _currentCounts.keys;

    d('[SHIFT SAVE DEBUG] ================================');
    d('[SHIFT SAVE DEBUG] Finalizing shift: type=$type at ${_now}');
    d('[SHIFT SAVE DEBUG] Roster filter: ${roster ?? 'none (all servers)'}');
    d('[SHIFT SAVE DEBUG] Available _currentCounts: $_currentCounts');
    d('[SHIFT SAVE DEBUG] Keys to check for saving: ${keysToSave.toList()}');

    for (final id in keysToSave) {
      final count = _currentCounts[id] ?? 0;
      d('[SHIFT SAVE DEBUG] Server $id: count=$count');
      if (count > 0) {
        // Only save servers with actual runs
        filteredCounts[id] = count;
        pizookieCounts[id] = _currentPizookieCounts[id] ?? 0;
        d('[SHIFT SAVE DEBUG] Server $id SAVED to $type history with $count runs');
      } else {
        d('[SHIFT SAVE DEBUG] Server $id SKIPPED (count=$count)');
      }
    }

    d('[SHIFT SAVE DEBUG] Final saving counts: $filteredCounts');
    d('[SHIFT SAVE DEBUG] Final saving pizookieCounts: $pizookieCounts');

    // CRITICAL: Don't save empty shifts to history - they pollute the historical data
    if (filteredCounts.isEmpty) {
      d('[SHIFT SAVE DEBUG] ⚠️ SKIPPING SAVE: No servers with runs > 0, not saving empty shift');
      d('[SHIFT SAVE DEBUG] ================================');
      return;
    }

    // Capture current station assignments for correlation analysis
    final stationAssignments = <String, String>{};
    final sectionAssignments = <String, String>{};
    
    try {
      final stationTypes = await StationsRepository.getStationTypeForShift(type);
      final stationSections = await StationsRepository.getStationSectionForShift(type);
      
      // Only capture assignments for servers with runs
      for (final serverId in filteredCounts.keys) {
        if (stationTypes.containsKey(serverId)) {
          stationAssignments[serverId] = stationTypes[serverId]?.toString() ?? '';
        }
        if (stationSections.containsKey(serverId)) {
          sectionAssignments[serverId] = stationSections[serverId]?.toString() ?? '';
        }
      }
      
      d('[SHIFT SAVE DEBUG] Station assignments captured: $stationAssignments');
      d('[SHIFT SAVE DEBUG] Section assignments captured: $sectionAssignments');
    } catch (e) {
      d('[SHIFT SAVE DEBUG] Warning: Could not capture station assignments: $e');
    }

    d('[SHIFT SAVE DEBUG] ✅ SAVING SHIFT: ${filteredCounts.length} servers with data');
    d('[SHIFT SAVE DEBUG] Saving pizookieCounts: $pizookieCounts');
    final rec = ShiftRecord(
      id: _randId(),
      label: type,
      shiftType: type,
      start: _shiftStart ?? _now,
      counts: filteredCounts,
      pizookieCounts: pizookieCounts,
      stationAssignments: stationAssignments.isNotEmpty ? stationAssignments : null,
      sectionAssignments: sectionAssignments.isNotEmpty ? sectionAssignments : null,
    );
    _history.add(rec);
    d('[SHIFT SAVE DEBUG] ✅ Shift saved to history with ${filteredCounts.length} servers');
    d('[SHIFT SAVE DEBUG] ================================');

    String? mvpId;
    int mvpScore = -1;

    rec.counts.forEach((id, n) {
      _totals[id] = (_totals[id] ?? 0) + n;
      final prof = _profiles[id] ?? ServerProfile();
      if (n > prof.bestShiftRuns) prof.bestShiftRuns = n;

      // Use _totals[id] for all-time achievements
      final allTime = _totals[id] ?? 0;
      if (settings.gamificationEnabled) {
        if (allTime >= 50 && !prof.achievements.contains('fifty_all_time')) {
          prof.achievements.add('fifty_all_time');
          prof.points += _pointsFor('fifty_all_time');
        }
        if (allTime >= 100 && !prof.achievements.contains('hundred_all_time')) {
          prof.achievements.add('hundred_all_time');
          prof.points += _pointsFor('hundred_all_time');
        }
      }

      if (n > mvpScore) {
        mvpScore = n;
        mvpId = id;
      }
      _profiles[id] = prof;
    });

    if (settings.gamificationEnabled && mvpId != null) {
      final p = _profiles[mvpId]!;
      p.shiftsAsMvp += 1;
      if (!p.achievements.contains('mvp')) {
        p.achievements.add('mvp');
        p.points += _pointsFor('mvp');
      }
    }

    final teamTotal = rec.counts.values.fold<int>(0, (a, b) => a + b);
    if (settings.gamificationEnabled && teamTotal >= _teamGoal) {
      for (final id in rec.counts.keys) {
        final p = _profiles[id]!;
        if (!p.achievements.contains('team_goal')) {
          p.achievements.add('team_goal');
          p.points += _pointsFor('team_goal');
        }
      }
    }

    _persistHistory();
    _persistTotals();
    _persistProfiles();

    _currentCounts.clear();
    _currentBonusXP.clear();
    _currentEarnedXP.clear();
    _lastFlashMessages.clear();
    _lastActionXP.clear();
    _lastMilestoneDetails.clear();
    _currentStreaks.clear();
    _lunchPeakCount.clear();
    _dinnerPeakCount.clear();
    _lunchCloserCount.clear();
    _dinnerCloserCount.clear();
    _currentPizookieCounts.clear();
    _teamTotalThisShift = 0;
  }

  Future<bool> endCurrentShiftWithPin(String pin) async {
    if (!(await isValidAdminPin(pin))) return false;
    if (_shiftActive) {
      await _finalizeAndSaveShift(_shiftType);
      _shiftActive = false;
      _shiftPaused = false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> pauseCurrentShiftWithPin(String pin) async {
    if (!(await isValidAdminPin(pin))) return false;
    if (_shiftActive) {
      _shiftActive = false;
      _shiftPaused = true;
      notifyListeners();
    }
    return true;
  }

  Future<bool> resumePausedShiftWithPin(String pin) async {
    if (!(await isValidAdminPin(pin))) return false;
    if (_shiftPaused) {
      _shiftActive = true;
      _shiftPaused = false;
      notifyListeners();
    }
    return true;
  }

  Future<void> endDay() async {
    if (_shiftActive) {
      await _finalizeAndSaveShift(_shiftType);
      _shiftActive = false;
    }
    _shiftPaused = false;
    notifyListeners();
  }

  int _computeGoalFromHistory() {
    if (_history.isEmpty) return 100;
    final last = _history.take(5).toList();
    final avg = last
            .map((r) => r.counts.values.fold<int>(0, (a, b) => a + b))
            .fold<int>(0, (a, b) => a + b) /
        last.length;
    final g = (avg * 1.1).round();
    return (g / 10).round() * 10;
  }

  Future<void> addServer(String name) async {
    final s = Server(id: _randId(), name: name.trim());
    _servers.add(s);
    // Only add a new profile if it doesn't exist
    if (!_profiles.containsKey(s.id)) {
      _profiles[s.id] = ServerProfile();
    }
    // Only add a new total if it doesn't exist
    if (!_totals.containsKey(s.id)) {
      _totals[s.id] = 0;
    }
    await _persistServers();
    await _persistProfiles();
    await _persistTotals();
    notifyListeners();
  }

  Future<bool> renameServer(String id, String newName,
      {required String pin}) async {
    if (!(await isValidAdminPin(pin))) return false;
    final s = serverById(id);
    if (s == null) return false;
    s.name = newName.trim();
    await _persistServers();
    notifyListeners();
    return true;
  }

  Future<bool> removeServer(String id, {required String pin}) async {
    if (!(await isValidAdminPin(pin))) return false;
    _servers.removeWhere((s) => s.id == id);
    _totals.remove(id);
    _profiles.remove(id);
    _workingServerIds.remove(id);
    _currentCounts.remove(id);
    _currentStreaks.remove(id);
    for (final rec in _history) {
      rec.counts.remove(id);
    }
    await _persistServers();
    await _persistTotals();
    await _persistProfiles();
    await _persistHistory();
    notifyListeners();
    return true;
  }

  int _pointsFor(String id) {
    final a = achievementsCatalog.firstWhereOrNull((x) => x.id == id);
    return a?.points ?? 0;
  }

  void _awardOnce(ServerProfile p, String id, String serverName) {
    final def = achievementsCatalog.firstWhereOrNull((x) => x.id == id);
    if (def == null) return;
    if (!def.repeatable && p.achievements.contains(id)) return;

    if (def.repeatable) {
      final ymd = _ymd(_now);
      final key = '${id}_$ymd';
      if (p.repeatEarnedDates.contains(key)) return;
      p.repeatEarnedDates.add(key);
      final roundedPoints = _roundXP(def.points);
      p.points += roundedPoints;
      _recentBadgeBubble = '$serverName earned the ${def.title} badge!';

      // Store achievement details for notification display
      final serverId =
          _profiles.entries.firstWhere((entry) => entry.value == p).key;
      _lastMilestoneDetails[serverId] = {
        'type': 'traditional_achievement',
        'achievementId': id,
        'xpReward': roundedPoints,
        'title': def.title,
        'description': def.description,
        'message': '🏆 ${def.title.toUpperCase()}!\n${def.description}',
        'subMessage': '+$roundedPoints XP Achievement Bonus!',
        'priority': 'medium',
        'context': {'repeatable': def.repeatable},
        'timestamp': _now.toIso8601String(),
        'actionType': 'achievement',
      };
    } else {
      p.achievements.add(id);
      final roundedPoints = _roundXP(def.points);
      p.points += roundedPoints;
      _recentBadgeBubble = '$serverName earned the ${def.title} badge!';

      // Store achievement details for notification display
      final serverId =
          _profiles.entries.firstWhere((entry) => entry.value == p).key;
      _lastMilestoneDetails[serverId] = {
        'type': 'traditional_achievement',
        'achievementId': id,
        'xpReward': roundedPoints,
        'title': def.title,
        'description': def.description,
        'message': '🏆 ${def.title.toUpperCase()}!\n${def.description}',
        'subMessage': '+$roundedPoints XP Achievement Bonus!',
        'priority': 'medium',
        'context': {'repeatable': def.repeatable},
        'timestamp': _now.toIso8601String(),
        'actionType': 'achievement',
      };
    }
  }

  MilestoneAchievement? increment(String id) {
    final now = _now;
    final m = now.hour * 60 + now.minute;
    final plan = _todayPlan;
    d('[DEBUG] increment attempt: server=$id, shiftActive=$_shiftActive, workingIds=$_workingServerIds');
    d('[DEBUG] increment: currentTime=$m, shiftType=$_shiftType, transition=${plan?.transitionStartMinutes}-${plan?.transitionEndMinutes}');
    d('[DEBUG] increment: lunchRoster=${plan?.lunchRoster}, dinnerRoster=${plan?.dinnerRoster}');

    // Check if server is in both shifts (critical for tracking Server B)
    final lunchIds = plan?.lunchRoster ?? [];
    final dinnerIds = plan?.dinnerRoster ?? [];
    final inLunch = lunchIds.contains(id);
    final inDinner = dinnerIds.contains(id);
    d('[DEBUG] increment: server $id -> inLunch=$inLunch, inDinner=$inDinner, currentCounts=${_currentCounts[id] ?? 0}');

    // Defensive gating: must be open, shift active, and server working
    if (!isOpenNow || !_shiftActive || !_workingServerIds.contains(id)) {
      d('[DEBUG] increment BLOCKED: isOpenNow=$isOpenNow, shiftActive=$_shiftActive, serverInWorking=${_workingServerIds.contains(id)}');
      return null;
    }
    d('[DEBUG] increment SUCCESS: server $id proceeding');

    const delta = 1;

    // --- Full Hands! achievement logic (now 2 rapid taps) ---
    final tapList = _recentTapTimes.putIfAbsent(id, () => <DateTime>[]);
    tapList.add(now);
    if (tapList.length > 2) tapList.removeAt(0);
    bool awardedFullHands = false;
    final prof = _profiles[id] ?? ServerProfile();
    final serverName = serverById(id)?.name ?? 'Server';

    if (settings.gamificationEnabled) {
      if (tapList.length == 2) {
        final t0 = tapList[0];
        final t1 = tapList[1];
        if (t1.difference(t0).inMilliseconds <= 3000) {
          _awardOnce(prof, 'full_hands', serverName);
          _profiles[id] = prof;
          awardedFullHands = true;
        }
      }
    }

    _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
    lastRunServerId = id;
    _teamTotalThisShift += delta;

    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;

    // Always award base XP with boost multiplier applied
    checkBoostExpiry(); // Check if boost has expired
    final basePoints = 10;
    final rawBoostedPoints =
        (_boostActive ? (basePoints * _boostMultiplier).round() : basePoints);
    final boostedPoints = _roundXP(rawBoostedPoints);
    prof.points += boostedPoints;

    // Track actual XP earned this shift
    _currentEarnedXP[id] = (_currentEarnedXP[id] ?? 0) + boostedPoints;

    // Track XP from this specific action
    int actionXP = boostedPoints;

    d('[DEBUG] +$boostedPoints points awarded to $id (base: $basePoints, boost: ${_boostActive ? "${_boostMultiplier}x" : "none"}), total now: ${prof.points}');

    // Award additional XP for Full Hands achievement if applicable
    if (awardedFullHands && settings.gamificationEnabled) {
      prof.points +=
          25; // Additional 25 XP for Full Hands (35 total - 10 base = 25 extra)
      _currentEarnedXP[id] = (_currentEarnedXP[id] ?? 0) + 25;
      actionXP += 25; // Add to this action's total
      d('[DEBUG] +25 additional XP for Full Hands achievement, total now: ${prof.points}');
    }
    prof.allTimeRuns += delta;
    d('[DEBUG] Server $id now has ${prof.points} XP, level ${prof.level}, allTimeRuns: ${prof.allTimeRuns}');

    final prevIso = prof.lastTapIso;
    prof.lastTapIso = now.toIso8601String();
    if (prevIso != null) {
      final prev = DateTime.tryParse(prevIso);
      if (prev != null) {
        final ms = now.difference(prev).inMilliseconds;
        if (ms > 0 && ms < 20 * 60 * 1000) {
          prof.tapIntervalsMsSum += ms;
          prof.tapIntervalsCount += 1;
        }
      }
    }

    if (settings.gamificationEnabled) {
      if (_currentStreaks[id]! > prof.streakBest) {
        prof.streakBest = _currentStreaks[id]!;
      }
      if (prof.streakBest >= 3) _awardOnce(prof, 'three_streak', serverName);
      if (prof.streakBest >= 5) _awardOnce(prof, 'five_streak', serverName);

      if (sCount >= 10) _awardOnce(prof, 'ten_in_shift', serverName);
      if (sCount >= 20) _awardOnce(prof, 'twenty_in_shift', serverName);
      if (now.hour >= 23) _awardOnce(prof, 'night_owl', serverName);

      _awardOnce(prof, 'first_run_today', serverName);
      if (prof.allTimeRuns == 0 &&
          !_profiles.containsKey('first_run_${id}_awarded')) {
        _awardOnce(prof, 'first_run', serverName);
      }
    }

    if (isLunchPeak(now)) {
      _lunchPeakCount[id] = (_lunchPeakCount[id] ?? 0) + delta;
      if (_lunchPeakCount[id]! >= 10)
        _awardOnce(prof, 'lunch_peak_10', serverName);
    }
    if (isDinnerPeak(now)) {
      _dinnerPeakCount[id] = (_dinnerPeakCount[id] ?? 0) + delta;
      if (_dinnerPeakCount[id]! >= 10)
        _awardOnce(prof, 'dinner_peak_10', serverName);
    }
    if (isLunchCloser(now)) {
      _lunchCloserCount[id] = (_lunchCloserCount[id] ?? 0) + delta;
      if (_lunchCloserCount[id]! >= 8)
        _awardOnce(prof, 'lunch_closer_8', serverName);
    }
    if (isDinnerCloser(now)) {
      _dinnerCloserCount[id] = (_dinnerCloserCount[id] ?? 0) + delta;
      if (_dinnerCloserCount[id]! >= 8)
        _awardOnce(prof, 'dinner_closer_8', serverName);
    }

    _profiles[id] = prof;

    final minuteEpoch =
        DateTime(now.year, now.month, now.day, now.hour, now.minute)
            .millisecondsSinceEpoch;
    _tapPerMinute.putIfAbsent(id, () => <int, int>{});
    _tapPerMinute[id]![minuteEpoch] =
        (_tapPerMinute[id]![minuteEpoch] ?? 0) + 1;
    _tapTimestamps
        .putIfAbsent(id, () => <int>[])
        .add(now.millisecondsSinceEpoch);
    _persistTapLog();
    _persistTapTimestamps();
    _persistProfiles();
    _persistTotals();

    // Check for milestone achievements and award XP
    final milestone = MilestoneDetectionService.checkForMilestones(id, this,
        isPizookie: false);
    if (milestone != null) {
      // Award the milestone XP to the profile
      final updatedProf = _profiles[id] ?? ServerProfile();
      final roundedMilestoneXP = _roundXP(milestone.xpReward);
      updatedProf.points += roundedMilestoneXP;

      // Add milestone bonus XP to current shift tracking
      _currentBonusXP[id] = (_currentBonusXP[id] ?? 0) + roundedMilestoneXP;
      _currentEarnedXP[id] = (_currentEarnedXP[id] ?? 0) + roundedMilestoneXP;

      // Add milestone XP to this action's total
      actionXP += roundedMilestoneXP;

      // Store milestone details for notification display
      _lastMilestoneDetails[id] = {
        'type': milestone.type.name,
        'xpReward': roundedMilestoneXP,
        'message': milestone.message,
        'subMessage': milestone.subMessage,
        'priority': milestone.priority.name,
        'context': milestone.context,
        'timestamp': _now.toIso8601String(),
        'actionType': 'regular',
      };

      // Add milestone to history
      updatedProf.milestoneHistory.add({
        'type': milestone.type.name,
        'xpReward': roundedMilestoneXP,
        'timestamp': _now.toIso8601String(),
        'message': milestone.message,
      });

      _profiles[id] = updatedProf;
      _persistProfiles(); // Persist immediately

      d('[DEBUG] Milestone earned by $id: ${milestone.type.name} (+$roundedMilestoneXP XP)');
      d('[DEBUG] Current shift bonus XP for $id: ${_currentBonusXP[id]}');
    }

    // Store the total XP gained from this specific action
    _lastActionXP[id] = actionXP;

    notifyListeners();
    return milestone;
  }

  void decrement(String id) {
    if (!_shiftActive || !_workingServerIds.contains(id)) return;
    final current = (_currentCounts[id] ?? 0);
    if (current > 0) {
      _currentCounts[id] = current - 1;
      _teamTotalThisShift = (_teamTotalThisShift - 1).clamp(0, 1 << 31);
    }
    _currentStreaks[id] = 0;
    notifyListeners();
  }

  Map<String, int> integrityBinsFor(String serverId, {bool todayOnly = false}) {
    final buckets = _tapPerMinute[serverId];
    if (buckets == null) return {'1': 0, '2': 0, '3': 0, '4+': 0};
    final now = _now;
    final ymd = _ymd(now);
    int s1 = 0, s2 = 0, s3 = 0, s4 = 0;
    buckets.forEach((minuteEpoch, count) {
      if (todayOnly) {
        final d = DateTime.fromMillisecondsSinceEpoch(minuteEpoch);
        if (_ymd(d) != ymd) return;
      }
      if (count <= 0) return;
      if (count == 1) {
        s1++;
      } else if (count == 2)
        s2++;
      else if (count == 3)
        s3++;
      else
        s4++;
    });
    return {'1': s1, '2': s2, '3': s3, '4+': s4};
  }

  Map<String, int> integrityBinsForDateRange(
    String serverId, {
    DateTime? startDate,
    DateTime? endDate,
    bool todayOnly = false,
  }) {
    final buckets = _tapPerMinute[serverId];
    if (buckets == null) return {'1': 0, '2': 0, '3': 0, '4+': 0};

    final now = _now;
    final ymd = _ymd(now);

    // Default date ranges based on common selections
    DateTime filterStartDate;
    DateTime filterEndDate = now;

    if (todayOnly) {
      filterStartDate = DateTime(now.year, now.month, now.day);
      filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (startDate != null && endDate != null) {
      filterStartDate = startDate;
      filterEndDate =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    } else {
      // Default to last 30 days if no specific range provided
      filterStartDate = now.subtract(const Duration(days: 30));
    }

    // Debug logging for custom range
    if (serverId == '4f55jaewuhldbaoi' &&
        startDate != null &&
        endDate != null) {
      d('DEBUG integrityBinsForDateRange for server $serverId:');
      d('  Filter start: $filterStartDate');
      d('  Filter end: $filterEndDate');
      d('  Total tap buckets: ${buckets.length}');
    }

    // Properly categorize minutes by click patterns (like integrityBinsFor but with date filtering)
    int s1 = 0, s2 = 0, s3 = 0, s4 = 0;
    int totalRuns = 0;
    int processedCount = 0;

    buckets.forEach((minuteEpoch, count) {
      final dt = DateTime.fromMillisecondsSinceEpoch(minuteEpoch);

      // Debug first few entries for server '4f55jaewuhldbaoi'
      if (serverId == '4f55jaewuhldbaoi' &&
          startDate != null &&
          endDate != null &&
          processedCount < 3) {
        d('  Bucket $processedCount: date=$dt, count=$count, inRange=${!dt.isBefore(filterStartDate) && !dt.isAfter(filterEndDate)}');
        processedCount++;
      }

      // Check if date falls within our filter range
      if (dt.isBefore(filterStartDate) || dt.isAfter(filterEndDate)) {
        return;
      }

      if (todayOnly && _ymd(dt) != ymd) {
        return;
      }

      // Categorize by click patterns (same logic as integrityBinsFor)
      if (count <= 0) return;
      totalRuns += count;

      if (count == 1) {
        s1++;
      } else if (count == 2)
        s2++;
      else if (count == 3)
        s3++;
      else
        s4++;
    });

    if (serverId == '4f55jaewuhldbaoi' &&
        startDate != null &&
        endDate != null) {
      d('  Total runs in range: $totalRuns');
      d('  Click pattern distribution: 1-click=$s1, 2-click=$s2, 3-click=$s3, 4+-click=$s4');
    }

    return {'1': s1, '2': s2, '3': s3, '4+': s4};
  }

  /// Get raw tap data for a server within a specific time range
  /// Returns a map of minute epochs to tap counts for that time window
  Map<int, int> rawTapDataForTimeRange(
    String serverId, {
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final buckets = _tapPerMinute[serverId];
    if (buckets == null) return {};

    final startEpoch = startTime.millisecondsSinceEpoch;
    final endEpoch = endTime.millisecondsSinceEpoch;

    final result = <int, int>{};

    buckets.forEach((minuteEpoch, count) {
      if (minuteEpoch >= startEpoch && minuteEpoch < endEpoch) {
        result[minuteEpoch] = count;
      }
    });

    return result;
  }

  /// Get total tap count for a server within a specific time window
  int getTapCountForTimeWindow(String serverId, DateTime start, DateTime end) {
    final tapData =
        rawTapDataForTimeRange(serverId, startTime: start, endTime: end);
    return tapData.values.fold(0, (sum, count) => sum + count);
  }

  /// Get raw tap data (DateTime -> count) for a server within a specific time window
  Map<DateTime, int> getRawTapDataForTimeRange(
      String serverId, DateTime start, DateTime end) {
    final rawData =
        rawTapDataForTimeRange(serverId, startTime: start, endTime: end);
    final Map<DateTime, int> result = {};

    for (final entry in rawData.entries) {
      final timestamp = entry.key;
      final count = entry.value;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      result[dateTime] = count;
    }

    return result;
  }

  /// Get individual click timestamps for a server within a time range
  List<DateTime> getIndividualClickTimestamps(
      String serverId, DateTime start, DateTime end) {
    final timestamps = _tapTimestamps[serverId] ?? [];
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    return timestamps
        .where((timestamp) => timestamp >= startEpoch && timestamp < endEpoch)
        .map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp))
        .toList()
      ..sort(); // Sort chronologically
  }

  /// Get count of individual clicks for a time range (for verification)
  int getIndividualClickCount(String serverId, DateTime start, DateTime end) {
    return getIndividualClickTimestamps(serverId, start, end).length;
  }

  /// Get individual pizookie click timestamps for a server within a time range
  List<DateTime> getIndividualPizookieTimestamps(
      String serverId, DateTime start, DateTime end) {
    final timestamps = _pizookieTimestamps[serverId] ?? [];
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    return timestamps
        .where((timestamp) => timestamp >= startEpoch && timestamp < endEpoch)
        .map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp))
        .toList()
      ..sort(); // Sort chronologically
  }

  /// Get all clicks with type information for click analysis
  List<Map<String, dynamic>> getIndividualClicksWithType(
      String serverId, DateTime start, DateTime end) {
    final regularClicks = getIndividualClickTimestamps(serverId, start, end);
    final pizookieClicks = getIndividualPizookieTimestamps(serverId, start, end);
    
    final allClicksWithType = <Map<String, dynamic>>[];
    
    // Add regular clicks
    for (final click in regularClicks) {
      final isPizookie = pizookieClicks.any((pizookie) => 
          pizookie.millisecondsSinceEpoch == click.millisecondsSinceEpoch);
      allClicksWithType.add({
        'timestamp': click,
        'isPizookie': isPizookie,
      });
    }
    
    // Sort by timestamp
    allClicksWithType.sort((a, b) => 
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
    
    return allClicksWithType;
  }

  void _pruneOldTapBuckets() {
    final cutoff =
        _now.subtract(const Duration(days: 180)).millisecondsSinceEpoch;
    for (final m in _tapPerMinute.values) {
      m.removeWhere((k, v) => k < cutoff);
    }
    // Also prune old individual timestamps
    for (final timestamps in _tapTimestamps.values) {
      timestamps.removeWhere((timestamp) => timestamp < cutoff);
    }
    // Also prune old pizookie timestamps
    for (final timestamps in _pizookieTimestamps.values) {
      timestamps.removeWhere((timestamp) => timestamp < cutoff);
    }
  }

  List<ShiftRecord> shiftsOnDate(DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);
    return history.where((h) {
      final hd = DateTime(h.start.year, h.start.month, h.start.day);
      return hd == d0;
    }).toList();
  }

  void updateBothRosters(
      {required List<String> lunch, required List<String> dinner}) {
    setTodayPlan(lunch, dinner);
    final now = _now;
    final currentShift = shiftType;

    if (currentShift == 'Lunch') {
      updateActiveRoster(lunch, preserveExistingCounts: true);
    } else {
      updateActiveRoster(dinner, preserveExistingCounts: true);
    }
  }

  void updateActiveRoster(List<String> newRoster,
      {bool preserveExistingCounts = false}) {
    final newSetOriginal = Set<String>.from(newRoster);

    // Time/plan-based gating: restrict which servers may be active right now
    // - Before transitionStart: only lunch roster allowed
    // - Between transitionStart..transitionEnd: allow lunch ∪ dinner
    // - After transitionEnd: only dinner roster allowed
    // If no plan or shift not active, don't gate.
    Set<String> _applyRosterGating(Set<String> requested) {
      final plan = _todayPlan;
      if (plan == null || !_shiftActive) return requested;

      final now = _now;
      final m = now.hour * 60 + now.minute;
      // Prefer explicit plan times, then settings
      final ts = plan.transitionStartMinutes;
      final te = plan.transitionEndMinutes;

      // Derive canonical sets
      final lunch = Set<String>.from(plan.lunchRoster);
      final dinner = Set<String>.from(plan.dinnerRoster);
      final union = lunch.union(dinner);

      Set<String> allowed;
      if (_manualShiftOverride && _shiftType == 'Lunch' && m < te) {
        // During manual Lunch (explicitly started), allow union up until transitionEnd
        allowed = union;
      } else if (m < ts) {
        // Strict lunch only before transition window
        allowed = lunch;
      } else if (m >= ts && m < te) {
        // During transition window, allow both
        allowed = union;
      } else {
        // After transitionEnd: dinner only
        allowed = dinner;
      }

      return requested.intersection(allowed);
    }

    final newSet = _applyRosterGating(newSetOriginal);

    if (preserveExistingCounts) {
      // COMPLETE FIX: When preserving counts during active shifts,
      // sync working set to match new roster while keeping all existing data
      _workingServerIds.clear();
      _workingServerIds.addAll(newSet);

      // Ensure all new servers have initialized counts (without overwriting existing)
      for (final id in newSet) {
        _currentCounts.putIfAbsent(id, () => 0);
        _currentStreaks.putIfAbsent(id, () => 0);
        _lunchPeakCount.putIfAbsent(id, () => 0);
        _dinnerPeakCount.putIfAbsent(id, () => 0);
        _lunchCloserCount.putIfAbsent(id, () => 0);
        _dinnerCloserCount.putIfAbsent(id, () => 0);
      }
    } else {
      // Original logic: Remove departed servers and clean up their data
      for (final id in _workingServerIds.toList()) {
        if (!newSet.contains(id)) {
          _currentCounts.remove(id);
          _currentStreaks.remove(id);
          _lunchPeakCount.remove(id);
          _dinnerPeakCount.remove(id);
          _lunchCloserCount.remove(id);
          _dinnerCloserCount.remove(id);
          _workingServerIds.remove(id);
        }
      }

      // Add new servers with fresh data
      for (final id in newSet) {
        if (!_workingServerIds.contains(id)) {
          _workingServerIds.add(id);
          _currentCounts[id] = 0;
          _currentStreaks[id] = 0;
          _lunchPeakCount[id] = 0;
          _dinnerPeakCount[id] = 0;
          _lunchCloserCount[id] = 0;
          _dinnerCloserCount[id] = 0;
        }
      }
    }
    notifyListeners();
  }

  void deleteShift(ShiftRecord shift) {
    _history.removeWhere((s) => s.id == shift.id);
    _persistHistory();
    notifyListeners();
  }

  Future<bool> deleteShiftWithPin(ShiftRecord shift, String pin) async {
    if (!(await isValidAdminPin(pin))) return false;
    _history.removeWhere((s) => s.id == shift.id);
    await _persistHistory();
    notifyListeners();
    return true;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static int weekday(DateTime d) => d.weekday;

  /// Business Day Model: Returns the business date for a given DateTime
  /// If time < 4:00 AM, you're still in yesterday's business day
  static DateTime businessDate(DateTime dateTime) {
    return (dateTime.hour < 4)
        ? DateTime(dateTime.year, dateTime.month, dateTime.day - 1)
        : DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Returns the start and end DateTime for a business day's operating hours
  DateTimeRange businessDayInterval(DateTime businessDate, int weekday) {
    final openMinutes = _hours.openMinutes[weekday] ?? 11 * 60;
    final closeMinutes = _hours.closeMinutes[weekday] ?? 23 * 60;
    final closeDayOffset = _hours.closeDayOffset[weekday] ?? 0;

    d('DEBUG businessDayInterval: openMinutes=$openMinutes, closeMinutes=$closeMinutes, closeDayOffset=$closeDayOffset');

    // Business day starts at opening time on the business date.
    // NOTE: If the configured open time is before the 4:00 anchor (early morning),
    // then that opening actually occurs on the next calendar day relative to
    // the businessDate (because businessDate shifts to the previous day for
    // clock times < 4:00). Adjust the start date accordingly.
    final startDate = (openMinutes < 4 * 60)
        ? businessDate.add(const Duration(days: 1))
        : businessDate;

    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      openMinutes ~/ 60, // hours
      openMinutes % 60, // minutes
    );

    // Calculate end time based on closeDayOffset and whether close extends overnight
    late final DateTime end;

    // Handle different closing scenarios
    if (closeDayOffset == 0) {
      // Same day operation: but we need to check if close time is actually before open time
      // If closeMinutes < openMinutes, it means we close the next day despite closeDayOffset=0
      if (closeMinutes < openMinutes) {
        // Close time is next day despite closeDayOffset=0 (e.g., open at 23:00, close at 01:00)
        end = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + 1,
          closeMinutes ~/ 60, // hours
          closeMinutes % 60, // minutes
        );
      } else {
        // Normal same day operation - use startDate, not businessDate
        end = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          closeMinutes ~/ 60, // hours
          closeMinutes % 60, // minutes
        );
      }
    } else {
      // Multi-day operation: closeMinutes represents total operation time from start
      // For overnight operations, calculate the actual close time correctly
      if (closeMinutes > 1440) {
        // closeMinutes > 1440 means operation extends past midnight
        // Calculate end time by adding the full duration from start
        final operationDurationMinutes = closeMinutes - openMinutes;
        end = start.add(Duration(minutes: operationDurationMinutes));
        d('DEBUG businessDayInterval: Overnight operation - duration=${operationDurationMinutes} minutes, end=$end');
      } else {
        // Normal overnight operation within 24 hours
        final operationDurationMinutes = closeMinutes - openMinutes;
        end = start.add(Duration(minutes: operationDurationMinutes));
      }
    }

    d('DEBUG businessDayInterval: Final interval start=$start, end=$end');
    return DateTimeRange(start: start, end: end);
  }

  // --- Add these methods to fix your missing method errors ---
  bool isLunchPeak(DateTime now) {
    final m = now.hour * 60 + now.minute;
    // Example: Lunch peak is 11:30am–1:30pm
    return m >= 11 * 60 + 30 && m < 13 * 60 + 30;
  }

  bool isDinnerPeak(DateTime now) {
    final m = now.hour * 60 + now.minute;
    // Example: Dinner peak is 5:30pm–7:30pm
    return m >= 17 * 60 + 30 && m < 19 * 60 + 30;
  }

  bool isLunchCloser(DateTime now) {
    final m = now.hour * 60 + now.minute;
    // Example: Lunch closer is 2:00pm–3:30pm
    return m >= 14 * 60 && m < 15 * 60 + 30;
  }

  bool isDinnerCloser(DateTime now) {
    final m = now.hour * 60 + now.minute;
    // Example: Dinner closer is 9:00pm–11:00pm
    return m >= 21 * 60 && m < 23 * 60;
  }

  /// Reconstructs allTimeRuns from historical tap data
  void reconstructAllTimeRuns() {
    d('[DEBUG] Starting allTimeRuns reconstruction from tap data...');
    d('[DEBUG] _tapPerMinute has ${_tapPerMinute.length} servers');

    for (final serverId in _tapPerMinute.keys) {
      final tapData = _tapPerMinute[serverId];
      if (tapData == null) continue;

      // Sum all taps for this server across all time periods
      final totalTaps =
          tapData.values.fold<int>(0, (sum, count) => sum + count);
      d('[DEBUG] Server $serverId has ${tapData.length} time periods, $totalTaps total taps');

      // Get or create profile
      final profile = _profiles[serverId] ?? ServerProfile();

      // Update profile.allTimeRuns if needed
      if (profile.allTimeRuns < totalTaps) {
        final oldValue = profile.allTimeRuns;
        profile.allTimeRuns = totalTaps;
        _profiles[serverId] = profile;

        d('[DEBUG] Reconstructed profile $serverId: allTimeRuns $oldValue → $totalTaps');
      } else {
        d('[DEBUG] Server $serverId: profile.allTimeRuns=${profile.allTimeRuns} already >= taps=$totalTaps, no change needed');
      }

      // ALSO update _totals which is used by MVP screen
      final currentTotals = _totals[serverId] ?? 0;
      if (currentTotals < totalTaps) {
        final oldTotals = currentTotals;
        _totals[serverId] = totalTaps;
        d('[DEBUG] Reconstructed totals $serverId: _totals $oldTotals → $totalTaps');
      } else {
        d('[DEBUG] Server $serverId: _totals=$currentTotals already >= taps=$totalTaps, no change needed');
      }
    }

    // Save the reconstructed data
    _persistProfiles();
    _persistTotals();
    notifyListeners();
    d('[DEBUG] allTimeRuns reconstruction complete!');
  }

  void updateAvatar(String serverId, String avatarPath) {
    d('AppState.updateAvatar called for $serverId with $avatarPath');
    final profile = _profiles[serverId];
    if (profile != null) {
      profile.avatarPath = avatarPath;
      final now = _now;
      final entry = {
        'path': avatarPath,
        'timestamp': now.toIso8601String(),
      };
      profile.avatarHistory = [...profile.avatarHistory, entry];
      // Force Provider to notify listeners by assigning a new map
      _profiles = Map<String, ServerProfile>.from(_profiles);
      notifyListeners();
      _persistProfiles();
    }
  }

  void updateBanner(String serverId, String bannerPath) {
    d('AppState.updateBanner called for $serverId with $bannerPath');
    final profile = _profiles[serverId];
    if (profile != null) {
      profile.bannerPath = bannerPath;
      // Force Provider to notify listeners by assigning a new map
      _profiles = Map<String, ServerProfile>.from(_profiles);
      notifyListeners();
      _persistProfiles();
    }
  }

  // Wallpaper system
  String _selectedWallpaper = 'none';
  bool _autoRotateWallpaper = false;

  String get selectedWallpaper => _selectedWallpaper;
  bool get autoRotateWallpaper => _autoRotateWallpaper;

  void setWallpaper(String wallpaperId) {
    _selectedWallpaper = wallpaperId;
    notifyListeners();
    Storage.settingsBox.put('selectedWallpaper', wallpaperId);
  }

  void setAutoRotateWallpaper(bool enabled) {
    _autoRotateWallpaper = enabled;
    notifyListeners();
    Storage.settingsBox.put('autoRotateWallpaper', enabled);
  }

  /// Returns backup information for fresh installs
  Future<Map<String, dynamic>> getExistingBackupInfo() async {
    // This is a stub implementation for the backup check functionality
    // Returns false to indicate no existing backups found
    return {
      'hasBackups': false,
      'count': 0,
    };
  }

  /// Public method to manually trigger allTimeRuns reconstruction for testing
  void manuallyReconstructAllTimeRuns() {
    reconstructAllTimeRuns();
  }
}
