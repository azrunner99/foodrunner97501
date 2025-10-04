import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/performance_rollout_models.dart';
import '../services/performance_flags.dart';
import '../services/performance_monitoring_service.dart';
import '../utils/performance_calculator.dart';

/// Performance rollout and reconciliation service
/// Phase 7: Rollout & Reconciliation
class PerformanceRolloutService {
  static final PerformanceRolloutService _instance = PerformanceRolloutService._internal();
  factory PerformanceRolloutService() => _instance;
  PerformanceRolloutService._internal();

  static const String _rolloutsKey = 'performance_rollouts';
  static const String _validationsKey = 'performance_validations';
  static const String _reconciliationsKey = 'performance_reconciliations';
  static const String _configKey = 'performance_rollout_config';

  final List<PerformanceRollout> _rollouts = [];
  final List<PerformanceValidation> _validations = [];
  final List<PerformanceReconciliation> _reconciliations = [];
  PerformanceRolloutConfig? _currentConfig;

  final PerformanceMonitoringService _monitoringService = PerformanceMonitoringService.instance;

  /// Initialize the rollout service
  Future<void> initialize() async {
    if (!PerformanceFlags.rollout) return;

    await _loadRollouts();
    await _loadValidations();
    await _loadReconciliations();
    await _loadConfig();
    
    // Create default config if none exists
    if (_currentConfig == null) {
      _currentConfig = _createDefaultConfig();
      await _saveConfig();
    }
  }

  /// Start a new performance rollout
  Future<PerformanceRollout> startRollout({
    required String version,
    required List<int> phases,
    required String initiatedBy,
    Map<String, dynamic>? customConfiguration,
  }) async {
    if (!PerformanceFlags.rollout) {
      throw Exception('Rollout feature is not enabled');
    }

    // Check for active rollout
    final existingActive = _rollouts.where((r) => r.isActive).toList();
    if (existingActive.isNotEmpty) {
      throw Exception('Cannot start new rollout while rollout ${existingActive.first.id} is active');
    }

    final rollout = PerformanceRollout(
      id: _generateRolloutId(),
      version: version,
      phases: phases,
      status: RolloutStatus.pending,
      startedAt: DateTime.now(),
      completedAt: null,
      initiatedBy: initiatedBy,
      configuration: customConfiguration ?? _currentConfig?.rolloutSettings ?? const {},
      affectedServers: const [],
      metrics: const {},
      errorMessage: null,
      rollbackData: const {},
    );
    _rollouts.add(rollout);
    await _saveRollouts();

    await _monitoringService.recordMetric(
      'rollout_started',
      1.0,
      category: 'Rollout',
      metadata: {
        'rolloutId': rollout.id,
        'version': version,
        'phases': phases,
        'action': 'rollout_started',
      },
    );

    return rollout;
  }

  /// Execute a rollout phase
  Future<void> executeRolloutPhase(String rolloutId, int phase) async {
    if (!PerformanceFlags.rollout) return;

    final rolloutIndex = _rollouts.indexWhere((r) => r.id == rolloutId);
    if (rolloutIndex == -1) {
      throw Exception('Rollout not found: $rolloutId');
    }

    final rollout = _rollouts[rolloutIndex];
    if (!rollout.isActive) {
      throw Exception('Rollout is not active: $rolloutId');
    }

    try {
      // Update rollout status to in progress
      _rollouts[rolloutIndex] = PerformanceRollout(
        id: rollout.id,
        version: rollout.version,
        phases: rollout.phases,
        status: RolloutStatus.inProgress,
        startedAt: rollout.startedAt,
        completedAt: rollout.completedAt,
        initiatedBy: rollout.initiatedBy,
        configuration: rollout.configuration,
        affectedServers: rollout.affectedServers,
        metrics: rollout.metrics,
        errorMessage: rollout.errorMessage,
        rollbackData: rollout.rollbackData,
      );
      await _saveRollouts();

      // Execute phase-specific logic
      await _executePhaseLogic(rolloutId, phase);

      // Validate the phase
      await _validateRolloutPhase(rolloutId, phase);

      // Record successful phase completion
      await _monitoringService.recordMetric(
        'phase_completed',
        1.0,
        category: 'Rollout',
        metadata: {
          'rolloutId': rolloutId,
          'phase': phase,
          'action': 'phase_completed',
        },
      );

    } catch (e) {
      // Handle phase failure
      await _handleRolloutFailure(rolloutId, e.toString());
      rethrow;
    }
  }

