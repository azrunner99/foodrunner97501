# Lunch → Dinner Transition

The lunch-to-dinner handoff used to be a ~80-line block buried inside the 30s
ticker with a "DO NOT MODIFY" warning and no tests. It is now:

1. Extracted into a single named method — **`AppState._maybeFinalizeLunchToDinner()`**
   (in `lib/app_state.dart`), called once per tick from `_startTicker()`.
2. Guarded by a characterization test — **`test/transition_logic_test.dart`** —
   which drives the real ticker under `fake_async` and asserts the behavior
   below. Run `flutter test` (or rely on CI) before and after any change here.

## Expected behavior (asserted by the test)

Given a day plan with lunch roster **L** and dinner roster **D**, at the end of
the transition window (`plan.transitionEndMinutes`):

| Server group | Membership | At dinner start |
|---|---|---|
| Lunch-only | in L, not in D | removed from all counters |
| Both-shift | in L **and** D | counts reset to 0 |
| Dinner-only | in D, not in L | counts accumulated during the window are **preserved** |

After the handoff, `workingServerIds` equals the dinner roster, `shiftType` is
`Dinner`, and `activeRosterView` is `dinner`.

## Why order matters

Dinner-only counts are backed up **before** any clearing and restored **after**
the dinner shift starts, otherwise `_beginShift(preserveCounts: true)` and the
both-shift reset would wipe them. The numbered steps in
`_maybeFinalizeLunchToDinner()` document this ordering.

## If you change the transition

- Edit `_maybeFinalizeLunchToDinner()` (not the ticker).
- Keep `test/transition_logic_test.dart` green; if behavior is intentionally
  changing, update the test's assertions in the same commit so the intent is
  recorded.
