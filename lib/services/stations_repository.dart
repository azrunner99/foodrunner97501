import '../storage.dart';

/// Repository for managing station type assignments and persistence
class StationsRepository {
  /// Get lunch station type assignments
  static Future<Map<String, dynamic>> getLunchStationType() async {
    return await Storage.getLunchStationType();
  }

  /// Set lunch station type assignments
  static Future<void> setLunchStationType(Map<String, dynamic> stationType) async {
    await Storage.setLunchStationType(stationType);
  }

  /// Get dinner station type assignments
  static Future<Map<String, dynamic>> getDinnerStationType() async {
    return await Storage.getDinnerStationType();
  }

  /// Set dinner station type assignments
  static Future<void> setDinnerStationType(Map<String, dynamic> stationType) async {
    await Storage.setDinnerStationType(stationType);
  }

  /// Get station type assignments for a specific shift type
  static Future<Map<String, dynamic>> getStationTypeForShift(String shiftType) async {
    if (shiftType.toLowerCase() == 'lunch') {
      return await getLunchStationType();
    } else {
      return await getDinnerStationType();
    }
  }

  /// Set station type assignments for a specific shift type
  static Future<void> setStationTypeForShift(String shiftType, Map<String, dynamic> stationType) async {
    if (shiftType.toLowerCase() == 'lunch') {
      await setLunchStationType(stationType);
    } else {
      await setDinnerStationType(stationType);
    }
  }

  /// Get lunch station section assignments
  static Future<Map<String, dynamic>> getLunchStationSection() async {
    return await Storage.getLunchStationSection();
  }

  /// Get dinner station section assignments
  static Future<Map<String, dynamic>> getDinnerStationSection() async {
    return await Storage.getDinnerStationSection();
  }

  /// Get station section assignments for a specific shift type
  static Future<Map<String, dynamic>> getStationSectionForShift(String shiftType) async {
    if (shiftType.toLowerCase() == 'lunch') {
      return await getLunchStationSection();
    } else {
      return await getDinnerStationSection();
    }
  }
}