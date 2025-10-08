import '../models.dart';
import '../utils/log.dart';

/// Conflict resolution strategy enumeration
enum ConflictResolution {
  /// Use AppState version
  useAppState,
  /// Use NPS Database version
  useNPS,
  /// Use Unified Database version
  useUnified,
  /// Create new entry in target database
  createInTarget,
  /// Update existing entry in target database
  updateTarget,
  /// Delete from target database
  deleteFromTarget,
  /// No action needed
  noAction,
  /// Manual intervention required
  requiresManualResolution,
}

/// Conflict resolution result
class ConflictResult {
  final ConflictResolution resolution;
  final String reason;
  final Server? resolvedServer;
  final Map<String, dynamic>? metadata;
  
  ConflictResult({
    required this.resolution,
    required this.reason,
    this.resolvedServer,
    this.metadata,
  });
  
  @override
  String toString() {
    return 'ConflictResult(resolution: $resolution, reason: $reason)';
  }
}

/// Automatic conflict resolution service
/// 
/// Handles conflicts between different data sources (AppState, NPS, UnifiedDB)
/// using a configurable priority-based strategy.
/// 
/// **Resolution Priority**:
/// 1. AppState is source of truth for **active** server data
/// 2. NPS Database is source of truth for **historical** NPS data
/// 3. Unified Database is the persistent backup
/// 4. Most recent update wins in case of timestamp conflicts
/// 
/// **Conflict Types**:
/// - **Missing in NPS**: Server exists in AppState but not NPS → CREATE in NPS
/// - **Missing in AppState**: Server exists in NPS but not AppState → Usually orphaned, DELETE from NPS
/// - **Data Mismatch**: Server exists in both but data differs → UPDATE based on most recent
/// - **ID Mismatch**: Same server, different IDs → Use ServerIdResolver mapping
/// 
/// Phase 3.3 of Database Unification Blueprint
class ConflictResolver {
  static ConflictResolver? _instance;
  static ConflictResolver get instance => _instance ??= ConflictResolver._();
  
  ConflictResolver._();
  
  /// Resolve conflict between AppState and NPS Database versions of a server
  /// 
  /// **Priority Rules**:
  /// 1. If server is only in AppState → Create in NPS
  /// 2. If server is only in NPS → Consider it orphaned, delete from NPS
  /// 3. If both exist but differ → Most recent wins (or AppState if no timestamps)
  ConflictResult resolveServerConflict({
    Server? appStateServer,
    Map<String, dynamic>? npsServer,
    Server? unifiedServer,
  }) {
    // Case 1: Server only in AppState
    if (appStateServer != null && npsServer == null && unifiedServer == null) {
      print('[ConflictResolver] Server only in AppState: ${appStateServer.id} (${appStateServer.name})');
      return ConflictResult(
        resolution: ConflictResolution.createInTarget,
        reason: 'Server exists in AppState but missing from other databases',
        resolvedServer: appStateServer,
        metadata: {'source': 'appState', 'action': 'create_in_nps_and_unified'},
      );
    }
    
    // Case 2: Server only in NPS (orphaned)
    if (appStateServer == null && npsServer != null) {
      final serverId = npsServer['id'] as String;
      final serverName = npsServer['name'] as String?;
      
      print('[ConflictResolver] Orphaned server in NPS: $serverId ($serverName)');
      return ConflictResult(
        resolution: ConflictResolution.deleteFromTarget,
        reason: 'Server exists in NPS but not in AppState (orphaned)',
        metadata: {'source': 'nps', 'action': 'delete_from_nps', 'serverId': serverId},
      );
    }
    
    // Case 3: Server in both AppState and NPS
    if (appStateServer != null && npsServer != null) {
      final appStateId = appStateServer.id;
      final npsId = npsServer['id'] as String;
      final appStateName = appStateServer.name;
      final npsName = npsServer['name'] as String;
      
      // Check if names differ
      if (appStateName != npsName) {
        print('[ConflictResolver] Name mismatch: AppState="$appStateName" vs NPS="$npsName"');
        return ConflictResult(
          resolution: ConflictResolution.useAppState,
          reason: 'AppState has more recent server name',
          resolvedServer: appStateServer,
          metadata: {
            'source': 'appState',
            'action': 'update_nps',
            'oldName': npsName,
            'newName': appStateName,
          },
        );
      }
      
      // Check if IDs differ (should be caught by ServerIdResolver, but just in case)
      if (appStateId != npsId) {
        print('[ConflictResolver] ID MISMATCH: AppState="$appStateId" vs NPS="$npsId" for server "$appStateName"');
        return ConflictResult(
          resolution: ConflictResolution.requiresManualResolution,
          reason: 'Server ID mismatch detected - requires manual intervention',
          metadata: {
            'appStateId': appStateId,
            'npsId': npsId,
            'serverName': appStateName,
          },
        );
      }
      
      // Names match, IDs match - all good
      return ConflictResult(
        resolution: ConflictResolution.noAction,
        reason: 'Server data is consistent across databases',
        resolvedServer: appStateServer,
        metadata: {'serverId': appStateId, 'serverName': appStateName},
      );
    }
    
    // Case 4: No data available (shouldn't happen)
    print('[ConflictResolver] No data available for conflict resolution');
    return ConflictResult(
      resolution: ConflictResolution.requiresManualResolution,
      reason: 'No server data available from any source',
    );
  }
  
