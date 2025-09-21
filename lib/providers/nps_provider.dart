import 'package:flutter/foundation.dart';
import '../utils/log.dart';
import '../models/server.dart';
import '../models/nps_feedback.dart';
import '../models/monthly_report.dart';
import '../storage/nps_database.dart';
import '../utils/nps_calculator.dart';
import '../app_state.dart';

/// Centralized state management for the NPS system
/// Handles all server data, feedback processing, and report generation
class NPSProvider with ChangeNotifier {
  final NPSDatabase _database;
  final NPSCalculator _calculator;

  // State variables
  List<NPSServer> _servers = [];
  List<NPSFeedback> _recentFeedback = [];
  NPSMonthlyReport? _currentReport;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Constructor
  NPSProvider()
      : _database = NPSDatabase.instance,
        _calculator = NPSCalculator();

  // Getters
  List<NPSServer> get servers => List.unmodifiable(_servers);
  List<NPSFeedback> get recentFeedback => List.unmodifiable(_recentFeedback);
  NPSMonthlyReport? get currentReport => _currentReport;
  NPSCalculator get calculator => _calculator;
  NPSDatabase get database => _database;
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
      await _loadRecentFeedback();
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
      final existingServerMaps = await _database.getAllServers();
      debugPrint(
          '🔥 [NPSProvider] NPS system has ${existingServerMaps.length} servers');

      String norm(String? s) => (s ?? '').trim().toLowerCase();

      final byOriginalId = <String, Map<String, dynamic>>{};
      final byName = <String, Map<String, dynamic>>{};
      for (final m in existingServerMaps) {
        final oid = norm(m['original_id'] as String?);
        if (oid.isNotEmpty) byOriginalId[oid] = m;
        byName[norm(m['name'] as String?)] = m;
      }

