import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../models/monthly_report.dart';
import '../utils/log.dart';
import '../screens/saved_nps_reports_screen.dart';
import '../screens/server_nps_tracking_screen.dart';
import '../services/server_data_service.dart';
import '../mixins/server_data_mixin.dart';

/// Simple, working Monthly NPS Data Entry Widget
/// 
/// Purpose: Allow bulk entry of NPS scores and feedback for servers over a month period
/// Features:
/// - Month/year selection
/// - Server list with input fields for NPS scores, sales, table count
/// - Save/load functionality that actually works
/// - Clear data persistence
class MonthlyNPSDataEntryWidget extends StatefulWidget {
  final DateTime? initialMonth;
  
  const MonthlyNPSDataEntryWidget({super.key, this.initialMonth});

  @override
  State<MonthlyNPSDataEntryWidget> createState() => _MonthlyNPSDataEntryWidgetState();
}

class _MonthlyNPSDataEntryWidgetState extends State<MonthlyNPSDataEntryWidget> with ServerDataMixin {
  DateTime _selectedMonth = DateTime.now();
  final Map<String, _ServerData> _serverData = {};
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  Map<String, bool> _monthsWithData = {}; // Track which months have data

  @override
  void initState() {
    super.initState();
    
    // Use initial month if provided, otherwise use current month
    if (widget.initialMonth != null) {
      _selectedMonth = DateTime(widget.initialMonth!.year, widget.initialMonth!.month);
    }
    
    _loadServerData();
    _loadMonthsWithData();
  }

  /// Load which months have data to highlight them in the month selector
  Future<void> _loadMonthsWithData() async {
    try {
      d('[MonthlyNPSDataEntry] Loading months with data using ServerDataMixin...');
      
      // ✅ Use mixin method - automatic filtering, ID resolution, and typing
      final allReports = await getAllNPSMonthlyReports();
      d('[MonthlyNPSDataEntry] Found ${allReports.length} reports (orphaned IDs already filtered)');
      
      _monthsWithData.clear();
      
      for (final report in allReports) {
        final reportMonth = report.reportMonth;
        final reportYear = report.reportYear;
        
        // Handle both YYYYMM format and separate columns
        int year, month;
        
        if (reportMonth > 1000) {
          // YYYYMM format (e.g., 202509)
          year = reportMonth ~/ 100;
          month = reportMonth % 100;
        } else {
          // Separate columns
          year = reportYear;
          month = reportMonth;
        }
        
        final monthKey = '${year}_$month';
        _monthsWithData[monthKey] = true;
      }
      
      d('[MonthlyNPSDataEntry] Loaded ${_monthsWithData.length} months with data');
      
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      d('[MonthlyNPSDataEntry] Error loading months with data: $e');
    }
  }


