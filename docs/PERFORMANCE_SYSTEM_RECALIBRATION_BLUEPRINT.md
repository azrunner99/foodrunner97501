# 🚀 Performance System Recalibration Blueprint

> Goal: Increase separation between truly high and low performing servers, eliminate neutral inflation from missing data, and establish resilient, explainable scoring with progressive rollout and safety nets.

## 1. Guiding Principles
- Fairness: Missing data should never look average.
- Transparency: Every score decomposable into auditable components.
- Progressiveness: Reward sustained improvement; expose stagnation / decay.
- Data Quality First: Scoring confidence proportional to input completeness.
- Reversible: Each phase can be rolled back independently (feature flags).

## 2. Current Pain Points (Confirmed)
| Issue | Impact | Priority |
|-------|--------|----------|
| Neutral 50 defaults for NPS & Sales | Mid-pack clustering | P0 |
| Blank / zero months (e.g., Sept) included | Drags high performers artificially | P0 |
| Consistency = 100 with <2 shifts | Sparse users appear stable | P0 |
| Experience factor dampens upside early | Understates breakout performers | P1 |
| Normalization pivot at 50 (expectedMin→50) | Compresses distribution | P1 |
| Sales ability fallback too generous | Hides weak contribution | P1 |
| Heavy NPS weight with sparse data | Distorts balance | P1 |
| No penalty for inactivity | Low effort ≈ mid effort | P2 |
| All-time reused each month | Flattens dynamics | P2 |
| Trend factor diluted by neutral inserts | Under-rewards improvement | P2 |

## 3. Phase Overview
| Phase | Name | Core Outcomes | Flag Name |
|-------|------|---------------|-----------|
| 1 | Data Hygiene & Safeguards | Exclude blank months, add data quality tags, stop creating NPSData for empty reports | `perf_v2_data_hygiene` |
| 2 | Baseline & Fallback Reform | Change neutral defaults → penalized / redistributed; adjust normalization floor | `perf_v2_baseline` |
| 3 | Differentiation Mechanics | Activity penalty, percentile stretch, consistency floor logic | `perf_v2_differentiation` |
| 4 | Temporal Derivation Layer | Derive monthly sales/check deltas; decay stale data | `perf_v2_temporal` |
| 5 | Adaptive Weighting & Confidence | Dynamic weights based on data completeness & recency | `perf_v2_adaptive_weights` |
| 6 | Monitoring & Telemetry | Instrument component outputs, distribution drift alerts | `perf_v2_telemetry` |
| 7 | Rollout & Reconciliation | Dual scoring display, migration notices, docs | `perf_v2_rollout` |

## 4. Phase Detail
### Phase 1: Data Hygiene & Safeguards (P0)
**Objectives**:
- Skip zeroed monthly report rows (treat as missing).
- Do not generate NPSData entries when allTimeSales + allTimeChecks == 0.
- Introduce Data Quality classification per server-month:
  - `complete` (NPS + sales + shifts ≥ threshold)
  - `partial` (some components missing)
  - `sparse` (below shift or feedback threshold)
  - `missing`
- Attach quality badge & explanatory tooltip in performance screen.

**Acceptance Criteria**:
- Blank September no longer influences 3‑month averages.
- Servers with 0 valid months show “Insufficient Data” messaging.
- Added `dataQuality` field to intermediate performance object.

**Success Metrics**:
- Reduction in standard deviation change after exclusion < 10% (avoid overvolatility).
- At least 1 category flagged `sparse` if shifts < threshold.

### Phase 2: Baseline & Fallback Reform (P0/P1)
**Changes**:
- Replace NPS fallback 50 → 40 (mild penalty for absence) OR weight redistribution + explicit `NPS Missing` flag.
- Sales fallback: 50 → Computed from cohort median * 0.85 OR mark as neutral but reduce weight.
- Normalization: expectedMin maps to 30 (not 50); expectedMax to 90 (values can exceed → asymptotic >90).
- Consistency: if shifts < 3 → cap consistency contribution at 60.