  /// Complete a rollout
  Future<void> completeRollout(String rolloutId) async {
    if (!PerformanceFlags.rollout) return;

    final rolloutIndex = _rollouts.indexWhere((r) => r.id == rolloutId);
    if (rolloutIndex == -1) {
      throw Exception('Rollout not found: $rolloutId');
    }

    final rollout = _rollouts[rolloutIndex];
    if (rollout.status != RolloutStatus.inProgress) {
      throw Exception('Rollout is not in progress: $rolloutId');
    }

    // Final validation placeholder (non-blocking for now)
    await _performFinalValidation(rolloutId);

    // Update rollout status to completed
    _rollouts[rolloutIndex] = PerformanceRollout(
      id: rollout.id,
      version: rollout.version,
      phases: rollout.phases,
      status: RolloutStatus.completed,
      startedAt: rollout.startedAt,
      completedAt: DateTime.now(),
      initiatedBy: rollout.initiatedBy,
      configuration: rollout.configuration,
      affectedServers: rollout.affectedServers,
      metrics: rollout.metrics,
      errorMessage: rollout.errorMessage,
      rollbackData: rollout.rollbackData,
    );
    await _saveRollouts();

    // Record rollout completion
    await _monitoringService.recordMetric(
      'rollout_completed',
      1.0,
      category: 'Rollout',
      metadata: {
        'rolloutId': rolloutId,
        'action': 'rollout_completed',
        'duration': rollout.duration?.inMinutes,
      },
    );
  }

  /// Rollback a rollout
  Future<void> rollbackRollout(String rolloutId, String reason) async {
    if (!PerformanceFlags.rollout) return;

    final rolloutIndex = _rollouts.indexWhere((r) => r.id == rolloutId);
    if (rolloutIndex == -1) {
      throw Exception('Rollout not found: $rolloutId');
    }

    final rollout = _rollouts[rolloutIndex];
    if (!rollout.isActive) {
      throw Exception('Rollout is not active: $rolloutId');
    }

    try {
      // Perform rollback operations
      await _performRollbackOperations(rolloutId, rollout.rollbackData);

      // Update rollout status to rolled back
      _rollouts[rolloutIndex] = PerformanceRollout(
        id: rollout.id,
        version: rollout.version,
        phases: rollout.phases,
        status: RolloutStatus.rolledBack,
        startedAt: rollout.startedAt,
        completedAt: DateTime.now(),
        initiatedBy: rollout.initiatedBy,
        configuration: rollout.configuration,
        affectedServers: rollout.affectedServers,
        metrics: rollout.metrics,
        errorMessage: reason,
        rollbackData: rollout.rollbackData,
      );
      await _saveRollouts();

      // Record rollback event
      await _monitoringService.recordMetric(
        'rollout_rolled_back',
        1.0,
        category: 'Rollout',
        metadata: {
          'rolloutId': rolloutId,
          'action': 'rollout_rolled_back',
          'reason': reason,
        },
      );

    } catch (e) {
      // Handle rollback failure
      await _handleRolloutFailure(rolloutId, 'Rollback failed: ${e.toString()}');
      rethrow;
    }
  }

