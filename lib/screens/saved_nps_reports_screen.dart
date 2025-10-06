import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../utils/log.dart';
import '../widgets/monthly_nps_data_entry_widget.dart';
import 'server_nps_tracking_screen.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import '../models/monthly_report.dart';

/// Rebuilt Saved NPS Reports Screen
/// 
/// Purpose: List and view all saved monthly NPS reports
/// Features:
/// - List all months with saved reports
/// - Show server count per month
/// - Navigate to detailed month view
/// - Refresh functionality
class SavedNPSReportsScreen extends StatefulWidget {
  const SavedNPSReportsScreen({super.key});

  @override
  State<SavedNPSReportsScreen> createState() => _SavedNPSReportsScreenState();
}

class _SavedNPSReportsScreenState extends State<SavedNPSReportsScreen> {
  List<Map<String, dynamic>> _availableMonths = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      d('[SavedNPSReports] Loading available months...');
      
      // Use the EXACT same approach as the working HistoricalNPSAggregationService
      final db = DatabaseFactory.instance;
      final dbType = DatabaseFactory.implementationType;
      
      d('[SavedNPSReports] Loading ALL monthly reports from database using ServerNPSStatusWidget approach...');
      d('[SavedNPSReports] Database type: $dbType');
      
      // Use the EXACT same approach as the working HistoricalNPSAggregationService
      List<Map<String, dynamic>> reportMaps = await db.queryTable('nps_monthly_reports');
      
      d('[SavedNPSReports] Retrieved ${reportMaps.length} monthly reports from database');
      
      // Debug: Show raw data if any found
      if (reportMaps.isNotEmpty) {
        d('[SavedNPSReports] First report raw data: ${reportMaps.first}');
      } else {
        d('[SavedNPSReports] ⚠️ NO REPORTS FOUND - This is the problem!');
      }
      
      // Filter out integer server IDs (EXACT same logic as HistoricalNPSAggregationService)
      final filteredReports = reportMaps.where((report) {
        final serverId = report['server_id'].toString();
        // Filter out ALL numeric IDs (both single and multi-digit)
        final isNumericId = RegExp(r'^\d+$').hasMatch(serverId);
        if (isNumericId) {
          d('[SavedNPSReports] Filtering out numeric server_id: $serverId');
        }
        return !isNumericId; // Keep only string IDs with proper name mappings
      }).toList();
      
      d('[SavedNPSReports] After filtering: ${filteredReports.length} reports (removed ${reportMaps.length - filteredReports.length} old format reports)');
      
      // Group by month and count servers
      final Map<String, Set<String>> monthToServers = {};
      
      for (final report in filteredReports) {
        final reportMonth = report['report_month'] as int?;
        final reportYear = report['report_year'] as int?;
        
        d('[SavedNPSReports] Processing report: month=$reportMonth, year=$reportYear');
        
        if (reportMonth == null || reportYear == null) {
          d('[SavedNPSReports] Skipping report with null month/year: $report');
          continue;
        }
        
        // Validate month is in valid range (1-12)
        if (reportMonth < 1 || reportMonth > 12) {
          d('[SavedNPSReports] ⚠️ Invalid month number: $reportMonth, skipping this report');
          continue;
        }
        
        // Create month key in YYYYMM format
        final monthKey = '${reportYear}${reportMonth.toString().padLeft(2, '0')}';
        final serverId = report['server_id']?.toString() ?? '';
        
        d('[SavedNPSReports] Adding to month $monthKey, server: $serverId');
        monthToServers.putIfAbsent(monthKey, () => <String>{}).add(serverId);
      }
      
      // Convert to the expected format
      final List<Map<String, dynamic>> result = [];
      for (final entry in monthToServers.entries) {
        final monthKey = entry.key;
        
        try {
          final year = int.parse(monthKey.substring(0, 4));
          final month = int.parse(monthKey.substring(4, 6));
          
          // Validate parsed month is in valid range
          if (month < 1 || month > 12) {
            d('[SavedNPSReports] ⚠️ Parsed invalid month: $month from key $monthKey, skipping');
            continue;
          }
          
          result.add({
            'report_year': year,
            'report_month': month,
            'server_count': entry.value.length,
          });
          
          d('[SavedNPSReports] Added month: $year-$month (${entry.value.length} servers)');
        } catch (e) {
          d('[SavedNPSReports] ⚠️ Error parsing month key $monthKey: $e, skipping');
          continue;
        }
      }
      
