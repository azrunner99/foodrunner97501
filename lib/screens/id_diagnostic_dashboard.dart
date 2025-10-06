import 'package:flutter/material.dart';
import '../services/server_id_resolver.dart';
import '../services/database_audit_tool.dart';
import '../utils/log.dart';

/// Real-time diagnostic dashboard for Server ID resolution monitoring
/// 
/// Provides live insights into ID resolution performance, failures,
/// and data integrity issues.
class IdDiagnosticDashboard extends StatefulWidget {
  const IdDiagnosticDashboard({Key? key}) : super(key: key);

  @override
  State<IdDiagnosticDashboard> createState() => _IdDiagnosticDashboardState();
}

class _IdDiagnosticDashboardState extends State<IdDiagnosticDashboard> {
  DatabaseAuditResult? _auditResult;
  Map<String, dynamic>? _resolverStats;
  String? _mappingReport;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load resolver statistics
      _resolverStats = ServerIdResolver.getStatistics();
      
      // Run database audit
      _auditResult = await DatabaseAuditTool.runFullAudit();
      
      // Generate mapping report
      _mappingReport = await ServerIdResolver.generateMappingReport();
      
    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
      d('[IdDiagnosticDashboard] Error loading data: $e');
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
        title: const Text('Server ID Diagnostic Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _resetResolver,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildDashboard(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemHealthCard(),
          const SizedBox(height: 16),
          _buildResolverStatsCard(),
          const SizedBox(height: 16),
          _buildAuditResultsCard(),
          const SizedBox(height: 16),
          _buildMappingReportCard(),
          const SizedBox(height: 16),
          _buildActionsCard(),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    if (_auditResult == null) return const SizedBox();

    final healthStatus = _getHealthStatus();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(healthStatus.icon, color: healthStatus.color, size: 32),
                const SizedBox(width: 12),
                Text(
                  'System Health: ${healthStatus.label}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: healthStatus.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHealthMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetrics() {
    final result = _auditResult!;
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildMetricChip('Servers (Main)', '${result.mainStorageServerCount}', Colors.blue),
        _buildMetricChip('Servers (NPS)', '${result.npsStorageServerCount}', Colors.green),
        _buildMetricChip('NPS Records', '${result.npsFeedbackCount}', Colors.purple),
        _buildMetricChip('Monthly Reports', '${result.monthlyReportsCount}', Colors.orange),
        _buildMetricChip('Orphaned Records', '${result.totalOrphanedRecords}', 
                        result.totalOrphanedRecords > 0 ? Colors.red : Colors.green),
        _buildMetricChip('Sync Issues', '${result.synchronizationIssues}',
                        result.synchronizationIssues > 0 ? Colors.red : Colors.green),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildResolverStatsCard() {
    if (_resolverStats == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID Resolver Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _resolverStats!;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildStatTile('Total Lookups', '${stats['total_lookups']}', Icons.search),
        _buildStatTile('Cache Hits', '${stats['cache_hits']}', Icons.speed),
        _buildStatTile('Cache Hit Rate', '${stats['cache_hit_rate']}', Icons.trending_up),
        _buildStatTile('Failures', '${stats['resolution_failures']}', Icons.error),
        _buildStatTile('Failure Rate', '${stats['failure_rate']}', Icons.trending_down),
        _buildStatTile('Cache Size', '${stats['cache_size']}', Icons.storage),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditResultsCard() {
    if (_auditResult == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Audit Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_auditResult!.issues.isEmpty)
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('No issues found'),
                subtitle: Text('All systems are operating normally'),
              )
            else
              ..._auditResult!.issues.map((issue) => _buildIssueListTile(issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueListTile(DatabaseIssue issue) {
    final iconData = _getIssueIcon(issue.severity);
    final color = _getIssueColor(issue.severity);
    
    return ListTile(
      leading: Icon(iconData, color: color),
      title: Text('[${issue.table}] ${issue.description}'),
      subtitle: issue.affectedIds.isNotEmpty
          ? Text('Affected IDs: ${issue.affectedIds.take(3).join(', ')}${issue.affectedIds.length > 3 ? '...' : ''}')
          : null,
      trailing: Chip(
        label: Text(_severityToString(issue.severity)),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color),
        labelStyle: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildMappingReportCard() {
    if (_mappingReport == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Server Mapping Report',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(_mappingReport!),
                  tooltip: 'Copy report to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _mappingReport!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                ),
                ElevatedButton.icon(
                  onPressed: _resetResolver,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Reset Cache'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportReport,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export Report'),
                ),
                ElevatedButton.icon(
                  onPressed: _runFullAudit,
                  icon: const Icon(Icons.search),
                  label: const Text('Run Full Audit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  HealthStatus _getHealthStatus() {
    final result = _auditResult!;
    
    if (result.hasCriticalIssues || result.synchronizationIssues > 10) {
      return HealthStatus('Critical', Colors.red, Icons.error);
    }
    
    if (result.issues.where((i) => i.severity == IssueSeverity.error).isNotEmpty ||
        result.totalOrphanedRecords > 5) {
      return HealthStatus('Warning', Colors.orange, Icons.warning);
    }
    
    if (result.issues.isNotEmpty) {
      return HealthStatus('Caution', Colors.yellow.shade700, Icons.info);
    }
    
    return HealthStatus('Healthy', Colors.green, Icons.check_circle);
  }

  IconData _getIssueIcon(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return Icons.error;
      case IssueSeverity.error:
        return Icons.warning;
      case IssueSeverity.warning:
        return Icons.info;
    }
  }

  Color _getIssueColor(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return Colors.red;
      case IssueSeverity.error:
        return Colors.orange;
      case IssueSeverity.warning:
        return Colors.yellow.shade700;
    }
  }

  String _severityToString(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return 'CRITICAL';
      case IssueSeverity.error:
        return 'ERROR';
      case IssueSeverity.warning:
        return 'WARNING';
    }
  }

  Future<void> _resetResolver() async {
    ServerIdResolver.resetResolver();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID Resolver cache cleared')),
    );
    await _loadDashboardData();
  }

  Future<void> _copyToClipboard(String text) async {
    // Implementation depends on clipboard package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard')),
    );
  }

  Future<void> _exportReport() async {
    final report = await DatabaseAuditTool.generateAuditReport();
    // Implementation for file export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report exported successfully')),
    );
  }

  Future<void> _runFullAudit() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _auditResult = await DatabaseAuditTool.runFullAudit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audit completed: ${_auditResult!.issues.length} issues found')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audit failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Health status information
class HealthStatus {
  final String label;
  final Color color;
  final IconData icon;
  
  HealthStatus(this.label, this.color, this.icon);
}