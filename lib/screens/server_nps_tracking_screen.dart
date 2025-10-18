import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../models/monthly_report.dart';
import '../utils/log.dart';
import '../widgets/monthly_nps_data_entry_widget.dart';

/// Rebuilt Server NPS Tracking Screen
/// 
/// Purpose: Central hub for NPS tracking with tabs for different views
/// Features:
/// - Data Entry tab (redirects to the widget)
/// - Performance Overview tab
/// - Historical Trends tab
/// - Saved Reports tab
class ServerNPSTrackingScreen extends StatefulWidget {
  const ServerNPSTrackingScreen({super.key});

  @override
  State<ServerNPSTrackingScreen> createState() => _ServerNPSTrackingScreenState();
}

class _ServerNPSTrackingScreenState extends State<ServerNPSTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server NPS Tracking'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Data Entry'),
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.folder), text: 'Saved Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MonthlyNPSDataEntryWidget(),
          _PerformanceOverviewTab(),
          _HistoricalTrendsTab(),
          _SavedReportsTab(),
        ],
      ),
    );
  }
}

/// Performance Overview Tab - Shows current month summary
class _PerformanceOverviewTab extends StatefulWidget {
  const _PerformanceOverviewTab();

  @override
  State<_PerformanceOverviewTab> createState() => _PerformanceOverviewTabState();
}

class _PerformanceOverviewTabState extends State<_PerformanceOverviewTab> {
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    setState(() => _isLoading = true);
    
    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      final reportMonth = int.parse('${_selectedMonth.year}${_selectedMonth.month.toString().padLeft(2, '0')}');
      
      d('[PerformanceOverview] Loading data for month $reportMonth');
      
      // Get all servers with reports for this month
      final allReports = await npsProvider.database.getServerNPSDataForMonth(
        _selectedMonth.month,
        _selectedMonth.year,
      );
      
      setState(() => _reports = allReports);
      
      d('[PerformanceOverview] Loaded ${_reports.length} server reports');
      
    } catch (e) {
      d('[PerformanceOverview] Error loading overview data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMonthSelector(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No reports found for this month'),
                          Text('Use Data Entry tab to add data'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return _buildReportCard(report);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_month),
            const SizedBox(width: 16),
            Text(
              'Viewing: ${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  helpText: 'Select month and year',
                );
                if (date != null) {
                  setState(() {
                    _selectedMonth = DateTime(date.year, date.month);
                  });
                  await _loadOverviewData();
                }
              },
              child: const Text('Change Month'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final serverName = report['server_name'] ?? 'Unknown Server';
    final allTimeNps = (report['all_time_nps_percentage'] ?? 0.0) as double;
    final threeMonthNps = (report['three_month_nps_percentage'] ?? 0.0) as double;
    final oneMonthNps = (report['one_month_nps_percentage'] ?? 0.0) as double;
    final sales = (report['all_time_sales'] ?? 0.0) as double;
    final tables = (report['all_time_table_count'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serverName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('All-Time NPS', '${allTimeNps.toStringAsFixed(1)}%', _getNpsColor(allTimeNps)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard('3-Month NPS', '${threeMonthNps.toStringAsFixed(1)}%', _getNpsColor(threeMonthNps)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard('1-Month NPS', '${oneMonthNps.toStringAsFixed(1)}%', _getNpsColor(oneMonthNps)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Sales', '\$${sales.toStringAsFixed(2)}', Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard('Tables', tables.toString(), Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getNpsColor(double nps) {
    if (nps >= 70) return Colors.green;
    if (nps >= 50) return Colors.orange;
    return Colors.red;
  }
}

/// Historical Trends Tab - Shows trends over time
class _HistoricalTrendsTab extends StatelessWidget {
  const _HistoricalTrendsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Historical Trends'),
          Text('Coming soon - will show NPS trends over time'),
        ],
      ),
    );
  }
}

/// Saved Reports Tab - Lists all saved monthly reports
class _SavedReportsTab extends StatefulWidget {
  const _SavedReportsTab();

  @override
  State<_SavedReportsTab> createState() => _SavedReportsTabState();
}

class _SavedReportsTabState extends State<_SavedReportsTab> {
  List<Map<String, dynamic>> _availableMonths = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    setState(() => _isLoading = true);
    
    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      
      d('[SavedReports] Loading available months...');
      
      final months = await npsProvider.database.getAvailableReportMonths();
      
      setState(() => _availableMonths = months);
      
      d('[SavedReports] Found ${_availableMonths.length} months with saved reports');
      
    } catch (e) {
      d('[SavedReports] Error loading saved reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved reports: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.folder),
                const SizedBox(width: 16),
                Text(
                  'Saved Monthly Reports',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSavedReports,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availableMonths.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No saved reports found'),
                          Text('Use Data Entry tab to create reports'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _availableMonths.length,
                      itemBuilder: (context, index) {
                        final month = _availableMonths[index];
                        return _buildMonthCard(month);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(Map<String, dynamic> month) {
    final year = month['report_year'] ?? 0;
    final monthNum = month['report_month'] ?? 0;
    final serverCount = month['server_count'] ?? 0;
    
    final monthName = DateTime(2000, monthNum).month == monthNum 
        ? DateTime(2000, monthNum).toString().split(' ')[1] 
        : 'Month $monthNum';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.calendar_month),
        title: Text('$monthName $year'),
        subtitle: Text('$serverCount servers with data'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to detailed view for this month
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View details for $monthName $year')),
          );
        },
      ),
    );
  }
}






