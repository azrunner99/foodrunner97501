# Server Performance Screen Fix Blueprint

Date: 2025-09-18
Owner: TBD (you)
Status: Planned
Scope: Server Performance Screen (Rankings, Trends, Analytics, Charts) + PerformanceCalculator

## Goals
- Align displayed timeframe with the actual data used for calculations
- Ensure NPS + Sales data join is reliable for all servers
- Correct peer rankings and analytics derived from ordering
- Improve clarity of metrics (Shifts, Avg/Shift) and handle outliers
- Preserve desired 50/30/20 weight model and behavior with limited/no data

## Current Behavior (Summary)
- Timeframe filter applies to shift history, but NPS data uses saved monthly reports with all-time fields (sales/checks/nps)
- NPS join uses `originalId` for `NPSData.serverId`; UI lookups use `server.id`. Mismatched IDs cause missing NPS for some servers
- "Shifts" counts only shifts that have > 0 runs; not true shifts worked
- Peer analytics (rank, top/bottom performers) computed before list is sorted -> incorrect values
- Baseline scores (~7–8%) can appear for servers with 0 runs due to consistency and experience floors

## Issues & Fixes

### 1) Timeframe/Data Semantics Mismatch (High)
- Problem: UI says "Last 30 Days" but NPS-based Sales/Checks use all-time fields from monthly reports
- Options:
  - A. Update data sourcing to use period-specific fields when available (preferred)
  - B. If only all-time available, clearly label contributions as all-time and exempt them from timeframe filtering
- Plan A (preferred):
  - Extend monthly report schema / loader to include period-specific fields per month:
    - month_sales, month_table_count, month_nps_percentage
  - In `loadNPSHistory`, set `responseCount` from month_table_count, `categoryBreakdown['sales']` from month_sales, and NPS from month_nps_percentage
  - Only include months in the selected timeframe window for the calculation
- Acceptance:
  - Changing timeframe to 7/30/90 affects NPS checks/sales averages and the final score in a plausible way
  - “Last 30 Days” screen no longer reflects all-time data

### 2) NPS Server ID Join Mismatch (High)
- Problem: `NPSData.serverId = originalId ?? id` vs calculator filtering by `server.id`
- Fix:
  - Standardize on a single ID for joins. Options:
    - Prefer `originalId` everywhere when present; pass that into `calculateServerPerformance` calls
    - Or set `NPSData.serverId = server.id` consistently when generating history (and only use originalId to fetch data)
  - Add a small mapping helper to translate between IDs if needed
- Acceptance:
  - For a server that previously showed "No NPS data", we now see correct checks/sales and an NPS contribution in the score
  - Debug logs confirm matches for target server IDs

### 3) Peer Analytics / Ranking Order (Medium)
- Problem: `teamAnalytics.topPerformers`, `peerRanking` computed before sorting the `performanceDataList`
- Fix:
  - Move sorting before calculating analytics and peer analyses, or compute rank using scores directly (without relying on current order)
- Acceptance:
  - Peer ranking matches the visual ranking in the list
  - Top/bottom performers match the sorted list

### 4) “Shifts” Label Semantics (Medium)
- Problem: "Shifts" is really "shifts with runs recorded"
- Fix Options:
  - A. Relabel UI chip: "Active Shifts"
  - B. Track and display true shifts worked if available; otherwise show both (Active / Worked)
- Acceptance:
  - Users understand why a server can have Shifts: 0 with runs shown as 0, reducing confusion

### 5) Baseline Score for Zero-Run Servers (Medium)
- Problem: Consistency=100 (for <2 shifts) and experience floor (>=0.6) yields ~7–8% even for 0 runs/no data
- Options:
  - A. Special case: if totalFoodRuns==0 and no NPS/Sales, set final score to 0
  - B. Reduce consistency floor impact when total runs == 0
  - C. Lower experience floor in “no data” scenarios
- Acceptance:
  - Zero-run, no-data servers show a minimal or zero score in line with business expectations

### 6) Outlier Handling & Formatting (Low)
- Problem: Extremely large “Avg/Shift” values (e.g., 1202.0) can mislead
- Fix:
  - Cap display to a reasonable max (e.g., 200) and show a tooltip (or small warning icon) when capped
  - Drop trailing .0 when integer
- Acceptance:
  - Values look reasonable; outliers are clearly indicated, not misleading

### 7) Banner Messaging Consistency (Low)
- Problem: Banner suggests monthly entry is needed for accuracy, but NPS all-time can dominate
- Fix:
  - Update copy to explain that monthly data improves alignment with timeframe, and NPS reports enrich guest/sales accuracy
- Acceptance:
  - Users aren’t surprised when scores still compute with NPS present

## Implementation Plan

Phase 1: Correctness
1. Sort-then-analytics order fix in `server_performance_screen.dart`
2. ID join consistency in `loadNPSHistory` + calculator calls
3. Add debug logging around resolved IDs and matches

Phase 2: Data-timeframe alignment
4. Extend monthly report reader to prefer month-level fields (if present); fallback to all-time fields
5. Use timeframe window to filter NPS months included
6. Update sales/check derivation to use month values in the selected timeframe

Phase 3: Semantics & UX
7. Update “Shifts” label or show (Active/Worked) when possible
8. Apply display caps and integer formatting for Avg/Shift
9. Update banner copy for clarity

Phase 4: Scoring edge cases
10. Apply zero-run/no-data guard rule (if chosen)
11. Add unit tests for zero-run with/without NPS

## Acceptance Tests (Manual)
- Timeframe switch changes Sales ability and NPS contribution (if month data exists)
- A server with known monthly report shows correct checks/sales in logs and contributes to score
- Peer ranking in Analytics matches Rankings tab
- “Shifts” semantics are clear
- Zero-run server without NPS shows minimal/zero score (if rule adopted)
- Outlier Avg/Shift displays capped with indication; integers don’t show .0

## Unit/Widget Tests (Suggested)
- PerformanceCalculator: average check computation with month vs all-time data
- Weight redistribution with npsDataMonths=0 and <3
- Zero-run/no-data scoring rule
- Mapping function: `server.id` <-> `originalId`

## Rollback Plan
- Keep a feature flag for new timeframe-aligned NPS usage (e.g., `useMonthlyNpsForSalesChecks`)
- Quick revert to current logic if anomalies discovered

## Risks & Mitigations
- Missing monthly fields in older reports → fallback to all-time
- ID mapping inconsistencies → add mapping table + logs during transition
- Perceived score volatility after timeframe alignment → communicate change in release notes

## Milestones
- M1 (Day 1–2): ID join, ordering fix, logging
- M2 (Day 3–4): Monthly NPS fields + timeframe alignment
- M3 (Day 5): UI semantics, caps/formatting, copy updates
- M4 (Day 6): Edge-case scoring guard + tests

## Notes
- Keep a `DEBUG_PERF` flag to toggle verbose logs
- Document exact field names expected from monthly reports (month_sales, month_table_count, month_nps_percentage)