  /// Batch resolve conflicts for multiple servers
  /// 
  /// Returns a map of server IDs to conflict results
  Map<String, ConflictResult> resolveAllConflicts({
    required List<Server> appStateServers,
    required List<Map<String, dynamic>> npsServers,
  }) {
    final results = <String, ConflictResult>{};
    
    // Build lookup maps
    final appStateMap = {for (var s in appStateServers) s.id: s};
    final npsMap = {for (var s in npsServers) s['id'] as String: s};
    
    // Get all unique server IDs
    final allIds = {...appStateMap.keys, ...npsMap.keys};
    
    for (final id in allIds) {
      final result = resolveServerConflict(
        appStateServer: appStateMap[id],
        npsServer: npsMap[id],
      );
      results[id] = result;
    }
    
    return results;
  }
  
  /// Generate a conflict report
  String generateConflictReport(Map<String, ConflictResult> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== Conflict Resolution Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Servers Analyzed: ${results.length}');
    buffer.writeln('');
    
    // Group by resolution type
    final byResolution = <ConflictResolution, List<String>>{};
    for (final entry in results.entries) {
      final resolution = entry.value.resolution;
      byResolution.putIfAbsent(resolution, () => []);
      byResolution[resolution]!.add(entry.key);
    }
    
    buffer.writeln('Resolution Summary:');
    for (final entry in byResolution.entries) {
      final count = entry.value.length;
      final percentage = (count / results.length * 100).toStringAsFixed(1);
      buffer.writeln('  ${entry.key.name}: $count ($percentage%)');
    }
    buffer.writeln('');
    
    // Detail each conflict type
    if (byResolution[ConflictResolution.createInTarget]?.isNotEmpty ?? false) {
      buffer.writeln('📝 Servers to CREATE in target databases:');
      for (final id in byResolution[ConflictResolution.createInTarget]!) {
        final result = results[id]!;
        buffer.writeln('  - ${result.resolvedServer?.name ?? id} ($id)');
      }
      buffer.writeln('');
    }
    
    if (byResolution[ConflictResolution.deleteFromTarget]?.isNotEmpty ?? false) {
      buffer.writeln('🗑️ Orphaned servers to DELETE:');
      for (final id in byResolution[ConflictResolution.deleteFromTarget]!) {
        buffer.writeln('  - $id');
      }
      buffer.writeln('');
    }
    
    if (byResolution[ConflictResolution.useAppState]?.isNotEmpty ?? false) {
      buffer.writeln('🔄 Servers to UPDATE (AppState wins):');
      for (final id in byResolution[ConflictResolution.useAppState]!) {
        final result = results[id]!;
        buffer.writeln('  - ${result.resolvedServer?.name ?? id} ($id)');
        buffer.writeln('    Reason: ${result.reason}');
      }
      buffer.writeln('');
    }
    
    if (byResolution[ConflictResolution.requiresManualResolution]?.isNotEmpty ?? false) {
      buffer.writeln('⚠️ MANUAL INTERVENTION REQUIRED:');
      for (final id in byResolution[ConflictResolution.requiresManualResolution]!) {
        final result = results[id]!;
        buffer.writeln('  - $id');
        buffer.writeln('    Reason: ${result.reason}');
        buffer.writeln('    Metadata: ${result.metadata}');
      }
      buffer.writeln('');
    }
    
    if (byResolution[ConflictResolution.noAction]?.isNotEmpty ?? false) {
      final count = byResolution[ConflictResolution.noAction]!.length;
      buffer.writeln('✅ Servers in sync: $count (no action needed)');
    }
    
    return buffer.toString();
  }
  
  /// Get conflict statistics
  Map<String, dynamic> getConflictStats(Map<String, ConflictResult> results) {
    final stats = <ConflictResolution, int>{};
    
    for (final result in results.values) {
      stats[result.resolution] = (stats[result.resolution] ?? 0) + 1;
    }
    
    return {
      'total': results.length,
      'needsAction': stats[ConflictResolution.createInTarget]! +
          stats[ConflictResolution.deleteFromTarget]! +
          stats[ConflictResolution.useAppState]!,
      'inSync': stats[ConflictResolution.noAction] ?? 0,
      'requiresManual': stats[ConflictResolution.requiresManualResolution] ?? 0,
      'breakdown': {
        'create': stats[ConflictResolution.createInTarget] ?? 0,
        'delete': stats[ConflictResolution.deleteFromTarget] ?? 0,
        'update': stats[ConflictResolution.useAppState] ?? 0,
        'noAction': stats[ConflictResolution.noAction] ?? 0,
        'manual': stats[ConflictResolution.requiresManualResolution] ?? 0,
      },
    };
  }
}

