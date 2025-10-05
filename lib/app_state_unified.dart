import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'app_state.dart' show ServerProfile;
import 'services/unified_storage_service.dart';
import 'utils/log.dart';

/// Unified AppState using the new unified storage system
/// 
/// This replaces the previous multi-storage architecture with a single
/// Drift-based storage solution. All data operations now go through
/// the UnifiedStorageService.
class AppStateUnified extends ChangeNotifier {
  static const Uuid _uuid = Uuid();
  
  // Core data
  final List<Server> _servers = [];
  final List<ShiftRecord> _history = [];
  final Map<String, ServerProfile> _profiles = {};
  final Map<String, Map<String, int>> _totals = {};
  final Map<String, Map<String, int>> _pizookieTotals = {};
  
  // Settings
  WeeklyHours _hours = WeeklyHours(openMinutes: {}, closeMinutes: {});
  String _currentShiftType = 'lunch';
  bool _isShiftActive = false;
  String? _currentShiftId;
  
  // Getters
  List<Server> get servers => List.unmodifiable(_servers);
  List<ShiftRecord> get history => List.unmodifiable(_history);
  Map<String, ServerProfile> get profiles => Map.unmodifiable(_profiles);
  Map<String, Map<String, int>> get totals => Map.unmodifiable(_totals);
  Map<String, Map<String, int>> get pizookieTotals => Map.unmodifiable(_pizookieTotals);
  WeeklyHours get hours => _hours;
  String get currentShiftType => _currentShiftType;
  bool get isShiftActive => _isShiftActive;
  String? get currentShiftId => _currentShiftId;
  
  // Unified storage service
  final UnifiedStorageService _storage = UnifiedStorageService.instance;
  
  /// Initialize the app state and load all data
  Future<void> load() async {
    try {
      d('[AppStateUnified] Loading data from unified storage...');
      
      // Initialize unified storage
      await _storage.init();
      
      // Load servers
      _servers.clear();
      _servers.addAll(await _storage.getAllServers());
      d('[AppStateUnified] Loaded ${_servers.length} servers');
      
      // Load shifts
      _history.clear();
      _history.addAll(await _storage.getAllShifts());
      d('[AppStateUnified] Loaded ${_history.length} shifts');
      
      // Load profiles
      _profiles.clear();
      final profiles = await _storage.getAllServerProfiles();
      for (final profile in profiles) {
        _profiles[profile.serverId] = profile;
      }
      d('[AppStateUnified] Loaded ${_profiles.length} profiles');
      
      // Load settings
      final hoursData = await _storage.getSetting<Map<String, dynamic>>('weekly_hours');
      if (hoursData != null) {
        _hours = WeeklyHours.fromMap(hoursData);
      }
      
      final shiftType = await _storage.getSetting<String>('current_shift_type');
      if (shiftType != null) {
        _currentShiftType = shiftType;
      }
      
      final isActive = await _storage.getSetting<bool>('is_shift_active');
      _isShiftActive = isActive ?? false;
      
      final shiftId = await _storage.getSetting<String>('current_shift_id');
      _currentShiftId = shiftId;
      
      // Calculate totals from shift data
      await _calculateTotals();
      
      d('[AppStateUnified] Data loading completed successfully');
      notifyListeners();
      
    } catch (e) {
      d('[AppStateUnified] Error loading data: $e');
      rethrow;
    }
  }
  
  /// Calculate totals from shift data
  Future<void> _calculateTotals() async {
    _totals.clear();
    _pizookieTotals.clear();
    
    for (final shift in _history) {
      for (final entry in shift.counts.entries) {
        final serverId = entry.key;
        final runs = entry.value;
        
        _totals.putIfAbsent(serverId, () => {});
        _totals[serverId]![shift.shiftType] = (_totals[serverId]![shift.shiftType] ?? 0) + runs;
      }
      
      for (final entry in shift.pizookieCounts.entries) {
        final serverId = entry.key;
        final pizookieRuns = entry.value;
        
        _pizookieTotals.putIfAbsent(serverId, () => {});
        _pizookieTotals[serverId]![shift.shiftType] = (_pizookieTotals[serverId]![shift.shiftType] ?? 0) + pizookieRuns;
      }
    }
  }
  
  // ============================================================================
  // SERVER OPERATIONS
  // ============================================================================
  
  /// Add a new server
  Future<void> addServer(Server server) async {
    try {
      _servers.add(server);
      await _storage.saveServer(server);
      d('[AppStateUnified] Server added: ${server.name}');
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error adding server: $e');
      rethrow;
    }
  }
  
