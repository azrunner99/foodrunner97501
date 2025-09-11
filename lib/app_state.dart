/// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'models.dart';
import 'storage.dart';
import 'gamification.dart';

String _randId() {
  final r = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
}

class ServerProfile {
  double get avgSecondsBetweenRuns =>
      tapIntervalsCount == 0 ? 0 : tapIntervalsMsSum / tapIntervalsCount / 1000.0;
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
  })  : achievements = achievements ?? [],
        repeatEarnedDates = repeatEarnedDates ?? [];

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
    );
  }

  static ServerProfile fromMap(Map m) => ServerProfile(
    allTimeRuns: (m['allTimeRuns'] ?? 0) as int,
    pizookieRuns: (m['pizookieRuns'] ?? 0) as int,
    bestShiftRuns: (m['bestShiftRuns'] ?? 0) as int,
    streakBest: (m['streakBest'] ?? 0) as int,
    shiftsAsMvp: (m['shiftsAsMvp'] ?? 0) as int,
    achievements: (m['achievements'] as List?)?.cast<String>() ?? <String>[],
    repeatEarnedDates: (m['repeatEarnedDates'] as List?)?.cast<String>() ?? <String>[],
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
        return Map<String, dynamic>.from(e.map((key, value) => MapEntry(key.toString(), value)));
      } else {
        return <String, dynamic>{};
      }
    }).toList() ?? <Map<String, dynamic>>[],
    hireDate: (m['hireDate'] ?? '') as String,
    birthday: (m['birthday'] ?? '') as String,
    isArchived: (m['isArchived'] ?? false) as bool,
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
  };
}
class AppState extends ChangeNotifier {
  String? _lastRunServerId;
  String? get lastRunServerId => _lastRunServerId;
  set lastRunServerId(String? id) {
    _lastRunServerId = id;
    notifyListeners();
  }
  Map<String, int> get currentPizookieCounts => Map.unmodifiable(_currentPizookieCounts);
  /// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
  /// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
  // Tracks per-shift pizookie runs for each server
  final Map<String, int> _currentPizookieCounts = {};
  String? incrementPizookie(String id) {
    if (!_shiftActive || !_workingServerIds.contains(id)) return null;

    final now = DateTime.now();
    const delta = 1;
    const pizookiePoints = 25;

  _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
  lastRunServerId = id;
    _teamTotalThisShift += delta;

    // Increment per-shift pizookie count
    _currentPizookieCounts[id] = (_currentPizookieCounts[id] ?? 0) + delta;

    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;
    final prof = _profiles[id] ?? ServerProfile();
    final serverName = serverById(id)?.name ?? 'Server';


    prof.points += pizookiePoints;
    prof.allTimeRuns += delta;
    prof.pizookieRuns += delta;
    print('[DEBUG] Server $id ran a Pizookie: \\${prof.points} XP, level \\${prof.level}, allTimeRuns: \\${prof.allTimeRuns}, pizookieRuns: \\${prof.pizookieRuns}');

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
      if (prof.allTimeRuns == 0 && !_profiles.containsKey('first_run_\\${id}_awarded')) {
        _awardOnce(prof, 'first_run', serverName);
      }

      if (isLunchPeak(now)) {
        _lunchPeakCount[id] = (_lunchPeakCount[id] ?? 0) + delta;
        if (_lunchPeakCount[id]! >= 10) _awardOnce(prof, 'lunch_peak_10', serverName);
      }
      if (isDinnerPeak(now)) {
        _dinnerPeakCount[id] = (_dinnerPeakCount[id] ?? 0) + delta;
        if (_dinnerPeakCount[id]! >= 10) _awardOnce(prof, 'dinner_peak_10', serverName);
      }
      if (isLunchCloser(now)) {
        _lunchCloserCount[id] = (_lunchCloserCount[id] ?? 0) + delta;
        if (_lunchCloserCount[id]! >= 8) _awardOnce(prof, 'lunch_closer_8', serverName);
      }
      if (isDinnerCloser(now)) {
        _dinnerCloserCount[id] = (_dinnerCloserCount[id] ?? 0) + delta;
        if (_dinnerCloserCount[id]! >= 8) _awardOnce(prof, 'dinner_closer_8', serverName);
      }
    }

    _profiles[id] = prof;

    final minuteEpoch = DateTime(now.year, now.month, now.day, now.hour, now.minute).millisecondsSinceEpoch;
    _tapPerMinute.putIfAbsent(id, () => <int, int>{});
    _tapPerMinute[id]![minuteEpoch] = (_tapPerMinute[id]![minuteEpoch] ?? 0) + 1;
    _persistTapLog();
    _persistProfiles();
    _persistTotals();

