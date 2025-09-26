import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for the Performance System Recalibration
/// Each phase can be enabled/disabled independently for safe rollout
class PerformanceFlags {
  static final Map<String, bool> _flags = {
    'perf_v2_data_hygiene': false,
    'perf_v2_baseline': false,
    'perf_v2_differentiation': false,
    'perf_v2_temporal': false,
    'perf_v2_adaptive_weights': false,
    'perf_v2_telemetry': false,
    'perf_v2_rollout': false,
  };

  static SharedPreferences? _prefs;

  /// Initialize the feature flags from SharedPreferences
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFlags();
  }

  /// Load flags from SharedPreferences
  static Future<void> _loadFlags() async {
    if (_prefs == null) return;
    
    for (final key in _flags.keys) {
      _flags[key] = _prefs!.getBool(key) ?? false;
    }
  }

  /// Save flags to SharedPreferences
  static Future<void> _saveFlags() async {
    if (_prefs == null) return;
    
    for (final entry in _flags.entries) {
      await _prefs!.setBool(entry.key, entry.value);
    }
  }

  // Phase 1: Data Hygiene & Safeguards
  static bool get dataHygiene => _flags['perf_v2_data_hygiene'] ?? false;
  
  // Phase 2: Baseline & Fallback Reform
  static bool get baselineReform => _flags['perf_v2_baseline'] ?? false;
  
  // Phase 3: Differentiation Mechanics
  static bool get differentiation => _flags['perf_v2_differentiation'] ?? false;
  
  // Phase 4: Temporal Derivation Layer
  static bool get temporalDerivation => _flags['perf_v2_temporal'] ?? false;
  
  // Phase 5: Adaptive Weighting & Confidence
  static bool get adaptiveWeights => _flags['perf_v2_adaptive_weights'] ?? false;
  
  // Phase 6: Monitoring & Telemetry
  static bool get telemetry => _flags['perf_v2_telemetry'] ?? false;
  static bool get monitoringTelemetry => _flags['perf_v2_telemetry'] ?? false;
  
  // Phase 7: Rollout & Reconciliation
  static bool get rollout => _flags['perf_v2_rollout'] ?? false;

  /// Enable a specific phase
  static Future<void> enablePhase(int phase) async {
    switch (phase) {
      case 1:
        _flags['perf_v2_data_hygiene'] = true;
        break;
      case 2:
        _flags['perf_v2_baseline'] = true;
        break;
      case 3:
        _flags['perf_v2_differentiation'] = true;
        break;
      case 4:
        _flags['perf_v2_temporal'] = true;
        break;
      case 5:
        _flags['perf_v2_adaptive_weights'] = true;
        break;
      case 6:
        _flags['perf_v2_telemetry'] = true;
        break;
      case 7:
        _flags['perf_v2_rollout'] = true;
        break;
      default:
        throw ArgumentError('Invalid phase number: $phase');
    }
    await _saveFlags();
  }

  /// Disable a specific phase (rollback)
  static Future<void> rollbackPhase(int phase) async {
    switch (phase) {
      case 1:
        _flags['perf_v2_data_hygiene'] = false;
        break;
      case 2:
        _flags['perf_v2_baseline'] = false;
        break;
      case 3:
        _flags['perf_v2_differentiation'] = false;
        break;
      case 4:
        _flags['perf_v2_temporal'] = false;
        break;
      case 5:
        _flags['perf_v2_adaptive_weights'] = false;
        break;
      case 6:
        _flags['perf_v2_telemetry'] = false;
        break;
      case 7:
        _flags['perf_v2_rollout'] = false;
        break;
      default:
        throw ArgumentError('Invalid phase number: $phase');
    }
    await _saveFlags();
  }

  /// Enable all phases (for testing)
  static Future<void> enableAllPhases() async {
    for (int phase = 1; phase <= 7; phase++) {
      await enablePhase(phase);
    }
  }

  /// Disable all phases (full rollback)
  static Future<void> disableAllPhases() async {
    for (int phase = 1; phase <= 7; phase++) {
      await rollbackPhase(phase);
    }
  }

  /// Get current flag status for debugging
  static Map<String, bool> get currentFlags => Map.from(_flags);

  /// Check if any performance v2 features are enabled
  static bool get hasAnyV2Features => _flags.values.any((enabled) => enabled);

  /// Get enabled phases list
  static List<int> get enabledPhases {
    final phases = <int>[];
    if (dataHygiene) phases.add(1);
    if (baselineReform) phases.add(2);
    if (differentiation) phases.add(3);
    if (temporalDerivation) phases.add(4);
    if (adaptiveWeights) phases.add(5);
    if (telemetry) phases.add(6);
    if (rollout) phases.add(7);
    return phases;
  }
}
