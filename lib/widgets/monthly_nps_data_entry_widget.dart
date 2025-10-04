import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../models/monthly_report.dart';
import '../services/error_handling_service.dart';
import '../app_state.dart';

/// Data class for holding server metrics input data
class ServerMetricsData {
  final String serverId;
  final String serverName;
  final TextEditingController allTimeNpsController;
  final TextEditingController threeMonthNpsController;
  final TextEditingController oneMonthNpsController;
  final TextEditingController allTimeSalesController;
  final TextEditingController allTimeTableCountController;

  ServerMetricsData({
    required this.serverId,
    required this.serverName,
    double? allTimeNpsPercentage,
    double? threeMonthNpsPercentage,
    double? oneMonthNpsPercentage,
    double? allTimeSales,
    int? allTimeTableCount,
  })  : allTimeNpsController = TextEditingController(
            text: allTimeNpsPercentage?.toStringAsFixed(1) ?? ''),
        threeMonthNpsController = TextEditingController(
            text: threeMonthNpsPercentage?.toStringAsFixed(1) ?? ''),
        oneMonthNpsController = TextEditingController(
            text: oneMonthNpsPercentage?.toStringAsFixed(1) ?? ''),
        allTimeSalesController =
            TextEditingController(text: allTimeSales?.toStringAsFixed(2) ?? ''),
        allTimeTableCountController =
            TextEditingController(text: allTimeTableCount?.toString() ?? '');

  ServerMetricsData copyWith({
    double? allTimeNpsPercentage,
    double? threeMonthNpsPercentage,
    double? oneMonthNpsPercentage,
    double? allTimeSales,
    int? allTimeTableCount,
  }) {
    // Clear all fields first
    allTimeNpsController.clear();
    threeMonthNpsController.clear();
    oneMonthNpsController.clear();
    allTimeSalesController.clear();
    allTimeTableCountController.clear();
    
    // Then set the provided values
    if (allTimeNpsPercentage != null) {
      allTimeNpsController.text = allTimeNpsPercentage.toStringAsFixed(1);
    }
    if (threeMonthNpsPercentage != null) {
      threeMonthNpsController.text = threeMonthNpsPercentage.toStringAsFixed(1);
    }
    if (oneMonthNpsPercentage != null) {
      oneMonthNpsController.text = oneMonthNpsPercentage.toStringAsFixed(1);
    }

    // Only set sales if it's a meaningful value (greater than 0)
    if (allTimeSales != null && allTimeSales > 0) {
      // Format as currency without the dollar sign (since prefixText handles it)
      allTimeSalesController.text = allTimeSales.toStringAsFixed(2);
    }

    // Only set table count if it's a meaningful value (greater than 0)
    if (allTimeTableCount != null && allTimeTableCount > 0) {
      allTimeTableCountController.text = allTimeTableCount.toString();
    }

    return this;
  }

  void dispose() {
    allTimeNpsController.dispose();
    threeMonthNpsController.dispose();
    oneMonthNpsController.dispose();
    allTimeSalesController.dispose();
    allTimeTableCountController.dispose();
  }

  /// Clear all input fields
  void clear() {
    allTimeNpsController.clear();
    threeMonthNpsController.clear();
    oneMonthNpsController.clear();
    allTimeSalesController.clear();
    allTimeTableCountController.clear();
  }

  /// Check if any fields have data
  bool hasData() {
    return allTimeNpsController.text.isNotEmpty ||
        threeMonthNpsController.text.isNotEmpty ||
        oneMonthNpsController.text.isNotEmpty ||
        allTimeSalesController.text.isNotEmpty ||
        allTimeTableCountController.text.isNotEmpty;
  }
}

/// Widget for monthly NPS data entry
/// Allows bulk entry of NPS scores and feedback for servers over a month period
class MonthlyNPSDataEntryWidget extends StatefulWidget {
  const MonthlyNPSDataEntryWidget({super.key});

  @override
  State<MonthlyNPSDataEntryWidget> createState() =>
      _MonthlyNPSDataEntryWidgetState();
}

