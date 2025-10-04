import 'package:flutter/foundation.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../utils/log.dart';

/// Diagnostic service for troubleshooting NPS data saving and syncing issues
class NPSDebugService {
  static const String _logPrefix = '[NPSDebugService]';
  
  /// Comprehensive diagnostic report for NPS data issues
  static Future<NPSDebugReport> generateDebugReport(
    NPSProvider npsProvider, 
    AppState appState
  ) async {
    d('$_logPrefix Starting comprehensive NPS debug analysis...');
    
    final report = NPSDebugReport();
    
    // 1. Check NPSProvider initialization
    report.npsInitialized = npsProvider.isInitialized;
    report.npsHasError = npsProvider.hasError;
    report.npsErrorMessage = npsProvider.errorMessage;
    
    // 2. Analyze server counts and mapping
    report.appStateServerCount = appState.servers.length;
    report.npsProviderServerCount = npsProvider.servers.length;
    
    // 3. Check server ID mappings
    final serverMappings = <NPSServerMapping>[];
    for (final appServer in appState.servers) {
      final npsServer = npsProvider.servers
          .where((s) => s.originalId == appServer.id || s.name == appServer.name)
          .firstOrNull;
          
      serverMappings.add(NPSServerMapping(
        appServerId: appServer.id,
        appServerName: appServer.name,
        npsServerId: npsServer?.id,
        npsServerName: npsServer?.name,
        npsOriginalId: npsServer?.originalId,
        isMapped: npsServer != null,
      ));
    }
    report.serverMappings = serverMappings;
    
    // 4. Check database connectivity and schema
    try {
      final dbServers = await npsProvider.database.getAllServers();
      report.databaseServerCount = dbServers.length;
      report.databaseConnected = true;
      
      // Check for sample monthly report
      if (dbServers.isNotEmpty) {
        final now = DateTime.now();
        // Use adapter-compatible API: month + year separate
        final month = now.month;
        final year = now.year;
        // Temporarily skip direct monthly report fetch (adapter visibility issue workaround)
        report.hasSampleData = false;
      }
    } catch (e) {
      report.databaseConnected = false;
      report.databaseError = e.toString();
    }
    
    // 5. Check available report months
    try {
      final availableMonths = await npsProvider.database.getAvailableReportMonths();
      report.availableReportMonths = availableMonths.length;
      report.recentReportMonths = availableMonths.take(3).toList();
    } catch (e) {
      report.availableReportMonths = 0;
      report.monthsError = e.toString();
    }
    
    d('$_logPrefix Debug report generation complete');
    return report;
  }
  
  /// Fix common NPS data issues
  static Future<List<String>> autoFixCommonIssues(
    NPSProvider npsProvider, 
    AppState appState
  ) async {
    final fixes = <String>[];
    
    try {
      // 1. Re-initialize NPSProvider if not initialized
      if (!npsProvider.isInitialized) {
        await npsProvider.initialize(appState: appState);
        fixes.add('Re-initialized NPSProvider with AppState servers');
      }
      
      // 2. Run server diagnostics and sync
      await npsProvider.diagnoseJoins(appState);
      fixes.add('Completed server join diagnostics');
      
      // 3. Verify database connectivity
      try {
        await npsProvider.database.getAllServers();
        fixes.add('Verified database connectivity');
      } catch (e) {
        fixes.add('Database connectivity issue detected: $e');
      }
      
    } catch (e) {
      fixes.add('Auto-fix failed: $e');
    }
    
    return fixes;
  }
  
  /// Print detailed debug information to console
  static void printDebugInfo(NPSDebugReport report) {
    print('\\n' + '='*60);
    print('NPS DATA DEBUG REPORT');
    print('='*60);
    
    print('\\n🔧 SYSTEM STATUS:');
    print('  NPS Initialized: ${report.npsInitialized}');
    print('  Has Error: ${report.npsHasError}');
    if (report.npsErrorMessage != null) {
      print('  Error: ${report.npsErrorMessage}');
    }
    
    print('\\n📊 SERVER COUNTS:');
    print('  AppState Servers: ${report.appStateServerCount}');
    print('  NPSProvider Servers: ${report.npsProviderServerCount}');
    print('  Database Servers: ${report.databaseServerCount}');
    
    print('\\n🔗 SERVER MAPPINGS:');
    for (final mapping in report.serverMappings) {
      final status = mapping.isMapped ? '✅' : '❌';
      print('  $status ${mapping.appServerName} (${mapping.appServerId})');
      if (mapping.isMapped) {
        print('    → NPS ID: ${mapping.npsServerId}, Original: ${mapping.npsOriginalId}');
      } else {
        print('    → NOT MAPPED TO NPS SYSTEM');
      }
    }
    
    print('\\n💾 DATABASE STATUS:');
    print('  Connected: ${report.databaseConnected}');
    if (report.databaseError != null) {
      print('  Error: ${report.databaseError}');
    }
    print('  Has Sample Data: ${report.hasSampleData}');
    print('  Available Report Months: ${report.availableReportMonths}');
    
    if (report.recentReportMonths.isNotEmpty) {
      print('\\n📅 RECENT REPORT MONTHS:');
      for (final month in report.recentReportMonths) {
        print('  ${month['report_year']}-${month['report_month'].toString().padLeft(2, '0')} (${month['server_count']} servers)');
      }
    }
    
    print('\\n' + '='*60);
    print('END DEBUG REPORT');
    print('='*60 + '\\n');
  }
}

/// Data model for NPS debug report
class NPSDebugReport {
  bool npsInitialized = false;
  bool npsHasError = false;
  String? npsErrorMessage;
  
  int appStateServerCount = 0;
  int npsProviderServerCount = 0;
  int databaseServerCount = 0;
  
  List<NPSServerMapping> serverMappings = [];
  
  bool databaseConnected = false;
  String? databaseError;
  bool hasSampleData = false;
  
  int availableReportMonths = 0;
  List<Map<String, dynamic>> recentReportMonths = [];
  String? monthsError;
}

/// Server mapping information
class NPSServerMapping {
  final String appServerId;
  final String appServerName;
  final String? npsServerId;
  final String? npsServerName;
  final String? npsOriginalId;
  final bool isMapped;
  
  NPSServerMapping({
    required this.appServerId,
    required this.appServerName,
    this.npsServerId,
    this.npsServerName,
    this.npsOriginalId,
    required this.isMapped,
  });
}