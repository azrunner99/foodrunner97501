# BJ's Food Runs — Modernization & Stabilization Plan

_Last updated: 2026-06-08. Goal: stabilize a fragile, dormant Flutter app and
modernize it so it's safe and pleasant to extend. Driven by a deep-dive code
review + 2026 best-practices research._

---

## 1. Where the app stands today

- **Stack:** Flutter ~3.19 (early 2024) / Dart 3.3, Provider + a single
  `ChangeNotifier`. ~9,700 lines of Dart, 30 files.
- **Persistence:** All data is JSON blobs in `SharedPreferences`, local to one
  device. No backup, no sync.
- **State:** One 1,371-line `AppState` "god object" mixes UI state, business
  rules, time logic, and persistence.
- **Core risk area:** Lunch→Dinner shift transitions run inside a 30-second
  polling `Timer` with a 100-line "⚠️ DO NOT MODIFY" block and a separate
  `TRANSITION_PROTECTION.md` ritual. Most historical bugs live here.
- **Tests:** Effectively zero — the one transition test has its assertions
  commented out.

### Concrete defects found in review
| # | Issue | Severity |
|---|-------|----------|
| 1 | No backup → device loss = total data loss | High (latent) |
| 2 | Transition engine fragile, polling-based, "do not touch" | High |
| 3 | Duplicate `_savePartialShift()` nested inside `_beginShift()` (shadows class method, missing the lunch-roster filter) — dead/buggy code | High |
| 4 | `collection` imported but **not** declared in `pubspec.yaml` | Medium |
| 5 | `increment()` vs `incrementPizookie()` ~90% copy-paste | Medium |
| 6 | `AppState` 1,371 lines; `home_screen.dart` 2,177 lines | Medium |
| 7 | 43 `print('[DEBUG]…')` in production (some with broken `\\${}` escaping) | Medium |
| 8 | Tests are stubs; fragile core has no safety net | Medium |
| 9 | Two `ProfileBannerScreen` classes (`..._new.dart` abandoned); `backup foodrunning/` folder committed | Low |
| 10 | ~2 years behind on Flutter/Dart | Low |

---

## 2. Key technology decisions (2026 research → our choices)

### State management & architecture — **stay on Provider, break up the god object**
- Research consensus: **Riverpod** is the recommended default for *new* apps,
  but **Provider is not deprecated** (no deprecation notice on pub.dev; v6.1.5+)
  and is fine to keep. A full rewrite is unjustified.
- Flutter's official first-party architecture guide now recommends **layered
  MVVM**: UI (views + view-models) → domain → **data layer (repositories +
  services)**, and is explicitly state-package-agnostic (`ChangeNotifier` is
  endorsed).
- **Plan:** refactor incrementally — extract **repositories** for persistence,
  split `AppState` into feature-scoped notifiers (shift, roster, gamification,
  profiles), use `context.select`/`Selector` to shrink rebuilds. Optionally
  migrate notifier-by-notifier to Riverpod later. **No rewrite.**

### Local persistence — **migrate to Drift (SQLite)**
- Research: **Drift** is the 2025–2026 default for structured local data —
  actively maintained, compile-time type-safe queries, real query/relations,
  all platforms incl. web, first-class schema migrations. **Isar** (original)
  is abandoned (community fork only); **Hive v2** is unmaintained (successor
  `hive_ce`); **ObjectBox** is fastest but native-only/no web.
- **Plan:** move structured data (servers, shifts, profiles, day plans, tap
  logs) into **Drift**. One-time, transactional, version-flagged migration from
  the existing SharedPreferences JSON on first launch. Keep `shared_preferences`
  only for small flags/settings (and adopt `SharedPreferencesAsync`).

### Data durability — **export/import first, cloud later**
- Research: for a tiny single-author app whose real need is "don't lose data if
  I lose the phone," **manual JSON export/import to the OS share sheet / Drive**
  solves it with zero backend, zero free-tier caps, zero server ops. It also
  enables device-to-device transfer.
- Cloud is only worth it for *automatic* multi-device sync. If/when needed,
  **Firestore** is the lowest-effort managed choice (offline persistence on by
  default); **Supabase** lacks native offline + free projects pause after ~1
  week idle; **PocketBase** means running a server. **CloudKit** is Apple-only.
- **Plan:** ship **export/import** in this round. Defer cloud unless you decide
  you want hands-free sync.

