import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../providers/nps_provider.dart';

class ServerPerformanceProfileScreen extends StatefulWidget {
  final Server server;
  final ServerPerformanceData performance;

  const ServerPerformanceProfileScreen({
    super.key,
    required this.server,
    required this.performance,
  });

  @override
  State<ServerPerformanceProfileScreen> createState() =>
      _ServerPerformanceProfileScreenState();
}

class _ServerPerformanceProfileScreenState
    extends State<ServerPerformanceProfileScreen> {
  bool _isLoading = true;
  List<String> _npsHistoryText = [];
  Map<String, dynamic> _npsMetrics = {};
  List<ShiftRecord> _allServerShifts = [];
  List<ShiftRecord> _recentShifts = [];
  int _totalHistoricalRuns = 0;
  int _totalPizookieRuns = 0;
  int _currentShiftRuns = 0;
  int _currentPizookieRuns = 0;
  int _appAllTimeRuns = 0;
  DateTime? _earliestShift;
  DateTime? _latestShift;

  @override
  void initState() {
    super.initState();
    _loadServerData();
  }

  Future<void> _loadServerData() async {
    setState(() => _isLoading = true);

    try {
      await _loadShiftHistory();
      await _loadNPSData();
    } catch (e) {
      print('[Server Profile] Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadShiftHistory() async {
    final app = context.read<AppState>();

    print(
        '[Profile Debug] Loading shift history for server ${widget.server.name} (ID: ${widget.server.id})');
    print('[Profile Debug] Total shifts in app.history: ${app.history.length}');

    // Get ALL historical shifts for this server
    _allServerShifts = app.history
        .where((shift) =>
            shift.counts.containsKey(widget.server.id) &&
            (shift.counts[widget.server.id] ?? 0) > 0)
        .toList();

    print(
        '[Profile Debug] Found ${_allServerShifts.length} shifts for this server');
    print(
        '[Profile Debug] Server ID exists in shift counts: ${app.history.map((s) => s.counts.containsKey(widget.server.id)).toList()}');

    // Debug: Check a few sample shifts
    if (app.history.isNotEmpty) {
      final sampleShifts = app.history.take(3);
      for (var shift in sampleShifts) {
        print(
            '[Profile Debug] Sample shift: ${shift.start}, counts: ${shift.counts}, contains ${widget.server.id}: ${shift.counts.containsKey(widget.server.id)}');
      }
    }

    // USE AUTHORITATIVE SOURCE: Get all-time runs from app.totals (tap data)
    // This is the same source used by the MVP screen and is the most accurate
    _appAllTimeRuns = app.totals[widget.server.id] ?? 0;
    _totalHistoricalRuns =
        _appAllTimeRuns; // Use authoritative source for consistency

    print(
        '[Profile Debug] Using authoritative total from app.totals: $_appAllTimeRuns');

    // Calculate pizookie runs from shift data (this is typically accurate)
    _totalPizookieRuns = _allServerShifts.fold<int>(
        0, (sum, shift) => sum + (shift.pizookieCounts[widget.server.id] ?? 0));

    print(
        '[Profile Debug] Calculated totals: authoritative=$_appAllTimeRuns, pizookies=$_totalPizookieRuns');

    // Current shift data
    _currentShiftRuns =
        app.shiftActive ? (app.currentCounts[widget.server.id] ?? 0) : 0;
    _currentPizookieRuns = app.shiftActive
        ? (app.currentPizookieCounts[widget.server.id] ?? 0)
        : 0;

    print(
        '[Profile Debug] Current shift: active=${app.shiftActive}, runs=$_currentShiftRuns, pizookies=$_currentPizookieRuns');

    // Recent shifts (last 90 days)
    _recentShifts = _allServerShifts
        .where((shift) => shift.start
            .isAfter(DateTime.now().subtract(const Duration(days: 90))))
        .take(50)
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    // Date range
    final sortedShifts = _allServerShifts
      ..sort((a, b) => a.start.compareTo(b.start));
    _earliestShift = sortedShifts.isNotEmpty ? sortedShifts.first.start : null;
    _latestShift = sortedShifts.isNotEmpty ? sortedShifts.last.start : null;
  }

  Future<void> _loadNPSData() async {
    final npsProvider = context.read<NPSProvider>();

    try {
      final npsServers =
          await npsProvider.database.getAllServers(activeOnly: false);
      print('[NPS Debug] Looking for server name: "${widget.server.name}"');
      print(
          '[NPS Debug] Available NPS servers: ${npsServers.map((s) => s['name']).toList()}');

      // Try exact match first
      var npsServer = npsServers.firstWhere(
        (s) => s['name'] == widget.server.name,
        orElse: () => <String, dynamic>{},
      );

      // If no exact match, try case-insensitive match
      if (npsServer.isEmpty) {
        npsServer = npsServers.firstWhere(
          (s) =>
              (s['name'] as String).toLowerCase() ==
              widget.server.name.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (npsServer.isNotEmpty) {
          print(
              '[NPS Debug] Found case-insensitive match: "${npsServer['name']}"');
        }
      }

      // If still no match, try partial match
      if (npsServer.isEmpty) {
        npsServer = npsServers.firstWhere(
          (s) =>
              (s['name'] as String)
                  .toLowerCase()
                  .contains(widget.server.name.toLowerCase()) ||
              widget.server.name
                  .toLowerCase()
                  .contains((s['name'] as String).toLowerCase()),
          orElse: () => <String, dynamic>{},
        );
        if (npsServer.isNotEmpty) {
          print('[NPS Debug] Found partial match: "${npsServer['name']}"');
        }
      }

      if (npsServer.isNotEmpty) {
        final npsServerId = npsServer['id'] as int;

        List<String> adminNpsData = ['📊 ADMIN-ENTERED NPS DATA:'];

        // Check multiple months
        final monthsToCheck = [
          202509,
          202508,
          202507,
          202506,
          202505,
          202504,
          202503
        ];

        Map<String, dynamic>? latestReportData;
        int reportsFound = 0;

        for (final monthKey in monthsToCheck) {
          try {
            final reportData = await npsProvider.database
                .getMonthlyReport(npsServerId, monthKey);
            if (reportData != null) {
              reportsFound++;
              latestReportData ??= reportData;

              final monthStr =
                  '${monthKey.toString().substring(0, 4)}-${monthKey.toString().substring(4)}';
              final allTimeNps = reportData['all_time_nps_percentage'];
              final threeMonthNps = reportData['three_month_nps_percentage'];
              final oneMonthNps = reportData['one_month_nps_percentage'];
              final allTimeSales = reportData['all_time_sales'] ?? 0.0;
              final allTimeChecks = reportData['all_time_table_count'] ?? 0;

              final checkAverage =
                  allTimeChecks > 0 ? (allTimeSales / allTimeChecks) : 0.0;

              adminNpsData.add('📅 $monthStr Report:');
              if (allTimeNps != null)
                adminNpsData.add(
                    '   All-time NPS: ${(allTimeNps as num).toStringAsFixed(1)}%');
              if (threeMonthNps != null)
                adminNpsData.add(
                    '   3-month NPS: ${(threeMonthNps as num).toStringAsFixed(1)}%');
              if (oneMonthNps != null)
                adminNpsData.add(
                    '   1-month NPS: ${(oneMonthNps as num).toStringAsFixed(1)}%');
              adminNpsData.add(
                  '   All-time sales: \$${allTimeSales.toStringAsFixed(0)}');
              adminNpsData.add('   All-time checks: $allTimeChecks');
              adminNpsData.add(
                  '   💰 Check average: \$${checkAverage.toStringAsFixed(2)}');
              adminNpsData.add('');

              if (latestReportData == reportData) {
                _npsMetrics = {
                  'allTimeNps': allTimeNps,
                  'allTimeSales': allTimeSales,
                  'allTimeChecks': allTimeChecks,
                  'checkAverage': checkAverage,
                  'reportMonth': monthStr,
                };
              }
            }
          } catch (e) {
            continue;
          }
        }

        if (reportsFound == 0) {
          adminNpsData = [
            '📊 No admin-entered NPS reports found for ${widget.server.name}',
            '⚠️ Use Admin → NPS Data Entry to add monthly reports'
          ];
        } else {
          adminNpsData.insert(
              1, '✅ Found $reportsFound admin-entered monthly reports');
          adminNpsData.insert(2, '');
        }

        _npsHistoryText = adminNpsData;
      } else {
        _npsHistoryText = [
          '❌ Server "${widget.server.name}" not found in NPS database',
          '📋 Available NPS servers: ${npsServers.map((s) => s['name']).join(', ')}',
          '',
          '🔧 To fix this:',
          '1. Go to Admin → NPS System → Server Management',
          '2. Add "${widget.server.name}" to the NPS database',
          '3. Or check if the server name spelling matches exactly'
        ];
      }
    } catch (e) {
      _npsHistoryText = ['❌ Error loading admin NPS data: $e'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.server.name} - Performance Profile'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServerData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Performance Score Card
                  _buildPerformanceScoreCard(),
                  const SizedBox(height: 16),

                  // Statistics Overview
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),

                  // NPS & Financial Data
                  if (_npsMetrics.isNotEmpty) ...[
                    _buildNPSMetricsCard(),
                    const SizedBox(height: 16),
                  ],

                  // Current Period Metrics
                  _buildCurrentMetricsCard(),
                  const SizedBox(height: 16),

                  // Admin NPS Data
                  _buildAdminNPSCard(),
                  const SizedBox(height: 16),

                  // Shift History
                  _buildShiftHistoryCard(),
                  const SizedBox(height: 16),

                  // Current Shift Status
                  if (app.shiftActive &&
                      (_currentShiftRuns > 0 || _currentPizookieRuns > 0))
                    _buildCurrentShiftCard(),

                  const SizedBox(height: 16),

                  // Performance Insights
                  _buildInsightsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildPerformanceScoreCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  widget.performance.formattedScore,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.performance.rating.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.performance.rating.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Based on food running + NPS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    if (widget.performance.performanceScore < 50)
                      Text(
                        '⚠️ Low score may indicate missing NPS data',
                        style: TextStyle(
                          color: Colors.orange[100],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final app = context.read<AppState>();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  '📊 Complete Historical Statistics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('✅ Total food runs',
                '$_appAllTimeRuns (authoritative)', Colors.green),
            _buildStatRow(
                'Total historical shifts', '${_allServerShifts.length}'),
            _buildStatRow('Food runs (shifts data)',
                '$_totalHistoricalRuns (same as above for consistency)'),
            _buildStatRow('Historical pizookie runs', '$_totalPizookieRuns'),
            _buildStatRow(
                'Current shift active',
                app.shiftActive ? 'Yes' : 'No',
                app.shiftActive ? Colors.green : Colors.grey),
            if (app.shiftActive)
              _buildStatRow(
                  'Current shift runs', '$_currentShiftRuns', Colors.orange),
            _buildStatRow('Current pizookie runs', '$_currentPizookieRuns'),
            if (_earliestShift != null)
              _buildStatRow(
                  'First shift', _earliestShift!.toString().substring(0, 16)),
            if (_latestShift != null)
              _buildStatRow(
                  'Latest shift', _latestShift!.toString().substring(0, 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildNPSMetricsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  '💰 Admin NPS Metrics Summary',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_npsMetrics['allTimeNps'] != null)
              _buildStatRow(
                  'All-time NPS',
                  '${(_npsMetrics['allTimeNps'] as num).toStringAsFixed(1)}%',
                  Colors.blue),
            _buildStatRow(
                'All-time sales',
                '\$${(_npsMetrics['allTimeSales'] as num).toStringAsFixed(0)}',
                Colors.green),
            _buildStatRow('All-time checks', '${_npsMetrics['allTimeChecks']}'),
            _buildStatRow(
                '💰 Check average',
                '\$${(_npsMetrics['checkAverage'] as num).toStringAsFixed(2)}',
                Colors.orange),
            _buildStatRow('Last report', '${_npsMetrics['reportMonth']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMetricsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Current Period Metrics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Raw Efficiency',
                '${widget.performance.metrics.rawEfficiency.toStringAsFixed(2)} runs/shift'),
            _buildStatRow(
                'Guest Efficiency',
                widget.performance.metrics.guestEfficiency == 0.0
                    ? '0.00 runs/check (no check data entered)'
                    : '${widget.performance.metrics.guestEfficiency.toStringAsFixed(3)} runs/check'),
            _buildStatRow(
                'Sales Efficiency',
                widget.performance.metrics.salesEfficiency == 0.0
                    ? '0.00 runs/\$1K (no sales data entered)'
                    : '${widget.performance.metrics.salesEfficiency.toStringAsFixed(2)} runs/\$1K'),
            _buildStatRow('Consistency',
                '${widget.performance.metrics.consistencyScore.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminNPSCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings,
                    color: Colors.purple[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  '📊 Admin-Entered NPS & Sales Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._npsHistoryText.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: text.startsWith('📊') ||
                              text.startsWith('📅') ||
                              text.startsWith('✅') ||
                              text.startsWith('❌') ||
                              text.startsWith('⚠️')
                          ? 14
                          : 13,
                      fontWeight: text.startsWith('📊') || text.startsWith('📅')
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftHistoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.indigo[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  '📅 Recent Shift History (Last 90 Days)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentShifts.isNotEmpty)
              ..._recentShifts.take(20).map((shift) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${shift.start.toString().substring(0, 16)}: ${shift.counts[widget.server.id]} runs + ${shift.pizookieCounts[widget.server.id] ?? 0} pizookies (${shift.shiftType})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ))
            else
              const Text('No recent shifts found'),
            if (_allServerShifts.length > _recentShifts.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${_allServerShifts.length - _recentShifts.length} more historical shifts',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentShiftCard() {
    return Card(
      elevation: 2,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle, color: Colors.red[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  '🔴 ACTIVE SHIFT',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Type', context.read<AppState>().shiftType),
            _buildStatRow(
                'Current food runs', '$_currentShiftRuns', Colors.orange),
            _buildStatRow('Current pizookie runs', '$_currentPizookieRuns'),
            _buildStatRow('Status', 'In progress', Colors.green),
            _buildStatRow('Started',
                '~${DateTime.now().subtract(const Duration(hours: 2)).toString().substring(0, 16)} (estimated)'),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Performance Insights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.performance.insights.isNotEmpty)
              ...widget.performance.insights.take(5).map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                            left: BorderSide(
                                width: 4, color: Colors.amber[600]!)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(insight.description),
                        ],
                      ),
                    ),
                  ))
            else
              const Text('No specific insights available.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
