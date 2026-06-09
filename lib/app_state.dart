/// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
import 'dart:async';
import 'dart:math';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'models.dart';
import 'storage.dart';
import 'gamification.dart';
import 'logging.dart';

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
  })  : achievements = achievements ?? [],
        repeatEarnedDates = repeatEarnedDates ?? [];

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

    final now = clock.now();
    const delta = 1;
    const pizookiePoints = 25;

    _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
    lastRunServerId = id;
    _teamTotalThisShift += delta;
    _currentPizookieCounts[id] = (_currentPizookieCounts[id] ?? 0) + delta;
    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;
    final prof = _profiles[id] ?? ServerProfile();
    final serverName = serverById(id)?.name ?? 'Server';

    prof.points += pizookiePoints;
    prof.allTimeRuns += delta;
    prof.pizookieRuns += delta;

    _recordTapInterval(prof, now);

    if (settings.gamificationEnabled) {
      _awardStreakAndShiftBadges(prof, id, sCount, serverName, now);
      _awardPeakCloserBadges(prof, id, serverName, now);
    }

    _profiles[id] = prof;
    _recordTapBucketAndPersist(id, now);
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
  bool _disposed = false;

  // Roster toggle state: 'auto', 'lunch', 'dinner'
  String _activeRosterView = 'auto';

  // expose
  // Active servers only — archived users are hidden from every feature and
  // report that reads this. Use [allServers] for admin management screens.
  List<Server> get servers => List.unmodifiable(_servers
      .where((s) => !s.archived)
      .sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
  // Every server including archived ones (admin management only).
  List<Server> get allServers =>
      List.unmodifiable(_servers.sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
  /// Whether [id] refers to a server that is currently active (exists and not
  /// archived). Reporting screens use this to skip archived/removed servers.
  bool isActiveServer(String id) =>
      _servers.any((s) => s.id == id && !s.archived);
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

  // Roster view (auto/lunch/dinner), used by the home screen for display.
  String get activeRosterView => _activeRosterView;

  void resetRosterView() {
    _activeRosterView = 'auto';
    notifyListeners();
  }

  List<String> get currentRoster {
    final now = clock.now();
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

    final ymd = _ymd(clock.now());
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
    // MIGRATION: Ensure encouragementFlashEnabled is always set
    if (settings.encouragementFlashEnabled == null) {
      settings.encouragementFlashEnabled = true;
      await Storage.settingsBox.put('gamification', settings.toMap());
    }

    // Restore an in-progress shift if the app was restarted mid-shift today.
    final csRaw = (await Storage.currentShiftBox.get('snapshot') as Map?) ?? {};
    if (csRaw.isNotEmpty && csRaw['ymd'] == ymd) {
      _restoreCurrentShift(Map<String, dynamic>.from(csRaw));
    } else if (csRaw.isNotEmpty) {
      await Storage.currentShiftBox.delete('snapshot'); // stale (previous day)
    }

    _teamGoal = _computeGoalFromHistory();

    _startTicker();
    _maybeActivateShiftByClock();
    // If the lunch->dinner handoff came due while the app was closed, finish it
    // now instead of waiting for the next tick.
    _maybeFinalizeLunchToDinner();
    notifyListeners();
  }

  // Save a partial shift record for only a subset of servers (e.g., lunch at transition)
  void _savePartialShift(String type, Map<String, int> counts, Map<String, int> pizookieCounts) {
    // Save exactly the counts the caller passes. (The caller decides which
    // servers belong to this partial shift; do not re-filter here, or runs
    // from servers removed from the roster mid-shift would be dropped.)
    final filteredCounts = counts;
    final filteredPizookieCounts = pizookieCounts;
    final rec = ShiftRecord(
      id: _randId(),
      label: type,
      shiftType: type,
      start: _shiftStart ?? clock.now(),
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
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _maybeActivateShiftByClock();
      _pruneOldTapBuckets();
      _maybeFinalizeLunchToDinner();
    });
  }

  /// Finalizes the lunch->dinner handoff once the day plan's transition window
  /// has ended. Driven by the periodic ticker.
  ///
  /// Behavior is locked in by test/transition_logic_test.dart:
  ///  - lunch-only servers (in lunch, not dinner) are removed
  ///  - both-shift servers (in lunch AND dinner) are reset to 0
  ///  - dinner-only servers (in dinner, not lunch) keep the counts they
  ///    accumulated during the transition window
  ///
  /// Order matters: dinner-only counts are backed up before clearing and
  /// restored after the dinner shift starts.
  void _maybeFinalizeLunchToDinner() {
    final plan = _todayPlan;
    if (plan == null) return;

    final now = clock.now();
    final m = now.hour * 60 + now.minute;
    final pastTransitionEnd = m >= plan.transitionEndMinutes;
    if (!pastTransitionEnd || _activeRosterView == 'dinner' || _shiftType != 'Lunch') {
      return;
    }

    final lunchSet = plan.lunchRoster.toSet();
    final dinnerSet = plan.dinnerRoster.toSet();
    final dinnerOnly = dinnerSet.difference(lunchSet);
    final bothShifts = dinnerSet.intersection(lunchSet);

    // Per-server, per-shift counters that move together through a transition.
    final counters = <Map<String, int>>[
      _currentCounts,
      _currentStreaks,
      _lunchPeakCount,
      _dinnerPeakCount,
      _lunchCloserCount,
      _dinnerCloserCount,
      _currentPizookieCounts,
    ];

    // 1. Back up dinner-only counts before anything is cleared.
    final preservedCounts = {for (final id in dinnerOnly) id: _currentCounts[id] ?? 0};
    final preservedStreaks = {for (final id in dinnerOnly) id: _currentStreaks[id] ?? 0};
    final preservedPizookies = {
      for (final id in dinnerOnly) id: _currentPizookieCounts[id] ?? 0
    };

    // 2. Persist the completed lunch shift. Save EVERY server's runs except
    //    current dinner-only servers (whose runs carry forward into dinner).
    //    This deliberately includes servers who were removed from the lunch
    //    roster mid-shift — their runs still belong to the lunch record.
    final lunchCounts = {
      for (final e in _currentCounts.entries)
        if (!dinnerOnly.contains(e.key)) e.key: e.value
    };
    final lunchPizookieCounts = {
      for (final e in _currentPizookieCounts.entries)
        if (!dinnerOnly.contains(e.key)) e.key: e.value
    };
    _savePartialShift('Lunch', lunchCounts, lunchPizookieCounts);

    // 3. Drop everyone who isn't on the dinner roster from the live counters;
    //    their runs were just recorded in the lunch shift. Only the dinner
    //    roster continues (lunch-only and mid-shift-removed servers are gone).
    for (final counter in counters) {
      counter.removeWhere((id, _) => !dinnerSet.contains(id));
    }

    // 4. Start the dinner shift, keeping existing dinner-roster counts.
    _beginShift('Dinner', plan.dinnerRoster, preserveCounts: true);
    _shiftActive = true;

    // 5. Restore dinner-only servers' preserved transition counts.
    for (final id in dinnerOnly) {
      _currentCounts[id] = preservedCounts[id]!;
      _currentStreaks[id] = preservedStreaks[id]!;
      _currentPizookieCounts[id] = preservedPizookies[id]!;
    }

    // 6. Reset both-shift servers to a clean dinner start.
    for (final id in bothShifts) {
      for (final counter in counters) {
        counter[id] = 0;
      }
    }

    // 7. The working set is exactly the dinner roster.
    _workingServerIds
      ..clear()
      ..addAll(plan.dinnerRoster);
    _activeRosterView = 'dinner';

    logDebug('[transition] lunch->dinner complete; '
        'working=$_workingServerIds counts=$_currentCounts');
    _persistCurrentShift();
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel the periodic shift-clock ticker so it doesn't leak past the
    // lifetime of this notifier (and so widget tests don't see a pending
    // timer). Idempotent: safe to call more than once.
    if (_disposed) return;
    _disposed = true;
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
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
  Future<void> _persistDayPlan() async {
    if (_todayPlan != null) {
      await Storage.dayPlanBox.put(_todayPlan!.ymd, _todayPlan!.toMap());
    }
  }
  Future<void> _persistTapLog() async {
    final map = _tapPerMinute.map((sid, m) => MapEntry(sid, m.map((k, v) => MapEntry(k.toString(), v))));
    await Storage.tapBox.put('per_minute', map);
  }

  /// Persists a snapshot of the in-progress shift so live run counts survive an
  /// app restart/crash. Tagged with today's date; a stale snapshot from a
  /// previous day is ignored (and cleared) on load.
  Future<void> _persistCurrentShift() async {
    final snapshot = <String, dynamic>{
      'ymd': _ymd(clock.now()),
      'shiftActive': _shiftActive,
      'shiftPaused': _shiftPaused,
      'shiftType': _shiftType,
      'shiftStart': _shiftStart?.toIso8601String(),
      'activeRosterView': _activeRosterView,
      'workingServerIds': _workingServerIds.toList(),
      'currentCounts': _currentCounts,
      'currentStreaks': _currentStreaks,
      'currentPizookieCounts': _currentPizookieCounts,
      'lunchPeakCount': _lunchPeakCount,
      'dinnerPeakCount': _dinnerPeakCount,
      'lunchCloserCount': _lunchCloserCount,
      'dinnerCloserCount': _dinnerCloserCount,
      'teamTotalThisShift': _teamTotalThisShift,
    };
    await Storage.currentShiftBox.put('snapshot', snapshot);
  }

  Future<void> _clearPersistedCurrentShift() async {
    await Storage.currentShiftBox.delete('snapshot');
  }

  void _restoreCurrentShift(Map<String, dynamic> m) {
    Map<String, int> ints(dynamic v) => v == null
        ? <String, int>{}
        : Map<String, int>.from(
            (v as Map).map((k, val) => MapEntry(k as String, val as int)));

    _shiftActive = (m['shiftActive'] as bool?) ?? false;
    _shiftPaused = (m['shiftPaused'] as bool?) ?? false;
    _shiftType = (m['shiftType'] as String?) ?? 'Lunch';
    _shiftStart =
        m['shiftStart'] != null ? DateTime.tryParse(m['shiftStart'] as String) : null;
    _activeRosterView = (m['activeRosterView'] as String?) ?? 'auto';
    _workingServerIds
      ..clear()
      ..addAll((m['workingServerIds'] as List?)?.cast<String>() ?? const <String>[]);
    _currentCounts
      ..clear()
      ..addAll(ints(m['currentCounts']));
    _currentStreaks
      ..clear()
      ..addAll(ints(m['currentStreaks']));
    _currentPizookieCounts
      ..clear()
      ..addAll(ints(m['currentPizookieCounts']));
    _lunchPeakCount
      ..clear()
      ..addAll(ints(m['lunchPeakCount']));
    _dinnerPeakCount
      ..clear()
      ..addAll(ints(m['dinnerPeakCount']));
    _lunchCloserCount
      ..clear()
      ..addAll(ints(m['lunchCloserCount']));
    _dinnerCloserCount
      ..clear()
      ..addAll(ints(m['dinnerCloserCount']));
    _teamTotalThisShift = (m['teamTotalThisShift'] as int?) ?? 0;
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
    final ymd = _ymd(clock.now());
    _todayPlan = DayPlan(
      ymd: ymd,
      lunchRoster: List.of(lunch),
      dinnerRoster: List.of(dinner),
      transitionStartMinutes: settings.transitionStartMinutes,
      transitionEndMinutes: settings.transitionEndMinutes,
    );
    _persistDayPlan();
    _maybeActivateShiftByClock();
    // Keep the active floor in sync with the edited plan, non-destructively,
    // so every roster screen behaves the same and editing never zeroes runs.
    if (_shiftActive) _syncFloorToPlan();
    notifyListeners();
  }

  /// Reconciles the working set ("who can tap right now") to today's plan for
  /// the current time: lunch roster before the transition, the union of both
  /// rosters during it, and the dinner roster after. Non-destructive.
  void _syncFloorToPlan() {
    final plan = _todayPlan;
    if (plan == null) return;
    final now = clock.now();
    final m = now.hour * 60 + now.minute;
    final List<String> floor;
    if (m >= plan.transitionStartMinutes && m < plan.transitionEndMinutes) {
      floor = [...plan.lunchRoster, ...plan.dinnerRoster];
    } else if (_shiftType == 'Dinner') {
      floor = plan.dinnerRoster;
    } else {
      floor = plan.lunchRoster;
    }
    updateActiveRoster(floor);
  }

  bool forceStartCurrentShift() {
    final now = clock.now();
    if (_todayPlan == null) return false;
    final intended = currentIntendedShiftType(now);
    final roster = intended == 'Lunch' ? _todayPlan!.lunchRoster : _todayPlan!.dinnerRoster;
    if (roster.isEmpty) return false;
    _beginShift(intended, roster);
    return true;
  }

  bool get isOpenNow {
    final now = clock.now();
  final wd = AppState.weekday(now);
    final open = _hours.openMinutes[wd] ?? 11 * 60;
    final close = _hours.closeMinutes[wd] ?? 23 * 60;
    final m = now.hour * 60 + now.minute;
    return m >= open && m < close;
  }

  String currentIntendedShiftType(DateTime now) {
  final wd = AppState.weekday(now);
    final m = now.hour * 60 + now.minute;
    final open = _hours.openMinutes[wd]!;
    if (m < open) return 'Lunch';
    if (m < dinnerSwitchMinutes) return 'Lunch';
    return 'Dinner';
  }

  void _maybeActivateShiftByClock() {
    final now = clock.now();
    final ymd = _ymd(now);
    
    if (_todayPlan == null || _todayPlan!.ymd != ymd) {
      if (_shiftActive) {
        // Don't clear state if a shift is active; just log a warning
        logDebug('[WARNING] _maybeActivateShiftByClock: _todayPlan missing or date mismatch, but shift is active. State NOT cleared.');
        return;
      } else {
        logDebug('[DEBUG] _maybeActivateShiftByClock: No plan for today, clearing state');
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
    final roster = intended == 'Lunch' ? _todayPlan!.lunchRoster : _todayPlan!.dinnerRoster;

    final wd = AppState.weekday(now);
    final open = _hours.openMinutes[wd]!;
    final close = _hours.closeMinutes[wd] ?? 23 * 60;
    final m = now.hour * 60 + now.minute;

    final transitionEnd = _todayPlan?.transitionEndMinutes ?? close;
    // Always activate lunch shift at or after open, before transition end
    final shouldBeActiveLunch = m >= open && m < transitionEnd && (_shiftType == 'Lunch' || intended == 'Lunch') && roster.isNotEmpty && !_shiftPaused;
    final shouldBeActiveDinner = m >= transitionEnd && m < close && (_shiftType == 'Dinner' || intended == 'Dinner') && roster.isNotEmpty && !_shiftPaused;


    final switchingToDinner = intended == 'Dinner' && _shiftType == 'Lunch' && _shiftActive;

    if (switchingToDinner) {
      // Transition window (intended is Dinner but the lunch shift is still
      // running until transitionEnd). Keep BOTH crews on the floor so arriving
      // dinner-only servers can log runs without a manual toggle. Lunch counts
      // are untouched; the lunch->dinner handoff is finalized at transitionEnd
      // by _maybeFinalizeLunchToDinner().
      _ensureWorkingServers(
          {..._todayPlan!.lunchRoster, ..._todayPlan!.dinnerRoster});
      return;
    }

    // During transition, keep lunch shift active and do not reset
    if (shouldBeActiveLunch) {
      if (!_shiftActive || _shiftType != 'Lunch') {
        logDebug('[DEBUG] _maybeActivateShiftByClock: Starting lunch shift');
        _beginShift('Lunch', roster);
        _shiftActive = true;
        notifyListeners();
      } else {
      }
      return;
    }
    if (shouldBeActiveDinner) {
      if (!_shiftActive || _shiftType != 'Dinner') {
        logDebug('[DEBUG] _maybeActivateShiftByClock: Starting dinner shift with preservation');
        _beginShift('Dinner', roster, preserveCounts: true);
        _shiftActive = true;
        notifyListeners();
      } else {
      }
      return;
    }
    
    // Outside of open hours - deactivate shift
    if (_shiftActive) {
      // If we're at transition end, let the ticker handle it with preservation logic
      final plan = _todayPlan;
      final isTransitionEnd = plan != null && m >= plan.transitionEndMinutes && _shiftType == 'Lunch';
      
      if (!isTransitionEnd) {
        logDebug('[DEBUG] _maybeActivateShiftByClock: Finalizing shift (not transition end)');
        _finalizeAndSaveShift(_shiftType);
      } else {
      }
    }
    _shiftActive = false;
    _shiftType = intended;
    _workingServerIds
      ..clear()
      ..addAll(roster);

    if (m >= close) {
      _todayPlan = null;
      resetRosterView();
      notifyListeners();
    }
  }

  void _beginShift(String type, List<String> roster, {bool preserveCounts = false}) {
    _shiftActive = true;
    _shiftPaused = false;
    _shiftType = type;
    _shiftStart = clock.now();

    _workingServerIds
      ..clear()
      ..addAll(roster);

    if (preserveCounts) {
      // Only add new dinner servers with 0, never clear or reset existing dinner server data
      for (final id in roster) {
        if (!_currentCounts.containsKey(id)) _currentCounts[id] = 0;
        if (!_currentStreaks.containsKey(id)) _currentStreaks[id] = 0;
        if (!_lunchPeakCount.containsKey(id)) _lunchPeakCount[id] = 0;
        if (!_dinnerPeakCount.containsKey(id)) _dinnerPeakCount[id] = 0;
        if (!_lunchCloserCount.containsKey(id)) _lunchCloserCount[id] = 0;
        if (!_dinnerCloserCount.containsKey(id)) _dinnerCloserCount[id] = 0;
        if (!_currentPizookieCounts.containsKey(id)) _currentPizookieCounts[id] = 0;
      }
      // Remove any counts for servers not in dinner roster
      _currentCounts.removeWhere((id, _) => !roster.contains(id));
      _currentStreaks.removeWhere((id, _) => !roster.contains(id));
      _lunchPeakCount.removeWhere((id, _) => !roster.contains(id));
      _dinnerPeakCount.removeWhere((id, _) => !roster.contains(id));
      _lunchCloserCount.removeWhere((id, _) => !roster.contains(id));
      _dinnerCloserCount.removeWhere((id, _) => !roster.contains(id));
      _currentPizookieCounts.removeWhere((id, _) => !roster.contains(id));
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

    _teamTotalThisShift = 0;
    _teamGoal = _computeGoalFromHistory();
    resetRosterView();
    _persistCurrentShift();
    notifyListeners();
  }

  void _finalizeAndSaveShift(String type) {
    // Build pizookieCounts for this shift from _currentPizookieCounts
    final pizookieCounts = <String, int>{};
    for (final id in _currentCounts.keys) {
      pizookieCounts[id] = _currentPizookieCounts[id] ?? 0;
    }
    logDebug('[DEBUG] Finalizing shift: type=$type');
    logDebug('[DEBUG] Saving counts: ${_currentCounts}');
    logDebug('[DEBUG] Saving pizookieCounts: $pizookieCounts');
    final rec = ShiftRecord(
      id: _randId(),
      label: type,
      shiftType: type,
      start: _shiftStart ?? clock.now(),
      counts: Map<String, int>.from(_currentCounts),
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
  // The shift is over; drop the in-progress snapshot so it can't be restored.
  _clearPersistedCurrentShift();
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
      _persistCurrentShift();
      notifyListeners();
    }
    return true;
  }

  Future<bool> resumePausedShiftWithPin(String pin) async {
    if (pin != adminPin) return false;
    if (_shiftPaused) {
      _shiftActive = true;
      _shiftPaused = false;
      _persistCurrentShift();
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

  /// Removes a server everywhere they live: live shift, all per-shift counters,
  /// today's roster plan, totals, profile, and every historical shift record.
  void _purgeServerData(String id) {
    _totals.remove(id);
    _profiles.remove(id);
    _workingServerIds.remove(id);
    _currentCounts.remove(id);
    _currentStreaks.remove(id);
    _lunchPeakCount.remove(id);
    _dinnerPeakCount.remove(id);
    _lunchCloserCount.remove(id);
    _dinnerCloserCount.remove(id);
    _currentPizookieCounts.remove(id);
    final plan = _todayPlan;
    if (plan != null) {
      plan.lunchRoster.remove(id);
      plan.dinnerRoster.remove(id);
    }
  }

  /// Permanently deletes a server and all of their data (irreversible).
  Future<bool> removeServer(String id, {required String pin}) async {
    if (pin != adminPin) return false;
    _servers.removeWhere((s) => s.id == id);
    _purgeServerData(id);
    for (final rec in _history) {
      rec.counts.remove(id);
      rec.pizookieCounts.remove(id);
    }
    await _persistServers();
    await _persistTotals();
    await _persistProfiles();
    await _persistHistory();
    await _persistDayPlan();
    await _persistCurrentShift();
    notifyListeners();
    return true;
  }

  /// Archives a server: hides them from every feature and report and takes them
  /// off the active floor/roster, but keeps their data so they can be restored.
  Future<bool> archiveServer(String id, {required String pin}) async {
    if (pin != adminPin) return false;
    final s = serverById(id);
    if (s == null) return false;
    s.archived = true;
    // Take them off today's floor and rosters (their totals/profile are kept).
    _workingServerIds.remove(id);
    _currentCounts.remove(id);
    _currentStreaks.remove(id);
    _lunchPeakCount.remove(id);
    _dinnerPeakCount.remove(id);
    _lunchCloserCount.remove(id);
    _dinnerCloserCount.remove(id);
    _currentPizookieCounts.remove(id);
    final plan = _todayPlan;
    if (plan != null) {
      plan.lunchRoster.remove(id);
      plan.dinnerRoster.remove(id);
    }
    await _persistServers();
    await _persistDayPlan();
    await _persistCurrentShift();
    notifyListeners();
    return true;
  }

  /// Restores a previously archived server back into active use.
  Future<bool> restoreServer(String id, {required String pin}) async {
    if (pin != adminPin) return false;
    final s = serverById(id);
    if (s == null) return false;
    s.archived = false;
    await _persistServers();
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
      final ymd = _ymd(clock.now());
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
    if (!_shiftActive || !_workingServerIds.contains(id)) return null;

    final now = clock.now();
    const delta = 1;

    // Full Hands! achievement: two taps within 3 seconds.
    String? justAwarded;
    final tapList = _recentTapTimes.putIfAbsent(id, () => <DateTime>[]);
    tapList.add(now);
    if (tapList.length > 2) tapList.removeAt(0);
    var awardedFullHands = false;
    final prof = _profiles[id] ?? ServerProfile();
    final serverName = serverById(id)?.name ?? 'Server';

    if (settings.gamificationEnabled && tapList.length == 2) {
      if (tapList[1].difference(tapList[0]).inMilliseconds <= 3000) {
        _awardOnce(prof, 'full_hands', serverName);
        _profiles[id] = prof;
        justAwarded = 'full_hands';
        awardedFullHands = true;
      }
    }

    _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
    lastRunServerId = id;
    _teamTotalThisShift += delta;
    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;

    // Full Hands awards 35 via the badge; otherwise a run is worth 10.
    if (!awardedFullHands || !settings.gamificationEnabled) {
      prof.points += 10;
    }
    prof.allTimeRuns += delta;

    _recordTapInterval(prof, now);

    if (settings.gamificationEnabled) {
      _awardStreakAndShiftBadges(prof, id, sCount, serverName, now);
    }
    // NOTE: regular runs award peak/closer badges unconditionally (even when
    // gamification is disabled). Preserved from the original behavior;
    // incrementPizookie does this only when gamification is enabled.
    _awardPeakCloserBadges(prof, id, serverName, now);

    _profiles[id] = prof;
    _recordTapBucketAndPersist(id, now);
    notifyListeners();
    return justAwarded;
  }

  /// Updates a profile's running average of seconds between taps.
  void _recordTapInterval(ServerProfile prof, DateTime now) {
    final prevIso = prof.lastTapIso;
    prof.lastTapIso = now.toIso8601String();
    if (prevIso == null) return;
    final prev = DateTime.tryParse(prevIso);
    if (prev == null) return;
    final ms = now.difference(prev).inMilliseconds;
    if (ms > 0 && ms < 20 * 60 * 1000) {
      prof.tapIntervalsMsSum += ms;
      prof.tapIntervalsCount += 1;
    }
  }

  /// Streak and per-shift run-count badges. Caller decides whether
  /// gamification is enabled before invoking.
  void _awardStreakAndShiftBadges(
      ServerProfile prof, String id, int sCount, String serverName, DateTime now) {
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

  /// Time-of-day peak/closer badges. Increments the matching window counter
  /// and awards the badge at its threshold.
  void _awardPeakCloserBadges(
      ServerProfile prof, String id, String serverName, DateTime now) {
    if (isLunchPeak(now)) {
      _lunchPeakCount[id] = (_lunchPeakCount[id] ?? 0) + 1;
      if (_lunchPeakCount[id]! >= 10) _awardOnce(prof, 'lunch_peak_10', serverName);
    }
    if (isDinnerPeak(now)) {
      _dinnerPeakCount[id] = (_dinnerPeakCount[id] ?? 0) + 1;
      if (_dinnerPeakCount[id]! >= 10) _awardOnce(prof, 'dinner_peak_10', serverName);
    }
    if (isLunchCloser(now)) {
      _lunchCloserCount[id] = (_lunchCloserCount[id] ?? 0) + 1;
      if (_lunchCloserCount[id]! >= 8) _awardOnce(prof, 'lunch_closer_8', serverName);
    }
    if (isDinnerCloser(now)) {
      _dinnerCloserCount[id] = (_dinnerCloserCount[id] ?? 0) + 1;
      if (_dinnerCloserCount[id]! >= 8) _awardOnce(prof, 'dinner_closer_8', serverName);
    }
  }

  /// Records this run in the per-minute tap histogram and persists the run.
  void _recordTapBucketAndPersist(String id, DateTime now) {
    final minuteEpoch =
        DateTime(now.year, now.month, now.day, now.hour, now.minute)
            .millisecondsSinceEpoch;
    _tapPerMinute.putIfAbsent(id, () => <int, int>{});
    _tapPerMinute[id]![minuteEpoch] = (_tapPerMinute[id]![minuteEpoch] ?? 0) + 1;
    _persistTapLog();
    _persistProfiles();
    _persistTotals();
    _persistCurrentShift();
  }

  void decrement(String id) {
    if (!_shiftActive || !_workingServerIds.contains(id)) return;
    final current = (_currentCounts[id] ?? 0);
    if (current > 0) {
      _currentCounts[id] = current - 1;
      _teamTotalThisShift = (_teamTotalThisShift - 1).clamp(0, 1 << 31);
    }
    _currentStreaks[id] = 0;
    _persistCurrentShift();
    notifyListeners();
  }

  Map<String, int> integrityBinsFor(String serverId, {bool todayOnly = false}) {
    final buckets = _tapPerMinute[serverId];
    if (buckets == null) return {'1': 0, '2': 0, '3': 0, '4+': 0};
    final now = clock.now();
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
    final cutoff = clock.now().subtract(const Duration(days: 180)).millisecondsSinceEpoch;
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
    // setTodayPlan already syncs the active floor to the new plan.
    setTodayPlan(lunch, dinner);
  }

  /// Syncs which servers are on the floor (can tap) to [newRoster].
  ///
  /// Removing a server takes them OFF the floor but NEVER deletes their
  /// accumulated runs — those still belong to this shift and are recorded when
  /// the shift finalizes. New servers join with a fresh count of 0; a server
  /// who is re-added keeps whatever runs they already had.
  void updateActiveRoster(List<String> newRoster) {
    final newSet = Set<String>.from(newRoster);
    _workingServerIds.removeWhere((id) => !newSet.contains(id));
    for (final id in newSet) {
      if (_workingServerIds.add(id)) {
        _currentCounts.putIfAbsent(id, () => 0);
        _currentStreaks.putIfAbsent(id, () => 0);
        _lunchPeakCount.putIfAbsent(id, () => 0);
        _dinnerPeakCount.putIfAbsent(id, () => 0);
        _lunchCloserCount.putIfAbsent(id, () => 0);
        _dinnerCloserCount.putIfAbsent(id, () => 0);
        _currentPizookieCounts.putIfAbsent(id, () => 0);
      }
    }
    _persistCurrentShift();
    notifyListeners();
  }

  /// Adds [ids] to the working set (initializing their per-shift counters to 0
  /// if absent) without disturbing any existing counts. Used during the
  /// transition window to put both lunch and dinner crews on the floor.
  void _ensureWorkingServers(Set<String> ids) {
    var changed = false;
    for (final id in ids) {
      if (_workingServerIds.add(id)) {
        _currentCounts.putIfAbsent(id, () => 0);
        _currentStreaks.putIfAbsent(id, () => 0);
        _lunchPeakCount.putIfAbsent(id, () => 0);
        _dinnerPeakCount.putIfAbsent(id, () => 0);
        _lunchCloserCount.putIfAbsent(id, () => 0);
        _dinnerCloserCount.putIfAbsent(id, () => 0);
        _currentPizookieCounts.putIfAbsent(id, () => 0);
        changed = true;
      }
    }
    if (changed) {
      _persistCurrentShift();
      notifyListeners();
    }
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
  logDebug('AppState.updateAvatar called for $serverId with $avatarPath');
    final profile = _profiles[serverId];
    if (profile != null) {
      profile.avatarPath = avatarPath;
      final now = clock.now();
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
    logDebug('AppState.updateBanner called for $serverId with $bannerPath');
    final profile = _profiles[serverId];
    if (profile != null) {
      profile.bannerPath = bannerPath;
      // Force Provider to notify listeners by assigning a new map
      _profiles = Map<String, ServerProfile>.from(_profiles);
      notifyListeners();
      _persistProfiles();
    }
  }
}