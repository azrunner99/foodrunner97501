import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';

class ServerNPSScorecardScreen extends StatefulWidget {
  const ServerNPSScorecardScreen({super.key});

  @override
  State<ServerNPSScorecardScreen> createState() => _ServerNPSScorecardScreenState();
}

class _ServerNPSScorecardScreenState extends State<ServerNPSScorecardScreen> {
  List<Map<String, dynamic>> _availableMonths = [];
  String? _selectedMonthKey;
  List<Map<String, dynamic>> _serverNPSData = [];
  bool _isLoading = true;
  bool _isLoadingServerData = false;
  String? _errorMessage;
  String _sortBy = 'name'; // Default sort by name

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  Future<void> _loadAvailableMonths() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final npsProvider = context.read<NPSProvider>();
      await npsProvider.initialize();
      
      final months = await npsProvider.database.getAvailableReportMonths();
      
      setState(() {
        _availableMonths = months;
        // Set the first month as selected, using a unique key
        if (months.isNotEmpty && _selectedMonthKey == null) {
          final firstMonth = months.first;
          _selectedMonthKey = _getMonthKey(firstMonth);
        }
        _isLoading = false;
      });

      // Auto-load data for the first month if available
      if (_selectedMonthKey != null && months.isNotEmpty) {
        await _loadServerNPSData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load available months: $e';
        _isLoading = false;
      });
    }
  }

  String _getMonthKey(Map<String, dynamic> monthData) {
    return '${monthData['report_month']}_${monthData['report_year']}';
  }

  Map<String, dynamic>? _getSelectedMonthData() {
    if (_selectedMonthKey == null) return null;
    try {
      return _availableMonths.firstWhere(
        (month) => _getMonthKey(month) == _selectedMonthKey,
      );
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _getSortedServerData() {
    final sortedData = List<Map<String, dynamic>>.from(_serverNPSData);
    
    switch (_sortBy) {
      case 'name':
        sortedData.sort((a, b) => 
          (a['server_name'] ?? '').toString().toLowerCase().compareTo(
            (b['server_name'] ?? '').toString().toLowerCase()
          )
        );
        break;
      case 'all_time_nps':
        sortedData.sort((a, b) {
          final aValue = a['all_time_nps_percentage'] as double?;
          final bValue = b['all_time_nps_percentage'] as double?;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          return bValue.compareTo(aValue); // Descending order
        });
        break;
      case 'three_month_nps':
        sortedData.sort((a, b) {
          final aValue = a['three_month_nps_percentage'] as double?;
          final bValue = b['three_month_nps_percentage'] as double?;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          return bValue.compareTo(aValue); // Descending order
        });
        break;
      case 'one_month_nps':
        sortedData.sort((a, b) {
          final aValue = a['one_month_nps_percentage'] as double?;
          final bValue = b['one_month_nps_percentage'] as double?;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          return bValue.compareTo(aValue); // Descending order
        });
        break;
    }
    
    return sortedData;
  }

  Future<void> _loadServerNPSData() async {
    if (_selectedMonthKey == null) return;
    
    try {
      setState(() {
        _isLoadingServerData = true;
        _errorMessage = null;
      });

      final selectedMonth = _getSelectedMonthData();
      if (selectedMonth == null) return;

      final npsProvider = context.read<NPSProvider>();
      final reportMonth = selectedMonth['report_month'] as int;
      final reportYear = selectedMonth['report_year'] as int;

      final serverData = await npsProvider.getServerNPSDataForMonth(reportMonth, reportYear);
      
      setState(() {
        _serverNPSData = serverData;
        _isLoadingServerData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load server NPS data: $e';
        _isLoadingServerData = false;
      });
    }
  }

  String _formatMonthYear(Map<String, dynamic> monthData) {
    final reportMonth = monthData['report_month'] as int;
    final reportYear = monthData['report_year'] as int;
    
    // Extract month and year from YYYYMM format if needed
    int month, year;
    if (reportMonth > 12) {
      // Format is YYYYMM
      year = reportMonth ~/ 100;
      month = reportMonth % 100;
    } else {
      // Format is just month (1-12)
      month = reportMonth;
      year = reportYear;
    }
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    // Ensure month is in valid range (1-12)
    if (month < 1 || month > 12) {
      return 'Invalid Date';
    }
    
    return '${monthNames[month - 1]} $year';
  }

  String _formatNPSPercentage(dynamic value) {
    if (value == null) return 'N/A';
    final percentage = value as double;
    return '${percentage.toStringAsFixed(1)}%';
  }

  Color _getNPSColor(dynamic value) {
    if (value == null) return Colors.grey;
    final percentage = value as double;
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server NPS Scorecard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading available NPS reports...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadAvailableMonths,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _availableMonths.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No NPS Reports Available',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'No monthly NPS reports have been saved by administrators yet. '
                              'Check back after admin reports have been generated.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Selection Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Report Month',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _selectedMonthKey,
                                    decoration: const InputDecoration(
                                      labelText: 'Month',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.calendar_month),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    isDense: false,
                                    items: _availableMonths.isNotEmpty
                                        ? _availableMonths.map((month) {
                                            final key = _getMonthKey(month);
                                            return DropdownMenuItem<String>(
                                              value: key,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _formatMonthYear(month),
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      '${month['server_count']} servers reported',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList()
                                        : [
                                            const DropdownMenuItem<String>(
                                              value: null,
                                              child: Text('No months available'),
                                            ),
                                          ],
                                    onChanged: _availableMonths.isNotEmpty
                                        ? (monthKey) {
                                            setState(() {
                                              _selectedMonthKey = monthKey;
                                            });
                                            if (monthKey != null) {
                                              _loadServerNPSData();
                                            }
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Sort Options
                          if (_selectedMonthKey != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Sort by:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _sortBy,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          isDense: true,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'name',
                                            child: Text('Server Name'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'all_time_nps',
                                            child: Text('All Time NPS'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'three_month_nps',
                                            child: Text('3 Month NPS'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'one_month_nps',
                                            child: Text('1 Month NPS'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _sortBy = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Server NPS Data Table
                          if (_selectedMonthKey != null) ...[
                            Builder(
                              builder: (context) {
                                final selectedMonth = _getSelectedMonthData();
                                return Text(
                                  selectedMonth != null 
                                    ? 'Server NPS Results - ${_formatMonthYear(selectedMonth)}'
                                    : 'Server NPS Results',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingServerData)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_serverNPSData.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'No server data available for this month',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          // Header Row
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: const Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    'Server Name',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    'All Time NPS',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '3 Month NPS',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '1 Month NPS',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Server Data Rows
                                          ..._getSortedServerData().map((serverData) {
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade200),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      serverData['server_name'] ?? 'Unknown',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getNPSColor(serverData['all_time_nps_percentage'])
                                                            .withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: _getNPSColor(serverData['all_time_nps_percentage']),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _formatNPSPercentage(serverData['all_time_nps_percentage']),
                                                        style: TextStyle(
                                                          color: _getNPSColor(serverData['all_time_nps_percentage']),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getNPSColor(serverData['three_month_nps_percentage'])
                                                            .withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: _getNPSColor(serverData['three_month_nps_percentage']),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _formatNPSPercentage(serverData['three_month_nps_percentage']),
                                                        style: TextStyle(
                                                          color: _getNPSColor(serverData['three_month_nps_percentage']),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getNPSColor(serverData['one_month_nps_percentage'])
                                                            .withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: _getNPSColor(serverData['one_month_nps_percentage']),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _formatNPSPercentage(serverData['one_month_nps_percentage']),
                                                        style: TextStyle(
                                                          color: _getNPSColor(serverData['one_month_nps_percentage']),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}