    notifyListeners();
    return null;
  }
  // For Full Hands! achievement: not persisted, just for session
  final Map<String, List<DateTime>> _recentTapTimes = {};
  static const adminPin = '5520';
  static const dinnerSwitchMinutes = 15 * 60 + 30; // 3:30 PM
  static const dinnerFullSwitchMinutes = 16 * 60; // 4:00 PM

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
  final Set<String> _workingServerIds = {};
  int _teamGoal = 0;
  int _teamTotalThisShift = 0;

  final Map<String, int> _lunchPeakCount = {};
  final Map<String, int> _dinnerPeakCount = {};
  final Map<String, int> _lunchCloserCount = {};
  final Map<String, int> _dinnerCloserCount = {};

  final Map<String, Map<int, int>> _tapPerMinute = {};
  String? _recentBadgeBubble;
  Timer? _ticker;

  // Roster toggle state: 'auto', 'lunch', 'dinner'
  String _activeRosterView = 'auto';

  // expose
  List<Server> get servers =>
      List.unmodifiable(_servers.sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
  Map<String, int> get totals => Map.unmodifiable(_totals);
  Map<String, ServerProfile> get profiles => Map.unmodifiable(_profiles);
  WeeklyHours get hours => _hours;

  bool get shiftActive => _shiftActive;
  bool get shiftPaused => _shiftPaused;
  String get shiftType => _shiftType;
  DateTime? get shiftStart => _shiftStart;
  Map<String, int> get currentCounts => Map.unmodifiable(_currentCounts);
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
  void toggleRosterView() {
    print('[DEBUG] toggleRosterView: Current view = $_activeRosterView');
    final plan = _todayPlan;
    if (_activeRosterView == 'lunch') {
      _activeRosterView = 'dinner';
      print('[DEBUG] toggleRosterView: Switching to dinner view');
      if (plan != null) {
        final now = DateTime.now();
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
      print('[DEBUG] toggleRosterView: Switching to lunch view');
      if (plan != null) {
        final now = DateTime.now();
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
      final now = DateTime.now();
      final m = now.hour * 60 + now.minute;
      _activeRosterView = m >= dinnerFullSwitchMinutes ? 'lunch' : 'dinner';
    }
    notifyListeners();
  }

  void resetRosterView() {
    _activeRosterView = 'auto';
    notifyListeners();
  }

  List<String> get currentRoster {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    if (_activeRosterView == 'lunch') {
      return _todayPlan?.lunchRoster ?? [];
    }
    if (_activeRosterView == 'dinner') {
      return _todayPlan?.dinnerRoster ?? [];
    }
    // 'auto' mode
    if (m < dinnerSwitchMinutes) {
      return _todayPlan?.lunchRoster ?? [];
    } else if (m < dinnerFullSwitchMinutes) {
      return _todayPlan?.lunchRoster ?? [];
    } else {
      return _todayPlan?.dinnerRoster ?? [];
    }
  }

  final List<ShiftRecord> _history = [];
  List<ShiftRecord> get history {
    final raw = (_history..sort((a, b) => b.start.compareTo(a.start)));
    return List.unmodifiable(raw);
  }

  int allTimeFor(String id) => (_totals[id] ?? 0) + (_currentCounts[id] ?? 0);
  Server? serverById(String id) => _servers.firstWhereOrNull((s) => s.id == id);

  Future<void> load() async {
    final sl = (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
    final loadedServers = sl.map((m) => Server.fromMap(Map<String, dynamic>.from(m))).toList();
    final loadedTotals = (await Storage.totalsBox.get('totals') as Map?)?.cast<String, int>() ?? {};
    final histList = (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
    final loadedProfiles = <String, ServerProfile>{};
    for (final s in loadedServers) {
      final m = (await Storage.profilesBox.get(s.id) as Map?) ?? {};
      loadedProfiles[s.id] = m.isEmpty ? ServerProfile() : ServerProfile.fromMap(m);
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
      ..addAll(histList.map((m) => ShiftRecord.fromMap(Map<String, dynamic>.from(m))));
    _profiles
      ..clear()
      ..addAll(loadedProfiles);

    final hm = (await Storage.settingsBox.get('weekly_hours') as Map?) ?? {};
    _hours = hm.isEmpty ? WeeklyHours.defaults() : WeeklyHours.fromMap(Map<String, dynamic>.from(hm));

    final ymd = _ymd(DateTime.now());
    final dp = (await Storage.dayPlanBox.get(ymd) as Map?) ?? {};
    _todayPlan = dp.isEmpty ? null : DayPlan.fromMap(Map<String, dynamic>.from(dp));

    final tapRaw = (await Storage.tapBox.get('per_minute') as Map?) ?? {};
    _tapPerMinute
      ..clear()
      ..addAll(tapRaw.map((sid, m) => MapEntry(sid as String, Map<int, int>.from((m as Map).map((k, v) => MapEntry(int.parse(k as String), v as int))))));

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
    _selectedWallpaper = (await Storage.settingsBox.get('selectedWallpaper') as String?) ?? 'none';
    _autoRotateWallpaper = (await Storage.settingsBox.get('autoRotateWallpaper') as bool?) ?? false;

    _teamGoal = _computeGoalFromHistory();

    _startTicker();
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  // Save a partial shift record for only a subset of servers (e.g., lunch at transition)
  void _savePartialShift(String type, Map<String, int> counts, Map<String, int> pizookieCounts) {
    // If saving a Lunch shift, filter out dinner-only servers from counts
    Map<String, int> filteredCounts = counts;
    Map<String, int> filteredPizookieCounts = pizookieCounts;
    if (type == 'Lunch' && _todayPlan != null) {
      final lunchSet = _todayPlan!.lunchRoster.toSet();
      filteredCounts = Map.fromEntries(counts.entries.where((e) => lunchSet.contains(e.key)));
      filteredPizookieCounts = Map.fromEntries(pizookieCounts.entries.where((e) => lunchSet.contains(e.key)));
    }
    final rec = ShiftRecord(
      id: _randId(),
      label: type,
      shiftType: type,
      start: _shiftStart ?? DateTime.now(),
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
      print('[DEBUG] Timer tick: checking shift activation');
      _maybeActivateShiftByClock();
      _pruneOldTapBuckets();

      // --- CRITICAL TRANSITION LOGIC - DO NOT MODIFY WITHOUT CAREFUL TESTING ---
      // This section handles the complex lunch-to-dinner transition that preserves
      // dinner-only server counts while resetting both-shift servers to 0.
      // 
      // EXPECTED BEHAVIOR:
      // - Lunch-only servers: Work until transition end, then removed
      // - Both-shift servers: Work both shifts, reset to 0 at dinner start  
      // - Dinner-only servers: Start during transition, preserve counts into dinner
      //
      // ROSTER LOGIC:
      // - dinnerOnly = servers in dinner roster but NOT in lunch roster
      // - bothShifts = servers in BOTH lunch AND dinner rosters
      // - lunchOnly = servers in lunch roster but NOT in dinner roster (auto-removed)
      //
      // ⚠️ CRITICAL: Order of operations matters for count preservation!
      // ⚠️ See commit a7fa1ef for working implementation details
      // --- Auto-switch from lunch to dinner at end of transition ---
      final now = DateTime.now();
      final m = now.hour * 60 + now.minute;
      final plan = _todayPlan;
      if (plan != null) {
        final end = plan.transitionEndMinutes;
        // Only at the END of transition, finalize and clear lunch server counts
        if (m >= end && _activeRosterView != 'dinner' && _shiftType == 'Lunch') {
          final lunchIds = plan.lunchRoster;
          final dinnerIds = plan.dinnerRoster;
          
          // FIRST: Preserve dinner-only server counts BEFORE any clearing
          final lunchSet = lunchIds.toSet();
          final dinnerSet = dinnerIds.toSet();
          final dinnerOnly = dinnerSet.difference(lunchSet);
          final bothShifts = dinnerSet.intersection(lunchSet);
          final preservedCounts = <String, int>{};
          final preservedStreaks = <String, int>{};
          final preservedPizookies = <String, int>{};
          
          print('[DEBUG] Lunch roster: $lunchIds');
          print('[DEBUG] Dinner roster: $dinnerIds');
          print('[DEBUG] Dinner-only servers: $dinnerOnly');
          print('[DEBUG] Both-shift servers: $bothShifts');
          print('[DEBUG] Preserving dinner-only servers: $dinnerOnly');
          print('[DEBUG] Current _currentCounts state: $_currentCounts');
          
          for (final id in dinnerOnly) {
            preservedCounts[id] = _currentCounts[id] ?? 0;
            preservedStreaks[id] = _currentStreaks[id] ?? 0;
            preservedPizookies[id] = _currentPizookieCounts[id] ?? 0;
            print('[DEBUG] Backing up server $id: ${preservedCounts[id]} counts (from _currentCounts[${id}] = ${_currentCounts[id]})');
          }
          
          // SECOND: Save lunch shift data
          final lunchCounts = Map<String, int>.fromEntries(
            _currentCounts.entries.where((e) => lunchIds.contains(e.key)));
          final lunchPizookieCounts = Map<String, int>.fromEntries(
            _currentPizookieCounts.entries.where((e) => lunchIds.contains(e.key)));
          _savePartialShift('Lunch', lunchCounts, lunchPizookieCounts);
          
          // THIRD: Remove lunch-only servers from all maps
          _currentCounts.removeWhere((id, _) => lunchIds.contains(id) && !dinnerIds.contains(id));
          _currentStreaks.removeWhere((id, _) => lunchIds.contains(id) && !dinnerIds.contains(id));
          _lunchPeakCount.removeWhere((id, _) => lunchIds.contains(id) && !dinnerIds.contains(id));
          _dinnerPeakCount.removeWhere((id, _) => lunchIds.contains(id) && !dinnerIds.contains(id));
          _lunchCloserCount.removeWhere((id, _) => lunchIds.contains(id) && !dinnerIds.contains(id));
          _dinnerCloserCount.removeWhere((id, _) => lunchIds.contains(id) && !dinnerIds.contains(id));
          _currentPizookieCounts.removeWhere((id, _) => lunchIds.contains(id) && !dinnerIds.contains(id));
          
          // FOURTH: Start dinner shift WITHOUT preserveCounts to properly clear both-shift servers
          _beginShift('Dinner', plan.dinnerRoster, preserveCounts: false);
          
          // FIFTH: Manually restore ONLY dinner-only server counts after the clear
          print('[DEBUG] Restoring dinner-only servers after clear: $dinnerOnly');
          for (final id in dinnerOnly) {
            _currentCounts[id] = preservedCounts[id] ?? 0;
            _currentStreaks[id] = preservedStreaks[id] ?? 0;
            _currentPizookieCounts[id] = preservedPizookies[id] ?? 0;
            print('[DEBUG] Restored server $id: ${_currentCounts[id]} counts');
          }
          _shiftActive = true;
          
          // REMOVED: Duplicate restoration logic that was overwriting preserved counts
          // The restoration already happened in step FIFTH above
          
          // SEVENTH: Update active roster to ensure all dinner servers are in working IDs
          _workingServerIds.clear();
          _workingServerIds.addAll(plan.dinnerRoster);
          
          _activeRosterView = 'dinner';
          print('[DEBUG] Dinner shift active: $_shiftActive');
          print('[DEBUG] Working servers: $_workingServerIds');
          print('[DEBUG] Current counts: $_currentCounts');
          notifyListeners();
        }
      }
    });
  }

  Future<void> _persistServers() async =>
      Storage.serversBox.put('list', _servers.map((s) => s.toMap()).toList());
  Future<void> _persistTotals() async => Storage.totalsBox.put('totals', _totals);
  Future<void> _persistHistory() async =>
      Storage.shiftsBox.put('list', _history.map((h) => h.toMap()).toList());
  Future<void> _persistProfiles() async {
    for (final e in _profiles.entries) {
      await Storage.profilesBox.put(e.key, e.value.toMap());
    }
  }
  Future<void> _persistHours() async => Storage.settingsBox.put('weekly_hours', _hours.toMap());

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
        final pizookieRuns = shift.pizookieCounts[serverId] ?? 0; // Use shift-specific pizookie data
        
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
  Future<void> _persistDayPlan() async {
    if (_todayPlan != null) {
      await Storage.dayPlanBox.put(_todayPlan!.ymd, _todayPlan!.toMap());
    }
  }
  Future<void> _persistTapLog() async {
    final map = _tapPerMinute.map((sid, m) => MapEntry(sid, m.map((k, v) => MapEntry(k.toString(), v))));
    await Storage.tapBox.put('per_minute', map);
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
    notifyListeners();
  }

  void setWeeklyHours(WeeklyHours h) {
    _hours = h;
    _persistHours();
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  void setTodayPlan(List<String> lunch, List<String> dinner) {
    final ymd = _ymd(DateTime.now());
    _todayPlan = DayPlan(
      ymd: ymd,
      lunchRoster: List.of(lunch),
      dinnerRoster: List.of(dinner),
      transitionStartMinutes: settings.transitionStartMinutes,
      transitionEndMinutes: settings.transitionEndMinutes,
    );
    _persistDayPlan();
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  bool forceStartCurrentShift() {
    final now = DateTime.now();
    if (_todayPlan == null) return false;
    final intended = currentIntendedShiftType(now);
    final roster = intended == 'Lunch' ? _todayPlan!.lunchRoster : _todayPlan!.dinnerRoster;
    if (roster.isEmpty) return false;
    _beginShift(intended, roster);
    return true;
  }

  Future<void> startNewShift({
    required String label,        // UI may pass text; we override based on clock
    required List<String> workingIds,
    DateTime? start,
  }) async {
    _shiftActive = true;
    final now = start ?? DateTime.now();
    _shiftType = currentIntendedShiftType(now);
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
    final now = DateTime.now();
  final wd = AppState.weekday(now);
    final open = _hours.openMinutes[wd] ?? 11 * 60;
    final closeRaw = _hours.closeMinutes[wd] ?? 23 * 60;
    // Handle midnight (24:00) close time - treat as end of day (1439 minutes)
    final close = closeRaw >= 1440 ? 1439 : closeRaw;
    final m = now.hour * 60 + now.minute;
    final isOpen = m >= open && m < close;
    print('[DEBUG] isOpenNow: m=$m, open=$open, close=$close, isOpen=$isOpen');
    return isOpen;
  }

  String currentIntendedShiftType(DateTime now) {
  final wd = AppState.weekday(now);
    final m = now.hour * 60 + now.minute;
    final open = _hours.openMinutes[wd]!;
    print('[DEBUG] currentIntendedShiftType: m=$m, open=$open, dinnerSwitch=$dinnerSwitchMinutes');
    if (m < open) {
      print('[DEBUG] currentIntendedShiftType: Before open, returning Lunch');
      return 'Lunch';
    }
    if (m < dinnerSwitchMinutes) {
      print('[DEBUG] currentIntendedShiftType: Before dinnerSwitch, returning Lunch');
      return 'Lunch';
    }
    print('[DEBUG] currentIntendedShiftType: After dinnerSwitch, returning Dinner');
    return 'Dinner';
  }

  void _maybeActivateShiftByClock() {
    final now = DateTime.now();
    final ymd = _ymd(now);
    print('[DEBUG] _maybeActivateShiftByClock called at $now');
    
    if (_todayPlan == null || _todayPlan!.ymd != ymd) {
      if (_shiftActive) {
        // Don't clear state if a shift is active; just log a warning
        print('[WARNING] _maybeActivateShiftByClock: _todayPlan missing or date mismatch, but shift is active. State NOT cleared.');
        return;
      } else {
        print('[DEBUG] _maybeActivateShiftByClock: No plan for today, clearing state');
        _shiftActive = false;
        _shiftPaused = false;
        _workingServerIds.clear();
        _currentCounts.clear();
        _currentStreaks.clear();
        resetRosterView();
        return;
      }
    }

    final intended = currentIntendedShiftType(now);
    final lunchRoster = _todayPlan!.lunchRoster;
    final dinnerRoster = _todayPlan!.dinnerRoster;

    final wd = AppState.weekday(now);
    final open = _hours.openMinutes[wd]!;
    final closeRaw = _hours.closeMinutes[wd] ?? 23 * 60;
    // Handle midnight (24:00) close time - treat as end of day (1439 minutes)
    final close = closeRaw >= 1440 ? 1439 : closeRaw;
    final m = now.hour * 60 + now.minute;

    final transitionEnd = _todayPlan?.transitionEndMinutes ?? close;
    print('[DEBUG] _maybeActivateShiftByClock: Plan details:');
    print('[DEBUG]   transitionStart=${_todayPlan?.transitionStartMinutes}');
    print('[DEBUG]   transitionEnd=${_todayPlan?.transitionEndMinutes}');
    print('[DEBUG]   lunchRoster=${_todayPlan?.lunchRoster}');
    print('[DEBUG]   dinnerRoster=${_todayPlan?.dinnerRoster}');
    
    // CRITICAL FIX: Proper transition and closing logic
    // Lunch should be active: open → transition end
    final shouldBeActiveLunch = m >= open && m < transitionEnd && lunchRoster.isNotEmpty && !_shiftPaused;
    // Dinner should be active: transition end → close 
    final shouldBeActiveDinner = m >= transitionEnd && m < close && dinnerRoster.isNotEmpty && !_shiftPaused;
    // Restaurant should be closed: at or after close time
    final shouldBeClosed = m >= close;

    print('[DEBUG] _maybeActivateShiftByClock: m=$m, open=$open, close=$close, transitionEnd=$transitionEnd');
    print('[DEBUG] _maybeActivateShiftByClock: intended=$intended, _shiftType=$_shiftType, _shiftActive=$_shiftActive');
    print('[DEBUG] _maybeActivateShiftByClock: shouldBeActiveLunch=$shouldBeActiveLunch, shouldBeActiveDinner=$shouldBeActiveDinner, shouldBeClosed=$shouldBeClosed');
    print('[DEBUG] _maybeActivateShiftByClock: _workingServerIds=$_workingServerIds');

    // CRITICAL FIX: Detect transition based on time, not intended shift type
    final isTransitionEnd = m >= transitionEnd && _shiftType == 'Lunch' && _shiftActive;
    final switchingToDinner = isTransitionEnd;

    if (switchingToDinner) {
      // CRITICAL FIX: Transition end logic
      print('[DEBUG] _maybeActivateShiftByClock: Transition end detected - switching to dinner shift');
      
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
        print('[DEBUG] _maybeActivateShiftByClock: Preserving dinner-only server $id: ${dinnerOnlyCounts[id]} counts');
      }
      
      // Finalize lunch shift and save records - include lunch-only + both-shift workers
      final lunchOnlyWorkers = lunchSet.difference(dinnerSet);
      final lunchPeriodWorkers = [...lunchOnlyWorkers, ...bothShifts].toList();
      _finalizeAndSaveShift('Lunch', lunchPeriodWorkers);
      
      // Start dinner shift normally (this clears all counts)
      _beginShift('Dinner', dinnerRoster, preserveCounts: false);
      
      // Restore dinner-only server counts
      for (final id in dinnerOnly) {
        _currentCounts[id] = dinnerOnlyCounts[id]!;
        _currentPizookieCounts[id] = dinnerOnlyPizookieCounts[id]!;
        print('[DEBUG] _maybeActivateShiftByClock: Restored dinner-only server $id to ${_currentCounts[id]} counts');
      }
      
      // Reset both-shift servers to 0 for fresh dinner start
      for (final id in bothShifts) {
        _currentCounts[id] = 0;
        _currentPizookieCounts[id] = 0;
        print('[DEBUG] _maybeActivateShiftByClock: Reset both-shift server $id to 0 for dinner');
      }
      
      _shiftActive = true;
      notifyListeners();
      return;
    }
    
    // CRITICAL FIX: Restaurant closing logic
    if (shouldBeClosed) {
      print('[DEBUG] _maybeActivateShiftByClock: Restaurant closed - finalizing shift and clearing state');
      if (_shiftActive) {
        _finalizeAndSaveShift(_shiftType);
      }
      _shiftActive = false;
      _shiftPaused = false;
      _workingServerIds.clear();
      _currentCounts.clear();
      _currentStreaks.clear();
      _todayPlan = null;
      resetRosterView();
      notifyListeners();
      return;
    }

    // During transition, keep lunch shift active and do not reset
    if (shouldBeActiveLunch) {
      if (!_shiftActive || _shiftType != 'Lunch') {
        print('[DEBUG] _maybeActivateShiftByClock: Starting lunch shift with roster: $lunchRoster');
        _beginShift('Lunch', lunchRoster);
        _shiftActive = true;
        notifyListeners();
      } else {
        // CRITICAL FIX: During transition period, add dinner-only servers to working set
        final transitionStart = _todayPlan!.transitionStartMinutes;
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
              print('[DEBUG] _maybeActivateShiftByClock: Added dinner-only server $id to working set during transition');
            }
          }
        }
        
        print('[DEBUG] _maybeActivateShiftByClock: Lunch shift already active, workingServerIds: $_workingServerIds');
      }
      return;
    }
    if (shouldBeActiveDinner) {
      if (!_shiftActive || _shiftType != 'Dinner') {
        print('[DEBUG] _maybeActivateShiftByClock: Starting dinner shift, roster: $dinnerRoster');
        _beginShift('Dinner', dinnerRoster, preserveCounts: false);
        _shiftActive = true;
        notifyListeners();
      } else {
        print('[DEBUG] _maybeActivateShiftByClock: Dinner shift already active, workingServerIds: $_workingServerIds');
      }
      return;
    }
  }

  void _beginShift(String type, List<String> roster, {bool preserveCounts = false}) {
    print('[DEBUG] _beginShift: type=$type, roster=$roster, preserveCounts=$preserveCounts');
    _shiftActive = true;
    _shiftPaused = false;
    _shiftType = type;
    _shiftStart = DateTime.now();

    _workingServerIds
      ..clear()
      ..addAll(roster);
    
    print('[DEBUG] _beginShift: _workingServerIds updated to $_workingServerIds');

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
        if (!_currentPizookieCounts.containsKey(id)) _currentPizookieCounts[id] = 0;
      }
      
      // DO NOT remove any existing counts when preserving - this was the bug!
      // The manual restoration logic will handle preserving dinner-only server counts
      print('[DEBUG] _beginShift: Preserved existing counts, no data removed');
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

  void _finalizeAndSaveShift(String type, [List<String>? roster]) {
    // Filter counts to only include servers assigned to this shift
    final filteredCounts = <String, int>{};
    final pizookieCounts = <String, int>{};
    
    final keysToSave = roster != null ? roster.where((id) => _currentCounts.containsKey(id)) : _currentCounts.keys;
    
    print('[DEBUG] Finalizing shift: type=$type');
    print('[DEBUG] Roster filter: ${roster ?? 'none (all servers)'}');
    print('[DEBUG] Available _currentCounts: $_currentCounts');
    print('[DEBUG] Keys to check for saving: ${keysToSave.toList()}');
    
    for (final id in keysToSave) {
      final count = _currentCounts[id] ?? 0;
      print('[DEBUG] Server $id: count=$count');
      if (count > 0) {  // Only save servers with actual runs
        filteredCounts[id] = count;
        pizookieCounts[id] = _currentPizookieCounts[id] ?? 0;
        print('[DEBUG] Server $id SAVED to $type history with $count runs');
      } else {
        print('[DEBUG] Server $id SKIPPED (count=$count)');
      }
    }
    
    print('[DEBUG] Final saving counts: $filteredCounts');
    print('[DEBUG] Final saving pizookieCounts: $pizookieCounts');
    print('[DEBUG] Saving pizookieCounts: $pizookieCounts');
    final rec = ShiftRecord(
      id: _randId(),
      label: type,
      shiftType: type,
      start: _shiftStart ?? DateTime.now(),
      counts: filteredCounts,
      pizookieCounts: pizookieCounts,
    );
    _history.add(rec);

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
  _currentStreaks.clear();
  _lunchPeakCount.clear();
  _dinnerPeakCount.clear();
  _lunchCloserCount.clear();
  _dinnerCloserCount.clear();
  _currentPizookieCounts.clear();
  _teamTotalThisShift = 0;
  }

  Future<bool> endCurrentShiftWithPin(String pin) async {
    if (pin != adminPin) return false;
    if (_shiftActive) {
      _finalizeAndSaveShift(_shiftType);
      _shiftActive = false;
      _shiftPaused = false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> pauseCurrentShiftWithPin(String pin) async {
    if (pin != adminPin) return false;
    if (_shiftActive) {
      _shiftActive = false;
      _shiftPaused = true;
      notifyListeners();
    }
    return true;
  }

  Future<bool> resumePausedShiftWithPin(String pin) async {
    if (pin != adminPin) return false;
    if (_shiftPaused) {
      _shiftActive = true;
      _shiftPaused = false;
      notifyListeners();
    }
    return true;
  }

  Future<void> endDay() async {
    if (_shiftActive) {
      _finalizeAndSaveShift(_shiftType);
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

  Future<bool> renameServer(String id, String newName, {required String pin}) async {
    if (pin != adminPin) return false;
    final s = serverById(id);
    if (s == null) return false;
    s.name = newName.trim();
    await _persistServers();
    notifyListeners();
    return true;
  }

  Future<bool> removeServer(String id, {required String pin}) async {
    if (pin != adminPin) return false;
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
      final ymd = _ymd(DateTime.now());
      final key = '${id}_$ymd';
      if (p.repeatEarnedDates.contains(key)) return;
      p.repeatEarnedDates.add(key);
      p.points += def.points;
      _recentBadgeBubble = '$serverName earned the ${def.title} badge!';
    } else {
      p.achievements.add(id);
      p.points += def.points;
      _recentBadgeBubble = '$serverName earned the ${def.title} badge!';
    }
  }

  String? increment(String id) {
  final now = DateTime.now();
  final m = now.hour * 60 + now.minute;
  final plan = _todayPlan;
  print('[DEBUG] increment attempt: server=$id, shiftActive=$_shiftActive, workingIds=$_workingServerIds');
  print('[DEBUG] increment: currentTime=$m, shiftType=$_shiftType, transition=${plan?.transitionStartMinutes}-${plan?.transitionEndMinutes}');
  print('[DEBUG] increment: lunchRoster=${plan?.lunchRoster}, dinnerRoster=${plan?.dinnerRoster}');
  
  // Check if server is in both shifts (critical for tracking Server B)
  final lunchIds = plan?.lunchRoster ?? [];
  final dinnerIds = plan?.dinnerRoster ?? [];
  final inLunch = lunchIds.contains(id);
  final inDinner = dinnerIds.contains(id);
  print('[DEBUG] increment: server $id -> inLunch=$inLunch, inDinner=$inDinner, currentCounts=${_currentCounts[id] ?? 0}');
  
  if (!_shiftActive || !_workingServerIds.contains(id)) {
    print('[DEBUG] increment BLOCKED: shiftActive=$_shiftActive, serverInWorking=${_workingServerIds.contains(id)}');
    return null;
  }
  print('[DEBUG] increment SUCCESS: server $id proceeding');

    const delta = 1;



    // --- Full Hands! achievement logic (now 2 rapid taps) ---
    String? justAwarded;
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
          justAwarded = 'full_hands';
          awardedFullHands = true;
        }
      }
    }

    _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
    lastRunServerId = id;
    _teamTotalThisShift += delta;

    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;

    // Only award 35 XP for Full Hands if gamification is enabled, otherwise always 10 XP
    if (!awardedFullHands || !settings.gamificationEnabled) {
  prof.points += 10;
  print('[DEBUG] +10 points awarded to $id, total now: ${prof.points}');
    }
    prof.allTimeRuns += delta;
    print('[DEBUG] Server $id now has ${prof.points} XP, level ${prof.level}, allTimeRuns: ${prof.allTimeRuns}');

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
      if (prof.allTimeRuns == 0 && !_profiles.containsKey('first_run_${id}_awarded')) {
        _awardOnce(prof, 'first_run', serverName);
      }
    }

    if (isLunchPeak(now)) {
      _lunchPeakCount[id] = (_lunchPeakCount[id] ?? 0) + delta;
      if (_lunchPeakCount[id]! >= 10) _awardOnce(prof, 'lunch_peak_10', serverName);
    }
    if (isDinnerPeak(now)) {
      _dinnerPeakCount[id] = (_dinnerPeakCount[id] ?? 0) + delta;
      if (_dinnerPeakCount[id]! >= 10) _awardOnce(prof, 'dinner_peak_10', serverName);
    }
    if (isLunchCloser(now)) {
      _lunchCloserCount[id] = (_lunchCloserCount[id] ?? 0) + delta;
      if (_lunchCloserCount[id]! >= 8) _awardOnce(prof, 'lunch_closer_8', serverName);
    }
    if (isDinnerCloser(now)) {
      _dinnerCloserCount[id] = (_dinnerCloserCount[id] ?? 0) + delta;
      if (_dinnerCloserCount[id]! >= 8) _awardOnce(prof, 'dinner_closer_8', serverName);
    }

  _profiles[id] = prof;

  final minuteEpoch = DateTime(now.year, now.month, now.day, now.hour, now.minute).millisecondsSinceEpoch;
  _tapPerMinute.putIfAbsent(id, () => <int, int>{});
  _tapPerMinute[id]![minuteEpoch] = (_tapPerMinute[id]![minuteEpoch] ?? 0) + 1;
  _persistTapLog();
  _persistProfiles();
  _persistTotals();

  notifyListeners();
  return justAwarded;
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
    final now = DateTime.now();
    final ymd = _ymd(now);
    int s1 = 0, s2 = 0, s3 = 0, s4 = 0;
    buckets.forEach((minuteEpoch, count) {
      if (todayOnly) {
        final d = DateTime.fromMillisecondsSinceEpoch(minuteEpoch);
        if (_ymd(d) != ymd) return;
      }
      if (count <= 0) return;
      if (count == 1) s1++;
      else if (count == 2) s2++;
      else if (count == 3) s3++;
      else s4++;
    });
    return {'1': s1, '2': s2, '3': s3, '4+': s4};
  }

  void _pruneOldTapBuckets() {
    final cutoff = DateTime.now().subtract(const Duration(days: 180)).millisecondsSinceEpoch;
    for (final m in _tapPerMinute.values) {
      m.removeWhere((k, v) => k < cutoff);
    }
  }

  List<ShiftRecord> shiftsOnDate(DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);
    return history.where((h) {
      final hd = DateTime(h.start.year, h.start.month, h.start.day);
      return hd == d0;
    }).toList();
  }

  void updateBothRosters({required List<String> lunch, required List<String> dinner}) {
    setTodayPlan(lunch, dinner);
    final now = DateTime.now();
    final intended = currentIntendedShiftType(now);
    if (intended == 'Lunch') {
      updateActiveRoster(lunch);
    } else {
      updateActiveRoster(dinner);
    }
  }

  void updateActiveRoster(List<String> newRoster, {bool preserveExistingCounts = false}) {
    final newSet = Set<String>.from(newRoster);
    for (final id in _workingServerIds.toList()) {
      if (!newSet.contains(id)) {
        if (preserveExistingCounts) {
          // Do not clear counts for servers not in the new roster
          _workingServerIds.remove(id);
          continue;
        }
        _currentCounts.remove(id);
        _currentStreaks.remove(id);
        _lunchPeakCount.remove(id);
        _dinnerPeakCount.remove(id);
        _lunchCloserCount.remove(id);
        _dinnerCloserCount.remove(id);
        _workingServerIds.remove(id);
      }
    }
    for (final id in newSet) {
      if (!_workingServerIds.contains(id)) {
        _workingServerIds.add(id);
        if (!preserveExistingCounts) {
          _currentCounts[id] = 0;
          _currentStreaks[id] = 0;
          _lunchPeakCount[id] = 0;
          _dinnerPeakCount[id] = 0;
          _lunchCloserCount[id] = 0;
          _dinnerCloserCount[id] = 0;
        } else {
          // If preserving, only initialize to 0 if not present
          _currentCounts.putIfAbsent(id, () => 0);
          _currentStreaks.putIfAbsent(id, () => 0);
          _lunchPeakCount.putIfAbsent(id, () => 0);
          _dinnerPeakCount.putIfAbsent(id, () => 0);
          _lunchCloserCount.putIfAbsent(id, () => 0);
          _dinnerCloserCount.putIfAbsent(id, () => 0);
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
  if (pin != adminPin) return false;
  _history.removeWhere((s) => s.id == shift.id);
  await _persistHistory();
  notifyListeners();
  return true;
}

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static int weekday(DateTime d) => d.weekday;

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

  void updateAvatar(String serverId, String avatarPath) {
  print('AppState.updateAvatar called for $serverId with $avatarPath');
    final profile = _profiles[serverId];
    if (profile != null) {
      profile.avatarPath = avatarPath;
      final now = DateTime.now();
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
    print('AppState.updateBanner called for $serverId with $bannerPath');
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
}