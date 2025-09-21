import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/log.dart';

/// Public box API wrapper to avoid exposing private types in public API
class Box {
  final String prefix;
  Box(this.prefix);

  Future<dynamic> get(String key) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('$prefix::$key');
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> put(String key, dynamic value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('$prefix::$key', jsonEncode(value));
  }

  Future<void> delete(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$prefix::$key');
  }
}

class Storage {
  // Application data schema version. Bump when making breaking storage changes.
  static const int currentSchemaVersion = 1;

  static late Box serversBox;
  static late Box totalsBox;
  static late Box shiftsBox;
  static late Box profilesBox;
  static late Box settingsBox;
  static late Box dayPlanBox;
  static late Box tapBox; // per-minute tap buckets
  static late Box tapTimestampsBox; // individual click timestamps
  static late Box performanceBox; // server performance data
  static late Box businessDataBox; // monthly business data
  static late Box performanceSettingsBox; // performance calculation settings
  static late Box enhancedBusinessDataBox; // enhanced monthly business data with NPS
  static late Box stationsBox; // station assignments and types
  static late Box assetsBox; // avatar and banner paths

  static Future<void> init() async {
    serversBox = Box('servers');
    totalsBox = Box('totals');
    shiftsBox = Box('shifts');
    profilesBox = Box('profiles');
    settingsBox = Box('settings');
    dayPlanBox = Box('dayplan');
    tapBox = Box('taplog');
    tapTimestampsBox = Box('tapTimestamps');
    performanceBox = Box('performance');
    businessDataBox = Box('businessData');
    performanceSettingsBox = Box('performanceSettings');
    enhancedBusinessDataBox = Box('enhancedBusinessData');
    stationsBox = Box('stations');
    assetsBox = Box('assets');
  }

  /// Export a JSON snapshot for the given box prefixes into docs/backups/autosafe.
  /// Returns the written file path, or null if write failed.
  static Future<String?> exportBoxes(List<String> prefixes) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final allKeys = sp.getKeys();
      final snapshot = <String, Map<String, dynamic>>{};

      for (final prefix in prefixes) {
        final pfx = '$prefix::';
        final boxMap = <String, dynamic>{};
        for (final key in allKeys.where((k) => k.startsWith(pfx))) {
          final raw = sp.getString(key);
          if (raw != null) {
            try {
              boxMap[key.substring(pfx.length)] = jsonDecode(raw);
            } catch (_) {
              // keep raw string if decode fails
              boxMap[key.substring(pfx.length)] = raw;
            }
          }
        }
        snapshot[prefix] = boxMap;
      }