  /// Update an existing server
  Future<void> updateServer(Server server) async {
    try {
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        _servers[index] = server;
        await _storage.saveServer(server);
        d('[AppStateUnified] Server updated: ${server.name}');
        notifyListeners();
      }
    } catch (e) {
      d('[AppStateUnified] Error updating server: $e');
      rethrow;
    }
  }
  
  /// Delete a server
  Future<void> deleteServer(String serverId) async {
    try {
      _servers.removeWhere((s) => s.id == serverId);
      await _storage.deleteServer(serverId);
      d('[AppStateUnified] Server deleted: $serverId');
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error deleting server: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // SHIFT OPERATIONS
  // ============================================================================
  
  /// Start a new shift
  Future<void> startShift(String shiftType) async {
    try {
      if (_isShiftActive) {
        throw Exception('Shift is already active');
      }
      
      _currentShiftType = shiftType;
      _isShiftActive = true;
      _currentShiftId = _uuid.v4();
      
      await _storage.setSetting('current_shift_type', shiftType);
      await _storage.setSetting('is_shift_active', true);
      await _storage.setSetting('current_shift_id', _currentShiftId);
      
      d('[AppStateUnified] Shift started: $shiftType');
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error starting shift: $e');
      rethrow;
    }
  }
  
  /// End the current shift
  Future<void> endShift() async {
    try {
      if (!_isShiftActive) {
        throw Exception('No active shift to end');
      }
      
      if (_currentShiftId != null) {
        final shift = ShiftRecord(
          id: _currentShiftId!,
          label: '${_currentShiftType.toUpperCase()} - ${DateTime.now().toString().split(' ')[0]}',
          shiftType: _currentShiftType,
          start: DateTime.now(),
          counts: _getCurrentShiftCounts(),
          pizookieCounts: _getCurrentPizookieCounts(),
        );
        
        _history.add(shift);
        await _storage.saveShift(shift);
        await _calculateTotals();
        
        d('[AppStateUnified] Shift ended and saved: ${shift.id}');
      }
      
      _isShiftActive = false;
      _currentShiftId = null;
      
      await _storage.setSetting('is_shift_active', false);
      await _storage.setSetting('current_shift_id', null);
      
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error ending shift: $e');
      rethrow;
    }
  }
  
  /// Add a food run for a server
  Future<void> addRun(String serverId, {bool isPizookie = false}) async {
    try {
      if (!_isShiftActive) {
        throw Exception('No active shift');
      }
      
      // This would typically update some temporary storage
      // For now, we'll just log the action
      d('[AppStateUnified] Run added for server $serverId (pizookie: $isPizookie)');
      
      // In a real implementation, you'd update temporary counters
      // and save them when the shift ends
      
    } catch (e) {
      d('[AppStateUnified] Error adding run: $e');
      rethrow;
    }
  }
  
  /// Get current shift counts (placeholder)
  Map<String, int> _getCurrentShiftCounts() {
    // This would return the actual counts from the current shift
    // For now, return empty map
    return {};
  }
  
  /// Get current pizookie counts (placeholder)
  Map<String, int> _getCurrentPizookieCounts() {
    // This would return the actual pizookie counts from the current shift
    // For now, return empty map
    return {};
  }
  
  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================
  
  /// Update server profile
  Future<void> updateServerProfile(String serverId, ServerProfile profile) async {
    try {
      _profiles[serverId] = profile;
      await _storage.saveServerProfile(serverId, profile);
      d('[AppStateUnified] Server profile updated: $serverId');
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error updating server profile: $e');
      rethrow;
    }
  }
  
  /// Get server profile
  ServerProfile? getServerProfile(String serverId) {
    return _profiles[serverId];
  }
  
  // ============================================================================
  // SETTINGS OPERATIONS
  // ============================================================================
  
  /// Update weekly hours
  Future<void> updateWeeklyHours(WeeklyHours hours) async {
    try {
      _hours = hours;
      await _storage.setSetting('weekly_hours', hours.toMap());
      d('[AppStateUnified] Weekly hours updated');
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error updating weekly hours: $e');
      rethrow;
    }
  }
  
  /// Update current shift type
  Future<void> updateCurrentShiftType(String shiftType) async {
    try {
      _currentShiftType = shiftType;
      await _storage.setSetting('current_shift_type', shiftType);
      d('[AppStateUnified] Current shift type updated: $shiftType');
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error updating shift type: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // UTILITY OPERATIONS
  // ============================================================================
  
  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      return await _storage.getDatabaseStats();
    } catch (e) {
      d('[AppStateUnified] Error getting database stats: $e');
      return {};
    }
  }
  
  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      await _storage.clearAllData();
      _servers.clear();
      _history.clear();
      _profiles.clear();
      _totals.clear();
      _pizookieTotals.clear();
      _hours = WeeklyHours(openMinutes: {}, closeMinutes: {});
      _currentShiftType = 'lunch';
      _isShiftActive = false;
      _currentShiftId = null;
      
      d('[AppStateUnified] All data cleared');
      notifyListeners();
    } catch (e) {
      d('[AppStateUnified] Error clearing data: $e');
      rethrow;
    }
  }
  
  /// Export data for backup
  Future<Map<String, dynamic>> exportData() async {
    try {
      return {
        'servers': _servers.map((s) => s.toMap()).toList(),
        'shifts': _history.map((s) => s.toMap()).toList(),
        'profiles': _profiles.map((k, v) => MapEntry(k, v.toMap())),
        'totals': _totals,
        'pizookieTotals': _pizookieTotals,
        'hours': _hours.toMap(),
        'currentShiftType': _currentShiftType,
        'isShiftActive': _isShiftActive,
        'currentShiftId': _currentShiftId,
      };
    } catch (e) {
      d('[AppStateUnified] Error exporting data: $e');
      return {};
    }
  }
}


