import 'package:flutter/material.dart';
import '../models/performance_models.dart';
import '../services/performance_rollout_service.dart';
import '../services/performance_flags.dart';

/// Performance rollout management dashboard screen
/// Phase 7: Rollout & Reconciliation
class PerformanceRolloutDashboard extends StatefulWidget {
  const PerformanceRolloutDashboard({Key? key}) : super(key: key);

  @override
  State<PerformanceRolloutDashboard> createState() => _PerformanceRolloutDashboardState();
}

class _PerformanceRolloutDashboardState extends State<PerformanceRolloutDashboard> {
  final PerformanceRolloutService _rolloutService = PerformanceRolloutService();
  List<PerformanceRollout> _rollouts = [];
  List<PerformanceValidation> _validations = [];
  List<PerformanceReconciliation> _reconciliations = [];
  PerformanceRolloutConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!PerformanceFlags.rollout) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final rollouts = _rolloutService.getRolloutHistory();
      final validations = _rolloutService.getValidationHistory();
      final reconciliations = _rolloutService.getReconciliationHistory();
      final config = _rolloutService.getCurrentConfig();
      
      setState(() {
        _rollouts = rollouts;
        _validations = validations;
        _reconciliations = reconciliations;
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PerformanceFlags.rollout) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Performance Rollout'),
          backgroundColor: Colors.purple.shade700,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Performance Rollout Not Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Phase 7: Rollout & Reconciliation is not enabled',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Rollout'),
        backgroundColor: Colors.purple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showStartRolloutDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentStatusCard(),
                    const SizedBox(height: 16),
                    _buildRolloutHistoryCard(),
                    const SizedBox(height: 16),
                    _buildValidationHistoryCard(),
                    const SizedBox(height: 16),
                    _buildReconciliationHistoryCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final activeRollout = _rolloutService.getActiveRollout();
    final enabledPhases = PerformanceFlags.enabledPhases;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Current Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeRollout != null) ...[
              _buildActiveRolloutInfo(activeRollout),
              const SizedBox(height: 16),
            ],
            _buildEnabledPhasesInfo(enabledPhases),
            const SizedBox(height: 16),
            _buildConfigurationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRolloutInfo(PerformanceRollout rollout) {
    Color statusColor;
    IconData statusIcon;
    
    switch (rollout.status) {
      case RolloutStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case RolloutStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.play_arrow;
        break;
      case RolloutStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RolloutStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case RolloutStatus.rolledBack:
        statusColor = Colors.red.shade900;
        statusIcon = Icons.undo;
        break;
      case RolloutStatus.paused:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.pause;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Active Rollout: ${rollout.version}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Status: ${rollout.status.name}'),
          Text('Phases: ${rollout.phases.join(', ')}'),
          Text('Started: ${_formatDateTime(rollout.startedAt)}'),
          if (rollout.duration != null)
            Text('Duration: ${_formatDuration(rollout.duration!)}'),
          const SizedBox(height: 8),
          Row(
            children: [
              if (rollout.status == RolloutStatus.inProgress) ...[
                ElevatedButton(
                  onPressed: () => _completeRollout(rollout.id),
                  child: const Text('Complete'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _rollbackRollout(rollout.id),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Rollback'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnabledPhasesInfo(List<int> enabledPhases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enabled Phases',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: enabledPhases.map((phase) => _buildPhaseChip(phase)).toList(),
        ),
      ],
    );
  }

  Widget _buildPhaseChip(int phase) {
    final phaseNames = {
      1: 'Data Hygiene',
      2: 'Baseline Reform',
      3: 'Differentiation',
      4: 'Temporal Analysis',
      5: 'Adaptive Weights',
      6: 'Monitoring',
      7: 'Rollout',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        'Phase $phase: ${phaseNames[phase] ?? 'Unknown'}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildConfigurationInfo() {
    if (_config == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuration',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text('Version: ${_config!.version}'),
        Text('Created: ${_formatDateTime(_config!.createdAt)}'),
        Text('Created By: ${_config!.createdBy}'),
        Text('Active: ${_config!.isActive ? 'Yes' : 'No'}'),
      ],
    );
  }

  Widget _buildRolloutHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Rollout History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_rollouts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _rollouts.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rollouts.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'No Rollouts Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_rollouts.take(5).map((rollout) => _buildRolloutItem(rollout))),
            if (_rollouts.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full rollout history
                  },
                  child: Text('View All ${_rollouts.length} Rollouts'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolloutItem(PerformanceRollout rollout) {
    Color statusColor;
    IconData statusIcon;
    
    switch (rollout.status) {
      case RolloutStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case RolloutStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.play_arrow;
        break;
      case RolloutStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RolloutStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case RolloutStatus.rolledBack:
        statusColor = Colors.red.shade900;
        statusIcon = Icons.undo;
        break;
      case RolloutStatus.paused:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.pause;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rollout.version} - ${rollout.status.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phases: ${rollout.phases.join(', ')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Started: ${_formatDateTime(rollout.startedAt)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (rollout.duration != null)
                  Text(
                    'Duration: ${_formatDuration(rollout.duration!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Validation History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_validations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _validations.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_validations.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'No Validations Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_validations.take(5).map((validation) => _buildValidationItem(validation))),
            if (_validations.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full validation history
                  },
                  child: Text('View All ${_validations.length} Validations'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationItem(PerformanceValidation validation) {
    Color statusColor;
    IconData statusIcon;
    
    switch (validation.status) {
      case ValidationStatus.passed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ValidationStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case ValidationStatus.warning:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case ValidationStatus.skipped:
        statusColor = Colors.grey;
        statusIcon = Icons.skip_next;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${validation.validationType} - ${validation.status.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Validated: ${_formatDateTime(validation.validatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (validation.hasWarnings)
                  Text(
                    'Warnings: ${validation.warnings.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade600,
                    ),
                  ),
                if (validation.hasErrors)
                  Text(
                    'Errors: ${validation.errors.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Reconciliation History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_reconciliations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _reconciliations.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_reconciliations.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.sync_problem, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'No Reconciliations Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_reconciliations.take(5).map((reconciliation) => _buildReconciliationItem(reconciliation))),
            if (_reconciliations.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full reconciliation history
                  },
                  child: Text('View All ${_reconciliations.length} Reconciliations'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationItem(PerformanceReconciliation reconciliation) {
    final statusColor = reconciliation.isSuccessful ? Colors.green : Colors.red;
    final statusIcon = reconciliation.isSuccessful ? Icons.check_circle : Icons.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reconciliation.type.name} - ${reconciliation.isSuccessful ? 'Success' : 'Failed'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reconciliation.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Started: ${_formatDateTime(reconciliation.startedAt)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (reconciliation.duration != null)
                  Text(
                    'Duration: ${_formatDuration(reconciliation.duration!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStartRolloutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Rollout'),
        content: const Text('This will start a new performance rollout. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewRollout();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _startNewRollout() async {
    try {
      final rollout = await _rolloutService.startRollout(
        version: '1.0.0',
        phases: [1, 2, 3, 4, 5, 6, 7],
        initiatedBy: 'user',
      );
      
      _loadDashboardData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rollout ${rollout.id} started successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start rollout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeRollout(String rolloutId) async {
    try {
      await _rolloutService.completeRollout(rolloutId);
      _loadDashboardData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rollout completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete rollout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rollbackRollout(String rolloutId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rollback Rollout'),
        content: const Text('This will rollback the current rollout. This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performRollback(rolloutId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rollback'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRollback(String rolloutId) async {
    try {
      await _rolloutService.rollbackRollout(rolloutId, 'User initiated rollback');
      _loadDashboardData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rollout rolled back successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rollback rollout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

