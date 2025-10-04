import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/phase4_validation_service.dart';
import '../utils/log.dart';

/// Phase 4 Runner: Server ID System Testing & Validation
/// 
/// This screen provides a comprehensive testing interface for the entire
/// server ID standardization system implemented in Phases 1-3.
class Phase4Runner extends StatefulWidget {
  const Phase4Runner({super.key});

  @override
  State<Phase4Runner> createState() => _Phase4RunnerState();
}

class _Phase4RunnerState extends State<Phase4Runner> {
  ValidationReport? _currentReport;
  bool _isRunning = false;
  final List<String> _log = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _log.add('${DateTime.now().toIso8601String()}: $message');
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runValidation() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _currentReport = null;
      _log.clear();
    });

    _addLog('🚀 Starting Phase 4: Comprehensive System Validation');
    _addLog('Testing all aspects of server ID standardization system...');

    try {
      final report = await Phase4ValidationService.runComprehensiveValidation();
      
      setState(() {
        _currentReport = report;
        _isRunning = false;
      });

      _addLog('✅ Validation completed in ${report.totalExecutionTime}ms');
      _addLog('🏥 System Health Score: ${report.healthScore}/100');
      
      if (report.healthScore >= 90) {
        _addLog('🎉 Excellent! System is performing optimally');
      } else if (report.healthScore >= 70) {
        _addLog('⚠️ Good, but some areas need attention');
      } else {
        _addLog('❌ System needs significant improvements');
      }

    } catch (e) {
      _addLog('💥 Validation failed with error: $e');
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _copyReportToClipboard() {
    if (_currentReport != null) {
      Clipboard.setData(ClipboardData(text: _currentReport!.summary));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report copied to clipboard!')),
      );
    }
  }

  Widget _buildHealthScoreCard() {
    if (_currentReport == null) return const SizedBox.shrink();

    final score = _currentReport!.healthScore;
    final color = score >= 90 
        ? Colors.green 
        : score >= 70 
            ? Colors.orange 
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.health_and_safety, color: color, size: 32),
                const SizedBox(width: 12),
                Text(
                  'System Health Score',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$score/100',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 12),
            Text(
              'Execution Time: ${_currentReport!.totalExecutionTime}ms',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    if (_currentReport == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildMetricCard(
          '📊 Database',
          '${_currentReport!.appServerCount} servers\\n${_currentReport!.npsReportCount} NPS reports',
          Colors.blue,
        ),
        _buildMetricCard(
          '⚡ Performance',
          '${_currentReport!.averageResolutionTime.toStringAsFixed(2)}ms\\navg resolution',
          _currentReport!.averageResolutionTime <= 10 ? Colors.green : Colors.orange,
        ),
        _buildMetricCard(
          '🔄 Consistency',
          '${_currentReport!.consistentServerIds} consistent\\n${_currentReport!.missingInApp + _currentReport!.missingInNps} issues',
          _currentReport!.missingInApp + _currentReport!.missingInNps == 0 ? Colors.green : Colors.orange,
        ),
        _buildMetricCard(
          '🔧 Integration',
          _currentReport!.widgetIntegrationWorking ? 'Working ✅' : 'Issues ❌',
          _currentReport!.widgetIntegrationWorking ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle.replaceAll('\\n', '\n'),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    if (_currentReport == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (_currentReport!.successes.isNotEmpty)
          _buildResultSection(
            '✅ Successes (${_currentReport!.successes.length})',
            _currentReport!.successes,
            Colors.green,
          ),
        
        if (_currentReport!.warnings.isNotEmpty)
          _buildResultSection(
            '⚠️ Warnings (${_currentReport!.warnings.length})',
            _currentReport!.warnings,
            Colors.orange,
          ),
        
        if (_currentReport!.errors.isNotEmpty)
          _buildResultSection(
            '❌ Errors (${_currentReport!.errors.length})',
            _currentReport!.errors,
            Colors.red,
          ),
      ],
    );
  }

  Widget _buildResultSection(String title, List<String> items, Color color) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.info_outline, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        children: items.take(10).map((item) => ListTile(
          dense: true,
          title: Text(item, style: const TextStyle(fontSize: 12)),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 4: System Validation'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_currentReport != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyReportToClipboard,
              tooltip: 'Copy Report to Clipboard',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.indigo, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Server ID System Validation',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Comprehensive testing of Phases 1-3 implementation',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Run Validation Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runValidation,
                icon: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Running Validation...' : 'Run Complete Validation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Health Score Card
            _buildHealthScoreCard(),

            const SizedBox(height: 16),

            // Metrics Grid
            _buildMetricsGrid(),

            const SizedBox(height: 16),

            // Results Summary
            _buildResultsSummary(),

            const SizedBox(height: 16),

            // Live Log
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Validation Log',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    child: _log.isEmpty
                        ? const Center(
                            child: Text(
                              'Click "Run Complete Validation" to start testing',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _logScrollController,
                            itemCount: _log.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  _log[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
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
}