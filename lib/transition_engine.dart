/// TRANSITION ENGINE - ISOLATED TRANSITION LOGIC
/// 
/// This class contains ALL transition logic in isolation.
/// NO other code should handle roster transitions.
/// This ensures the core function is protected and testable.

class TransitionEngine {
  // IMMUTABLE STATE - Never modify directly
  final Set<String> _lunchRoster;
  final Set<String> _dinnerRoster;
  
  TransitionEngine({
    required Set<String> lunchRoster,
    required Set<String> dinnerRoster,
  }) : _lunchRoster = Set.unmodifiable(lunchRoster),
       _dinnerRoster = Set.unmodifiable(dinnerRoster);

  /// Core transition logic - determines active servers for each phase
  TransitionResult calculateTransition({
    required String currentPhase, // 'lunch', 'transition', 'dinner'
    required Map<String, int> currentCounts,
  }) {
    _validateInputs(currentPhase, currentCounts);
    
    switch (currentPhase) {
      case 'lunch':
        return _lunchPhase(currentCounts);
      case 'transition':
        return _transitionPhase(currentCounts);
      case 'dinner':
        return _dinnerPhase(currentCounts);
      default:
        throw ArgumentError('Invalid phase: $currentPhase');
    }
  }

  /// LUNCH PHASE: Only lunch roster servers are active
  TransitionResult _lunchPhase(Map<String, int> currentCounts) {
    final activeServers = Set<String>.from(_lunchRoster);
    final preservedCounts = Map<String, int>.from(currentCounts);
    
    // Ensure dinner-only servers can't accumulate counts
    for (final serverId in _dinnerOnlyServers) {
      preservedCounts[serverId] = 0;
    }
    
    return TransitionResult(
      activeServers: activeServers,
      preservedCounts: preservedCounts,
      phase: 'lunch',
      debugInfo: 'Lunch phase: ${activeServers.join(", ")} active',
    );
  }

  /// TRANSITION PHASE: All servers are active for clicks
  TransitionResult _transitionPhase(Map<String, int> currentCounts) {
    final activeServers = Set<String>()
      ..addAll(_lunchRoster)
      ..addAll(_dinnerRoster);
    
    final preservedCounts = Map<String, int>.from(currentCounts);
    
    return TransitionResult(
      activeServers: activeServers,
      preservedCounts: preservedCounts,
      phase: 'transition',
      debugInfo: 'Transition phase: ${activeServers.join(", ")} active',
    );
  }

  /// DINNER PHASE: Critical count preservation logic
  TransitionResult _dinnerPhase(Map<String, int> currentCounts) {
    final activeServers = Set<String>.from(_dinnerRoster);
    final preservedCounts = <String, int>{};
    
    // CRITICAL LOGIC: Count preservation rules
    for (final serverId in activeServers) {
      if (_dinnerOnlyServers.contains(serverId)) {
        // Dinner-only servers: PRESERVE transition counts
        preservedCounts[serverId] = currentCounts[serverId] ?? 0;
      } else if (_bothShiftServers.contains(serverId)) {
        // Both-shift servers: RESET to 0 for dinner
        preservedCounts[serverId] = 0;
      }
    }
    
    return TransitionResult(
      activeServers: activeServers,
      preservedCounts: preservedCounts,
      phase: 'dinner',
      debugInfo: 'Dinner phase: ${activeServers.join(", ")} active, '
                'preserved: ${_dinnerOnlyServers.join(", ")}, '
                'reset: ${_bothShiftServers.join(", ")}',
    );
  }

  /// Server categorization - computed properties for clarity
  Set<String> get _dinnerOnlyServers => _dinnerRoster.difference(_lunchRoster);
  Set<String> get _bothShiftServers => _dinnerRoster.intersection(_lunchRoster);
  Set<String> get _lunchOnlyServers => _lunchRoster.difference(_dinnerRoster);

  /// Validation to prevent invalid states
  void _validateInputs(String phase, Map<String, int> counts) {
    if (!['lunch', 'transition', 'dinner'].contains(phase)) {
      throw ArgumentError('Invalid phase: $phase');
    }
    
    if (_lunchRoster.isEmpty && _dinnerRoster.isEmpty) {
      throw StateError('Both rosters cannot be empty');
    }
    
    // Validate all roster servers have count entries
    final allServers = Set<String>()..addAll(_lunchRoster)..addAll(_dinnerRoster);
    for (final serverId in allServers) {
      if (!counts.containsKey(serverId)) {
        throw StateError('Missing count for server: $serverId');
      }
    }
  }

  /// Debug information for troubleshooting
  Map<String, dynamic> get debugInfo => {
    'lunchRoster': _lunchRoster.toList(),
    'dinnerRoster': _dinnerRoster.toList(),
    'lunchOnly': _lunchOnlyServers.toList(),
    'dinnerOnly': _dinnerOnlyServers.toList(),
    'bothShifts': _bothShiftServers.toList(),
  };
}

/// Immutable result from transition calculations
class TransitionResult {
  final Set<String> activeServers;
  final Map<String, int> preservedCounts;
  final String phase;
  final String debugInfo;

  const TransitionResult({
    required this.activeServers,
    required this.preservedCounts,
    required this.phase,
    required this.debugInfo,
  });

  @override
  String toString() => 'TransitionResult($debugInfo)';
}

/// Annotation to mark transition-critical code
class TransitionCritical {
  final String description;
  const TransitionCritical(this.description);
}
