import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nps_benchmarking_widget.dart';
import '../widgets/nps_target_management_widget.dart';
import '../services/nps_benchmarking_service.dart';

class NPSBenchmarkingScreen extends StatefulWidget {
  const NPSBenchmarkingScreen({super.key});

  @override
  State<NPSBenchmarkingScreen> createState() => _NPSBenchmarkingScreenState();
}

class _NPSBenchmarkingScreenState extends State<NPSBenchmarkingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Benchmarking'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.assessment),
              text: 'Benchmarking',
            ),
            Tab(
              icon: Icon(Icons.flag),
              text: 'Targets',
            ),
            Tab(
              icon: Icon(Icons.info),
              text: 'Industry Data',
            ),
          ],
        ),
      ),
      body: Consumer<NPSBenchmarkingService>(
        builder: (context, benchmarkService, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBenchmarkingTab(),
              _buildTargetsTab(),
              _buildIndustryDataTab(benchmarkService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBenchmarkingTab() {
    return const SingleChildScrollView(
      child: NPSBenchmarkingWidget(),
    );
  }

  Widget _buildTargetsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: NPSTargetManagementWidget(),
    );
  }

  Widget _buildIndustryDataTab(NPSBenchmarkingService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndustryBenchmarksCard(service),
          const SizedBox(height: 20),
          _buildCompetitorDataCard(service),
          const SizedBox(height: 20),
          _buildBenchmarkingGuideCard(),
        ],
      ),
    );
  }

  Widget _buildIndustryBenchmarksCard(NPSBenchmarkingService service) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Industry Benchmarks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (service.industryBenchmarks.isEmpty)
              const Text('No industry benchmark data available')
            else
              ...service.industryBenchmarks
                  .map((benchmark) => _buildBenchmarkItem(benchmark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkItem(IndustryBenchmark benchmark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${benchmark.industry} - ${benchmark.category}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Avg: ${benchmark.averageNPS.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBenchmarkMetric(
                'Excellent',
                benchmark.excellentNPS.toStringAsFixed(1),
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildBenchmarkMetric(
                'Good',
                benchmark.goodNPS.toStringAsFixed(1),
                Colors.lightGreen,
              ),
              const SizedBox(width: 12),
              _buildBenchmarkMetric(
                'Fair',
                benchmark.fairNPS.toStringAsFixed(1),
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildBenchmarkMetric(
                'Poor',
                benchmark.poorNPS.toStringAsFixed(1),
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.source, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  benchmark.source,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                'Updated: ${benchmark.lastUpdated.day}/${benchmark.lastUpdated.month}/${benchmark.lastUpdated.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitorDataCard(NPSBenchmarkingService service) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Competitor Benchmarks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (service.competitiveBenchmarks.isEmpty)
              const Text('No competitor benchmark data available')
            else
              ...service.competitiveBenchmarks
                  .map((competitor) => _buildCompetitorItem(competitor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitorItem(CompetitiveBenchmark competitor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  competitor.competitorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNPSColor(competitor.npsScore),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  competitor.npsScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (competitor.isVerified)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                competitor.category,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${competitor.responseCount} responses',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                competitor.timeframe,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.source, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Source: ${competitor.source}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkingGuideCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Understanding NPS Benchmarks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideSection(
              'NPS Score Ranges',
              [
                '90-100: World Class Performance',
                '70-89: Excellent',
                '50-69: Good',
                '30-49: Above Average',
                '10-29: Average',
                '0-9: Below Average',
                'Below 0: Poor',
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideSection(
              'Restaurant Industry Insights',
              [
                'Casual dining average: 15-25 NPS',
                'Fast casual average: 25-35 NPS',
                'Fine dining average: 35-45 NPS',
                'QSR (Quick Service) average: 20-30 NPS',
                'Top performers typically exceed 50 NPS',
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideSection(
              'Improvement Strategies',
              [
                'Focus on service quality and consistency',
                'Address detractor feedback promptly',
                'Train staff on customer experience',
                'Monitor and respond to feedback trends',
                'Set realistic, achievable targets',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Color _getNPSColor(double nps) {
    if (nps >= 50) return Colors.green;
    if (nps >= 30) return Colors.lightGreen;
    if (nps >= 10) return Colors.orange;
    if (nps >= 0) return Colors.orangeAccent;
    return Colors.red;
  }
}
