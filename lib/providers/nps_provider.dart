import 'package:flutter/foundation.dart';
import '../models/server.dart';
import '../models/nps_feedback.dart';
import '../models/monthly_report.dart';
import '../storage/nps_database.dart';
import '../utils/nps_calculator.dart';
import '../app_state.dart';
import '../models.dart' as main_models;

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
  NPSProvider() : _database = NPSDatabase.instance, _calculator = NPSCalculator();
  
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
      // Sync servers from main app if provided
      if (appState != null) {
        await _syncServersFromAppState(appState);
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
      debugPrint('[NPSProvider] Starting server sync from AppState...');
      debugPrint('[NPSProvider] Main app has ${appState.servers.length} servers');
      
      for (final mainServer in appState.servers) {
        debugPrint('[NPSProvider] Processing server: ${mainServer.name}');
        
        // Check if server already exists in NPS system
        final existingServerMaps = await _database.getAllServers();
        debugPrint('[NPSProvider] NPS system has ${existingServerMaps.length} servers');
        
        final existingServer = existingServerMaps.firstWhere(
          (serverMap) => serverMap['name'] == mainServer.name,
          orElse: () => <String, dynamic>{},
        );

        if (existingServer.isEmpty) {
          // Server doesn't exist in NPS system, add it
          final serverMap = {
            'name': mainServer.name,
            'hire_date': (mainServer.hireDate ?? DateTime.now()).toIso8601String(),
            'active': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          await _database.insertServer(serverMap);
          debugPrint('[NPSProvider] ✅ Synced server: ${mainServer.name}');
        } else {
          debugPrint('[NPSProvider] ⏭️ Server already exists: ${mainServer.name}');
        }
      }
      debugPrint('[NPSProvider] Server sync completed!');
    } catch (e) {
      debugPrint('[NPSProvider] ❌ Error syncing servers: $e');
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
      _recentFeedback = feedbackMaps.map((map) => NPSFeedback.fromMap(map)).toList();
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
      final existingServer = _servers.where(
        (s) => s.name.toLowerCase() == server.name.toLowerCase(),
      ).firstOrNull;
      
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
        throw Exception('Cannot delete server with existing feedback. Archive server instead.');
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
        _recentFeedback.sort((a, b) => b.feedbackDate.compareTo(a.feedbackDate));
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
      final feedbackMaps = await _database.getFeedbackInDateRange(startDate, endDate);
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
        final feedbackMaps = await _database.getFeedbackInDateRange(startDate, endDate);
        final feedback = feedbackMaps.map((map) => NPSFeedback.fromMap(map))
            .where((f) => f.serverId == serverId)
            .toList();
        
        // Calculate NPS manually for date range
        if (feedback.isEmpty) {
          npsScore = null;
        } else {
          final yes = feedback.where((f) => f.feedbackType == FeedbackType.yes).length;
          final no = feedback.where((f) => f.feedbackType == FeedbackType.no).length;
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
        final yes = _recentFeedback.where((f) => f.feedbackType == FeedbackType.yes).length;
        final no = _recentFeedback.where((f) => f.feedbackType == FeedbackType.no).length;
        final total = _recentFeedback.length;
        
        analytics['overall_nps'] = ((yes - no) / total) * 100;
        analytics['feedback_breakdown'] = {
          'yes': yes,
          'maybe': _recentFeedback.where((f) => f.feedbackType == FeedbackType.maybe).length,
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