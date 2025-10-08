import 'dart:async';
import '../app_state.dart';
import '../utils/log.dart';
import 'database_sync_service.dart';

/// Periodic background database synchronization service
/// 
/// Runs automatic validation and sync every N minutes to ensure
/// all databases (AppState, NPS, UnifiedStorage) remain in sync.
/// 
/// Features:
/// - Configurable sync interval (default: 5 minutes)
/// - Automatic issue detection
/// - Optional auto-fix
/// - Detailed logging
/// 
/// Phase 3.2 of Database Unification Blueprint
class PeriodicSyncService {
  static PeriodicSyncService? _instance;
  static PeriodicSyncService get instance => _instance ??= PeriodicSyncService._();
  
  PeriodicSyncService._();
  
  Timer? _syncTimer;
  AppState? _appState;
  bool _isRunning = false;
  bool _autoFixEnabled = true;
  Duration _syncInterval = const Duration(minutes: 5);
  
  DateTime? _lastSyncTime;
  DateTime? _lastIssueDetectedTime;
  int _totalSyncsRun = 0;
  int _totalIssuesFixed = 0;
  Map<String, dynamic>? _lastSyncResult;
  
  /// Initialize the periodic sync service
  /// 
  /// [appState] - The AppState instance to monitor
  /// [autoFixEnabled] - Whether to automatically fix issues (default: true)
  /// [syncInterval] - How often to run sync checks (default: 5 minutes)
  void initialize(
    AppState appState, {
    bool autoFixEnabled = true,
    Duration? syncInterval,
  }) {
    _appState = appState;
    _autoFixEnabled = autoFixEnabled;
    if (syncInterval != null) {
      _syncInterval = syncInterval;
    }
    
    print('[PeriodicSyncService] Initialized (interval: ${_syncInterval.inMinutes}min, autoFix: $_autoFixEnabled)');
  }
  
  /// Start the periodic sync timer
  void start() {
    if (_isRunning) {
      print('[PeriodicSyncService] Already running');
      return;
    }
    
    if (_appState == null) {
      print('[PeriodicSyncService] Cannot start - AppState not set. Call initialize() first.');
      return;
    }
    
    _isRunning = true;
    
    // Run initial sync immediately
    _runSync();
    
    // Schedule periodic syncs
    _syncTimer = Timer.periodic(_syncInterval, (_) => _runSync());
    
        print('[PeriodicSyncService] ✅ Started (checking every ${_syncInterval.inMinutes} minutes)');
  }
  
