# JuliaFlow product spec

Version 1.0 · 2026-11-11 · Owner: Akshay (Gravelaw) · Status: **approved direction, not yet implemented**

This file is the single canonical product spec. It replaces BRD v0.5.0
(`business-requirements-v0.3.0.md`), `Plan.md`, `docs/TODO.md`,
`docs/risk-register.md`, `docs/product-roadmap.md` and the earlier BRDs, which
move to `docs/archive/2026-11-11-pre-product-spec/`. Detailed workflows live in
the [persona sheets](personas/). Work is tracked in GitHub Issues and the
GitHub Project for this repository; Linear is retired.

## 1. Problem and wedge

Data scientists who want speed and reproducibility end up with notebooks:
fast to start, hard to reproduce, easy to leak test data into, and slow on
large tables in Python. Visual tools (KNIME, Orange, Dataiku) are
reproducible, but they hide the code and are not built on Julia.

**Wedge:** a local, visual workbench for tabular machine learning that is
fast on laptop-sized data (up to 1 GB / 10 M rows), enforces correct
validation by construction, and exports every workflow as a plain Julia
script that reproduces the result without the app.

## 2. Primary user and positioning

| | |
| --- | --- |
| Primary persona | [Applied data scientist](personas/applied-data-scientist.md): knows ML, can read code, wants a faster, safer path from CSV to a validated model and predictions. |
| Second persona (Phase 2) | [Domain data scientist](personas/domain-data-scientist.md): grouped or sequential data (wells, patients, sensors), where row-random splits give wrong scores. |
| Not targeted now | Non-coding analysts, MLOps teams, data engineers. Their needs return only after the primary journey ships. |

| Alternative | Why a user would pick JuliaFlow instead |
| --- | --- |
| Jupyter / Pluto + MLJ | Same Julia engine, but with leakage-safe splits, typed schema roles and experiment comparison built in; export keeps the code path. |
| KNIME / Orange | Code is a first-class export, not hidden; Julia speed on 10 M rows; no Java or Python stack. |
| Dataiku / cloud AutoML | Fully local and offline, free, and no data leaves the machine. |

## 3. MVP journey

One journey, end to end, on one laptop with no network:

1. **Create project** from a template: binary classification or regression.
2. **Import** local CSV or Parquet files as train, optional validation, and optional test/scoring data.
3. **Map roles**: target, id, feature, ignore, group. Fix inferred types.
4. **Profile**: per-column statistics, missing values, distributions and a target-leakage warning list.
5. **Prepare**: missing-value imputation, categorical encoding and numeric scaling, fitted on training rows only.
6. **Split**: random, stratified or grouped k-fold, with the test set locked until final evaluation.
7. **Train and compare**: at least a linear/logistic baseline and one gradient-boosted tree model, with manual or grid tuning on validation folds only.
8. **Evaluate once** on the locked test set, then show metrics and explanations computed from the fitted model.
9. **Predict and export**: a prediction CSV that matches an optional output contract (columns and id coverage).
10. **Export the workflow** as a Julia project (`Project.toml` + script) that reproduces step 9.

**MVP done means** the Titanic and House Prices acceptance runs in the
[applied data scientist sheet](personas/applied-data-scientist.md) pass on the
reference machine, within the NFR targets below, with no fixture or demo data.

## 4. Functional requirements

