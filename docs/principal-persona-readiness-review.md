# Principal Persona Readiness Review

Date: 2026-06-21

## Review Structure

The review was run as a principal-reviewer program:

- Contract/API reviewer
- Julia gateway/runtime reviewer
- Frontend/UX workflow reviewer
- Data science/ML validity reviewer
- Security/local trust-boundary reviewer
- MLOps/model-ops reviewer
- Principal reviewer synthesis

The specialist reviewers performed read-only reviews against the current worktree, persona reports, architecture review, contracts, gateway/runtime code, frontend routes, and control docs. The principal reviewer then collated the findings against the four daily local-workstation personas.

## Principal Gate Decision

Decision: **P0 block for implementation readiness**.

JuliaFlow is ready for design and refactor planning, but it is not ready to implement or claim daily data/ML workstation readiness. The current product surfaces are valuable local-first evidence, but they are still workflow/execution-centered and route-scoped. Persona readiness requires a durable project-centered architecture.

This does not block small safety fixes or documentation cleanup. It blocks deeper persona feature work until the architecture substrate is designed and accepted.

## P0 Readiness Blockers

1. `DataScienceProject` aggregate is missing.
   - Current route-scoped contracts cannot represent project files, schema roles, split strategy, validation/test evidence, statistics, training/tuning, evaluation, predictions, model lifecycle, drift, and reproducibility as one durable state.

2. Typed runtime/job contracts are missing.
   - Generic workflow executions are not enough for statistical analysis, training, tuning, evaluation, scoring, drift monitoring, prediction export, or MLOps evidence.

3. Data science validity is not enforceable.
   - Train/validation/test roles, split locks, grouped/time/depth strategies, fit/apply transform separation, metric selection, final test protection, and output contracts are not enforced across contracts, gateway, execution, and frontend.

4. Local trust boundaries must be fixed before broad import.
   - Reviewers identified gateway auth/CORS default risk, arbitrary server-local path import, fixture-style data import/profile, backup auth metadata exposure, PostgreSQL schema interpolation, object-store runtime gating, realpath confinement, and checksum streaming gaps.

5. Current ML, registry, deploy, and monitor surfaces are not MLOps-ready.
   - They should be described as thin local evidence proofs until model lifecycle gates, scoring artifacts, drift baselines, retraining review, rollback lineage, and job/trial resource evidence exist.

## P1 Required Architecture Changes

1. Add additive project contracts and OpenAPI paths.
   - Add `/api/v1/data-science-projects`.
   - Add explicit `schemaVersion`.
   - Add `DataScienceProject`, `ProjectDataset`, `SchemaContract`, `DatasetSplitPlan`, `SplitAssignment`, `ValidationFold`, `FinalTestLock`, `StatisticalAnalysisRun`, `TrainingPlan`, `TuningStudy`, `TuningTrial`, `EvaluationReport`, `PredictionExport`, `ModelLifecycleRecord`, `MonitoringBaseline`, `DriftReport`, and reproducibility evidence records.
   - Keep existing `/api/v1/workflows/...` endpoints as backward-compatible adapters.

2. Split the gateway before feature depth.
   - Extract `LocalApplianceHealth`, `ChartSpecService`, `DataCatalogService`, `AnalysisService`, `ExperimentService`, `ModelRegistryService`, `MonitoringService`, `DeployExportService`, `LocalSourceAccess`, and thin route dispatch.

3. Add a data-science project repository.
   - Persist projects independently from workflow execution metadata.
   - Start with file-backed local appliance mode.
   - Add PostgreSQL lab/team mode using the existing metadata pattern.

4. Add typed jobs and results.
   - `StatisticalAnalysisJob`
   - `TrainingJob`
   - `TuningJob`
   - `EvaluationJob`
   - `BatchScoringJob`
   - `DriftMonitoringJob`
   - `PredictionExportJob`
   - Each job must include dataset snapshot refs, validation strategy, fit/apply transform refs, seed policy, artifact refs, metric outputs, generated Julia code refs, and CPU/GPU resource evidence.

5. Add model lifecycle gates.
   - Candidate, validated, approved, deployed, deprecated, archived.
   - Gate registration/deployment on evaluation evidence, final test policy, reproducibility bundle, model/data card completeness, drift baseline where applicable, artifact checksums, and rollback target.

6. Move frontend state behind project-backed actions.
   - Data, Transform, ML Studio, Models, Visualize, Deploy, and Monitor should read and mutate the shared project aggregate.
   - Route-local UI state should only represent temporary view controls, not project decisions.

7. Expand contract and release gates.
   - Add domain presence tests, generated-client tests, OpenAPI path coverage, backward-compatible fixture roundtrips, release/local-appliance no-fixture tests, and negative tests for invalid split/tuning/deploy states.

## P2 Product And UX Depth

1. Local Dataset Wizard
   - File/folder picker or source grant evidence.
   - Train/validation/test/evaluation/output roles.
   - Schema preview and type correction.
   - Target, id, group, time, depth, sensitive, ignore roles.
   - Explicit unsupported connector states.

2. Real statistical EDA and diagnostics
   - Descriptive statistics, OLS, t-test, chi-square, ANOVA, Pearson, Spearman, residual diagnostics, missingness, outliers, leakage checks, drift checks, grouped/domain summaries, and assumptions.
   - Output should include result tables, Plotly specs, warnings, generated Julia code, and reproducibility refs.

3. Guided no-code workflow
   - Safe defaults.
   - Baseline-first modeling.
   - Validation-before-tuning.
   - Plain-language metric and assumption explanations.
   - Disabled-state reasons and reversible high-risk decisions.