      if (kIsWeb) {
        d('[SCHEMA] exportBoxes skipped on web environment');
        return null;
      }

      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      final dir = Directory('docs/backups/autosafe');
      await dir.create(recursive: true);
      final path = '${dir.path}${Platform.pathSeparator}schema-$ts.json';
      final file = File(path);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(snapshot));
      d('[SCHEMA] Exported snapshot to $path');
      return path;
    } catch (e, st) {
      d('[SCHEMA] Warning: exportBoxes failed: $e\n$st');
      return null;
    }
  }

  // Settings / Schema helpers

  /// Returns the stored schema version, or 0 if none stored yet.
  static Future<int> getSchemaVersion() async {
    final v = await settingsBox.get('schemaVersion');
    if (v is int) return v;
    // If stored as string/num accidentally, try to parse
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  /// Persists the given schema version to settings.
  static Future<void> setSchemaVersion(int version) async {
    await settingsBox.put('schemaVersion', version);
  }

  // Performance Data Helper Methods

  /// Save server performance data
  static Future<void> saveServerPerformance(
      String serverId, Map<String, dynamic> performanceData) async {
    await performanceBox.put(serverId, performanceData);
  }

  /// Get server performance data
  static Future<Map<String, dynamic>?> getServerPerformance(
      String serverId) async {
    return await performanceBox.get(serverId);
  }

  /// Save monthly business data
  static Future<void> saveMonthlyBusinessData(
      String monthKey, Map<String, dynamic> businessData) async {
    await businessDataBox.put(monthKey, businessData);
  }

  /// Get monthly business data
  static Future<Map<String, dynamic>?> getMonthlyBusinessData(
      String monthKey) async {
    return await businessDataBox.get(monthKey);
  }

  /// Get all monthly business data keys
  static Future<List<String>> getAllBusinessDataKeys() async {
    final sp = await SharedPreferences.getInstance();
    final allKeys = sp.getKeys();
    return allKeys
        .where((key) => key.startsWith('businessData::'))
        .map((key) => key.substring('businessData::'.length))
        .toList();
  }

  /// Save performance calculation settings
  static Future<void> savePerformanceSettings(
      Map<String, dynamic> settings) async {
    await performanceSettingsBox.put('main', settings);
  }

  /// Get performance calculation settings
  static Future<Map<String, dynamic>?> getPerformanceSettings() async {
    return await performanceSettingsBox.get('main');
  }

  /// Get the last business data entry date
  static Future<DateTime?> getLastBusinessDataEntryDate() async {
    final keys = await getAllBusinessDataKeys();
    if (keys.isEmpty) return null;

    // Sort keys to find the most recent
    keys.sort();
    final latestKey = keys.last;
    final data = await getMonthlyBusinessData(latestKey);

    if (data != null && data['entryDate'] != null) {
      return DateTime.parse(data['entryDate']);
    }

    return null;
  }

  /// Check if business data entry is due (30+ days since last entry)
  static Future<bool> isBusinessDataEntryDue() async {
    final lastEntry = await getLastBusinessDataEntryDate();
    if (lastEntry == null) return true; // No previous entry, definitely due

    final daysSinceLastEntry = DateTime.now().difference(lastEntry).inDays;
    return daysSinceLastEntry >= 30;
  }

  /// Generate a month key for business data storage (YYYY-MM format)
  static String generateMonthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Generate date range key for custom date ranges (YYYY-MM-DD_to_YYYY-MM-DD format)
  static String generateDateRangeKey(DateTime startDate, DateTime endDate) {
    final start =
        '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final end =
        '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    return '${start}_to_$end';
  }

  /// Get all month keys that overlap with a date range
  static List<String> getOverlappingMonthKeys(
      DateTime startDate, DateTime endDate) {
    final monthKeys = <String>[];
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final end = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(end) || current == end) {
      monthKeys.add(generateMonthKey(current));
      current = DateTime(current.year, current.month + 1, 1);
    }

    return monthKeys;
  }

  /// Check if a date range has any existing data
  static Future<List<String>> getExistingDataForDateRange(
      DateTime startDate, DateTime endDate) async {
    final overlappingMonths = getOverlappingMonthKeys(startDate, endDate);
    final existingData = <String>[];

    for (final monthKey in overlappingMonths) {
      final data = await getMonthlyBusinessData(monthKey);
      if (data != null) {
        existingData.add(monthKey);
      }
    }

    return existingData;
  }

  /// Get summary of existing data for date range
  static Future<Map<String, dynamic>> getDateRangeDataSummary(
      DateTime startDate, DateTime endDate) async {
    final overlappingMonths = getOverlappingMonthKeys(startDate, endDate);
    final summary = <String, dynamic>{
      'monthsInRange': overlappingMonths.length,
      'monthsWithData': 0,
      'totalGuests': 0.0,
      'totalSales': 0.0,
      'monthDetails': <String, Map<String, dynamic>>{},
    };

    for (final monthKey in overlappingMonths) {
      final data = await getMonthlyBusinessData(monthKey);
      if (data != null) {
        summary['monthsWithData']++;
        summary['totalGuests'] +=
            (data['totalGuestCount'] as num?)?.toDouble() ?? 0.0;
        summary['totalSales'] +=
            (data['totalSales'] as num?)?.toDouble() ?? 0.0;
        summary['monthDetails'][monthKey] = {
          'guests': data['totalGuestCount'],
          'sales': data['totalSales'],
          'entryDate': data['entryDate'],
        };
      }
    }

    return summary;
  }

  /// Save enhanced monthly business data (with NPS)
  static Future<void> saveEnhancedMonthlyBusinessData(
      String monthKey, Map<String, dynamic> enhancedData) async {
    await enhancedBusinessDataBox.put(monthKey, enhancedData);
  }

  /// Get enhanced monthly business data (with NPS)
  static Future<Map<String, dynamic>?> getEnhancedMonthlyBusinessData(
      String monthKey) async {
    return await enhancedBusinessDataBox.get(monthKey);
  }

  /// Get all enhanced business data keys
  static Future<List<String>> getAllEnhancedBusinessDataKeys() async {
    final sp = await SharedPreferences.getInstance();
    final allKeys = sp.getKeys();
    return allKeys
        .where((key) => key.startsWith('enhancedBusinessData::'))
        .map((key) => key.substring('enhancedBusinessData::'.length))
        .toList();
  }

  /// Persist station keys to settings box
  static Future<void> persistStationKeys(
      Map<String, dynamic> stationKeys) async {
    for (final key in stationKeys.keys) {
      await settingsBox.put(key, stationKeys[key]);
    }
  }

  /// Get admin PIN with default fallback
  static Future<String> getAdminPin() async {
    final pin = await settingsBox.get('adminPin');
    return pin ?? '0000'; // Default PIN if none set
  }

  /// Set admin PIN
  static Future<void> setAdminPin(String pin) async {
    await settingsBox.put('adminPin', pin);
  }

  // Station Data Helper Methods

  /// Get lunch station type data
  static Future<Map<String, dynamic>> getLunchStationType() async {
    final data = await stationsBox.get('lunchStationType');
    return data ?? {};
  }

  /// Set lunch station type data
  static Future<void> setLunchStationType(Map<String, dynamic> stationType) async {
    await stationsBox.put('lunchStationType', stationType);
  }

  /// Get dinner station type data
  static Future<Map<String, dynamic>> getDinnerStationType() async {
    final data = await stationsBox.get('dinnerStationType');
    return data ?? {};
  }

  /// Set dinner station type data
  static Future<void> setDinnerStationType(Map<String, dynamic> stationType) async {
    await stationsBox.put('dinnerStationType', stationType);
  }

  /// Get lunch station section data
  static Future<Map<String, dynamic>> getLunchStationSection() async {
    final data = await stationsBox.get('lunchStationSection');
    return data ?? {};
  }

  /// Set lunch station section data
  static Future<void> setLunchStationSection(Map<String, dynamic> stationSection) async {
    await stationsBox.put('lunchStationSection', stationSection);
  }

  /// Get dinner station section data
  static Future<Map<String, dynamic>> getDinnerStationSection() async {
    final data = await stationsBox.get('dinnerStationSection');
    return data ?? {};
  }

  /// Set dinner station section data
  static Future<void> setDinnerStationSection(Map<String, dynamic> stationSection) async {
    await stationsBox.put('dinnerStationSection', stationSection);
  }

  // Asset Data Helper Methods

  /// Get avatar path for a server
  static Future<String?> getAvatarPath(String serverId) async {
    return await assetsBox.get('avatar_$serverId');
  }

  /// Set avatar path for a server
  static Future<void> setAvatarPath(String serverId, String path) async {
    await assetsBox.put('avatar_$serverId', path);
  }

  /// Get banner path for a server
  static Future<String?> getBannerPath(String serverId) async {
    return await assetsBox.get('banner_$serverId');
  }

  /// Set banner path for a server
  static Future<void> setBannerPath(String serverId, String path) async {
    await assetsBox.put('banner_$serverId', path);
  }

  // Migration Helper Methods

  /// Migrate raw SharedPreferences keys to Storage boxes
  static Future<void> migrateRawKeys() async {
    final sp = await SharedPreferences.getInstance();
    final allKeys = sp.getKeys();

    // Migrate station data
    if (allKeys.contains('lunchStationType')) {
      final value = sp.getString('lunchStationType');
      if (value != null) {
        final data = jsonDecode(value);
        await setLunchStationType(data);
        await sp.remove('lunchStationType');
      }
    }

    if (allKeys.contains('dinnerStationType')) {
      final value = sp.getString('dinnerStationType');
      if (value != null) {
        final data = jsonDecode(value);
        await setDinnerStationType(data);
        await sp.remove('dinnerStationType');
      }
    }

    if (allKeys.contains('lunchStationSection')) {
      final value = sp.getString('lunchStationSection');
      if (value != null) {
        final data = jsonDecode(value);
        await setLunchStationSection(data);
        await sp.remove('lunchStationSection');
      }
    }

    if (allKeys.contains('dinnerStationSection')) {
      final value = sp.getString('dinnerStationSection');
      if (value != null) {
        final data = jsonDecode(value);
        await setDinnerStationSection(data);
        await sp.remove('dinnerStationSection');
      }
    }

    // Migrate avatar and banner data
    final avatarKeys = allKeys.where((key) => key.startsWith('avatar_')).toList();
    for (final key in avatarKeys) {
      final value = sp.getString(key);
      if (value != null) {
        final serverId = key.substring('avatar_'.length);
        await setAvatarPath(serverId, value);
        await sp.remove(key);
      }
    }

    final bannerKeys = allKeys.where((key) => key.startsWith('banner_')).toList();
    for (final key in bannerKeys) {
      final value = sp.getString(key);
      if (value != null) {
        final serverId = key.substring('banner_'.length);
        await setBannerPath(serverId, value);
        await sp.remove(key);
      }
    }
  }
}
