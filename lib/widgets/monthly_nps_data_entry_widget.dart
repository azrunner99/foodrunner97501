import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../models/monthly_report.dart';
import '../utils/log.dart';
import '../screens/saved_nps_reports_screen.dart';
import '../screens/server_nps_tracking_screen.dart';

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

class _MonthlyNPSDataEntryWidgetState extends State<MonthlyNPSDataEntryWidget> {
  DateTime _selectedMonth = DateTime.now();
  final Map<String, _ServerData> _serverData = {};
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Use initial month if provided, otherwise use current month
    if (widget.initialMonth != null) {
      _selectedMonth = DateTime(widget.initialMonth!.year, widget.initialMonth!.month);
    }
    
    _loadServerData();
  }


  Future<void> _loadServerData() async {
    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      
      d('[MonthlyNPSDataEntry] Loading server data...');
      d('[MonthlyNPSDataEntry] AppState has ${appState.servers.length} servers');
      
      // Clear existing data
      _serverData.clear();
      
      // Create data entries for each server
      for (final server in appState.servers) {
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
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      final reportMonth = int.parse('${_selectedMonth.year}${_selectedMonth.month.toString().padLeft(2, '0')}');
      
      d('[MonthlyNPSDataEntry] Loading existing data for month $reportMonth (${_selectedMonth.year}-${_selectedMonth.month})');
      d('[MonthlyNPSDataEntry] Loading data for ${_serverData.length} servers');
      
      for (final entry in _serverData.entries) {
        final serverId = entry.key;
        final serverData = entry.value;
        
        try {
          // Try to get existing monthly report
          final existingReport = await npsProvider.database.getMonthlyReport(serverId, reportMonth);
          
          if (existingReport != null) {
            d('[MonthlyNPSDataEntry] Found existing report for server $serverId: $existingReport');
            
            // Load the saved data
            serverData.allTimeNpsController.text = (existingReport['all_time_nps_percentage'] ?? 0.0).toString();
            serverData.threeMonthNpsController.text = (existingReport['three_month_nps_percentage'] ?? 0.0).toString();
            serverData.oneMonthNpsController.text = (existingReport['one_month_nps_percentage'] ?? 0.0).toString();
            serverData.allTimeSalesController.text = (existingReport['all_time_sales'] ?? 0.0).toString();
            serverData.allTimeTableCountController.text = (existingReport['all_time_table_count'] ?? 0).toString();
            
            d('[MonthlyNPSDataEntry] ✅ Loaded data for server $serverId');
          } else {
            // Clear fields if no saved data
            serverData.clear();
            d('[MonthlyNPSDataEntry] ❌ No saved data for server $serverId');
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
              'month_feedback_yes': 0,
              'month_feedback_maybe': 0,
              'month_feedback_no': 0,
              'three_month_feedback_yes': 0,
              'three_month_feedback_maybe': 0,
              'three_month_feedback_no': 0,
              'all_time_feedback_yes': 0,
              'all_time_feedback_maybe': 0,
              'all_time_feedback_no': 0,
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_month),
            const SizedBox(width: 16),
            Text(
              'Selected Month: ${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _showMonthPicker(),
              child: const Text('Change Month'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _hasUnsavedChanges ? _clearAllData : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        ),
      ),
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

                return Card(
            margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serverData.serverName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                        child: TextField(
                                controller: serverData.allTimeNpsController,
                                decoration: const InputDecoration(
                                  labelText: 'All-Time NPS %',
                            hintText: '0.0',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                          onChanged: (_) => _onFieldChanged(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                        child: TextField(
                                controller: serverData.threeMonthNpsController,
                                decoration: const InputDecoration(
                                  labelText: '3-Month NPS %',
                            hintText: '0.0',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                          onChanged: (_) => _onFieldChanged(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                        child: TextField(
                                controller: serverData.oneMonthNpsController,
                                decoration: const InputDecoration(
                                  labelText: '1-Month NPS %',
                            hintText: '0.0',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                          onChanged: (_) => _onFieldChanged(),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                        child: TextField(
                                controller: serverData.allTimeSalesController,
                                decoration: const InputDecoration(
                                  labelText: 'All-Time Sales',
                            hintText: '0.00',
                                  border: OutlineInputBorder(),
                                  prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _onFieldChanged(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                        child: TextField(
                          controller: serverData.allTimeTableCountController,
                                decoration: const InputDecoration(
                            labelText: 'All-Time Tables',
                            hintText: '0',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                          onChanged: (_) => _onFieldChanged(),
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