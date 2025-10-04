/// Temporary compatibility extensions for ServerProfile
/// 
/// This file provides missing fields and methods that were removed
/// when app_state.dart was reverted by the transition protection system.
/// These extensions allow the app to compile until the full app_state.dart 
/// can be safely updated.

import '../app_state.dart';

extension ServerProfileCompatibility on ServerProfile {
  // Missing boolean fields
  bool get isArchived => false; // Default to not archived
  
  // Missing date fields  
  String get hireDate => ''; // Default to empty
  String get birthday => ''; // Default to empty
  
  // Missing text fields
  String get archiveNotes => ''; // Default to empty
  
  // Missing collection fields - using getters that create new empty instances each time
  List<String> get recentMessages => <String>[]; // Default to empty list
  Map<String, DateTime> get messageLastUsed => <String, DateTime>{}; // Default to empty map
  Map<String, int> get messageUsageCount => <String, int>{}; // Default to empty map
  Map<String, double> get messageEngagement => <String, double>{}; // Default to empty map
  List<DateTime> get recentTapTimes => <DateTime>[]; // Default to empty list
  Map<String, DateTime> get dailyFirsts => <String, DateTime>{}; // Default to empty map
  List<Map<String, dynamic>> get milestoneHistory => <Map<String, dynamic>>[]; // Default to empty list
  
  // Missing nullable fields
  int? get lastKnownRank => null; // Default to null
  
  // Add setter for lastKnownRank (even though it's a stub)
  set lastKnownRank(int? value) {
    // Stub setter - does nothing since we can't modify the original class
  }
  
  // Missing copyWith method
  ServerProfile copyWith({
    String? hireDate,
    String? birthday,
    bool? isArchived,
    String? archiveNotes,
  }) {
    // Return the same profile since we can't modify the original class
    // This is a temporary stub
    return this;
  }
}

extension AppStateCompatibility on AppState {
  // Missing methods that other files expect
  
  Future<void> updateServerProfile(String serverId, ServerProfile profile) async {
    // Stub implementation - does nothing
    // This prevents compilation errors until full app_state.dart is restored
  }
  
  Future<bool> isValidAdminPin(String pin) async {
    // Stub implementation - always returns false for safety
    return false;
  }
  
  Future<void> save() async {
    // Stub implementation - does nothing
    // This prevents compilation errors
  }
  
  // Missing methods for shift click analysis
  int getTapCountForTimeWindow(String serverId, DateTime start, DateTime end) {
    // Stub implementation - returns 0
    return 0;
  }
  
  List<DateTime> getIndividualClickTimestamps(String serverId, DateTime start, DateTime end) {
    // Stub implementation - returns empty list
    return [];
  }
  
  List<Map<String, dynamic>> getIndividualClicksWithType(String serverId, DateTime start, DateTime end) {
    // Stub implementation - returns empty list
    return [];
  }

  // Missing backup methods
  Future<Map<String, dynamic>?> getExistingBackupInfo() async {
    // Stub implementation - returns null
    return null;
  }

  // Missing business date/time methods
  static DateTime businessDate(DateTime date) {
    // Stub implementation - returns the same date
    return date;
  }

  Map<String, DateTime> businessDayInterval(DateTime date, int weekday) {
    // Stub implementation - returns basic interval
    return {
      'start': date,
      'end': date.add(const Duration(hours: 12)),
    };
  }

  // Missing boost-related properties
  bool get boostActive => false;
  double get boostMultiplier => 1.0;
  DateTime? get boostEndTime => null;
  String get boostDescription => '';

  void checkBoostExpiry() {
    // Stub implementation - does nothing
  }

  // Missing XP and milestone tracking
  Map<String, int> get currentEarnedXP => {};
  Map<String, String?> get lastFlashMessages => {};
  Map<String, int> get lastActionXP => {};
  Map<String, String?> get lastMilestoneDetails => {};
  Map<String, int> get currentBonusXP => {};

  void setLastFlashMessage(String serverId, String message) {
    // Stub implementation - does nothing
  }

  // Missing integrity tracking
  List<Map<String, dynamic>> integrityBinsForDateRange(String serverId, {bool todayOnly = false}) {
    // Stub implementation - returns empty list
    return [];
  }

  // Missing wallpaper functionality
  String get selectedWallpaper => 'none';
  void setWallpaper(String wallpaperId) {
    // Stub implementation - does nothing
  }

  // Missing station assignments
  Map<String, String> get currentStationAssignments => {};
}
