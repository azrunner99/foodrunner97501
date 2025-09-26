/// Station/Section Analytics Dashboard Screen
/// Comprehensive analytics interface for section-level performance monitoring

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../app_state.dart';
import '../models.dart';
import '../storage.dart';
import '../models/station_type.dart';
import '../models/station_performance_metric.dart';
import '../services/station_analytics_service.dart';
import '../services/enhanced_station_analytics_service.dart';
import '../services/advanced_station_analytics_service.dart';
import '../services/historical_station_analytics_service.dart';
import '../services/stations_repository.dart';
import '../widgets/real_time_station_monitor.dart';
import '../widgets/advanced_station_analytics_dashboard.dart';
import '../widgets/historical_station_analytics_dashboard.dart';
import '../utils/log.dart';

/// Section performance data for analytics
class SectionPerformanceData {
  final String sectionName;
  final String stationType;
  final int totalRuns;
  final int totalShifts;
  final double averageRunsPerShift;
  final double totalSales;
  final double averageSalesPerRun;
  final int totalServers;
  final List<String> serverNames;
  final double efficiencyScore;
  final double npsScore;
  final int guestCount;
  // Phase 2: Enhanced data integration
  final double? threeMonthNPSAverage;
  final int totalNPSResponses;
  final double? averageTicketSize;
  final int totalTablesServed;
  final double? averageGuestCountPerTable;
  final Map<String, double> serverPerformanceScores;
  final List<String> performanceInsights;
  final bool hasNPSData;
  final bool hasSalesData;
  final bool hasGuestData;

  SectionPerformanceData({
    required this.sectionName,
    required this.stationType,
    required this.totalRuns,
    required this.totalShifts,
    required this.averageRunsPerShift,
    required this.totalSales,
    required this.averageSalesPerRun,
    required this.totalServers,
    required this.serverNames,
    required this.efficiencyScore,
    required this.npsScore,
    required this.guestCount,
    // Phase 2: Enhanced data integration
    this.threeMonthNPSAverage,
    this.totalNPSResponses = 0,
    this.averageTicketSize,
    this.totalTablesServed = 0,
    this.averageGuestCountPerTable,
    this.serverPerformanceScores = const {},
    this.performanceInsights = const [],
    this.hasNPSData = false,
    this.hasSalesData = false,
    this.hasGuestData = false,
  });
}

class StationAnalyticsScreen extends StatefulWidget {
  const StationAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<StationAnalyticsScreen> createState() => _StationAnalyticsScreenState();
}

