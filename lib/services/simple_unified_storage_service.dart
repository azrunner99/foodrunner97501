import 'dart:convert';
import '../models.dart';
import '../utils/log.dart';

/// Simple Unified Storage Service
/// 
/// This is a simplified version that provides the interface for unified storage
/// without requiring the generated Drift code. It can be used for testing and
/// development before the full migration is complete.
class SimpleUnifiedStorageService {
  static SimpleUnifiedStorageService? _instance;
  static SimpleUnifiedStorageService get instance => _instance ??= SimpleUnifiedStorageService._();
  
  SimpleUnifiedStorageService._();
  
  bool _isInitialized = false;
  
  // In-memory storage for testing
  final List<Server> _servers = [];
  final List<ShiftRecord> _shifts = [];
  final Map<String, Map<String, dynamic>> _profiles = {};
  final List<Map<String, dynamic>> _npsFeedback = [];
  final List<Map<String, dynamic>> _monthlyReports = [];
  final Map<String, dynamic> _settings = {};
  final List<Map<String, dynamic>> _performanceData = [];
  final List<Map<String, dynamic>> _businessData = [];
  
  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      d('[SimpleUnifiedStorageService] Initializing...');
      _isInitialized = true;
      d('[SimpleUnifiedStorageService] Initialized successfully');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error initializing: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // SERVER OPERATIONS
  // ============================================================================
  
  /// Get all servers
  Future<List<Server>> getAllServers() async {
    await _ensureInitialized();
    return List.from(_servers);
  }
  
  /// Save a server
  Future<void> saveServer(Server server) async {
    await _ensureInitialized();
    
    try {
      final existingIndex = _servers.indexWhere((s) => s.id == server.id);
      if (existingIndex != -1) {
        _servers[existingIndex] = server;
      } else {
        _servers.add(server);
      }
      d('[SimpleUnifiedStorageService] Server saved: ${server.name}');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving server: $e');
      rethrow;
    }
  }
  
