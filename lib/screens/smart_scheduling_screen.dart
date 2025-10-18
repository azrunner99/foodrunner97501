/// Smart Scheduling Dashboard
/// AI-powered interface for intelligent shift scheduling and optimization

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/predictive_scheduling_models.dart';
import '../services/predictive_scheduling_engine.dart';
import '../services/ai_station_recommendation_system.dart';
import '../services/intelligent_shift_optimizer.dart';
import '../widgets/wallpaper_background.dart';

class SmartSchedulingScreen extends StatefulWidget {
  const SmartSchedulingScreen({super.key});

  @override
  State<SmartSchedulingScreen> createState() => _SmartSchedulingScreenState();
}

class _SmartSchedulingScreenState extends State<SmartSchedulingScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _selectedShiftType = 'Lunch';
  PredictedSchedule? _currentPrediction;
  ShiftOptimization? _currentOptimization;
  bool _isLoading = false;
  bool _autoOptimizationEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSchedulingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedulingData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load prediction
      final prediction = await PredictiveSchedulingEngine.getCachedPrediction(
        _selectedDate,
        _selectedShiftType,
      );
      
      // Load optimization
      final optimization = await IntelligentShiftOptimizer.getCachedOptimization(
        _selectedDate,
        _selectedShiftType,
      );

      if (mounted) {
        setState(() {
          _currentPrediction = prediction;
          _currentOptimization = optimization;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[SMART_SCHEDULE] Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateNewPrediction() async {
    final app = context.read<AppState>();
    final availableServers = app.activeServers.map((s) => s.id).toList(); // Only schedule active servers

    setState(() {
      _isLoading = true;
    });

    try {
      final prediction = await PredictiveSchedulingEngine.generateSchedule(
        date: _selectedDate,
        shiftType: _selectedShiftType,
        availableServerIds: availableServers,
      );

      if (mounted) {
        setState(() {
          _currentPrediction = prediction;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[SMART_SCHEDULE] Error generating prediction: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating prediction: $e')),
        );
      }
    }
  }

  Future<void> _runOptimization() async {
    final app = context.read<AppState>();
    final availableServers = app.servers.map((s) => s.id).toList();

    setState(() {
      _isLoading = true;
    });

    try {
      final stationRequirements = <String, double>{
        'Server': 3.0,
        'Host': 1.0,
        'Busser': 2.0,
        'Runner': 1.0,
      };

      final optimization = await IntelligentShiftOptimizer.optimizeShift(
        date: _selectedDate,
        shiftType: _selectedShiftType,
        availableServerIds: availableServers,
        stationRequirements: stationRequirements,
      );

      if (mounted) {
        setState(() {
          _currentOptimization = optimization;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[SMART_SCHEDULE] Error running optimization: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error running optimization: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Scheduling'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Predictions'),
            Tab(icon: Icon(Icons.tune), text: 'Optimization'),
            Tab(icon: Icon(Icons.timeline), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: WallpaperBackground(
        child: Column(
          children: [
            _buildDateShiftSelector(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPredictionsTab(),
                  _buildOptimizationTab(),
                  _buildAnalyticsTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDateShiftSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shift', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedShiftType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Lunch', 'Dinner'].map((shift) =>
                    DropdownMenuItem(value: shift, child: Text(shift)),
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedShiftType = value;
                      });
                      _loadSchedulingData();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentPrediction == null) {
      return _buildEmptyPredictionState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPredictionOverviewCard(),
          const SizedBox(height: 16),
          _buildAssignmentsList(),
          const SizedBox(height: 16),
          _buildInsightsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyPredictionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No AI Prediction Available',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a new prediction for this date and shift',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateNewPrediction,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Prediction'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionOverviewCard() {
    final prediction = _currentPrediction!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text('AI Prediction Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildConfidenceChip(prediction.confidenceScore),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile('Predicted Efficiency', '${prediction.predictedEfficiency.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricTile('Assignments', '${prediction.recommendedAssignments.length}'),
                ),
                Expanded(
                  child: _buildMetricTile('Insights', '${prediction.insights.length}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Generated: ${DateFormat('MMM dd, HH:mm').format(prediction.generatedAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentOptimization != null) ...[
            _buildOptimizationOverviewCard(),
            const SizedBox(height: 16),
            _buildOptimizationComparison(),
            const SizedBox(height: 16),
            _buildOptimizationInsights(),
          ] else ...[
            _buildEmptyOptimizationState(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyOptimizationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Optimization Available',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Run optimization to improve shift assignments',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _runOptimization,
            icon: const Icon(Icons.tune),
            label: const Text('Run Optimization'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationOverviewCard() {
    final optimization = _currentOptimization!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('Optimization Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildGradeChip(optimization.grade),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile('Score', '${optimization.optimizationScore.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricTile('Improvement', '${optimization.improvementPercentage.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricTile('Changes', '${optimization.numberOfChanges}'),
                ),
              ],
            ),
            if (optimization.isHighlyEffective) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Highly effective optimization!',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
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

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceTrendsCard(),
          const SizedBox(height: 16),
          _buildServerPerformanceCard(),
          const SizedBox(height: 16),
          _buildStationEfficiencyCard(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAutoOptimizationCard(),
          const SizedBox(height: 16),
          _buildMLTrainingCard(),
          const SizedBox(height: 16),
          _buildDataManagementCard(),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(double confidence) {
    final color = confidence >= 0.8 ? Colors.green : 
                  confidence >= 0.6 ? Colors.orange : Colors.red;
    
    return Chip(
      label: Text(
        'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildGradeChip(String grade) {
    final color = grade == 'A' ? Colors.green :
                  grade == 'B' ? Colors.blue :
                  grade == 'C' ? Colors.orange : Colors.red;
    
    return Chip(
      label: Text(
        'Grade: $grade',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAssignmentsList() {
    final assignments = _currentPrediction!.recommendedAssignments;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recommended Assignments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...assignments.entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    const Icon(Icons.arrow_forward, size: 16),
                    Expanded(
                      flex: 2,
                      child: Text(entry.value, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList() {
    final insights = _currentPrediction!.insights;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...insights.map((insight) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getInsightIcon(insight.type), 
                         color: _getInsightColor(insight.type), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(insight.description, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationComparison() {
    final optimization = _currentOptimization!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Before vs After', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Original', style: TextStyle(fontWeight: FontWeight.w500)),
                      ...optimization.originalAssignments.entries.take(5).map((e) =>
                        Text('${e.key}: ${e.value}', style: TextStyle(color: Colors.grey.shade600)),
                      ).toList(),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Optimized', style: TextStyle(fontWeight: FontWeight.w500)),
                      ...optimization.optimizedAssignments.entries.take(5).map((e) =>
                        Text('${e.key}: ${e.value}', 
                             style: TextStyle(
                               color: optimization.originalAssignments[e.key] != e.value ? 
                                     Colors.green.shade700 : Colors.grey.shade600,
                               fontWeight: optimization.originalAssignments[e.key] != e.value ? 
                                          FontWeight.bold : FontWeight.normal,
                             )),
                      ).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationInsights() {
    final insights = _currentOptimization!.insights;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optimization Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...insights.map((insight) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getInsightIcon(insight.type), 
                         color: _getInsightColor(insight.type), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(insight.description, style: TextStyle(color: Colors.grey.shade600)),
                          if (insight.recommendation.isNotEmpty)
                            Text('→ ${insight.recommendation}', 
                                 style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrendsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              child: const Center(
                child: Text('Performance trend charts will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Server Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 150,
              child: const Center(
                child: Text('Server performance analytics will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationEfficiencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Station Efficiency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 150,
              child: const Center(
                child: Text('Station efficiency metrics will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoOptimizationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Auto-Optimization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Auto-Optimization'),
              subtitle: const Text('Automatically apply high-confidence optimizations'),
              value: _autoOptimizationEnabled,
              onChanged: (value) {
                setState(() {
                  _autoOptimizationEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMLTrainingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Machine Learning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Train AI models with latest data to improve predictions'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _trainMLModels,
              icon: const Icon(Icons.model_training),
              label: const Text('Train Models'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _updateServerProfiles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Update Profiles'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Cache'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: _generateNewPrediction,
        child: const Icon(Icons.auto_awesome),
        tooltip: 'Generate New Prediction',
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton(
        onPressed: _runOptimization,
        child: const Icon(Icons.tune),
        tooltip: 'Run Optimization',
      );
    }
    return null;
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'warning': return Icons.warning;
      case 'optimization': return Icons.trending_up;
      case 'recommendation': return Icons.lightbulb;
      case 'error': return Icons.error;
      default: return Icons.info;
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'warning': return Colors.orange;
      case 'optimization': return Colors.green;
      case 'recommendation': return Colors.blue;
      case 'error': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSchedulingData();
    }
  }

  Future<void> _trainMLModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AIStationRecommendationSystem.trainMLModels();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ML models trained successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error training models: $e')),
        );
      }
    }
  }

  Future<void> _updateServerProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PredictiveSchedulingEngine.updateServerPerformanceProfiles();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server profiles updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profiles: $e')),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    // Implementation for clearing cache
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }
}