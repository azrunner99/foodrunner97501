import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Represents a station type with name, abbreviation, and number of sections
class StationType {
  final String name;
  final String abbreviation;
  final int sections;

  StationType({
    required this.name,
    required this.abbreviation,
    required this.sections,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'abbreviation': abbreviation,
        'sections': sections,
      };

  factory StationType.fromJson(Map<String, dynamic> json) => StationType(
        name: json['name'],
        abbreviation: json['abbreviation'],
        sections: json['sections'],
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StationType &&
        other.name == name &&
        other.abbreviation == abbreviation &&
        other.sections == sections;
  }

  @override
  int get hashCode => name.hashCode ^ abbreviation.hashCode ^ sections.hashCode;

  @override
  String toString() => 'StationType(name: $name, abbreviation: $abbreviation, sections: $sections)';
}

/// Load station types from SharedPreferences
Future<List<StationType>> loadStationTypes() async {
  final prefs = await SharedPreferences.getInstance();
  const prefsKey = 'station_types';
  final jsonString = prefs.getString(prefsKey);
  if (jsonString != null) {
    final List decoded = json.decode(jsonString);
    return decoded
        .map((e) => StationType.fromJson(e))
        .cast<StationType>()
        .toList();
  }
  return [];
}