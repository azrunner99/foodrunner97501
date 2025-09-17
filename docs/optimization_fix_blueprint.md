# Food Runs Counter – Optimization & Fix Blueprint

Date: 2025-09-16
Branch: feature/leaderboard-improvements-preserved
Owner: foodrunner97501 (azrunner99)

## Purpose
This document is a durable plan to fix and harden the app. It captures the issues identified during our recent audit and establishes a prioritized, testable path to resolution. Treat this as the source of truth when context is lost or after memory resets.

## Goals
- Eliminate analyzer noise and fragile code paths.
- Make roster/shift transitions robust during live operations (no count loss, no click misattribution).
- Ensure persistence is consistent and intentional (team colors, station assignments, rosters).
- Consolidate logic to a single source of truth and add regression tests.

---

## Quick Inventory (what matters for this plan)
- Core state: `lib/app_state.dart`
- Roster UI: `lib/screens/update_roster_screen.dart`
- Admin UI (clean): `lib/screens/clean_admin_screen.dart`
- Corrupted legacy admin: `lib/screens/admin_screen.dart` (unused, but breaks analyzer)
- Persistence wrapper: `lib/storage.dart` (namespaced SharedPreferences)
- Station assignments persistence keys (direct SP keys):
  - `lunchStationType`, `dinnerStationType`, `lunchStationSection`, `dinnerStationSection`

---

## Issues and Priorities

### P0 — Must-do immediately
1) Corrupted `lib/screens/admin_screen.dart` (1096 analyzer errors)
- Symptom: Interleaved imports/classes/prints; not used at runtime but pollutes analysis.
- Impact: Breaks analyzer/dev ergonomics; risk of accidental import.
- Decision:
  - Remove or move out of `lib/`. If preservation needed, rename to `admin_screen.corrupted.bak` outside `lib/`.
  - Alternative (if removal deferred): Exclude via `analysis_options.yaml`.

2) Team color persistence after roster save
- Current: `update_roster_screen.dart::saveRoster()` sets `s.teamColor` in memory but does not persist servers.
- Impact: Team colors can disappear after app restart.
- Decision: After applying team colors, call `await app.save()` to persist servers, profiles, totals, day plan, and tap logs.

3) Duplicate transition switching logic
- Current: Lunch→Dinner switching logic appears in two places:
  - `_startTicker()` (timer block with transition end handling)
  - `_maybeActivateShiftByClock()` (transition end handling)
- Impact: Fragile; easy to drift and cause double-work or regressions.
- Decision: Consolidate into a single place. Recommended: keep transition logic only in `_maybeActivateShiftByClock()` and remove the duplicate block from `_startTicker()`.

### P1 — Important, soon after P0
4) `updateBothRosters` uses intended shift instead of current
- Current: `AppState.updateBothRosters(...)` selects roster based on `currentIntendedShiftType(now)`, risking mismatches at transition boundaries.
- Current usage: No active call sites found; UI does `setTodayPlan(...)` + `updateActiveRoster(...)` using `shiftType` (correct).
- Decision:
  - Either remove the unused method, or
  - Change it to use `shiftType` (current) and `preserveExistingCounts: shiftActive` to mirror the proven pattern.
  - Add a doc comment that this method should not be used to decide shifts by clock.

5) Document “intended shift” vs plan-based timings
- Current: `currentIntendedShiftType()` uses static `dinnerSwitchMinutes` (3:30pm), while live switching respects `todayPlan.transitionEndMinutes`.
- Impact: Conceptual drift; acceptable but must be documented.
- Decision: Add documentation clarifying that “intended” is a heuristic useful for manual/forced starts, while live behavior uses plan times.

### P2 — Nice-to-have and cleanup
6) Persistence pattern consistency for station keys
- Current: Station assignments persist via raw SP keys outside `Storage`.
- Impact: Not a bug; increases cognitive load.
- Decision: Consider refactor later to `Storage.settingsBox` with namespaced keys to standardize.

7) Debug print noise
- Current: Extensive `[DEBUG] ...` logs.
- Decision: Optional: wrap prints with a simple logger that can be toggled via settings (e.g., `settings.debugLoggingEnabled`).

---

## Detailed Fix Steps

### Fix 1: Remove or quarantine corrupted admin screen (P0)
- File: `lib/screens/admin_screen.dart`
- Actions:
  - Option A (preferred): Delete file.
  - Option B: Move it to `backup/` or rename to `lib/screens/admin_screen.corrupted.bak` and exclude from analyzer.
  - Option C: Add to `analysis_options.yaml` exclude block:
    
    ```yaml
    analyzer:
      exclude:
        - lib/screens/admin_screen.dart
    ```
    
- Acceptance Criteria:
  - `flutter analyze` shows no errors from `admin_screen.dart`.
  - App still routes `/admin` to `CleanAdminScreen` and functions normally.

### Fix 2: Persist team colors after roster save (P0)
- File: `lib/screens/update_roster_screen.dart`
- Current behavior:
  - Updates `s.teamColor` in-memory and saves station keys.
- Change:
  - After assigning team colors, call `await widget.app.save()` (or a public `persistServers()` if you prefer a smaller scope) to persist to `Storage.serversBox`.
- Acceptance Criteria:
  - Set team colors, restart app, verify colors persist (e.g., Home screen team pie chart shows consistent teams).

### Fix 3: Consolidate transition logic (P0)
- Files: `lib/app_state.dart`
- Change:
  - Keep transition end logic only in `_maybeActivateShiftByClock()`.
  - Remove duplicate from the `_startTicker()` periodic block.
  - Ensure the remaining logic covers:
    - Save lunch partial, clear lunch-only, reset both-shift to 0, preserve dinner-only counts, rebuild workingId set to dinner roster.
