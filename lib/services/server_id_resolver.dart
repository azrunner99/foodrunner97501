import 'dart:collection';
import '../models.dart';
import '../models/server.dart';
import '../storage.dart';
import '../utils/log.dart';

/// Central Server ID Resolution Service
/// 
/// Handles all server ID format conversions and lookups across the application.
/// Provides intelligent fallback strategies and performance optimization.
class ServerIdResolver {
  static ServerIdResolver? _instance;
  static ServerIdResolver get instance => _instance ??= ServerIdResolver._();
  
  ServerIdResolver._();

  // LRU Cache for recently resolved IDs (max 100 entries)
  final _cache = LinkedHashMap<String, ResolvedServerId>();
  static const int _maxCacheSize = 100;
  
  // Statistics tracking
  int _totalLookups = 0;
  int _cacheHits = 0;
  int _resolutionFailures = 0;
  Map<String, int> _resolutionMethods = {};

  /// Primary resolution method - resolves any input to standard String ID
  /// 
  /// Accepts: String, int, Server object, or any dynamic input
  /// Returns: Standardized String ID or null if resolution fails
  static Future<String?> resolveToStandardId(dynamic input) async {
    return await instance._resolveToStandardId(input);
  }

  /// Resolve to database-compatible integer ID
  /// 
  /// Used for SQL queries that expect integer server_id
  static Future<int?> resolveToDatabaseId(dynamic input) async {
    return await instance._resolveToDatabaseId(input);
  }

  /// Resolve to complete Server object
  /// 
  /// Most comprehensive resolution - returns full server data
  static Future<Server?> resolveToServerObject(dynamic input) async {
    return await instance._resolveToServerObject(input);
  }

  /// Get all known ID formats for a given server
  /// 
  /// Returns all possible ID representations for debugging/migration
  static Future<List<String>> getAllKnownIds(Server server) async {
    return await instance._getAllKnownIds(server);
  }

  /// Validate that an ID actually exists in the system
  static Future<bool> validateIdExists(dynamic serverId) async {
    final resolved = await resolveToServerObject(serverId);
    return resolved != null;
  }

  /// Generate comprehensive ID mapping report for diagnostics
  static Future<String> generateMappingReport() async {
    return await instance._generateMappingReport();
  }

  /// Get resolution statistics for performance monitoring
  static Map<String, dynamic> getStatistics() {
    return instance._getStatistics();
  }

  /// Clear cache and reset statistics
  static void reset() {
    instance._cache.clear();
    instance._totalLookups = 0;
    instance._cacheHits = 0;
    instance._resolutionFailures = 0;
    instance._resolutionMethods.clear();
  }

  // PRIVATE IMPLEMENTATION METHODS

  Future<String?> _resolveToStandardId(dynamic input) async {
    _totalLookups++;
    
    if (input == null) {
      _resolutionFailures++;
      return null;
    }

    final cacheKey = 'std_${input.toString()}';
    if (_cache.containsKey(cacheKey)) {
      _cacheHits++;
      final cached = _cache[cacheKey]!;
      _moveToFront(cacheKey);
      return cached.standardId;
    }

    final resolved = await _performResolution(input);
    if (resolved != null) {
      _addToCache(cacheKey, resolved);
      return resolved.standardId;
    }

    _resolutionFailures++;
    d('[ServerIdResolver] Failed to resolve to standard ID: $input');
    return null;
  }

  Future<int?> _resolveToDatabaseId(dynamic input) async {
    _totalLookups++;
    
    if (input == null) {
      _resolutionFailures++;
      return null;
    }

    final cacheKey = 'db_${input.toString()}';
    if (_cache.containsKey(cacheKey)) {
      _cacheHits++;
      final cached = _cache[cacheKey]!;
      _moveToFront(cacheKey);
      return cached.databaseId;
    }

    final resolved = await _performResolution(input);
    if (resolved != null) {
      _addToCache(cacheKey, resolved);
      return resolved.databaseId;
    }

    _resolutionFailures++;
    d('[ServerIdResolver] Failed to resolve to database ID: $input');
    return null;
  }

  Future<Server?> _resolveToServerObject(dynamic input) async {
    _totalLookups++;
    
    if (input == null) {
      _resolutionFailures++;
      return null;
    }

    final cacheKey = 'obj_${input.toString()}';
    if (_cache.containsKey(cacheKey)) {
      _cacheHits++;
      final cached = _cache[cacheKey]!;
      _moveToFront(cacheKey);
      return cached.serverObject;
    }

    final resolved = await _performResolution(input);
    if (resolved != null) {
      _addToCache(cacheKey, resolved);
      return resolved.serverObject;
    }

    _resolutionFailures++;
    d('[ServerIdResolver] Failed to resolve to server object: $input');
    return null;
  }

