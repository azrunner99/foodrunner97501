import '../app_state.dart';
import '../models.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import 'server_id_resolver.dart';
import '../utils/log.dart';

/// Unified server data access service
/// 
/// Single API for accessing server data from any storage system.
/// Automatically handles ID resolution, data merging, and fallback strategies.
/// 
/// Phase 1.3 of Database Unification Blueprint
/// 
/// Usage:
/// ```dart
/// // Initialize once in main.dart
/// ServerDataService.instance.initialize(appState);
/// 
/// // Then use anywhere in the app
/// final server = await ServerDataService.instance.getServer('server_id');
/// final allServers = await ServerDataService.instance.getAllServers();
/// ```
class ServerDataService {
  static ServerDataService? _instance;
  static ServerDataService get instance => _instance ??= ServerDataService._();
  
  ServerDataService._();
  
  final NPSDatabaseAdapter _npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
  AppState? _appState;
  bool _initialized = false;
  
  // Cache for frequently accessed data
  final Map<String, Server> _serverCache = {};
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Initialize with AppState reference
  void initialize(AppState appState) {
    _appState = appState;
    _initialized = true;
    d('[ServerDataService] Initialized with ${appState.servers.length} servers');
  }
  
  /// Check if cache is still valid
  bool get _isCacheValid {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry;
  }
  
  /// Invalidate cache (call when servers are added/updated)
  void invalidateCache() {
    _serverCache.clear();
    _cacheTimestamp = null;
    d('[ServerDataService] Cache invalidated');
  }
  
  /// Get server by ID (from any source, with ID resolution)
  /// 
  /// Search order:
  /// 1. AppState (fastest, most up-to-date)
  /// 2. Local cache
  /// 3. NPS Database (fallback)
  Future<Server?> getServer(String serverId) async {
    if (!_initialized) {
      d('[ServerDataService] ⚠️ Not initialized, returning null');
      return null;
    }
    
    // Resolve ID to canonical format
    final canonicalId = ServerIdResolver.instance.getCanonicalId(serverId);
    
    // Try AppState first (fastest, most up-to-date)
    if (_appState != null) {
      try {
        final server = _appState!.servers.firstWhere(
          (s) => s.id == canonicalId,
        );
        d('[ServerDataService] Found server $canonicalId in AppState');
        return server;
      } catch (e) {
        // Not found in AppState, continue to cache/database
      }
    }
    
    // Try cache
    if (_isCacheValid && _serverCache.containsKey(canonicalId)) {
      d('[ServerDataService] Found server $canonicalId in cache');
      return _serverCache[canonicalId];
    }
    
    // Try NPS Database as last resort
    try {
      final servers = await _npsAdapter.queryTable(
        'servers',
        where: 'id = ? OR original_id = ?',
        whereArgs: [canonicalId, canonicalId],
      );
      
      if (servers.isNotEmpty) {
        final serverData = servers.first;
        final server = Server(
          id: serverData['id'].toString(),
          name: serverData['name'] as String,
          teamColor: serverData['team_color'] as String?,
          stationType: serverData['station_type'] as String?,
          hireDate: serverData['hire_date'] != null 
              ? DateTime.parse(serverData['hire_date'] as String)
              : null,
        );
        
        // Cache it for next time
        _serverCache[canonicalId] = server;
        _cacheTimestamp = DateTime.now();
        
        d('[ServerDataService] Found server $canonicalId in NPS Database');
        return server;
      }
    } catch (e) {
      d('[ServerDataService] Error fetching server $canonicalId from NPS DB: $e');
    }
    
    d('[ServerDataService] ⚠️ Server $canonicalId not found in any source');
    return null;
  }
  
  /// Get all servers (merged from all sources, deduplicated)
  /// 
  /// Returns a unified list of servers from:
  /// - AppState (primary source)
  /// - NPS Database (for any servers not in AppState)
  Future<List<Server>> getAllServers({bool activeOnly = true}) async {
    if (!_initialized) {
      d('[ServerDataService] ⚠️ Not initialized, returning empty list');
      return [];
    }
    
    final serverMap = <String, Server>{};
    
    // Start with AppState servers (primary source)
    if (_appState != null) {
      // Use activeServers if activeOnly is true, otherwise all servers
      final servers = activeOnly ? _appState!.activeServers : _appState!.servers;
      
      // Debug Antonio specifically
      final antonioInList = servers.any((s) => s.id == 'rtintker4mvv4qfl');
      final antonioProfile = _appState!.profiles['rtintker4mvv4qfl'];
      d('[ServerDataService] activeOnly=$activeOnly, Antonio in list: $antonioInList');
      d('[ServerDataService] Antonio profile exists: ${antonioProfile != null}, isArchived: ${antonioProfile?.isArchived ?? false}');
      
      for (final server in servers) {
        serverMap[server.id] = server;
      }
      d('[ServerDataService] Loaded ${serverMap.length} servers from AppState (activeOnly: $activeOnly)');
    }
    
    // Add any servers from NPS DB not in AppState
    try {
      final npsServers = await _npsAdapter.getAllServers(activeOnly: activeOnly);
      int addedFromNPS = 0;
      
      for (final npsData in npsServers) {
        final id = npsData['id'].toString();
        if (!serverMap.containsKey(id)) {
          serverMap[id] = Server(
            id: id,
            name: npsData['name'] as String,
            teamColor: npsData['team_color'] as String?,
            stationType: npsData['station_type'] as String?,
            hireDate: npsData['hire_date'] != null
                ? DateTime.parse(npsData['hire_date'] as String)
                : null,
          );
          addedFromNPS++;
        }
      }
      
      if (addedFromNPS > 0) {
        d('[ServerDataService] Added $addedFromNPS servers from NPS Database');
      }
    } catch (e) {
      d('[ServerDataService] Error fetching NPS servers: $e');
      // Continue with what we have from AppState
    }
    
    // Sort alphabetically by name
    final servers = serverMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    
    d('[ServerDataService] Returning ${servers.length} total servers');
    return servers;
  }
  