  Future<void> _loadServerData() async {
    setState(() => _isLoading = true);
    
    try {
      d('[MonthlyNPSDataEntry] Loading server data using ServerDataService...');
      
      // ⭐ Phase 1.4: Use ServerDataService for unified server access
      // Only show active (non-archived) servers in data entry
      final servers = await ServerDataService.instance.getAllServers(activeOnly: true);
      
      d('[MonthlyNPSDataEntry] ServerDataService returned ${servers.length} servers');
      
      // Clear existing data
      _serverData.clear();
      
      // Create data entries for each server
      for (final server in servers) {
        _serverData[server.id] = _ServerData(serverId: server.id, serverName: server.name);
      }
      
      d('[MonthlyNPSDataEntry] Created ${_serverData.length} server entries');
      
      // Load existing data for the selected month
      await _loadExistingData();
      
    } catch (e) {
      d('[MonthlyNPSDataEntry] Error loading server data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading server data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingData() async {
    if (_serverData.isEmpty) return;
    
    try {
      d('[MonthlyNPSDataEntry] Loading existing data for month ${_selectedMonth.year}-${_selectedMonth.month} using ServerDataMixin...');
      d('[MonthlyNPSDataEntry] Loading data for ${_serverData.length} servers');
      
      // ✅ Use mixin method to get all monthly reports, then filter by month
      final allReports = await getAllNPSMonthlyReports();
      final reportMonth = int.parse('${_selectedMonth.year}${_selectedMonth.month.toString().padLeft(2, '0')}');
      final monthlyReports = allReports.where((report) => report.reportMonth == reportMonth).toList();
      d('[MonthlyNPSDataEntry] Found ${monthlyReports.length} monthly reports for ${_selectedMonth.year}-${_selectedMonth.month}');
      
      // Create a map of serverId -> report for quick lookup
      final reportsByServerId = <String, NPSMonthlyReport>{};
      for (final report in monthlyReports) {
        reportsByServerId[report.serverId] = report;
      }
      
      for (final entry in _serverData.entries) {
        final serverId = entry.key;
        final serverData = entry.value;
        
        try {
          // Check if we have a report for this server and month
          final existingReport = reportsByServerId[serverId];
          
          if (existingReport != null) {
            d('[MonthlyNPSDataEntry] Found existing report for server $serverId: NPS=${existingReport.allTimeNpsPercentage}');
            
            // Load the saved data using the typed model
            serverData.allTimeNpsController.text = (existingReport.allTimeNpsPercentage ?? 0.0).toString();
            serverData.threeMonthNpsController.text = (existingReport.threeMonthNpsPercentage ?? 0.0).toString();
            serverData.oneMonthNpsController.text = (existingReport.oneMonthNpsPercentage ?? 0.0).toString();
            serverData.allTimeSalesController.text = existingReport.allTimeSales.toString();
            serverData.allTimeTableCountController.text = existingReport.allTimeTableCount.toString();
            
            d('[MonthlyNPSDataEntry] ✅ Loaded data for server $serverId');
          } else {
            // Clear fields if no saved data for this month
            serverData.clear();
            d('[MonthlyNPSDataEntry] ❌ No saved data for server $serverId in ${_selectedMonth.year}-${_selectedMonth.month}');
          }
        } catch (e) {
          d('[MonthlyNPSDataEntry] ❌ Error loading data for server $serverId: $e');
        }
      }
      
      setState(() {});
      
    } catch (e) {
      d('[MonthlyNPSDataEntry] ❌ Error loading existing data: $e');
    }
  }

  Future<void> _saveData() async {
    if (_serverData.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    // Show save status
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Saving data...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      final reportMonth = int.parse('${_selectedMonth.year}${_selectedMonth.month.toString().padLeft(2, '0')}');
      
      d('[MonthlyNPSDataEntry] Saving data for month $reportMonth');
      
      int savedCount = 0;
      
      for (final entry in _serverData.entries) {
        final serverId = entry.key;
        final serverData = entry.value;
        
        // Only save if there's actual data
        if (serverData.hasData()) {
          try {
            final reportData = {
              'server_id': serverId,
              'report_month': reportMonth,
              'report_year': _selectedMonth.year,
              'all_time_nps_percentage': double.tryParse(serverData.allTimeNpsController.text) ?? 0.0,
              'three_month_nps_percentage': double.tryParse(serverData.threeMonthNpsController.text) ?? 0.0,
              'one_month_nps_percentage': double.tryParse(serverData.oneMonthNpsController.text) ?? 0.0,
              'all_time_sales': double.tryParse(serverData.allTimeSalesController.text) ?? 0.0,
              'all_time_table_count': int.tryParse(serverData.allTimeTableCountController.text) ?? 0,
              'generated_at': DateTime.now().toIso8601String(),
              'data_as_of_date': DateTime.now().toIso8601String(),
            };
            
            final result = await npsProvider.database.insertOrUpdateMonthlyReport(reportData);
            savedCount++;
            
            d('[MonthlyNPSDataEntry] Saved data for server $serverId, result: $result');
            d('[MonthlyNPSDataEntry] Report data: $reportData');
            
          } catch (e) {
            d('[MonthlyNPSDataEntry] Error saving data for server $serverId: $e');
          }
        }
      }
      
      setState(() => _hasUnsavedChanges = false);
      
      // Refresh months with data after saving
      await _loadMonthsWithData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved data for $savedCount servers')),
        );
      }
      
      d('[MonthlyNPSDataEntry] Successfully saved data for $savedCount servers');
      
    } catch (e) {
      d('[MonthlyNPSDataEntry] Error saving data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFieldChanged() {
    setState(() => _hasUnsavedChanges = true);
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialYear: _selectedMonth.year,
        initialMonth: _selectedMonth.month,
        onSelected: (year, month) async {
          setState(() {
            _selectedMonth = DateTime(year, month);
            _hasUnsavedChanges = false;
          });
          await _loadExistingData();
        },
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all data for this month? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              for (final serverData in _serverData.values) {
                serverData.clear();
              }
              setState(() => _hasUnsavedChanges = true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _navigateToSavedReports() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SavedNPSReportsScreen(),
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

  @override
  Widget build(BuildContext context) {
        return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly NPS Data Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServerData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => _navigateToSavedReports(),
            tooltip: 'View Saved Reports',
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => _navigateToServerTracking(),
            tooltip: 'Server Tracking Dashboard',
          ),
          if (_hasUnsavedChanges)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveData,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.grey),
              onPressed: null,
              tooltip: 'No changes to save',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMonthSelector(),
                _buildServerList(),
              ],
            ),
      floatingActionButton: _hasUnsavedChanges
          ? FloatingActionButton(
              onPressed: _isLoading ? null : _saveData,
              child: const Icon(Icons.save),
              tooltip: 'Save Changes',
            )
          : FloatingActionButton(
              onPressed: _navigateToSavedReports,
              child: const Icon(Icons.folder),
              tooltip: 'View Saved Reports',
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Month & Year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                if (_hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Unsaved Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Year Selector
            _buildYearSelector(),
            const SizedBox(height: 20),
            
            // Month Grid
            _buildMonthGrid(),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasUnsavedChanges ? _clearAllData : null,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToSavedReports,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('View Reports'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'Year:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonth.year,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
                onChanged: (newYear) {
                  if (newYear != null) {
                    setState(() {
                      _selectedMonth = DateTime(newYear, _selectedMonth.month);
                      _hasUnsavedChanges = false;
                    });
                    _loadExistingData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Month:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: months.length,
          itemBuilder: (context, index) {
            final monthIndex = index + 1;
            final isSelected = monthIndex == _selectedMonth.month;
            final monthKey = '${_selectedMonth.year}_$monthIndex';
            final hasData = _monthsWithData[monthKey] ?? false;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, monthIndex);
                  _hasUnsavedChanges = false;
                });
                _loadExistingData();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : hasData 
                          ? Colors.green[50] 
                          : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : hasData 
                            ? Colors.green[300]! 
                            : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      months[index],
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white 
                            : hasData 
                                ? Colors.green[700] 
                                : Colors.grey[600],
                        fontWeight: isSelected || hasData 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    if (hasData && !isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 12,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServerList() {
    if (_serverData.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No servers found'),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _serverData.length,
                    itemBuilder: (context, index) {
          final entry = _serverData.entries.elementAt(index);
          final serverData = entry.value;

                return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: serverData.hasData() 
                    ? Colors.green[200]! 
                    : Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Server Header
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: serverData.hasData() 
                                    ? Colors.green 
                                    : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                serverData.serverName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: serverData.hasData() 
                                      ? Colors.green[700] 
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            if (serverData.hasData())
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(
                                  'Has Data',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // NPS Scores Section
                        Text(
                          'NPS Scores',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStyledTextField(
                                controller: serverData.allTimeNpsController,
                                labelText: 'All-Time NPS %',
                                hintText: '0.0',
                                icon: Icons.trending_up,
                                suffixText: '%',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStyledTextField(
                                controller: serverData.threeMonthNpsController,
                                labelText: '3-Month NPS %',
                                hintText: '0.0',
                                icon: Icons.trending_flat,
                                suffixText: '%',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStyledTextField(
                                controller: serverData.oneMonthNpsController,
                                labelText: '1-Month NPS %',
                                hintText: '0.0',
                                icon: Icons.trending_down,
                                suffixText: '%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Sales & Tables Section
                        Text(
                          'Sales & Performance',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStyledTextField(
                                controller: serverData.allTimeSalesController,
                                labelText: 'All-Time Sales',
                                hintText: '0.00',
                                icon: Icons.attach_money,
                                prefixText: '\$',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStyledTextField(
                                controller: serverData.allTimeTableCountController,
                                labelText: 'All-Time Tables',
                                hintText: '0',
                                icon: Icons.table_restaurant,
                                suffixText: ' tables',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    String? prefixText,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => _onFieldChanged(),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        suffixText: suffixText,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  @override
  void dispose() {
    for (final serverData in _serverData.values) {
      serverData.dispose();
    }
    super.dispose();
  }
}

/// Simple data holder for each server's input fields
class _ServerData {
  final String serverId;
  final String serverName;
  final TextEditingController allTimeNpsController = TextEditingController();
  final TextEditingController threeMonthNpsController = TextEditingController();
  final TextEditingController oneMonthNpsController = TextEditingController();
  final TextEditingController allTimeSalesController = TextEditingController();
  final TextEditingController allTimeTableCountController = TextEditingController();

  _ServerData({required this.serverId, required this.serverName});

  void clear() {
    allTimeNpsController.clear();
    threeMonthNpsController.clear();
    oneMonthNpsController.clear();
    allTimeSalesController.clear();
    allTimeTableCountController.clear();
  }

  bool hasData() {
    return allTimeNpsController.text.isNotEmpty ||
        threeMonthNpsController.text.isNotEmpty ||
        oneMonthNpsController.text.isNotEmpty ||
        allTimeSalesController.text.isNotEmpty ||
        allTimeTableCountController.text.isNotEmpty;
  }

  void dispose() {
    allTimeNpsController.dispose();
    threeMonthNpsController.dispose();
    oneMonthNpsController.dispose();
    allTimeSalesController.dispose();
    allTimeTableCountController.dispose();
  }
}

/// Month/Year picker dialog
class _MonthYearPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final Function(int year, int month) onSelected;

  const _MonthYearPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.onSelected,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return AlertDialog(
      title: const Text('Select Month and Year'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            // Year picker
            Text(
              'Year: $_selectedYear',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedYear--),
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  _selectedYear.toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedYear++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Month picker
            Text(
              'Month:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: months.length,
                itemBuilder: (context, index) {
                final monthIndex = index + 1;
                  final isSelected = monthIndex == _selectedMonth;
                  
                  return InkWell(
                    onTap: () => setState(() => _selectedMonth = monthIndex),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                    child: Text(
                          months[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSelected(_selectedYear, _selectedMonth);
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}