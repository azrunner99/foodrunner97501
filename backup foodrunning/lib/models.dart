import 'dart:convert';

class Server {
  final String id;
  String name;

  Server({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  static Server fromMap(Map map) =>
      Server(id: map['id'] as String, name: map['name'] as String);
}

class ShiftRecord {
  final String id;               // generated id
  final String label;            // e.g., "Lunch", "Dinner", "Other"
  final String shiftType;        // "Lunch" | "Dinner" | "Other"
  final DateTime start;
  final Map<String, int> counts; // serverId -> runs

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
        'counts': jsonEncode(counts),
      };

  static ShiftRecord fromMap(Map map) => ShiftRecord(
        id: map['id'] as String,
        label: map['label'] as String,
        shiftType: (map['shiftType'] as String?) ??
            _inferTypeFromLabel(map['label'] as String?),
        start: DateTime.parse(map['start'] as String),
        counts: Map<String, int>.from(jsonDecode(map['counts'] as String)),
      );

  static String _inferTypeFromLabel(String? label) {
    final l = (label ?? '').toLowerCase();
    if (l.contains('lunch')) return 'Lunch';
    if (l.contains('dinner')) return 'Dinner';
    return 'Other';
  }
}