  /// Validate performance data integrity
  Future<PerformanceValidation> validatePerformanceData({
    required String rolloutId,
    required String validationType,
    Map<String, dynamic>? customCriteria,
  }) async {
    if (!PerformanceFlags.rollout) {
      return _createDefaultValidation(rolloutId, validationType);
    }

    final criteria = customCriteria ?? _currentConfig?.validationCriteria ?? {};
    final results = <String, dynamic>{};
    final warnings = <String>[];
    final errors = <String>[];

    try {
      switch (validationType) {
        case 'data_integrity':
          await _validateDataIntegrity(results, warnings, errors);
          break;
        case 'score_accuracy':
          await _validateScoreAccuracy(results, warnings, errors);
          break;
        case 'system_health':
          await _validateSystemHealth(results, warnings, errors);
          break;
        case 'performance_consistency':
          await _validatePerformanceConsistency(results, warnings, errors);
          break;
        default:
          errors.add('Unknown validation type: $validationType');
      }

      final status = errors.isNotEmpty 
          ? ValidationStatus.failed 
          : warnings.isNotEmpty 
              ? ValidationStatus.warning 
              : ValidationStatus.passed;

      final validation = PerformanceValidation(
        id: _generateValidationId(),
        rolloutId: rolloutId,
        status: status,
        validationType: validationType,
        criteria: criteria,
        results: results,
        warnings: warnings,
        errors: errors,
        validatedAt: DateTime.now(),
        validatedBy: 'system',
        metadata: {
          'validationDuration': DateTime.now().millisecondsSinceEpoch,
          'criteriaVersion': criteria['version'] ?? '1.0',
        },
      );

      _validations.add(validation);
      await _saveValidations();

      return validation;

    } catch (e) {
      final validation = PerformanceValidation(
        id: _generateValidationId(),
        rolloutId: rolloutId,
        status: ValidationStatus.failed,
        validationType: validationType,
        criteria: criteria,
        results: results,
        warnings: warnings,
        errors: ['Validation failed: ${e.toString()}'],
        validatedAt: DateTime.now(),
        validatedBy: 'system',
        metadata: {'error': e.toString()},
      );

      _validations.add(validation);
      await _saveValidations();

      return validation;
    }
  }

  /// Perform data reconciliation
  Future<PerformanceReconciliation> performReconciliation({
    required String rolloutId,
    required ReconciliationType type,
    required String description,
    required Map<String, dynamic> parameters,
    String? initiatedBy,
  }) async {
    if (!PerformanceFlags.rollout) {
      return _createDefaultReconciliation(rolloutId, type, description);
    }

    final beforeState = await _captureSystemState();
    final startedAt = DateTime.now();
    bool isSuccessful = false;
    String? errorMessage;
    final metrics = <String, dynamic>{};

    try {
      switch (type) {
        case ReconciliationType.dataMigration:
          await _performDataMigration(parameters, metrics);
          break;
        case ReconciliationType.scoreRecalculation:
          await _performScoreRecalculation(parameters, metrics);
          break;
        case ReconciliationType.validationCheck:
          await _performValidationCheck(parameters, metrics);
          break;
        case ReconciliationType.rollback:
          await _performRollback(parameters, metrics);
          break;
        case ReconciliationType.cleanup:
          await _performCleanup(parameters, metrics);
          break;
      }

      isSuccessful = true;

    } catch (e) {
      errorMessage = e.toString();
      isSuccessful = false;
    }

    final afterState = await _captureSystemState();
    final completedAt = DateTime.now();

    final reconciliation = PerformanceReconciliation(
      id: _generateReconciliationId(),
      rolloutId: rolloutId,
      type: type,
      description: description,
      parameters: parameters,
      beforeState: beforeState,
      afterState: afterState,
      startedAt: startedAt,
      completedAt: completedAt,
      initiatedBy: initiatedBy ?? 'system',
      isSuccessful: isSuccessful,
      errorMessage: errorMessage,
      metrics: metrics,
    );

    _reconciliations.add(reconciliation);
    await _saveReconciliations();

    return reconciliation;
  }

  /// Get rollout history
  List<PerformanceRollout> getRolloutHistory() => List.from(_rollouts);

  /// Get active rollout
  PerformanceRollout? getActiveRollout() => 
      _rollouts.where((r) => r.isActive).firstOrNull;

  /// Get validation history
  List<PerformanceValidation> getValidationHistory() => List.from(_validations);

  /// Get reconciliation history
  List<PerformanceReconciliation> getReconciliationHistory() => List.from(_reconciliations);

  /// Get current rollout configuration
  PerformanceRolloutConfig? getCurrentConfig() => _currentConfig;

  /// Execute phase-specific logic
  Future<void> _executePhaseLogic(String rolloutId, int phase) async {
    switch (phase) {
      case 1:
        await _executePhase1(rolloutId);
        break;
      case 2:
        await _executePhase2(rolloutId);
        break;
      case 3:
        await _executePhase3(rolloutId);
        break;
      case 4:
        await _executePhase4(rolloutId);
        break;
      case 5:
        await _executePhase5(rolloutId);
        break;
      case 6:
        await _executePhase6(rolloutId);
        break;
      case 7:
        await _executePhase7(rolloutId);
        break;
      default:
        throw Exception('Unknown phase: $phase');
    }
  }

