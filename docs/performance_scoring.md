# Performance Scoring Engine (Phase 2)

This document details the transparent composite scoring system implemented in `lib/utils/performance_calculator.dart`.

## Overview
Each server receives a composite 0–100 score derived from three components plus an experience factor multiplier:

```
finalScore = (npsScore * npsWeight + salesAbilityScore * salesWeight + foodRunningScore * foodRunningWeight) * experienceFactor
```

All intermediate values are exposed on `ServerPerformanceData`:
- npsComponentScore
- salesAbilityScore
- foodRunningScore
- averageCheck
- npsWeight / salesWeight / foodRunningWeight
- experienceFactor

This enables exact reconstruction for auditing and UI transparency.

## Component Details
### 1. NPS / Guest Perception (Default 50%)
Inputs:
- Rolling 3‑month average (primary stability signal)
- 1‑month snapshot (recency signal)
- Trend multiplier (recent vs previous month differential)

Computation:
```
base = threeMonthAvg * 0.8 + oneMonthScore * 0.2
trendFactor = clamp(1 + (recent - previous)/200, 0.8, 1.2)
rawNpsScore = base * trendFactor
```

Low Sample Smoothing:
If fewer than 2 months of data or <30 recent responses (approximated), blend toward neutral (50) with strength in [0.15, 0.6].
```
smoothed = 50 + (rawNpsScore - 50) * strength
```

### 2. Sales Ability (Default 30%)
Measures average check compared to a dynamic peer baseline.

Baseline Sources (priority order):
1. Period `MonthlyBusinessData` totals (sales / guestCount)
2. Aggregated all‑time NPS totals (excluding focal server)
3. Fallback neutral = 70

Average Check Source for Server:
- Prefer NPS all‑time totals (sales & checks) if available; else period business approximation

Piecewise Mapping (ratio = serverAvg / baseline):
- ratio <= 0.8 → 25
- 0.8..1.0 → 25..55
- 1.0..1.4 → 55..85
- 1.4..1.8 → 85..100
- >1.8 → 100

Low Volume Confidence Shrink:
```
confidence = clamp(checkVolume / 40, 0.2, 1.0)
score = 50 + (score - 50) * confidence
if (checkVolume < 15) score = 50 + (score - 50) * 0.6 (extra dampening)
```

### 3. Food Running (Default 20%)
Blends:
- Complexity-adjusted runs per shift (60%)
- Guest efficiency (runs per guest) (20%)
- Consistency (inverse variance) (20%)
Each sub-metric normalized around expected baselines.

### Weight Redistribution Rules
| Condition | NPS | Sales | Food |
|-----------|-----|-------|------|
| Default (>=3 NPS months) | 50% | 30% | 20% |
| 2 months NPS | 45% | 32.5% | 22.5% |
| 1 month NPS | 40% | 35% | 25% |
| 0 months NPS | 0% | 60% | 40% |

### Experience Factor (0.60–1.00)
Non-linear tenure curve with staged ramps:
- 0–30 days: 0.60 → 0.75
- 31–90 days: 0.75 → 0.90
- 91–180 days: 0.90 → 0.95
- 180+ days: 0.95 → 1.00 (slow approach)
Adjustments:
- +0.02 if >=3 NPS months
- −0.05 floor protection for <60 days & 0 NPS months

## Caching & Batch Processing
A simple in-memory map caches the restaurant baseline average check within a batch:
```
key = "<totalSales>:<totalGuests>|<npsHistoryLength>"
```
Used by `calculateBatchPerformance` to avoid recomputing aggregate baselines for each server.

## Data Hygiene
Feature flag `FeatureFlags.perfV2DataHygiene` allows skipping blank NPS months (zero sales & checks) to reduce misleading low-volume noise.

## Testing
Key Tests:
- `performance_transparency_test.dart` – verifies component fields present & weight redistribution logic
- `performance_smoothing_test.dart` – asserts smoothing behavior and exact reconstruction
- `performance_sales_ability_test.dart` – sales ability differentiation & low-volume penalties
- `performance_baseline_cache_test.dart` – validates batch baseline reuse consistency

## Planned Enhancements
- Timeframe-specific NPS slicing (strict window alignment)
- Deterministic ranking tie-breakers (score desc, experienceFactor desc, serverId asc)
- Zero-run guard (classification and optional exclusion)
- Server ID normalization (originalId vs derived id) across all joins

## Change Log Excerpt
Phase 2 introduced transparency fields + smoothing + dynamic baseline caching enabling stable, audit-friendly server performance evaluation.

---
Last updated: (auto) Phase 2 implementation session.
