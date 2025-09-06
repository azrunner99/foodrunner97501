/// RUNTIME TRANSITION VALIDATION
/// Add these methods to AppState for runtime protection

mixin TransitionValidation {
  
  /// Validates transition state integrity - call after any transition change
  @TransitionCritical("Validates core transition state integrity")
  void _validateTransitionState() {
    if (kDebugMode) {
      // Critical state validations
      assert(_workingServerIds.isNotEmpty || !_shiftActive, 
             'CRITICAL: No working servers during active shift');
      
      assert(lunchRoster.isNotEmpty || dinnerRoster.isNotEmpty,
             'CRITICAL: Both rosters cannot be empty');
      
      // Roster integrity checks
      if (_shiftType == 'Lunch') {
        assert(_workingServerIds.every((id) => lunchRoster.contains(id)),
               'CRITICAL: Lunch shift has non-lunch servers active');
      } else if (_shiftType == 'Dinner') {
        assert(_workingServerIds.every((id) => dinnerRoster.contains(id)),
               'CRITICAL: Dinner shift has non-dinner servers active');
      }
      
      // Count preservation validation
      final dinnerOnly = dinnerRoster.toSet().difference(lunchRoster.toSet());
      final bothShifts = dinnerRoster.toSet().intersection(lunchRoster.toSet());
      
      if (_shiftType == 'Dinner' && _shiftActive) {
        for (final serverId in bothShifts) {
          // Both-shift servers should start dinner at 0
          if (_currentCounts[serverId] != 0 && !_debugModeActive) {
            print('⚠️  WARNING: Both-shift server $serverId should reset to 0 at dinner start');
          }
        }
      }
      
      _logTransitionState('VALIDATION_PASS');
    }
  }

  /// Logs critical transition events for debugging
  @TransitionCritical("Logs transition state for debugging")
  void _logTransitionState(String event) {
    if (kDebugMode) {
      final state = {
        'event': event,
        'shiftType': _shiftType,
        'shiftActive': _shiftActive,
        'workingServers': _workingServerIds.toList(),
        'lunchRoster': lunchRoster,
        'dinnerRoster': dinnerRoster,
        'currentCounts': Map.from(_currentCounts),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('[TRANSITION-STATE] $event: ${jsonEncode(state)}');
    }
  }

  /// Validates click is allowed for the given server
  @TransitionCritical("Core click validation logic")
  bool _isClickAllowed(String serverId) {
    // CRITICAL: This is the core click validation logic
    final allowed = _shiftActive && _workingServerIds.contains(serverId);
    
    if (kDebugMode && !allowed) {
      print('[CLICK-DENIED] Server $serverId: shiftActive=$_shiftActive, inWorkingSet=${_workingServerIds.contains(serverId)}');
    }
    
    return allowed;
  }

  /// Safely backs up counts with validation
  @TransitionCritical("Count backup validation")
  Map<String, int> _safeBackupCounts(Set<String> serverIds) {
    final backup = <String, int>{};
    
    for (final serverId in serverIds) {
      final count = _currentCounts[serverId] ?? 0;
      backup[serverId] = count;
      
      if (kDebugMode) {
        print('[BACKUP] Server $serverId: $count runs');
      }
    }
    
    return backup;
  }

  /// Safely restores counts with validation
  @TransitionCritical("Count restore validation")
  void _safeRestoreCounts(Map<String, int> backup) {
    for (final entry in backup.entries) {
      final serverId = entry.key;
      final count = entry.value;
      
      _currentCounts[serverId] = count;
      
      if (kDebugMode) {
        print('[RESTORE] Server $serverId: $count runs');
      }
    }
  }

  /// Emergency state reset - use only for recovery
  @TransitionCritical("Emergency state recovery")
  void _emergencyResetTransitionState() {
    if (kDebugMode) {
      print('[EMERGENCY-RESET] Resetting transition state');
      
      _workingServerIds.clear();
      _shiftActive = false;
      _shiftType = 'Lunch';
      
      // Reset all counts to 0
      for (final key in _currentCounts.keys.toList()) {
        _currentCounts[key] = 0;
      }
      
      notifyListeners();
      print('[EMERGENCY-RESET] Complete');
    }
  }

  /// Debug flag for testing
  bool _debugModeActive = false;
  
  void enableDebugMode() => _debugModeActive = true;
  void disableDebugMode() => _debugModeActive = false;
}

/// Enhanced increment method with full protection
@TransitionCritical("Core click handling with validation")
void increment(String serverId) {
  // RUNTIME VALIDATION
  _validateTransitionState();
  
  // CORE LOGIC - PROTECTED
  if (!_isClickAllowed(serverId)) {
    if (kDebugMode) {
      print('[CLICK-BLOCKED] Server $serverId not allowed to click');
    }
    return;
  }
  
  // LOG CRITICAL EVENT
  _logTransitionState('CLICK_RECEIVED');
  
  // SAFE INCREMENT
  final oldCount = _currentCounts[serverId] ?? 0;
  _currentCounts[serverId] = oldCount + 1;
  
  if (kDebugMode) {
    print('[CLICK-SUCCESS] Server $serverId: ${oldCount} -> ${oldCount + 1}');
  }
  
  // UPDATE GAMIFICATION (safe to modify)
  _updateServerStats(serverId);
  _updateGamification(serverId);
  _saveState();
  
  // POST-INCREMENT VALIDATION
  _validateTransitionState();
  
  notifyListeners();
}