  /// Core resolution logic with multiple fallback strategies
  Future<ResolvedServerId?> _performResolution(dynamic input) async {
    try {
      // Get current servers list
      final servers = await _getCurrentServers();
      if (servers.isEmpty) {
        d('[ServerIdResolver] No servers available for resolution');
        return null;
      }

      // Strategy 1: Direct ID match (exact string match)
      if (input is String) {
        try {
          final directMatch = servers.firstWhere(
            (s) => s.id == input,
          );
          _incrementMethodCount('direct_string_match');
          return _createResolvedId(directMatch, 'direct_string_match');
        } catch (e) {
          // No exact match found, continue to next strategy
        }
      }

      // Strategy 2: Direct ID match (convert int to string)
      if (input is int) {
        final intAsString = input.toString();
        try {
          final directMatch = servers.firstWhere(
            (s) => s.id == intAsString,
          );
          _incrementMethodCount('direct_int_match');
          return _createResolvedId(directMatch, 'direct_int_match');
        } catch (e) {
          // No exact match found, continue to next strategy
        }
      }

      // Strategy 3: Server object input
      if (input is Server) {
        _incrementMethodCount('server_object_input');
        return _createResolvedId(input, 'server_object_input');
      }

      // Strategy 4: Name-based ID pattern matching (for legacy numeric IDs)
      final inputStr = input.toString();
      final parsedInt = int.tryParse(inputStr);
      if (parsedInt != null) {
        // Try to match servers with names like "Server 1", "Server 2", etc.
        try {
          final intMatch = servers.firstWhere(
            (s) => s.id.contains(parsedInt.toString()) || 
                   s.name.toLowerCase().contains('server $parsedInt'),
          );
          _incrementMethodCount('parsed_int_pattern_match');
          return _createResolvedId(intMatch, 'parsed_int_pattern_match');
        } catch (e) {
          // No pattern match found, continue
        }
      }

      // Strategy 5: Name-based fallback (case-insensitive)
      try {
        final nameMatch = servers.firstWhere(
          (s) => s.name.toLowerCase() == inputStr.toLowerCase(),
        );
        _incrementMethodCount('name_fallback_match');
        d('[ServerIdResolver] WARNING: Used name fallback for ID resolution: $input -> ${nameMatch.name}');
        return _createResolvedId(nameMatch, 'name_fallback_match');
      } catch (e) {
        // No exact name match, try partial
      }

      // Strategy 6: Partial name match (contains)
      try {
        final partialNameMatch = servers.firstWhere(
          (s) => s.name.toLowerCase().contains(inputStr.toLowerCase()) ||
                 inputStr.toLowerCase().contains(s.name.toLowerCase()),
        );
        _incrementMethodCount('partial_name_match');
        d('[ServerIdResolver] WARNING: Used partial name match for ID resolution: $input -> ${partialNameMatch.name}');
        return _createResolvedId(partialNameMatch, 'partial_name_match');
      } catch (e) {
        // No partial name match found
      }

      // All strategies failed
      d('[ServerIdResolver] All resolution strategies failed for input: $input');
      return null;

    } catch (e) {
      d('[ServerIdResolver] Error during resolution: $e');
      return null;
    }
  }

  /// Get current servers from app state
  Future<List<Server>> _getCurrentServers() async {
    try {
      // Try to get from storage first
      final serversData = await Storage.serversBox.get('list');
      if (serversData != null) {
        final serversList = (serversData as List).cast<Map<String, dynamic>>();
        return serversList.map((data) => Server.fromMap(data)).toList();
      }
      return [];
    } catch (e) {
      d('[ServerIdResolver] Error loading servers: $e');
      return [];
    }
  }

  /// Create a resolved ID object with all format variations
  ResolvedServerId _createResolvedId(Server server, String method) {
    // Try to extract integer from server.id (e.g., "server_1" -> 1)
    final databaseId = _extractDatabaseId(server.id);

    return ResolvedServerId(
      standardId: server.id,
      databaseId: databaseId,
      serverObject: server,
      resolutionMethod: method,
    );
  }

