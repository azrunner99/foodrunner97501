# Food Runs Counter / Server Performance Engine

An operational Flutter application for tracking server food runs, shift activity, and translating multi‑source operational + guest feedback data into a transparent composite performance score.

## High Level Features
* Real‑time shift run tracking with roster transitions (lunch → dinner) and preservation of dinner‑only counts
* Monthly business data entry (sales, guest counts) feeding efficiency metrics
* NPS (Net Promoter Style) server feedback ingestion with rolling + snapshot metrics
* Phase 2 transparent performance scoring engine (NPS, Sales Ability, Food Running) with adaptive weight redistribution
* Low‑volume smoothing + confidence shrink to prevent volatile outliers
* Dynamic average check baseline (peer‑excluded) with caching & batch API
* Gamification layer (XP, milestones, shift transitions) with audit/debug logging

## Performance Scoring (Phase 2)
The composite performance score blends three components then applies an experience factor:

| Component | Default Weight | Description |
|-----------|----------------|-------------|
| NPS / Guest Perception | 50% | Rolling 3‑month (80%) + 1‑month (20%) with trend multiplier and low sample smoothing |
| Sales Ability | 30% | Average check vs dynamic restaurant baseline (focal server excluded) with piecewise mapping & low‑volume confidence shrink |
| Food Running | 20% | Complexity‑adjusted runs, efficiency (runs / guest), and consistency (variance based) |

Adaptive Weight Redistribution:
* 0 months of NPS data → NPS weight 0%, Sales 60%, Food 40%
* 1–2 months of NPS → NPS weight reduced linearly but not below 35%; difference redistributed evenly to Sales & Food

Smoothing & Confidence:
* NPS: If <2 months or <30 recent responses, blend toward neutral (50) using strength proportional to response volume
* Sales Ability: Two‑stage shrink—(a) confidence by check volume up to 40 checks, (b) extra dampening if <15 checks

Experience Factor (0.60–1.00): Non‑linear tenure curve (first 6 months staged plateaus) with slight bonus for ≥3 NPS months and guard for new/no‑data hires.

Exact Reconstruction: Final score = (NPS*w1 + Sales*w2 + Food*w3) * experienceFactor. All intermediate values (+ weights & experienceFactor) are exposed on `ServerPerformanceData` for transparency.

Detailed algorithm documentation lives in `docs/performance_scoring.md`.

## Key Files
| File | Purpose |
|------|---------|
| `lib/utils/performance_calculator.dart` | Core scoring algorithms, baseline cache, batch API |
| `lib/models/performance_models.dart` | Data models including transparency fields |
| `lib/screens/server_performance_screen.dart` | UI surface for rankings and component display |
| `test/performance_transparency_test.dart` | Validates component exposure & weight redistribution |
| `test/performance_smoothing_test.dart` | Verifies smoothing + exact reconstruction |

## Batch & Caching
`PerformanceCalculator.calculateBatchPerformance` reuses a cached restaurant baseline average check keyed by business totals + NPS history length, reducing repeated denominator recomputation in multi‑server evaluations.

## Upcoming (Planned)
* Timeframe‑aligned NPS slice refinement (strictly within selected window)
* Deterministic ranking tie‑breakers (score desc, experienceFactor desc, serverId asc)
* Zero‑run guard (classification + neutral floor or exclusion)
* ID normalization (originalId vs id) in all analytic joins

## Development / Testing
Run static analysis + tests (PowerShell):
```
flutter analyze ; flutter test -r compact
```

## Contributing
Internal project; follow `DEV_CHECKLIST_with_agents.md` and semantic commit guidelines in `COMMIT_MESSAGE.md`.

## License
Internal / proprietary (no external distribution declared).