  /// Get server with full profile data
  /// 
  /// Returns a map containing:
  /// - server: Server object
  /// - profile: ServerProfile (if exists)
  /// - hasProfile: boolean
  Future<Map<String, dynamic>?> getServerWithProfile(String serverId) async {
    final server = await getServer(serverId);
    if (server == null) return null;
    
    final profile = _appState?.profiles[server.id];
    
    return {
      'server': server,
      'profile': profile,
      'hasProfile': profile != null,
      'allTimeRuns': profile?.allTimeRuns ?? 0,
      'points': profile?.points ?? 0,
      'level': profile?.level ?? 1,
    };
  }
  
  /// Get multiple servers by IDs
  Future<List<Server>> getServersByIds(List<String> serverIds) async {
    final servers = <Server>[];
    
    for (final id in serverIds) {
      final server = await getServer(id);
      if (server != null) {
        servers.add(server);
      }
    }
    
    return servers;
  }
  
  /// Check if server exists in any storage
  Future<bool> serverExists(String serverId) async {
    final server = await getServer(serverId);
    return server != null;
  }
  
  /// Get server by name (case-insensitive)
  Future<Server?> getServerByName(String name) async {
    final normalizedName = name.trim().toLowerCase();
    
    // Try ServerIdResolver first (has name mapping)
    final canonicalId = ServerIdResolver.instance.getCanonicalIdByName(name);
    if (canonicalId != null) {
      return await getServer(canonicalId);
    }
    
    // Fallback to manual search
    final allServers = await getAllServers();
    try {
      return allServers.firstWhere(
        (s) => s.name.trim().toLowerCase() == normalizedName,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get servers working in current shift
  Future<List<Server>> getWorkingServers() async {
    if (_appState == null || !_appState!.shiftActive) {
      return [];
    }
    
    final workingIds = _appState!.workingServerIds;
    return await getServersByIds(workingIds.toList());
  }
  
  /// Get server count by source
  Future<Map<String, int>> getServerCountBySource() async {
    final appStateCount = _appState?.servers.length ?? 0;
    
    int npsCount = 0;
    try {
      final npsServers = await _npsAdapter.getAllServers();
      npsCount = npsServers.length;
    } catch (e) {
      d('[ServerDataService] Error getting NPS count: $e');
    }
    
    return {
      'appState': appStateCount,
      'npsDatabase': npsCount,
      'total': (await getAllServers()).length,
    };
  }
  
  /// Get detailed server info for debugging
  Future<Map<String, dynamic>> getServerDebugInfo(String serverId) async {
    final canonicalId = ServerIdResolver.instance.getCanonicalId(serverId);
    final allKnownIds = ServerIdResolver.instance.getAllKnownIds(canonicalId);
    
    // Check each source
    Server? appStateServer;
    if (_appState != null) {
      try {
        appStateServer = _appState!.servers.firstWhere((s) => s.id == canonicalId);
      } catch (e) {
        // Not found
      }
    }
    
    Map<String, dynamic>? npsServer;
    try {
      final npsServers = await _npsAdapter.queryTable(
        'servers',
        where: 'id = ?',
        whereArgs: [canonicalId],
      );
      if (npsServers.isNotEmpty) {
        npsServer = npsServers.first;
      }
    } catch (e) {
      // Error accessing NPS
    }
    
    return {
      'requestedId': serverId,
      'canonicalId': canonicalId,
      'allKnownIds': allKnownIds.toList(),
      'inAppState': appStateServer != null,
      'inNPSDatabase': npsServer != null,
      'appStateData': appStateServer?.toMap(),
      'npsData': npsServer,
    };
  }
  
  /// Generate a comprehensive server data report
  Future<String> generateServerReport() async {
    final buffer = StringBuffer();
    final counts = await getServerCountBySource();
    final allServers = await getAllServers();
    
    buffer.writeln('=== Server Data Service Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Initialized: $_initialized');
    buffer.writeln('');
    buffer.writeln('Server Counts by Source:');
    buffer.writeln('  AppState: ${counts['appState']}');
    buffer.writeln('  NPS Database: ${counts['npsDatabase']}');
    buffer.writeln('  Total (deduplicated): ${counts['total']}');
    buffer.writeln('');
    buffer.writeln('Cache Status:');
    buffer.writeln('  Valid: $_isCacheValid');
    buffer.writeln('  Entries: ${_serverCache.length}');
    buffer.writeln('  Last Updated: $_cacheTimestamp');
    buffer.writeln('');
    buffer.writeln('Servers:');
    
    for (final server in allServers) {
      buffer.writeln('  ${server.name} (${server.id})');
      
      // Check which sources have this server
      final inAppState = _appState?.servers.any((s) => s.id == server.id) ?? false;
      final sources = <String>[];
      if (inAppState) sources.add('AppState');
      if (_serverCache.containsKey(server.id)) sources.add('Cache');
      
      buffer.writeln('    Sources: ${sources.join(', ')}');
      if (server.teamColor != null) buffer.writeln('    Team: ${server.teamColor}');
      if (server.stationType != null) buffer.writeln('    Station: ${server.stationType}');
    }
    
    return buffer.toString();
  }
}


