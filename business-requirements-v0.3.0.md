# Low-Code Drag-and-Drop Data Science Toolkit (Julia Backend)

## Document Control
- **Date:** 2026-03-04
- **Owner:** Product / Data Platform
- **Version:** 0.3.0 (concept refresh: personas + GPU scope)

## 1. Purpose
Define business needs for a low-code, drag-and-drop Data Science toolkit that covers all phases of the CRISP-DM framework—business understanding, data understanding, data preparation, modeling, evaluation, and deployment. It pairs a visual web front end with a Julia-powered compute backend (CPU and GPU), enabling rapid, repeatable data ingestion, preparation, versioning, insight generation with visualization, algorithm implementation, clustering, model training (CPU/GPU), model versioning, model evaluation, and model deployment without heavy coding while preserving high-performance numerical workflows.

## 2. Goals & Outcomes
- Reduce time from business question to deployed, monitored (CPU/GPU) model from months to weeks.
- Make CRISP-DM workflows reproducible, auditable, and shareable across teams.
- Provide governed access and lineage while sustaining performance on wide/large datasets.
- Lower barrier for junior talent while empowering senior/principal data scientists with extensibility.

## 3. In Scope (aligned to CRISP-DM)
- **Business Understanding:** Project briefs, objectives, success metrics templates; linkage to downstream flows.
- **Data Understanding:** Connectors, schema inference, profiling, data quality checks, drift/bias screens.
- **Data Preparation:** Visual transformations, feature engineering nodes, sampling strategies, versioned datasets.
- **Modeling:** Algorithm blocks (classification/regression/clustering) with CPU/GPU execution paths, hyperparameter sweeps, feature selection, custom Julia code nodes.
- **Evaluation:** Holdout/cross-validation, metric dashboards, statistical tests, error analysis views, model cards.
- **Deployment:** Batch scoring flows, REST inference endpoints (CPU/GPU), exportable artifacts, rollout strategies (shadow/A-B), and scheduling.
- **Lifecycle Enablement:** Flow versioning, lineage, approvals, collaboration, CI/CD-friendly API, and artifact registry.

## 4. Out of Scope (v1)
- Deep learning serving at massive scale (multi-GPU/multi-node) beyond targeted GPU acceleration of supported blocks.
- Full-feature MLOps platform (feature store, online store) beyond read-only ingestion.
- Real-time sub-second streaming inference.

## 5. Personas (experience-banded)
- **Junior Data Scientist (1–3 yrs):** Needs guided CRISP-DM flows, strong defaults, and safety guardrails; limited infrastructure privileges.
- **Data Scientist (4–7 yrs):** Seeks fast iteration and reproducibility; mixes custom stats/ML blocks with low-code nodes; expects API hooks.
- **Senior Data Scientist (8–12 yrs):** Curates templates and policies; enforces governance; optimizes performance on larger datasets (CPU/GPU).
- **Principal / Staff DS (>12 yrs) or PhD Postdoc (~7 yrs, CS major, math minor):** Defines standards; demands extensibility, auditability, and compliance readiness for regulated domains; validates CPU/GPU architecture choices.

## 6. Persona-Based User Stories
- Junior DS: Start from a CRISP-DM wizard, profile data, fix issues, and produce a baseline model + report in one session.
- DS: Swap in a custom Julia modeling node, run cross-validation, and register the best model with metrics and lineage.
- Senior DS: Publish governed templates and enforce PII checks before flows can be scheduled or deployed.
- Principal/PhD: Review lineage, approvals, and signed artifacts before greenlighting production rollout.

## 7. Functional Requirements (CRISP-DM mapped)
- **Business Understanding**
  - Project brief templates with objectives, KPIs, constraints; tie to runs and reports.
  - Success-metric library with thresholding and alerting.
- **Data Understanding**
  - Connectors: S3/HTTPS upload, parquet/CSV, JDBC/ODBC (Postgres/Redshift/BigQuery).
  - Profiling: schema inference, type detection, null/unique/distribution stats, drift/bias screens.
  - Data quality rules with fail/flag actions and remediation suggestions.
- **Data Preparation**
  - Visual transforms: filter/aggregate/join/pivot/unpivot, missing handling, casting, scaling, window functions.
  - Feature engineering nodes (bucketization, encoding, text cleaning) and custom Julia transform blocks.
  - Dataset versioning with snapshots, diffs, and reproducibility metadata.
- **Modeling**
  - Algorithm blocks: logistic/linear regression, tree/boosting (CPU/GPU where available), random forest, k-means, PCA, basic time-series ARIMA/ETS; GPU-accelerated variants where supported.
  - Hyperparameter search (grid/random) with resource caps; resumable sweeps; resource selectors (CPU vs GPU).
  - Custom Julia model node (package allowlist) with code assist and unit-test stubs; optional GPU kernels.
- **Evaluation**
  - Train/validation/test splits, cross-validation; metric suites (accuracy/ROC-AUC/F1/RMSE/MAE/silhouette).
  - Error analysis: slices, confusion details, lift charts, calibration.
  - Model cards auto-generated with inputs, metrics, datasets, and caveats.
- **Deployment**
  - Batch scoring pipelines; REST/GRPC inference endpoint scaffolding with autoscaling hooks for CPU and GPU pools.
  - Rollout strategies: shadow, A/B with traffic splits, canary by time or segment.
  - Model registry with versioning, stage transitions (dev→staging→prod), hardware tags (CPU/GPU), and approval gates.
  - Scheduling (cron/API) for retraining and scoring; webhooks/notifications; hardware-aware queueing.
- **Collaboration & Governance**
  - Role-based access (admin/editor/viewer), inline comments, approvals, audit logs.
  - Managed palettes/templates; policy checks for PII and license compliance before publish.
  - Lineage graph across datasets, features, models, and deployments.
