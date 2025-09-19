# Server Performance Systems – Optimization Plan

Goal
- Improve Server Performance screen responsiveness and correctness without regressions.
- Keep changes incremental, observable, and easy to roll back.

Branching and safety
- Branch: fix/perf-housekeeping (small commits, no behavior change first).
- Feature flags for new logic (default off).
- Validate with flutter analyze/test on each commit.

Targets
1) Replace direct AppState() constructions with injected provider state
   - Why: Prevent stale/duplicate state and reduce memory churn.
   - Where:
     - `lib/utils/data_validation_engine.dart`
     - `lib/utils/performance_gamification_engine.dart` (all usages incl. _getRecentPerformanceData)
   - Approach: Pass AppState via constructor/params; avoid new AppState() inside utilities.

2) Wire business data parameter into workload analysis
   - File: `lib/utils/performance_analyzer.dart`
   - Fix: Use provided business context when calculating workload splits.

3) Replace placeholder analytics in performance and gamification
   - Files:
     - `lib/utils/performance_analyzer.dart` (_analyzePerformanceByWorkload)
     - `lib/utils/performance_gamification_engine.dart` (_calculateRankChange, _getRecentAchievements)
   - Add: Minimal real logic gated by:
     - const bool kEnableAdvancedWorkloadAnalysis = false;
     - const bool kEnableGamificationEnhancements = false;

4) Optional offloading for heavy analysis
   - Files:
     - `lib/utils/data_validation_engine.dart`
     - `lib/utils/integrity_analyzer.dart` (as used by server_dashboard_screen)
   - Plan: Provide compute() offload paths behind:
     - const bool kOffloadHeavyAnalysis = false;
   - Default remains on main isolate.

5) Docs alignment
   - Update `docs/technical-architecture.md` to reflect current NPSProvider usage.

Verification checklist
- flutter analyze: no errors/warnings introduced.
- flutter test: all green; add unit tests for new analytics branches.
- Manual checks on Server Performance screen:
  - Loads quickly; no UI jank on initial render.
  - Leaderboard and workload sections reflect non-placeholder numbers when feature flags are on.
- Large dataset smoke test (backup/restore round-trip; measure frame times).

Risk and rollback
- All new behavior behind flags; can disable instantly.
- Each step is separate commit; revert individually if needed.

Deliverables
- Refactored utilities with injected state
- Implemented real analytics under flags
- Updated docs
- Unit tests covering new code paths

Out of scope (for now)
- Network/cloud sync
- Persistent telemetry/metrics
- UI redesign beyond data correctness

Notes
- Keep build artifacts (build/) out of git; publish APK via Releases instead of committing binaries.
