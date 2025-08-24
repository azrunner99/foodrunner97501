class Server {
  final String id;
  String name;
  String? teamColor;

  Server({
    required this.id,
    required this.name,
    this.teamColor,
  });

  // Add this factory constructor
  factory Server.fromMap(Map<String, dynamic> map) {
    return Server(
      id: map['id'] as String,
      name: map['name'] as String,
      teamColor: map['teamColor'] as String?,
    );
  }

  // Add this method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teamColor': teamColor,
    };
  }
}

class ShiftRecord {
  String id;
  String label;      // “Lunch” or “Dinner”
  String shiftType;  // “Lunch” or “Dinner”
  DateTime start;    // start of that shift
  Map<String, int> counts; // serverId -> runs

  ShiftRecord({
    required this.id,
    required this.label,
    required this.shiftType,
    required this.start,
    required this.counts,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'shiftType': shiftType,
    'start': start.toIso8601String(),
    'counts': counts,
  };
  static ShiftRecord fromMap(Map<String, dynamic> m) => ShiftRecord(
    id: m['id'],
    label: m['label'],
    shiftType: m['shiftType'],
    start: DateTime.parse(m['start']),
    counts: Map<String, int>.from((m['counts'] as Map).map((k, v) => MapEntry(k as String, v as int))),
  );
}

/// Day plan for building both rosters ahead of time.
class DayPlan {
  String ymd; // YYYY-MM-DD
  List<String> lunchRoster;  // server ids
  List<String> dinnerRoster; // server ids
  DayPlan({required this.ymd, required this.lunchRoster, required this.dinnerRoster});
  Map<String, dynamic> toMap() => {'ymd': ymd, 'lunchRoster': lunchRoster, 'dinnerRoster': dinnerRoster};
  static DayPlan fromMap(Map<String, dynamic> m) => DayPlan(
    ymd: m['ymd'], lunchRoster: (m['lunchRoster'] as List).cast<String>(), dinnerRoster: (m['dinnerRoster'] as List).cast<String>(),
  );
}

/// Weekly open/close minutes since midnight, 1=Mon .. 7=Sun
class WeeklyHours {
  final Map<int, int> openMinutes;  // weekday -> minutes since midnight
  final Map<int, int> closeMinutes; // weekday -> minutes since midnight
  WeeklyHours({required this.openMinutes, required this.closeMinutes});
  Map<String, dynamic> toMap() => {
    'open': openMinutes.map((k, v) => MapEntry(k.toString(), v)),
    'close': closeMinutes.map((k, v) => MapEntry(k.toString(), v)),
  };
  static WeeklyHours fromMap(Map<String, dynamic> m) {
    Map<int, int> parse(Map src) => src.map((k, v) => MapEntry(int.parse(k as String), v as int));
    return WeeklyHours(openMinutes: parse(m['open']), closeMinutes: parse(m['close']));
  }

  static WeeklyHours defaults() {
    // Mon-Thu 11:00–23:00, Fri-Sat 11:00–24:00, Sun 11:00–22:00
    final open = <int, int>{for (var d = 1; d <= 7; d++) d: 11 * 60};
    final close = <int, int>{
      1: 23 * 60, 2: 23 * 60, 3: 23 * 60, 4: 23 * 60,
      5: 24 * 60, 6: 24 * 60, 7: 22 * 60,
    };
    return WeeklyHours(openMinutes: open, closeMinutes: close);
  }
}
