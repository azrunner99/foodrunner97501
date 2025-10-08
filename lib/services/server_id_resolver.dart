import '../app_state.dart';
import '../models/server.dart';
import '../models.dart';
import '../storage/nps_database_adapter.dart';
import '../utils/log.dart';

/// Service to resolve server ID inconsistencies across different data sources
/// 
/// This service provides a canonical mapping between different server ID formats
/// and ensures consistent server identification across AppState, NPSProvider, and database.
class ServerIdResolver {
  static ServerIdResolver? _instance;
  static ServerIdResolver get instance => _instance ??= ServerIdResolver._();
  
  ServerIdResolver._();

  /// Canonical server ID mappings: canonical_id -> all_known_ids
  final Map<String, Set<String>> _canonicalMappings = {};
  
  /// Reverse mappings: any_id -> canonical_id
  final Map<String, String> _reverseMappings = {};
  
  /// Server name mappings: normalized_name -> canonical_id
  final Map<String, String> _nameMappings = {};
  
  bool _isInitialized = false;
  
  /// Initialize the resolver with current server data
  Future<void> initialize(AppState appState, NPSDatabaseAdapter database) async {
    // Always re-initialize to ensure we have the latest data
    _canonicalMappings.clear();
    _reverseMappings.clear();
    _nameMappings.clear();
    _isInitialized = false;
    
    try {
      d('[ServerIdResolver] Initializing server ID mappings...');
      
      // Clear existing mappings
      _canonicalMappings.clear();
      _reverseMappings.clear();
      _nameMappings.clear();
      
      // Get servers from both sources
      final appStateServers = appState.servers;
      final npsServers = await database.getAllServers();
      
      d('[ServerIdResolver] Found ${appStateServers.length} AppState servers and ${npsServers.length} NPS servers');
      
      // Build canonical mappings using AppState as the source of truth
      for (final appServer in appStateServers) {
        final canonicalId = appServer.id;
        final normalizedName = _normalizeName(appServer.name);
        
        // Initialize canonical mapping
        _canonicalMappings[canonicalId] = {canonicalId};
        _reverseMappings[canonicalId] = canonicalId;
        _nameMappings[normalizedName] = canonicalId;
        
        // Find matching NPS servers by name
        final matchingNpsServers = npsServers.where((npsServer) {
          final npsName = _normalizeName(npsServer['name'] as String? ?? '');
          return npsName == normalizedName;
        }).toList();
        
        // Add all matching NPS server IDs to the canonical mapping
        for (final npsServer in matchingNpsServers) {
          final npsId = npsServer['id']?.toString() ?? '';
          final npsOriginalId = npsServer['original_id']?.toString() ?? '';
          
          if (npsId.isNotEmpty) {
            _canonicalMappings[canonicalId]!.add(npsId);
            _reverseMappings[npsId] = canonicalId;
          }
          
          if (npsOriginalId.isNotEmpty) {
            _canonicalMappings[canonicalId]!.add(npsOriginalId);
            _reverseMappings[npsOriginalId] = canonicalId;
          }
        }
      }
      
      // Handle orphaned NPS servers (not found in AppState)
      for (final npsServer in npsServers) {
        final npsId = npsServer['id']?.toString() ?? '';
        final npsName = _normalizeName(npsServer['name'] as String? ?? '');
        
        if (npsId.isNotEmpty && !_reverseMappings.containsKey(npsId)) {
          // This is an orphaned NPS server, create a canonical mapping for it
          _canonicalMappings[npsId] = {npsId};
          _reverseMappings[npsId] = npsId;
          if (npsName.isNotEmpty) {
            _nameMappings[npsName] = npsId;
          }
        }
      }
      
      _isInitialized = true;
      d('[ServerIdResolver] ✅ Initialized with ${_canonicalMappings.length} canonical server mappings');
      
      // Debug: Print mappings
      for (final entry in _canonicalMappings.entries) {
        d('[ServerIdResolver] Canonical ID "${entry.key}" maps to: ${entry.value.join(", ")}');
      }
      
    } catch (e) {
      d('[ServerIdResolver] ❌ Error initializing: $e');
      rethrow;
    }
  }
  
