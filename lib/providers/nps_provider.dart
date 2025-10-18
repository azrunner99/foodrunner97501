import 'package:flutter/foundation.dart';
import '../utils/log.dart';
import '../models/server.dart';
import '../models/monthly_report.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import '../services/server_id_resolver.dart';
import '../utils/nps_calculator.dart';
import '../app_state.dart';

/// Centralized state management for the NPS system
/// Handles all server data, feedback processing, and report generation
class NPSProvider with ChangeNotifier {
  final NPSDatabaseAdapter _database;
  late final NPSCalculator _calculator;

  // State variables
  List<NPSServer> _servers = [];
  NPSMonthlyReport? _currentReport;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Constructor
  NPSProvider()
      : _database = NPSDatabaseAdapter(DatabaseFactory.instance) {
    _calculator = NPSCalculator(_database);
  }

  // Getters
  List<NPSServer> get servers => List.unmodifiable(_servers);
  
  /// Get only active (non-archived) servers for current operations
  /// This filters based on the NPS database's active column
  List<NPSServer> get activeServers => 
      List.unmodifiable(_servers.where((s) => s.active).toList());
  
  NPSMonthlyReport? get currentReport => _currentReport;
  NPSCalculator get calculator => _calculator;
  NPSDatabaseAdapter get database => _database;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasServers => _servers.isNotEmpty;
  bool get hasError => _errorMessage != null;