Each requirement is written as Given / When / Then. The ID prefix is `PR-`.
The old `JF-*` IDs are mapped in [§10](#10-mapping-from-brd-v050).

| ID | Requirement |
| --- | --- |
| PR-01 Project | Given no project, when the user picks a template and names a project, then a project folder is created under an approved root with a TOML manifest, and it reopens after an app restart. |
| PR-02 Import | Given a CSV or Parquet file under an approved root, when the user imports it, then every row is read (no row cap), a SHA-256 checksum and row count are recorded, and paths outside approved roots or through symlinks/junctions are rejected with a reason. |
| PR-03 Roles and types | Given an imported table, when the user sets target, id, feature, ignore and group roles or changes a column type, then the change is saved in the project, invalid casts are listed with sample rows, and the target can never also be a feature. |
| PR-04 Profile | Given a table, when the user opens Profile, then per-column count, missing %, unique count, min/max/mean/quantiles and a histogram or top-k bar are shown from the full data, and each chart has a table alternative. |
| PR-05 Leakage warnings | Given a target, when profiling runs, then columns that are near-duplicates of the target, ids correlated with the target, and columns with values only in test rows are flagged with the evidence. |
| PR-06 Preparation | Given a preparation step (impute, encode, scale), when it is applied, then its parameters are learned from training rows only, stored with the step, and reused unchanged on validation, test and scoring rows. |
| PR-07 Splits | Given a split strategy (random, stratified, grouped k-fold), when the user creates it, then assignments are fixed with a seed and a checksum, a group never spans train and validation, and changing the source data creates a new split. |
| PR-08 Test lock | Given a locked test set, when any tuning or model selection runs, then test rows are not read; the test set is unlocked only by an explicit "final evaluation" action, which is recorded. |
| PR-09 Training | Given a split and a prepared table, when the user trains a model, then MLJ fits it on CPU, the run records data checksum, split id, hyperparameters, seed, package versions, duration and peak memory, and the run can be cancelled. |
| PR-10 Models | The MVP supports linear and ridge regression, logistic regression and gradient-boosted trees (EvoTrees). Other MLJ models are shown as unavailable with a reason. |
| PR-11 Tuning | Given a model and a search space, when manual or grid tuning runs, then each trial is scored on validation folds only and listed in a trial table, and the best trial can be promoted. |
| PR-12 Compare | Given two or more runs on the same split, when the user compares them, then metrics, hyperparameters and durations are shown side by side; runs on different splits are marked not comparable. |
| PR-13 Explain | Given a fitted model, when the user opens Explain, then coefficients (linear models) or gain importance (trees) and permutation importance on validation data are computed from that model; the target is never listed as a feature. |
| PR-14 Predict and export | Given a promoted model and scoring data, when the user exports predictions, then a CSV is written that passes the optional output contract (required columns, one row per id, no missing ids). |
| PR-15 Reproducible export | Given a project, when the user exports it, then a folder with `Project.toml`, a Julia script and data checksums is written; running the script in a clean Julia environment reproduces the prediction CSV (see NFR-07). |
| PR-16 Honest states | Every screen shows loading, empty, error and unsupported states with a reason and a next action; no demo or fixture data appears in a real project. |

## 5. Non-functional requirements

Reference machine: 16 GB RAM, 8 CPU cores, SSD, no GPU, Windows 11 or Ubuntu
24.04. Targets are acceptance thresholds, measured and published with the
data shape and cold/warm state.

| ID | Requirement | Target |
| --- | --- | --- |
| NFR-01 Data envelope | Largest supported table | 1 GB CSV or Parquet, 10 M rows × 50 columns, in memory |
| NFR-02 Import speed | Import + checksum of 1 GB CSV | ≤ 60 s warm |
| NFR-03 Profile speed | Full profile of 10 M × 50 | ≤ 60 s warm |
| NFR-04 Interaction | Preview, role change, chart redraw | ≤ 2 s on a 10 k-row sample |
| NFR-05 Cold start | App start to usable Explorer after install | ≤ 30 s (precompiled system image) |
| NFR-06 Training | Logistic regression on 10 M × 50 | ≤ 5 min |
| NFR-07 Reproducibility | Exported script vs app predictions, same versions | identical for deterministic models; metrics within 1e-9 relative |
| NFR-08 Memory | Peak RSS during NFR-01 workload | ≤ 12 GB, with a clear error before the OS kills the process |
| NFR-09 Offline | Network access after install | none required; no telemetry |
| NFR-10 Accessibility | Core journey | keyboard-only operable; WCAG 2.1 AA contrast; charts have tables |

## 6. Non-goals and deferred work

Non-goals (not planned): cloud execution, accounts or sync; Kubernetes,
ArgoCD or MinIO deployment; streaming data; public extension marketplace;
promising GPU speedups for arbitrary Julia code.

Deferred (on the roadmap, not in the MVP):

- GPU acceleration (CUDA.jl, KernelAbstractions) and the Reactant compiler: Phase 3, as a measured differentiator, never a release gate.
- Data larger than memory (DuckDB / out-of-core).
- Models, Deploy and Monitor routes: registry, local endpoints, drift.
- PostgreSQL multi-user metadata and RBAC; extensions Hub.
- Packaged Windows EXE and Docker image; the MVP runs from the repository.
- Non-coding analyst guidance mode.

## 7. Architecture constraints

- Frontend: React + TypeScript in `apps/frontend`; nine-route shell kept, with only Explorer, Data, Transform, Visualize, ML Studio and Settings active in the MVP.
- Backend: Julia gateway in `services/api-gateway` only composes, routes, authorizes, audits and maps errors; product logic lives in Julia modules.
- Contracts first: a payload change updates `packages/contracts` (TypeScript + OpenAPI), the Julia mapping, fixtures and tests together.
- Data between steps is Arrow IPC; project and pipeline state is TOML that round-trips.
- Local I/O: approved roots, real-path confinement, symlink/junction policy, checksums and redaction.
- CPU is the only required compute path. Any later GPU path must report the actual device and fall back to CPU with a reason.
- Release and local-appliance modes never substitute demo or fixture data for missing state.

## 8. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Julia cold start feels slow | Users quit before the first result | Ship a precompiled system image; measure NFR-05 in CI |
| Current CSV path caps at 1,000 rows | MVP journey impossible | First Phase 1 item; Arrow-backed full-file ingestion |
| Hardcoded explainability (target listed as top feature) | Wrong conclusions; trust loss | Replace with PR-13 computed explanations; test that the target never appears |
| Large single files (gateway ~8 k lines, `runtests.jl` ~8 k lines) | Slow change, merge pain | Split by module while touching each area; no big-bang refactor |
| Solo developer bandwidth | Scope creep stalls the MVP | Only items in §3 and §4 enter Phase 1; everything else waits |
| Hosted CI cost | Slow feedback | Local CI through EasyCI; hosted CI runs only the release gate |
| Dependency advisories (vitest, smol-toml) | Security exposure in dev tooling | Track as GitHub issues; update with Dependabot PRs |

## 9. Roadmap

Phases are ordered by dependency, not dated.

| Phase | Scope | Exit |
| --- | --- | --- |
| 0 Reset | This spec; lean governance; Linear → GitHub Project migration | Spec merged; backlog lives in GitHub |
| 1 Data core | PR-01–PR-07: full-file CSV/Parquet import, roles/types, profile, leakage warnings, train-only preparation, splits | Titanic and House Prices data load, profile and split within NFR-01–04 |
| 2 Model core | PR-08–PR-16: test lock, training, tuning, compare, explain, predict, export | MVP done (§3) on the reference machine |
| 3 Differentiators | Domain persona (grouped/sequential), GPU paths with measured benefit, system-image packaging | Wellbore acceptance run; published CPU vs GPU numbers |
| 4 Lifecycle | Models, Deploy, Monitor routes; installers | Defined when Phase 2 ships |

## 10. Mapping from BRD v0.5.0

| BRD v0.5.0 | New home |
| --- | --- |
| JF-LOC-001/002/003 | PR-01, PR-02, NFR-09, §7 |
| JF-LOC-004 (Hub) | Deferred |
| JF-REP-001 | PR-15, NFR-07 (backup/migration deferred) |
| JF-EXP-001 | PR-13 |
| JF-UX-001–005 | PR-16, NFR-10, §7 (six active routes) |
| JF-DS-001 | PR-02, NFR-01–03 |
| JF-DS-002 | PR-06, PR-07, PR-08 |
| JF-DS-003 | PR-06 |
| JF-ML-001 | Deferred (Phase 4) |
| JF-HW-001/002, JF-RT-001–005, JF-ACC-001–005, JF-PERF-001 | Deferred (Phase 3); RT-003 memory safety → NFR-08 |
| JF-PKG-001/002 | Deferred (Phase 3–4) |
| JF-COMP-001, JF-REL-001 | Retired |

## 11. Open decisions

1. Parquet in Phase 1 or Phase 2 (adds a dependency; CSV alone meets Titanic/House Prices).
2. Whether to ship the Julia system image in Phase 2 to meet NFR-05, or accept a slower first start until Phase 3.
3. Whether the second persona's template is wellbore (ROGII) or a simpler grouped dataset.
