import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models.dart';
import '../models/station_performance_metric.dart';
import '../services/station_analytics_service.dart';
import '../services/advanced_reporting_service.dart';
import '../services/automated_backup_service.dart';
import '../widgets/advanced_analytics_dashboard_widget.dart';
import '../services/error_handling_service.dart';

/// Comprehensive Analytics Dashboard
/// Complete analytics interface with advanced reporting and backup management
class ComprehensiveAnalyticsDashboard extends StatefulWidget {
  const ComprehensiveAnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<ComprehensiveAnalyticsDashboard> createState() => _ComprehensiveAnalyticsDashboardState();
}

class _ComprehensiveAnalyticsDashboardState extends State<ComprehensiveAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<StationComparisonData> _stationComparisons = [];
  List<String> _performanceInsights = [];
  Map<String, double> _stationEfficiencies = {};
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();
  BackupConfiguration? _backupConfig;
  List<BackupInfo> _availableBackups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalyticsData();
    _loadBackupConfiguration();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load actual shift records from storage
      final appState = Provider.of<AppState>(context, listen: false);
      final allRecords = appState.history;

      // Load analytics with real data
      final comparisons = await StationAnalyticsService.compareStationPerformance();
      final insights = await StationAnalyticsService.getPerformanceInsights();
      final efficiencies = await StationAnalyticsService.calculateStationEfficiency(allRecords);

      setState(() {
        _stationComparisons = comparisons;
        _performanceInsights = insights;
        _stationEfficiencies = efficiencies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _loadBackupConfiguration() async {
    try {
      final config = await AutomatedBackupService.getBackupConfiguration();
      final backups = await AutomatedBackupService.getAvailableBackups();
      
      setState(() {
        _backupConfig = config;
        _availableBackups = backups;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Station Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Advanced Reports', icon: Icon(Icons.assessment)),
            Tab(text: 'Data Export', icon: Icon(Icons.download)),
            Tab(text: 'Backup & Recovery', icon: Icon(Icons.backup)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildStationAnalyticsTab(),
                _buildAdvancedReportsTab(),
                _buildDataExportTab(),
                _buildBackupTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 16),
          _buildMetricsCards(),
          const SizedBox(height: 16),
          _buildQuickInsights(),
        ],
      ),
    );
  }

  Widget _buildStationAnalyticsTab() {
    return AdvancedAnalyticsDashboardWidget(
      stationData: _stationComparisons,
      stationEfficiencies: _stationEfficiencies,
      performanceInsights: _performanceInsights,
    );
  }

  Widget _buildAdvancedReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Reports',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildReportCards(),
        ],
      ),
    );
  }

  Widget _buildDataExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Export',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup & Recovery',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildBackupConfiguration(),
          const SizedBox(height: 16),
          _buildBackupActions(),
          const SizedBox(height: 16),
          _buildAvailableBackups(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedStartDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedEndDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('Total Stations', _stationEfficiencies.length.toString(), Icons.business, Colors.blue),
        _buildMetricCard('Avg Efficiency', _calculateAverageEfficiency().toStringAsFixed(1) + '%', Icons.trending_up, Colors.green),
        _buildMetricCard('Active Insights', _performanceInsights.length.toString(), Icons.lightbulb, Colors.orange),
        _buildMetricCard('Data Points', _calculateTotalDataPoints().toString(), Icons.data_usage, Colors.purple),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...(_performanceInsights.take(3).map((insight) => ListTile(
              leading: const Icon(Icons.insights, color: Colors.blue),
              title: Text(insight),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      children: [
        _buildReportCard(
          'Performance Report',
          'Comprehensive station performance analysis',
          Icons.analytics,
          Colors.blue,
          () => _generatePerformanceReport(),
        ),
        _buildReportCard(
          'Station Comparison',
          'Compare performance across stations',
          Icons.compare,
          Colors.green,
          () => _generateStationComparisonReport(),
        ),
        _buildReportCard(
          'Anomaly Detection',
          'Identify unusual performance patterns',
          Icons.warning,
          Colors.orange,
          () => _generateAnomalyReport(),
        ),
        _buildReportCard(
          'Seasonality Analysis',
          'Analyze day-of-week patterns',
          Icons.calendar_view_week,
          Colors.purple,
          () => _generateSeasonalityReport(),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export to CSV'),
              subtitle: const Text('Export data in CSV format'),
              trailing: const Icon(Icons.download),
              onTap: () => _exportData(ReportFormat.csv),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export to PDF'),
              subtitle: const Text('Generate PDF report'),
              trailing: const Icon(Icons.download),
              onTap: () => _exportData(ReportFormat.pdf),
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.blue),
              title: const Text('Export to JSON'),
              subtitle: const Text('Export raw data in JSON format'),
              trailing: const Icon(Icons.download),
              onTap: () => _exportData(ReportFormat.json),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupConfiguration() {
    if (_backupConfig == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Backup Frequency'),
              subtitle: Text('Every ${_backupConfig!.frequencyDays} day(s)'),
              trailing: const Icon(Icons.schedule),
            ),
            ListTile(
              title: const Text('Cloud Backup'),
              subtitle: Text(_backupConfig!.cloudBackupEnabled ? 'Enabled' : 'Disabled'),
              trailing: Icon(_backupConfig!.cloudBackupEnabled ? Icons.cloud_done : Icons.cloud_off),
            ),
            ListTile(
              title: const Text('Retention Period'),
              subtitle: Text('${_backupConfig!.maxRetentionDays} days'),
              trailing: const Icon(Icons.storage),
            ),
            if (_backupConfig!.lastBackupDate != null)
              ListTile(
                title: const Text('Last Backup'),
                subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(_backupConfig!.lastBackupDate!)),
                trailing: const Icon(Icons.history),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _performBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('Create Backup'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _configureBackup,
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBackups() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Backups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_availableBackups.isEmpty)
              const Text('No backups available')
            else
              ...(_availableBackups.map((backup) => ListTile(
                leading: const Icon(Icons.backup, color: Colors.blue),
                title: Text(DateFormat('MMM dd, yyyy HH:mm').format(backup.timestamp)),
                subtitle: Text('${(backup.size / 1024 / 1024).toStringAsFixed(1)} MB • ${backup.filesCount} files'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('Restore'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  onSelected: (value) => _handleBackupAction(value, backup),
                ),
              ))),
          ],
        ),
      ),
    );
  }

  // Event handlers

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = date;
        } else {
          _selectedEndDate = date;
        }
      });
      _loadAnalyticsData();
    }
  }

  double _calculateAverageEfficiency() {
    if (_stationEfficiencies.isEmpty) return 0.0;
    return _stationEfficiencies.values.reduce((a, b) => a + b) / _stationEfficiencies.length;
  }

  int _calculateTotalDataPoints() {
    return _stationComparisons.fold(0, (sum, station) => sum + station.totalShifts);
  }

  Future<void> _generatePerformanceReport() async {
    try {
      final reportPath = await AdvancedReportingService.generatePerformanceReport(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        selectedStations: _stationEfficiencies.keys.toList(),
        selectedMetrics: ['efficiency', 'utilization', 'quality'],
        format: ReportFormat.csv,
      );
      
      if (mounted) {
        ErrorHandlingService.showSuccessSnackBar(
          context,
          'Performance report generated: $reportPath',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _generateStationComparisonReport() async {
    try {
      final reportPath = await AdvancedReportingService.generateStationComparisonReport(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        stationTypes: _stationEfficiencies.keys.toList(),
      );
      
      if (mounted) {
        ErrorHandlingService.showSuccessSnackBar(
          context,
          'Station comparison report generated: $reportPath',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _generateAnomalyReport() async {
    try {
      final reportPath = await AdvancedReportingService.generateAnomalyReport(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        anomalyThreshold: 2.0,
      );
      
      if (mounted) {
        ErrorHandlingService.showSuccessSnackBar(
          context,
          'Anomaly report generated: $reportPath',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _generateSeasonalityReport() async {
    try {
      final reportPath = await AdvancedReportingService.generateSeasonalityReport(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
      
      if (mounted) {
        ErrorHandlingService.showSuccessSnackBar(
          context,
          'Seasonality report generated: $reportPath',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _exportData(ReportFormat format) async {
    try {
      final data = _stationComparisons.map((station) => {
        'station_type': station.stationType,
        'current_efficiency': station.currentEfficiency,
        'trend_percentage': station.trendPercentage,
        'total_shifts': station.totalShifts,
      }).toList();
      
      final exportPath = await AdvancedReportingService.exportData(
        data: data,
        filename: 'analytics_export',
        format: format,
      );
      
      if (mounted) {
        ErrorHandlingService.showSuccessSnackBar(
          context,
          'Data exported to: $exportPath',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _performBackup() async {
    try {
      final result = await AutomatedBackupService.performBackup();
      
      if (result.success) {
        if (mounted) {
          ErrorHandlingService.showSuccessSnackBar(
            context,
            'Backup completed successfully',
          );
        }
        _loadBackupConfiguration();
      } else {
        if (mounted) {
          ErrorHandlingService.showErrorSnackBar(context, result.error ?? 'Backup failed');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _configureBackup() async {
    // Show backup configuration dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Backup'),
        content: const Text('Backup configuration dialog would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackupAction(String action, BackupInfo backup) async {
    if (action == 'restore') {
      try {
        final result = await AutomatedBackupService.restoreFromBackup(backup.path);
        
        if (result.success) {
          if (mounted) {
            ErrorHandlingService.showSuccessSnackBar(
              context,
              'Backup restored successfully',
            );
          }
        } else {
          if (mounted) {
            ErrorHandlingService.showErrorSnackBar(context, result.error ?? 'Restore failed');
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorHandlingService.showErrorSnackBar(context, e);
        }
      }
    } else if (action == 'delete') {
      // Implement backup deletion
      if (mounted) {
        ErrorHandlingService.showSuccessSnackBar(
          context,
          'Backup deletion would be implemented here',
        );
      }
    }
  }
}
