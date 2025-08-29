/// Helper to load section assignments from SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<Map<String, String?>> loadSectionAssignments(bool isLunch) async {
  final prefs = await SharedPreferences.getInstance();
  final key = isLunch ? 'lunchStationSection' : 'dinnerStationSection';
  final sectionJson = prefs.getString(key);
  return sectionJson != null
      ? Map<String, String?>.from(json.decode(sectionJson))
      : {};
}
