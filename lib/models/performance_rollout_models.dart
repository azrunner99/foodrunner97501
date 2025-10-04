/// Performance rollout model set (expanded) used by service + dashboards.

enum RolloutStatus { pending, inProgress, completed, failed, rolledBack, paused }
enum ValidationStatus { passed, failed, warning, skipped }
enum ReconciliationType { dataMigration, scoreRecalculation, validationCheck, rollback, cleanup }

class PerformanceRolloutConfig {
  final String version;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  // Newly added fields expected by service/dashboard
  final List<int> enabledPhases;
  final Map<String, dynamic> featureFlags; // individual feature toggles
  final Map<String, dynamic> rolloutSettings; // generic rollout settings (timeouts, retries, etc.)
  final Map<String, dynamic> validationCriteria; // validation criteria map
  final Map<String, dynamic> rollbackSettings; // rollback behavior configuration

  PerformanceRolloutConfig({
    this.version = '1.0.0',
    this.isActive = true,
    DateTime? createdAt,
    this.createdBy = 'system',
    this.enabledPhases = const [],
    this.featureFlags = const {},
    this.rolloutSettings = const {},
    this.validationCriteria = const {},
    this.rollbackSettings = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'version': version,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'enabledPhases': enabledPhases,
        'featureFlags': featureFlags,
        'rolloutSettings': rolloutSettings,
        'validationCriteria': validationCriteria,
        'rollbackSettings': rollbackSettings,
      };

  factory PerformanceRolloutConfig.fromJson(Map<String, dynamic> json) => PerformanceRolloutConfig(
        version: json['version'] ?? '1.0.0',
        isActive: json['isActive'] ?? true,
        createdAt: _tryParseDate(json['createdAt']) ?? DateTime.now(),
        createdBy: json['createdBy'] ?? 'system',
        enabledPhases: (json['enabledPhases'] as List?)?.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList() ?? const [],
        featureFlags: (json['featureFlags'] as Map?)?.cast<String, dynamic>() ?? const {},
        rolloutSettings: (json['rolloutSettings'] as Map?)?.cast<String, dynamic>() ?? const {},
        validationCriteria: (json['validationCriteria'] as Map?)?.cast<String, dynamic>() ?? const {},
        rollbackSettings: (json['rollbackSettings'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class PerformanceRollout {
  final String id;
  final String version;
  final List<int> phases;
  final RolloutStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String initiatedBy;
  final Map<String, dynamic> configuration;
  final List<String> affectedServers;
  final Map<String, dynamic> metrics;
  final String? errorMessage;
  final Map<String, dynamic> rollbackData;

  PerformanceRollout({
    required this.id,
    required this.version,
    required this.phases,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.initiatedBy,
    required this.configuration,
    required this.affectedServers,
    required this.metrics,
    required this.errorMessage,
    required this.rollbackData,
  });

  bool get isActive => status == RolloutStatus.pending || status == RolloutStatus.inProgress;
  Duration? get duration => startedAt != null && completedAt != null ? completedAt!.difference(startedAt!) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'phases': phases,
        'status': status.name,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'initiatedBy': initiatedBy,
        'configuration': configuration,
        'affectedServers': affectedServers,
        'metrics': metrics,
        'errorMessage': errorMessage,
        'rollbackData': rollbackData,
      };

  factory PerformanceRollout.fromJson(Map<String, dynamic> json) => PerformanceRollout(
        id: json['id'] as String,
        version: json['version'] ?? '1.0.0',
        phases: (json['phases'] as List?)?.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList() ?? const [],
        status: _parseEnum(RolloutStatus.values, json['status'], RolloutStatus.pending),
        startedAt: _tryParseDate(json['startedAt']),
        completedAt: _tryParseDate(json['completedAt']),
        initiatedBy: json['initiatedBy'] ?? 'system',
        configuration: (json['configuration'] as Map?)?.cast<String, dynamic>() ?? const {},
        affectedServers: (json['affectedServers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        metrics: (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {},
        errorMessage: json['errorMessage'] as String?,
        rollbackData: (json['rollbackData'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class PerformanceValidation {
  final String id;
  final String rolloutId;
  final ValidationStatus status;
  final String validationType;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> results;
  final List<String> warnings;
  final List<String> errors;
  final DateTime validatedAt;
  final String validatedBy;
  final Map<String, dynamic> metadata;

  PerformanceValidation({
    required this.id,
    required this.rolloutId,
    required this.status,
    required this.validationType,
    required this.criteria,
    required this.results,
    required this.warnings,
    required this.errors,
    required this.validatedAt,
    required this.validatedBy,
    required this.metadata,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => status == ValidationStatus.passed && errors.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rolloutId': rolloutId,
        'status': status.name,
        'validationType': validationType,
        'criteria': criteria,
        'results': results,
        'warnings': warnings,
        'errors': errors,
        'validatedAt': validatedAt.toIso8601String(),
        'validatedBy': validatedBy,
        'metadata': metadata,
      };

  factory PerformanceValidation.fromJson(Map<String, dynamic> json) => PerformanceValidation(
        id: json['id'] as String,
        rolloutId: json['rolloutId'] as String,
        status: _parseEnum(ValidationStatus.values, json['status'], ValidationStatus.passed),
        validationType: json['validationType'] ?? 'unknown',
        criteria: (json['criteria'] as Map?)?.cast<String, dynamic>() ?? const {},
        results: (json['results'] as Map?)?.cast<String, dynamic>() ?? const {},
        warnings: (json['warnings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        errors: (json['errors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        validatedAt: _tryParseDate(json['validatedAt']) ?? DateTime.now(),
        validatedBy: json['validatedBy'] ?? 'system',
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class PerformanceReconciliation {
  final String id;
  final String rolloutId;
  final ReconciliationType type;
  final String description;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final DateTime startedAt;
  final DateTime completedAt;
  final String initiatedBy;
  final bool isSuccessful;
  final String? errorMessage;
  final Map<String, dynamic> metrics;

  PerformanceReconciliation({
    required this.id,
    required this.rolloutId,
    required this.type,
    required this.description,
    required this.parameters,
    required this.beforeState,
    required this.afterState,
    required this.startedAt,
    required this.completedAt,
    required this.initiatedBy,
    required this.isSuccessful,
    required this.errorMessage,
    required this.metrics,
  });

  Duration get duration => completedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'rolloutId': rolloutId,
        'type': type.name,
        'description': description,
        'parameters': parameters,
        'beforeState': beforeState,
        'afterState': afterState,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'initiatedBy': initiatedBy,
        'isSuccessful': isSuccessful,
        'errorMessage': errorMessage,
        'metrics': metrics,
      };

  factory PerformanceReconciliation.fromJson(Map<String, dynamic> json) => PerformanceReconciliation(
        id: json['id'] as String,
        rolloutId: json['rolloutId'] as String,
        type: _parseEnum(ReconciliationType.values, json['type'], ReconciliationType.validationCheck),
        description: json['description'] ?? 'N/A',
        parameters: (json['parameters'] as Map?)?.cast<String, dynamic>() ?? const {},
        beforeState: (json['beforeState'] as Map?)?.cast<String, dynamic>() ?? const {},
        afterState: (json['afterState'] as Map?)?.cast<String, dynamic>() ?? const {},
        startedAt: _tryParseDate(json['startedAt']) ?? DateTime.now(),
        completedAt: _tryParseDate(json['completedAt']) ?? DateTime.now(),
        initiatedBy: json['initiatedBy'] ?? 'system',
        isSuccessful: json['isSuccessful'] ?? false,
        errorMessage: json['errorMessage'] as String?,
        metrics: (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

// Helpers
T _parseEnum<T>(List<T> values, dynamic raw, T fallback) {
  if (raw == null) return fallback;
  final name = raw.toString();
  for (final v in values) {
    if (v.toString().split('.').last == name) return v;
  }
  return fallback;
}

DateTime? _tryParseDate(dynamic raw) {
  if (raw == null) return null;
  try { return DateTime.parse(raw.toString()); } catch (_) { return null; }
}