class _StationAnalyticsScreenState extends State<StationAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<StationType> _stationTypes = [];
  String? _selectedStationType;
  List<SectionPerformanceData> _sectionPerformances = [];
  List<String> _performanceInsights = [];
  Map<String, double> _stationEfficiencies = {};
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStationTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStationTypes() async {
    setState(() => _isLoading = true);
    
    try {
      d('[StationAnalytics] Loading station types...');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('station_types');
      
      if (jsonString != null) {
        final List decoded = json.decode(jsonString);
        final stationTypes = decoded
            .map((e) => StationType.fromJson(e))
            .cast<StationType>()
            .toList();
        
        d('[StationAnalytics] Loaded ${stationTypes.length} station types');
        for (final stationType in stationTypes) {
          d('[StationAnalytics] - ${stationType.name}: ${stationType.abbreviation} (${stationType.sections} sections)');
        }
        
        setState(() {
          _stationTypes = stationTypes;
          if (stationTypes.isNotEmpty) {
            _selectedStationType = stationTypes.first.name;
            d('[StationAnalytics] Selected station type: $_selectedStationType');
            _loadSectionAnalytics();
          } else {
            _isLoading = false;
          }
        });
      } else {
        d('[StationAnalytics] No station types found');
        setState(() {
          _isLoading = false;
          _stationTypes = [];
          _selectedStationType = null;
        });
      }
    } catch (e) {
      d('[StationAnalytics] Error loading station types: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading station types: $e')),
        );
      }
    }
  }

  Future<void> _loadSectionAnalytics() async {
    if (_selectedStationType == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      d('[StationAnalytics] Loading section analytics for $_selectedStationType...');
      
      // Load shift records
      final List<Map> rawRecords = 
          (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
      final allRecords = rawRecords.map((json) => 
          ShiftRecord.fromMap(Map<String, dynamic>.from(json))).toList();
      
      d('[StationAnalytics] Loaded ${allRecords.length} shift records');
      
      // Find the selected station type
      final selectedType = _stationTypes.firstWhere(
        (type) => type.name == _selectedStationType,
        orElse: () => _stationTypes.first,
      );
      
      // Generate section performance data from real data
      final sectionPerformances = await _generateSectionPerformanceDataFromRealData(
        selectedType, 
        allRecords
      );
      
      d('[StationAnalytics] Generated ${sectionPerformances.length} section performances from real data');
      
      setState(() {
        _sectionPerformances = sectionPerformances;
        _isLoading = false;
      });
    } catch (e) {
      d('[StationAnalytics] Error loading section analytics: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading section analytics: $e')),
        );
      }
    }
  }

  Future<List<SectionPerformanceData>> _generateSectionPerformanceDataFromRealData(
    StationType stationType, 
    List<ShiftRecord> shiftRecords
  ) async {
    final List<SectionPerformanceData> performances = [];
    
    // Get real station/section assignments from multiple sources
    final lunchStationTypes = await StationsRepository.getLunchStationType();
    final dinnerStationTypes = await StationsRepository.getDinnerStationType();
    final lunchStationSections = await Storage.getLunchStationSection();
    final dinnerStationSections = await Storage.getDinnerStationSection();
    
    // Get server data from AppState
    final appState = Provider.of<AppState>(context, listen: false);
    final servers = appState.servers;
    
    d('[StationAnalytics] Real data sources:');
    d('[StationAnalytics] - Lunch station types: $lunchStationTypes');
    d('[StationAnalytics] - Dinner station types: $dinnerStationTypes');
    d('[StationAnalytics] - Lunch station sections: $lunchStationSections');
    d('[StationAnalytics] - Dinner station sections: $dinnerStationSections');
    d('[StationAnalytics] - Servers with station types: ${servers.where((s) => s.stationType != null).map((s) => '${s.name}: ${s.stationType}').toList()}');
    
    // Combine all station assignments from different sources
    final allStationAssignments = <String, String>{};
    final allSectionAssignments = <String, String>{};
    
    // Add from shift records
    for (final shift in shiftRecords) {
      if (shift.stationAssignments != null) {
        allStationAssignments.addAll(shift.stationAssignments!);
      }
      if (shift.sectionAssignments != null) {
        allSectionAssignments.addAll(shift.sectionAssignments!);
      }
    }
    
    // Add from lunch/dinner assignments
    allStationAssignments.addAll(Map<String, String>.from(lunchStationTypes));
    allStationAssignments.addAll(Map<String, String>.from(dinnerStationTypes));
    allSectionAssignments.addAll(Map<String, String>.from(lunchStationSections));
    allSectionAssignments.addAll(Map<String, String>.from(dinnerStationSections));
    
    // Add from server-level station types
    for (final server in servers) {
      if (server.stationType != null) {
        allStationAssignments[server.id] = server.stationType!;
      }
    }
    
    d('[StationAnalytics] Combined station assignments: $allStationAssignments');
    d('[StationAnalytics] Combined section assignments: $allSectionAssignments');
    
    // Filter to only servers assigned to the selected station type
    final serversInStation = allStationAssignments.entries
        .where((entry) => entry.value == stationType.name)
        .map((entry) => entry.key)
        .toList();
    
    d('[StationAnalytics] Servers in $stationType: $serversInStation');
    
    if (serversInStation.isEmpty) {
      d('[StationAnalytics] No servers assigned to $stationType - returning empty data');
      return performances;
    }
    
    // Generate sections for this station type
    d('[StationAnalytics] Generating sections for ${stationType.name} (${stationType.abbreviation}) with ${stationType.sections} sections');
    for (int i = 1; i <= stationType.sections; i++) {
      final sectionName = '${stationType.abbreviation} $i';
      d('[StationAnalytics] Generated section name: $sectionName');
      
      // Find servers assigned to this section
      final serversInSection = allSectionAssignments.entries
          .where((entry) => entry.value == i.toString() && serversInStation.contains(entry.key))
          .map((entry) => entry.key)
          .toList();
      
      d('[StationAnalytics] Section $sectionName: Servers $serversInSection');
      
      // Calculate metrics for this section from shift records
      int totalRuns = 0;
      int totalShifts = 0;
      Set<String> serverIds = {};
      List<String> serverNames = [];
      
      for (final shift in shiftRecords) {
        bool hasServerInThisSection = false;
        
        for (final serverId in serversInSection) {
          if (shift.counts.containsKey(serverId)) {
            hasServerInThisSection = true;
            serverIds.add(serverId);
            totalRuns += shift.counts[serverId] ?? 0;
          }
        }
        
        if (hasServerInThisSection) {
          totalShifts++;
        }
      }
      
      // Get server names
      for (final serverId in serversInSection) {
        final server = servers.firstWhere(
          (s) => s.id == serverId,
          orElse: () => Server(id: serverId, name: 'Unknown Server'),
        );
        serverNames.add(server.name);
      }
      
      // Only add section if it has actual data
      if (totalRuns > 0 || totalShifts > 0 || serversInSection.isNotEmpty) {
        final averageRunsPerShift = totalShifts > 0 ? totalRuns / totalShifts : 0.0;
        final efficiencyScore = _calculateEfficiencyScore(averageRunsPerShift);
        
        // Phase 2: Enhanced data integration
        d('[StationAnalytics] Getting enhanced data for section $sectionName...');
        
        // Initialize enhanced analytics service
        final enhancedService = EnhancedStationAnalyticsService();
        
        // Get NPS data for servers in this section
        final npsData = await enhancedService.getNPSDataForSection(
          serverIds: serversInSection,
          monthsToLookBack: 3,
        );
        
        // Get sales data for servers in this section
        final salesData = await enhancedService.getSalesDataForSection(
          serverIds: serversInSection,
          shiftRecords: shiftRecords,
        );
        
        // Get guest count data for servers in this section
        final guestData = await enhancedService.getGuestCountDataForSection(
          serverIds: serversInSection,
          shiftRecords: shiftRecords,
        );
        
        // Calculate performance scores
        final performanceScores = await enhancedService.calculateServerPerformanceScores(
          serverIds: serversInSection,
          npsData: npsData,
          salesData: salesData,
          guestData: guestData,
          shiftRecords: shiftRecords,
        );
        
        // Calculate section-level NPS metrics
        double? threeMonthNPSAverage;
        int totalNPSResponses = 0;
        bool hasNPSData = false;
        
        if (npsData.isNotEmpty) {
          final npsValues = npsData.values.where((nps) => nps.hasActualNpsData).toList();
          if (npsValues.isNotEmpty) {
            threeMonthNPSAverage = npsValues.map((nps) => nps.threeMonthAverage).reduce((a, b) => a + b) / npsValues.length;
            totalNPSResponses = npsValues.fold(0, (sum, nps) => sum + nps.responseCount);
            hasNPSData = true;
          }
        }
        
        // Calculate section-level sales metrics
        double? averageTicketSize;
        bool hasSalesData = false;
        double totalSales = 0.0;
        
        if (salesData.isNotEmpty) {
          totalSales = salesData.values.reduce((a, b) => a + b);
          if (totalRuns > 0) {
            averageTicketSize = totalSales / totalRuns;
            hasSalesData = true;
          }
        }
        
        // Calculate section-level guest metrics
        int totalGuests = guestData.values.fold(0, (sum, guests) => sum + guests);
        double? averageGuestCountPerTable;
        bool hasGuestData = false;
        
        if (totalGuests > 0) {
          averageGuestCountPerTable = totalGuests / totalShifts;
          hasGuestData = true;
        }
        
        // Generate performance insights
        final tempSectionData = SectionPerformanceData(
          sectionName: sectionName,
          stationType: stationType.name,
          totalRuns: totalRuns,
          totalShifts: totalShifts,
          averageRunsPerShift: averageRunsPerShift,
          totalSales: totalSales,
          averageSalesPerRun: averageTicketSize ?? -1.0,
          totalServers: serversInSection.length,
          serverNames: serverNames,
          efficiencyScore: efficiencyScore,
          npsScore: threeMonthNPSAverage ?? -1.0,
          guestCount: totalGuests,
          threeMonthNPSAverage: threeMonthNPSAverage,
          totalNPSResponses: totalNPSResponses,
          averageTicketSize: averageTicketSize,
          totalTablesServed: totalShifts, // Estimate tables as shifts
          averageGuestCountPerTable: averageGuestCountPerTable,
          serverPerformanceScores: performanceScores,
          hasNPSData: hasNPSData,
          hasSalesData: hasSalesData,
          hasGuestData: hasGuestData,
        );
        
        final performanceInsights = enhancedService.generatePerformanceInsights(
          sectionData: tempSectionData,
          npsData: npsData,
          salesData: salesData,
        );
        
        performances.add(SectionPerformanceData(
          sectionName: sectionName,
          stationType: stationType.name,
          totalRuns: totalRuns,
          totalShifts: totalShifts,
          averageRunsPerShift: averageRunsPerShift,
          totalSales: totalSales,
          averageSalesPerRun: averageTicketSize ?? -1.0,
          totalServers: serversInSection.length,
          serverNames: serverNames,
          efficiencyScore: efficiencyScore,
          npsScore: threeMonthNPSAverage ?? -1.0,
          guestCount: totalGuests,
          threeMonthNPSAverage: threeMonthNPSAverage,
          totalNPSResponses: totalNPSResponses,
          averageTicketSize: averageTicketSize,
          totalTablesServed: totalShifts,
          averageGuestCountPerTable: averageGuestCountPerTable,
          serverPerformanceScores: performanceScores,
          performanceInsights: performanceInsights,
          hasNPSData: hasNPSData,
          hasSalesData: hasSalesData,
          hasGuestData: hasGuestData,
        ));
        
        d('[StationAnalytics] Added enhanced section $sectionName: $totalRuns runs, $totalShifts shifts, ${serversInSection.length} servers, NPS: ${threeMonthNPSAverage?.toStringAsFixed(1) ?? 'N/A'}%');
      }
    }
    
    d('[StationAnalytics] Generated ${performances.length} sections with real data');
    return performances;
  }

  double _calculateEfficiencyScore(double avgRunsPerShift) {
    // Simple efficiency calculation based only on runs data
    // Target: 20 runs per shift = 100% efficiency
    double score = (avgRunsPerShift / 20) * 100;
    return score.clamp(0, 100);
  }

  List<String> _generateSectionInsights() {
    if (_sectionPerformances.isEmpty) return [];
    
    final insights = <String>[];
    
    // Find best and worst performing sections
    final sortedSections = List<SectionPerformanceData>.from(_sectionPerformances)
      ..sort((a, b) => b.efficiencyScore.compareTo(a.efficiencyScore));
    
    if (sortedSections.isNotEmpty) {
      final bestSection = sortedSections.first;
      final worstSection = sortedSections.last;
      
      insights.add('${bestSection.sectionName} is your top performer with ${bestSection.efficiencyScore.toStringAsFixed(1)}% efficiency');
      
      if (worstSection.efficiencyScore < bestSection.efficiencyScore * 0.8) {
        insights.add('${worstSection.sectionName} needs attention - efficiency is ${worstSection.efficiencyScore.toStringAsFixed(1)}%');
      }
    }
    
    // Calculate average metrics
    final totalRuns = _sectionPerformances.fold(0, (sum, section) => sum + section.totalRuns);
    final validSalesSections = _sectionPerformances.where((s) => s.totalSales >= 0).toList();
    final totalSales = validSalesSections.fold(0.0, (sum, section) => sum + section.totalSales);
    final avgEfficiency = _sectionPerformances.fold(0.0, (sum, section) => sum + section.efficiencyScore) / _sectionPerformances.length;
    
    if (totalRuns > 0) {
      if (validSalesSections.isNotEmpty) {
        insights.add('Total section performance: ${totalRuns} runs, \$${totalSales.toStringAsFixed(0)} sales');
      } else {
        insights.add('Total section performance: ${totalRuns} runs (sales data not available)');
      }
    }
    
    if (avgEfficiency > 0) {
      insights.add('Average section efficiency: ${avgEfficiency.toStringAsFixed(1)}%');
    }
    
    return insights;
  }

  List<String> _generateSectionRecommendations() {
    if (_sectionPerformances.isEmpty) return [];
    
    final recommendations = <String>[];
    
    // Find underperforming sections
    final underperformingSections = _sectionPerformances.where((section) => section.efficiencyScore < 60).toList();
    
    if (underperformingSections.isNotEmpty) {
      for (final section in underperformingSections) {
        recommendations.add('Consider additional training for ${section.sectionName} - current efficiency: ${section.efficiencyScore.toStringAsFixed(1)}%');
      }
    }
    
    // Find sections with low server count
    final understaffedSections = _sectionPerformances.where((section) => section.totalServers < 2).toList();
    
    if (understaffedSections.isNotEmpty) {
      for (final section in understaffedSections) {
        recommendations.add('${section.sectionName} may need more staff - currently has ${section.totalServers} server(s)');
      }
    }
    
    // Find sections with high sales potential (only if sales data is available)
    final validSalesSections = _sectionPerformances.where((section) => section.averageSalesPerRun >= 0).toList();
    final highSalesSections = validSalesSections.where((section) => section.averageSalesPerRun > 30).toList();
    
    if (highSalesSections.isNotEmpty) {
      recommendations.add('${highSalesSections.first.sectionName} shows strong sales performance - consider replicating strategies');
    } else if (validSalesSections.isEmpty) {
      recommendations.add('Sales data not yet available - run NPS reports to enable sales analytics');
    }
    
    return recommendations;
  }

  Widget _buildRecommendationCard(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(recommendation)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station/Section Analytics'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSectionAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.analytics), text: 'Advanced'),
            Tab(icon: Icon(Icons.history), text: 'Historical'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAdvancedAnalyticsTab(),
                _buildHistoricalAnalyticsTab(),
                _buildTrendsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadSectionAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStationSelector(),
            const SizedBox(height: 24),
            _buildSectionPerformanceCards(),
            const SizedBox(height: 24),
            _buildRealTimeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedAnalyticsTab() {
    if (_selectedStationType == null) {
      return const Center(
        child: Text('Please select a station type to view advanced analytics'),
      );
    }
    
    return AdvancedStationAnalyticsDashboard(
      sectionName: _selectedStationType!,
      stationType: _selectedStationType!,
      allSectionData: _sectionPerformances,
    );
  }

  Widget _buildHistoricalAnalyticsTab() {
    if (_selectedStationType == null) {
      return const Center(
        child: Text('Please select a station type to view historical analytics'),
      );
    }
    
    return HistoricalStationAnalyticsDashboard(
      sectionName: _selectedStationType!,
      stationType: _selectedStationType!,
      allSectionData: _sectionPerformances,
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStationSelector(),
          const SizedBox(height: 24),
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildStationComparisonSection(),
          const SizedBox(height: 24),
          _buildTrendChartsSection(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStationSelector(),
          const SizedBox(height: 24),
          _buildInsightsSection(),
          const SizedBox(height: 24),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildStationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Station Selection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stationTypes.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning, size: 48, color: Colors.amber.shade600),
                    const SizedBox(height: 12),
                    const Text(
                      'No Station Types Configured',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please configure station types in Admin → Manage Stations first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedStationType,
                decoration: const InputDecoration(
                  labelText: 'Select Station Type',
                  border: OutlineInputBorder(),
                ),
                items: _stationTypes.map((stationType) {
                  return DropdownMenuItem<String>(
                    value: stationType.name,
                    child: Text('${stationType.name} (${stationType.sections} sections)'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedStationType) {
                    setState(() {
                      _selectedStationType = newValue;
                    });
                    _loadSectionAnalytics();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPerformanceCards() {
    if (_stationTypes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.add_business,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Station Types Defined',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To use Station/Section Analytics, you need to create station types first:\n\n1. Go to Admin → Manage Stations\n2. Create station types (e.g., "Cocktail" with abbreviation "CKTL")\n3. Go to Admin → Update Roster to assign servers\n4. Run shifts to collect data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_selectedStationType == null) {
      return const SizedBox.shrink();
    }

    // If no section performance data, show a message
    if (_sectionPerformances.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 16),
                    Text(
                      'No Station/Section Data Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No servers are currently assigned to the selected station type. To use this feature:\n\n1. Go to Admin → Manage Stations to create station types\n2. Go to Admin → Update Roster to assign servers to stations and sections\n3. Run some shifts to collect performance data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To start using this feature, ensure your shift records include station and section assignments when servers are scheduled.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Section Performance - $_selectedStationType',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_sectionPerformances.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info, size: 48, color: Colors.blue.shade600),
                    const SizedBox(height: 12),
                    const Text(
                      'No Section Data Available',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Section performance data will appear when shifts with station assignments are completed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _sectionPerformances.map((performance) => 
                  _buildSectionPerformanceCard(performance)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPerformanceCard(SectionPerformanceData performance) {
    final efficiencyColor = _getEfficiencyColor(performance.efficiencyScore);
    final grade = _getEfficiencyGrade(performance.efficiencyScore);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: efficiencyColor.withOpacity(0.1),
        border: Border.all(color: efficiencyColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: efficiencyColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  performance.sectionName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${performance.efficiencyScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: efficiencyColor,
                    ),
                  ),
                  Text(
                    'Grade: $grade',
                    style: TextStyle(
                      fontSize: 12,
                      color: efficiencyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('Runs', '${performance.totalRuns}', Icons.directions_run),
              ),
              Expanded(
                child: _buildMetricItem('Shifts', '${performance.totalShifts}', Icons.schedule),
              ),
              Expanded(
                child: _buildMetricItem('Avg/Shift', '${performance.averageRunsPerShift.toStringAsFixed(1)}', Icons.trending_up),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Sales', 
                  !performance.hasSalesData ? 'Insufficient Data' : '\$${performance.totalSales.toStringAsFixed(0)}', 
                  Icons.attach_money
                ),
              ),
              Expanded(
                child: _buildMetricItem('Servers', '${performance.totalServers}', Icons.people),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Guests', 
                  !performance.hasGuestData ? 'Insufficient Data' : '${performance.guestCount}', 
                  Icons.restaurant
                ),
              ),
            ],
          ),
          // Phase 2: Enhanced metrics row
          if (performance.hasNPSData || performance.hasSalesData || performance.hasGuestData) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'NPS Score', 
                    !performance.hasNPSData ? 'Insufficient Data' : '${performance.threeMonthNPSAverage?.toStringAsFixed(1) ?? 'N/A'}%', 
                    Icons.sentiment_satisfied
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Avg Ticket', 
                    !performance.hasSalesData ? 'Insufficient Data' : '\$${performance.averageTicketSize?.toStringAsFixed(0) ?? 'N/A'}', 
                    Icons.receipt
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Tables', 
                    '${performance.totalTablesServed}', 
                    Icons.table_restaurant
                  ),
                ),
              ],
            ),
          ],
          // Phase 2: Performance insights
          if (performance.performanceInsights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Performance Insights',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...performance.performanceInsights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.blue.shade600)),
                        Expanded(
                          child: Text(
                            insight,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRealTimeSection() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.live_tv, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Real-Time Monitoring',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (appState.shiftActive)
                  RealTimeStationMonitor(
                    currentCounts: appState.currentCounts,
                    stationAssignments: appState.currentStationAssignments,
                  )
                else
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pause_circle_outline, size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No active shift', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationComparisonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Section Performance Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_sectionPerformances.isEmpty)
              Container(
                height: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.amber.shade600),
                    const SizedBox(height: 12),
                    const Text(
                      'Section Performance Comparison',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Charts will appear when you have shift data with section assignments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < _sectionPerformances.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _sectionPerformances[value.toInt()].sectionName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _sectionPerformances.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data.efficiencyScore,
                            color: _getEfficiencyColor(data.efficiencyScore),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyOverviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Station Efficiency Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_stationEfficiencies.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No station data available yet. Station analytics will appear once shifts with station assignments are completed.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _stationEfficiencies.entries.map((entry) => 
                  _buildStationEfficiencyRow(entry.key, entry.value)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationEfficiencyRow(String stationType, double efficiency) {
    final color = _getEfficiencyColor(efficiency);
    final grade = _getEfficiencyGrade(efficiency);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stationType,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${efficiency.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Grade: $grade',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEfficiencyGrade(double efficiency) {
    if (efficiency >= 90) return 'A+';
    if (efficiency >= 80) return 'A';
    if (efficiency >= 70) return 'B';
    if (efficiency >= 60) return 'C';
    if (efficiency >= 50) return 'D';
    return 'F';
  }

  Widget _buildStationEfficiencyCard(StationComparisonData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.stationType,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${data.currentEfficiency.toStringAsFixed(1)}% efficiency',
                  style: TextStyle(color: _getEfficiencyColor(data.currentEfficiency)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    data.trendPercentage > 0 ? Icons.trending_up : 
                    data.trendPercentage < 0 ? Icons.trending_down : Icons.trending_flat,
                    color: data.trendPercentage > 0 ? Colors.green : 
                           data.trendPercentage < 0 ? Colors.red : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.trendPercentage.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: data.trendPercentage > 0 ? Colors.green : 
                             data.trendPercentage < 0 ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${data.totalShifts} shifts',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(DateFormat.yMd().format(_selectedStartDate)),
                subtitle: const Text('Start Date'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedStartDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedStartDate = date);
                    _loadSectionAnalytics();
                  }
                },
              ),
            ),
            Expanded(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(DateFormat.yMd().format(_selectedEndDate)),
                subtitle: const Text('End Date'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedEndDate,
                    firstDate: _selectedStartDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedEndDate = date);
                    _loadSectionAnalytics();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChartsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.purple.shade600),
                  const SizedBox(height: 12),
                  const Text(
                    'Performance Trends',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Historical trend analysis will appear as you accumulate more shift data over time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMatrixSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server-Station Performance Matrix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view, size: 48, color: Colors.teal.shade600),
                  const SizedBox(height: 12),
                  const Text(
                    'Performance Matrix',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Detailed server performance by station will show here when you have sufficient data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Performance Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_sectionPerformances.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI-powered insights will appear here as you collect more section performance data.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _generateSectionInsights().map((insight) => _buildInsightCard(insight)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(insight)),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'AI Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_sectionPerformances.isEmpty)
              const Text('Recommendations will appear when section performance data is available')
            else
              Column(
                children: _generateSectionRecommendations().map((rec) => _buildRecommendationCard(rec)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return Colors.red;
  }

  // Helper to get current station assignments from app state
  Map<String, String> get currentStationAssignments {
    final appState = Provider.of<AppState>(context, listen: false);
    // This would need to be implemented in AppState to provide current station assignments
    // For now, return empty map
    return {};
  }
}