- Acceptance Criteria:
  - Transition scenarios pass:
    - A→F swap during lunch: F can click immediately; counts preserved.
    - C→G swap during transition: G can click immediately; counts preserved; both-shift servers reset at dinner start.
  - No double-invocation behavior in logs at transition end.

### Fix 4: Guard `updateBothRosters` (P1)
- File: `lib/app_state.dart`
- Change (choose one):
  - Remove the method if unused.
  - Or update to use `shiftType` and `preserveExistingCounts: shiftActive`.
  - Add a doc comment explaining why not to use intended-shift for live roster updates.
- Acceptance Criteria:
  - No code path uses intended shift to pick active roster during live updates.

### Fix 5: Document “intended” vs “plan” shift timing (P1)
- File: `lib/app_state.dart` (comments near `currentIntendedShiftType`)
- Change:
  - Add clear comment block explaining intended is a heuristic (static 3:30pm), while live shift activation uses plan’s transition window.
- Acceptance Criteria:
  - Future maintainers can understand and avoid misusing intended shift logic.

### Fix 6: Standardize station key persistence (P2, optional)
- Files:
  - `lib/screens/update_roster_screen.dart`
  - `lib/storage.dart`
- Change:
  - Move station key persistence into `Storage.settingsBox` using namespaced keys, or keep but add a helper wrapper for reads/writes.
- Acceptance Criteria:
  - All persistence flows are discoverable via `Storage`.

### Fix 7: Optional logging toggle (P2)
- Files:
  - `lib/app_state.dart` and other heavy log producers
  - `lib/app_state.dart` settings (extend `GamificationSettings` or add a simple `debug` flag in `settingsBox`)
- Change:
  - Wrap print statements with a `if (settings.debugLoggingEnabled)` or a simple `Log.d(...)` function.
- Acceptance Criteria:
  - Logs can be silenced in production while keeping them available for testing.

---

## Tests & Validation

### Unit tests (prioritize)
- File: `test/transition_integration_test.dart` (extend) and/or add new tests
- Scenarios:
  1) updateActiveRoster preserve semantics
     - Given: Lunch active with counts; call `updateActiveRoster([...])` with `preserveExistingCounts: true` that swaps a server.
     - Expect: Working set reflects new roster; existing server counts maintained; new servers initialized to 0; removed servers’ counts are not needed for active set.
  2) Transition end behavior (lunch→dinner)
     - Given: Lunch roster L, dinner roster D; some servers in both, some dinner-only.
     - When: Time crosses `todayPlan.transitionEndMinutes`.
     - Expect: Lunch-only removed; both-shift counts reset; dinner-only counts preserved; `workingServerIds == D`.
  3) Team color persistence
     - Set team colors, invoke save flow, simulate reload via `AppState.load()`.
     - Expect: `servers[i].teamColor` restored.

### Manual smoke
- Start lunch, assign roster, click counts.
- During lunch, swap A→F; verify immediate clickability and preserved counts.
- Enter transition window, add dinner-only servers; verify they can click.
- At transition end, verify both-shift reset and dinner-only preserved.

### Static checks
- `flutter analyze` → zero errors/warnings related to corrupted admin screen.
- Diffs confirm only intended changes.

---

## Rollback Strategy
- All edits are local and scoped. If issues arise:
  - Revert the specific commit for Fix 3 (transition consolidation) while we re-verify logic.
  - For Fix 2 (team color persistence), rollback to previous `saveRoster()` if any unexpected side effects occur (low risk).
  - For Fix 1 (admin screen), if needed restore from `git` history but keep it outside `lib/`.

---

## Timeline & Ownership (suggested)
- Day 1 (P0):
  - Remove/quarantine `admin_screen.dart`.
  - Add persistence call to `saveRoster()`.
  - Consolidate transition logic into `_maybeActivateShiftByClock()`; verify via quick manual test.
- Day 2 (P1):
  - Update or remove `updateBothRosters`; add comments for intended vs plan.
  - Add/extend unit tests for roster preservation and transition end.
- Day 3 (P2):
  - Optional: Standardize station keys via `Storage`.
  - Optional: Logging toggle.

---

## Acceptance Criteria (summary)
- No analyzer errors from admin screen.
- Team colors survive app restart after a roster save.
- Transition end behavior reliable and single-sourced.
- No usage of intended shift in live roster updates.
- Tests cover roster preserve + transition end scenarios.

---

## Notes for Future Maintainers
- “Intended shift” is a UI/heuristic helper; real shift activation is time/plan-driven.
- When making live roster changes during an active shift, always use:
  - `setTodayPlan(lunch, dinner);`
  - `updateActiveRoster(currentShiftRoster, preserveExistingCounts: shiftActive);`
- If adding new persistence domains, prefer `Storage.*Box` for namespacing and backup consistency.

---

## Appendix: File References
- `lib/app_state.dart`
  - `_maybeActivateShiftByClock()` – authoritative transition handling (keep here)
  - `_startTicker()` – call `_maybeActivateShiftByClock()` and housekeeping; avoid duplicate transition logic
  - `updateActiveRoster(...)` – correct preservation behavior during active shifts
  - `updateBothRosters(...)` – deprecate/adjust/remove
- `lib/screens/update_roster_screen.dart`
  - `saveRoster()` – add `await app.save()` to persist server team colors
- `lib/screens/clean_admin_screen.dart`
  - Primary admin screen route `/admin`
- `lib/screens/admin_screen.dart`
  - Corrupted/unused; remove, quarantine, or exclude
- `lib/storage.dart`
  - SharedPreferences wrapper used by most persistence logic
