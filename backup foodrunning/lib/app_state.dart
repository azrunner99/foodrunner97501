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

/// Per-server persistent profile stats + badges/achievements.
class ServerProfile {
  int allTimeRuns;
  int bestShiftRuns;
  int streakBest;
  int shiftsAsMvp;
  List<String> achievements; // ids
  ServerProfile({
    this.allTimeRuns = 0,
    this.bestShiftRuns = 0,
    this.streakBest = 0,
    this.shiftsAsMvp = 0,
    List<String>? achievements,
  }) : achievements = achievements ?? [];

  Map<String, dynamic> toMap() => {
        'allTimeRuns': allTimeRuns,
        'bestShiftRuns': bestShiftRuns,
        'streakBest': streakBest,
        'shiftsAsMvp': shiftsAsMvp,
        'achievements': achievements,
      };

  static ServerProfile fromMap(Map m) => ServerProfile(
        allTimeRuns: (m['allTimeRuns'] ?? 0) as int,
        bestShiftRuns: (m['bestShiftRuns'] ?? 0) as int,
        streakBest: (m['streakBest'] ?? 0) as int,
        shiftsAsMvp: (m['shiftsAsMvp'] ?? 0) as int,
        achievements: (m['achievements'] as List?)?.cast<String>() ?? <String>[],
      );
}

class AppState extends ChangeNotifier {
  final List<Server> _servers = [];
  final Map<String, int> _totals = {};
  final Map<String, ServerProfile> _profiles = {}; // id -> profile

  GamificationSettings settings = GamificationSettings();

  bool _shiftActive = false;
  String _shiftLabel = '';
  String _shiftType = 'Other'; // Lunch | Dinner | Other
  DateTime? _shiftStart;
  final Map<String, int> _currentCounts = {};
  final Map<String, int> _currentStreaks = {};
  final Set<String> _workingServerIds = {};
  final List<ShiftRecord> _history = [];

  // Resume support: snapshot of last ended shift state
  Map<String, dynamic>? _lastEndedSnapshot; // persisted in settings_box

  int _teamGoal = 0;
  int _teamTotalThisShift = 0;

  // getters
  List<Server> get servers => List.unmodifiable(_servers);
  Map<String, int> get totals => Map.unmodifiable(_totals);
  Map<String, ServerProfile> get profiles => Map.unmodifiable(_profiles);

  bool get shiftActive => _shiftActive;
  String get shiftLabel => _shiftLabel;
  String get shiftType => _shiftType;
  DateTime? get shiftStart => _shiftStart;

  Map<String, int> get currentCounts => Map.unmodifiable(_currentCounts);
  Set<String> get workingServerIds => Set.unmodifiable(_workingServerIds);
  List<ShiftRecord> get history =>
      _history.sorted((a, b) => b.start.compareTo(a.start));

  int get teamGoal => _teamGoal;
  int get teamTotalThisShift => _teamTotalThisShift;

  bool get canResumeLastShift =>
      !_shiftActive && _lastEndedSnapshot != null;

  Server? serverById(String id) =>
      _servers.firstWhereOrNull((s) => s.id == id);

  int allTimeFor(String id) =>
      (_totals[id] ?? 0) + (_currentCounts[id] ?? 0);

  Future<void> load() async {
    // servers
    final sb = Storage.serversBox;
    final serverList = (sb.get('list') as List?)?.cast<Map>() ?? [];
    _servers
      ..clear()
      ..addAll(serverList.map(
          (m) => Server.fromMap(Map<String, dynamic>.from(m))));

    // totals
    final tb = Storage.totalsBox;
    final tm = (tb.get('totals') as Map?)?.cast<String, int>() ?? {};
    _totals
      ..clear()
      ..addAll(tm);

    // history
    final shb = Storage.shiftsBox;
    final histList = (shb.get('list') as List?)?.cast<Map>() ?? [];
    _history
      ..clear()
      ..addAll(histList.map(
          (m) => ShiftRecord.fromMap(Map<String, dynamic>.from(m))));

    // profiles
    final pb = Storage.profilesBox;
    _profiles
      ..clear()
      ..addEntries(_servers.map((s) {
        final m = (pb.get(s.id) as Map?) ?? {};
        return MapEntry(
            s.id, m.isEmpty ? ServerProfile() : ServerProfile.fromMap(m));
      }));

    // settings
    final sbx = Storage.settingsBox;
    final sm = (sbx.get('gamification') as Map?) ?? {};
    settings =
        sm.isEmpty ? GamificationSettings() : GamificationSettings.fromMap(sm);

    _lastEndedSnapshot = (sbx.get('lastEndedSnapshot') as Map?)?.cast<String, dynamic>();

    // compute baseline goal from last 5 shifts
    _teamGoal = _computeGoalFromHistory();
    notifyListeners();
  }

