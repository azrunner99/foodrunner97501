# TRANSITION LOGIC PROTECTION CHECKLIST

## ⚠️ CRITICAL CODE AREAS - TEST BEFORE MODIFYING

### Core Transition Methods (lib/app_state.dart)
- `_startTicker()` - Lines ~475-580: Contains the main transition logic
- `_maybeActivateShiftByClock()` - Lines ~665-740: Handles shift activation
- `_beginShift()` - Method that starts shifts with preservation logic

### Key Variables - DO NOT RENAME WITHOUT UPDATING TESTS
- `_currentCounts`: Server click counts
- `_workingServerIds`: Set of active servers  
- `_shiftActive`: Boolean indicating if shift is running
- `_shiftType`: 'Lunch' or 'Dinner'
- `_activeRosterView`: UI state for roster display

### Critical Logic Patterns - PRESERVE EXACTLY
1. **Roster categorization** (commit a7fa1ef):
   ```dart
   final dinnerOnly = dinnerSet.difference(lunchSet);
   final bothShifts = dinnerSet.intersection(lunchSet);
   ```

2. **Count preservation order**:
   - FIRST: Backup dinner-only server counts
   - SECOND: Save lunch shift data
   - THIRD: Remove lunch-only servers
   - FOURTH: Start dinner shift
   - FIFTH: Restore dinner-only counts
   - SIXTH: Reset both-shift servers to 0

### Testing Requirements Before Any Changes
- [ ] Run transition test with roster: Lunch [A,B], Dinner [B,C]
- [ ] Verify Server A disappears at dinner
- [ ] Verify Server B resets to 0 at dinner start
- [ ] Verify Server C preserves transition clicks
- [ ] Check flutter logs for proper debug output
- [ ] Ensure no "shift starts at" message during active shift

### Debug Logging - DO NOT REMOVE
These debug statements are crucial for troubleshooting:
- `[DEBUG] Lunch roster:` / `[DEBUG] Dinner roster:`
- `[DEBUG] Dinner-only servers:` / `[DEBUG] Both-shift servers:`
- `[DEBUG] Backing up server` / `[DEBUG] Restored server`
- `[DEBUG] Before reset` / `[DEBUG] After reset`

## Red Flags That Indicate Broken Logic
- Server counts disappear unexpectedly
- "Shift starts at" appears during active period
- Servers can't click during dinner
- Both-shift servers don't reset to 0
- Dinner-only servers lose transition counts

## Safe Areas to Modify
- UI components (screens/*.dart)
- Non-transition gamification logic
- History/reporting features
- Settings that don't affect roster timing

## Emergency Rollback
If transition logic breaks, revert to commit: `a7fa1ef`
```
git checkout a7fa1ef -- lib/app_state.dart
```
