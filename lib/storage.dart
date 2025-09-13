import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class _Box {
  final String prefix;
  _Box(this.prefix);

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
  static late _Box serversBox;
  static late _Box totalsBox;
  static late _Box shiftsBox;
  static late _Box profilesBox;
  static late _Box settingsBox;
  static late _Box dayPlanBox;
  static late _Box tapBox; // per-minute tap buckets
  static late _Box tapTimestampsBox; // individual click timestamps
  static late _Box performanceBox; // server performance data
  static late _Box businessDataBox; // monthly business data
  static late _Box performanceSettingsBox; // performance calculation settings
  static late _Box enhancedBusinessDataBox; // enhanced monthly business data with NPS

  static Future<void> init() async {
    serversBox = _Box('servers');
    totalsBox = _Box('totals');
    shiftsBox = _Box('shifts');
    profilesBox = _Box('profiles');
    settingsBox = _Box('settings');
    dayPlanBox = _Box('dayplan');
    tapBox = _Box('taplog');
    tapTimestampsBox = _Box('tapTimestamps');
    performanceBox = _Box('performance');
    businessDataBox = _Box('businessData');
    performanceSettingsBox = _Box('performanceSettings');
    enhancedBusinessDataBox = _Box('enhancedBusinessData');
  }

  // Performance Data Helper Methods
  
  /// Save server performance data
  static Future<void> saveServerPerformance(String serverId, Map<String, dynamic> performanceData) async {
    await performanceBox.put(serverId, performanceData);
  }

  /// Get server performance data
  static Future<Map<String, dynamic>?> getServerPerformance(String serverId) async {
    return await performanceBox.get(serverId);
  }

  /// Save monthly business data
  static Future<void> saveMonthlyBusinessData(String monthKey, Map<String, dynamic> businessData) async {
    await businessDataBox.put(monthKey, businessData);
  }

  /// Get monthly business data
  static Future<Map<String, dynamic>?> getMonthlyBusinessData(String monthKey) async {
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
  static Future<void> savePerformanceSettings(Map<String, dynamic> settings) async {
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

  /// Save enhanced monthly business data (with NPS)
  static Future<void> saveEnhancedMonthlyBusinessData(String monthKey, Map<String, dynamic> enhancedData) async {
    await enhancedBusinessDataBox.put(monthKey, enhancedData);
  }

  /// Get enhanced monthly business data (with NPS)
  static Future<Map<String, dynamic>?> getEnhancedMonthlyBusinessData(String monthKey) async {
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
}