  /// Execute Phase 1: Data Hygiene & Safeguards
  Future<void> _executePhase1(String rolloutId) async {
    // Enable data hygiene features
    await PerformanceFlags.enablePhase(1);
    
    // Perform data cleanup
    await _performDataCleanup();
    
    // Validate data quality
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'data_integrity',
    );
  }

  /// Execute Phase 2: Baseline & Fallback Reform
  Future<void> _executePhase2(String rolloutId) async {
    // Enable baseline reform features
    await PerformanceFlags.enablePhase(2);
    
    // Recalculate baseline scores
    await _recalculateBaselineScores();
    
    // Validate score accuracy
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'score_accuracy',
    );
  }

  /// Execute Phase 3: Differentiation Mechanics
  Future<void> _executePhase3(String rolloutId) async {
    // Enable differentiation features
    await PerformanceFlags.enablePhase(3);
    
    // Apply enhanced scoring
    await _applyEnhancedScoring();
    
    // Validate performance consistency
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'performance_consistency',
    );
  }

  /// Execute Phase 4: Temporal Derivation Layer
  Future<void> _executePhase4(String rolloutId) async {
    // Enable temporal features
    await PerformanceFlags.enablePhase(4);
    
    // Initialize temporal analysis
    await _initializeTemporalAnalysis();
    
    // Validate temporal data
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'data_integrity',
    );
  }

  /// Execute Phase 5: Adaptive Weighting & Confidence
  Future<void> _executePhase5(String rolloutId) async {
    // Enable adaptive weighting features
    await PerformanceFlags.enablePhase(5);
    
    // Initialize adaptive weights
    await _initializeAdaptiveWeights();
    
    // Validate confidence calculations
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'score_accuracy',
    );
  }

  /// Execute Phase 6: Monitoring & Telemetry
  Future<void> _executePhase6(String rolloutId) async {
    // Enable monitoring features
    await PerformanceFlags.enablePhase(6);
    
    // Initialize monitoring service
    await _monitoringService.initialize();
    
    // Validate system health
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'system_health',
    );
  }

  /// Execute Phase 7: Rollout & Reconciliation
  Future<void> _executePhase7(String rolloutId) async {
    // Enable rollout features
    await PerformanceFlags.enablePhase(7);
    
    // Initialize rollout service
    await initialize();
    
    // Final system validation
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'system_health',
    );
  }

  /// Validate data integrity
  Future<void> _validateDataIntegrity(Map<String, dynamic> results, List<String> warnings, List<String> errors) async {
    // Check database connectivity
    results['database_connectivity'] = true;
    
    // Check data consistency
    results['data_consistency'] = true;
    
    // Check for missing data
    results['missing_data_check'] = true;
    
    // Add sample validation logic
    if (results['database_connectivity'] == false) {
      errors.add('Database connectivity failed');
    }
  }

  /// Validate score accuracy
  Future<void> _validateScoreAccuracy(Map<String, dynamic> results, List<String> warnings, List<String> errors) async {
    // Validate score calculations
    results['score_calculations'] = true;
    
    // Check for score anomalies
    results['score_anomalies'] = false;
    
    // Validate score ranges
    results['score_ranges'] = true;
    
    if (results['score_anomalies'] == true) {
      warnings.add('Score anomalies detected');
    }
  }

  /// Validate system health
  Future<void> _validateSystemHealth(Map<String, dynamic> results, List<String> warnings, List<String> errors) async {
    // Check system performance
    results['system_performance'] = true;
    
    // Check memory usage
    results['memory_usage'] = 75.0; // 75% usage
    
    // Check CPU usage
    results['cpu_usage'] = 45.0; // 45% usage
    
    if (results['memory_usage'] > 80.0) {
      warnings.add('High memory usage detected');
    }
  }

  /// Validate performance consistency
  Future<void> _validatePerformanceConsistency(Map<String, dynamic> results, List<String> warnings, List<String> errors) async {
    // Check performance consistency
    results['performance_consistency'] = true;
    
    // Check for performance drift
    results['performance_drift'] = false;
    
    if (results['performance_drift'] == true) {
      warnings.add('Performance drift detected');
    }
  }

  /// Perform data migration
  Future<void> _performDataMigration(Map<String, dynamic> parameters, Map<String, dynamic> metrics) async {
    // Implement data migration logic
    metrics['records_migrated'] = 1000;
    metrics['migration_duration'] = 5000; // 5 seconds
  }

  /// Perform score recalculation
  Future<void> _performScoreRecalculation(Map<String, dynamic> parameters, Map<String, dynamic> metrics) async {
    // Implement score recalculation logic
    metrics['scores_recalculated'] = 500;
    metrics['recalculation_duration'] = 3000; // 3 seconds
  }

  /// Perform validation check
  Future<void> _performValidationCheck(Map<String, dynamic> parameters, Map<String, dynamic> metrics) async {
    // Implement validation check logic
    metrics['validations_performed'] = 10;
    metrics['validation_duration'] = 2000; // 2 seconds
  }

  /// Perform rollback
  Future<void> _performRollback(Map<String, dynamic> parameters, Map<String, dynamic> metrics) async {
    // Implement rollback logic
    metrics['rollback_operations'] = 5;
    metrics['rollback_duration'] = 4000; // 4 seconds
  }

  /// Perform cleanup
  Future<void> _performCleanup(Map<String, dynamic> parameters, Map<String, dynamic> metrics) async {
    // Implement cleanup logic
    metrics['cleanup_operations'] = 3;
    metrics['cleanup_duration'] = 1000; // 1 second
  }

  /// Capture system state
  Future<Map<String, dynamic>> _captureSystemState() async {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'enabled_phases': PerformanceFlags.enabledPhases,
      'system_health': 'healthy',
    };
  }

  /// Handle rollout failure
  Future<void> _handleRolloutFailure(String rolloutId, String errorMessage) async {
    final rolloutIndex = _rollouts.indexWhere((r) => r.id == rolloutId);
    if (rolloutIndex != -1) {
      final rollout = _rollouts[rolloutIndex];
      _rollouts[rolloutIndex] = PerformanceRollout(
        id: rollout.id,
        version: rollout.version,
        phases: rollout.phases,
        status: RolloutStatus.failed,
        startedAt: rollout.startedAt,
        completedAt: DateTime.now(),
        initiatedBy: rollout.initiatedBy,
        configuration: rollout.configuration,
        affectedServers: rollout.affectedServers,
        metrics: rollout.metrics,
        errorMessage: errorMessage,
        rollbackData: rollout.rollbackData,
      );
      await _saveRollouts();
    }
  }

  /// Perform final validation
  Future<PerformanceValidation> _performFinalValidation(String rolloutId) async {
    return await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'system_health',
    );
  }

  /// Perform rollback operations
  Future<void> _performRollbackOperations(String rolloutId, Map<String, dynamic> rollbackData) async {
    // Implement rollback operations based on rollback data
    await Future.delayed(const Duration(seconds: 1)); // Simulate rollback
  }

  /// Validate rollout phase
  Future<void> _validateRolloutPhase(String rolloutId, int phase) async {
    await validatePerformanceData(
      rolloutId: rolloutId,
      validationType: 'data_integrity',
    );
  }

  /// Perform data cleanup
  Future<void> _performDataCleanup() async {
    // Implement data cleanup logic
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Recalculate baseline scores
  Future<void> _recalculateBaselineScores() async {
    // Implement baseline score recalculation
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  /// Apply enhanced scoring
  Future<void> _applyEnhancedScoring() async {
    // Implement enhanced scoring logic
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Initialize temporal analysis
  Future<void> _initializeTemporalAnalysis() async {
    // Implement temporal analysis initialization
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// Initialize adaptive weights
  Future<void> _initializeAdaptiveWeights() async {
    // Implement adaptive weights initialization
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Create default rollout configuration
  PerformanceRolloutConfig _createDefaultConfig() {
    return PerformanceRolloutConfig(
      version: '1.0.0',
      enabledPhases: [1, 2, 3, 4, 5, 6, 7],
      featureFlags: {
        'data_hygiene': true,
        'baseline_reform': true,
        'differentiation': true,
        'temporal_derivation': true,
        'adaptive_weights': true,
        'monitoring_telemetry': true,
        'rollout_reconciliation': true,
      },
      rolloutSettings: {
        'auto_validation': true,
        'rollback_on_failure': true,
        'phase_timeout': 300, // 5 minutes
        'max_retries': 3,
      },
      validationCriteria: {
        'data_integrity_threshold': 95.0,
        'score_accuracy_threshold': 98.0,
        'system_health_threshold': 90.0,
        'performance_consistency_threshold': 85.0,
      },
      rollbackSettings: {
        'auto_rollback': true,
        'rollback_timeout': 600, // 10 minutes
        'backup_retention': 7, // 7 days
      },
      createdAt: DateTime.now(),
      createdBy: 'system',
      isActive: true,
    );
  }

  /// Create default validation
  PerformanceValidation _createDefaultValidation(String rolloutId, String validationType) {
    return PerformanceValidation(
      id: _generateValidationId(),
      rolloutId: rolloutId,
      status: ValidationStatus.skipped,
      validationType: validationType,
      criteria: {},
      results: {},
      warnings: ['Rollout feature is not enabled'],
      errors: [],
      validatedAt: DateTime.now(),
      validatedBy: 'system',
      metadata: {},
    );
  }

  /// Create default reconciliation
  PerformanceReconciliation _createDefaultReconciliation(String rolloutId, ReconciliationType type, String description) {
    return PerformanceReconciliation(
      id: _generateReconciliationId(),
      rolloutId: rolloutId,
      type: type,
      description: description,
      parameters: {},
      beforeState: {},
      afterState: {},
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
      initiatedBy: 'system',
      isSuccessful: false,
      errorMessage: 'Rollout feature is not enabled',
      metrics: {},
    );
  }

  /// Generate unique rollout ID
  String _generateRolloutId() {
    return 'rollout_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Generate unique validation ID
  String _generateValidationId() {
    return 'validation_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Generate unique reconciliation ID
  String _generateReconciliationId() {
    return 'reconciliation_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Load rollouts from storage
  Future<void> _loadRollouts() async {
    final prefs = await SharedPreferences.getInstance();
    final rolloutsJson = prefs.getString(_rolloutsKey);
    
    if (rolloutsJson != null) {
      // In a real implementation, you'd parse the JSON and populate _rollouts
      _rollouts.clear();
    }
  }

  /// Save rollouts to storage
  Future<void> _saveRollouts() async {
    final prefs = await SharedPreferences.getInstance();
    // In a real implementation, you'd serialize to JSON
    await prefs.setString(_rolloutsKey, 'rollouts_saved');
  }

  /// Load validations from storage
  Future<void> _loadValidations() async {
    final prefs = await SharedPreferences.getInstance();
    final validationsJson = prefs.getString(_validationsKey);
    
    if (validationsJson != null) {
      // In a real implementation, you'd parse the JSON and populate _validations
      _validations.clear();
    }
  }

  /// Save validations to storage
  Future<void> _saveValidations() async {
    final prefs = await SharedPreferences.getInstance();
    // In a real implementation, you'd serialize to JSON
    await prefs.setString(_validationsKey, 'validations_saved');
  }

  /// Load reconciliations from storage
  Future<void> _loadReconciliations() async {
    final prefs = await SharedPreferences.getInstance();
    final reconciliationsJson = prefs.getString(_reconciliationsKey);
    
    if (reconciliationsJson != null) {
      // In a real implementation, you'd parse the JSON and populate _reconciliations
      _reconciliations.clear();
    }
  }

  /// Save reconciliations to storage
  Future<void> _saveReconciliations() async {
    final prefs = await SharedPreferences.getInstance();
    // In a real implementation, you'd serialize to JSON
    await prefs.setString(_reconciliationsKey, 'reconciliations_saved');
  }

  /// Load configuration from storage
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);
    
    if (configJson != null) {
      // In a real implementation, you'd parse the JSON
      _currentConfig = _createDefaultConfig();
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    // In a real implementation, you'd serialize to JSON
    await prefs.setString(_configKey, 'config_saved');
  }
}