class _MonthlyNPSDataEntryWidgetState extends State<MonthlyNPSDataEntryWidget> {
  DateTime _selectedMonth = DateTime.now();
  final Map<String, ServerMetricsData> _serverData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServerData();
  }

  Future<void> _loadServerData() async {
    final npsProvider = Provider.of<NPSProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    
    debugPrint('[MonthlyNPSDataEntry] Starting server data loading...');
    debugPrint('[MonthlyNPSDataEntry] AppState servers: ${appState.servers.length}');
    
    // Show AppState servers for debugging
    for (int i = 0; i < appState.servers.length; i++) {
      final server = appState.servers[i];
      debugPrint('[MonthlyNPSDataEntry] AppState Server ${i + 1}: id=${server.id}, name=${server.name}');
    }
    
    // Ensure NPSProvider is properly initialized with AppState
    if (!npsProvider.isInitialized) {
      debugPrint('[MonthlyNPSDataEntry] NPSProvider not initialized, initializing with AppState...');
      await npsProvider.initialize(appState: appState);
      debugPrint('[MonthlyNPSDataEntry] NPSProvider initialization completed');
    }

    debugPrint('[MonthlyNPSDataEntry] NPSProvider servers: ${npsProvider.servers.length}');
    for (final server in npsProvider.servers) {
      debugPrint('[MonthlyNPSDataEntry] NPSProvider Server: id=${server.id}, name=${server.name}, active=${server.active}');
    }

    // If NPSProvider has no servers, use AppState servers directly
    if (npsProvider.servers.isEmpty && appState.servers.isNotEmpty) {
      debugPrint('[MonthlyNPSDataEntry] NPSProvider has no servers, using AppState servers directly');
      
      for (final appServer in appState.servers) {
        _serverData[appServer.id] = ServerMetricsData(
          serverId: appServer.id,
          serverName: appServer.name,
        );
        debugPrint('[MonthlyNPSDataEntry] Added AppState server: ${appServer.name} (${appServer.id})');
      }
    } else {
      // Use NPSProvider servers as originally intended
      for (final server in npsProvider.servers.where((s) => s.active)) {
        _serverData[server.id] = ServerMetricsData(
          serverId: server.id,
          serverName: server.name,
        );
      }
    }

    debugPrint('[MonthlyNPSDataEntry] Final server data count: ${_serverData.length}');
    await _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    if (_serverData.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      final reportMonth = int.parse(
          '${_selectedMonth.year}${_selectedMonth.month.toString().padLeft(2, '0')}');

      debugPrint('🔍 Loading data for month: ${_selectedMonth.year}-${_selectedMonth.month} (reportMonth: $reportMonth)');

      // Load existing data for each server
      for (final entry in _serverData.entries) {
        final serverId = entry.key;
        try {
          debugPrint('🔍 [MonthlyNPSDataEntry] Loading data for server: $serverId');
          
          // Try to load saved data from database using current server ID
          var existingReportMap = await npsProvider.database
              .getMonthlyReport(serverId, reportMonth);

          // If no data found, try alternative ID formats
          if (existingReportMap == null) {
            debugPrint('🔍 [MonthlyNPSDataEntry] No data found for $serverId, trying alternative formats...');
            final appState = Provider.of<AppState>(context, listen: false);
            
            // Try to find server by name if ID doesn't work
            final matchingAppServer = appState.servers.firstWhere(
              (s) => s.id == serverId || s.name == _serverData[serverId]?.serverName,
              orElse: () => appState.servers.first, // fallback
            );
            
            if (matchingAppServer.id != serverId) {
              debugPrint('🔍 [MonthlyNPSDataEntry] Trying server name match: ${matchingAppServer.name}');
              existingReportMap = await npsProvider.database
                  .getMonthlyReport(matchingAppServer.id, reportMonth);
                  
              if (existingReportMap != null) {
                debugPrint('✅ [MonthlyNPSDataEntry] Found data using name-matched ID ${matchingAppServer.id} for server $serverId');
              }
            }
            
            // Last resort: try numeric index-based IDs
            if (existingReportMap == null) {
              final serverIndex = appState.servers.indexWhere((s) => s.id == serverId);
              if (serverIndex >= 0) {
                final mappedId = (serverIndex + 1).toString(); // Convert to String
                debugPrint('🔍 [MonthlyNPSDataEntry] Trying mapped ID: $mappedId for server $serverId');
                existingReportMap = await npsProvider.database
                    .getMonthlyReport(mappedId, reportMonth);
                    
                if (existingReportMap != null) {
                  debugPrint('✅ [MonthlyNPSDataEntry] Found data using mapped ID $mappedId for server $serverId');
                }
              }
            }
          }

          debugPrint('🔍 Server $serverId - existingReportMap: $existingReportMap');

          if (existingReportMap != null) {
            // Load saved data from database
            final report = NPSMonthlyReport.fromMap(existingReportMap);
            _serverData[serverId] = _serverData[serverId]!.copyWith(
              allTimeNpsPercentage: report.allTimeNpsPercentage,
              threeMonthNpsPercentage: report.threeMonthNpsPercentage,
              oneMonthNpsPercentage: report.oneMonthNpsPercentage,
              allTimeSales: report.allTimeSales,
              allTimeTableCount: report.allTimeTableCount,
            );
            debugPrint('✅ Loaded saved data for server $serverId: NPS=${report.allTimeNpsPercentage}, Sales=${report.allTimeSales}');
          } else {
            // No saved data found - clear all fields for this month
            _serverData[serverId]!.clear();
            debugPrint('🧹 Cleared data for server $serverId (no saved data for month $reportMonth)');
          }
        } catch (e) {
          debugPrint('❌ Error loading data for server $serverId: $e');
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final data in _serverData.values) {
      data.dispose();
    }
    super.dispose();
  }

  int _getAvailableServerCount(NPSProvider npsProvider) {
    // If NPSProvider has servers, use those
    if (npsProvider.servers.isNotEmpty) {
      return npsProvider.servers.where((s) => s.active).length;
    }
    
    // Otherwise, use AppState servers
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      return appState.servers.length;
    } catch (e) {
      return _serverData.length; // Fallback to current loaded data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Monthly NPS Data Entry',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(npsProvider),
                const SizedBox(height: 16),
                _buildDataEntryWarning(),
                const SizedBox(height: 24),
                _buildMonthSelector(),
                const SizedBox(height: 24),
                _buildServerListSection(npsProvider),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(NPSProvider npsProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter NPS scores and feedback for servers by month',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_getAvailableServerCount(npsProvider)} servers available',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Clear All button
          OutlinedButton.icon(
            onPressed: _clearAllDataWithConfirmation,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataEntryWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'IMPORTANT DATA ENTRY GUIDELINES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Leave fields BLANK if no reviews were received',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Enter 0 only if actual 0% score was received',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Incorrect entries will skew performance calculations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectMonth,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerListSection(NPSProvider npsProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server NPS Data Entry',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading server data...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _serverData.length,
                    itemBuilder: (context, index) {
                      final serverDataEntry = _serverData.entries.toList()[index];
                      final serverId = serverDataEntry.key;
                      final serverData = serverDataEntry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serverData.serverName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: serverData.allTimeNpsController,
                                decoration: const InputDecoration(
                                  labelText: 'All-Time NPS %',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: serverData.threeMonthNpsController,
                                decoration: const InputDecoration(
                                  labelText: '3-Month NPS %',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: serverData.oneMonthNpsController,
                                decoration: const InputDecoration(
                                  labelText: '1-Month NPS %',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: serverData.allTimeSalesController,
                                decoration: const InputDecoration(
                                  labelText: 'All-Time Sales',
                                  border: OutlineInputBorder(),
                                  prefixText: '\$',
                                  hintText: '0.00',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (value) {
                                  // Format currency as user types
                                  if (value.isNotEmpty) {
                                    final numericValue = double.tryParse(value);
                                    if (numericValue != null) {
                                      // Remove cursor position issues by formatting on focus loss instead
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller:
                                    serverData.allTimeTableCountController,
                                decoration: const InputDecoration(
                                  labelText: 'All-Time Check Count',
                                  border: OutlineInputBorder(),
                                  hintText: 'Number of checks',
                                ),
                                keyboardType: TextInputType.number,
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveData,
        icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Saving...' : 'Save All Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _selectMonth() async {
    debugPrint('🔘 Month selector tapped!');
    debugPrint('🔘 Current month: ${_selectedMonth.year}-${_selectedMonth.month}');
    
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        debugPrint('🔘 Opening month picker dialog...');
        return _MonthYearPickerDialog(
          initialDate: _selectedMonth,
        );
      },
    );

    debugPrint('🔘 Dialog returned: $selectedDate');

    if (selectedDate != null) {
      debugPrint('🔘 Month selected: $selectedDate');
      debugPrint('🔘 Previous month: ${_selectedMonth.year}-${_selectedMonth.month}');
      debugPrint('🔘 New month: ${selectedDate.year}-${selectedDate.month}');
      
      // Check if the month actually changed
      if (selectedDate.year == _selectedMonth.year && selectedDate.month == _selectedMonth.month) {
        debugPrint('🔘 Same month selected, no action needed');
        return;
      }
      
      setState(() {
        _selectedMonth = selectedDate;
      });
      debugPrint('🔘 About to call _loadExistingData() for month: ${_selectedMonth.year}-${_selectedMonth.month}');
      await _loadExistingData();
      debugPrint('🔘 _loadExistingData() completed');
    } else {
      debugPrint('🔘 Month selection cancelled');
    }
  }

  void _clearAllDataWithConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
              'Are you sure you want to clear all entered data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _clearAllData();
    }
  }

  void _clearAllData() {
    setState(() {
      for (final data in _serverData.values) {
        data.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared successfully'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _saveData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Use same server loading logic as _loadServerData
      List<dynamic> activeServers;
      if (npsProvider.servers.isNotEmpty) {
        activeServers = npsProvider.servers.where((s) => s.active).toList();
        debugPrint('💾 Using NPSProvider servers: ${activeServers.length}');
      } else {
        activeServers = appState.servers;
        debugPrint('💾 Using AppState servers: ${activeServers.length}');
      }

      debugPrint('💾 Starting save for month: ${_selectedMonth.year}-${_selectedMonth.month}');
      debugPrint('💾 Active servers: ${activeServers.length}');
      print('🔍 [MonthlyNPSDataEntry] SAVE: Active servers count: ${activeServers.length}');
      for (final server in activeServers) {
        print('🔍 [MonthlyNPSDataEntry] SAVE: Server ${server.name} (${server.id})');
      }

      int savedCount = 0;

      for (final server in activeServers) {
        final serverData = _serverData[server.id];
        debugPrint('💾 Server ${server.name} (ID: ${server.id}) - hasData: ${serverData?.hasData()}');
        
        if (serverData != null && serverData.hasData()) {
          // Create NPSMonthlyReport from the server data
          final monthKey = _selectedMonth.year * 100 + _selectedMonth.month;

          final report = NPSMonthlyReport(
            serverId: server.id.toString(), // Ensure consistent String format
            reportMonth: monthKey,
            reportYear: _selectedMonth.year,
            allTimeNpsPercentage:
                double.tryParse(serverData.allTimeNpsController.text),
            threeMonthNpsPercentage:
                double.tryParse(serverData.threeMonthNpsController.text),
            oneMonthNpsPercentage:
                double.tryParse(serverData.oneMonthNpsController.text),
            allTimeSales:
                double.tryParse(serverData.allTimeSalesController.text) ?? 0.0,
            allTimeTableCount:
                int.tryParse(serverData.allTimeTableCountController.text) ?? 0,
            monthFeedback:
                FeedbackCounts(yes: 0, maybe: 0, no: 0), // Default empty counts
            threeMonthFeedback: FeedbackCounts(yes: 0, maybe: 0, no: 0),
            allTimeFeedback: FeedbackCounts(yes: 0, maybe: 0, no: 0),
            dataAsOfDate: DateTime.now(),
          );

          debugPrint('💾 Saving report for server ${server.name}: NPS=${report.allTimeNpsPercentage}, Sales=${report.allTimeSales}, MonthKey=$monthKey');

          // Save the report using the calculator
          await npsProvider.calculator.saveMonthlyReport(report);
          savedCount++;
          debugPrint('✅ Saved NPS data for server ${server.name}');
        }
      }

      // Reload data after saving to show persisted values
      await _loadExistingData();

      if (mounted) {
        ErrorHandlingService.showSuccessSnackBar(
          context,
          'Successfully saved NPS data for $savedCount servers!',
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving NPS data: $e');
      if (mounted) {
        ErrorHandlingService.showErrorSnackBar(context, e);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

/// Helper class for managing feedback entries during data entry
class NPSFeedbackEntry {
  int? score;
  String? comment;

  NPSFeedbackEntry({this.score, this.comment});
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthYearPickerDialog({
    required this.initialDate,
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
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Month'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear--;
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$_selectedYear',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear++;
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Month selection grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final monthIndex = index + 1;
                final monthNames = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec'
                ];

                return SizedBox(
                  width: 70,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = monthIndex;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMonth == monthIndex
                          ? Theme.of(context).primaryColor
                          : null,
                      foregroundColor:
                          _selectedMonth == monthIndex ? Colors.white : null,
                      padding: const EdgeInsets.all(4),
                    ),
                    child: Text(
                      monthNames[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }),
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
            final selectedDate = DateTime(_selectedYear, _selectedMonth, 1);
            Navigator.of(context).pop(selectedDate);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
