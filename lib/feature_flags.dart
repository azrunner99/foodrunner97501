/// Central feature flag registry for progressive rollout of recalibrated performance system.
/// Each flag should be: (1) documented in the blueprint, (2) reversible, and (3) default safe/off.
class FeatureFlags {
  FeatureFlags._();

  // Phase 1: Data Hygiene & Safeguards
  static bool perfV2DataHygiene = false; // Exclude blank months, dataQuality tagging

  // Future phases (declared early for visibility; remain false until implemented)
  static bool perfV2Baseline = false; // Baseline & fallback reform
  static bool perfV2Differentiation = false; // Differentiation mechanics
  static bool perfV2Temporal = false; // Temporal derivation layer
  static bool perfV2AdaptiveWeights = false; // Adaptive weighting & confidence
  static bool perfV2Telemetry = false; // Monitoring & telemetry
  static bool perfV2Rollout = false; // Dual display & reconciliation

  /// Optional runtime override helper (e.g., from debug console / admin panel)
  /// Example: FeatureFlags.setFlag('perfV2DataHygiene', true);
  static bool setFlag(String name, bool value) {
    switch (name) {
      case 'perfV2DataHygiene':
        perfV2DataHygiene = value; return true;
      case 'perfV2Baseline':
        perfV2Baseline = value; return true;
      case 'perfV2Differentiation':
        perfV2Differentiation = value; return true;
      case 'perfV2Temporal':
        perfV2Temporal = value; return true;
      case 'perfV2AdaptiveWeights':
        perfV2AdaptiveWeights = value; return true;
      case 'perfV2Telemetry':
        perfV2Telemetry = value; return true;
      case 'perfV2Rollout':
        perfV2Rollout = value; return true;
      default:
        return false;
    }
  }

  /// Snapshot of current flags for logging/diagnostics.
  static Map<String, bool> snapshot() => {
    'perfV2DataHygiene': perfV2DataHygiene,
    'perfV2Baseline': perfV2Baseline,
    'perfV2Differentiation': perfV2Differentiation,
    'perfV2Temporal': perfV2Temporal,
    'perfV2AdaptiveWeights': perfV2AdaptiveWeights,
    'perfV2Telemetry': perfV2Telemetry,
    'perfV2Rollout': perfV2Rollout,
  };
}