  /// Extract database-compatible integer ID from string ID
  int _extractDatabaseId(String serverId) {
    // Try direct integer parse first
    final directInt = int.tryParse(serverId);
    if (directInt != null) return directInt;
    
    // Try to extract number from patterns like "server_1", "Server 2", etc.
    final numberPattern = RegExp(r'\d+');
    final match = numberPattern.firstMatch(serverId);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    
    // Fallback: use hashCode for consistent mapping
    return serverId.hashCode.abs() % 10000; // Keep it reasonable for DB
  }

  Future<List<String>> _getAllKnownIds(Server server) async {
    final ids = <String>[];
    
    // Add primary ID
    ids.add(server.id);
    
    // Add name as potential ID
    ids.add(server.name);
    
    // Add any extracted database integer representations
    final intId = _extractDatabaseId(server.id);
    ids.add(intId.toString());
    
    return ids.toSet().toList(); // Remove duplicates
  }

  Future<String> _generateMappingReport() async {
    final servers = await _getCurrentServers();
    final report = StringBuffer();
    
    report.writeln('=== SERVER ID MAPPING REPORT ===');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('Total Servers: ${servers.length}');
    report.writeln('');
    
    report.writeln('=== RESOLUTION STATISTICS ===');
    final stats = _getStatistics();
    stats.forEach((key, value) {
      report.writeln('$key: $value');
    });
    report.writeln('');
    
    report.writeln('=== SERVER MAPPING TABLE ===');
    report.writeln('Standard ID | Database ID | Name | All Known IDs');
    report.writeln('-' * 70);
    
    for (final server in servers) {
      final allIds = await _getAllKnownIds(server);
      final databaseId = _extractDatabaseId(server.id);
      
      report.writeln('${server.id} | $databaseId | ${server.name} | ${allIds.join(', ')}');
    }
    
    report.writeln('');
    report.writeln('=== POTENTIAL ISSUES ===');
    
    // Check for duplicate IDs
    final standardIds = servers.map((s) => s.id).toList();
    final duplicateStandardIds = standardIds.where((id) => 
      standardIds.where((other) => other == id).length > 1
    ).toSet();
    
    if (duplicateStandardIds.isNotEmpty) {
      report.writeln('⚠️  DUPLICATE STANDARD IDs: ${duplicateStandardIds.join(', ')}');
    }
    
    // Check for servers with non-extractable database IDs
    final problematicIds = servers.where((s) {
      final dbId = _extractDatabaseId(s.id);
      return dbId == 0 || dbId == s.id.hashCode.abs() % 10000; // Indicates fallback was used
    }).toList();
    
    if (problematicIds.isNotEmpty) {
      report.writeln('⚠️  SERVERS WITH COMPLEX ID PATTERNS: ${problematicIds.map((s) => s.name).join(', ')}');
      report.writeln('    These servers are using hashCode-based database IDs which may cause lookup issues.');
    }
    
    return report.toString();
  }

  Map<String, dynamic> _getStatistics() {
    final cacheHitRate = _totalLookups > 0 ? (_cacheHits / _totalLookups * 100) : 0.0;
    final failureRate = _totalLookups > 0 ? (_resolutionFailures / _totalLookups * 100) : 0.0;
    
    return {
      'total_lookups': _totalLookups,
      'cache_hits': _cacheHits,
      'cache_hit_rate': '${cacheHitRate.toStringAsFixed(1)}%',
      'resolution_failures': _resolutionFailures,
      'failure_rate': '${failureRate.toStringAsFixed(1)}%',
      'cache_size': _cache.length,
      'resolution_methods': Map.from(_resolutionMethods),
    };
  }

  // Cache management methods
  void _addToCache(String key, ResolvedServerId resolved) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry (LRU)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = resolved;
  }

  void _moveToFront(String key) {
    final value = _cache[key]!;
    _cache.remove(key);
    _cache[key] = value;
  }

  void _incrementMethodCount(String method) {
    _resolutionMethods[method] = (_resolutionMethods[method] ?? 0) + 1;
  }
}

/// Resolved server ID containing all format variations
class ResolvedServerId {
  final String standardId;
  final int databaseId;
  final Server serverObject;
  final String resolutionMethod;

  ResolvedServerId({
    required this.standardId,
    required this.databaseId,
    required this.serverObject,
    required this.resolutionMethod,
  });

  @override
  String toString() {
    return 'ResolvedServerId(standard: $standardId, database: $databaseId, method: $resolutionMethod)';
  }
}