      // Sort descending by year then month
      result.sort((a, b) {
        final yearCompare = (b['report_year'] as int).compareTo(a['report_year'] as int);
        return yearCompare != 0 ? yearCompare : (b['report_month'] as int).compareTo(a['report_month'] as int);
      });
      
      setState(() => _availableMonths = result);
      
      d('[SavedNPSReports] ✅ Found ${_availableMonths.length} months with saved reports');
      
      // Debug: Print each month found
      for (final month in _availableMonths) {
        d('[SavedNPSReports] Month: ${month['report_year']}-${month['report_month']}, Servers: ${month['server_count']}');
      }
      
      // If no months found, show debug info
      if (_availableMonths.isEmpty) {
        d('[SavedNPSReports] 🔍 DEBUG: No months found. Raw data analysis:');
        d('[SavedNPSReports] 🔍 Total raw reports: ${reportMaps.length}');
        d('[SavedNPSReports] 🔍 Filtered reports: ${filteredReports.length}');
        d('[SavedNPSReports] 🔍 Month-to-servers map: ${monthToServers.length} entries');
        for (final entry in monthToServers.entries.take(5)) {
          d('[SavedNPSReports] 🔍 Month ${entry.key}: ${entry.value.length} servers');
        }
      }
      
    } catch (e) {
      d('[SavedNPSReports] ❌ Error loading saved reports: $e');
      setState(() => _errorMessage = e.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading saved reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved NPS Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToDataEntry(),
            tooltip: 'Data Entry',
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => _navigateToServerTracking(),
            tooltip: 'Server Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedReports,
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading saved reports...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading reports',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSavedReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableMonths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No saved reports found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the Monthly NPS Data Entry screen to create reports',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToDataEntry(),
              icon: const Icon(Icons.edit),
              label: const Text('Go to Data Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSavedReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildReportsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.folder, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Monthly Reports',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_availableMonths.length} months with data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text('${_availableMonths.length}'),
              backgroundColor: Colors.blue.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _availableMonths.length,
      itemBuilder: (context, index) {
        final month = _availableMonths[index];
        return _buildMonthCard(month, index);
      },
    );
  }

  Widget _buildMonthCard(Map<String, dynamic> month, int index) {
    final year = month['report_year'] ?? 0;
    final monthNum = month['report_month'] ?? 0;
    final serverCount = month['server_count'] ?? 0;
    
    final monthName = _getMonthName(monthNum);
    final dateTime = DateTime(year, monthNum);
    final isCurrentMonth = _isCurrentMonth(year, monthNum);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentMonth ? 4 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentMonth ? Colors.blue : Colors.grey,
          child: Text(
            monthNum.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              monthName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              year.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (isCurrentMonth) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$serverCount servers with data'),
            const SizedBox(height: 4),
            Text(
              _formatDate(dateTime),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (serverCount > 0)
              Chip(
                label: Text(serverCount.toString()),
                backgroundColor: Colors.green.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () => _onMonthTapped(month),
      ),
    );
  }

  String _getMonthName(int monthNum) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    // Validate month number is in valid range (1-12)
    if (monthNum < 1 || monthNum > 12) {
      d('[SavedNPSReports] Invalid month number: $monthNum, using "Unknown"');
      return 'Unknown';
    }
    
    return months[monthNum - 1];
  }

  bool _isCurrentMonth(int year, int monthNum) {
    final now = DateTime.now();
    return year == now.year && monthNum == now.month;
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _onMonthTapped(Map<String, dynamic> month) {
    final year = month['report_year'] ?? 0;
    final monthNum = month['report_month'] ?? 0;
    final serverCount = month['server_count'] ?? 0;
    
    d('[SavedNPSReports] Tapped on month: $year-$monthNum ($serverCount servers)');
    
    // Navigate to data entry screen for this specific month
    final selectedDate = DateTime(year, monthNum);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MonthlyNPSDataEntryWidget(initialMonth: selectedDate),
      ),
    );
  }

  void _navigateToDataEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MonthlyNPSDataEntryWidget(),
      ),
    );
  }

  void _navigateToServerTracking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ServerNPSTrackingScreen(),
      ),
    );
  }
}