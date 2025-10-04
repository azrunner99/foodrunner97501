import 'package:flutter/material.dart';
import '../database/phase6_calculation_audit_service.dart';
import '../utils/log.dart';

class Phase6Runner extends StatefulWidget {
  const Phase6Runner({super.key});

  @override
  State<Phase6Runner> createState() => _Phase6RunnerState();
}

class _Phase6RunnerState extends State<Phase6Runner> {
  bool _isRunning = false;
  Phase6AuditReport? _report;
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Phase 6: Widget Calculation Audit'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Health Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _report?.success == true 
                          ? Icons.check_circle 
                          : _report?.success == false 
                              ? Icons.error 
                              : Icons.analytics,
                      size: 64,
                      color: _report?.success == true 
                          ? Colors.green 
                          : _report?.success == false 
                              ? Colors.red 
                              : Colors.indigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Widget Health Analysis',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _report?.overallHealth ?? 'Ready to analyze NPS widget calculations',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_report != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Health Score: ${_report!.healthScore}/100',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getHealthScoreColor(_report!.healthScore),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Metrics Overview
            if (_report != null) ...[
              _buildMetricsOverview(),
              const SizedBox(height: 16),
            ],
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _runAudit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: _isRunning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Analyzing...'),
                        ],
                      )
                    : const Text('Run Widget Calculation Audit'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detailed Results
            if (_report != null) _buildDetailedResults(),
            
            const SizedBox(height: 16),
            
            // Live Logs
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.analytics, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Audit Log',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (_logs.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _logs.clear();
                                });
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'Click "Run Widget Calculation Audit" to analyze NPS calculations',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    log,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
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
  
  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildMetricsOverview() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildMetricCard(
          'NPS Entries',
          _report!.totalNPSEntries.toString(),
          Icons.rate_review,
          Colors.blue,
        ),
        _buildMetricCard(
          'Server Coverage',
          '${_report!.uniqueServersWithNPS}/${_report!.resolvedServerIds + _report!.unresolvedServerIds}',
          Icons.people,
          Colors.green,
        ),
        _buildMetricCard(
          'NPS Score',
          _report!.calculatedNPSScore.toString(),
          Icons.trending_up,
          _report!.calculatedNPSScore >= 0 ? Colors.green : Colors.red,
        ),
        _buildMetricCard(
          'Issues',
          '${_report!.criticalIssues}/${_report!.warnings.length}',
          Icons.warning,
          _report!.criticalIssues > 0 ? Colors.red : Colors.orange,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
  
  Widget _buildDetailedResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, size: 20),
                SizedBox(width: 8),
                Text(
                  'Detailed Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Total Responses', '${_report!.totalResponses}'),
            _buildDetailRow('Date Range', _report!.dataDateRange),
            _buildDetailRow('Current Month', '${_report!.currentMonthEntries} entries'),
            _buildDetailRow('Avg Rating', _report!.averageRating.toStringAsFixed(1)),
            _buildDetailRow('Promoters/Detractors', '${_report!.totalPromoters}/${_report!.totalDetractors}'),
            if (_report!.unresolvedServerIds > 0)
              _buildDetailRow('Unresolved Servers', '${_report!.unresolvedServerIds}'),
            if (_report!.criticalIssues > 0) ...[
              const SizedBox(height: 8),
              const Text(
                'Critical Issues:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              ..._report!.errors.map((error) => Text(
                '• $error',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )),
            ],
            if (_report!.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Warnings:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              ..._report!.warnings.map((warning) => Text(
                '• $warning',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _runAudit() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });
    
    _addLog('🔍 Starting Widget Calculation Audit...');
    _addLog('Analyzing NPS data integrity and calculations...');
    
    try {
      final auditService = Phase6CalculationAuditService();
      final report = await auditService.auditCalculations();
      
      setState(() {
        _report = report;
        _isRunning = false;
      });
      
      _addLog('📊 Audit Results Summary:');
      _addLog('   • Total NPS Entries: ${report.totalNPSEntries}');
      _addLog('   • Servers with NPS Data: ${report.uniqueServersWithNPS}');
      _addLog('   • Date Range: ${report.dataDateRange}');
      _addLog('   • Overall NPS Score: ${report.calculatedNPSScore}');
      _addLog('   • Average Rating: ${report.averageRating.toStringAsFixed(1)}');
      
      if (report.serverCalculationSamples.isNotEmpty) {
        _addLog('');
        _addLog('📈 Server-Level Calculations:');
        for (final sample in report.serverCalculationSamples.take(5)) {
          _addLog('   • $sample');
        }
      }
      
      if (report.criticalIssues > 0) {
        _addLog('');
        _addLog('❌ Critical Issues Found:');
        for (final error in report.errors) {
          _addLog('   • $error');
        }
      }
      
      if (report.warnings.isNotEmpty) {
        _addLog('');
        _addLog('⚠️ Warnings:');
        for (final warning in report.warnings) {
          _addLog('   • $warning');
        }
      }
      
      _addLog('');
      _addLog('✅ Audit completed - Health Score: ${report.healthScore}/100');
      
    } catch (e) {
      _addLog('❌ Audit failed: $e');
      setState(() {
        _isRunning = false;
      });
    }
  }
  
  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 23);
      _logs.add('[$timestamp] $message');
    });
  }
}