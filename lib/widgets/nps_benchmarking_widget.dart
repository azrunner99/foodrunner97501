import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/nps_benchmarking_service.dart';
import '../providers/nps_provider.dart';
import '../models/nps_score_feedback.dart';

class NPSBenchmarkingWidget extends StatefulWidget {
  const NPSBenchmarkingWidget({super.key});

  @override
  State<NPSBenchmarkingWidget> createState() => _NPSBenchmarkingWidgetState();
}

class _NPSBenchmarkingWidgetState extends State<NPSBenchmarkingWidget> {
  String _selectedBenchmarkType = 'industry';
  String _selectedTimeframe = '30';

  @override
  Widget build(BuildContext context) {
    return Consumer2<NPSBenchmarkingService, NPSProvider>(
      builder: (context, benchmarkService, npsProvider, child) {
        // Generate sample feedback data for demo
        final sampleFeedback = _generateSampleFeedback();
        final analysis = benchmarkService.analyzePerformance(sampleFeedback, npsProvider.servers);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBenchmarkTypeSelector(),
              const SizedBox(height: 20),
              _buildPerformanceOverview(analysis),
              const SizedBox(height: 20),
              _buildBenchmarkComparison(analysis),
              const SizedBox(height: 20),
              _buildTrendAnalysis(sampleFeedback, benchmarkService),
              const SizedBox(height: 20),
              _buildRecommendations(analysis),
              const SizedBox(height: 20),
              _buildTargetProgress(analysis, benchmarkService),
              const SizedBox(height: 20),
              _buildCompetitorComparison(analysis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.assessment,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Benchmarking',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compare your NPS performance against industry standards and competitors',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
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

  Widget _buildBenchmarkTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benchmark Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'industry',
                        label: Text('Industry'),
                        icon: Icon(Icons.business),
                      ),
                      ButtonSegment(
                        value: 'competitor',
                        label: Text('Competitor'),
                        icon: Icon(Icons.groups),
                      ),
                      ButtonSegment(
                        value: 'targets',
                        label: Text('Targets'),
                        icon: Icon(Icons.flag),
                      ),
                    ],
                    selected: {_selectedBenchmarkType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedBenchmarkType = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview(BenchmarkAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Current NPS',
                    analysis.currentNPS.toStringAsFixed(1),
                    _getNPSColor(analysis.currentNPS),
                    Icons.speed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Industry Avg',
                    analysis.industryAverage.toStringAsFixed(1),
                    Colors.blue,
                    Icons.bar_chart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Rating',
                    analysis.performanceRating,
                    _getRatingColor(analysis.performanceRating),
                    Icons.star,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Percentile',
                    '${analysis.percentileRank.toInt()}th',
                    Colors.purple,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkComparison(BenchmarkAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Industry Benchmark Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildBenchmarkChart(analysis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkChart(BenchmarkAnalysis analysis) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 80,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Poor', style: TextStyle(fontSize: 10));
                  case 1:
                    return const Text('Fair', style: TextStyle(fontSize: 10));
                  case 2:
                    return const Text('Industry\nAvg', style: TextStyle(fontSize: 10));
                  case 3:
                    return const Text('Good', style: TextStyle(fontSize: 10));
                  case 4:
                    return const Text('Excellent', style: TextStyle(fontSize: 10));
                  case 5:
                    return const Text('Your\nScore', style: TextStyle(fontSize: 10));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarGroup(0, -10, Colors.red), // Poor
          _buildBarGroup(1, 10, Colors.orange), // Fair
          _buildBarGroup(2, analysis.industryAverage, Colors.blue), // Industry Avg
          _buildBarGroup(3, 30, Colors.lightGreen), // Good
          _buildBarGroup(4, 50, Colors.green), // Excellent
          _buildBarGroup(5, analysis.currentNPS, _getNPSColor(analysis.currentNPS)), // Your Score
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.clamp(0, 80),
          color: color,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(List<NPSScoreFeedback> feedback, NPSBenchmarkingService service) {
    final trendAnalysis = service.getTrendAnalysis(feedback, int.parse(_selectedTimeframe));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Trend Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedTimeframe,
                  items: const [
                    DropdownMenuItem(value: '7', child: Text('7 days')),
                    DropdownMenuItem(value: '30', child: Text('30 days')),
                    DropdownMenuItem(value: '90', child: Text('90 days')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeframe = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTrendCard(
                    'Start Period',
                    trendAnalysis.startNPS.toStringAsFixed(1),
                    Icons.start,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrendCard(
                    'End Period',
                    trendAnalysis.endNPS.toStringAsFixed(1),
                    Icons.stop,
                    _getNPSColor(trendAnalysis.endNPS),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrendCard(
                    'Change',
                    '${trendAnalysis.change >= 0 ? '+' : ''}${trendAnalysis.change.toStringAsFixed(1)}',
                    trendAnalysis.change >= 0 ? Icons.trending_up : Icons.trending_down,
                    trendAnalysis.change >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrendCard(
                    'Trend',
                    trendAnalysis.trend,
                    _getTrendIcon(trendAnalysis.trend),
                    _getTrendColor(trendAnalysis.trend),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BenchmarkAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (analysis.recommendations.isEmpty)
              const Text('No specific recommendations at this time.')
            else
              ...analysis.recommendations.map((rec) => _buildRecommendationCard(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(PerformanceRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getPriorityColor(recommendation.priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getPriorityColor(recommendation.priority).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(recommendation.priority),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.priority,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Impact: +${recommendation.potentialImpact.toStringAsFixed(1)} NPS',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'Timeline: ${recommendation.estimatedTimeframe} days',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetProgress(BenchmarkAnalysis analysis, NPSBenchmarkingService service) {
    final progress = service.getTargetProgress(analysis.currentNPS);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (progress.isEmpty)
              const Text('No active targets set.')
            else
              ...progress.entries.map((entry) => _buildProgressBar(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String targetName, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                targetName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${progress.toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorComparison(BenchmarkAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Competitor Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (analysis.competitorComparison.isEmpty)
              const Text('No competitor data available.')
            else
              ...analysis.competitorComparison.entries.map((entry) => 
                _buildCompetitorItem(entry.key, entry.value)
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitorItem(String competitorName, double difference) {
    final isAhead = difference < 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAhead ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAhead ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAhead ? Icons.trending_up : Icons.trending_down,
            color: isAhead ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              competitorName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${isAhead ? '+' : ''}${difference.abs().toStringAsFixed(1)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAhead ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for colors and icons
  Color _getNPSColor(double nps) {
    if (nps >= 50) return Colors.green;
    if (nps >= 30) return Colors.lightGreen;
    if (nps >= 10) return Colors.orange;
    if (nps >= 0) return Colors.orangeAccent;
    return Colors.red;
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'needs improvement':
        return Colors.orangeAccent;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.lightGreen;
    if (progress >= 40) return Colors.orange;
    return Colors.red;
  }

  // Generate sample feedback for demo
  List<NPSScoreFeedback> _generateSampleFeedback() {
    final List<NPSScoreFeedback> sampleData = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 100; i++) {
      final date = now.subtract(Duration(days: i % 30));
      sampleData.add(NPSScoreFeedback(
        id: i,
        serverId: (i % 3) + 1,
        score: 3 + (i % 8), // Scores from 3-10
        comment: 'Sample feedback $i',
        submissionDate: date,
        createdAt: date,
      ));
    }
    
    return sampleData;
  }
}