**Success Metrics**:
- Increase score spread (IQR) by ≥ 25%.
- Correlation between runs/shift and final score increases vs baseline.

### Phase 3: Differentiation Mechanics
**Additions**:
- Inactivity penalty: `activityFactor = min(1.0, shiftsWorked / targetShifts)`; multiply final.
- Tail stretch: post-score transform `score' = 50 + 1.15*(score - 50)` clipped 0–100.
- Consistency volatility guard: servers with extremely high variance flagged.

**Success Metrics**:
- Bottom decile separation: difference between 10th and 25th percentile increases ≥ 15%.

### Phase 4: Temporal Derivation Layer
**Additions**:
- Derive monthly deltas: sales, checks from cumulative history.
- Mark `resetDetected` if negative delta.
- Recency decay: months older than 3 apply 0.85 weight; >6 drop or compress.

**Success Metrics**:
- Improvement month-over-month correlates positively (ρ > 0.4) with score deltas.

### Phase 5: Adaptive Weighting & Confidence
**Mechanics**:
- Compute `dataConfidence` = weighted completeness index (NPS coverage, shift count density, sales delta continuity).
- Blend weights: if confidence < 0.5 reduce NPS weight, increase food running.
- Display confidence bar.

### Phase 6: Monitoring & Telemetry
**Instrumentation**:
- Log structured JSON: per server component scores, inputs, quality flags.
- Distribution monitor: alert if std dev < threshold or > 2× baseline.

### Phase 7: Rollout & Reconciliation
**UI**:
- Dual display: `Current Score | New Score (beta)`.
- Tooltip: “Why did my score change?” linking to docs.
- Final migration: retire old path after 2 stable cycles.

## 5. Data Model Adjustments
| Field | Add / Change | Purpose |
|-------|--------------|---------|
| `ServerPerformanceData.dataQuality` | Add | Classification string |
| `ServerPerformanceData.dataConfidence` | Add (0–1) | Adaptive weighting |
| `MonthlyDerivedMetrics` (new) | Add | Holds per-month deltas & flags |
| `PerformanceComponentBreakdown` | Add | For analytics & telemetry |

## 6. Flags & Rollback
- Each phase gated by a boolean in a central `PerformanceFlags` service.
- Rollback strategy: disable flag → reverts to previous stable transformation layer.
- Provide migration script to purge invalid derived month rows if spec changes.

## 7. Testing Strategy
| Layer | Test Types |
|-------|------------|
| Hygiene | Blank month exclusion, negative delta clamp |
| Baseline | Fallback scoring vs cohort distribution |
| Differentiation | Activity penalty & tail stretch invariants |
| Temporal | Delta correctness & reset detection |
| Adaptive | Weight shifts under low confidence scenarios |
| Telemetry | JSON schema validity + volume bounding |

## 8. Metrics Dashboard (Planned KPIs)
- Score IQR & std dev trend
- Top vs median vs bottom decile separation
- Data completeness coverage %
- Correlation (runs/shift → final score)
- % servers with missing NPS after 30 days
- Confidence-weight distribution histogram

## 9. Risk & Mitigation
| Risk | Mitigation |
|------|------------|
| Over-penalizing new hires | Floor experience multiplier after changes |
| Score volatility | Introduce moving average view toggle |
| User confusion | Dual-score period + contextual tooltips |
| Data resets | Detect negative deltas & quarantine month |
| Telemetry bloat | Sampling + size caps |

## 10. Rollout Timeline (Indicative)
Week 1: Phase 1
Week 2: Phase 2
Week 3: Phase 3 + start Phase 4 derivation indexing
Week 4: Phase 4 completion + Phase 5 adaptive weights (beta)
Week 5: Phase 6 instrumentation
Week 6: Phase 7 dual display → full cutover decision