  /// Stop the periodic sync timer
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
        print('[PeriodicSyncService] 🛑 Stopped');
  }
  
  /// Manually trigger a sync check
  Future<Map<String, dynamic>> triggerManualSync() async {
        print('[PeriodicSyncService] Manual sync triggered');
    return await _runSync();
  }
  
  /// Run a sync check
  Future<Map<String, dynamic>> _runSync() async {
    if (_appState == null) {
      return {'error': 'AppState not initialized'};
    }
    
    _lastSyncTime = DateTime.now();
    _totalSyncsRun++;
    
    try {
      print('[PeriodicSyncService] 🔄 Running periodic sync check (#$_totalSyncsRun)...');
      
      // Step 1: Check sync status
      final status = await DatabaseSyncService.instance.verifySyncStatus(_appState!);
      
      final isSynced = status['isSynced'] as bool;
      final missingCount = (status['missingFromNPS'] as List).length;
      final orphanCount = (status['orphanedInNPS'] as List).length;
      
      if (isSynced) {
        print('[PeriodicSyncService] ✅ All databases in sync (${status['serversInSync']} servers)');
        _lastSyncResult = {
          'timestamp': _lastSyncTime!.toIso8601String(),
          'status': 'synced',
          'serversInSync': status['serversInSync'],
          'issuesFound': 0,
          'issuesFixed': 0,
        };
        return _lastSyncResult!;
      }
      
      // Step 2: Issues detected
      print('[PeriodicSyncService] ⚠️ Sync issues detected:');
      if (missingCount > 0) {
        print('[PeriodicSyncService]   - $missingCount servers missing from NPS');
      }
      if (orphanCount > 0) {
        print('[PeriodicSyncService]   - $orphanCount orphaned servers in NPS');
      }
      
      _lastIssueDetectedTime = DateTime.now();
      
      // Step 3: Auto-fix if enabled
      if (_autoFixEnabled) {
        print('[PeriodicSyncService] 🔧 Auto-fixing issues...');
        
        final fixResult = await DatabaseSyncService.instance.autoFixSyncIssues(
          _appState!,
          removeOrphans: true, // Phase 3: We're confident enough to remove orphans
        );
        
        final fixCount = fixResult['fixCount'] as int;
        _totalIssuesFixed += fixCount;
        
        print('[PeriodicSyncService] ✅ Fixed $fixCount issues');
        
        _lastSyncResult = {
          'timestamp': _lastSyncTime!.toIso8601String(),
          'status': 'fixed',
          'serversInSync': fixResult['afterSync']['serversInSync'],
          'issuesFound': missingCount + orphanCount,
          'issuesFixed': fixCount,
          'fixDetails': fixResult['fixesApplied'],
        };
        
        return _lastSyncResult!;
      } else {
        // Auto-fix disabled - just report
        print('[PeriodicSyncService] Auto-fix is disabled. Issues not fixed.');
        
        _lastSyncResult = {
          'timestamp': _lastSyncTime!.toIso8601String(),
          'status': 'issues_detected',
          'serversInSync': status['serversInSync'],
          'issuesFound': missingCount + orphanCount,
          'issuesFixed': 0,
          'note': 'Auto-fix disabled',
        };
        
        return _lastSyncResult!;
      }
    } catch (e, stackTrace) {
      print('[PeriodicSyncService] ❌ Error during sync: $e');
      print('[PeriodicSyncService] Stack trace: $stackTrace');
      
      _lastSyncResult = {
        'timestamp': _lastSyncTime!.toIso8601String(),
        'status': 'error',
        'error': e.toString(),
      };
      
      return _lastSyncResult!;
    }
  }
  
  /// Get current sync status
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'autoFixEnabled': _autoFixEnabled,
      'syncInterval': _syncInterval.inMinutes,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastIssueDetectedTime': _lastIssueDetectedTime?.toIso8601String(),
      'totalSyncsRun': _totalSyncsRun,
      'totalIssuesFixed': _totalIssuesFixed,
      'lastSyncResult': _lastSyncResult,
    };
  }
  
  /// Update sync interval
  void setSyncInterval(Duration interval) {
    final wasRunning = _isRunning;
    
    if (wasRunning) {
      stop();
    }
    
    _syncInterval = interval;
    
    if (wasRunning) {
      start();
    }
    
        print('[PeriodicSyncService] Sync interval updated to ${interval.inMinutes} minutes');
  }
  
  /// Enable or disable auto-fix
  void setAutoFix(bool enabled) {
    _autoFixEnabled = enabled;
        print('[PeriodicSyncService] Auto-fix ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Generate a detailed status report
  String generateReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('=== Periodic Sync Service Status ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('Service Status: ${_isRunning ? '🟢 RUNNING' : '🔴 STOPPED'}');
    buffer.writeln('Auto-Fix: ${_autoFixEnabled ? '✅ ENABLED' : '⚠️ DISABLED'}');
    buffer.writeln('Sync Interval: ${_syncInterval.inMinutes} minutes');
    buffer.writeln('');
    buffer.writeln('Statistics:');
    buffer.writeln('  Total Syncs Run: $_totalSyncsRun');
    buffer.writeln('  Total Issues Fixed: $_totalIssuesFixed');
    buffer.writeln('  Last Sync: ${_lastSyncTime != null ? _lastSyncTime : 'Never'}');
    buffer.writeln('  Last Issue Detected: ${_lastIssueDetectedTime != null ? _lastIssueDetectedTime : 'Never'}');
    buffer.writeln('');
    
    if (_lastSyncResult != null) {
      buffer.writeln('Last Sync Result:');
      buffer.writeln('  Status: ${_lastSyncResult!['status']}');
      buffer.writeln('  Servers in Sync: ${_lastSyncResult!['serversInSync']}');
      buffer.writeln('  Issues Found: ${_lastSyncResult!['issuesFound'] ?? 0}');
      buffer.writeln('  Issues Fixed: ${_lastSyncResult!['issuesFixed'] ?? 0}');
      
      if (_lastSyncResult!['error'] != null) {
        buffer.writeln('  Error: ${_lastSyncResult!['error']}');
      }
    }
    
    return buffer.toString();
  }
}

