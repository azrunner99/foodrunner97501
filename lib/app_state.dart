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
  int allTimeRuns;
  int bestShiftRuns;
  int streakBest;
  int shiftsAsMvp;
  List<String> achievements;
  List<String> repeatEarnedDates;
  int points;
  int tapIntervalsMsSum;
  int tapIntervalsCount;
  String? lastTapIso;

  ServerProfile({
    this.allTimeRuns = 0,
    this.bestShiftRuns = 0,
    this.streakBest = 0,
    this.shiftsAsMvp = 0,
    List<String>? achievements,
    List<String>? repeatEarnedDates,
    this.points = 0,
    this.tapIntervalsMsSum = 0,
    this.tapIntervalsCount = 0,
    this.lastTapIso,
  })  : achievements = achievements ?? [],
        repeatEarnedDates = repeatEarnedDates ?? [];

  Map<String, dynamic> toMap() => {
        'allTimeRuns': allTimeRuns,
        'bestShiftRuns': bestShiftRuns,
        'streakBest': streakBest,
        'shiftsAsMvp': shiftsAsMvp,
        'achievements': achievements,
        'repeatEarnedDates': repeatEarnedDates,
        'points': points,
        'tapIntervalsMsSum': tapIntervalsMsSum,
        'tapIntervalsCount': tapIntervalsCount,
        'lastTapIso': lastTapIso,
      };

  static ServerProfile fromMap(Map m) => ServerProfile(
        allTimeRuns: (m['allTimeRuns'] ?? 0) as int,
        bestShiftRuns: (m['bestShiftRuns'] ?? 0) as int,
        streakBest: (m['streakBest'] ?? 0) as int,
        shiftsAsMvp: (m['shiftsAsMvp'] ?? 0) as int,
        achievements: (m['achievements'] as List?)?.cast<String>() ?? <String>[],
        repeatEarnedDates: (m['repeatEarnedDates'] as List?)?.cast<String>() ?? <String>[],
        points: (m['points'] ?? 0) as int,
        tapIntervalsMsSum: (m['tapIntervalsMsSum'] ?? 0) as int,
        tapIntervalsCount: (m['tapIntervalsCount'] ?? 0) as int,
        lastTapIso: m['lastTapIso'] as String?,
      );

  double get avgSecondsBetweenRuns =>
      tapIntervalsCount == 0 ? 0 : tapIntervalsMsSum / tapIntervalsCount / 1000.0;

  int get level => levelForPoints(points);
  int get nextLevelAt => nextLevelTarget(points);
}

class AppState extends ChangeNotifier {
  static const adminPin = '5520';
  static const dinnerSwitchMinutes = 15 * 60 + 30; // 3:30 PM

  final List<Server> _servers = [];
  final Map<String, int> _totals = {};
  final Map<String, ServerProfile> _profiles = {};
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

  final List<ShiftRecord> _history = [];
  List<ShiftRecord> get history {
    final raw = (_history..sort((a, b) => b.start.compareTo(a.start)));
    return List.unmodifiable(raw);
  }

  int allTimeFor(String id) => (_totals[id] ?? 0) + (_currentCounts[id] ?? 0);
  Server? serverById(String id) => _servers.firstWhereOrNull((s) => s.id == id);