### Testing — **inject a clock, characterize the core, don't chase %**
- Research: use **`package:clock`** (replace `DateTime.now()` → `clock.now()`,
  pin with `withClock(Clock.fixed(...))`) + **`package:fake_async`**
  (`fakeAsync((async) { async.elapse(Duration(seconds: 30)); })`) — FakeAsync
  auto-overrides the clock, so the 30s polling Timer becomes deterministic.
- Write **characterization tests** that pin *current* transition behavior
  before refactoring; prioritize fragile/critical logic over coverage %.
  Golden tests via **`alchemist`** (the `golden_toolkit` successor) are optional
  and low-priority here.

### Flutter/Dart upgrade — **3.19 → current stable, incrementally**
- Research: current stable is **Flutter 3.44 / Dart 3.12** (verify locally with
  `flutter --version`). Upgrade in steps, run **`dart fix --apply`** + `flutter
  analyze` + tests after each. Expect the **`Color.withOpacity()` →
  `withValues(alpha:)`** migration (deprecated in 3.27) and Material 3 default
  changes. Do this *after* the test safety net exists.

### CI/CD & lint — **GitHub Actions gate, keep flutter_lints (ratchet later)**
- Research: `subosito/flutter-action@v2` + `actions/checkout@v6`; run
  `dart format --output=none --set-exit-if-changed .` (NOT the removed `flutter
  format`), `flutter analyze`, `flutter test`, `flutter build`. Keep
  `flutter_lints` now; adopting `very_good_analysis` on a messy codebase floods
  errors — ratchet rules on after cleanup. Optional `lefthook` pre-commit.

### AI-assisted refactoring discipline
- Research consensus: **characterization tests before any refactor**, then
  **small single-intent PRs** gated by CI. Pitfalls to guard against:
  hallucinated APIs, silent behavior changes, over-eager large rewrites
  (AI code churn ~2× baseline). Rule: *no characterization tests → no refactor*
  of that area.

---

## 3. Phased roadmap

> Ordering principle: **build a safety net before touching the fragile core.**
> Phases are sequenced so each one is independently shippable and low-risk.

### Phase 0 — Quick wins & CI gate _(low risk, do first)_
- Add GitHub Actions: format check, `flutter analyze`, `flutter test`, build.
- Add `collection` to `pubspec.yaml`.
- Delete dead code: nested `_savePartialShift`, `profile_banner_screen_new.dart`,
  `lib/examples/`, `backup foodrunning/` folder.
- Replace/remove the 43 `print()` debug lines (guarded `debugPrint` or a logger);
  fix the broken `\\${}` escapes.
- **Exit criteria:** CI green on a clean tree; no behavior change.

### Phase 1 — Safety net around the fragile core _(no behavior change)_
- Introduce `package:clock`; route all `DateTime.now()` in `app_state.dart`
  through `clock.now()`.
- Write `fakeAsync` characterization tests pinning today's transition behavior
  (the scenarios in `TRANSITION_PROTECTION.md`: lunch-only removed, both-shift
  reset to 0, dinner-only preserved). Make the stubbed `transition_logic_test`
  real.
- **Exit criteria:** transition behavior is covered by passing tests.

### Phase 2 — Flutter/Dart upgrade
- Step 3.19 → … → 3.44; `dart fix --apply`, fix `withOpacity`/M3 deprecations.
- **Exit criteria:** builds on current stable; all Phase 1 tests still pass.

### Phase 3 — Refactor god object & transition engine _(guarded by Phase 1 tests)_
- Extract persistence into repositories; split `AppState` into feature notifiers.
- Redesign transitions as a **pure, deterministic state machine** (kill the
  fragile polling reliance); deduplicate `increment`/`incrementPizookie`.
- Split `home_screen.dart` into smaller widgets.
- **Exit criteria:** same test behavior, smaller files, transition doc retired.

### Phase 4 — Persistence migration to Drift
- Define Drift schema; one-time transactional migration from SharedPreferences.
- **Exit criteria:** app runs on Drift; migration verified on real exported data.

### Phase 5 — Data durability
- JSON export/import via share sheet (backup + device transfer).
- **Exit criteria:** can back up and restore all data off-device.

### Later / optional
- Stricter lints (`very_good_analysis`) ratcheted in; cloud sync (Firestore) if
  hands-free multi-device becomes a real need; new features.

---

## 4. Suggested first step
Phase 0 is pure upside and unblocks everything else (a CI gate makes every later
change safer). Recommend starting there, then Phase 1 before touching any
shift-transition logic.