4. Accessibility and persona-flow verification
   - Visible focus states.
   - Correct tab semantics.
   - Dialog focus handling.
   - Keyboard/text alternative for the transform canvas.
   - Persona-flow browser tests from local import through monitor/deploy.

## P3 Documentation And Positioning Corrections

- Use “thin local evidence proof” or “product-depth shell” for current ML/registry/deploy/monitor state.
- Do not call the application daily-workstation-ready or MLOps-ready until P0/P1 blockers are closed.
- Normalize terminology: train, validation, test/evaluation, output contract. Use “submission” only for competition templates.
- Clarify node-library maturity: existing stable nodes are useful building blocks, but not ML-validity-stable workflows until typed packs and validation semantics exist.

## Required Design Reviews Before Implementation

No more review is needed to justify the current block. Before implementation readiness, the following reviews must be run against concrete design artifacts:

1. Contract/API design review
   - `DataScienceProject`, schema versioning, compatibility, OpenAPI package versioning, generated-client behavior.

2. Security threat model
   - Gateway auth/CORS, local import paths, backup/export, PostgreSQL schema handling, object-store hooks, artifact validation.

3. ML validity review
   - Split strategy, fit/apply semantics, tuning, final-test locks, metrics, provenance, reproducibility bundle contents.

4. MLOps lifecycle review
   - Registry states, promotion gates, scoring artifacts, drift baselines, retraining, rollback, deployment semantics.

5. Frontend accessibility/persona-flow review
   - Run after project-backed UX exists.

## Recommended Implementation Sequence

1. Contracts first.
2. Gateway split.
3. Project repository.
4. Typed jobs.
5. Validity gates.
6. Registry/MLOps.
7. Frontend migration.
8. Security hardening.
9. Acceptance tests.

## Acceptance Gates For The First Implementation Slice

The first implementation slice should be the `DataScienceProject` substrate only. It should not attempt full EDA, tuning, drift, or deployment.

Minimum evidence:

- Contract and OpenAPI types for the aggregate and first child records.
- Generated TypeScript client support.
- File-backed project repository.
- Gateway routes for create/read/update/list project records.
- Backward-compatible existing workflow/data/ML endpoints.
- Tests proving old clients still pass.
- Negative tests for missing required project fields.
- Control-doc sync and traceability updates after code exists.

## Principal Reviewer Conclusion

Proceed with the `DataScienceProject` design and substrate. Do not deepen ML Studio, Models, Deploy, Monitor, drift, tuning, or local connector behavior until the project aggregate, trust boundaries, typed jobs, and validation gates exist.

## Implementation Readiness Review Addendum - 2026-07-08

Decision: **continue AKS-36 implementation; do not close the P0 blocker yet**.

The current AKS-36 branch now has the core `DataScienceProject` substrate, project-scoped validation/evaluation/export/drift/lifecycle routes, typed project job evidence, worker dispatch metadata, registry persistence, project-backed frontend evidence, and live-browser smoke coverage. The remaining implementation gate is no longer the absence of the aggregate; it is final closure of the local-source trust boundary, broader gateway module split, no-code onboarding, accessibility baseline, and release verification evidence.

### Contract/API Review

- Accepted: additive project contracts and `/api/v1/data-science-projects` remain backward compatible with workflow-scoped endpoints.
- Accepted: project jobs now include `data_profile`, `training`, `transform_fit_apply`, `statistical_analysis`, `tuning_study`, `final_evaluation`, `batch_scoring`, `prediction_export`, `drift_report`, `deploy_package`, `model_lifecycle`, and `retraining` as explicit contract job types.
- Remaining: keep generated-client and OpenAPI tests as the authority for any new job or child-record field.

### Security And Local Trust Review

- Accepted: managed-local refs, raw local import roots, output-contract imports, sensitive filename/content sniffing, and redacted audit evidence have implementation coverage.
- Remaining: maintain `docs/local-source-threat-model.md` as the threat model for browser-to-localhost mutation routes, file/folder import grants, symlink/junction rejection, connector-specific policies, backup/export redaction, PostgreSQL identifier validation, object-store hook gating, and checksum streaming.
- Blocking rule: broad connector enablement stays disabled until the connector has a documented trust policy and tests.

### ML Validity Review

- Accepted: training/tuning/final evaluation/prediction export/model lifecycle flows carry split/final-test/output-contract evidence and reject final-test use for training/tuning.
- Accepted: project-backed transform fit/apply records distinguish train-only fitting from held-out application.
- Remaining: package-backed MLJ fitting/tuning and hardware-backed GPU trials are optional capability paths with explicit fallback evidence until dependencies/hardware are available.

### MLOps Lifecycle Review

- Accepted: registry and lifecycle records now support approval, deployment, rollback, deprecation, archive, retraining request, drift report linkage, worker-backed retraining jobs, and physical registry persistence.
- Remaining: production-grade drift baselines and retraining review should remain evidence-scoped to local project records until broader operational integrations are intentionally added.

### Frontend And Persona Review

- Accepted: Data, Transform, ML Studio, Models, Deploy, and Monitor now read project-backed evidence for the implemented path.
- Added: the Data route includes a Local Dataset Wizard for dataset role, schema role suggestions, validation strategy, and final-test locking; Transform includes a keyboard-accessible pipeline outline for non-pointer inspection.
- Remaining: AKS-48/AKS-49 closure requires browser coverage for local onboarding and accessibility-focused route controls before any daily-workstation readiness claim.