  /// Get the canonical server ID for any server ID
  String getCanonicalId(String anyServerId) {
    if (!_isInitialized) {
      d('[ServerIdResolver] ⚠️ Not initialized, returning input ID as-is');
      return anyServerId;
    }
    
    final canonicalId = _reverseMappings[anyServerId];
    if (canonicalId == null) {
      d('[ServerIdResolver] ⚠️ No canonical mapping found for "$anyServerId", returning as-is');
      return anyServerId;
    }
    
    return canonicalId;
  }
  
  /// Get all known IDs for a canonical server ID
  Set<String> getAllKnownIds(String canonicalServerId) {
    if (!_isInitialized) return {canonicalServerId};
    
    return _canonicalMappings[canonicalServerId] ?? {canonicalServerId};
  }
  
  /// Find canonical ID by server name
  String? getCanonicalIdByName(String serverName) {
    if (!_isInitialized) return null;
    
    final normalizedName = _normalizeName(serverName);
    return _nameMappings[normalizedName];
  }
  
  /// Check if two server IDs refer to the same server
  bool areSameServer(String id1, String id2) {
    if (id1 == id2) return true;
    
    final canonical1 = getCanonicalId(id1);
    final canonical2 = getCanonicalId(id2);
    
    return canonical1 == canonical2;
  }
  
  /// Get all canonical server IDs
  Set<String> getAllCanonicalIds() {
    if (!_isInitialized) return {};
    
    return _canonicalMappings.keys.toSet();
  }
  
  /// Normalize server name for matching
  String _normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Reset the resolver (for testing or re-initialization)
  void reset() {
    _canonicalMappings.clear();
    _reverseMappings.clear();
    _nameMappings.clear();
    _isInitialized = false;
  }
  
  /// Static method for compatibility with existing code
  static Future<String?> resolveToStandardId(dynamic serverId) async {
    if (serverId == null) return null;
    return instance.getCanonicalId(serverId.toString());
  }
  
  /// Static method for compatibility with existing code
  static Future<Server?> resolveToServerObject(dynamic serverId) async {
    if (serverId == null) return null;
    final canonicalId = instance.getCanonicalId(serverId.toString());
    
    // Try to get the actual server name from AppState
    try {
      final appState = AppState();
      final server = appState.servers.firstWhere(
        (s) => s.id == canonicalId,
        orElse: () => Server(
          id: canonicalId,
          name: 'Server $canonicalId', // Fallback name only if not found in AppState
        ),
      );
      return server;
    } catch (e) {
      d('[ServerIdResolver] Error resolving server name for $canonicalId: $e');
      // Return a basic server object with canonical ID as fallback
      return Server(
        id: canonicalId,
        name: 'Server $canonicalId', // Fallback name
      );
    }
  }
  
  /// Static method for compatibility with existing code
  static void resetResolver() {
    instance.reset();
  }
  
  /// Get statistics about resolver usage
  static Map<String, dynamic> getStatistics() {
    final instance = ServerIdResolver.instance;
    return {
      'canonical_mappings_count': instance._canonicalMappings.length,
      'reverse_mappings_count': instance._reverseMappings.length,
      'name_mappings_count': instance._nameMappings.length,
      'is_initialized': instance._isInitialized,
    };
  }
  
  /// Generate a mapping report for debugging
  static Future<String> generateMappingReport() async {
    final instance = ServerIdResolver.instance;
    final buffer = StringBuffer();
    
    buffer.writeln('=== Server ID Mapping Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Initialized: ${instance._isInitialized}');
    buffer.writeln('Canonical Mappings: ${instance._canonicalMappings.length}');
    buffer.writeln('Reverse Mappings: ${instance._reverseMappings.length}');
    buffer.writeln('Name Mappings: ${instance._nameMappings.length}');
    buffer.writeln('');
    
    if (instance._isInitialized) {
      buffer.writeln('=== Canonical ID Mappings ===');
      for (final entry in instance._canonicalMappings.entries) {
        buffer.writeln('Canonical ID: "${entry.key}"');
        buffer.writeln('  Maps to: ${entry.value.join(", ")}');
        buffer.writeln('');
      }
    }
    
    return buffer.toString();
  }
  
  /// Debug: Print current mappings
  void debugPrintMappings() {
    if (!_isInitialized) {
      d('[ServerIdResolver] Not initialized');
      return;
    }
    
    d('[ServerIdResolver] Current mappings:');
    for (final entry in _canonicalMappings.entries) {
      d('[ServerIdResolver]   "${entry.key}" -> ${entry.value.join(", ")}');
    }
  }
}