  /// Delete a server
  Future<void> deleteServer(String serverId) async {
    await _ensureInitialized();
    
    try {
      _servers.removeWhere((s) => s.id == serverId);
      d('[SimpleUnifiedStorageService] Server deleted: $serverId');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error deleting server: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // SHIFT OPERATIONS
  // ============================================================================
  
  /// Get all shifts
  Future<List<ShiftRecord>> getAllShifts() async {
    await _ensureInitialized();
    return List.from(_shifts);
  }
  
  /// Save a shift
  Future<void> saveShift(ShiftRecord shift) async {
    await _ensureInitialized();
    
    try {
      final existingIndex = _shifts.indexWhere((s) => s.id == shift.id);
      if (existingIndex != -1) {
        _shifts[existingIndex] = shift;
      } else {
        _shifts.add(shift);
      }
      d('[SimpleUnifiedStorageService] Shift saved: ${shift.id}');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving shift: $e');
      rethrow;
    }
  }
  
  /// Delete a shift
  Future<void> deleteShift(String shiftId) async {
    await _ensureInitialized();
    
    try {
      _shifts.removeWhere((s) => s.id == shiftId);
      d('[SimpleUnifiedStorageService] Shift deleted: $shiftId');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error deleting shift: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================
  
  /// Get all server profiles
  Future<List<Map<String, dynamic>>> getAllServerProfiles() async {
    await _ensureInitialized();
    return _profiles.entries.map((e) => {
      'serverId': e.key,
      ...e.value,
    }).toList();
  }
  
  /// Save a server profile
  Future<void> saveServerProfile(String serverId, Map<String, dynamic> profile) async {
    await _ensureInitialized();
    
    try {
      _profiles[serverId] = Map<String, dynamic>.from(profile);
      d('[SimpleUnifiedStorageService] Server profile saved: $serverId');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving server profile: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // NPS OPERATIONS
  // ============================================================================
  
  /// Save NPS feedback
  Future<void> saveNPSFeedback(Map<String, dynamic> feedback) async {
    await _ensureInitialized();
    
    try {
      _npsFeedback.add(Map<String, dynamic>.from(feedback));
      d('[SimpleUnifiedStorageService] NPS feedback saved');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving NPS feedback: $e');
      rethrow;
    }
  }
  
  /// Get NPS feedback for a server
  Future<List<Map<String, dynamic>>> getNPSFeedback(String serverId) async {
    await _ensureInitialized();
    return _npsFeedback.where((f) => f['server_id'] == serverId).toList();
  }
  
  /// Get all NPS feedback
  Future<List<Map<String, dynamic>>> getAllNPSFeedback() async {
    await _ensureInitialized();
    return List.from(_npsFeedback);
  }
  
  /// Save monthly report
  Future<void> saveMonthlyReport(Map<String, dynamic> report) async {
    await _ensureInitialized();
    
    try {
      _monthlyReports.add(Map<String, dynamic>.from(report));
      d('[SimpleUnifiedStorageService] Monthly report saved');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving monthly report: $e');
      rethrow;
    }
  }
  
  /// Get monthly reports for a server
  Future<List<Map<String, dynamic>>> getMonthlyReports(String serverId) async {
    await _ensureInitialized();
    return _monthlyReports.where((r) => r['server_id'] == serverId).toList();
  }
  
  // ============================================================================
  // SETTINGS OPERATIONS
  // ============================================================================
  
  /// Get a setting value
  Future<T?> getSetting<T>(String key) async {
    await _ensureInitialized();
    return _settings[key] as T?;
  }
  
  /// Set a setting value
  Future<void> setSetting(String key, dynamic value) async {
    await _ensureInitialized();
    
    try {
      if (value == null) {
        _settings.remove(key);
      } else {
        _settings[key] = value;
      }
      d('[SimpleUnifiedStorageService] Setting saved: $key');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving setting: $e');
      rethrow;
    }
  }
  
  /// Get all settings
  Future<Map<String, dynamic>> getAllSettings() async {
    await _ensureInitialized();
    return Map.from(_settings);
  }
  
  // ============================================================================
  // PERFORMANCE DATA OPERATIONS
  // ============================================================================
  
  /// Save performance data
  Future<void> savePerformanceData(String serverId, String dataType, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      _performanceData.add({
        'serverId': serverId,
        'dataType': dataType,
        'dataContent': data,
        'createdAt': DateTime.now().toIso8601String(),
      });
      d('[SimpleUnifiedStorageService] Performance data saved: $serverId/$dataType');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving performance data: $e');
      rethrow;
    }
  }
  
  /// Get performance data for a server
  Future<List<Map<String, dynamic>>> getPerformanceData(String serverId, String dataType) async {
    await _ensureInitialized();
    return _performanceData
        .where((p) => p['serverId'] == serverId && p['dataType'] == dataType)
        .map((p) => p['dataContent'] as Map<String, dynamic>)
        .toList();
  }
  
  // ============================================================================
  // BUSINESS DATA OPERATIONS
  // ============================================================================
  
  /// Save business data
  Future<void> saveBusinessData(String monthYear, String dataType, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      _businessData.add({
        'monthYear': monthYear,
        'dataType': dataType,
        'dataContent': data,
        'createdAt': DateTime.now().toIso8601String(),
      });
      d('[SimpleUnifiedStorageService] Business data saved: $monthYear/$dataType');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error saving business data: $e');
      rethrow;
    }
  }
  
  /// Get business data for a month
  Future<List<Map<String, dynamic>>> getBusinessData(String monthYear, String dataType) async {
    await _ensureInitialized();
    return _businessData
        .where((b) => b['monthYear'] == monthYear && b['dataType'] == dataType)
        .map((b) => b['dataContent'] as Map<String, dynamic>)
        .toList();
  }
  
  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================
  
  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    await _ensureInitialized();
    
    return {
      'servers': _servers.length,
      'shifts': _shifts.length,
      'nps_feedback': _npsFeedback.length,
      'monthly_reports': _monthlyReports.length,
      'profiles': _profiles.length,
      'performance_data': _performanceData.length,
      'business_data': _businessData.length,
    };
  }
  
  /// Clear all data
  Future<void> clearAllData() async {
    await _ensureInitialized();
    
    try {
      _servers.clear();
      _shifts.clear();
      _profiles.clear();
      _npsFeedback.clear();
      _monthlyReports.clear();
      _settings.clear();
      _performanceData.clear();
      _businessData.clear();
      d('[SimpleUnifiedStorageService] All data cleared');
    } catch (e) {
      d('[SimpleUnifiedStorageService] Error clearing data: $e');
      rethrow;
    }
  }
  
  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }
}








