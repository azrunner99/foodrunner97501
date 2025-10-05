import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';

class ServerNPSScorecardScreen extends StatefulWidget {
  const ServerNPSScorecardScreen({super.key});

  @override
  State<ServerNPSScorecardScreen> createState() =>
      _ServerNPSScorecardScreenState();
}

class _ServerNPSScorecardScreenState extends State<ServerNPSScorecardScreen> {
  int _selectedMonth = 7; // July
  int _selectedYear = 2025;
  List<Map<String, dynamic>> _serverNPSData = [];
  bool _isLoadingServerData = false;
  int? _selectedMonthKey;
  String _sortBy = 'server_name'; // Default sort by all-time NPS
  bool _sortDescending = false; // Default to A-Z for names
  List<Map<String, dynamic>> _availableMonths = []; // Available months with data
  bool _isLoadingMonths = false;

  @override
  void initState() {
    super.initState();
    _selectedMonthKey = _selectedYear * 100 + _selectedMonth;
    _loadAvailableMonths();
  }

  Future<void> _loadServerNPSData() async {
      setState(() {
        _isLoadingServerData = true;
      });

    try {
      final npsProvider = context.read<NPSProvider>();

      // Ensure provider is initialized
      if (!npsProvider.isInitialized) {
        await npsProvider.initialize();
      }

      // Get the data directly using the method we know works
      final serverData = await _getServerNPSDataForMonth(npsProvider.database, _selectedMonth, _selectedYear);

      print('[NPS Scorecard] Loaded ${serverData.length} servers for $_selectedMonth/$_selectedYear');

      // Remove duplicates based on server name (keep the one with best data)
      final deduplicatedData = _deduplicateServerData(serverData);
      
      setState(() {
        _serverNPSData = deduplicatedData;
        _isLoadingServerData = false;
      });
      
      // Sort the data after loading
      _sortServerData();
    } catch (e) {
      print('[NPS Scorecard] Error loading server data: $e');
      setState(() {
        _serverNPSData = [];
        _isLoadingServerData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server NPS Scorecard 😊'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
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
                    Text(
                      'Select Reporting Period',
                      style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _isLoadingMonths
                              ? const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  value: '${_selectedYear}_$_selectedMonth',
                                    decoration: const InputDecoration(
                                      labelText: 'Month',
                                      border: OutlineInputBorder(),
                                  ),
                                  items: _availableMonths.map((monthData) {
                                    final monthKey = monthData['month_key'] as String;
                                    final monthName = monthData['display_name'] as String;
                                    final serverCount = monthData['server_count'] as int;
                                            return DropdownMenuItem<String>(
                                      value: monthKey,
                                      child: Text('$monthName ($serverCount servers)'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      final parts = value.split('_');
                                      final year = int.parse(parts[0]);
                                      final month = int.parse(parts[1]);
                                            setState(() {
                                        _selectedYear = year;
                                        _selectedMonth = month;
                                        _selectedMonthKey = year * 100 + month;
                                            });
                                              _loadServerNPSData();
                                            }
                                  },
                                ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                    Text(
                      'Showing NPS data for ${_serverNPSData.length} servers',
                      style: Theme.of(context).textTheme.bodyMedium,
                            ),
                  ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // NPS Color Reference Key
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                    Text(
                      'NPS Performance Key',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sort Dropdown
                    Row(
                      children: [
                        const Text(
                          'Sort by: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                            value: _sortBy,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: const [
                      DropdownMenuItem(value: 'server_name', child: Text('Server Name')),
                      DropdownMenuItem(value: 'all_time_nps', child: Text('All-Time NPS')),
                      DropdownMenuItem(value: 'three_month_nps', child: Text('3-Month NPS')),
                      DropdownMenuItem(value: 'one_month_nps', child: Text('1-Month NPS')),
                      DropdownMenuItem(value: 'check_average', child: Text('All-Time Check Avg')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _sortBy = value;
                                            });
                                _sortServerData();
                                          }
                                        },
                                      ),
                                    ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _sortDescending = !_sortDescending;
                            });
                            _sortServerData();
                          },
                          icon: Icon(
                            _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                            color: Colors.blue,
                          ),
                          tooltip: _sortDescending ? 'Highest First' : 'Lowest First',
                        ),
                      ],
                            ),
                            const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                                    Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(color: Colors.green, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'EXCELLENT',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '90%+',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              border: Border.all(color: Colors.orange, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            child: const Column(
                                children: [
                                Text(
                                  'GOOD',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '80-89%',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            child: const Column(
                                    children: [
                                Text(
                                  'NEEDS IMPROVEMENT',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  'Below 80%',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
            ),
            const SizedBox(height: 16),
            
            // Server List
            Expanded(
              child: _isLoadingServerData
                  ? const Center(child: CircularProgressIndicator())
                  : _serverNPSData.isEmpty
                      ? const Center(
                                  child: Text(
                                    'No server data available for this month',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : Card(
                                  child: Column(
                                    children: [
                              // Header
                                      Container(
                                padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Server Name',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                      child: Center(
                                              child: Text(
                                          'All-Time NPS',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                      child: Center(
                                              child: Text(
                                          '3-Month NPS',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                                ),
                                        ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                      child: Center(
                                              child: Text(
                                          '1-Month NPS',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                                ),
                                        ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                      child: Center(
                                              child: Text(
                                          'All-Time Check Avg',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                                ),
                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              // Server List
                                      Expanded(
                                child: ListView.builder(
                                  itemCount: _serverNPSData.length,
                                  itemBuilder: (context, index) {
                                    final server = _serverNPSData[index];
                                    final allTimeNPS = server['all_time_nps_percentage'] as double? ?? 0.0;
                                    final threeMonthNPS = server['three_month_nps_percentage'] as double? ?? 0.0;
                                    final oneMonthNPS = server['one_month_nps_percentage'] as double? ?? 0.0;
                                    final sales = server['all_time_sales'] as double? ?? 0.0;
                                    final tableCount = server['all_time_table_count'] as int? ?? 0;
                                    
                                    // Calculate check average (sales ÷ table count)
                                    final checkAverage = tableCount > 0 ? sales / tableCount : 0.0;
                                    
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                              server['server_name'] ?? 'Unknown',
                                              style: const TextStyle(fontSize: 12),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                            child: Center(
                                                                child: Text(
                                                '${allTimeNPS.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getNPSColor(allTimeNPS),
                                                ),
                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                            child: Center(
                                                                child: Text(
                                                '${threeMonthNPS.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getNPSColor(threeMonthNPS),
                                                ),
                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                            child: Center(
                                                                child: Text(
                                                oneMonthNPS > 0 ? '${oneMonthNPS.toStringAsFixed(1)}%' : 'N/A',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: oneMonthNPS > 0 ? _getNPSColor(oneMonthNPS) : Colors.grey,
                                                ),
                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Center(
                                                          child: Text(
                                                '\$${checkAverage.toStringAsFixed(2)}',
                                                            style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                  },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
    );
  }

  Color _getNPSColor(double npsScore) {
    if (npsScore >= 90) return Colors.green;
    if (npsScore >= 80) return Colors.orange;
    return Colors.red;
  }

  /// Load available months that have NPS report data
  Future<void> _loadAvailableMonths() async {
    setState(() {
      _isLoadingMonths = true;
    });

    try {
      final npsProvider = context.read<NPSProvider>();
      
      // Ensure provider is initialized
      if (!npsProvider.isInitialized) {
        await npsProvider.initialize();
      }

      // Get available months with data
      final availableMonths = await _getAvailableMonthsWithData(npsProvider.database);
      
      print('[NPS Scorecard] Found ${availableMonths.length} months with data');
      
      setState(() {
        _availableMonths = availableMonths;
        _isLoadingMonths = false;
      });
      
      // Load data for the selected month if it exists
      if (availableMonths.isNotEmpty) {
        // Check if current selection exists, otherwise use first available
        final currentKey = '${_selectedYear}_$_selectedMonth';
        final hasCurrentMonth = availableMonths.any((m) => m['month_key'] == currentKey);
        
        if (!hasCurrentMonth) {
          // Use first available month
          final firstMonth = availableMonths.first;
          final parts = (firstMonth['month_key'] as String).split('_');
          setState(() {
            _selectedYear = int.parse(parts[0]);
            _selectedMonth = int.parse(parts[1]);
            _selectedMonthKey = _selectedYear * 100 + _selectedMonth;
          });
        }
        
        _loadServerNPSData();
        }
      } catch (e) {
      print('[NPS Scorecard] Error loading available months: $e');
      setState(() {
        _availableMonths = [];
        _isLoadingMonths = false;
      });
    }
  }

  /// Remove duplicate servers based on server name, keeping the best data
  List<Map<String, dynamic>> _deduplicateServerData(List<Map<String, dynamic>> serverData) {
    final Map<String, Map<String, dynamic>> uniqueServers = {};
    
    for (final server in serverData) {
      final serverName = server['server_name'] as String? ?? 'Unknown';
      
      if (!uniqueServers.containsKey(serverName)) {
        // First occurrence of this server name
        uniqueServers[serverName] = server;
      } else {
        // Duplicate found - keep the one with better data (higher all-time NPS or more recent data)
        final existing = uniqueServers[serverName]!;
        final existingNPS = existing['all_time_nps_percentage'] as double? ?? 0.0;
        final currentNPS = server['all_time_nps_percentage'] as double? ?? 0.0;
        
        // Keep the server with higher all-time NPS, or if equal, keep the one with more sales data
        if (currentNPS > existingNPS) {
          uniqueServers[serverName] = server;
        } else if (currentNPS == existingNPS) {
          final existingSales = existing['all_time_sales'] as double? ?? 0.0;
          final currentSales = server['all_time_sales'] as double? ?? 0.0;
          if (currentSales > existingSales) {
            uniqueServers[serverName] = server;
          }
        }
      }
    }
    
    final deduplicated = uniqueServers.values.toList();
    print('[NPS Scorecard] Deduplicated ${serverData.length} records to ${deduplicated.length} unique servers');
    
    return deduplicated;
  }

  /// Sort server data based on selected criteria
  void _sortServerData() {
    setState(() {
      _serverNPSData.sort((a, b) {
        if (_sortBy == 'server_name') {
          // String comparison for server names
          final nameA = (a['server_name'] as String? ?? '').toLowerCase();
          final nameB = (b['server_name'] as String? ?? '').toLowerCase();
          return _sortDescending ? nameB.compareTo(nameA) : nameA.compareTo(nameB);
        }
        
        // Numeric comparison for other fields
        double valueA = 0.0;
        double valueB = 0.0;
        
        switch (_sortBy) {
          case 'all_time_nps':
            valueA = a['all_time_nps_percentage'] as double? ?? 0.0;
            valueB = b['all_time_nps_percentage'] as double? ?? 0.0;
            break;
          case 'three_month_nps':
            valueA = a['three_month_nps_percentage'] as double? ?? 0.0;
            valueB = b['three_month_nps_percentage'] as double? ?? 0.0;
            break;
          case 'one_month_nps':
            valueA = a['one_month_nps_percentage'] as double? ?? 0.0;
            valueB = b['one_month_nps_percentage'] as double? ?? 0.0;
            break;
          case 'check_average':
            final salesA = a['all_time_sales'] as double? ?? 0.0;
            final tableCountA = a['all_time_table_count'] as int? ?? 0;
            valueA = tableCountA > 0 ? salesA / tableCountA : 0.0;
            
            final salesB = b['all_time_sales'] as double? ?? 0.0;
            final tableCountB = b['all_time_table_count'] as int? ?? 0;
            valueB = tableCountB > 0 ? salesB / tableCountB : 0.0;
            break;
        }
        
        if (_sortDescending) {
          return valueB.compareTo(valueA); // Highest first
        } else {
          return valueA.compareTo(valueB); // Lowest first
        }
      });
    });
  }

  /// Get available months that have NPS report data
  Future<List<Map<String, dynamic>>> _getAvailableMonthsWithData(dynamic database) async {
    try {
      // Query the database to find months with actual data
      final monthsWithData = <Map<String, dynamic>>[];
      
      // Check months from 2024-2026 (you can adjust this range)
      for (int year = 2024; year <= 2026; year++) {
        for (int month = 1; month <= 12; month++) {
          final serverData = await database.getServerNPSDataForMonth(month, year);
          if (serverData.isNotEmpty) {
            // Deduplicate to get accurate count
            final deduplicatedData = _deduplicateServerData(serverData);
            final monthNames = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            
            monthsWithData.add({
              'month_key': '${year}_$month',
              'display_name': '${monthNames[month - 1]} $year',
              'server_count': deduplicatedData.length,
              'year': year,
              'month': month,
            });
          }
        }
      }
      
      // Sort by year and month (most recent first)
      monthsWithData.sort((a, b) {
        final aYear = a['year'] as int;
        final aMonth = a['month'] as int;
        final bYear = b['year'] as int;
        final bMonth = b['month'] as int;
        
        if (aYear != bYear) {
          return bYear.compareTo(aYear); // Most recent year first
        }
        return bMonth.compareTo(aMonth); // Most recent month first
      });
      
      return monthsWithData;
      } catch (e) {
      print('[NPS Scorecard] Error getting available months: $e');
        return [];
      }
  }

  /// Get server NPS data for a specific month
  Future<List<Map<String, dynamic>>> _getServerNPSDataForMonth(
      dynamic database, int reportMonth, int reportYear) async {
    try {
      print('[NPS Scorecard] Querying for month=$reportMonth, year=$reportYear');
      
      // Use the adapter method that we know works
      final serverData = await database.getServerNPSDataForMonth(reportMonth, reportYear);
      
      print('[NPS Scorecard] Retrieved ${serverData.length} server records');
      
      return serverData;
    } catch (e) {
      print('[NPS Scorecard] Error getting server data: $e');
      return [];
    }
  }
}