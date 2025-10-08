import '../app_state.dart';
import '../models.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import '../utils/log.dart';

/// Automatic database synchronization service
/// 
/// Ensures server data is synchronized across all storage systems
/// whenever changes occur. This service prevents the UNIQUE constraint
/// errors by properly handling insert vs update logic.
/// 
/// Phase 1.2 of Database Unification Blueprint
class DatabaseSyncService {
  static DatabaseSyncService? _instance;
  static DatabaseSyncService get instance => _instance ??= DatabaseSyncService._();
  
  DatabaseSyncService._();
  
  final NPSDatabaseAdapter _npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
  bool _initialized = false;
  
  /// Initialize the sync service
  Future<void> initialize() async {
    if (_initialized) return;
    d('[DatabaseSyncService] Initializing...');
    _initialized = true;
    d('[DatabaseSyncService] ✅ Initialized');
  }
  
  /// Sync a single server from AppState to NPS Database
  /// 
  /// Handles both INSERT (new server) and UPDATE (existing server) cases
  /// to prevent UNIQUE constraint errors.
  Future<void> syncServerToNPS(Server server) async {
    try {
      d('[DatabaseSyncService] Syncing server ${server.id} (${server.name}) to NPS Database...');
      
      final serverData = {
        'id': server.id,
        'name': server.name,
        'original_id': server.id,
        'hire_date': (server.hireDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Check if server already exists
      final existingServers = await _npsAdapter.queryTable(
        'servers',
        where: 'id = ?',
        whereArgs: [server.id],
      );
      
      if (existingServers.isNotEmpty) {
        // Server exists - UPDATE it
        await _npsAdapter.updateServer(server.id, serverData);
        d('[DatabaseSyncService] ✅ Updated existing server ${server.id} (${server.name})');
      } else {
        // Server doesn't exist - INSERT it
        serverData['created_at'] = DateTime.now().toIso8601String();
        await _npsAdapter.insertServer(serverData);
        d('[DatabaseSyncService] ✅ Inserted new server ${server.id} (${server.name})');
      }
    } catch (e, stackTrace) {
      d('[DatabaseSyncService] ❌ Error syncing server ${server.id}: $e');
      d('[DatabaseSyncService] Stack trace: $stackTrace');
      // Don't rethrow - sync failures shouldn't break the app
      // But we log it for debugging
    }
  }
  
  /// Sync all servers from AppState to NPS Database
  /// 
  /// This is useful for:
  /// - Initial setup
  /// - Manual sync from admin panel
  /// - Recovery from sync failures
  Future<Map<String, dynamic>> syncAllServersToNPS(AppState appState) async {
    d('[DatabaseSyncService] Syncing ${appState.servers.length} servers to NPS Database...');
    
    int synced = 0;
    int updated = 0;
    int inserted = 0;
    int errors = 0;
    final List<String> errorDetails = [];
    
    for (final server in appState.servers) {
      try {
        final existingServers = await _npsAdapter.queryTable(
          'servers',
          where: 'id = ?',
          whereArgs: [server.id],
        );
        
        await syncServerToNPS(server);
        
        if (existingServers.isNotEmpty) {
          updated++;
        } else {
          inserted++;
        }
        synced++;
      } catch (e) {
        errors++;
        errorDetails.add('${server.id}: $e');
        d('[DatabaseSyncService] Error syncing ${server.id}: $e');
      }
    }
    
    final result = {
      'total': appState.servers.length,
      'synced': synced,
      'updated': updated,
      'inserted': inserted,
      'errors': errors,
      'errorDetails': errorDetails,
      'success': errors == 0,
    };
    
    d('[DatabaseSyncService] ✅ Sync complete: $synced synced ($inserted new, $updated updated), $errors errors');
    
    return result;
  }
  
  /// Verify sync status between AppState and NPS Database
  /// 
  /// Returns detailed information about:
  /// - How many servers are in sync
  /// - Which servers are missing from NPS database
  /// - Which servers are orphaned in NPS database (not in AppState)
  Future<Map<String, dynamic>> verifySyncStatus(AppState appState) async {
    d('[DatabaseSyncService] Verifying sync status...');
    
    try {
      final appServerIds = appState.servers.map((s) => s.id).toSet();
      final npsServers = await _npsAdapter.getAllServers();
      final npsServerIds = npsServers.map((s) => s['id'].toString()).toSet();
      
      final inAppNotNPS = appServerIds.difference(npsServerIds);
      final inNPSNotApp = npsServerIds.difference(appServerIds);
      final inSync = appServerIds.intersection(npsServerIds);
      
      final result = {
        'appServerCount': appServerIds.length,
        'npsServerCount': npsServerIds.length,
        'serversInSync': inSync.length,
        'missingFromNPS': inAppNotNPS.toList(),
        'orphanedInNPS': inNPSNotApp.toList(),
        'isSynced': inAppNotNPS.isEmpty && inNPSNotApp.isEmpty,
        'syncPercentage': appServerIds.isEmpty ? 100.0 : (inSync.length / appServerIds.length * 100),
      };
      
      d('[DatabaseSyncService] Sync status: ${result['serversInSync']}/${result['appServerCount']} in sync (${(result['syncPercentage'] as double).toStringAsFixed(1)}%)');
      
      if (inAppNotNPS.isNotEmpty) {
        d('[DatabaseSyncService] ⚠️ Missing from NPS: ${inAppNotNPS.join(", ")}');
      }
      
      if (inNPSNotApp.isNotEmpty) {
        d('[DatabaseSyncService] ⚠️ Orphaned in NPS: ${inNPSNotApp.join(", ")}');
      }
      
      return result;
    } catch (e, stackTrace) {
      d('[DatabaseSyncService] ❌ Error verifying sync status: $e');
      d('[DatabaseSyncService] Stack trace: $stackTrace');
      
      return {
        'error': e.toString(),
        'appServerCount': appState.servers.length,
        'npsServerCount': 0,
        'serversInSync': 0,
        'missingFromNPS': appState.servers.map((s) => s.id).toList(),
        'orphanedInNPS': [],
        'isSynced': false,
        'syncPercentage': 0.0,
      };
    }
  }
  
  /// Auto-fix common sync issues
  /// 
  /// Attempts to:
  /// 1. Sync missing servers from AppState to NPS
  /// 2. Optionally remove orphaned servers from NPS (if requested)
  Future<Map<String, dynamic>> autoFixSyncIssues(
    AppState appState, {
    bool removeOrphans = false,
  }) async {
    d('[DatabaseSyncService] Auto-fixing sync issues...');
    
    final status = await verifySyncStatus(appState);
    final fixes = <String>[];
    
    // Fix 1: Sync missing servers
    if (status['missingFromNPS'].isNotEmpty) {
      final missing = status['missingFromNPS'] as List;
      d('[DatabaseSyncService] Syncing ${missing.length} missing servers...');
      
      for (final serverId in missing) {
        final server = appState.servers.firstWhere((s) => s.id == serverId);
        await syncServerToNPS(server);
        fixes.add('Synced missing server: ${server.name} ($serverId)');
      }
    }
    
    // Fix 2: Remove orphans (optional, dangerous operation)
    if (removeOrphans && status['orphanedInNPS'].isNotEmpty) {
      final orphans = status['orphanedInNPS'] as List;
      d('[DatabaseSyncService] ⚠️ Removing ${orphans.length} orphaned servers...');
      
      for (final serverId in orphans) {
        try {
          await _npsAdapter.deleteServer(serverId);
          fixes.add('Removed orphaned server: $serverId');
        } catch (e) {
          fixes.add('Failed to remove orphan $serverId: $e');
        }
      }
    }
    
    // Verify fixes worked
    final newStatus = await verifySyncStatus(appState);
    
    d('[DatabaseSyncService] ✅ Auto-fix complete: ${fixes.length} fixes applied');
    
    return {
      'fixesApplied': fixes,
      'fixCount': fixes.length,
      'beforeSync': status,
      'afterSync': newStatus,
      'success': newStatus['isSynced'],
    };
  }
  
  /// Get detailed sync report for debugging
  Future<String> generateSyncReport(AppState appState) async {
    final status = await verifySyncStatus(appState);
    final buffer = StringBuffer();
    
    buffer.writeln('=== Database Sync Status Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('AppState Servers: ${status['appServerCount']}');
    buffer.writeln('NPS Database Servers: ${status['npsServerCount']}');
    buffer.writeln('In Sync: ${status['serversInSync']} (${status['syncPercentage'].toStringAsFixed(1)}%)');
    buffer.writeln('Status: ${status['isSynced'] ? '✅ SYNCED' : '⚠️ OUT OF SYNC'}');
    buffer.writeln('');
    
    if (status['missingFromNPS'].isNotEmpty) {
      buffer.writeln('⚠️ Missing from NPS Database:');
      for (final id in status['missingFromNPS']) {
        final server = appState.servers.firstWhere((s) => s.id == id, orElse: () => Server(id: id, name: 'Unknown'));
        buffer.writeln('  - ${server.name} ($id)');
      }
      buffer.writeln('');
    }
    
    if (status['orphanedInNPS'].isNotEmpty) {
      buffer.writeln('⚠️ Orphaned in NPS Database:');
      for (final id in status['orphanedInNPS']) {
        buffer.writeln('  - $id (not in AppState)');
      }
      buffer.writeln('');
    }
    
    if (status['isSynced']) {
      buffer.writeln('✅ All servers are synchronized!');
      buffer.writeln('');
      buffer.writeln('Server List:');
      for (final server in appState.servers) {
        buffer.writeln('  ✓ ${server.name} (${server.id})');
      }
    }
    
    return buffer.toString();
  }
}

