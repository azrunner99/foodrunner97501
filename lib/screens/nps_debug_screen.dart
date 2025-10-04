import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../services/nps_debug_service.dart';

/// Debug screen for troubleshooting NPS data issues
class NPSDebugScreen extends StatefulWidget {
  const NPSDebugScreen({super.key});

  @override
  State<NPSDebugScreen> createState() => _NPSDebugScreenState();
}

class _NPSDebugScreenState extends State<NPSDebugScreen> {
  NPSDebugReport? _debugReport;
  List<String> _autoFixResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final npsProvider = context.read<NPSProvider>();
      final appState = context.read<AppState>();
      
      final report = await NPSDebugService.generateDebugReport(npsProvider, appState);
      setState(() {
        _debugReport = report;
      });
      
      // Print detailed info to console
      NPSDebugService.printDebugInfo(report);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug analysis failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runAutoFix() async {
    setState(() {
      _isLoading = true;
      _autoFixResults.clear();
    });

    try {
      final npsProvider = context.read<NPSProvider>();
      final appState = context.read<AppState>();
      
      final fixes = await NPSDebugService.autoFixCommonIssues(npsProvider, appState);
      setState(() {
        _autoFixResults = fixes;
      });
      
      // Re-run diagnostics after fixes
      await _runDiagnostics();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied ${fixes.length} fixes'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-fix failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NPS Debug & Diagnostics'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
            tooltip: 'Refresh Diagnostics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Running diagnostics...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  if (_debugReport != null) ...[
                    _buildSystemStatusCard(),
                    const SizedBox(height: 16),
                    _buildServerMappingCard(),
                    const SizedBox(height: 16),
                    _buildDatabaseStatusCard(),
                    const SizedBox(height: 16),
                    _buildReportMonthsCard(),
                  ],
                  if (_autoFixResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAutoFixResultsCard(),
                  ],
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'NPS System Diagnostics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This screen helps diagnose and fix common issues with NPS data saving and syncing.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    final report = _debugReport!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 System Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('NPS Initialized', report.npsInitialized),
            _buildStatusRow('Has Error', report.npsHasError, isError: true),
            if (report.npsErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Error: ${report.npsErrorMessage}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerMappingCard() {
    final report = _debugReport!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔗 Server Mappings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'App: ${report.appStateServerCount} | NPS: ${report.npsProviderServerCount}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...report.serverMappings.map((mapping) => _buildServerMappingRow(mapping)),
          ],
        ),
      ),
    );
  }

  Widget _buildServerMappingRow(NPSServerMapping mapping) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            mapping.isMapped ? Icons.check_circle : Icons.error,
            color: mapping.isMapped ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mapping.appServerName} (${mapping.appServerId})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (mapping.isMapped)
                  Text(
                    'NPS ID: ${mapping.npsServerId}, Original: ${mapping.npsOriginalId}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  )
                else
                  Text(
                    'NOT MAPPED',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseStatusCard() {
    final report = _debugReport!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💾 Database Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Connected', report.databaseConnected),
            _buildStatusRow('Has Sample Data', report.hasSampleData),
            Text('Database Servers: ${report.databaseServerCount}'),
            if (report.databaseError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DB Error: ${report.databaseError}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportMonthsCard() {
    final report = _debugReport!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Report Months (${report.availableReportMonths} total)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (report.recentReportMonths.isEmpty)
              Text(
                'No report months found',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...report.recentReportMonths.map(
                (month) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${month['report_year']}-${month['report_month'].toString().padLeft(2, '0')} (${month['server_count']} servers)',
                  ),
                ),
              ),
            if (report.monthsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Error: ${report.monthsError}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoFixResultsCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 Auto-Fix Results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ..._autoFixResults.map(
              (fix) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(fix)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runAutoFix,
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Run Auto-Fix'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _runDiagnostics,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Diagnostics'),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool status, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status 
              ? (isError ? Icons.error : Icons.check_circle) 
              : (isError ? Icons.check_circle : Icons.error),
            color: status 
              ? (isError ? Colors.red : Colors.green) 
              : (isError ? Colors.green : Colors.red),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            status.toString(),
            style: TextStyle(
              color: status 
                ? (isError ? Colors.red : Colors.green) 
                : (isError ? Colors.green : Colors.red),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}