## 11. Acceptance Gate for Full Cutover
- ≥ 95% servers classified (not missing)
- Spread (P90 − P10) improved ≥ 20% vs baseline
- Support queries < 5% of active users (stability signal)
- No regression in primary engagement metrics

## 12. Immediate Kickoff Checklist (Phase 1)
- [ ] Add feature flag registry skeleton
- [ ] Guard NPSData creation on non-zero checks OR sales
- [ ] Tag dataQuality at load time
- [ ] Expose dataQuality in performance screen (badge placeholder)
- [ ] Log exclusion counts for blank months

---
**Ready for Phase 1 implementation when approved.**

> Once you confirm, we proceed with adding the flag scaffolding and Phase 1 hygiene changes.

## 13. Agent Escalation & Handoff Guidance
This section defines when the current generalist implementation agent should notify you to consider switching to a more specialized agent (e.g., advanced data science modeling, UX polishing, large‑scale telemetry optimization). Triggers are grouped by category; once any HIGH trigger is met, I will explicitly recommend escalation before proceeding further.

### A. Data Modeling & Statistical Rigor
Escalate if:
- (HIGH) You require statistically validated confidence intervals, bootstrapped variance estimates, or hypothesis testing on score distribution shifts (e.g., p-values, effect sizes) prior to rollout.
- (HIGH) Adaptive weighting needs Bayesian updating or hierarchical modeling (beyond deterministic heuristics specified here).
- (MEDIUM) Desire to introduce predictive modeling (e.g., forecasting server performance trajectories) or anomaly detection using ML.

### B. Telemetry & Observability
Escalate if:
- (HIGH) Need scalable ingestion pipeline (stream processing, external APM integration) instead of local JSON logging.
- (MEDIUM) Require automated drift detection with alert thresholds tuned via historical backtesting.

### C. UI / UX Productization
Escalate if:
- (HIGH) You want a multi-step in‑app migration wizard or progressive education modals for users about score changes.
- (MEDIUM) Advanced data visualizations (interactive percentile bands, violin plots) beyond current widget set are requested.

### D. Performance & Platform Concerns
Escalate if:
- (HIGH) Score computation latency exceeds 200ms per server consistently under production load and needs algorithmic optimization or concurrency strategy.
- (MEDIUM) Memory footprint of telemetry buffers exceeds 5 MB per session and requires streaming or chunked persistence design.

### E. Governance & Audit Requirements
Escalate if:
- (HIGH) External auditors require immutable event logs with hash chaining or cryptographic attestations.
- (MEDIUM) Need role-based access differentiation for raw vs derived performance components.

### F. Decision Support & Coaching Automation
Escalate if:
- (HIGH) You intend to auto-generate individualized coaching plans using LLM or ML content synthesis from performance deltas.
- (MEDIUM) Need natural language query over historical performance metrics (semantic search / vector indexing).

### G. Multi-Location / Multi-Tenant Scaling
Escalate if:
- (HIGH) Plan to aggregate and benchmark across multiple restaurants with cross-entity normalization strategies.
- (MEDIUM) Need shard-aware ID generation or distributed caching for performance computations.

### Handoff Package (What I Will Prepare Before Escalation)
If escalation is triggered, I will produce:
1. Current flag states and rollout matrix (phase → enabled? → date)
2. Data schema diff (original vs augmented fields, with sample JSON)
3. Distribution snapshots (IQR, P10/P50/P90, std dev) pre/post last phase
4. Known caveats / technical debt list (with priority & impact)
5. Suggested specialized agent profile (e.g., “Statistical modeling & experimentation”)

### Non-Escalation Assurance
If none of the above triggers are met, implementation continues locally with deterministic heuristics, feature flags, and reversible changes as defined. I will re-scan criteria at each phase boundary and before enabling any new weight adaptation logic.

---
*Agent escalation guidance appended (v1).* 