- **Observability**
  - Run logs/metrics/traces; data and prediction drift monitors; resource usage dashboards (CPU/GPU utilization, memory, VRAM).
  - Alerting to email/Slack/webhook with run status and drift signals.
- **Outputs & Reporting**
  - HTML/PDF reports, embeddable iframes, dataset/model artifact downloads.
  - API for CI/CD integration (trigger runs, fetch artifacts, promote models).

## 8. Non-Functional Requirements
- **Performance:** 10–50 GB batches; interactive previews <2s on samples; full runs <20m typical on CPU, faster on GPU-enabled flows; inference P95 <300ms for REST endpoints with GPU headroom for heavy models.
- **Scalability:** Horizontal scaling of Julia workers; mixed CPU/GPU worker pools; queue-backed dispatch; caching of intermediates.
- **Security & Compliance:** SSO (SAML/OIDC), RBAC, audit logs, encryption in transit/at rest, secrets via vault, optional data masking.
- **Reliability:** 99.5% monthly uptime; retries with checkpoints; deterministic runs via pinned environments.
- **Usability:** Accessible canvas (ARIA), keyboard shortcuts, undo/redo, tooltips, wizards, and starter templates per persona.
- **Portability:** Containerized deployment; on-prem or VPC; API-first design.

## 9. High-Level Architecture
- **Frontend:** Web app (React/Svelte) for canvas and CRISP-DM wizards; WebSockets for live status.
- **Backend API:** REST/GraphQL gateway; auth/RBAC; versioning; scheduling; registry endpoints.
- **Compute Layer:** Julia services executing DAGs via Dagger.jl (parallel/cached) across CPU and GPU worker pools; interacts with storage and metadata.
- **Storage:** Metadata: Postgres; Artifacts/Models: object storage; Cache: Redis; Registry tables for datasets/models (including hardware tags).
- **Observability:** Centralized logging/metrics/tracing; lineage service; drift monitors; GPU/CPU utilization exporters.

## 10. Recommended Julia Ecosystem
- API: Genie.jl or HTTP.jl + OpenAPI.jl; middleware via Plug; JSON3.jl.
- DAG/Compute: Dagger.jl; Distributed/Threads for scaling; KernelAbstractions.jl for portable GPU kernels.
- Data: DataFrames.jl, CSV.jl, Arrow.jl, Tables.jl; ODBC.jl/LibPQ.jl; AWS.jl/GoogleCloud.jl/AzureSDK.jl.
- Transforms/Stats/ML: Chain.jl/Pipes.jl, Statistics, StatsBase.jl, HypothesisTests.jl, Clustering.jl, MultivariateStats.jl, DecisionTree.jl/GLM.jl/XGBoost.jl (GPU support via XGBoost), MLJ.jl for model management, Flux.jl/Knet.jl for GPU-capable models where needed.
- GPU Enablement: CUDA.jl (NVIDIA), AMDGPU.jl (AMD), oneAPI.jl (Intel), Metal.jl (Apple) with Array abstractions; CuArrays/ROCArray backends; NNlib.jl for GPU ops.
- Visualization/Reporting: Makie.jl, AlgebraOfGraphics.jl, PlotlyJS.jl, Weave.jl/Franklin.jl for report rendering.
- Auth/Security: OAuth.jl/JWTs.jl; secrets via SimpleSecrets.jl or vault client.
- Scheduling: Clockwork.jl or Cron.jl; background tasks with Genie/HTTP servers.
- Observability: LoggingExtras.jl, OpenTelemetry.jl, Prometheus.jl; GPU telemetry exporters where available.
- QA: Test.jl, Aqua.jl, BenchmarkTools.jl.

## 11. Dependencies & Constraints
- Julia 1.11+; environments pinned via `Project.toml/Manifest.toml`; artifact mirrors for reproducibility.
- Browser support: evergreen Chrome/Edge/Firefox, Safari ≥17.
- Compliance targets: SOC 2 Type II readiness; GDPR-aligned data handling.

## 12. Success Metrics (initial)
- Median time to first CRISP-DM baseline (profile + model + report) < 60 minutes from new dataset.
- ≥60% of new DS projects initiated through the tool within 3 months of rollout.
- Model promotion success rate ≥ 95% after trial period.
- Data/model lineage coverage ≥ 90% of production flows.
- ≥30% of eligible training jobs use GPU paths with ≥2x speedup vs CPU baselines.

## 13. Risks & Mitigations
- **Performance on wide/long data:** Column pruning, pushdown filters, Arrow-based pipeline, sampling.
- **Custom code safety:** Package allowlist, resource limits, sandboxing, code review workflow.
- **Adoption:** Guided wizards, templates per persona, in-app tours, and export paths to BI/MLOps stacks.
- **Regulatory demands:** Strong audit logs, signed artifacts, and configurable retention.

## 14. Milestones (draft)
- M0 (Decision): Approve CRISP-DM scope and budget.
- M1 (8 weeks): CRISP-DM wizard + ingest/profile/prepare + basic modeling blocks + single connector (CPU path).
- M2 (16 weeks): Versioning, lineage, evaluation dashboards, three tier-1 connectors, PDF/HTML reporting; initial GPU-enabled training for supported models.
- M3 (24 weeks): Deployment endpoints (CPU/GPU), scheduling, registry, drift monitors, policy checks, marketplace preview.

## 15. Open Questions
- Which CRISP-DM templates to ship first per industry (e.g., churn, fraud, demand)?
- Required compliance artifacts (model cards, DPIA, SOC evidence) for pilot customers?
- Preferred deployment model for first pilots (managed vs. VPC)?
- Priority order for algorithm blocks (tree/boosting vs. linear vs. clustering vs. time-series)?