  Future<void> _persistServers() async =>
      Storage.serversBox.put('list', _servers.map((s) => s.toMap()).toList());
  Future<void> _persistTotals() async =>
      Storage.totalsBox.put('totals', _totals);
  Future<void> _persistHistory() async =>
      Storage.shiftsBox.put('list', _history.map((h) => h.toMap()).toList());
  Future<void> _persistProfiles() async {
    final pb = Storage.profilesBox;
    for (final e in _profiles.entries) {
      await pb.put(e.key, e.value.toMap());
    }
  }

  Future<void> _persistSettings() async =>
      Storage.settingsBox.put('gamification', settings.toMap());

  Future<void> _saveLastEndedSnapshot(Map<String, dynamic>? snap) async {
    _lastEndedSnapshot = snap;
    if (snap == null) {
      await Storage.settingsBox.delete('lastEndedSnapshot');
    } else {
      await Storage.settingsBox.put('lastEndedSnapshot', snap);
    }
  }

  Future<void> addServer(String name) async {
    final s = Server(id: _randId(), name: name.trim());
    _servers.add(s);
    _profiles[s.id] = ServerProfile();
    await _persistServers();
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> renameServer(String id, String newName) async {
    final s = serverById(id);
    if (s == null) return;
    s.name = newName.trim();
    await _persistServers();
    notifyListeners();
  }

  Future<void> removeServer(String id) async {
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
  }

  String _computeShiftType(DateTime t) {
    final hm = t.hour * 60 + t.minute;
    if (hm >= 15 * 60 + 30) return 'Dinner'; // >= 3:30 PM
    if (hm >= 11 * 60) return 'Lunch';       // >= 11:00 AM
    return 'Other';
  }

  int _computeGoalFromHistory() {
    if (_history.isEmpty) return 100; // starter goal
    final last = _history.take(5).toList();
    final avg = last
        .map((r) => r.counts.values.fold<int>(0, (a, b) => a + b))
        .fold<int>(0, (a, b) => a + b) /
        last.length;
    final g = (avg * 1.1).round();
    return (g / 10).round() * 10; // nearest 10
  }

  Future<void> startNewShift({
    required String label,        // UI may pass text; we override based on clock
    required List<String> workingIds,
    DateTime? start,
  }) async {
    _shiftActive = true;
    final now = start ?? DateTime.now();
    _shiftType = _computeShiftType(now);
    _shiftLabel = _shiftType;
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

    _teamTotalThisShift = 0;
    _teamGoal = _computeGoalFromHistory();
    await _saveLastEndedSnapshot(null); // starting fresh clears resume
    notifyListeners();
  }

  /// End shift and persist. Also save a reversible snapshot so we can resume.
  Future<void> endShift() async {
    if (!_shiftActive || _shiftStart == null) return;

    final rec = ShiftRecord(
      id: _randId(),
      label: _shiftLabel,
      shiftType: _shiftType,
      start: _shiftStart!,
      counts: Map<String, int>.from(_currentCounts),
    );
    _history.add(rec);

    // update totals + profiles, find MVP
    String? mvpId;
    int mvpScore = -1;

    rec.counts.forEach((id, n) {
      _totals[id] = (_totals[id] ?? 0) + n;

      final prof = _profiles[id] ?? ServerProfile();
      prof.allTimeRuns += n;
      if (n > prof.bestShiftRuns) prof.bestShiftRuns = n;
      _profiles[id] = prof;

      if (n > mvpScore) {
        mvpScore = n;
        mvpId = id;
      }
    });

    if (mvpId != null) {
      final p = _profiles[mvpId]!;
      p.shiftsAsMvp += 1;
      if (!p.achievements.contains('mvp')) p.achievements.add('mvp');
    }

    final teamTotal = rec.counts.values.fold<int>(0, (a, b) => a + b);
    if (teamTotal >= _teamGoal) {
      for (final id in rec.counts.keys) {
        final p = _profiles[id]!;
        if (!p.achievements.contains('team_goal')) {
          p.achievements.add('team_goal');
        }
      }
    }

    await _persistHistory();
    await _persistTotals();
    await _persistProfiles();

    // Save a snapshot for resume
    await _saveLastEndedSnapshot({
      'recordId': rec.id,
      'label': _shiftLabel,
      'shiftType': _shiftType,
      'start': _shiftStart!.toIso8601String(),
      'workingIds': _workingServerIds.toList(),
      'counts': Map<String, int>.from(_currentCounts),
      'streaks': Map<String, int>.from(_currentStreaks),
      'teamGoal': _teamGoal,
      'teamTotal': _teamTotalThisShift,
    });

    // reset live state
    _shiftActive = false;
    _shiftLabel = '';
    _shiftType = 'Other';
    _shiftStart = null;
    _workingServerIds.clear();
    _currentCounts.clear();
    _currentStreaks.clear();
    _teamTotalThisShift = 0;

    notifyListeners();
  }

  /// Resume the last ended shift. Revert history/totals/profiles and restore live state.
  Future<bool> resumeLastShift() async {
    if (_shiftActive || _lastEndedSnapshot == null) return false;

    final snap = _lastEndedSnapshot!;
    final recId = snap['recordId'] as String?;

    // Remove the history record we just ended (if it exists)
    if (recId != null) {
      _history.removeWhere((h) => h.id == recId);
      await _persistHistory();
      // Recompute profiles and totals from history to avoid double counting
      _rebuildTotalsAndProfilesFromHistory();
      await _persistTotals();
      await _persistProfiles();
    }

    // Restore live state
    _shiftActive = true;
    _shiftLabel = (snap['label'] as String?) ?? 'Other';
    _shiftType = (snap['shiftType'] as String?) ?? 'Other';
    _shiftStart = DateTime.tryParse((snap['start'] as String?) ?? '') ?? DateTime.now();

    _workingServerIds
      ..clear()
      ..addAll(((snap['workingIds'] as List?) ?? const <String>[]).cast<String>());

    _currentCounts
      ..clear()
      ..addAll(((snap['counts'] as Map?) ?? const <String, int>{}).cast<String, int>());

    _currentStreaks
      ..clear()
      ..addAll(((snap['streaks'] as Map?) ?? const <String, int>{}).cast<String, int>());

    _teamGoal = (snap['teamGoal'] as int?) ?? _computeGoalFromHistory();
    _teamTotalThisShift = (snap['teamTotal'] as int?) ?? _currentCounts.values.fold(0, (a, b) => a + b);

    await _saveLastEndedSnapshot(null);
    notifyListeners();
    return true;
  }

  /// Delete a shift from history and recompute derived stats.
  Future<void> deleteShift(String id) async {
    _history.removeWhere((h) => h.id == id);
    await _persistHistory();
    _rebuildTotalsAndProfilesFromHistory();
    await _persistTotals();
    await _persistProfiles();
    notifyListeners();
  }

  void _rebuildTotalsAndProfilesFromHistory() {
    _totals.clear();
    // Reset profiles but keep existing objects so we don't lose badges like 'streakBest'
    final ids = _profiles.keys.toList();
    for (final id in ids) {
      final p = _profiles[id] ?? ServerProfile();
      p.allTimeRuns = 0;
      p.bestShiftRuns = 0;
      p.shiftsAsMvp = 0;
      // keep streakBest and achievements that aren't count-based if you like;
      // we will re-award MVP/team_goal from history below.
      p.achievements.remove('mvp');
      p.achievements.remove('team_goal');
      p.achievements.remove('fifty_all_time');
      p.achievements.remove('hundred_all_time');
      _profiles[id] = p;
    }

    for (final rec in _history) {
      // MVP for that record
      String? mvpId;
      int mvpScore = -1;

      rec.counts.forEach((id, n) {
        _totals[id] = (_totals[id] ?? 0) + n;

        final p = _profiles[id] ?? ServerProfile();
        p.allTimeRuns += n;
        if (n > p.bestShiftRuns) p.bestShiftRuns = n;
        _profiles[id] = p;

        if (n > mvpScore) {
          mvpScore = n;
          mvpId = id;
        }
      });

      if (mvpId != null) {
        final p = _profiles[mvpId]!;
        p.shiftsAsMvp += 1;
        if (!p.achievements.contains('mvp')) p.achievements.add('mvp');
      }

      final teamTotal = rec.counts.values.fold<int>(0, (a, b) => a + b);
      if (teamTotal >= _computeGoalFromHistory()) {
        for (final id in rec.counts.keys) {
          final p = _profiles[id]!;
          if (!p.achievements.contains('team_goal')) {
            p.achievements.add('team_goal');
          }
        }
      }
    }

    // Re-award all-time thresholds
    for (final p in _profiles.values) {
      if (p.allTimeRuns >= 50 && !p.achievements.contains('fifty_all_time')) {
        p.achievements.add('fifty_all_time');
      }
      if (p.allTimeRuns >= 100 && !p.achievements.contains('hundred_all_time')) {
        p.achievements.add('hundred_all_time');
      }
    }
  }

  /// Increment with streaks and power-ups.
  void increment(String id) {
    if (!_shiftActive || !_workingServerIds.contains(id)) return;

    final r = Random();
    var delta = 1;
    final pu = rollPowerUp(r);
    if (pu == PowerUp.doublePoint) delta = 2;
    if (pu == PowerUp.bonusFive) delta = 6; // 1 + bonus 5

    _currentCounts[id] = (_currentCounts[id] ?? 0) + delta;
    _teamTotalThisShift += delta;

    // streaks and achievements
    _currentStreaks[id] = (_currentStreaks[id] ?? 0) + 1;
    final sCount = _currentCounts[id]!;
    final prof = _profiles[id] ?? ServerProfile();
    if (_currentStreaks[id]! > prof.streakBest) {
      prof.streakBest = _currentStreaks[id]!;
    }
    if (prof.streakBest >= 3 && !prof.achievements.contains('three_streak')) {
      prof.achievements.add('three_streak');
    }
    if (prof.streakBest >= 5 && !prof.achievements.contains('five_streak')) {
      prof.achievements.add('five_streak');
    }
    if (sCount >= 10 && !prof.achievements.contains('ten_in_shift')) {
      prof.achievements.add('ten_in_shift');
    }
    if (sCount >= 20 && !prof.achievements.contains('twenty_in_shift')) {
      prof.achievements.add('twenty_in_shift');
    }
    final now = DateTime.now();
    if (now.hour >= 23 && !prof.achievements.contains('night_owl')) {
      prof.achievements.add('night_owl');
    }
    _profiles[id] = prof;

    notifyListeners();
  }

  void decrement(String id) {
    if (!_shiftActive || !_workingServerIds.contains(id)) return;
    final current = (_currentCounts[id] ?? 0);
    if (current > 0) {
      _currentCounts[id] = current - 1;
      _teamTotalThisShift = (_teamTotalThisShift - 1).clamp(0, 1 << 31);
    }
    _currentStreaks[id] = 0; // streak broken
    notifyListeners();
  }

  // toggle setting and persist
  Future<void> updateSettings(GamificationSettings s) async {
    settings = s;
    await _persistSettings();
    notifyListeners();
  }

  // history helpers
  List<ShiftRecord> shiftsOnDate(DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);
    return history.where((h) {
      final hd = DateTime(h.start.year, h.start.month, h.start.day);
      return hd == d0;
    }).toList();
  }
}