      for (final mainServer in appState.servers) {
        final mainIdNorm = norm(mainServer.id);
        final mainNameNorm = norm(mainServer.name);
        debugPrint(
            '🔥 [NPSProvider] Processing server: ${mainServer.name} (ID: ${mainServer.id})');

        Map<String, dynamic>? existingServer =
            byOriginalId[mainIdNorm] ?? byName[mainNameNorm];

        if (existingServer == null) {
          // Server doesn't exist in NPS system, add it
          final serverMap = {
            'name': mainServer.name.trim(),
            'original_id':
                mainServer.id.trim(), // Store the original main app server ID
            'hire_date':
                (mainServer.hireDate ?? DateTime.now()).toIso8601String(),
            'active': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          final newId = await _database.insertServer(serverMap);
          // Update indexes
          serverMap['id'] = newId;
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
              await _database.updateServer(existingServer['id'] as int,
                  {'original_id': mainServer.id.trim()});
              existingServer['original_id'] = mainServer.id.trim();
              byOriginalId[mainIdNorm] = existingServer;
              debugPrint(
                  '🔥 [NPSProvider] ✅ Updated original_id for existing server: ${mainServer.name}');
            } catch (e) {
              debugPrint(
                  '🔥 [NPSProvider] ⚠️ Could not update original_id for ${mainServer.name}: $e');
            }
          }
          debugPrint(
              '[NPSProvider] ⏭️ Server already exists: ${mainServer.name}');
        }
      }
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

  /// Load recent feedback (last 30 days) from the database
  Future<void> _loadRecentFeedback() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final feedbackMaps = await _database.getFeedbackInDateRange(
        thirtyDaysAgo,
        DateTime.now(),
      );
      _recentFeedback =
          feedbackMaps.map((map) => NPSFeedback.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recent feedback: $e');
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
          _servers.first.id!,
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

      if (server.id == null) {
        throw Exception('Cannot update server without ID');
      }

      // Update in database
      await _database.updateServer(server.id!, server.toMap());

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
  Future<bool> deleteServer(int serverId) async {
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
  Future<bool> archiveServer(int serverId) async {
    try {
      final server = _servers.firstWhere((s) => s.id == serverId);
      final archivedServer = server.copyWith(active: false);

      return await updateServer(archivedServer);
    } catch (e) {
      _setError('Failed to archive server: $e');
      return false;
    }
  }

  /// Get server by ID
  NPSServer? getServerById(int serverId) {
    try {
      return _servers.firstWhere((s) => s.id == serverId);
    } catch (e) {
      return null;
    }
  }

  /// Get active servers only
  List<NPSServer> get activeServers {
    return _servers.where((s) => s.active).toList();
  }

  // Feedback Management Operations

  /// Submit new feedback for a server
  Future<bool> submitFeedback(NPSFeedback feedback) async {
    _setLoading(true);
    try {
      // Validate feedback
      if (!feedback.isValid()) {
        throw Exception('Feedback data is invalid');
      }

      // Verify server exists and is active
      final server = getServerById(feedback.serverId);
      if (server == null) {
        throw Exception('Server not found');
      }
      if (!server.active) {
        throw Exception('Cannot submit feedback for inactive server');
      }

      // Add to database
      final feedbackId = await _database.insertFeedback(feedback.toMap());
      final newFeedback = feedback.copyWith(id: feedbackId);

      // Update recent feedback if within last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      if (newFeedback.feedbackDate.isAfter(thirtyDaysAgo)) {
        _recentFeedback.add(newFeedback);
        _recentFeedback
            .sort((a, b) => b.feedbackDate.compareTo(a.feedbackDate));
      }

      // Regenerate current report if feedback is for current month
      final now = DateTime.now();
      if (newFeedback.feedbackDate.year == now.year &&
          newFeedback.feedbackDate.month == now.month) {
        await _generateCurrentReport();
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to submit feedback: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get feedback for a specific server
  Future<List<NPSFeedback>> getServerFeedback(int serverId) async {
    try {
      final feedbackMaps = await _database.getFeedbackForServer(serverId);
      return feedbackMaps.map((map) => NPSFeedback.fromMap(map)).toList();
    } catch (e) {
      _setError('Failed to load server feedback: $e');
      return [];
    }
  }

  /// Get feedback within a date range
  Future<List<NPSFeedback>> getFeedbackByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final feedbackMaps =
          await _database.getFeedbackInDateRange(startDate, endDate);
      return feedbackMaps.map((map) => NPSFeedback.fromMap(map)).toList();
    } catch (e) {
      _setError('Failed to load feedback by date range: $e');
      return [];
    }
  }

  // Analytics and Reporting

  /// Calculate NPS for a specific server
  Future<Map<String, dynamic>> calculateServerNPS(
    int serverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      double? npsScore;

      if (startDate == null && endDate == null) {
        // All-time NPS
        npsScore = await _calculator.calculateAllTimeNPS(serverId);
      } else if (startDate != null && endDate != null) {
        // Date range NPS - use feedback data directly
        final feedbackMaps =
            await _database.getFeedbackInDateRange(startDate, endDate);
        final feedback = feedbackMaps
            .map((map) => NPSFeedback.fromMap(map))
            .where((f) => f.serverId == serverId)
            .toList();

        // Calculate NPS manually for date range
        if (feedback.isEmpty) {
          npsScore = null;
        } else {
          final yes =
              feedback.where((f) => f.feedbackType == FeedbackType.yes).length;
          final no =
              feedback.where((f) => f.feedbackType == FeedbackType.no).length;
          final total = feedback.length;

          if (total > 0) {
            npsScore = ((yes - no) / total) * 100;
          }
        }
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

  /// Generate comprehensive analytics report
  Future<Map<String, dynamic>> generateAnalyticsReport() async {
    try {
      final analytics = <String, dynamic>{};

      // Get overall statistics
      analytics['total_servers'] = _servers.length;
      analytics['active_servers'] = _servers.where((s) => s.active).length;
      analytics['total_feedback'] = _recentFeedback.length;

      // Calculate overall NPS for all servers
      if (_recentFeedback.isNotEmpty) {
        final yes = _recentFeedback
            .where((f) => f.feedbackType == FeedbackType.yes)
            .length;
        final no = _recentFeedback
            .where((f) => f.feedbackType == FeedbackType.no)
            .length;
        final total = _recentFeedback.length;

        analytics['overall_nps'] = ((yes - no) / total) * 100;
        analytics['feedback_breakdown'] = {
          'yes': yes,
          'maybe': _recentFeedback
              .where((f) => f.feedbackType == FeedbackType.maybe)
              .length,
          'no': no,
        };
      }

      return analytics;
    } catch (e) {
      _setError('Failed to generate analytics report: $e');
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
      return await _database.getServerNPSDataForMonth(reportMonth, reportYear);
    } catch (e) {
      _setError('Failed to load server NPS data for month: $e');
      return [];
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
            await _database.getMonthlyReport(npsServer.id!, reportMonth);
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
