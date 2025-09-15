import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server.dart';
import '../models/nps_feedback.dart';
import '../providers/nps_provider.dart';

/// Widget for displaying analytics and reports
class NPSAnalyticsWidget extends StatefulWidget {
  const NPSAnalyticsWidget({super.key});
  
  @override
  State<NPSAnalyticsWidget> createState() => _NPSAnalyticsWidgetState();
}

class _NPSAnalyticsWidgetState extends State<NPSAnalyticsWidget> {
  NPSServer? _selectedServer;
  String _selectedPeriod = 'all_time'; // all_time, 3_month, 1_month
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  Map<String, dynamic>? _analyticsData;
  bool _isLoadingAnalytics = false;
  
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }
  
  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoadingAnalytics = true;
    });
    
    try {
      final npsProvider = Provider.of<NPSProvider>(context, listen: false);
      
      if (_selectedServer != null) {
        // Server-specific analytics
        DateTime? startDate;
        DateTime? endDate;
        
        if (_selectedPeriod == '3_month') {
          endDate = DateTime.now();
          startDate = DateTime(endDate.year, endDate.month - 3, endDate.day);
        } else if (_selectedPeriod == '1_month') {
          endDate = DateTime.now();
          startDate = DateTime(endDate.year, endDate.month, 1);
        } else if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate;
          endDate = _customEndDate;
        }
        
        _analyticsData = await npsProvider.calculateServerNPS(
          _selectedServer!.id!,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        // Overall analytics
        _analyticsData = await npsProvider.generateAnalyticsReport();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
      }
    }
  }
  
  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );
    
    if (range != null) {
      setState(() {
        _customStartDate = range.start;
        _customEndDate = range.end;
        _selectedPeriod = 'custom';
      });
      _loadAnalytics();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFiltersCard(npsProvider),
              const SizedBox(height: 16),
              if (_isLoadingAnalytics)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_analyticsData != null) ...[
                if (_selectedServer != null)
                  _buildServerAnalyticsCard()
                else
                  _buildOverallAnalyticsCard(),
                const SizedBox(height: 16),
                _buildFeedbackTrendsCard(npsProvider),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFiltersCard(NPSProvider npsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Server Selection
            DropdownButtonFormField<NPSServer?>(
              value: _selectedServer,
              decoration: const InputDecoration(
                labelText: 'Server',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<NPSServer?>(
                  value: null,
                  child: Text('All Servers'),
                ),
                ...npsProvider.servers.map((server) {
                  return DropdownMenuItem<NPSServer?>(
                    value: server,
                    child: Text(server.name),
                  );
                }),
              ],
              onChanged: (server) {
                setState(() {
                  _selectedServer = server;
                });
                _loadAnalytics();
              },
            ),
            const SizedBox(height: 16),
            
            // Period Selection
            if (_selectedServer != null) ...[
              const Text(
                'Time Period',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Time'),
                    selected: _selectedPeriod == 'all_time',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = 'all_time';
                        });
                        _loadAnalytics();
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Last 3 Months'),
                    selected: _selectedPeriod == '3_month',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = '3_month';
                        });
                        _loadAnalytics();
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Current Month'),
                    selected: _selectedPeriod == '1_month',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = '1_month';
                        });
                        _loadAnalytics();
                      }
                    },
                  ),
                  ChoiceChip(
                    label: Text(_selectedPeriod == 'custom' && _customStartDate != null
                        ? 'Custom Range'
                        : 'Custom...'),
                    selected: _selectedPeriod == 'custom',
                    onSelected: (selected) {
                      if (selected) {
                        _selectCustomDateRange();
                      }
                    },
                  ),
                ],
              ),
              if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Custom Range: ${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildServerAnalyticsCard() {
    final npsScore = _analyticsData?['nps_score'] as double?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedServer!.name} - ${_getPeriodDisplayName()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (npsScore != null) ...[
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getNPSColor(npsScore),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              npsScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'NPS',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getNPSRating(npsScore),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getNPSColor(npsScore),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No feedback data available for this period',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverallAnalyticsCard() {
    final totalServers = _analyticsData?['total_servers'] as int? ?? 0;
    final activeServers = _analyticsData?['active_servers'] as int? ?? 0;
    final totalFeedback = _analyticsData?['total_feedback'] as int? ?? 0;
    final overallNPS = _analyticsData?['overall_nps'] as double?;
    final feedbackBreakdown = _analyticsData?['feedback_breakdown'] as Map<String, dynamic>?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Analytics (Last 30 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Summary Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Servers',
                    totalServers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Active Servers',
                    activeServers.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Total Feedback',
                    totalFeedback.toString(),
                    Icons.rate_review,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Overall NPS
            if (overallNPS != null) ...[
              const Text(
                'Overall NPS Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getNPSColor(overallNPS).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getNPSColor(overallNPS)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getNPSColor(overallNPS),
                      ),
                      child: Center(
                        child: Text(
                          overallNPS.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNPSRating(overallNPS),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getNPSColor(overallNPS),
                            ),
                          ),
                          Text(
                            'Based on $totalFeedback feedback entries',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Feedback Breakdown
            if (feedbackBreakdown != null) ...[
              const Text(
                'Feedback Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFeedbackBreakdownCard(
                      'Yes',
                      feedbackBreakdown['yes'] ?? 0,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFeedbackBreakdownCard(
                      'Maybe',
                      feedbackBreakdown['maybe'] ?? 0,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFeedbackBreakdownCard(
                      'No',
                      feedbackBreakdown['no'] ?? 0,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeedbackTrendsCard(NPSProvider npsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (npsProvider.recentFeedback.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                '${npsProvider.recentFeedback.length} feedback entries in the last 30 days',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: npsProvider.recentFeedback.take(5).length,
                  itemBuilder: (context, index) {
                    final feedback = npsProvider.recentFeedback[index];
                    final server = npsProvider.getServerById(feedback.serverId);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getFeedbackColor(feedback.feedbackType),
                        child: Icon(
                          _getFeedbackIcon(feedback.feedbackType),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(server?.name ?? 'Unknown Server'),
                      subtitle: Text('${feedback.feedbackType.displayName} - ${_formatDate(feedback.feedbackDate)}'),
                      trailing: feedback.salesAmount != null
                          ? Text('\$${feedback.salesAmount!.toStringAsFixed(2)}')
                          : null,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeedbackBreakdownCard(String label, int count, Color color) {
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
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getPeriodDisplayName() {
    switch (_selectedPeriod) {
      case 'all_time':
        return 'All Time';
      case '3_month':
        return 'Last 3 Months';
      case '1_month':
        return 'Current Month';
      case 'custom':
        return 'Custom Range';
      default:
        return 'All Time';
    }
  }
  
  Color _getNPSColor(double nps) {
    if (nps >= 70) return Colors.green;
    if (nps >= 50) return Colors.lightGreen;
    if (nps >= 0) return Colors.orange;
    return Colors.red;
  }
  
  String _getNPSRating(double nps) {
    if (nps >= 70) return 'Excellent';
    if (nps >= 50) return 'Good';
    if (nps >= 0) return 'Needs Improvement';
    return 'Poor';
  }
  
  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.yes:
        return Colors.green;
      case FeedbackType.maybe:
        return Colors.orange;
      case FeedbackType.no:
        return Colors.red;
    }
  }
  
  IconData _getFeedbackIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.yes:
        return Icons.thumb_up;
      case FeedbackType.maybe:
        return Icons.thumbs_up_down;
      case FeedbackType.no:
        return Icons.thumb_down;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}