  /// Initialize the provider and load initial data
  /// Optionally sync servers from the main app's AppState
  Future<void> initialize({AppState? appState}) async {
    _setLoading(true);
    try {
      debugPrint(
          '🚨 [NPSProvider] initialize() called with appState: ${appState != null ? "PRESENT" : "NULL"}');

      // Sync servers from main app if provided
      if (appState != null) {
        debugPrint(
            '🚨 [NPSProvider] About to call _syncServersFromAppState...');
        await _syncServersFromAppState(appState);
        debugPrint('🚨 [NPSProvider] _syncServersFromAppState completed');
      } else {
        debugPrint('🚨 [NPSProvider] Skipping sync - no AppState provided');
      }

      await _loadServers();
      await _generateCurrentReport();
      _isInitialized = true;
      _clearError();
    } catch (e) {
      _setError('Failed to initialize NPS system: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sync servers from the main app's AppState to the NPS system
  Future<void> _syncServersFromAppState(AppState appState) async {
    try {
      debugPrint('🔥 [NPSProvider] Starting server sync from AppState...');
      debugPrint(
          '🔥 [NPSProvider] Main app has ${appState.servers.length} servers');
      
      // Build lookup indexes once for efficient and robust matching
      debugPrint('🔥 [NPSProvider] About to call _database.getAllServers()...');
      final existingServerMaps = await _database.getAllServers();
      debugPrint('🔥 [NPSProvider] Successfully got ${existingServerMaps.length} servers from database');
      debugPrint(
          '🔥 [NPSProvider] NPS system has ${existingServerMaps.length} servers');

      String norm(String? s) => (s ?? '').trim().toLowerCase();

      // Create sets of AppState server IDs for cleanup
      final appStateServerIds = appState.servers.map((s) => s.id).toSet();
      final appStateServerNames = appState.servers.map((s) => norm(s.name)).toSet();

      final byOriginalId = <String, Map<String, dynamic>>{};
      final byName = <String, Map<String, dynamic>>{};
      for (final m in existingServerMaps) {
        final oid = norm(m['original_id'] as String?);
        if (oid.isNotEmpty) byOriginalId[oid] = m;
        byName[norm(m['name'] as String?)] = m;
      }

      // TEMPORARY FIX: Skip complex cleanup and just ensure servers exist
      debugPrint('🔥 [NPSProvider] Skipping cleanup for now - focusing on data loading fix');

      for (final mainServer in appState.servers) {
        final mainIdNorm = norm(mainServer.id);
        final mainNameNorm = norm(mainServer.name);
        debugPrint(
            '🔥 [NPSProvider] Processing server: ${mainServer.name} (ID: ${mainServer.id})');

        Map<String, dynamic>? existingServer =
            byOriginalId[mainIdNorm] ?? byName[mainNameNorm];

        if (existingServer == null) {
          // Server doesn't exist in NPS system, add it
          // Use the main server ID as the NPS server ID (convert to TEXT)
          final serverMap = {
            'id': mainServer.id.trim(), // Use main app server ID as TEXT primary key
            'name': mainServer.name.trim(),
            'original_id':
                mainServer.id.trim(), // Store the original main app server ID
            'hire_date':
                (mainServer.hireDate ?? DateTime.now()).toIso8601String(),
            'active': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          await _database.insertServer(serverMap);
          // Update indexes
          serverMap['id'] = mainServer.id.trim();
          byOriginalId[mainIdNorm] = serverMap;
          byName[mainNameNorm] = serverMap;
          debugPrint(
              '🔥 [NPSProvider] ✅ Synced server: ${mainServer.name} (original_id: ${mainServer.id})');
        } else {
          // Server exists, ensure original_id is present and normalized
          final needsOriginalId = (existingServer['original_id'] == null) ||
              norm(existingServer['original_id'] as String?).isEmpty;
          if (needsOriginalId && mainServer.id.trim().isNotEmpty) {
            try {
              final serverId = existingServer['id']?.toString();
              if (serverId != null) {
                await _database.updateServer(serverId,
                    {'original_id': mainServer.id.trim()});
                existingServer['original_id'] = mainServer.id.trim();
                byOriginalId[mainIdNorm] = existingServer;
                debugPrint(
                    '🔥 [NPSProvider] ✅ Updated original_id for existing server: ${mainServer.name}');
              }
            } catch (e) {
              debugPrint(
                  '🔥 [NPSProvider] ⚠️ Could not update original_id for ${mainServer.name}: $e');
            }
          }
          debugPrint(
              '[NPSProvider] ⏭️ Server already exists: ${mainServer.name}');
        }
      }
      // Refresh the ServerIdResolver with the cleaned-up server data
      await ServerIdResolver.instance.initialize(appState, _database);
      
      debugPrint('[NPSProvider] Server sync completed!');
    } catch (e) {
      debugPrint('[NPSProvider] ❌ Error syncing servers: $e');
    }
  }

  /// Diagnostic: Validate joins between main AppState servers and NPS servers
  Future<void> diagnoseJoins(AppState appState) async {
    try {
      final existingServerMaps = await _database.getAllServers();
      String norm(String? s) => (s ?? '').trim().toLowerCase();
      final byOriginalId = <String, Map<String, dynamic>>{
        for (final m in existingServerMaps)
          if (((m['original_id'] as String?) ?? '').trim().isNotEmpty)
            norm(m['original_id'] as String?): m
      };
      final byName = <String, Map<String, dynamic>>{
        for (final m in existingServerMaps) norm(m['name'] as String?): m
      };

      int ok = 0, missing = 0, needsOid = 0;
      for (final mainServer in appState.servers) {
        final match =
            byOriginalId[norm(mainServer.id)] ?? byName[norm(mainServer.name)];
        if (match == null) {
          debugPrint(
              '🧩 [NPSProvider] Join missing → Main:"${mainServer.name}" (id:${mainServer.id}) not found in NPS');
          missing++;
        } else {
          final hasOid =
              (((match['original_id'] as String?) ?? '').trim().isNotEmpty);
          if (!hasOid) {
            debugPrint(
                '🧩 [NPSProvider] Join weak → NPS:"${match['name']}" lacks original_id (will rely on name match)');
            needsOid++;
          } else {
            ok++;
          }
        }
      }
      debugPrint(
          '🧩 [NPSProvider] Join diagnostics → OK:$ok, Needs original_id:$needsOid, Missing:$missing');
    } catch (e) {
      debugPrint('🧩 [NPSProvider] Join diagnostics failed: $e');
    }
  }

  /// Load all servers from the database
  Future<void> _loadServers() async {
    try {
      final serverMaps = await _database.getAllServers();
      _servers = serverMaps.map((map) => NPSServer.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load servers: $e');
    }
  }


  /// Generate the current month's report
  Future<void> _generateCurrentReport() async {
    try {
      final now = DateTime.now();
      final reportMonth = now.year * 100 + now.month;

      // Get the first server as example for monthly report
      if (_servers.isNotEmpty) {
        _currentReport = await _calculator.generateMonthlyReport(
          _servers.first.id,
          reportMonth,
        );
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to generate current report: $e');
    }
  }

  // Server Management Operations

  /// Add a new server to the system
  Future<bool> addServer(NPSServer server) async {
    _setLoading(true);
    try {
      // Validate server data
      if (!server.isValid()) {
        throw Exception('Server data is invalid');
      }

      // Check if server name already exists
      final existingServer = _servers
          .where(
            (s) => s.name.toLowerCase() == server.name.toLowerCase(),
          )
          .firstOrNull;

      if (existingServer != null) {
        throw Exception('A server with this name already exists');
      }

      // Add to database
      final serverId = await _database.insertServer(server.toMap());
      final newServer = server.copyWith(id: serverId);
      _servers.add(newServer);
      _servers.sort((a, b) => a.name.compareTo(b.name));

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add server: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing server
  Future<bool> updateServer(NPSServer server) async {
    _setLoading(true);
    try {
      // Validate server data
      if (!server.isValid()) {
        throw Exception('Server data is invalid');
      }

      if (server.id.isEmpty) {
        throw Exception('Cannot update server without ID');
      }

      // Update in database
      await _database.updateServer(server.id, server.toMap());

      // Update in local state
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        _servers[index] = server;
        _servers.sort((a, b) => a.name.compareTo(b.name));
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update server: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a server from the system (soft delete)
  Future<bool> deleteServer(String serverId) async {
    _setLoading(true);
    try {
      // Check if server has feedback
      final feedback = await _database.getFeedbackForServer(serverId);
      if (feedback.isNotEmpty) {
        throw Exception(
            'Cannot delete server with existing feedback. Archive server instead.');
      }

      // Delete from database (soft delete - sets active = 0)
      await _database.deleteServer(serverId);

      // Update local state
      final index = _servers.indexWhere((s) => s.id == serverId);
      if (index != -1) {
        final server = _servers[index];
        _servers[index] = server.copyWith(active: false);
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete server: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Archive a server (set as inactive)
  Future<bool> archiveServer(String serverId, {AppState? appState}) async {
    try {
      final server = _servers.firstWhere((s) => s.id == serverId);
      final archivedServer = server.copyWith(active: false);

      final success = await updateServer(archivedServer);
      
      // Also sync to AppState's isArchived flag if provided
      if (success && appState != null) {
        final profile = appState.profiles[serverId] ?? ServerProfile();
        final updatedProfile = profile.copyWith(
          isArchived: true,
          archiveNotes: 'Archived via NPS Management',
        );
        await appState.updateServerProfile(serverId, updatedProfile);
      }
      
      return success;
    } catch (e) {
      _setError('Failed to archive server: $e');
      return false;
    }
  }

  /// Get server by ID
  NPSServer? getServerById(String serverId) {
    try {
      return _servers.firstWhere((s) => s.id == serverId);
    } catch (e) {
      return null;
    }
  }


  // Analytics and Reporting

  /// Calculate NPS for a specific server
  Future<Map<String, dynamic>> calculateServerNPS(
    String serverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      double? npsScore;

      if (startDate == null && endDate == null) {
        // All-time NPS
        npsScore = await _calculator.calculateAllTimeNPS(serverId);
      }

      return {
        'nps_score': npsScore,
        'server_id': serverId,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
    } catch (e) {
      _setError('Failed to calculate server NPS: $e');
      return {};
    }
  }


  /// Refresh all data from database
  Future<void> refreshData() async {
    await initialize();
  }

  /// Get server NPS data for a specific month
  Future<List<Map<String, dynamic>>> getServerNPSDataForMonth(
      int reportMonth, int reportYear) async {
    try {
      print('[NPSProvider] getServerNPSDataForMonth called with month: $reportMonth, year: $reportYear');
      final result = await _database.getServerNPSDataForMonth(reportMonth, reportYear);
      print('[NPSProvider] Database returned ${result.length} records');
      for (int i = 0; i < result.length; i++) {
        print('[NPSProvider] Record $i: ${result[i]}');
      }
      return result;
    } catch (e) {
      print('[NPSProvider] Error in getServerNPSDataForMonth: $e');
      _setError('Failed to load server NPS data for month: $e');
      return [];
    }
  }

  /// Generate monthly reports for a specific month
  Future<void> generateMonthlyReports(int reportMonth, int reportYear) async {
    try {
      _setLoading(true);
      
      // Convert to YYYYMM format
      final monthKey = reportYear * 100 + reportMonth;
      
      debugPrint('[NPSProvider] Generating monthly reports for $reportMonth/$reportYear (monthKey: $monthKey)');
      
      // Generate reports for all servers
      final reports = await _calculator.generateMonthlyReportsForAllServers(monthKey);
      
      debugPrint('[NPSProvider] Generated ${reports.length} monthly reports');
      
      // Save each report to the database
      for (final report in reports) {
        await _calculator.saveMonthlyReport(report);
      }
      
      debugPrint('[NPSProvider] Successfully saved all monthly reports for $reportMonth/$reportYear');
      
    } catch (e) {
      debugPrint('[NPSProvider] Error generating monthly reports: $e');
      _setError('Failed to generate monthly reports: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get all-time NPS metrics for a server from monthly reports
  /// This is used as fallback when no current period NPS data exists
  Future<Map<String, dynamic>?> getAllTimeNPSMetrics(String serverId) async {
    try {
      // Find the NPS server ID mapping for the given main app server ID
      final npsServer = _servers.firstWhere(
        (server) => server.originalId == serverId,
        orElse: () => throw Exception(
            'No NPS server found for main app server ID: $serverId'),
      );

      // Generate month numbers for the last 12 months to find any existing reports
      final now = DateTime.now();
      double totalChecks = 0;
      double totalSales = 0;
      int reportsFound = 0;

      for (int i = 0; i < 12; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final reportMonth = monthDate.month;

        final reportData =
            await _database.getMonthlyReport(npsServer.id, reportMonth);
        if (reportData != null && reportData.isNotEmpty) {
          reportsFound++;
          // Use all_time data from the most recent report found
          if (reportData.containsKey('all_time_table_count')) {
            totalChecks =
                (reportData['all_time_table_count'] as num?)?.toDouble() ?? 0;
          }
          if (reportData.containsKey('all_time_sales')) {
            totalSales =
                (reportData['all_time_sales'] as num?)?.toDouble() ?? 0;
          }

          // If we found a report with all_time data, use it and break
          if (totalChecks > 0 || totalSales > 0) {
      d('DEBUG: Found all-time NPS data for server $serverId: $totalChecks checks, \$${totalSales.toStringAsFixed(2)} sales');
            break;
          }
        }
      }

      if (reportsFound > 0 && (totalChecks > 0 || totalSales > 0)) {
        return {
          'checks': totalChecks,
          'sales': totalSales,
          'reportsFound': reportsFound,
        };
      } else {
  d('DEBUG: No all-time NPS data found for server $serverId');
        return null;
      }
    } catch (e) {
    d('DEBUG: Error getting all-time NPS metrics for server $serverId: $e');
      return null;
    }
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
}
