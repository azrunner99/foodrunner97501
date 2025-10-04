import 'dart:async';
import '../app_state.dart';
import '../providers/nps_provider.dart';
import '../storage/database_factory.dart';
import '../utils/log.dart';

/// Comprehensive service to synchronize server data between AppState and NPS database
/// 
/// This service ensures that:
/// 1. All servers from AppState exist in the NPS database
/// 2. Server names are consistent between both systems
/// 3. Old numeric server IDs are cleaned up
/// 4. Proper error handling and logging
class ServerSynchronizationService {
  static ServerSynchronizationService? _instance;
  static ServerSynchronizationService get instance {
    _instance ??= ServerSynchronizationService._();
    return _instance!;
  }
  
  ServerSynchronizationService._();
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the synchronization service
  Future<void> initialize() async {
    if (_isInitialized) {
      d('[ServerSyncService] Already initialized');
      return;
    }
    
    try {
      d('[ServerSyncService] Initializing server synchronization service');
      _isInitialized = true;
      d('[ServerSyncService] ✅ Initialization completed');
    } catch (e) {
      d('[ServerSyncService] ❌ Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// Perform comprehensive server synchronization
  /// 
  /// This method:
  /// 1. Cleans up old numeric server IDs from NPS database
  /// 2. Ensures all AppState servers exist in NPS database
  /// 3. Updates server names to match AppState
  /// 4. Validates data consistency
  Future<ServerSyncResult> synchronizeServers(AppState appState, NPSProvider npsProvider) async {
    d('[ServerSyncService] 🔄 Starting comprehensive server synchronization');
    
    final result = ServerSyncResult();
    
    try {
      // Step 1: Initialize NPS Provider if needed
      if (!npsProvider.isInitialized) {
        d('[ServerSyncService] Initializing NPSProvider with AppState');
        await npsProvider.initialize(appState: appState);
      }
      
      // Step 2: Clean up old numeric server IDs
      await _cleanupOldServerIds(result);
      
      // Step 3: Synchronize current servers
      await _synchronizeCurrentServers(appState, npsProvider, result);
      
      // Step 4: Validate synchronization
      await _validateSynchronization(appState, npsProvider, result);
      
      result.success = true;
      d('[ServerSyncService] ✅ Synchronization completed successfully');
      d('[ServerSyncService] 📊 Results: ${result.serversAdded} added, ${result.serversUpdated} updated, ${result.oldServersRemoved} old removed');
      
    } catch (e) {
      result.success = false;
      result.errorMessage = e.toString();
      d('[ServerSyncService] ❌ Synchronization failed: $e');
    }
    
    return result;
  }
  
  /// Clean up old numeric server IDs from the database
  Future<void> _cleanupOldServerIds(ServerSyncResult result) async {
    d('[ServerSyncService] 🧹 Cleaning up old numeric server IDs');
    
    try {
      final db = DatabaseFactory.instance;
      
      // Find old numeric server IDs (like "1", "2", "3")
      final oldServers = await db.queryTable(
        'servers',
        where: 'LENGTH(id) <= 2 AND id GLOB \'[0-9]*\'',
      );
      
      d('[ServerSyncService] Found ${oldServers.length} old numeric server IDs to clean up');
      
      for (final oldServer in oldServers) {
        final oldId = oldServer['id'].toString();
        d('[ServerSyncService] 🗑️ Removing old server ID: $oldId');
        
        // Delete associated NPS data
        await db.deleteFrom('nps_monthly_reports', 'server_id = ?', [oldId]);
        await db.deleteFrom('nps_feedback', 'server_id = ?', [oldId]);
        await db.deleteFrom('performance_trends', 'server_id = ?', [oldId]);
        await db.deleteFrom('performance_insights', 'server_id = ?', [oldId]);
        
        // Delete the server itself
        await db.deleteFrom('servers', 'id = ?', [oldId]);
        
        result.oldServersRemoved++;
      }
      
      d('[ServerSyncService] ✅ Cleaned up ${result.oldServersRemoved} old servers');
      
    } catch (e) {
      d('[ServerSyncService] ⚠️ Error during cleanup: $e');
      // Don't fail the entire sync for cleanup errors
    }
  }
  
  /// Synchronize current servers from AppState to NPS database
  Future<void> _synchronizeCurrentServers(AppState appState, NPSProvider npsProvider, ServerSyncResult result) async {
    d('[ServerSyncService] 🔄 Synchronizing current servers from AppState');
    
    final appStateServers = appState.servers;
    d('[ServerSyncService] Found ${appStateServers.length} servers in AppState');
    
    final db = DatabaseFactory.instance;
    
    for (final server in appStateServers) {
      try {
        // Check if server already exists in NPS database
        final existing = await db.queryTable(
          'servers',
          where: 'id = ? OR original_id = ?',
          whereArgs: [server.id, server.id],
          limit: 1,
        );
        
        if (existing.isEmpty) {
          // Server doesn't exist - add it
          d('[ServerSyncService] ➕ Adding new server: ${server.name} (${server.id})');
          
          await db.insertInto('servers', {
            'id': server.id,
            'name': server.name,
            'original_id': server.id,
            'hire_date': server.hireDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
            'active': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          result.serversAdded++;
          
        } else {
          // Server exists - update if name is different
          final existingServer = existing.first;
          if (existingServer['name'] != server.name) {
            d('[ServerSyncService] 📝 Updating server name: ${existingServer['name']} → ${server.name}');
            
            await db.updateTable('servers', {
              'name': server.name,
              'updated_at': DateTime.now().toIso8601String(),
            }, 'id = ?', [server.id]);
            
            result.serversUpdated++;
          }
        }
        
      } catch (e) {
        d('[ServerSyncService] ❌ Error syncing server ${server.name}: $e');
        result.errorMessage = '${result.errorMessage}\nError syncing ${server.name}: $e';
      }
    }
  }
  
  /// Validate that synchronization was successful
  Future<void> _validateSynchronization(AppState appState, NPSProvider npsProvider, ServerSyncResult result) async {
    d('[ServerSyncService] ✅ Validating synchronization results');
    
    try {
      final db = DatabaseFactory.instance;
      final npsServers = await db.queryTable('servers', where: 'active = 1');
      final appStateServers = appState.servers;
      
      d('[ServerSyncService] Validation: ${appStateServers.length} AppState servers, ${npsServers.length} NPS servers');
      
      // Check that all AppState servers exist in NPS database
      for (final appServer in appStateServers) {
        final found = npsServers.any((npsServer) => 
          npsServer['id'] == appServer.id || npsServer['original_id'] == appServer.id);
        
        if (!found) {
          throw Exception('AppState server ${appServer.name} (${appServer.id}) not found in NPS database');
        }
      }
      
      result.finalAppStateCount = appStateServers.length;
      result.finalNpsCount = npsServers.length;
      
      d('[ServerSyncService] ✅ Validation passed: All servers synchronized correctly');
      
    } catch (e) {
      d('[ServerSyncService] ❌ Validation failed: $e');
      throw Exception('Synchronization validation failed: $e');
    }
  }
}

/// Result of server synchronization operation
class ServerSyncResult {
  bool success = false;
  int serversAdded = 0;
  int serversUpdated = 0;
  int oldServersRemoved = 0;
  int finalAppStateCount = 0;
  int finalNpsCount = 0;
  String errorMessage = '';
  
  @override
  String toString() {
    return 'ServerSyncResult(success: $success, added: $serversAdded, updated: $serversUpdated, removed: $oldServersRemoved, appState: $finalAppStateCount, nps: $finalNpsCount)';
  }
}