  Future<void> load() async {
    final sl = (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
    _servers
      ..clear()
      ..addAll(sl.map((m) => Server.fromMap(Map<String, dynamic>.from(m))));

    final tm = (await Storage.totalsBox.get('totals') as Map?)?.cast<String, int>() ?? {};
    _totals
      ..clear()
      ..addAll(tm);

    final histList = (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
    _history
      ..clear()
      ..addAll(histList.map((m) => ShiftRecord.fromMap(Map<String, dynamic>.from(m))));

    _profiles.clear();
    for (final s in _servers) {
      final m = (await Storage.profilesBox.get(s.id) as Map?) ?? {};
      _profiles[s.id] = m.isEmpty ? ServerProfile() : ServerProfile.fromMap(m);
    }

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
    settings = sm.isEmpty
        ? GamificationSettings()
        : GamificationSettings.fromMap(Map<String, dynamic>.from(sm));

    _teamGoal = _computeGoalFromHistory();

    _startTicker();
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _maybeActivateShiftByClock();
      _pruneOldTapBuckets();
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
    _todayPlan = DayPlan(ymd: ymd, lunchRoster: List.of(lunch), dinnerRoster: List.of(dinner));
    _persistDayPlan();
    _maybeActivateShiftByClock();
    notifyListeners();
  }

  /// Force an immediate start of the “intended” shift (Lunch before 3:30, Dinner after).
  /// Used by the “Run Food!” button so managers can bring up the grid right now.
  bool forceStartCurrentShift() {
    final now = DateTime.now();
    if (_todayPlan == null) return false;
    final intended = currentIntendedShiftType(now);
    final roster = intended == 'Lunch' ? _todayPlan!.lunchRoster : _todayPlan!.dinnerRoster;
    if (roster.isEmpty) return false;
    _beginShift(intended, roster);
    return true;
  }

  bool get isOpenNow {
    final now = DateTime.now();
    final wd = _weekday(now);
    final open = _hours.openMinutes[wd] ?? 11 * 60;
    final close = _hours.closeMinutes[wd] ?? 23 * 60;
    final m = now.hour * 60 + now.minute;
    return m >= open && m < close;
  }

  String currentIntendedShiftType(DateTime now) {
    final wd = _weekday(now);
    final m = now.hour * 60 + now.minute;
    final open = _hours.openMinutes[wd]!;
    if (m < open) return 'Lunch';
    if (m < dinnerSwitchMinutes) return 'Lunch';
    return 'Dinner';
  }

  void _maybeActivateShiftByClock() {
    final now = DateTime.now();
    final ymd = _ymd(now);
    if (_todayPlan == null || _todayPlan!.ymd != ymd) {
      _shiftActive = false;
      _shiftPaused = false;
      _workingServerIds.clear();
      _currentCounts.clear();
      _currentStreaks.clear();
      return;
    }

    final intended = currentIntendedShiftType(now);
    final roster = intended == 'Lunch' ? _todayPlan!.lunchRoster : _todayPlan!.dinnerRoster;

    final wd = _weekday(now);
    final open = _hours.openMinutes[wd]!;
    final m = now.hour * 60 + now.minute;
    final shouldBeActive = m >= open && roster.isNotEmpty && !_shiftPaused;

    final switchingToDinner = intended == 'Dinner' && _shiftType == 'Lunch' && _shiftActive;

    if (switchingToDinner) {
      _finalizeAndSaveShift('Lunch');
      _beginShift('Dinner', roster);
      return;
    }

    if (shouldBeActive) {
      if (!_shiftActive || _shiftType != intended) {
        _beginShift(intended, roster);
      }
    } else {
      _shiftActive = false;
      _shiftType = intended;
      _workingServerIds
        ..clear()
        ..addAll(roster);
    }
  }

  void _beginShift(String type, List<String> roster) {
    _shiftActive = true;
    _shiftPaused = false;
    _shiftType = type;
    _shiftStart = DateTime.now();

    _workingServerIds
      ..clear()
      ..addAll(roster);

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

    _teamTotalThisShift = 0;
    _teamGoal = _computeGoalFromHistory();
    notifyListeners();
  }

  void _finalizeAndSaveShift(String type) {
    final rec = ShiftRecord(
      id: _randId(),
      label: type,
      shiftType: type,
      start: _shiftStart ?? DateTime.now(),
      counts: Map<String, int>.from(_currentCounts),
    );
    _history.add(rec);

    String? mvpId;
    int mvpScore = -1;

    rec.counts.forEach((id, n) {
      _totals[id] = (_totals[id] ?? 0) + n;
      final prof = _profiles[id] ?? ServerProfile();
      prof.allTimeRuns += n;
      if (n > prof.bestShiftRuns) prof.bestShiftRuns = n;

      if (prof.allTimeRuns >= 50 && !prof.achievements.contains('fifty_all_time')) {
        prof.achievements.add('fifty_all_time');
        prof.points += _pointsFor('fifty_all_time');
      }
      if (prof.allTimeRuns >= 100 && !prof.achievements.contains('hundred_all_time')) {
        prof.achievements.add('hundred_all_time');
        prof.points += _pointsFor('hundred_all_time');
      }

      if (n > mvpScore) {
        mvpScore = n;
        mvpId = id;
      }
      _profiles[id] = prof;
    });

    if (mvpId != null) {
      final p = _profiles[mvpId]!;
      p.shiftsAsMvp += 1;
      if (!p.achievements.contains('mvp')) {
        p.achievements.add('mvp');
        p.points += _pointsFor('mvp');
      }
    }

    final teamTotal = rec.counts.values.fold<int>(0, (a, b) => a + b);
    if (teamTotal >= _teamGoal) {
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
    _teamTotalThisShift = 0;
  }

  Future<bool> endCurrentShiftWithPin(String pin) async {
    if (pin != adminPin) return false;
    if (_shiftActive) {
      _finalizeAndSaveShift(_shiftType);
      _shiftActive = false;
      _shiftPaused = false;
      notifyListeners();
    }
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
    _profiles[s.id] = ServerProfile();
    await _persistServers();
    await _persistProfiles();
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

  // Power-ups are silly but fun
  void increment(String id) {
    if (!_shiftActive || !_workingServerIds.contains(id)) return;

    final now = DateTime.now();
    final r = Random();
    var delta = 1;
    final pu = rollPowerUp(r);
    if (pu == PowerUp.doublePoint) delta = 2;
    if (pu == PowerUp.bonusFive) delta = 6;

    _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
    _teamTotalThisShift += delta;

    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;
    final prof = _profiles[id] ?? ServerProfile();
    final serverName = serverById(id)?.name ?? 'Server';

    prof.points += delta;

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

    notifyListeners();
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

  /// Update both rosters mid-day and sync the active roster if needed.
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

  /// Update the live active roster only (used by Active Roster screen).
  void updateActiveRoster(List<String> newRoster) {
    final newSet = Set<String>.from(newRoster);
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
    notifyListeners();
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static int _weekday(DateTime d) => d.weekday;
}
