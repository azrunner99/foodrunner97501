import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../widgets/wallpaper_background.dart';
import '../storage.dart';

/// Comprehensive Server NPS Management Screen
/// Provides dedicated tools for recording, analyzing, and managing server NPS data
class ServerNPSScreen extends StatefulWidget {
  const ServerNPSScreen({super.key});

  @override
  State<ServerNPSScreen> createState() => _ServerNPSScreenState();
}

class _ServerNPSScreenState extends State<ServerNPSScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = '';
  Map<String, NPSData> _npsData = {};
  bool _isLoading = false;
  
  // Controllers for quick entry
  final Map<String, TextEditingController> _quickScoreControllers = {};
  final Map<String, TextEditingController> _quickResponseControllers = {};
  final Map<String, TextEditingController> _quickCommentControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedMonth = _getCurrentMonthKey();
    _loadNPSData();
    _initializeControllers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    final app = context.read<AppState>();
    for (final server in app.servers) {
      _quickScoreControllers[server.id] = TextEditingController();
      _quickResponseControllers[server.id] = TextEditingController();
      _quickCommentControllers[server.id] = TextEditingController();
    }
  }

  void _disposeControllers() {
    for (final controller in _quickScoreControllers.values) {
      controller.dispose();
    }
    for (final controller in _quickResponseControllers.values) {
      controller.dispose();
    }
    for (final controller in _quickCommentControllers.values) {
      controller.dispose();
    }
  }

  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadNPSData() async {
    setState(() => _isLoading = true);
    try {
      final enhancedData = await Storage.getEnhancedMonthlyBusinessData(_selectedMonth);
      if (enhancedData != null && enhancedData['serverNPSData'] != null) {
        final serverNPSData = enhancedData['serverNPSData'] as Map;
        _npsData.clear();
        for (final entry in serverNPSData.entries) {
          try {
            _npsData[entry.key] = NPSData.fromMap(entry.value as Map<String, dynamic>);
          } catch (e) {
            // Skip invalid entries
          }
        }
        _populateControllers();
      } else {
        _npsData.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading NPS data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    for (final entry in _npsData.entries) {
      final serverId = entry.key;
      final npsData = entry.value;
      
      _quickScoreControllers[serverId]?.text = npsData.monthlyScore.toStringAsFixed(1);
      _quickResponseControllers[serverId]?.text = npsData.responseCount.toString();
      _quickCommentControllers[serverId]?.text = 
          npsData.guestComments.isNotEmpty ? npsData.guestComments.first : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server NPS Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade600.withOpacity(0.8),
                Colors.orange.shade400.withOpacity(0.6),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Overview'),
            Tab(icon: Icon(Icons.edit), text: 'Quick Entry'),
            Tab(icon: Icon(Icons.trending_up), text: 'Analytics'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: WallpaperBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildQuickEntryTab(),
              _buildAnalyticsTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showMonthSelector,
      icon: const Icon(Icons.calendar_month),
      label: Text(_getMonthDisplayName(_selectedMonth)),
      backgroundColor: Colors.orange.shade600,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildOverviewTab() {
    final app = context.watch<AppState>();
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final servers = app.servers;
    final serversWithNPS = servers.where((s) => _npsData.containsKey(s.id)).toList();
    final avgNPS = _calculateAverageNPS();
    final totalResponses = _calculateTotalResponses();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Summary Card
          _buildSummaryCard(avgNPS, totalResponses, serversWithNPS.length, servers.length),
          
          const SizedBox(height: 16),
          
          // Server NPS Overview
          Text(
            'Server NPS Scores',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          
          ...servers.map((server) => _buildServerNPSCard(server)),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double avgNPS, int totalResponses, int serversWithData, int totalServers) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  'NPS Summary - ${_getMonthDisplayName(_selectedMonth)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Restaurant NPS',
                    '${avgNPS.toStringAsFixed(1)}%',
                    Icons.star,
                    _getNPSColor(avgNPS),
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Responses',
                    totalResponses.toString(),
                    Icons.comment,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Servers with Data',
                    '$serversWithData/$totalServers',
                    Icons.person_add,
                    serversWithData == totalServers ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'NPS Category',
                    _getNPSCategoryName(avgNPS),
                    Icons.category,
                    _getNPSColor(avgNPS),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServerNPSCard(Server server) {
    final npsData = _npsData[server.id];
    final hasData = npsData != null;
    final app = context.watch<AppState>();
    final profile = app.profiles[server.id];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: hasData 
                ? [Colors.white, _getNPSColor(npsData.monthlyScore).withOpacity(0.1)]
                : [Colors.grey.shade50, Colors.grey.shade100],
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade600,
            backgroundImage: profile?.avatarPath != null 
                ? AssetImage(profile!.avatarPath!) 
                : null,
            child: profile?.avatarPath == null 
                ? Text(
                    server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(
            server.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${npsData.monthlyScore.toStringAsFixed(1)}% • ${npsData.responseCount} responses'),
                    if (npsData.guestComments.isNotEmpty)
                      Text(
                        'Latest: "${npsData.guestComments.first}"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                )
              : const Text('No data for this month'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasData) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getNPSColor(npsData.monthlyScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getNPSCategoryName(npsData.monthlyScore),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${npsData.monthlyScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getNPSColor(npsData.monthlyScore),
                  ),
                ),
              ] else ...[
                Icon(Icons.add_circle_outline, color: Colors.grey.shade400),
                Text(
                  'Add Data',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _showServerNPSDetail(server),
        ),
      ),
    );
  }

  Widget _buildQuickEntryTab() {
    final app = context.watch<AppState>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick NPS Entry - ${_getMonthDisplayName(_selectedMonth)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quickly add or update NPS scores for all servers',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          
          ...app.servers.map((server) => _buildQuickEntryCard(server)),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAllQuickEntries,
              icon: const Icon(Icons.save),
              label: const Text('Save All Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildQuickEntryCard(Server server) {
    final app = context.watch<AppState>();
    final profile = app.profiles[server.id];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade600,
                  backgroundImage: profile?.avatarPath != null 
                      ? AssetImage(profile!.avatarPath!) 
                      : null,
                  child: profile?.avatarPath == null 
                      ? Text(
                          server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (server.stationType != null)
                        Text(
                          server.stationType!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quickScoreControllers[server.id],
                    decoration: const InputDecoration(
                      labelText: 'NPS Score',
                      hintText: '0-100',
                      suffix: Text('%'),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quickResponseControllers[server.id],
                    decoration: const InputDecoration(
                      labelText: 'Responses',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quickCommentControllers[server.id],
              decoration: const InputDecoration(
                labelText: 'Latest Guest Comment',
                hintText: 'Enter guest feedback...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Text(
        'Analytics Coming Soon',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Text(
        'History Coming Soon',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  // Helper methods
  double _calculateAverageNPS() {
    if (_npsData.isEmpty) return 0.0;
    final scores = _npsData.values.map((nps) => nps.monthlyScore).toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  int _calculateTotalResponses() {
    return _npsData.values.fold(0, (sum, nps) => sum + nps.responseCount);
  }

  Color _getNPSColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    if (score >= 50) return Colors.deepOrange;
    return Colors.red;
  }

  String _getNPSCategoryName(double score) {
    if (score >= 80) return 'Exceptional';
    if (score >= 70) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  String _getMonthDisplayName(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    
    if (year == null || month == null) return monthKey;
    
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[month - 1]} $year';
  }

  void _showMonthSelector() {
    // Implementation for month selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: const Text('Month selector will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showServerNPSDetail(Server server) {
    // Implementation for detailed server NPS view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${server.name} - NPS Details'),
        content: const Text('Detailed NPS view will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllQuickEntries() async {
    setState(() => _isLoading = true);
    
    try {
      final app = context.read<AppState>();
      final updatedNPSData = <String, Map<String, dynamic>>{};
      
      for (final server in app.servers) {
        final scoreText = _quickScoreControllers[server.id]?.text ?? '';
        final responsesText = _quickResponseControllers[server.id]?.text ?? '';
        final commentText = _quickCommentControllers[server.id]?.text ?? '';
        
        if (scoreText.isNotEmpty) {
          final score = double.tryParse(scoreText) ?? 0.0;
          final responses = int.tryParse(responsesText) ?? 1;
          final comments = commentText.isNotEmpty ? [commentText] : <String>[];
          
          final npsData = NPSData(
            serverId: server.id,
            month: DateTime.now(),
            monthlyScore: score,
            threeMonthAverage: score, // Will be calculated properly later
            responseCount: responses,
            categoryBreakdown: {
              'service': score,
              'food': score,
              'atmosphere': score,
            },
            guestComments: comments,
            lastUpdated: DateTime.now(),
          );
          
          updatedNPSData[server.id] = npsData.toMap();
        }
      }
      
      // Save to storage
      final enhancedData = await Storage.getEnhancedMonthlyBusinessData(_selectedMonth) ?? {};
      enhancedData['serverNPSData'] = updatedNPSData;
      await Storage.saveEnhancedMonthlyBusinessData(_selectedMonth, enhancedData);
      
      // Reload data
      await _loadNPSData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NPS data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving NPS data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}