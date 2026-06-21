# Checkpoint Log

## Purpose

This file tracks milestone snapshots in compact form.
Agent must read newest checkpoint entry before starting work.
Agent must append/update checkpoint entry after major work block.

Each checkpoint entry must contain:

1. Work done till date at checkpoint
2. Gaps pending at checkpoint
3. Next items to implement after checkpoint

## Active Checkpoint Chain

- `cp/00-foundation`
- `cp/01-contracts-frozen`
- `cp/02-alpha-core` in progress

---

## Checkpoint: `cp/02-alpha-core` AKS-36 Drift Report Gate Slice - 2026-06-21

### Work Done Till Date

- Added `RunDriftReportRequest` and `RunDriftReportResponse` contracts plus a project-scoped OpenAPI route for local drift reporting.
- Added typed gateway client and endpoint-path coverage for the new route.
- Implemented `POST /api/v1/data-science-projects/{projectId}/drift/run` in the gateway.
- The route validates project/dataset membership, blocks drift reporting until prediction export evidence exists, creates or reuses monitoring baselines, validates metric names and thresholds, and persists deterministic drift report evidence.
- Persisted monitoring baselines and drift reports into `DataScienceProject.monitoringBaselines` and `DataScienceProject.driftReports` with validation evidence linking project, dataset, prediction export, evaluation report, and output contract.
- Added focused contract assertions and Julia route assertions for successful baseline/report persistence and invalid threshold rejection.
- Verified the slice with `npm run validate:contracts` and a focused Julia route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent remains open. Drift reporting now has a project-backed gated route, but real drift statistics, production baseline refresh semantics, monitoring UI coverage, alert/retraining workflow, and typed drift job lifecycle remain open.
- Transform fit/apply semantics, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Replace deterministic drift evidence with real drift statistics and monitoring artifacts.
- Add transform fit/apply semantics with split/evaluation evidence discipline.
- Start gateway internal module extraction and local source trust-boundary hardening.

## Checkpoint: `cp/02-alpha-core` AKS-36 Prediction Export Gate Slice - 2026-06-21

### Work Done Till Date

- Added `RunPredictionExportRequest` and `RunPredictionExportResponse` contracts plus a project-scoped OpenAPI route for local prediction export.
- Added typed gateway client and endpoint-path coverage for the new route.
- Implemented `POST /api/v1/data-science-projects/{projectId}/predictions/export` in the gateway.
- The route validates project/dataset membership, blocks export without an approved final-evaluation report, requires final-test evidence on that report, requires explicit output contract evidence, validates export format/row count, and persists local prediction export evidence.
- Persisted prediction exports into `DataScienceProject.predictionExports` with artifact ref, row count, format, output contract, and validation evidence linking the export to the approved evaluation report.
- Added focused contract assertions and Julia route assertions for successful persistence, bad format rejection, and missing output contract rejection.
- Verified the slice with `npm run validate:contracts` and a focused Julia route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent remains open. Prediction export now has a project-backed gated route, but real Julia scoring, prediction file materialization, output schema validation, UI workflow coverage, and typed scoring/export job lifecycle remain open.
- Transform fit/apply semantics, drift/evaluation monitoring records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Replace deterministic prediction export evidence with real Julia scoring and export artifacts.
- Add drift records and transform fit/apply semantics with the same split/evaluation evidence discipline.
- Start gateway internal module extraction and local source trust-boundary hardening.

## Checkpoint: `cp/02-alpha-core` AKS-36 Final Evaluation Gate Slice - 2026-06-21

### Work Done Till Date

- Added `RunFinalEvaluationRequest` and `RunFinalEvaluationResponse` contracts plus a project-scoped OpenAPI route for local final evaluation.
- Added typed gateway client and endpoint-path coverage for the new route.
- Implemented `POST /api/v1/data-science-projects/{projectId}/evaluation/run` in the gateway.
- The route validates project/dataset membership, requires locked split evidence with a nonzero test fraction, requires explicit `finalTestPolicy: use_final_test`, blocks missing training/tuning prerequisites, and requires prior validation-only tuning evidence before using the locked test split.
- Persisted deterministic final-evaluation reports into `DataScienceProject.evaluationReports` with metrics, approval status, local artifact evidence, and validation evidence linking project, split, and tuning study.
- Added focused contract assertions and Julia route assertions for successful persistence, bad final-test policy rejection, and missing prerequisite rejection.
- Verified the slice with `npm run validate:contracts` and a focused Julia route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent remains open. Final evaluation now has a project-backed gated route, but real Julia scoring/evaluation execution, persisted model-scoring artifacts, metric/threshold semantics, UI workflow coverage, and typed evaluation job lifecycle remain open.
- Prediction/output export, transform fit/apply semantics, drift/evaluation monitoring records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Replace deterministic final-evaluation evidence with real Julia scoring/evaluation artifacts.
- Add prediction/export and drift records with the same split/final-test evidence discipline.
- Start gateway internal module extraction and local source trust-boundary hardening.

## Checkpoint: `cp/02-alpha-core` AKS-36 Validation-Only Tuning Study Slice - 2026-06-21

### Work Done Till Date

- Added `RunTuningStudyRequest` and `RunTuningStudyResponse` contracts plus a project-scoped OpenAPI route for local validation-only tuning studies.
- Added typed gateway client and endpoint-path coverage for the new route.
- Implemented `POST /api/v1/data-science-projects/{projectId}/tuning/run` in the gateway.
- The route validates project/dataset membership, requires split-plan evidence, requires nonzero validation/test fractions, rejects `use_final_test`, creates or updates a training plan, persists deterministic tuning-study evidence, and returns the updated project.
- Added `validationEvidence` to tuning-study records so accepted studies carry project/split/final-test policy context.
- Added focused contract assertions and Julia route assertions for successful persistence and final-test misuse rejection.
- Verified the slice with `npm run validate:contracts`, a focused Julia route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, and `npm run build`.

### Gaps Pending

- AKS-36 parent remains open. Tuning now has a project-backed validation-only run record route, but real Julia hyperparameter optimization, persisted trial artifacts, UI workflow coverage, and typed tuning job lifecycle remain open.
- Final evaluation, prediction/output export, transform fit/apply semantics, drift/evaluation records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Replace deterministic tuning evidence with real Julia tuning execution and trial artifacts.
- Add final-evaluation, prediction/export, and drift records with split/final-test gates.
- Start gateway internal module extraction and local source trust-boundary hardening.

## Checkpoint: `cp/02-alpha-core` AKS-36 Statistical EDA Run Substrate Slice - 2026-06-21

### Work Done Till Date

- Added `RunStatisticalAnalysisRequest` and `RunStatisticalAnalysisResponse` contracts plus a project-scoped OpenAPI route for statistical EDA runs.
- Added typed gateway client and endpoint-path coverage for the new route.
- Implemented `POST /api/v1/data-science-projects/{projectId}/statistical-analysis/run` in the gateway.
- The route validates project/dataset membership, validates supported method names, generates local Plotly-compatible chart evidence, persists the run into `DataScienceProject.statisticalAnalysisRuns`, and returns the updated project.
- Added focused contract assertions and Julia route assertions for successful persistence and unsupported-method rejection.
- Verified the slice with `npm run validate:contracts`, a focused Julia route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, and `npm run build`.

### Gaps Pending

- AKS-36 parent remains open. Statistical EDA now has a project-backed run record route, but real Julia execution for OLS, t-test, chi-square, ANOVA, Pearson/Spearman correlation, result tables, and UI workflow coverage remains open.
- Hyperparameter tuning, final evaluation, prediction/output export, transform fit/apply semantics, drift/evaluation records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Replace deterministic EDA profile evidence with real Julia statistical computations and result artifacts.
- Add typed tuning/final-evaluation/prediction/drift records and validation gates.
- Start gateway internal module extraction and local source trust-boundary hardening.

## Checkpoint: `cp/02-alpha-core` AKS-36 Model Promotion And Deploy Validation Gate Slice - 2026-06-21

### Work Done Till Date

- Added `validationEvidence` to model registry and deploy package contract/OpenAPI records.
- Required validated ML experiment context before model registration can create a registry record.
- Required the same validation context before local deploy packaging can package a model or fallback-synthesize registry details.
- Prevented model registry list synthesis from exposing unvalidated executions as promotable model records.
- Added controlled 409 responses for missing model-registration or deploy-package validation evidence.
- Added Julia route assertions for blocked registration/deploy before validation, accepted registration/deploy after validation, and validation evidence on accepted records.
- Verified the slice with a focused Julia route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, and `npm run build`.

### Gaps Pending

- AKS-36 parent remains open. Validation enforcement now covers ML experiment runs, model registration, and local deploy packaging, but not hyperparameter tuning, final evaluation, prediction/output export, transform fit/apply semantics, or drift/evaluation records.
- Gateway module split, local source trust-boundary hardening, statistical EDA services, typed jobs, first-class model lifecycle records, and broader project-backed feature migration remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Add typed tuning/final-evaluation/prediction/drift records and validation gates.
- Start gateway internal module extraction before adding deeper stats/tuning/registry/drift behavior.
- Add local-source trust-boundary checks and statistical EDA run records for the next data-science substrate slices.

## Checkpoint: `cp/02-alpha-core` AKS-36 ML Experiment Validation Enforcement Slice - 2026-06-21

### Work Done Till Date

- Extended `GatewayMlExperimentRunRequest` and OpenAPI `MlExperimentRunRequest` with `projectId`, `splitPlanId`, and `finalTestPolicy`.
- Extended ML experiment records with `validationEvidence` so accepted runs can report the project/split/final-test policy context behind metrics.
- Updated the frontend ML Studio run action to send active `DataScienceProject` split context to the gateway in live mode.
- Added gateway-side ML experiment validation before accepting a run: project/dataset consistency, split-plan existence, nonzero validation/test fractions, and rejection of `use_final_test` for training/tuning.
- Added focused contract and Julia route coverage for accepted validation evidence, missing split rejection, and final-test misuse rejection.
- Verified the slice with a focused Julia route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, and `npm run build`.

### Gaps Pending

- AKS-36 parent remains open. Validation enforcement currently covers ML experiment runs only.
- Hyperparameter tuning, model registration, deployment packaging, final evaluation, prediction exports, and drift/evaluation records still need split/final-test gates.
- Gateway module split, local source trust-boundary hardening, statistical EDA services, typed jobs, model lifecycle records, and broader project-backed feature migration remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Extend the same validation discipline to tuning, registration, deployment, final evaluation, and prediction/export paths.
- Start gateway internal module extraction before adding deeper stats/tuning/registry/drift behavior.
- Add local-source trust-boundary checks and statistical EDA run records for the next data-science substrate slices.

## Checkpoint: `cp/02-alpha-core` AKS-36 DataScienceProject API Negative Validation Slice - 2026-06-21

### Work Done Till Date

- Hardened `DataScienceProject` gateway validation for unsupported `schemaVersion`, route/body project id mismatch, and non-array child-record fields.
- Added explicit API status classification for malformed project payloads, duplicate project creation, and missing projects.
- Tightened OpenAPI `UpdateDataScienceProjectRequest` so update payloads are bounded to documented project fields instead of arbitrary properties.
- Added contract assertions for the bounded update schema.
- Added Julia route assertions for missing project name, duplicate project creation, unsupported schema version, invalid child-record shape, and project id mismatch.
- Verified the slice with `npm run validate:contracts` and a focused Julia negative route smoke using `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent remains open. Project API payload validation is stronger, but validation/test enforcement is not yet wired into execution, tuning, registry promotion, deployment, or final evaluation gates.
- Gateway module split, local source trust-boundary hardening, statistical EDA services, typed jobs, model lifecycle gates, drift reports, and broader project-backed frontend routing remain open.
- Full Julia suite remains blocked on this Windows host by application-control policy for generated/JLL DLLs.

### Next Items To Implement

- Add gateway/execution validation checks for split alignment, final-test locks, and fit/apply metadata before tuning or model promotion.
- Start gateway internal module extraction for data-project/catalog/analysis/experiment/monitoring responsibilities.
- Harden local source import trust boundaries before enabling broader connector behavior.

## Checkpoint: `cp/02-alpha-core` AKS-36 Data Project Frontend Persistence Slice - 2026-06-21

### Work Done Till Date

- Added a fixture-backed `DataScienceProject` aggregate to frontend shared state.
- Loaded live data-science projects through the gateway client and kept release/local-appliance mode strict when the gateway returns no project aggregate.
- Added Data route schema diagnostics backed by project schema contracts, including editable logical type, role, and nullable fields.
- Added validation/test split controls backed by project split plans, including strategy, group/depth column selectors, visible train/validation/test fractions, and final-test lock state.
- Added app-level persistence through `updateDataScienceProject`, with deterministic demo fallback and live gateway `PUT /api/v1/data-science-projects/{projectId}` coverage.
- Added focused frontend tests for demo project edits and live gateway project update requests.

### Gaps Pending

- AKS-36 parent remains open. Data schema/validation is now project-backed, but Transform, ML Studio, Models, Monitor, Deploy, and reports are not fully project-backed.
- Validation/test discipline is persisted, but not yet enforced in gateway/execution paths for tuning, model registration, deployment, or final evaluation.
- Gateway module split, local source trust-boundary hardening, statistical EDA services, typed jobs, model lifecycle gates, drift reports, and broader release/local-appliance no-fixture evidence remain open.
- Browser route QA was attempted with `npm run test:browser -- tests/browser/local-ui.spec.ts`, but Playwright failed before app assertions because Chromium could not launch on this host (`browserType.launch: spawn UNKNOWN`).

### Next Items To Implement

- Add negative contract/API coverage for project invalid updates and project id mismatch.
- Implement execution/gateway validation checks for split alignment and final-test lock constraints.
- Begin gateway internal module extraction before adding deeper stats, tuning, registry, or drift behavior.

## Checkpoint: `cp/02-alpha-core` AKS-36 DataScienceProject Substrate First Slice - 2026-06-21

### Work Done Till Date

- Added additive `DataScienceProject` contracts in `packages/contracts/src/index.ts`.
- Added OpenAPI paths and schemas for `/api/v1/data-science-projects` and `/api/v1/data-science-projects/{projectId}`.
- Added gateway client methods and typed fixture coverage for list/create/get/update project calls.
- Added `DataScienceProjectRecord` persistence in `JuliaFlowGatewayRepository`, including file-backed storage, PostgreSQL-compatible table/load/save methods, project change durable events, and lazy `LibPQ` loading.
- Added `GatewayState` project loading plus thin gateway create/list/read/update project routes with audit events and not-found classification.
- Added repository contract coverage and API Gateway route assertions for create/list/get/update/reload behavior.

### Gaps Pending

- AKS-36 parent remains open. The slice does not complete gateway module split, local trust-boundary hardening, validation/test locks, typed jobs, statistical EDA calculations, model lifecycle gates, drift reports, project-backed frontend modules, or persona-flow browser verification.
- Full Julia suite remains environment-blocked on this Windows host: normal run hits application-control policy on generated/JLL DLLs, and `--compiled-modules=no` full suite timed out. A focused Julia route smoke passed.

### Next Items To Implement

- Add negative project contract/API tests for missing required fields and invalid project id update payloads.
- Run the required concrete design reviews for contract/API, security, ML validity, and MLOps lifecycle.
- Continue with gateway module split, trust-boundary hardening, and validation/test strategy enforcement before deep ML Studio/Models/Deploy/Monitor work.

## Checkpoint: `cp/02-alpha-core` Principal Persona Readiness Multi-Review - 2026-06-21

### Work Done Till Date

- Added `docs/principal-persona-readiness-review.md`.
- Ran six specialist read-only reviews in parallel: contract/API, Julia gateway/runtime, frontend/UX workflow, data science/ML validity, security/local trust boundary, and MLOps/model ops.
- Collated the specialist findings through a principal reviewer.
- Principal gate decision: P0 block for implementation readiness. The repo is ready for design/refactor planning, but not ready to claim daily data/ML workstation readiness.
- Updated `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/architecture.md`, `docs/persona-architecture-review.md`, and `docs/project-tracker.md`.

### Gaps Pending

- No code implementation was added in this review slice.
- `DataScienceProject` contracts, file-backed project repository, gateway module split, typed stats/training/tuning/evaluation/scoring/drift jobs, validation/test locks, registry lifecycle gates, drift reports, local import trust-boundary hardening, and project-backed frontend modules remain unimplemented.
- Follow-up design reviews are still required against concrete design artifacts before implementation readiness: contract/API, security threat model, ML validity, MLOps lifecycle, and frontend accessibility/persona-flow.

### Next Items To Implement

- Implement the `DataScienceProject` substrate first: additive contracts/OpenAPI, generated-client coverage, file-backed repository, thin gateway create/read/update/list routes, backward-compatible existing endpoints, and negative tests for missing required fields.
- Do not deepen ML Studio, Models, Deploy, Monitor, drift, tuning, or broad local connector behavior until the project aggregate, trust boundaries, typed jobs, and validation gates exist.

## Checkpoint: `cp/02-alpha-core` Persona-Driven Architecture Review - 2026-06-21

### Work Done Till Date

- Added `docs/persona-architecture-review.md`.
- Reviewed the current contract, gateway, execution, worker, frontend, node roadmap, and persona-report architecture against four daily local-workstation personas.
- Identified the main architecture gap: JuliaFlow needs a shared contract-first `DataScienceProject` aggregate before it can safely implement generic tabular, statistical EDA, validation/test, tuning, registry, drift, and no-code workflow features.
- Identified refactor needs: split gateway product logic into focused internal modules, add project-backed repositories, add typed statistical/training/tuning/evaluation/scoring/drift jobs, move model registry state out of execution metadata, and refactor frontend route-local state behind project-backed feature modules.
- Updated `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, and `docs/architecture.md` to record the review and open architecture lane.

### Gaps Pending

- This checkpoint is architecture review only; no contracts, gateway modules, repositories, execution jobs, frontend feature modules, registry gates, or drift reports were implemented.
- Existing Data, Transform, ML Studio, Models, and Monitor route evidence remains route-specific until the `DataScienceProject` substrate exists.

### Next Items To Implement

- Add the `DataScienceProject` contract and OpenAPI substrate first.
- Refactor `services/api-gateway/src/JuliaFlowApiGateway.jl` into focused internal modules before adding more persona-specific product logic.
- Implement validation/test locks and statistical EDA run records before tuning, final test, registry promotion, drift monitoring, or wellbore domain templates.

## Checkpoint: `cp/02-alpha-core` Data Scientist Competition Persona Readiness - 2026-06-20

### Work Done Till Date

- Added `docs/data-scientist-persona-competition-readiness-report.md`.
- Evaluated JuliaFlow as a local-first data-science app against Titanic, House Prices, and ROGII Wellbore workflows.
- Identified the generalized capabilities required across all three projects: local train/validation/test import, optional output contract import, schema/type role mapping, task/metric selection, validation/test strategy, train/validation/test transform alignment, experiment comparison, prediction export, and reproducibility evidence.
- Identified wellbore-specific requirements: multi-file well import, MD/depth validation, trajectory/typewell features, grouped validation by well, well log/trajectory visualizations, and domain model cards.
- Revised the analysis to treat the Kaggle competitions as examples, not product boundaries, and added missing data-science workflows: train/validation/test separation, final test locks, editable schema/type diagnostics, statistical EDA, hyperparameter tuning, and generalized prediction/export artifacts.
- Extended the analysis to four daily local-workstation personas: senior data engineer, principal data scientist, MLOps engineer focused on training/drift/evaluation, and non-coding statistics/ML user.
- Compared JuliaFlow's required daily-use depth against KNIME, Orange, and H2O-style low-code expectations: connectors and workflow breadth, no-code widget/canvas simplicity, interactive EDA, AutoML/tuning, explainability, registry, deployment, and drift/model monitoring.

### Gaps Pending

- This checkpoint is a product/persona analysis artifact only; no implementation was added for dataset wizard, schema/type editor, statistical EDA surface, validation/test manager, tuning workflow, training task setup, or prediction export.
- The daily-use persona expansion is analysis only; no implementation was added for connector packs, quality-rule engines, scheduling, MLOps evaluation/drift dashboards, model registry lifecycle, CPU/GPU run profiles, AutoML recommendations, or guided no-code workflows.
- The app remains generic/churn-demo oriented until the report's P0 workflow substrate is implemented.

### Next Items To Implement

- Convert the P0 report findings into Linear work items or map them into the current AKS backlog.
- Implement the generic tabular data-science MVP before building the ROGII-specific wellbore domain template.
- Add follow-up backlog for senior data-engineer, principal data-scientist, MLOps, and no-code daily-workflow requirements before claiming JuliaFlow is ready for daily local workstation adoption.

## Checkpoint: `cp/02-alpha-core` AKS-29 Through AKS-35 Parity Hardening - 2026-06-20

### Work Done Till Date

- Merged PR #37 and started the AKS-29 through AKS-35 follow-up branch from updated `main`.
- Added `docs/aks-30-35-implementation-plan.md` with per-task plans for AKS-30, AKS-31, AKS-32, AKS-33, AKS-34, and AKS-35.
- Added shared chart readiness/export utilities and updated the Plotly renderer for ready/stale/empty/error states.
- Added stale chart fixture evidence and coverage.
- Hardened Explorer with workspace source state, artifact count/locality, and no-artifact empty state.
- Hardened Data with active source state, disabled-source reasons, sample-size preview mutation, and readiness text wrapping evidence.
- Hardened Transform with editable node strategy/output settings, unsaved-edit warning state, validation recovery, and config logging.
- Added focused unit and browser coverage for chart readiness, stale chart evidence, Data sampling, and Transform config validation.

### Gaps Pending

- Real Data connector handlers for SQLite/PostgreSQL/MySQL/USB/drop remain future gateway work.
- Persisted Transform pipeline editing beyond local UI state remains future contract/gateway work.
- Final live-backend smoke, control-doc validators, PR publication, and Linear updates remain pending.

### Next Items To Implement

- Run the final verification set, including live-backend smoke and control-doc validators.
- Push the branch, open a draft PR, update Linear AKS-28 through AKS-35, and link the PR evidence.

## Checkpoint: `cp/02-alpha-core` Explorer/Data/Transform Mock Parity - 2026-06-20

### Work Done Till Date

- Implemented the focused Explorer/Data/Transform mock-parity product-depth slice.
- Created the Linear parent/child backlog under AKS-28 through AKS-35 for shared chart foundation, Explorer/Data/Transform parity, gateway/contracts, visual QA, and the Data ML Readiness text-overlap bug.
- Added reusable local interactive chart contracts, Julia/gateway Plotly-compatible chart spec helpers, and a lazy local Plotly renderer with accessible summaries and export hooks.
- Explorer now renders gateway-backed workspace summaries, artifact evidence, local activity/package/runtime data, and Plotly mini charts with proper sidebar icons.
- Data now exposes local source/read-mode/tabs/filter/sort/profile/lineage behavior, disabled unsupported sources with reasons, Plotly EDA charts, and wrapped readiness text.
- Transform now uses React Flow for node-edge editing and shows grouped palette search, selected-node settings, validation/run/history evidence, before/after preview, generated Julia code, logs, artifacts, and Plotly metrics.
- Verification passed: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `node scripts/run-julia.mjs --project=. tests/julia/runtests.jl`, `npm run test:browser -- tests/browser/local-ui.spec.ts`, and `npm run smoke:live-backend-browser`.

### Gaps Pending

- Unsupported Data connectors remain disabled until real gateway/source handlers are implemented.
- The Plotly renderer is lazy-loaded, but bundle-size monitoring remains important for future chart-heavy slices.
- Persisted Transform pipeline editing depth and broader visual QA remain tracked in the AKS-28 child backlog.

### Next Items To Implement

- Run control-doc sync, BRD traceability, and diff checks after this checkpoint update.
- Commit, push, and open the draft PR for the current branch.

## Checkpoint: `cp/02-alpha-core` AKS-13 Live Workflow Metadata Recovery - 2026-06-20

### Work Done Till Date

- Completed the AKS-13 frontend recovery slice after PR #25 release verification closure.
- Release/local-appliance workflow loading now validates backend workflow detail before rendering live canvas/pipeline state.
- Incomplete workflow metadata now reports an unavailable workflow state with recovery guidance instead of substituting fixture workflow nodes.
- Demo/development fixture fallback remains available for offline demos and local development.
- Transform renders explicit workflow metadata recovery guidance when required-mode workflow nodes are unavailable.
- Verification passed: `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run test`, `npm run build`, `npm run validate:contracts`, and `npm run smoke:live-backend-browser`.

### Gaps Pending

- Provider/cloud deployment and hardware-gated GPU proof remain optional compatibility work unless reprioritized.
- The live smoke exits successfully but still prints Julia HTTP connection-cancel teardown noise after Playwright completes.

### Next Items To Implement

- Open the AKS-13 draft PR and link `artifacts/release-verification/live-backend-browser` as live UI evidence.
- Run `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check` before final PR handoff.

## Checkpoint: `cp/02-alpha-core` AKS-5 Stage 5 Release Verification Implementation - 2026-06-19

### Work Done Till Date

- Added the Stage 5 release verification entrypoint `npm run verify:release` with deterministic summary/log artifacts and phase/failure classification.
- Added `npm run smoke:live-backend-browser`, `playwright.live.config.ts`, and live-backend Playwright coverage for local-appliance release behavior.
- Proved live gateway/frontend browser QA for no demo substitution, Data import, Explorer save/run, Monitor execution evidence, dashboard artifact rows/export, Settings/auth state, Offline Hub install, and reproducibility export.
- Made the file-backed gateway path avoid Windows Application Control failures by disabling Julia package images/compiled modules in the live smoke and lazy-loading `LibPQ` only for PostgreSQL repositories.
- Fixed frontend live state to use backend workflow/dashboard ids and de-duplicate dynamic dashboard table columns.

### Gaps Pending

- Full no-skip fresh-checkout `npm run verify:release` is still required before AKS-5 closure.
- Stage 5 PR publication and CI evidence remain pending.

### Next Items To Implement

- Run full release verification after this control-doc update.
- Push/open the focused Stage 5 PR and link final passing artifacts.

---

## Checkpoint: `cp/02-alpha-core` AKS-5 Stage 3 Dashboard/Explainability Evidence Binding - 2026-06-19

### Work Done Till Date

- Bound Visualize dashboard rows to the published dashboard binding dataset instead of direct local fixture rows.
- Added explicit no-artifact-row states for release/local-appliance dashboards without persisted dataset rows.
- Added Monitor executed-run explainability evidence tied to the latest execution id, workflow id, dataset checksum prefix, model artifact ref, metric, and explanation method.
- Added focused frontend tests for artifact-backed dashboard rows, local-appliance no-data behavior, and execution-tied explainability evidence.

### Gaps Pending

- Stage 5 live-backend browser QA remains pending.
- Fresh-checkout release verification script/CI job remains pending.

### Next Items To Implement

- Implement the AKS-5 Stage 5 release verification pipeline.
- Add live-backend browser QA for setup/import, authoring, run, Monitor, dashboard publish/view/export, Hub install, Settings/auth state, reproducibility export, and no false demo-backed UI.

---

## Checkpoint: `cp/02-alpha-core` AKS-5 Stage 3 Save/Run/Monitor Lifecycle - 2026-06-19

### Work Done Till Date

- Added the first Stage 3 workflow lifecycle slice to the modular frontend.
- Explorer now exposes Save Workflow and Run Workflow actions backed by gateway workflow update and execution APIs.
- Frontend state loads execution records from the gateway and appends returned run execution ids without inventing release-mode placeholders.
- Added a Monitor route for backend execution records, latest execution status, completed-node evidence, and explicit no-execution states.
- Added focused frontend coverage for route navigation, demo fallback lifecycle labels, gateway save/run calls, and local-appliance empty execution records.

### Gaps Pending

- Dashboard chart/export data still needs persisted execution artifact dataset binding.
- Explainability evidence still needs executed workflow, dataset checksum, model artifact, metric, and generated explanation output binding.
- Full AKS-5 release verification and live-backend browser QA remain pending.

### Next Items To Implement

- Implement artifact-backed dashboard datasets for Stage 3.
- Bind explainability evidence to the executed workflow run before claiming Stage 3 complete.

---

## Checkpoint: `cp/02-alpha-core` AKS-5 Native Windows Bootstrap Compatibility - 2026-06-18

### Work Done Till Date

- Restored the release baseline from `Gravelaw/LowcodeMLtoolkit.jl` in a temp clone after confirming the active Documents folder is stale and lacks `.git`.
- Confirmed the GitHub baseline contains the modular frontend views/components, Playwright browser test assets, Offline Hub, reproducibility, backup/restore, and migration scripts.
- Updated the toolchain guard so native Windows Node is accepted alongside Debian-native Node, while WSL `/mnt/c` Windows Node interop remains rejected.
- Added `doctor:windows`, `julia:instantiate`, and explicit `dev-local --skip-instantiate` behavior.
- Documented the generated Julia manifest policy and Windows/Debian bootstrap commands.

### Gaps Pending

- In-place restoration of `C:\Users\aksha\Documents\LowCodeJulia` is blocked in this session because shell-level file and directory creation fails under that path; the staged branch work is happening from the verified temp clone.
- Later AKS-5 child issues for release-mode separation, real vertical workflow proof, and full release pipeline remain queued.

### Next Items To Implement

- Push the staged AKS-5 branch and open the draft PR against `main`.
- Continue with release/demo mode boundaries and live-backend browser verification.

---

## Checkpoint: `cp/02-alpha-core` Backend-Backed Deploy Packaging Actions — 2026-06-17

### Work Done Till Date

- Continued the mock-aligned local product-depth sequence after Visualize checkpoint/export actions.
- Added workflow deploy package contracts, OpenAPI schemas, and typed gateway client support.
- Added gateway routes that generate and list local-only deployment package records from workflow/model/checkpoint evidence.
- Returned Deploy package records with endpoint URL, service/package refs, package checksum, generated Julia service code, run command, deployment status, local-only flag, and artifact evidence.
- Persisted Deploy package history into local execution metadata and marked the related model registry record `local_ready`.
- Wired Deploy to run the backend action when a gateway is configured and deterministic demo fallback when offline.
- Added visible package history and artifact evidence in Deploy.
- Added focused Julia route assertions, contract/OpenAPI assertions, typed-client fixture coverage, and frontend demo smoke coverage.

### Gaps Pending

- Current local product-depth sequence is closed for Data, Transform, ML Studio, Models, Visualize, and Deploy actions.
- Provider/cloud deployment remains optional compatibility work outside this local-first package slice.
- Downloadable package archives and process supervision can be future local UX depth if prioritized.

### Next Items To Implement

- Finish PR verification/CI/review and merge once green.
- After merge, audit the BRD/control set for the next local-first gap rather than treating provider deployment as the default next item.

---

## Checkpoint: `cp/02-alpha-core` Backend-Backed Visualize Checkpoint/Export Actions — 2026-06-17

### Work Done Till Date

- Continued the mock-aligned local product-depth sequence after Models registry actions.
- Added dashboard checkpoint-export contracts, OpenAPI schemas, and typed gateway client support.
- Added a gateway route that composes dashboard publish, checkpoint creation, and reproducibility bundle export into one local evidence action.
- Returned Visualize export records with workflow/dashboard IDs, dashboard version, checkpoint tag/summary, bundle ID/checksum, artifact refs/checksums, created timestamp, and local-only flag.
- Wired Visualize to run the backend action when a gateway is configured and deterministic demo fallback when offline.
- Added visible export history in Visualize for checkpoint tags, bundle IDs, artifact counts, and checksum prefixes.
- Added focused Julia route assertions, contract/OpenAPI assertions, and frontend demo smoke coverage.

### Gaps Pending

- Local Deploy packaging remains the last product-depth slice before claiming full mock-aligned product readiness.
- Downloadable bundle UX can be deepened later; current evidence exposes local artifact refs/checksums and bundle IDs.

### Next Items To Implement

- Implement backend-backed local Deploy packaging actions.
- Keep `npm run validate:contracts`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, control-doc validators, and `git diff --check` in the PR gate.

---

## Checkpoint: `cp/02-alpha-core` Backend-Backed Models Registry Actions — 2026-06-17

### Work Done Till Date

- Implemented the next backend-backed product-depth slice after ML Studio experiment actions.
- Added workflow model register/list routes, contracts, OpenAPI schemas, typed client methods, and client fixture coverage.
- Gateway model registry records persist into local execution metadata with checkpoint, model, dataset checksum, primary metric, tags, owner, deployment status, and local artifact references.
- Models now registers models through the gateway when configured and preserves deterministic demo fallback with accessible action coverage.
- Added Julia gateway assertions and frontend demo-mode coverage for the Models registry action.

### Gaps Pending

- Visualize checkpoint/export depth and local Deploy packaging remain open product-depth slices.
- Richer registry filtering/search and deployment promotion UX remain future depth after the core local workflow actions close.

### Next Items To Implement

- Continue local product-depth with Visualize checkpoint/export before local Deploy packaging.
- Keep `npm run validate:contracts`, Julia tests, frontend tests, `npm run test`, `npm run build`, control-doc sync, BRD traceability, and `git diff --check` in the gate set.

---

## Checkpoint: `cp/02-alpha-core` Backend-Backed ML Studio Experiment Actions — 2026-06-17

### Work Done Till Date

- Implemented the next backend-backed product-depth slice after Data import/profile and Transform run/history.
- Added workflow ML experiment run/history routes, contracts, OpenAPI schemas, typed client methods, and client fixture coverage.
- Gateway experiment records reuse local execution/checkpoint and explainability evidence to return dataset/model IDs, dataset checksum, metrics, feature importance, hardware backend, GPU readiness, and local artifact references.
- ML Studio now runs experiments through the gateway when configured and preserves deterministic demo fallback with accessible action coverage.
- Added Julia gateway assertions and frontend demo-mode coverage for the ML Studio action.

### Gaps Pending

- Models registry mutation, Visualize checkpoint/export depth, and local Deploy packaging remain open product-depth slices.
- Richer MLJ training execution is still future depth beyond this deterministic local-evidence action.

### Next Items To Implement

- Continue local product-depth with Models registry mutation or Visualize checkpoint/export before local Deploy packaging.
- Keep `npm run validate:contracts`, Julia tests, frontend tests, `npm run test`, `npm run build`, control-doc sync, BRD traceability, and `git diff --check` in the gate set.

---

## Checkpoint: `cp/02-alpha-core` Mock-Aligned Local Product Workflow Vertical First Slice — 2026-06-17

### Work Done Till Date

- Implemented the first frontend-shell slice of the mock-aligned local product workflow vertical.
- Route shell now exposes Explorer, Data, Transform, ML Studio, Models, Visualize, Deploy, Hub, Monitor, and Settings.
- Explorer remains the workspace/canvas entry point, while Visualize carries the existing BI dashboard authoring/viewer behavior and preserves `/dashboard` deep-link compatibility.
- Data, Transform, ML Studio, Models, and Deploy render shared local state from health, data-estate, workflow, checkpoint, execution, explainability/model, dashboard, and runtime endpoint evidence.
- Added frontend coverage for the route shell and a demo-mode walk through the local workflow vertical.

### Gaps Pending

- This slice is frontend/product integration only; backend-backed import/profile, transform run/history, experiment tracking, model registry mutation, and deploy packaging actions remain open.
- Full product readiness still needs deeper module behavior and final PR review after PR #11 lands.

### Next Items To Implement

- Rebase this vertical branch after PR #11 lands, then add backend-backed product actions starting with Data import/profile and Transform history if product depth remains the selected lane.
- Keep `npm run test`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check` in the gate set.

---

## Checkpoint: `cp/02-alpha-core` Backup/Restore And Migration Proof Complete — 2026-06-17

### Work Done Till Date

- Landed PR #10 and restarted from updated `main` on `codex-local-backup-restore-proof`.
- Added local appliance backup export/import routes for checksum-protected migration bundles.
- Bundles cover workflows, checkpoints, executions, published dashboards, Hub records, auth policy/directory, package/runtime metadata, local settings, and data-estate artifact references/checksums.
- Restore validates the signed backup checksum, reports missing local artifacts and checksum mismatches, rehydrates metadata into a fresh local repository, and rejects tampered bundles.
- Added `npm run smoke:local-migration` with an in-process gateway smoke that proves export, restore, missing artifact reporting, and tamper rejection.

### Gaps Pending

- Backup bundles do not embed local binary artifact bytes; they provide manifest-style references/checksums for migration validation.
- Mock-derived product modules remain open implementation work.

### Next Items To Implement

- Start the mock-aligned local product workflow vertical: Explorer/Workspace -> Data -> Transform -> ML Studio/Models -> Visualize -> checkpoint/export.
- Keep `npm run smoke:local-migration`, `npm run validate:contracts`, Julia tests, control-doc sync, BRD traceability, and `git diff --check` in the PR gate set.

---

## Checkpoint: `cp/02-alpha-core` Mock-Aligned BRD Product Surface Refresh Complete — 2026-06-16

### Work Done Till Date

- Compared the eight `mockdesigns/` screens against the BRD and current repo state.
- Updated the BRD to capture Explorer, Data, Transform, ML Studio, Models, Deploy, Visualize, and Settings as required local-first product modules.
- Added requirements for local workspace health/activity, local data import/profile/lineage, transform canvas/code/history, MLJ training/experiments, model registry/drift/lineage, local deployment targets/endpoints, dashboard builder/export, local package/Julia settings, API keys, autosave, and snapshots.
- Removed stale core-product emphasis on cloud/provider paths by keeping hosted SaaS collaboration, remote managed inference, cloud telemetry, cloud model registries, cloud deployment, external connectors, and external registries optional.

### Gaps Pending

- This checkpoint closes the BRD/control-doc refresh only; mock-derived module implementation remains open.
- Academic reproducibility and backup/restore remain open local-first lanes.

### Next Items To Implement

- Start academic reproducibility workflow unless the next selected slice is a mock-derived local module implementation pass.
- Keep `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check` as required evidence for doc/control slices.

---

## Checkpoint: `cp/02-alpha-core` Debian Toolchain / Offline Hub Proof Complete — 2026-06-16

### Work Done Till Date

- Rectified the active development shell for Debian: `npm run doctor:debian` verifies native Linux/nvm Node and repo-local Juliaup LTS with workspace-local Julia depots.
- Implemented and verified the offline Hub proof after explainability/model evidence closure.
- Gateway `/health` exposes local Hub cache readiness, artifact-store path, mirror-registry path, artifact cache root, bundled extension count, installed local extension count, and offline install readiness.
- Local bootstrap initializes offline Hub artifact and mirror registry files under the local appliance cache.
- `npm run smoke:local-offline-hub` runs through the in-process gateway router, registers/enables a local official extension from local artifact/mirror registries, and verifies unsafe sandbox commands remain blocked.
- Frontend Monitor, TypeScript/OpenAPI contracts, Julia health assertions, frontend tests, and contract tests cover the expanded Offline Hub evidence surface.

### Gaps Pending

- Offline Hub proof is closed for the current local-first slice.
- Socket-bound gateway smoke remains unavailable in the current sandbox because TCP bind fails with `EPERM`; the in-process router smoke verifies the install path without network binding.
- The Babel/esbuild/Vite dependency advisories are resolved in this PR branch; `npm audit --audit-level=moderate` now reports zero vulnerabilities after the Vite 8 lockfile upgrade.
- Academic reproducibility bundles and backup/restore integrity remain queued for the next local-first lanes.

### Next Items To Implement

- Start academic reproducibility workflow: offline EDA -> model -> explain -> dashboard -> checkpoint -> export/reimport with package, seed, checksum, metric, model, explanation, dashboard, and notes evidence.
- Keep `npm run doctor:debian` and `npm run smoke:local-offline-hub` in the local-first gate set.

---

## Checkpoint: `cp/02-alpha-core` Explainability / Model Evidence Proof Complete — 2026-06-06

### Work Done Till Date

- Implemented and verified the explainability/model evidence slice after local hardware runtime closure.
- Gateway `/health`, checkpoint payloads, and accepted execution payloads expose deterministic dataset-card, model-card, feature-importance, local-explanation, limitations/warnings, and reproducibility-bundle readiness evidence.
- `scripts/dev-local.mjs` smoke checks verify explainability evidence and `npm run smoke:local-explainability` runs the bounded local proof.
- Frontend Monitor renders explainability evidence in health and execution surfaces.
- Contracts, OpenAPI, Julia gateway tests, frontend tests, and contract tests cover the expanded evidence surface.

### Gaps Pending

- Current explainability/model evidence proof is closed for deterministic local evidence wiring.
- Broader export/reimport reproducibility bundles remain queued for the academic reproducibility lane.
- Backup/restore integrity remains queued for the backup/restore lane.

### Next Items To Implement

- Start offline Hub proof: bundled/local extension install without external registry dependency, checksum verification, sandbox tests, local artifact cache, and unsafe-extension blocking.
- Keep `npm run smoke:local-explainability` in the local-first gate set.

---


## Checkpoint: `cp/02-alpha-core` Local Hardware Runtime Proof Complete — 2026-06-03

### Work Done Till Date

- Implemented and verified the local hardware runtime slice after local metadata/database closure.
- Gateway `/health` now exposes hardware profile status, selected backend, bounded CPU scheduler policy, CPU worker concurrency, CPU memory limit, CUDA probe status, hardware/simulated GPU counts, VRAM totals, and GPU device summaries.
- `scripts/dev-local.mjs` smoke checks verify the hardware profile evidence for local profiles.
- Added `scripts/smoke-local-hardware.mjs` behind `npm run smoke:local-hardware`; the smoke proves CPU fallback with an empty GPU registry and deterministic CUDA-smoke skip behavior when CUDA is not requested.
- Frontend Monitor renders hardware profile, CPU scheduler/memory limit, GPU probe, and VRAM evidence.
- TypeScript/OpenAPI contracts, Julia gateway tests, frontend tests, and contract tests cover the expanded health surface.

### Gaps Pending

- Current hardware runtime proof is closed for CPU/RAM/disk profiling, bounded CPU scheduling, memory-aware CPU limits, selected backend evidence, GPU probe summaries, and explicit CPU fallback.
- Hardware-backed CUDA smoke remains optional and conditional on a host with CUDA packages/runtime available.
- Multi-GPU evidence remains optional compatibility/final hardware-gated scope, not a local-first GA blocker.

### Next Items To Implement

- Start explainability/model evidence proof: dataset cards, model cards, feature importance, local/global explanations, limitations/warnings, and checkpoint/reproducibility-bundle export.
- Keep `npm run smoke:local-bootstrap`, `npm run smoke:local-data-estate`, `npm run smoke:local-metadata`, and `npm run smoke:local-hardware` in the local-first gate set.

---

## Checkpoint: `cp/02-alpha-core` Local Metadata / Database Proof Complete — 2026-05-31

### Work Done Till Date

- Implemented and verified the local metadata/database slice after local data-estate closure.
- Gateway `/health` now exposes metadata mode/backend/root/readiness/schema/concurrency/capability evidence for file and PostgreSQL repository backends.
- `scripts/dev-local.mjs` smoke checks now verify metadata evidence for `single-user` and `lab-team` profiles.
- Added `scripts/smoke-local-metadata.mjs` and `scripts/smoke-local-metadata.jl` behind `npm run smoke:local-metadata`; the smoke proves single-user file metadata, live Docker Postgres lab-team metadata, repository contracts, shared Postgres catalog/cursor visibility, and smoke-schema cleanup.
- Frontend Monitor renders metadata evidence alongside local profile, data estate, Postgres profile, and worker health.
- TypeScript/OpenAPI contracts, Julia gateway/repository tests, frontend tests, and contract tests cover the expanded health surface.

### Gaps Pending

- Current metadata/database proof is closed for single-user file mode and lab/team local PostgreSQL mode.
- Metadata backup/restore and migration integrity remain queued for the later backup/restore lane.
- Provider-managed database proof remains optional compatibility scope, not a core local-first GA gate.

### Next Items To Implement

- Start local hardware runtime proof: CPU/RAM/disk/GPU profiler, CPU scheduling, memory-aware worker limits, CUDA smoke when available, and explicit CPU fallback evidence.
- Keep `npm run smoke:local-bootstrap`, `npm run smoke:local-data-estate`, and `npm run smoke:local-metadata` in the local-first gate set.

---

## Checkpoint: `cp/02-alpha-core` Local Data Estate Proof Complete — 2026-05-30

### Work Done Till Date

- Implemented and verified the managed local data-estate slice after bootstrap closure.
- Gateway `/health` now exposes manifest/checksum evidence, Arrow IPC and Parquet artifact-format support, quota and used-byte reporting, cleanup hook readiness, backup root/status, and DuckDB query binding path/status.
- `scripts/dev-local.mjs` smoke checks now reject incomplete managed-estate evidence, and `scripts/smoke-local-data-estate.mjs` provides a bounded temporary-home proof command through `npm run smoke:local-data-estate`.
- Frontend Monitor renders estate manifests, quota, DuckDB query binding, and cleanup/backup readiness.
- TypeScript/OpenAPI contracts, Julia gateway tests, frontend tests, and contract tests cover the expanded health surface.

### Gaps Pending

- Current data-estate product proof is closed for manifests, artifact-format evidence, quotas, cleanup/backup hooks, and DuckDB query binding.
- This slice records a DuckDB query binding file and managed readiness, not a full analytical query execution benchmark.
- Full backup/restore integrity remains queued for the later backup/restore and migration proof lane.

### Next Items To Implement

- Start local metadata/database proof: single-user metadata mode plus PostgreSQL lab/team mode for concurrent metadata, RBAC, audit, execution history, and shared workflow catalog.
- Keep `npm run smoke:local-bootstrap` and `npm run smoke:local-data-estate` in the gate set for local-first follow-up slices.

---

## Checkpoint: `cp/02-alpha-core` Local Appliance Bootstrap Proof Complete — 2026-05-30

### Work Done Till Date

- Implemented and verified the local-first bootstrap slice:
  - `scripts/dev-local.mjs` one-command runner with default `single-user` profile and support for `lab-team`, `s3-compatible-local`, and `developer`.
  - `scripts/smoke-local-bootstrap.mjs` bounded temporary-home smoke wrapper.
  - `package.json` scripts `dev:local` and `smoke:local-bootstrap`.
- Local appliance home/data-estate initialization creates `raw`, `processed`, `features`, `models`, `runs`, `checkpoints`, `dashboards`, `logs`, and `extensions`.
- Gateway `/health` exposes local appliance evidence across Julia + contracts/OpenAPI + frontend Monitor:
  - profile/home/data-estate and zone readiness
  - writable/disk status
  - local service URLs
  - Postgres/MinIO profile status
  - CPU/GPU readiness and fallback reason
  - cloud credentials not required for local bootstrap mode
- Updated focused tests for Julia gateway health fields, contract schema expectations, frontend Monitor rendering, and Windows/WSL-safe Node tool invocation.
- Verified this session:
  - `npm run smoke:local-bootstrap` passed with `single-user`, gateway health, and `wf-foundation` sample workflow availability.
  - `julia --project=. tests/julia/runtests.jl` passed.
  - `npm run test` passed.
  - `npm run validate:contracts` passed.
  - Direct frontend TypeScript checks passed: `node ../../node_modules/typescript/bin/tsc --noEmit -p tsconfig.json` and `node ../../node_modules/typescript/bin/tsc --noEmit -p tsconfig.node.json`.
  - Direct Vite production build passed: `node ../../node_modules/vite/bin/vite.js build --configLoader runner`.
  - `npm run validate:control-doc-sync` and `npm run validate:brd-traceability` passed after final control-doc updates.

### Gaps Pending

- Local appliance bootstrap product proof is closed for the current slice.
- Residual toolchain caveat: `npm run build` reaches Vite transform in this Windows npm/WSL interop shell, then the npm wrapper can hang after Vite exits; direct Node/TypeScript/Vite build commands pass. Native WSL Node/npm should be preferred for future repeatable build-wrapper evidence.
- Lab-team PostgreSQL and S3-compatible local dependency startup profiles are wired but not yet smoke-closed with live Postgres/MinIO dependencies; those belong with local metadata/database and optional S3-compatible-local follow-up evidence.

### Next Items To Implement

- Start local data estate proof: managed filesystem manifests, durable Arrow/Parquet artifacts, DuckDB query acceleration, quotas, cleanup, and backup/restore hooks.
- Keep `single-user` bootstrap smoke in the gate set for every local-first follow-up.
- Revisit native `npm run build` wrapper behavior after native WSL Node/npm is available or CI provides a single-runtime shell.

---

## Checkpoint: `cp/00-foundation`

### Work Done Till Date

- Monorepo scaffold created
- Core docs, CI scaffold, local infra scaffold added
- Contracts and initial frontend/backend shells created

### Gaps Pending

- Contract freeze not complete yet at this point
- Persistence/runtime/editor still shallow

### Next Items To Implement

- freeze contracts
- harden gateway
- deepen execution and frontend shell

---

## Checkpoint: `cp/01-contracts-frozen`

### Work Done Till Date

- Workflow schema, OpenAPI, JSON-RPC, TS contract exports, Julia node/runtime seam stabilized
- Gateway persistence paths and route coverage expanded
- Contract tests and Julia tests broadened

### Gaps Pending

- Alpha workspace still mostly shell
- No real persisted graph editing loop
- No meaningful Phase 1 user workflows yet

### Next Items To Implement

- authoring-first frontend
- save/update loop
- runtime action loop
- base node pack growth

---

## Checkpoint: `cp/02-alpha-core` In Progress

### Work Done Till Date

- Repository canvas refreshed against current tree, docs, frontend, Julia services, contracts, and infra
- Repo onboarding summary added in `docs/repo-onboarding.md`
- `AGENTS.md` updated to reflect current monorepo structure and active commands
- `AGENTS.md` updated again to make `caveman:caveman` the default session communication mode for this repo
- Authoring-first frontend layout delivered
- Editable draft workflow graph delivered
- Flow variable editing delivered
- Inspector config editing delivered
- Save/update workflow loop delivered
- Run workflow loop delivered
- Gateway execute path accepts runtime inputs
- Frontend realtime websocket subscription delivered for live gateway mode
- Canvas node runtime/status overlay now reacts to realtime node state events
- Gateway realtime path now emits full node state notifications for subscribe and execute flows
- Realtime execution-state notifications now update live execution rail
- Manual connection authoring/removal delivered in inspector
- Compatibility preview now blocks invalid edge types, duplicate edges, and occupied target inputs
- Canvas drag/drop positioning now persists through shared workflow graph metadata
- Shared workflow contracts now carry:
  - graph revision
  - node layouts
  - viewport
  - selected node
  - dashboards
  - node capabilities
  - runtime/streaming metadata
- Frontend save/update now uses contract-first workflow JSON payloads
- Gateway workflow detail/summary payloads now expose graph revision, dashboards, and run mode
- Realtime gateway now keeps subscriber state and broadcasts workflow save/execution changes beyond request-scoped replies
- Execution records now expose CPU/GPU resource-plan metadata and starter stream lifecycle metadata
- Frontend now renders thin dashboard v0 summary from workflow-bound dashboard definitions
- Frontend dashboard v0 composer now supports direct draft editing of dashboard bindings and chart definitions
- Starter Alpha node catalog expanded across source/transform/aggregate/control/stream/BI/sink categories
- Streaming MVP execution path now activates stream workflows through gateway/runtime and supports pause/resume/stop over JSON-RPC
- Stream stop now emits a `streaming.checkpoint.completed` notification payload for subscribed canvases
- Execution records now also expose dispatch plans with lane, worker pool, isolation mode, and accelerator metadata
- Batch GPU workflows now auto-transition into a queued isolated GPU lane with worker identity metadata
- Frontend execution rail now renders GPU dispatch context from live gateway payloads
- Docker Compose now includes an optional `gpu` profile hook for local isolated worker experiments
- Hub v0 skeleton now exists across contracts, gateway persistence/routes, frontend catalog shell, and install/enable flow scaffolding
- Test suite green after gateway regression fixes
- OpenAPI artifact refreshed to document current workflow, execution, checkpoint, and Hub REST surfaces
- README and repo-onboarding docs reconciled with current Alpha-core implementation
- New `services/worker-service/` module now owns stream/GPU worker-lifecycle transitions as a dedicated service seam
- API gateway now delegates stream/GPU activation and stream pause/resume/stop through worker-service while preserving existing API behavior
- New `scripts/run-stream-worker.jl` now supports out-of-process promotion of queued stream executions from persisted store state
- Docker Compose dev stack now includes a `stream-worker` service entry for local multi-process streaming experiments
- Gateway legacy polling path was added for worker-driven stream state rebroadcast before durable event consumer existed
- Execution payload deserialization now restores worker metadata into internal keys needed by worker-service and gateway sync logic
- New `scripts/run-gpu-worker.jl` now supports out-of-process promotion of queued GPU executions from persisted store state
- Docker Compose `gpu-worker` profile now runs the real GPU worker script rather than a placeholder sleep container
- Gateway legacy polling path also covered worker-driven GPU state rebroadcast before durable event consumer existed
- Worker-runtime Phase B slice is now complete across both stream and GPU lanes
- Milestone A thin event backbone slice now added:
  - durable event envelope/types added in contracts
  - append-only event log and consumer cursor persistence added for file/PostgreSQL repos
  - workflow/execution/Hub writes now dual-write durable events
  - stream checkpoint completion now emits durable event entries
  - gateway consumer path can replay events into existing websocket notifications without polling
  - legacy sync entrypoint now routes through durable consumer when backbone mode is enabled
  - worker-originated execution updates now carry producer identity through durable events
- Hub hardening slice now added:
  - manifest fields now include engine compatibility, contract version, supported checkpoints, dependencies, publisher identity, and release metadata
  - compatibility evaluator now emits warnings/blockers and blocks incompatible enable requests
  - Hub register endpoint now persists new extension catalog entries with evaluated compatibility
  - frontend Hub shell now surfaces compatibility status, blockers, warnings, and richer lifecycle controls
- BI publish/layout thin slice now added:
  - dashboard draft charts now persist panel layout metadata
  - published dashboard artifact store now exists separately from workflow draft state
  - gateway now supports publish/get published dashboard routes
  - frontend now supports publish button and published-vs-draft preview
- BI viewer/share slice now added:
  - frontend can now open URL-driven published dashboard viewer state
  - published dashboard surface now renders read-only cards with version/dataset metadata
  - share link action now emits viewer URL
- UI shell + UX foundation slice now added:
  - frontend now uses route-based product shell with dedicated Canvas, Dashboard, Hub, Monitor, and Settings views
  - canvas view remains authoring-first and removes roadmap/checkpoint clutter from primary screen
  - dashboard authoring and published viewer now live in dedicated BI workspace
  - Hub now has dedicated marketplace surface
  - runtime/checkpoint evidence moved into dedicated monitor surface
  - roadmap/checkpoint context moved into settings surface
- Contract/backend additions for UI/UX upgrade now added:
  - health payload now exposes realtime transport, event backbone mode, consumer poll interval, and worker modes
  - published dashboards now carry `visibility` and optional `shareToken`
  - workflow-scoped published dashboard listing route now exists
  - durable event schema now includes `dashboard.published`
  - Hub records now carry trust result, upgrade info, and installed version
  - Hub lifecycle now supports `upgrade`
  - gateway now blocks enabling unsigned partner extensions
- Canvas repository UX now groups starter nodes by family
- Access + diagnostics + provenance hardening slice now added:
  - published dashboard read route now enforces `shareToken` for public snapshots
  - workspace published dashboard read route now enforces `workspaceToken` via env-backed server gate
  - workspace published dashboard read route now also supports `Authorization: Bearer <workspace-token>`
  - contracts/OpenAPI/gateway client now include `shareToken` read parameter for published dashboard fetch
  - contracts/OpenAPI/gateway client now include `workspaceToken` read parameter for published dashboard fetch
  - OpenAPI now includes optional dashboard authorization header parameter for published-dashboard read route
  - frontend viewer now forwards URL share token when loading published dashboard
  - frontend viewer now forwards URL workspace token when loading workspace published dashboard
  - frontend viewer now supports env-configured workspace bearer token for workspace published-dashboard reads
  - health payload now adds event-log size + latest sequence, consumer cursor/lag, active stream count, queued stream count, active GPU count, queued GPU count, and worker-owned GPU count
  - health payload now also adds event-consumer catch-up percent and total queued/running execution counts
  - monitor surface now renders those additional runtime diagnostics
  - partner provenance now requires `sig:` signature format, signature identity binding, `https://` release-notes reference, and `hub://` package-ref scheme
  - Hub marketplace cards now display package reference and release notes provenance fields
  - BI dashboard draft workspace now supports duplicate/remove controls with single-draft guard, in addition to create/edit/publish/view flows
  - base extension now also includes `base.aggregate_rows` with direct extension tests
  - base extension now includes `base.filter_rows` node with extension tests
  - Julia gateway tests now explicitly cover release-notes URL trust blocker, partner-identity suffix blocker, signature identity binding blocker, package-ref scheme blocker, workspace token gate (missing/invalid/valid), and workspace bearer gate (invalid/valid)
  - Frontend BI workspace test now explicitly covers duplicate/remove dashboard composition flow
  - Frontend viewer tests now explicitly cover workspace bearer-auth fetch path
  - Contracts/frontend/julia tests now explicitly cover event-consumer catch-up and total queued/running execution diagnostics

### Gaps Pending

- BRD gap review on 2026-04-24 confirms Alpha shell is strong, but Phase 1 / Alpha is not complete yet
- Base node pack depth remains far below BRD target and several nodes still behave as placeholders
- BI publish/viewer exists, but chart-data service, semantic layer, live binding, and richer sharing/RBAC are pending
- Stream/GPU workers queue and promote execution state, but real Kafka/window/checkpoint runtime and GPU compute path are pending
- Hub trust/provenance gates exist, but publish UX, package hash verification, sandbox compatibility tests, and private mirror are pending
- Auth/RBAC, observability/performance gates, and production K8s/Helm manifests are still thin/scaffold-level

### Next Items To Implement

- follow `docs/TODO.md` P0 order
- execute `.omx/plans/brd-gap-review-2026-04-24.md` beginning with base node pack reality pass
- create `docs/brd-traceability.md` during first implementation slice
- update tracker/checkpoint/TODO after each P0 milestone closes

---

## Checkpoint: `cp/02-alpha-core` BRD Gap Review — 2026-04-24

### Work Done Till Date

- Reviewed current code/docs against `JuliaFlow_BRD_v1.0.docx`
- Created detailed execution plan at `.omx/plans/brd-gap-review-2026-04-24.md`
- Created/update TODO list at `docs/TODO.md`
- Re-ranked remaining work around real Alpha readiness rather than UI shell presence
- Verification passed for planning/doc update: `git diff --check`, `npm run test`, `npm run build`, `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`

### Gaps Pending

- Base node pack real behavior and breadth
- BI chart-data/semantic/live binding path
- Auth/RBAC and resource permission model
- Streaming adapter/window/checkpoint/backpressure runtime
- GPU compute execution path
- Hub publish/install sandbox and mirror flow
- Observability/performance/deployment hardening

### Next Items To Implement

- start with P0 base node pack reality pass
- then BI v0 data path
- then Auth/RBAC contract slice
- keep tracker, checkpoint, TODO, contracts, code, and tests synchronized

---

## Checkpoint: OMX Explore Tooling Fix — 2026-04-24

### Work Done Till Date

- Fixed `omx explore` startup on this machine after it failed because `cargo` was missing
- Installed user-local Rust toolchain / `cargo` via rustup for the packaged explore harness path
- Added `~/.codex/.omx-config.json` with `OMX_EXPLORE_SPARK_MODEL=gpt-5.4-mini` so explore no longer attempts unsupported `gpt-5.3-codex-spark` before fallback
- Verified:
  - `cargo --version` reports `cargo 1.95.0`
  - `omx explore --prompt "smoke: answer exact word OK"` returns `OK` without spark fallback noise
  - `omx doctor` reports Explore Harness ready; 13 passed, 1 warning, 0 failed

### Gaps Pending

- Product/BRD gaps remain unchanged: base node breadth, BI data path, Auth/RBAC, streaming runtime, GPU compute path, Hub hardening, observability/perf/deployment
- Tooling warning remains: legacy `~/.agents/skills` coexists with canonical `~/.codex/skills`

### Next Items To Implement

- Resume `docs/TODO.md` P0 order, starting with base node pack reality pass
- Cleanup legacy skill roots only if user explicitly wants duplicate-skill cleanup

---

## Checkpoint: P0 Base Node Pack Reality Pass — 2026-04-24

### Work Done Till Date

- Implemented first P0 base node pack reality pass from `docs/TODO.md`
- Base extension registry now exposes 25 Tier-1 nodes
- Added `TabularPayload.jl` helpers for inline-row materialization while preserving Arrow IPC payload shape
- Added `TierOneTableNodes.jl` with tested transform/combine/profile/BI nodes
- Replaced placeholder forwarding behavior for select/filter/aggregate/trainer when inline rows are present
- Added `docs/brd-traceability.md` as BRD evidence matrix
- Updated `extensions/base/src/README.md` with current node registry behavior

### Gaps Pending

- Storage-backed Arrow/DataFrames materialization for external `ref` payloads remains pending
- Node library still needs scale-up from 25 -> 75 -> 150+ BRD target
- BI chart-data path, Auth/RBAC, streaming runtime, GPU compute, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement storage-backed Arrow/DataFrames materialization or continue to BI v0 chart-data path depending on chosen P0 lane
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: BI Chart-Data Seam — 2026-04-24

### Work Done Till Date

- Added published dashboard chart-data route `/api/v1/dashboards/{dashboardId}/charts/{chartId}/data`
- Reused published-dashboard share/workspace token authorization for chart-data reads
- Added typed contract/client response `GatewayDashboardChartDataResponse` and `getPublishedDashboardChartData`
- Updated OpenAPI schema/path and contract tests
- Frontend published dashboard viewer now fetches chart data and displays row count + fields per chart
- Julia gateway tests cover authorized and unauthorized chart-data reads

### Gaps Pending

- Chart-data route currently returns deterministic seam data, not real outlet-backed datasets
- Semantic layer is minimal dimensions/measures metadata only
- Live outlet refresh/cache invalidation and richer renderers remain pending
- Auth/RBAC, streaming runtime, GPU compute, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Replace seam data with real BI outlet-backed chart datasets and semantic measures
- Then implement Auth/RBAC contract slice

---

## Checkpoint: Auth/RBAC Thin Slice — 2026-04-24

### Work Done Till Date

- Added auth context, auth mode, workspace role, and resource permission types to contracts
- Added OpenAPI `GatewayAuthContext` schema and auth health fields
- Added gateway dev-token auth mode using `JULIAFLOW_DEV_AUTH_TOKEN` and `JULIAFLOW_AUTH_MODE`
- Added owner/editor/viewer permission gates for workflow, execution, checkpoint, dashboard publish, and Hub mutation routes
- Kept public share-token and workspace dashboard-token paths separate from RBAC bearer token gates
- Added Julia gateway tests for token-required, viewer allowed read, viewer denied execute, editor allowed execute, and editor denied Hub install
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- Production OIDC/JWT validation is not implemented
- Persisted users/workspaces/roles and resource policies are not implemented
- Audit events for auth-sensitive operations are still pending
- Storage-backed node execution, real BI datasets/semantics, streaming runtime, GPU compute, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Add production OIDC/JWT + persisted policy/audit path or move to streaming runtime MVP depending P0 lane priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: External Ref Tabular Materialization Seam — 2026-04-24

### Work Done Till Date

- Added context-aware tabular materialization for external Arrow-shaped refs
- `TabularPayload.jl` now resolves rows from metadata stores, loader callbacks, `tabular_ref_root`, and local `file://` JSON/JSONL fixtures
- Select/filter/aggregate/trainer and Tier-1 table nodes now attempt external-ref materialization before returning non-materialized warnings
- Base extension tests now cover metadata-store and file-ref materialization paths
- Updated TODO, BRD traceability, extension README, tracker, and checkpoint state
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- Production Arrow/DataFrames readers for object-storage refs are still pending
- Node library still needs scale-up from 25 -> 75 -> 150+ BRD target
- Real BI datasets/semantics, production OIDC/RBAC, streaming runtime, GPU compute, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Add production Arrow/DataFrames object-storage adapter path or move to BI data-backed semantic/live path depending P0 lane priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: BI Published Artifact Dataset Slice — 2026-04-24

### Work Done Till Date

- Added optional published-dashboard `datasets` persistence for BI outlet row snapshots
- Publish path now snapshots rows from matching workflow `bi_outlets` entries
- Chart-data route now returns stored dataset rows when present, with synthetic fallback kept for dashboards without data snapshots
- Contracts/OpenAPI now expose `DashboardDatasetRow` and published dashboard dataset maps
- Updated Julia and contract tests to cover artifact-backed chart data
- Updated TODO, BRD traceability, tracker, and checkpoint state
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- BI semantic measures/dimensions remain field-hint level
- Live refresh/cache invalidation, drilldown/cross-filter, export, and full chart rendering remain pending
- Production Arrow/DataFrames node execution, production OIDC/RBAC, streaming runtime, GPU compute, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement BI semantic/live hardening or move to streaming runtime MVP depending P0 lane priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: BI Semantic Cache Export Slice — 2026-04-24

### Work Done Till Date

- Added inferred BI semantic metadata to published chart-data responses
- Added cache/live metadata: cache key, source version, snapshot time, refresh mode, live flag, stale flag
- Added CSV export route for published dashboard chart data while preserving share/workspace token auth
- Updated contracts/OpenAPI/client types and contract tests for semantic/cache/export surfaces
- Updated Julia gateway tests for semantic ordering, cache metadata, and CSV body
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- Live refresh/cache invalidation is not implemented
- Drilldown/cross-filter, export UX, and full chart renderer behavior remain pending
- Production Arrow/DataFrames node execution, production OIDC/RBAC, streaming runtime, GPU compute, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement live refresh/cache invalidation and renderer/export UX, or move to production OIDC/RBAC / streaming MVP depending active priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: Streaming Fixture Window Checkpoint MVP — 2026-04-24

### Work Done Till Date

- Added fixture streaming batch processor to worker service
- Added bounded batch processing using stream policy `max_in_flight_batches`
- Added window summaries using runtime window size and event timestamps/offsets
- Added stream diagnostics: adapter, processed offset/rows, batch count, consumer lag, backpressure, watermark, checkpoint id, checkpoint offsets
- Gateway checkpoint payloads now include replay offsets, watermark, consumer lag, and metadata-derived checkpoint id
- Execution payloads/contracts expose stream diagnostics with camelCase fields
- Added Julia tests and contract tests for fixture batch/window/checkpoint/diagnostic surfaces
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- Kafka/NATS adapters are still pending
- Durable replay runner and exactly-once proof are still pending
- Production watermarking and sink transaction semantics are still pending
- Production Arrow/DataFrames node execution, production OIDC/RBAC, GPU compute, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement production streaming adapters/replay/exactly-once hardening or move to GPU execution MVP depending active priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: GPU Registry Mock Fallback MVP — 2026-04-24

### Work Done Till Date

- Added GPU registry summary from env-configured worker devices
- Added GPU compute tick so worker can complete mock workload execution instead of only promoting queued jobs
- Added CPU fallback path for GPU-tagged jobs when GPU registry is empty
- Added execution metadata for GPU path, selected device, workload, registry, and computed result
- Added gateway health fields for GPU registry device count and fallback availability
- Updated contracts/OpenAPI and tests for new GPU execution and health surfaces
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- Real CUDA/KernelAbstractions kernels are still pending
- Device memory operations, stronger worker isolation guarantees, and multi-GPU scheduling are still pending
- Production Arrow/DataFrames node execution, production OIDC/RBAC, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Defer CUDA/multi-GPU hardening to the final hardware-gated GPU phase; continue unblocked production Arrow/DataFrames / OIDC work depending active priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: BI Live Render UX Slice — 2026-04-24

### Work Done Till Date

- Added differentiated frontend previews for line, bar, area, table, and metric published charts
- Added viewer cross-filter selection across published charts
- Added manual refresh action and live polling for live snapshot dashboards
- Added per-chart CSV export action to published viewer
- Viewer now surfaces semantic dimensions/measures and refresh summary per chart
- Updated frontend tests for share/workspace viewer chart-data fetches and rendered controls
- Updated AGENTS.md with session learnings on reasoning/model choice and bounded worker-script smoke tests
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- Cache invalidation beyond polling is still pending
- Drilldown/cross-filter and richer export/viewer polish are still pending
- Production Arrow/DataFrames node execution, production OIDC/RBAC, streaming production hardening, GPU production hardening, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement BI interaction hardening or move to production Arrow/DataFrames / OIDC hardening depending active priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: Object-Store Source Sink Roundtrip Slice — 2026-04-25

### Work Done Till Date

- Added local object-store ref path resolution for `object://` and `warehouse://` refs
- Arrow table source now materializes rows from local object-store-backed refs when store roots are present
- Arrow table sink now persists materialized rows into local object-store-backed refs when store roots are present
- Added base extension tests for source and sink object-store roundtrip behavior
- Updated README, TODO, BRD traceability, tracker, and checkpoint state
- Fresh verification evidence: `git diff --check`, `julia --project=. extensions/base/test/runtests.jl`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, and `npm run build` all pass

### Gaps Pending

- Real Arrow/DataFrames readers/writers for object storage are still pending
- Node library still needs scale-up from 25 -> 75 -> 150+ BRD target
- Production OIDC/RBAC, streaming production hardening, GPU production hardening, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement real Arrow/DataFrames object-storage adapters or move to production OIDC/RBAC depending active priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: BI Realtime Invalidation Slice — 2026-04-25

### Work Done Till Date

- Added realtime viewer invalidation on `dashboard.published` and `dashboard.outlet.updated` notifications
- Viewer now keeps selection summary visible after cross-filter interactions
- CSV export now respects filtered viewer state
- Updated TODO, BRD traceability, tracker, and tests to reflect interaction hardening progress

### Gaps Pending

- Deeper drilldown flows are still pending
- Richer export/viewer polish is still pending
- Production Arrow/DataFrames node execution, production OIDC/RBAC, streaming production hardening, GPU production hardening, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement deeper BI drilldown and richer viewer/export polish or move to production Arrow/DataFrames / OIDC hardening depending active priority
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: Auth Semantics And Protocol Drift Cleanup — 2026-04-25

### Work Done Till Date

- Gateway now maps common auth/share/workspace failures to clearer HTTP statuses:
  - `401` for invalid auth/share/workspace tokens
  - `403` for permission denials
  - `409` for Hub install checkpoint conflict
- Realtime protocol doc now includes `dashboard.published` to match current contracts and frontend behavior
- `docs/repo-onboarding.md` now reflects implemented BI publish/share, worker-service paths, durable event backbone thin slice, and current remaining production-depth gaps
- Fresh verification evidence:
  - `julia --project=. tests/julia/runtests.jl`
  - `node tests/contracts/workflow-schema.test.mjs`
  - `npm run test`
  - `npm run build`

### Gaps Pending

- Production OIDC/JWT validation, persisted roles/policy, and audit events are still pending
- Production Arrow/DataFrames node execution, streaming production hardening, GPU production hardening, Hub hardening, observability/perf/deployment remain pending
- Older plan artifacts still contain stale already-completed status for some P0 slices

### Next Items To Implement

- Implement real Arrow/DataFrames object-storage adapters or production OIDC/RBAC hardening depending active P0 priority
- Refresh older BRD-plan artifact wording if it blocks future execution decisions
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: Audit Event Foundation — 2026-04-25

### Work Done Till Date

- Added durable `audit.action` events for current mutating control-plane routes:
  - workflow create/import/update/execute
  - execution status transition
  - dashboard publish
  - checkpoint create
  - Hub register/install
- Contracts and durable event schema now include `audit.action`
- Added dedicated Julia test coverage confirming audit events persist with auth context and target metadata
- Fresh verification evidence:
  - `julia --project=. tests/julia/runtests.jl`
  - `node tests/contracts/workflow-schema.test.mjs`
  - `npm run test`
  - `npm run build`

### Gaps Pending

- Audit log query surfaces and admin UI are still pending
- Production OIDC/JWT validation and persisted workspace/user/role policy are still pending
- Production Arrow/DataFrames node execution, streaming production hardening, GPU production hardening, Hub hardening, observability/perf/deployment remain pending

### Next Items To Implement

- Implement production OIDC/RBAC hardening or real Arrow/DataFrames object-storage adapters depending active P0 priority and dependency constraints
- Refresh older BRD-plan artifact wording if it blocks future execution decisions
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized

---

## Checkpoint: BRD Endgame Traceability Guard — 2026-04-25

### Work Done Till Date

- Analyzed JuliaFlow repo against BRD, tracker/checkpoint state, TODO, traceability, and markdown docs.
- Created current endgame plan at `.omx/plans/repo-brd-endgame-2026-04-25.md`.
- Updated `AGENTS.md` with JuliaFlow end-goal delivery rules and evidence-gated milestone completion requirements.
- Added BRD traceability automation through `scripts/validate-brd-traceability.mjs`, `tests/contracts/brd-traceability.test.mjs`, and `npm run validate:brd-traceability`.
- Reconciled `docs/brd-traceability.md` checked TODO evidence rows plus stale auth/GPU status.
- Marked BRD traceability automation complete in `docs/TODO.md`.
- Fresh verification evidence:
  - `node scripts/validate-brd-traceability.mjs`
  - `node --test tests/contracts/brd-traceability.test.mjs`
  - `npm run validate:contracts`
  - `npm run validate:brd-traceability`
  - `npm run test`
  - `npm run build`
  - `git diff --check`
  - `julia --project=. extensions/base/test/runtests.jl`
  - `julia --project=. tests/julia/runtests.jl`

### Gaps Pending

- Production Arrow/DataFrames object-storage materialization and node scale-up remain the next P0 runtime blocker.
- Deeper BI drilldown/viewer/export polish remains pending.
- Production OIDC/JWT validation, persisted users/workspaces/roles, audit query/admin UI, and resource-policy UI remain pending.
- Kafka/NATS adapters, durable replay runner, exactly-once proof, production watermarking, and sink transactions remain pending.
- Real CUDA/KernelAbstractions kernels, device memory ops, worker isolation guarantees, and multi-GPU scheduling remain pending.
- Hub hardening, components/control-flow, observability/perf gates, deployment hardening, and node-library scale roadmap remain P1/P2 work.

### Next Items To Implement

- Resume P0 order with production Arrow/DataFrames object-storage materialization and staged node scale-up.
- Run `npm run validate:brd-traceability` whenever `docs/TODO.md` or `docs/brd-traceability.md` changes.
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized.

---

## Checkpoint: BRD Reanalysis / Next-Step Plan — 2026-04-28

### Work Done Till Date

- Reanalyzed JuliaFlow against current tracker/checkpoint state, TODO, BRD traceability, and prior plans.
- Confirmed Alpha P0 blockers remain production Arrow/DataFrames materialization, BI polish, production OIDC/RBAC, streaming production hardening, and GPU production hardening.
- Created current next-step plan at `.omx/plans/repo-brd-next-steps-2026-04-28.md`.
- Updated `docs/TODO.md` plan pointer and tracker state to reference the new plan.

### Gaps Pending

- Production Arrow/DataFrames object-storage materialization and staged node scale-up remain the next P0 runtime blocker.
- Deeper BI drilldown/viewer/export polish remains pending.
- Production OIDC/JWT validation, persisted users/workspaces/roles, audit query/admin UI, and resource-policy UI remain pending.
- Kafka/NATS adapters, durable replay runner, exactly-once proof, production watermarking, and sink transactions remain pending.
- Real CUDA/KernelAbstractions kernels, device memory ops, worker isolation guarantees, and multi-GPU scheduling remain pending.
- Hub hardening, components/control-flow, observability/perf gates, deployment hardening, and node-library scale roadmap remain P1/P2 work.

### Next Items To Implement

- Start with Stage 1 in `.omx/plans/repo-brd-next-steps-2026-04-28.md`: production Arrow/DataFrames materialization behind adapter seams plus node scale roadmap.
- Keep local/demo fallback paths while adding production-depth adapters and tests.
- Run `npm run validate:brd-traceability` whenever TODO/traceability status changes.
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized.

---

## Checkpoint: Production Materialization Adapter Seam — 2026-04-28

### Work Done Till Date

- `omx team` launch was attempted but blocked by dirty worktree guard (`leader_workspace_dirty_for_worktrees`), so implementation continued solo in the leader worktree to avoid stashing/reverting unrelated in-flight changes.
- Added production table materialization adapter seam for base nodes without adding new dependencies.
- Source/read callbacks now support `tabular_ref_reader`, `arrow_table_reader`, and `dataframe_reader` metadata entries.
- Sink/write callbacks now support `tabular_ref_writer`, `arrow_table_writer`, and `dataframe_writer` metadata entries.
- Source payloads preserve `format = :arrow_ipc` and `ref`, can propagate adapter-provided schema, and record `materialization_adapter` telemetry.
- Sink writes prefer configured writer adapter, then fall back to local JSON object-store path, and record `persistence_adapter` telemetry.
- Added extension tests for adapter-backed source read and sink write paths.
- Added `docs/node-library-roadmap.md` with stable / adapter-required / experimental quality tiers and 25 -> 75 -> 150 -> 300+ scale plan.
- Fresh verification:
  - `git diff --check`
  - `julia --project=. extensions/base/test/runtests.jl`
  - `julia --project=. tests/julia/runtests.jl`
  - `npm run validate:brd-traceability`
  - `npm run test`
  - `npm run build`

### Gaps Pending

- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 25 -> 75 -> 150 with stable/adapter-required test evidence.
- Deeper BI drilldown/viewer/export polish remains pending.
- Production OIDC/JWT validation, persisted policy/audit query/admin UI, streaming production hardening, GPU production hardening, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Implement package-backed Arrow/DataFrames object-store adapter on top of the new reader/writer seam, or continue node scale roadmap if dependency decision is deferred.
- Next slice should add package-backed Arrow/DataFrames object-store adapter or node-scale roadmap execution; full verification for this seam has passed.
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized.

---

## Checkpoint: Base Node Scale 35 Stable Nodes — 2026-04-28

### Work Done Till Date

- Advanced base node scale from 25 to 35 stable Tier-1 nodes.
- Added 10 stable cleanup/stat prep nodes: trim strings, normalize case, replace values, regex extract, validate schema, top-N rows, group filter, rolling mean, rank rows, and percentile rows.
- Registered and exported the new node types and node keys from the base extension.
- Added output-inspecting extension tests for all new nodes.
- Hardened local file materialization: `file://` refs now require `allow_file_refs = true` and configured root confinement; input/output row, column, and ref-byte caps are enforced by metadata limits with defaults.
- Updated base extension README, TODO, BRD traceability, and node-library roadmap for the 35-node baseline.
- Fresh targeted verification:
  - `julia --project=. extensions/base/test/runtests.jl`

### Gaps Pending

- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 35 -> 75 -> 150 with stable/adapter-required test evidence.
- Deeper BI drilldown/viewer/export polish remains pending.
- Production OIDC/JWT validation, persisted policy/audit query/admin UI, streaming production hardening, GPU production hardening, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Continue node scale toward 75 stable/adapter-required nodes or implement package-backed Arrow/DataFrames object-store adapter if dependency decision is available.
- Run full verification after integrated changes: `git diff --check`, extension tests, full Julia tests, `npm run validate:brd-traceability`, `npm run test`, and `npm run build`.
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized.

---

## Checkpoint: Base Node Scale 50 Stable Nodes — 2026-04-29

### Work Done Till Date

- Advanced base node scale from 35 to 50 stable Tier-1 nodes.
- Added 15 stable math/window/join/reshape nodes: coalesce columns, clip values, cumulative sum, rolling sum, lag column, string contains filter, column math, null-if, min-max scale, z-score, left join, anti join, union distinct, unpivot rows, and pivot rows.
- Registered and exported the new node types and node keys from the base extension.
- Added output-inspecting extension tests for all new nodes.
- Hardened local file materialization: `file://` refs now require `allow_file_refs = true` and configured root confinement; input/output row, column, and ref-byte caps are enforced by metadata limits with defaults.
- Updated base extension README, TODO, BRD traceability, node-library roadmap, tracker, and autopilot plan artifacts for the 50-node baseline.
- Fresh targeted verification:
  - `julia --project=. extensions/base/test/runtests.jl`

### Gaps Pending

- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 50 -> 75 -> 150 with stable/adapter-required test evidence.
- Deeper BI drilldown/viewer/export polish remains pending.
- Production OIDC/JWT validation, persisted policy/audit query/admin UI, streaming production hardening, GPU production hardening, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Continue node scale toward 75 stable/adapter-required nodes or implement package-backed Arrow/DataFrames object-store adapter if dependency decision is available.
- Run full verification after integrated changes: `git diff --check`, extension tests, full Julia tests, `npm run validate:brd-traceability`, `npm run test`, and `npm run build`.
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized.

---

## Checkpoint: GitHub Push Prep And Next-Step Plan — 2026-04-29

### Work Done Till Date

- Added a future-session handoff for the post-50-node baseline; the standalone handoff file was later removed during documentation cleanup.
- The handoff recorded sanity/repo cleanup, GitHub integration checks, production Arrow/DataFrames adapter work, node scale 50 -> 75, BI polish, and production hardening lanes.
- Verified GitHub target with `gh repo view Gravelaw/LowcodeMLtoolkit.jl`; authenticated account has admin permission.
- Merged existing remote BRD/license documents into local `main` instead of force-pushing over GitHub history.

### Gaps Pending

- Repo cleanup still needs a dedicated pass for generated tracked artifacts, binary/design assets, and release-tag/CI hygiene.
- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 50 -> 75 -> 150 with stable/adapter-required test evidence.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Start next session from the active tracker/TODO/checkpoint set.
- Run sanity checks after GitHub push and inspect remote CI/status if configured.
- Execute cleanup first, then production Arrow/DataFrames adapter or node scale 50 -> 75 depending dependency decision.

---

## Checkpoint: Base Node Scale 75 Stable Nodes — 2026-04-30

### Work Done Till Date

- Advanced base node scale from 50 to 75 stable Tier-1 nodes without adding dependencies.
- Added 25 stable date/time, grouped/window, join/enrich, BI-prep, profile/hash, and whitespace nodes.
- Registered/exported all new node keys and node types.
- Added output-inspecting extension tests for all 25 new nodes.
- Updated TODO, BRD traceability, node-library roadmap, base extension README, project tracker, and checkpoint log for the 75-node baseline.
- Fresh targeted verification:
  - `julia --project=. extensions/base/test/runtests.jl`

### Gaps Pending

- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 75 -> 150 with stable/adapter-required test evidence.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Implement package-backed/service-backed Arrow/DataFrames object-store adapter when dependency decision is available, or continue node scale 75 -> 150 with tested stable/adapter-required nodes.
- Run full verification after integrated changes: `git diff --check`, extension tests, full Julia tests, `npm run validate:brd-traceability`, `npm run test`, and `npm run build`.
- Keep `docs/TODO.md`, `docs/brd-traceability.md`, tracker, checkpoint, code, and tests synchronized.


---

## Checkpoint: Materialization Risk Mitigation — 2026-04-30

### Work Done Till Date

- Added risk register and mitigation plan for the production materialization dependency-choice risk.
- Implemented no-new-deps named service-backed adapter registry on top of `TabularPayload.jl`.
- Added registry read/write tests for `object://` source and `warehouse://` sink paths.
- Updated TODO, BRD traceability, node-library roadmap, base extension README, project tracker, and checkpoint log to distinguish risk mitigation from full package-backed completion.

### Gaps Pending

- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 75 -> 150 with stable/adapter-required test evidence.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Add package-backed Arrow/DataFrames object-store adapter when dependency approval is explicit, or collect deployment evidence for a production service adapter.
- Continue node scale 75 -> 150 with tested stable/adapter-required nodes.
- Keep BRD traceability evidence honest: service-backed registry mitigates risk; package-backed completion remains open.

---

## Checkpoint: Base Node Scale 100 And Arrow/DataFrames Materialization — 2026-04-30

### Work Done Till Date

- Advanced base node scale from 75 to 100 stable Tier-1 nodes.
- Added 25 deterministic column, string, numeric, grouped aggregate, bucket/encoding, BI metric, dashboard summary, and rows-to-columns nodes.
- Registered/exported all new node keys and node types.
- Added output-inspecting extension tests for all 25 new nodes.
- Added package-backed local Arrow/DataFrames materialization for root-confined `.arrow`, `.feather`, and `.ipc` refs behind `enable_arrow_dataframe_adapter = true`.
- Added root and base extension dependencies for `Arrow.jl`, `DataFrames.jl`, and `Tables.jl`.
- Preserved JSON/JSONL fallback, direct callback adapters, and named service-backed adapter registry precedence.
- Updated TODO, BRD traceability, node-library roadmap, base extension README, project tracker, and checkpoint log for the 100-node/package-backed baseline.

### Gaps Pending

- Base node library still needs scale from 100 -> 150 stable/adapter-required nodes.
- Remote/cloud object-storage adapter integration remains pending beyond the current root-confined local object-store-style path.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Continue node scale 100 -> 150 with tested stable/adapter-required nodes.
- Add remote/cloud object-store service adapter evidence or cloud package integration for production stores.
- Keep BRD traceability evidence honest: package-backed local Arrow/DataFrames materialization is complete; remote/cloud stores and node scale remain open.

---

## Checkpoint: Base Node Scale 125 Stable Nodes — 2026-05-01

### Work Done Till Date

- Advanced base node scale from 100 to 125 stable Tier-1 nodes.
- Added 25 deterministic advanced stats, ML scoring/evaluation, streaming prep, and Hub/package helper nodes.
- Registered/exported all new node keys and node types.
- Added output-inspecting extension tests for all 25 new nodes.
- Updated TODO, BRD traceability, node-library roadmap, base extension README, project tracker, and checkpoint log for the 125-node baseline.

### Gaps Pending

- Base node library still needs scale from 125 -> 150 stable/adapter-required nodes.
- Remote/cloud object-storage adapter integration remains pending beyond the current root-confined local object-store-style path.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Continue node scale 125 -> 150 with tested stable/adapter-required nodes.
- Add remote/cloud object-store service adapter evidence or cloud package integration once provider/credential decision exists.
- Keep BRD traceability evidence honest: package-backed local Arrow/DataFrames materialization and 125 stable nodes exist; remote/cloud stores and 150-node target remain open.

---

## Checkpoint: Remote Adapter And 150 Stable Nodes — 2026-05-01

### Work Done Till Date

- Added provider-neutral remote object-store adapter support for Arrow IPC base64 JSON envelopes on the `TabularPayload.jl` seam.
- Preserved direct callbacks, named registry adapters, package-backed local Arrow/DataFrames refs, and JSON/JSONL fallbacks.
- Advanced base node scale from 125 to 150 stable Tier-1 nodes.
- Added 25 deterministic quality, governance, feature engineering, streaming, and GPU-helper nodes.
- Registered/exported all new node keys and node types.
- Added output-inspecting extension tests for the 25 new nodes plus remote adapter read/write tests.
- Updated TODO, BRD traceability, node-library roadmap, base extension README, project tracker, and checkpoint log for the 150-node and remote-adapter baseline.

### Gaps Pending

- Provider-specific cloud object-store deployments/credentials and production manifests remain pending hardening work.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming adapters, production GPU kernels, Hub hardening, observability/perf, and deployment hardening remain pending.
- 300+ ecosystem breadth remains Beta/GA roadmap work after the 150-node Phase 1 baseline.

### Next Items To Implement

- Move to the next P0 BRD lane: BI drilldown/viewer/export polish or production OIDC/RBAC hardening.
- Add provider-specific cloud deployment evidence for remote object-store adapters when target provider/credentials are available.
- Keep BRD traceability evidence honest: 150 stable nodes and provider-neutral remote adapter are implemented; provider-specific deployments are hardening work.

---

## Checkpoint: BI Drilldown And Export Polish — 2026-05-03

### Work Done Till Date

- Added published-dashboard drilldown panel for selected chart rows.
- Preserved published snapshot read-only behavior and share/workspace token viewer compatibility.
- Added filtered CSV, full CSV, and selected-row JSON export controls in the viewer.
- Extended frontend tests for share-token viewer drilldown/export behavior.
- Updated `docs/TODO.md`, `docs/brd-traceability.md`, and `docs/project-tracker.md` for the completed P0 BI viewer polish slice.

### Gaps Pending

- Richer chart visualizations, downloadable export files, and server-side drill paths remain future BI enhancements.
- Production OIDC/RBAC, streaming, GPU, Hub, observability/perf, and deployment hardening remain open roadmap work.

### Next Items To Implement

- Start the next P0 hardening lane: production OIDC/JWT/RBAC or production streaming adapters/replay/exactly-once.
- Continue full verification before any milestone claim.

---

## Checkpoint: Next P0 Plan — Production OIDC/RBAC Hardening — 2026-05-03

### Work Done Till Date

- Confirmed BI drilldown/export polish is the latest completed P0 slice and production OIDC/RBAC is the next planned P0 lane.
- Added a risk-aware production OIDC/RBAC execution plan and acceptance criteria; the standalone plan file was later removed during documentation cleanup after its history was preserved here and in the tracker.
- Added `docs/risk-register.md` with active security, streaming, GPU, object-store, and Hub risks.
- Updated TODO and BRD traceability wording to point at the current plan and risk register without marking new implementation complete.

### Gaps Pending

- OIDC/JWT validation, persisted users/workspaces/roles/resource policies, audit query/admin UI, and policy management remain unimplemented.
- Streaming production hardening, GPU production hardening, provider-specific object-store deployment evidence, Hub hardening, observability/perf gates, and deployment hardening remain open roadmap gaps.

### Next Items To Implement

- Start production OIDC/RBAC hardening from contracts and OpenAPI, then gateway auth/repository seams, tests, and minimal UI/admin surfaces as needed.
- Preserve dev-token/disabled-auth, share-token, and workspace-token flows with regression tests.
- Burn down `R-SEC-001` through `R-SEC-004` in `docs/risk-register.md` before moving to streaming or GPU hardening.

---

## Checkpoint: OIDC/RBAC First Production-Hardening Slice — 2026-05-03

### Work Done Till Date

- Implemented the first production-auth hardening slice: OIDC-style JWT auth mode, persisted role/resource policies, audit policy-change events, and bounded redacted audit query API.
- Updated contracts/OpenAPI/event schema/client types and added Julia plus contract tests.
- Updated TODO, BRD traceability, tracker, and risk register without marking P0 auth complete.

### Gaps Pending

- JWKS/RSA or selected live IdP validation remains pending beyond HS256 fixture validation.
- Persisted users/workspaces admin model, resource-policy admin UI, broader security review, and PostgreSQL auth policy runtime evidence remain pending.
- Streaming/GPU production hardening remain next roadmap lanes after auth/security depth.

### Next Items To Implement

- Add live-provider OIDC/JWKS validation seam and key-rotation tests.
- Add minimal admin UI for users/workspaces/role bindings/resource policies and audit browsing.
- Re-run full verification and only check TODO P0 item 11 after code/test evidence covers the remaining gaps.


---

## Checkpoint: OIDC Discovery/JWKS Rotation Hardening — 2026-05-03

### Work Done Till Date

- Added mockable OIDC discovery/JWKS key resolution with `kid` lookup, HS256 JWKS fixture support, allowed-algorithm gating, and key-rotation tests.
- Exposed non-secret OIDC configuration status in gateway healthcheck and contract/OpenAPI types.
- Updated README, onboarding, TODO, traceability, tracker, and risk register.

### Gaps Pending

- RSA/live IdP validation, persisted users/workspaces admin model, resource-policy/audit admin UI, PostgreSQL runtime evidence, and broader security review remain pending.

### Next Items To Implement

- Implement selected-provider RSA/JWKS adapter or live IdP fixture path.
- Build minimal admin UI for role/resource-policy management and audit browsing.
- Keep full verification loop before any milestone claim.


---

## Checkpoint: Security Admin Policy/Audit Visibility — 2026-05-04

### Work Done Till Date

- Added read-only Settings visibility for persisted auth policy and redacted audit query data.
- Kept admin API calls optional so missing auth does not break live gateway loading.
- Updated frontend test coverage, TODO, traceability, tracker, and risk register.

### Gaps Pending

- RSA/live IdP validation, editable users/workspaces/resource-policy admin UI, PostgreSQL runtime evidence, and broader security review remain pending.

### Next Items To Implement

- Build editable admin UX for users/workspaces/role bindings/resource policies.
- Add selected-provider RSA/JWKS validation path.
- Keep full verification loop before any P0 auth milestone claim.


### Editable Auth Policy Admin UX (2026-05-04)

### Work Done Till Date

- Upgraded Settings security admin from read-only policy visibility to editable role-binding and resource-policy draft management.
- Added validation for required principal/workspace/resource fields and known permission names.
- Wired Save auth policy to the existing persisted auth-policy API in live mode and local state in demo mode.
- Extended frontend gateway tests to prove policy mutations send role/resource-policy update payloads.

### Gaps Pending

- RSA/live IdP validation remains pending.
- Persisted users/workspaces directory UI remains pending beyond free-form policy principal/workspace IDs.
- PostgreSQL-backed auth policy runtime evidence and broader security review remain pending.

### Next Items To Implement

- Add selected-provider RSA/JWKS validation path or documented adapter fixture.
- Add persisted users/workspaces directory admin surface and PostgreSQL auth-policy runtime evidence.
- Keep P0 auth TODO unchecked until live-provider, directory/admin, and review evidence exist.

---

## Checkpoint: Repo BRD Reanalysis And Pending Implementation Plan — 2026-05-05

### Work Done Till Date

- Analyzed current repo implementation against the BRD, `docs/TODO.md`, `docs/brd-traceability.md`, tracker/checkpoint docs, `.omx/plans`, `.omx/context`, `.omx/reviews`, and `.omx/state`.
- Confirmed latest completed P0 slices: materialization/150-node baseline and BI viewer polish; confirmed auth hardening is partially complete but still open.
- Created `.omx/plans/repo-brd-pending-implementation-plan-2026-05-05.md` with staged implementation order and acceptance/verification gates.

### Gaps Pending

- P0 auth: RSA/live IdP validation, users/workspaces directory admin model, PostgreSQL runtime evidence, and broader security review.
- P0 streaming: Kafka/NATS adapters, replay/exactly-once proof, watermarking, and sink transactions.
- Final hardware-gated GPU: real CUDA/KernelAbstractions kernels, device memory operations, isolation, and multi-GPU scheduling.
- P1/P2: Hub publish/install hardening, components/control-flow, observability/perf gates, and deployment hardening.

### Next Items To Implement

- Implement Stage 1 auth completion plan first, preserving dev-token/disabled/share/workspace-token flows.
- Use dependency-expert review before adding RSA/JWT, Kafka/NATS, or CUDA/KernelAbstractions dependencies.
- Update TODO/traceability only with code/test/review evidence and run `npm run validate:brd-traceability` after any TODO/traceability status change.

---

## Checkpoint: Auth Directory Admin Slice — 2026-05-05

### Work Done Till Date

- Implemented persisted user/workspace directory contracts, repository persistence, gateway admin routes, active directory runtime enforcement, directory self-lockout prevention, durable/audit events, Settings editing UX, and tests.
- Preserved existing dev-token/disabled/OIDC HS256, share-token, workspace-token, role/resource-policy, and audit query paths.
- Updated TODO, BRD traceability, tracker, checkpoint, and risk register without marking P0 auth complete.

### Gaps Pending

- RSA/live IdP validation, PostgreSQL runtime evidence, and broader security review remain before P0 auth completion.
- Streaming production hardening and GPU production hardening remain next P0 lanes after auth/security depth.

### Next Items To Implement

- Complete full verification and code review for this slice.
- Decide/implement RSA/JWKS live-provider validation path with security/dependency review.
- Run PostgreSQL auth directory/policy evidence when `JULIAFLOW_TEST_POSTGRES_URL` is available.

---

## Checkpoint: Auth Directory Admin Verification And Review — 2026-05-06

### Work Done Till Date

- Completed local review for the auth directory admin slice after subagent quota failure.
- Hardened directory enforcement to reject inactive/missing runtime principals/workspaces when records exist.
- Added self-lockout prevention for directory updates and tests for disabled-user denial plus lockout rejection.
- Verified frontend, Julia, contract, BRD traceability, build, and diff whitespace checks.

### Gaps Pending

- RSA/live IdP validation, PostgreSQL runtime evidence, and broader security review remain before P0 auth completion.
- Streaming production hardening and GPU production hardening remain next P0 lanes after auth/security depth.

### Next Items To Implement

- Decide/implement RSA/JWKS live-provider validation path with security/dependency review.
- Run PostgreSQL auth directory/policy evidence when `JULIAFLOW_TEST_POSTGRES_URL` is available.
- Keep P0 auth TODO unchecked until live-provider, PostgreSQL runtime, and security-review evidence exist.

---

## Checkpoint: RS256 OIDC/JWKS Validation Slice — 2026-05-06

### Work Done Till Date

- Added no-new-dependency RS256 JWT verification against OIDC discovery/JWKS metadata.
- Implemented RSA JWK lookup plus PKCS#1 v1.5 SHA-256 signature validation in the gateway.
- Added Julia coverage for valid RS256 token acceptance and tampered RS256 signature rejection.
- Kept P0 auth TODO unchecked and documented remaining external live-IdP, PostgreSQL runtime, and broader security-review gaps.

### Gaps Pending

- External live-IdP smoke remains pending because no provider credentials/metadata target were supplied.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Broader security review remains pending before P0 auth completion.
- Streaming production hardening and GPU production hardening remain next P0 lanes after auth/security depth.

### Next Items To Implement

- Complete full verification and code review for this RS256 slice.
- Add external IdP smoke evidence when provider/credentials are available.
- Run PostgreSQL auth directory/policy evidence when `JULIAFLOW_TEST_POSTGRES_URL` is available.

---

## Checkpoint: RS256 OIDC/JWKS Verification And Review — 2026-05-06

### Work Done Till Date

- Completed local code review for RS256 OIDC/JWKS validation.
- Added review-driven 2048-bit minimum RSA modulus enforcement.
- Verified frontend, Julia, contract, BRD traceability, build, and diff whitespace checks.

### Gaps Pending

- External live-IdP smoke remains pending because no provider credentials/metadata target were supplied.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Broader security review remains pending before P0 auth completion.
- Streaming production hardening and GPU production hardening remain next P0 lanes after auth/security depth.

### Next Items To Implement

- Run PostgreSQL auth directory/policy evidence when `JULIAFLOW_TEST_POSTGRES_URL` is available.
- Add external IdP smoke evidence when provider/credentials are available.
- Run broader auth security review before marking P0 auth complete.

---

## Checkpoint: Auth Security Review — 2026-05-06

### Work Done Till Date

- Completed broader local auth/RBAC security review after directory admin and RS256 JWKS hardening.
- Added `docs/security/auth-security-review-2026-05-06.md`.
- Confirmed no critical, high, or medium local-review findings.
- Preserved P0 auth as open for external live-IdP smoke and PostgreSQL runtime evidence.

### Gaps Pending

- External live-IdP smoke remains pending because no provider credentials/metadata target were supplied.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Streaming production hardening and GPU production hardening remain next P0 lanes after auth/security depth.

### Next Items To Implement

- Run PostgreSQL auth directory/policy evidence when `JULIAFLOW_TEST_POSTGRES_URL` is available.
- Add external IdP smoke evidence when provider/credentials are available.
- If auth evidence remains credential-blocked, proceed to next P0 lane: streaming production hardening.

---

## Checkpoint: Streaming Exactly-Once Fixture Slice — 2026-05-06

### Work Done Till Date

- Added committed-offset metadata, sink transaction IDs, idempotency keys, and duplicate replay suppression for fixture streaming.
- Exposed stream exactly-once/replay metadata through repository payloads, contracts, and OpenAPI.
- Added Julia worker and contract coverage for duplicate replay suppression and transaction metadata.

### Gaps Pending

- Kafka/NATS adapters remain pending.
- Durable replay runner across process restarts remains pending beyond fixture duplicate suppression.
- Production watermarking and external sink transactions remain pending.
- GPU production hardening remains queued after streaming depth.

### Next Items To Implement

- Add Kafka/NATS adapter contract fixtures without new runtime dependencies.
- Add durable replay runner evidence across restart using persisted checkpoint offsets.
- Add production watermark and external sink transaction tests before checking P0 streaming complete.

---

## Checkpoint: Streaming Adapter Contract Slice — 2026-05-06

### Work Done Till Date

- Added Kafka/NATS adapter contract metadata without adding runtime broker dependencies.
- Exposed adapter contract metadata through repository payloads, contracts, and OpenAPI.
- Added Julia worker tests for Kafka/NATS contract metadata and contract schema assertions.

### Gaps Pending

- Runtime Kafka/NATS clients remain pending until dependency/provider approval.
- Durable replay runner across process restarts remains pending beyond fixture duplicate suppression.
- Production watermarking and external sink transactions remain pending.
- GPU production hardening remains queued after streaming depth.

### Next Items To Implement

- Add durable replay runner evidence across restart using persisted checkpoint offsets.
- Add runtime Kafka/NATS clients after dependency/provider decision.
- Add production watermark and external sink transaction tests before checking P0 streaming complete.

---

## Checkpoint: Streaming Restart Replay Slice — 2026-05-07

### Work Done Till Date

- Added fixture restart replay coverage for streaming worker recovery from persisted committed offsets.
- Updated `replay_stream_fixture_batch!` so replay at the committed checkpoint resumes with the next unprocessed fixture events and records restored replay metadata.
- Added Julia worker tests that sync a fresh `WorkerServiceState` from persisted executions, resume from the committed offset, and verify prior rows are not reprocessed.

### Gaps Pending

- Runtime Kafka/NATS clients remain pending until dependency/provider approval.
- Production watermarking and external sink transactions remain pending.
- Live broker restart proof remains dependency/provider-gated beyond the no-new-dependency fixture restart evidence.
- GPU production hardening remains queued after streaming depth.

### Next Items To Implement

- Add production watermark and external sink transaction tests before checking P0 streaming complete.
- Add runtime Kafka/NATS clients after dependency/provider decision.
- Add live broker restart evidence once a broker/provider target is available.

---

## Checkpoint: Streaming Watermark Transaction State Slice — 2026-05-07

### Work Done Till Date

- Added policy-aware watermark handling for fixture streaming so processing-time and event-time modes produce explicit monotonic committed watermark state.
- Added fenced sink transaction state metadata alongside transaction IDs and idempotency keys.
- Exposed watermark state and sink transaction state through gateway payloads, TypeScript contracts, and OpenAPI.
- Added Julia worker coverage for processing-time/event-time watermark behavior and contract coverage for the new payload fields.

### Gaps Pending

- Runtime Kafka/NATS clients remain pending until dependency/provider approval.
- Live external sink transaction backend evidence remains pending beyond fenced fixture transaction metadata.
- Live broker restart proof remains dependency/provider-gated beyond fixture restart evidence.
- GPU production hardening remains queued after streaming depth.

### Next Items To Implement

- Add runtime Kafka/NATS clients after dependency/provider decision.
- Add live broker restart and external sink transaction backend evidence once services are available.
- Move to GPU production hardening if streaming runtime dependencies remain blocked.

---

## Checkpoint: GPU Production-Hardening Prep Slice — 2026-05-07

### Work Done Till Date

- Added no-new-dependency GPU placement/dispatch metadata for deterministic multi-device scheduling prep.
- Worker runtime now records requested device, selected device, fallback reason, placement reason, scheduler policy, worker isolation mode, and capacity metadata.
- Invalid requested devices fall back to deterministic GPU placement with explicit reason; CPU fallback remains reserved for empty GPU registry/no matching device availability.
- Contracts/OpenAPI/gateway mapping and Julia tests were updated for the metadata shape.

### Gaps Pending

- Real CUDA/KernelAbstractions kernels, device-memory operations, and hardware-backed multi-GPU isolation remain pending.
- CUDA/KernelAbstractions dependency and hardware/CI approval are still required before checking final GPU production closure complete.

### Next Items To Implement

- Complete full verification: Julia suite, npm test/build, BRD traceability validator, and diff whitespace check.
- If GPU dependencies/hardware are approved, implement a small real kernel/device-memory smoke path behind explicit gates.
- Otherwise keep GPU production-hardening P0 open and move to other unblocked P1/P2 hardening.

---

## Checkpoint: BRD Reanalysis And Next-Step Plan — 2026-05-07

### Work Done Till Date

- Compared BRD/control docs/checkpoints against current implementation and uncommitted GPU prep state.
- Saved next-step plan at `.omx/plans/repo-brd-next-steps-2026-05-07.md`.
- Confirmed `npm run validate:brd-traceability` and `git diff --check` pass during planning.

### Gaps Pending

- Existing GPU prep slice still needs full Julia, JS, build, traceability, and review evidence before further scope.
- Auth live-IdP/PostgreSQL, streaming live broker/sink, and real CUDA/KernelAbstractions evidence remain open.

### Next Items To Implement

- Complete verification/review for GPU production-hardening prep.
- Decide whether to proceed to gated CUDA/KernelAbstractions smoke or pivot to unblocked P1 Hub hardening.
- Keep P0 TODO items unchecked until traceability has live/provider/hardware evidence.

---

## Checkpoint: GPU Production-Hardening Prep Verification — 2026-05-08

### Work Done Till Date

- Completed full verification for the no-new-dependency GPU placement/dispatch prep slice.
- Evidence passed: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:brd-traceability`, `git diff --check`, and bounded `JULIAFLOW_WORKER_ONCE=1 julia --project=. scripts/run-gpu-worker.jl` smoke.
- Kept final GPU production closure open because this is still metadata/mock-worker prep, not real CUDA/KernelAbstractions compute evidence.

### Gaps Pending

- Real CUDA/KernelAbstractions kernels, device-memory operations, hardware-backed isolation, and multi-GPU scheduling evidence remain pending.
- Auth live-IdP/PostgreSQL and streaming live broker/sink evidence remain credential/provider/dependency-gated.

### Next Items To Implement

- Complete code review for the verified GPU prep diff.
- If review is clean, choose next lane: gated CUDA/KernelAbstractions smoke when approved, otherwise P1 Hub publish/install hardening.
- Keep P0 TODO items unchecked until traceability has live/provider/hardware evidence.

---

## Checkpoint: GPU Prep Review Fixes — 2026-05-08

### Work Done Till Date

- Fixed review-found GPU requested-device alias drift and tracker timestamp.
- Added explicit GPU CPU-fallback, placement-fallback, and request-satisfied metadata so observability can distinguish CPU fallback from deterministic GPU placement fallback.
- Added regression coverage for flow-variable dispatch override and `nvidia:1` request alias placement.

### Gaps Pending

- Real CUDA/KernelAbstractions kernel/device-memory evidence remains pending before final GPU production closure.
- Capacity schema can be hardened when the real GPU backend shape is known.

### Next Items To Implement

- Rerun full verification after review fixes.
- Rerun code review and complete autopilot only on `APPROVE` plus architecture `CLEAR`.
- Keep final hardware-gated GPU item unchecked until real GPU evidence exists.

---

## Checkpoint: GPU Prep Review Fix Verification — 2026-05-08

### Work Done Till Date

- Reran full verification after review fixes.
- Evidence passed: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:brd-traceability`, `git diff --check`, and bounded `JULIAFLOW_WORKER_ONCE=1 julia --project=. scripts/run-gpu-worker.jl` smoke.

### Gaps Pending

- Real CUDA/KernelAbstractions kernel/device-memory evidence remains pending before final GPU production closure.
- Final code-review rerun is still required before autopilot completion.

### Next Items To Implement

- Rerun code review on the fixed diff.
- If clean, close autopilot with verification evidence.
- Keep final hardware-gated GPU item unchecked until real GPU evidence exists.

---

## Checkpoint: GPU Prep Autopilot Completion — 2026-05-08

### Work Done Till Date

- Completed `$autopilot` loop for GPU production-hardening prep stabilization.
- Final verification passed: Julia suite, npm test, npm build, BRD traceability validator, diff whitespace check, bounded GPU worker smoke.
- Final code review passed with `APPROVE`; architecture review passed with `CLEAR`.

### Gaps Pending

- Real CUDA/KernelAbstractions kernel/device-memory/hardware evidence remains required before checking final GPU production closure complete.
- Auth live-IdP/PostgreSQL and streaming live broker/sink evidence remain provider/dependency-gated.

### Next Items To Implement

- Choose next lane: gated CUDA/KernelAbstractions smoke if approved, otherwise P1 Hub publish/install hardening.
- Preserve no-new-dependency fallback paths and honest P0 traceability.
- Commit/push only when requested or when delivery scope includes GitHub handoff.

---

## Checkpoint: Hub Publish/Install Hardening — 2026-05-09

### Work Done Till Date

- Implemented Alpha Hub publish/install hardening metadata path: artifact hashes, sandbox command metadata, private/offline mirror refs, trust/compatibility blockers, gateway publish registration, persisted catalog roundtrip, and frontend publish sample UX.
- Updated TODO, BRD traceability, risk register, project tracker, and checkpoint log for the completed P1 scope.
- Initial verification passed for `npm run test` and `julia --project=. tests/julia/runtests.jl` after code/test changes.

### Gaps Pending

- Full final verification still requires build, BRD traceability validator, whitespace diff check, and review pass before commit.
- Future Hub production depth remains: execute sandbox commands, verify downloaded artifact hashes, and test real private/offline registry mirrors.
- Remaining P0 gates are external-provider/hardware-dependent.

### Next Items To Implement

- Run final verification: `npm run build`, `npm run validate:brd-traceability`, `git diff --check`, plus rerun failed checks if any.
- Run code/architecture review; commit only if clean.
- Continue next unblocked gap after commit: P1 components/control-flow contracts or observability/perf gates.

---

## Checkpoint: Hub Hardening Review Fix Completion — 2026-05-09

### Work Done Till Date

- Closed review findings for Hub publish/install hardening: artifact hash validation now applies to official and partner manifests, required manifest shapes are enforced, Hub install/enable/upgrade are blocked when trust or compatibility fails, and local-file mirror refs are rejected for Hub mirrors.
- Frontend Hub lifecycle gating now still allows disabling already-enabled unsafe extensions while blocking install/enable/upgrade remediation-risk actions.
- Added regression coverage for malformed hash payloads, official bad/missing hashes, official/partner local-file mirror rejection, unsafe enable attempts, persistence roundtrip, and UI disable parity.

### Gaps Pending

- External/provider gates remain: live IdP/PostgreSQL, Kafka/NATS/live sink, and real CUDA/KernelAbstractions hardware evidence.
- Future Hub depth remains: actual sandbox execution, artifact download verification, and real private registry mirror smoke.
- Native subagent re-review was attempted but blocked by usage-limit errors; local verification and manual review were completed instead.

### Next Items To Implement

- Commit the verified Hub hardening slice.
- Continue next unblocked local gap: P1 components/control-flow contracts or observability/perf gates, unless external provider/hardware approval arrives.

---

## Checkpoint: Remaining P0 Live-Evidence Harness Slice — 2026-05-09

### Work Done Till Date

- Added reproducible gated smoke harnesses for remaining P0 external evidence: Keycloak/PostgreSQL auth, Kafka streaming replay/sink idempotency, and CUDA/KernelAbstractions GPU compute.
- Added worker-service support for Kafka captured-event replay and file-backed fenced sink idempotency state, with Julia regression coverage.
- Added CUDA/KernelAbstractions dependencies and a gated real-kernel smoke script.

### Gaps Pending

- Auth P0 still needs the Keycloak/PostgreSQL smoke to pass and be recorded as evidence.
- Streaming P0 still needs the live Kafka smoke to pass and be recorded as evidence.
- Final hardware-gated GPU item still needs real CUDA smoke plus multi-GPU scheduling evidence on >=2 visible devices; this host only reports one CUDA GPU.

### Next Items To Implement

- Run the three smoke commands from README and record outputs in traceability before changing TODO checkboxes.
- Keep P0 TODO items 11, 13, and 15 open until all required live/provider/hardware evidence exists.
- Use the smoke outputs to fix any live-environment drift in Keycloak claims, Kafka consumption, or CUDA runtime setup.

---

## Checkpoint: Auth And Streaming P0 Live Evidence Closure — 2026-05-09

### Work Done Till Date

- Passed live auth smoke: `./scripts/smoke-keycloak-postgres-auth.sh` returned JSON evidence for Keycloak RS256, PostgreSQL repository, protected route access, policy/directory persistence, and audit query.
- Passed live streaming smoke: `./scripts/smoke-kafka-streaming.sh` returned JSON evidence for Kafka consume/replay, committed offset 3, duplicate suppression, and fenced sink output with 3 rows.
- Marked TODO P0 items 11 and 13 complete and linked evidence in `docs/brd-traceability.md`.

### Gaps Pending

- Final hardware-gated GPU item remains open because this host exposes one CUDA device and the final hardware-gated plan requires >=2 visible devices for multi-GPU scheduling evidence.
- Provider-specific production deployments still need target-provider smoke repeats even though local-platform P0 evidence is complete for auth and Kafka streaming.

### Next Items To Implement

- Run the multi-GPU CUDA/KernelAbstractions smoke on suitable hardware.
- Keep Final Hardware-Gated Phase GPU item unchecked until multi-GPU evidence is linked.
- Rerun final verification after any GPU closure change.

---

## Checkpoint: GPU Hardware Constraint Rephase — 2026-05-10

### Work Done Till Date

- Moved GPU production hardening / multi-GPU closure to the Final Hardware-Gated Phase because GPU count is an environment constraint.
- Updated control docs and developer-facing docs so one-device CUDA/KernelAbstractions smoke is recorded as useful evidence, not a blocker for near-term P1/P2 progress.
- Kept auth/RBAC and Kafka streaming P0 local-platform closures unchanged.

### Gaps Pending

- Final GPU closure still requires >=2 visible CUDA devices, hardware-backed worker isolation proof, and linked multi-GPU scheduling evidence.
- Provider-specific production smokes remain needed for auth, PostgreSQL, Kafka/NATS, sinks, and object-store deployments.

### Next Items To Implement

- Proceed with unblocked P1/P2 work unless a >=2-device GPU runner becomes available.
- When hardware exists, run `JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1 julia --project=. scripts/smoke-cuda-kernel.jl`, link evidence, and rerun BRD traceability validation.

---

## Checkpoint: P0 Closure Verification And Commit Prep — 2026-05-10

### Work Done Till Date

- Verified P0 closure state: `docs/TODO.md` P0 has 14 checked items and zero unchecked items; GPU multi-GPU closure is no longer P0 and is tracked in Final Hardware-Gated Phase.
- Fresh evidence passed: live Keycloak/PostgreSQL auth smoke, live Kafka streaming smoke, Julia suite, npm test, npm build, BRD traceability validator, diff whitespace check, bounded GPU worker smoke, and one-device CUDA/KernelAbstractions smoke.

### Gaps Pending

- Final GPU closure still needs >=2 visible CUDA devices plus linked hardware-backed isolation and multi-GPU scheduling evidence.
- Provider-specific production smokes remain pending for chosen external IdP, managed PostgreSQL, managed Kafka/NATS, sinks, and object stores.

### Next Items To Implement

- Commit all latest verified changes.
- Continue P1/P2 lanes unless final GPU hardware becomes available.
---

## Checkpoint: Components/Control-Flow Contract Slice — 2026-05-12

### Work Done Till Date

- Added P1 workflow metadata contracts for containers, components, switch/case, loop, try/catch, and parallel chunk definitions across TypeScript contracts, OpenAPI, JSON schema, gateway mapping, and Julia parser/serializer/validator.
- Added foundation fixture coverage, Julia validation coverage, contract assertions, and frontend Canvas inspector visibility for component/control-flow bindings.
- Verified initial evidence: `julia --project=. tests/julia/runtests.jl` and `npm run test` passed before documentation closure.

### Gaps Pending

- Full runtime execution semantics for loop and try/catch nodes remain future Beta work beyond the current P1 contract/validation slice.
- Observability/perf gates, production deployment manifests, provider-specific object-store proof, and final >=2-device GPU closure remain open.

### Next Items To Implement

- Continue P1 observability/perf gates: OTel/Prometheus seam, 1,000-node render harness, node dispatch microbench, and coverage thresholds.
- Then continue P2 deployment hardening with real K8s/Helm/Kustomize service manifests.
- Return to final GPU closure only when >=2 visible CUDA devices are available.
---

## Checkpoint: Observability/Perf First Gate Slice — 2026-05-12

### Work Done Till Date

- Added a Prometheus-style `/metrics` endpoint with workflow, execution, durable event-log, consumer-lag, queued, and running execution gauges.
- Added OpenAPI coverage for `/metrics`.
- Added `npm run validate:perf`, combining a 1,000-node/500-connection render harness and a Julia dispatch microbench.
- Verified `npm run validate:perf` passed with render `elapsedMs` under 500 ms and dispatch average under the configured threshold.

### Gaps Pending

- P1 observability/perf item remains unchecked until fuller OTel integration and real coverage thresholds land.
- Production deployment manifests remain P2 open.
- Final hardware-gated GPU closure remains blocked on >=2 visible CUDA devices.

### Next Items To Implement

- Add coverage threshold enforcement compatible with the existing test stack.
- Add OTel trace/span seam around gateway request handling and execution dispatch.
- Continue deployment hardening after observability/perf item can be checked with traceability evidence.

### Observability/Perf Trace And Coverage Surface Slice — 2026-05-13

### Work Done Till Date

- Added no-new-dependency OTel-style trace/span metadata for gateway HTTP routing and execution dispatch planning.
- Exposed observability span counters through health/metrics surfaces and contract/OpenAPI execution trace fields.
- Added `npm run validate:coverage` as a dependency-free coverage-surface threshold gate across frontend, contracts, Julia gateway/execution, and base extension tests.
- Verified: `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:perf`, `npm run validate:coverage`, `npm run validate:brd-traceability`, and `git diff --check` passed.

### Gaps Pending

- P1 observability/perf item remains unchecked until real coverage-provider thresholds are approved or equivalent threshold evidence is accepted.
- Production deployment manifests remain P2 open.
- Final hardware-gated GPU closure remains blocked on >=2 visible CUDA devices.

### Next Items To Implement

- Either add real coverage-provider thresholds with approved dependency support or move to P2 deployment hardening.
- Keep `npm run validate:coverage` in the standard observability/perf gate until a real provider replaces it.
- Continue deployment hardening after observability/perf evidence is stable.

### P1 Observability/Perf Closure — 2026-05-13

### Work Done Till Date

- Selected the official Vitest v8 coverage provider path and added `@vitest/coverage-v8` to the frontend workspace.
- Configured real coverage thresholds in `apps/frontend/vite.config.ts` for `App.tsx` and `sample-workflow.ts`.
- Wired `npm run validate:coverage` to run real Vitest coverage plus the dependency-free cross-surface coverage inventory, and added `npm run validate:p1` for perf + coverage + BRD traceability.
- Marked P1 Observability/perf gates complete after linking TODO traceability evidence.
- Verified P1 closure gates: `npm run validate:p1`, `npm run test`, `npm run build`, and `julia --project=. tests/julia/runtests.jl` passed after real coverage thresholds landed.

### Gaps Pending

- P1 is complete.
- P2 deployment hardening remains open.
- Final hardware-gated GPU closure remains blocked on >=2 visible CUDA devices.

### Next Items To Implement

- Start P2 deployment hardening: replace ArgoCD placeholders with real Deployment/Service/Ingress/SecretRef manifests and production overlays.
- Keep coverage thresholds ratcheted upward as more frontend tests land.
- Return to final GPU closure only when >=2 visible CUDA devices are available.

---

## Checkpoint: P2 Deployment Hardening — 2026-05-14

### Work Done Till Date

- Replaced placeholder ArgoCD workload intent ConfigMaps with Kustomize bases and dev overlays for API Gateway, Execution Service, Frontend, and provider-neutral platform dependency seams.
- Added workload manifests for Deployments, Services, runtime ConfigMaps, dev Ingresses, and secret templates without committing real credentials.
- Fixed review blockers: AppProject now whitelists `argoproj.io/Application`; API Gateway dev defaults avoid required Postgres/OIDC secrets and require a dev auth token for protected routes; Execution Service runs a real HTTP health/metrics runner; frontend runtime config is mounted as `juliaflow-config.js` and read before Vite env fallback.
- Kept platform dependencies provider-neutral by declaring namespace, service contracts, secret templates, and dependency-contract metadata instead of fake production PostgreSQL/Kafka/Keycloak/MinIO/Redis workloads.
- Added `scripts/validate-k8s-manifests.sh` and `npm run validate:k8s` for render/static validation, including AppProject app-of-apps policy checks and structural YAML fallback when kubectl/kustomize is unavailable.

### Gaps Pending

- Provider-specific staging/prod overlays and live cluster server-side dry-run evidence remain pending until target providers/cluster access exist.
- External production smoke repeats remain needed for managed IdP/PostgreSQL/Kafka/NATS/object-store choices.
- Final hardware-gated GPU closure remains blocked until >=2 visible CUDA devices exist.

### Next Items To Implement

- Add selected-provider overlays and secret delivery integration (for example ExternalSecrets/SealedSecrets/provider-native secret sync) without committing credentials.
- Run `kubectl apply --dry-run=server -k ...` against a configured cluster for all workload overlays.
- Continue provider-specific object-store deployment proof or GA release-hardening gates next.
---

## Checkpoint: Agent Guidance / Future Module Skill Routing — 2026-05-14

### Work Done Till Date

- Added concise `AGENTS.md` guidance for future module delivery, skill invocation, frontend-heavy work, Julia language/syntax work, provider deployment work, and native subagent usage.
- Added repo-local skills: `juliaflow-control-loop`, `juliaflow-julia-development`, `juliaflow-frontend-development`, and `juliaflow-provider-deployment`.
- Reaffirmed NASA/JPL Power of 10 as always-on for core logic.

### Gaps Pending

- Future modules still require domain-specific implementation and evidence; this checkpoint only adds guidance and reusable skill surfaces.
- Live provider/cluster proof and final multi-GPU hardware evidence remain separate future gates.

### Next Items To Implement

- Invoke the relevant repo-local skill before future module work.
- Keep docs, contracts, code, tests, tracker, and checkpoint synchronized for each future slice.
- Continue with provider-specific deployment proof, frontend expansion, or final hardware-gated GPU work when prerequisites exist.
---

## Checkpoint: Current Phase Plan Sync — 2026-05-14

### Work Done Till Date

- Created `Plan.md` for the current Provider-Specific GA Proof / Module Expansion phase.
- Synced `docs/TODO.md` with open current-phase items after P0/P1/P2 local-platform closure.
- Updated `docs/risk-register.md` to reflect provider deployment proof, frontend-scale risk, Julia-runtime-depth risk, and final GPU hardware gating.

### Gaps Pending

- Provider-specific overlays, secret delivery integration, server-side dry-run, and live smokes remain pending.
- Frontend module expansion and Julia runtime module expansion are open future lanes.
- Final GPU production hardening still requires >=2 visible CUDA devices.

### Next Items To Implement

- Use `Plan.md` as the current plan source before the next implementation slice.
- Continue provider-specific GA proof first when external target access exists; otherwise proceed with frontend or Julia module expansion.
- Update TODO, risks, tracker, checkpoint, and traceability together after the next meaningful phase change.
---

## Checkpoint: Control-Doc Sync Guard — 2026-05-14

### Work Done Till Date

- Added a control-doc sync validator and package script: `npm run validate:control-doc-sync`.
- Updated `AGENTS.md` and the control-loop skill so every completed slice, phase, or review requires Plan/TODO/risk/tracker/checkpoint updates.
- Updated Plan, TODO, risk register, tracker, and checkpoint to record the guard itself.
- Verified the guard with `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, `node --test tests/contracts/brd-traceability.test.mjs`, `npm run test`, `npm run build`, and `git diff --check`.

### Gaps Pending

- The validator proves required control docs were touched, not that their wording is semantically perfect.
- Future CI/release gates should include the validator.

### Next Items To Implement

- Run `npm run validate:control-doc-sync` on every future slice, phase, review, and before commits with non-control changes.
- Continue pairing control-doc sync with traceability validation for milestone/TODO changes.

---

## Checkpoint: Frontend Module Expansion / BI Viewer Row-Search Slice — 2026-05-15

### Work Done Till Date

- Implemented the first current-phase frontend module expansion slice in the BI published dashboard viewer.
- Published viewers now have a row-search control that filters visible chart rows after chart cross-filter selection.
- Filtered CSV export now uses the same effective viewer row set: chart filter plus row search.
- Regression coverage now exercises share-token viewer row search, clear row search, and search-aware CSV export.

### Gaps Pending

- Provider-specific deployment/object-store proof still lacks live provider, cluster, and credential context.
- Julia runtime module expansion remains pending for loop/try-catch/control-flow execution semantics.
- Governed Hub production depth remains pending for bounded sandbox execution and artifact hash verification.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Complete full verification: `npm run test`, `npm run build`, `npm run validate:control-doc-sync`, and `npm run validate:brd-traceability`.
- If full gates pass, move to Julia runtime module expansion as the next repo-local lane unless provider access appears.
- Keep frontend route shell, demo fallback, runtime `juliaflow-config.js`, and accessible selectors intact in future frontend slices.

---

## Checkpoint: Julia Runtime Module Expansion / Loop Runtime-Plan Slice — 2026-05-15

### Work Done Till Date

- Added bounded loop runtime-plan semantics without changing node compute execution.
- Valid loops now derive ordered body node IDs from the DAG and include `controlFlowPlan` evidence on execution records.
- Invalid loops whose end node is unreachable from the start node now fail validation.
- Contracts, gateway payload mapping, Monitor UI, fixtures, and tests were updated for the additive execution evidence.

### Gaps Pending

- Try/catch runtime execution semantics remain pending.
- Provider-specific deployment/object-store proof still requires external provider and cluster context.
- Governed Hub sandbox/hash verification remains pending.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Complete full verification for this runtime slice.
- Continue with try/catch runtime semantics next unless provider/cluster access is supplied.
- Keep control-flow runtime additions additive and evidence-backed across Julia, contracts, gateway, frontend, and tests.

---

## Checkpoint: Julia Runtime Module Expansion / Try-Catch Runtime-Plan Slice — 2026-05-16

### Work Done Till Date

- Added additive try/catch runtime-plan evidence without changing node compute execution.
- Execution records now include try/catch `controlFlowPlan` entries with try and catch node IDs.
- Contracts, gateway payload mapping, Monitor UI, fixtures, and tests were updated for the try/catch evidence shape.

### Gaps Pending

- Failure-driven executor semantics and worker-runtime behavior remain pending.
- Provider-specific deployment/object-store proof still requires external provider and cluster context.
- Governed Hub sandbox/hash verification remains pending.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Complete full verification and code review for this runtime slice.
- Continue with deeper runtime execution semantics or Hub production depth unless provider/cluster access is supplied.
- Keep loop/try-catch runtime additions additive until failure-driven node execution is deliberately expanded.


---

## Checkpoint: Governed Hub Production Depth / Deterministic Sandbox-Hash-Mirror Proof Slice — 2026-05-16

### Work Done Till Date

- Added Hub `verification` evidence across TS contracts, OpenAPI, Julia repository payloads, gateway install responses, and frontend Hub cards.
- Added deterministic install-time checks for bounded sandbox command shape, artifact hash match/mismatch, and supported `mirror://` / `private://` references.
- Preserved safe remediation: disable remains available even when compatibility, trust, or verification blockers exist.
- Added Julia, frontend, and contract regression coverage for passed verification, hash mismatch blocking, unsafe sandbox blocking, mirror status, and UI blocker rendering.

### Gaps Pending

- Real isolated sandbox execution is still pending; manifest commands are not executed directly on the request path.
- Downloaded artifact hash verification and real private/offline registry mirror proof remain future Hub production-depth follow-ups.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Complete full gate execution and review for this slice before commit/push.
- Add isolated sandbox runner plus downloaded-artifact verification when registry/mirror fixtures are ready.
- Continue deeper runtime execution semantics or provider proof when prerequisites are available.


---

## Checkpoint: Julia Runtime Module Expansion / Try-Catch Failure-Recovery Route Slice — 2026-05-16

### Work Done Till Date

- Added try/catch failure-recovery routing on top of existing try/catch metadata.
- Status updates reporting `failedNodeId` for a covered try node now append recovery evidence and keep the execution non-terminal.
- Uncaught failed-node telemetry still transitions to failed normally.
- Updated contracts, OpenAPI, gateway mapping, frontend Monitor UI, Julia tests, frontend tests, contract tests, tracker, TODO, risk register, and traceability docs.

### Gaps Pending

- Real catch-node compute execution is not implemented in this slice.
- Worker-runtime branch state and catch-node scheduling remain future runtime work.
- Provider-specific deployment/object-store proof and real Hub sandbox/download/mirror proof remain gated on external context/fixtures.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Complete full verification and code review for this slice.
- Add real catch-node compute and worker branch-state execution in a future runtime slice.
- Continue provider proof only when cluster/provider/credential prerequisites exist.


---

## Checkpoint: Julia Runtime Module Expansion / Catch-Node Branch-State Slice — 2026-05-17

### Work Done Till Date

- Added worker-service catch-branch execution after try/catch recovery.
- Recovered executions now queue branch work, execute bounded catch nodes, record `controlFlowBranchState`, and complete once the catch branch finishes.
- Branch evidence includes worker id, failed node id, catch/completed node IDs, deterministic BI outlet row-count node results, gateway payload mapping, contracts/OpenAPI, and Monitor UI rendering.
- Added Julia, frontend, and contract regression coverage plus Autopilot PRD/test-spec artifacts.

### Gaps Pending

- General DAG branch rescheduling and broader executor scheduling remain future runtime work.
- Provider-specific deployment/object-store proof still requires provider, cluster, and credential context.
- Real Hub sandbox/download/private-mirror proof still requires isolated runner and registry fixtures.
- Final GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Complete full verification and code review for this slice.
- Continue with general DAG branch rescheduling or Hub isolated sandbox proof if provider context remains unavailable.
- Keep all future slice claims tied to traceability and control-doc sync gates.

---

## Checkpoint: Governed Hub Production Depth / Isolated Sandbox-Artifact-Mirror Proof Slice — 2026-05-17

### Work Done Till Date

- Prioritized unblocked `R-HUB-001` after provider deployment/object-store risks remained gated on external provider, cluster, and credentials.
- Added env-gated allowlisted sandbox fixture execution for Hub installs, local artifact-store hash verification, and private/offline mirror-registry resolution.
- Missing artifact-store entries and missing mirror-registry refs now block install/enable/upgrade with verification evidence, while unsafe sandbox/file-mirror behavior remains blocked.
- Hub UI now surfaces verification details; Julia/frontend regression coverage and the labs sandbox fixture were added.

### Gaps Pending

- External Hub registry/provider mirror proof remains pending until provider or registry context exists.
- Provider-specific deployment/object-store proof still requires live target context and credentials.
- General DAG branch rescheduling remains future runtime work.
- Final GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Complete security/code review, commit, push, and verify remote publication for this slice.
- If external provider context appears, proceed to `R-DEP-001` and `R-OBJ-001`; otherwise continue general DAG branch rescheduling or frontend/Hub polish.
- Keep sandbox execution env-gated and allowlisted in future Hub work.

---

## Checkpoint: Julia Runtime Module Expansion / DAG Branch Rescheduling Slice — 2026-05-17

### Work Done Till Date

- Implemented bounded DAG branch rescheduling for recovered try/catch catch branches.
- Worker-service now groups catch nodes into deterministic dependency stages from workflow connections and records stage-level branch metadata.
- Gateway repository mapping, TS/OpenAPI contracts, Monitor UI, Julia tests, frontend tests, TODO, risk register, traceability, plan, and tracker were updated together.

### Gaps Pending

- General executor scheduling across non-catch runtime paths remains open.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Complete full verification and clean code review for this slice.
- Commit and push after gates pass.
- Continue broader multi-node executor scheduling unless provider context becomes available first.

---

## Checkpoint: Julia Runtime Module Expansion / Executor Stage-Schedule Slice — 2026-05-17

### Work Done Till Date

- Added additive general workflow executor scheduling evidence beyond catch-branch DAG rescheduling.
- Execution service now builds bounded topological `executorSchedule` entries from workflow stages with lane, worker-pool, readiness, max-concurrency, and scheduler-policy data.
- Gateway payload mapping, TS/OpenAPI contracts, Monitor UI, Julia regression tests, frontend tests, and control docs were synchronized.

### Gaps Pending

- Real asynchronous multi-tick executor scheduling remains open.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Run full verification and code review for this slice.
- Commit and push after gates pass.
- Continue true multi-tick executor scheduling unless provider context becomes available first.

---

## Checkpoint: Julia Runtime Module Expansion / Multi-Tick Executor Slice — 2026-05-17

### Work Done Till Date

- Added metadata-only multi-tick executor scheduling over existing `executorSchedule` evidence.
- Worker-service now progresses CPU batch executions through accepted -> queued -> running stage progress -> completed with one bounded stage action per tick.
- Gateway payload mapping, TS/OpenAPI contracts, Monitor UI, Julia regression tests, frontend tests, and control docs were synchronized.

### Gaps Pending

- Real node execution, output materialization, and per-node error propagation remain open for future staged executor work.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Run full verification and code review for this slice.
- Commit and push after gates pass.
- Continue real node execution/output/error handling inside staged executor ticks unless provider context becomes available first.

---

## Checkpoint: Julia Runtime Module Expansion / Executor Node Result-Error Binding Slice — 2026-05-17

### Work Done Till Date

- Added callback-bound node output/error telemetry to staged executor ticks.
- Worker-service now records per-stage node results, flattened executor node results, output refs/row counts, and failed-node/error metadata.
- Gateway payload mapping, TS/OpenAPI contracts, Monitor UI, Julia regression tests, frontend tests, and control docs were synchronized.

### Gaps Pending

- Full base-extension dataflow execution and payload propagation through the callback seam remain open.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Run full verification and code review for this slice.
- Commit and push after gates pass.
- Continue full dataflow/payload execution binding unless provider context becomes available first.

---

## Checkpoint: Julia Runtime Module Expansion / Base-Extension Dataflow Binding Slice — 2026-05-18

### Work Done Till Date

- Added a focused base-extension executor dataflow helper for staged executor callbacks.
- Executor callbacks can now execute registered base source/transform/sink nodes, propagate Arrow IPC payloads through stored stage outputs, and return row/output/persisted-ref telemetry.
- Julia regression tests, extension tests, and control docs were synchronized.

### Gaps Pending

- Broader callback-bound dataflow coverage across all base nodes and production scheduling policies remains open.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Run full verification and code review for this slice.
- Commit and push after gates pass.
- Continue broader executor dataflow coverage unless provider context becomes available first.

---

## Checkpoint: Julia Runtime Module Expansion / Executor Dataflow Authored-Alias Coverage Slice — 2026-05-18

### Work Done Till Date

- Added authored-node alias coverage to the base-extension executor dataflow helper.
- UI/contract-style base node types now resolve into canonical base node keys for staged executor callbacks.
- Authored workflow ports now supply default input/output port IDs for source, transform, aggregate, and sink nodes.
- Julia runtime and extension regressions cover alias-authored Arrow IPC dataflow through staged executor ticks.

### Gaps Pending

- Production scheduling policy evidence for callback-bound executor dataflow remains open.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Run full verification and code review for this slice.
- Commit and push after gates pass.
- Continue production scheduling policy evidence unless provider context becomes available first.

---

## Checkpoint: Julia Runtime Module Expansion / Executor Dataflow Scheduling-Policy Evidence Slice — 2026-05-19

### Work Done Till Date

- Added production-oriented scheduling-policy evidence for callback-bound executor dataflow.
- Schedule-stage and executor-state payloads now expose `dataflowPolicy` / `dataflow_policy` details across Julia, gateway, contracts, OpenAPI, and Monitor UI.
- Regression tests cover policy evidence on normal scheduler payloads and alias-authored source -> select -> aggregate -> sink dataflow execution.

### Gaps Pending

- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.
- Frontend module depth remains the next unblocked local lane if provider context is still unavailable.

### Next Items To Implement

- Run full verification and code review for this slice.
- Commit and push after gates pass.
- Continue frontend module expansion unless provider context becomes available first.

---

## Checkpoint: Frontend Module Expansion / Monitor Executor Detail Slice — 2026-05-28

### Work Done Till Date

- Pulled `Gravelaw/LowcodeMLtoolkit.jl` into the local Git workspace on `main`.
- Reviewed BRD, plan, TODO, traceability, risk, tracker, and checkpoint state for the current Provider-Specific GA Proof / Module Expansion phase.
- Added Monitor execution-rail detail for executor dataflow stage policies and per-node executor/branch results.
- Removed tracked `.staging/` skill residue and ignored future `.staging/` folders.
- Resolved the moderate `ws` audit advisory with `npm audit fix`.

### Gaps Pending

- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains gated on external registry/provider context.
- Final multi-GPU closure remains hardware-gated on `>=2` visible CUDA devices.
- Further BI/Hub/settings polish remains available as local frontend module depth.

### Next Items To Implement

- Run focused frontend and control-doc verification for this slice.
- Continue provider-specific GA proof when provider context exists; otherwise continue local frontend/Hub polish slices.

---

## Checkpoint: BRD Local-First Strategy Refresh — 2026-05-28

### Work Done Till Date

- Promoted `business-requirements-v0.3.0.md` to the v0.4.0 local-first BRD baseline.
- Reframed JuliaFlow as a self-contained local appliance for academia, labs, students, researchers, small teams, and low-resource users.
- Added core requirements for local appliance bootstrap, local data estate, DuckDB analytics, PostgreSQL lab/team metadata mode, optional MinIO local S3 profile, local CPU/GPU hardware validation, AI explainability/model transparency, offline Hub, academic reproducibility bundles, and backup/restore.
- Downgraded provider-specific deployment, cloud object stores, external Hub registries, enterprise identity, Kubernetes/ArgoCD production overlays, and cloud multi-GPU closure to optional compatibility paths.
- Updated Plan, TODO, risk register, tracker, checkpoint, and BRD traceability docs to point future implementation at local-first GA proof.

### Gaps Pending

- Local appliance bootstrap proof remains open.
- Local data estate and DuckDB query path proof remain open.
- Local PostgreSQL lab/team metadata mode proof remains open.
- Local hardware profiler, GPU smoke, and CPU fallback proof remain open.
- Explainability/model evidence and academic reproducibility bundle proof remain open.
- Offline Hub proof and backup/restore proof remain open.

### Next Items To Implement

- Build the local appliance bootstrap proof first.
- Then implement local data estate and metadata/database proof before deeper explainability and offline Hub work.

---

## Checkpoint: Documentation Cleanup — 2026-05-28

### Work Done Till Date

- Removed only the user-approved obsolete documentation artifacts: one superseded BRD draft, the old persona archive, legacy handoff/parallel-lane planning files, one old OIDC/RBAC planning file, and two empty release-note stubs.
- Repointed active README/TODO/tracker/checkpoint references away from removed files and into the active control-doc set.
- Recorded documentation-sprawl risk mitigation while keeping the active local-first BRD baseline intact.

### Gaps Pending

- Historical tracker/checkpoint narratives still preserve prior work context by design.
- Active implementation remains local appliance bootstrap, local data estate, local metadata/database, local hardware runtime, explainability/model evidence, offline Hub, reproducibility, and backup/restore.

### Next Items To Implement

- Start the local appliance bootstrap proof.

---

## Checkpoint: Agent Prompt Hygiene And Skill Routing Cleanup — 2026-05-28

### Work Done Till Date

- Compared `AGENTS.md` with repo-local skills and installed plugin skill names.
- Added `juliaflow-local-first-appliance` for one-command local bootstrap, local data estate, DuckDB/PostgreSQL modes, hardware proof, explainability, offline Hub, reproducibility, and backup/restore work.
- Updated repo-local skills to use installed `analysis-engineering-workflow`, `julia-engineering-toolkit`, `frontend-design-workflow`, `lowcode-ml-ui-patterns`, and `codex-security` skill names.
- Reworked `AGENTS.md` to remove unavailable skill names, hard-coded model guidance, and stale provider-first routing.

### Gaps Pending

- Product implementation still needs local appliance bootstrap, data estate, metadata/database, hardware, explainability, offline Hub, reproducibility, and backup/restore proofs.
- Prompt routing should be checked again when installed plugin inventory changes.

### Next Items To Implement

- Use the new local-first appliance skill for the next local bootstrap implementation slice.

---

## Checkpoint: Agent Prompt Hygiene Skill Frontmatter Repair — 2026-06-16

### Work Done Till Date

- Repaired `.codex/skills/juliaflow-local-first-appliance/SKILL.md` by quoting its description frontmatter value, preserving the existing trigger wording while making the colon-bearing YAML scalar valid.
- Hardened `scripts/validate-control-doc-sync.mjs` to avoid failing when child-process git output is returned with status `0` in the current environment.
- Ran a local frontmatter check across all repo-local `SKILL.md` files for required `name` and `description` keys.

### Gaps Pending

- The official `skill-creator` validator could not run because `PyYAML` is not installed in the current Python environment.

### Next Items To Implement

- Install or restore project validation dependencies before running the official skill validator.

---

## Checkpoint: Offline Hub Proof Implementation Staged — 2026-06-16

### Work Done Till Date

- Added local Hub cache readiness evidence to gateway `/health`, including artifact-store and mirror-registry paths plus local install counts.
- Updated local bootstrap setup so the Hub cache contains offline artifact and mirror registry files by default.
- Added `scripts/smoke-local-offline-hub.mjs`, `scripts/smoke-local-offline-hub.jl`, and the `npm run smoke:local-offline-hub` command to prove local extension install without an external registry and to keep unsafe sandbox commands blocked.
- Updated contracts, OpenAPI, frontend Monitor rendering, frontend fixtures, contract tests, and Julia health assertions for the new evidence surface.
- Rectified the active development shell for Debian with `npm run doctor:debian`, repo-local Juliaup LTS, workspace-local Julia depots, and Julia sandbox execution through the active Julia command instead of a PATH-dependent `julia` shim.
- Verified with `npm run doctor:debian`, `npm run smoke:local-offline-hub`, Debian-local `julia --project=. tests/julia/runtests.jl`, `npm run validate:contracts`, `npm run test`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

### Gaps Pending

- Offline Hub proof is closed for the current local-first slice.
- Socket-bound gateway smoke remains unavailable in the current sandbox because TCP bind fails with `EPERM`; the offline Hub smoke uses the in-process gateway router to verify the same install path without network binding.
- The Babel/esbuild/Vite dependency advisories are resolved in this PR branch; `npm audit --audit-level=moderate` now reports zero vulnerabilities after the Vite 8 lockfile upgrade.

### Next Items To Implement

- Start academic reproducibility workflow: offline EDA -> model -> explain -> dashboard -> checkpoint -> export/reimport with package, seed, checksum, metric, model, explanation, dashboard, and notes evidence.
---

## Checkpoint: Academic Reproducibility Workflow Proof — 2026-06-17

### Work Done Till Date

- Added local reproducibility bundle export/import routes to the gateway.
- Added contract/OpenAPI/client shapes for reproducibility bundle export and import.
- Bundles include workflow, checkpoint, dataset checksum/card, package/runtime metadata, seeds, model artifact evidence, metrics, explainability output, dashboard snapshot, notes, local-only flag, and deterministic checksum.
- Import validates the checksum, restores workflow/checkpoint/dashboard evidence into a fresh local repository, and rejects tampered bundles.
- Added `npm run smoke:local-reproducibility` to prove export/reimport through the in-process gateway router without network binding or cloud credentials.

### Gaps Pending

- Backup/restore and migration remain open for full local data estate and metadata portability.
- Mock-derived product modules remain requirements-only until implementation slices land.

### Next Items To Implement

- Start backup/restore and migration proof.
- Keep `npm run smoke:local-reproducibility` in the local-first verification gate set.

---

## Checkpoint: Backend-Backed Data And Transform Product Actions — 2026-06-17

### Work Done Till Date

- Closed PR #12 after GitHub `web` and `julia` checks passed, then started draft PR #13 for the next product-depth branch.
- Added local data import/profile gateway support with data-estate zone validation, checksum/profile evidence, manifest/DuckDB status, and deterministic local artifact references.
- Added transform run/history gateway support that wraps workflow execution state and returns workflow-node, checkpoint, status, and artifact evidence.
- Extended `packages/contracts` TypeScript client types and OpenAPI paths/schemas for the new Data and Transform endpoints.
- Wired Data and Transform product views to run the actions against the gateway when configured, with deterministic demo fallback and visible action feedback.
- Added route-level Julia tests, typed-client contract coverage, OpenAPI assertions, and frontend demo smoke coverage.

### Gaps Pending

- Full product readiness still needs ML Studio experiment tracking, Models registry mutation, Visualize checkpoint/export depth, and local Deploy packaging.
- Optional provider/cloud compatibility remains out of scope for this local-first slice.
- Hardware-backed CUDA/multi-GPU evidence remains environment-gated.

### Next Items To Implement

- Finish PR #13 verification/CI/review and merge once green.
- Continue product-depth implementation with ML Studio experiments or Models registry actions before packaging/deploy depth.

---

## Checkpoint: Mockup-Aligned Local UI And Browser Automation — 2026-06-17

### Work Done Till Date

- Replaced the dark glass frontend surface with the mockup-aligned JuliaFlow Local appliance shell, including left navigation, `100% Local` strip, compact white cards, purple actions, green local/privacy state, and consistent right-side detail panels.
- Split frontend implementation into `App.tsx`, shared `components/`, deterministic `fixtures/local-fixtures.ts`, and dedicated `views/` route components.
- Added deterministic local-only synthetic data for churn rows, data profiles, transform runs, ML experiments, model registry records, dashboard exports, deploy packages, local health, checkpoints, and generated Julia code snippets.
- Added Playwright browser tests that intercept gateway API calls and verify desktop plus mobile-width journeys across Explorer, Data, Transform, ML Studio, Models, Visualize, Deploy, and Settings.
- Preserved runtime gateway configuration and demo fallback behavior for offline UI operation.

### Gaps Pending

- Browser automation is fixture-backed by default; an optional live `dev:local` smoke path can be added later without becoming the default gate.
- Provider/cloud compatibility and multi-GPU evidence remain optional or hardware-gated and were not expanded by this UI slice.

### Next Items To Implement

- Keep Playwright browser automation in the release gate and expand it only around concrete local workflow regressions or accessibility findings.
- Complete full PR verification with contracts, Julia tests, frontend tests, build, control-doc sync, BRD traceability, and diff whitespace checks.

---

## Checkpoint: AKS-5 Stage 2 Release-Mode Boundary - 2026-06-18

### Work Done Till Date

- Added contract-first runtime mode support for `demo`, `development`, `release`, and `local-appliance`.
- Added fixture provenance, fixture-substitution policy, and unavailable-state evidence to TypeScript contracts, OpenAPI, gateway health, and frontend app state.
- Updated frontend runtime config so release/local-appliance mode reports missing gateway data, protected-gateway auth failures, and failed actions explicitly instead of using deterministic fixture substitutions.
- Wired gateway/OIDC bearer token, workspace id, and workspace role config through the normal frontend gateway client so workflows, execution actions, Hub/admin/auth APIs, dashboard publish/read, and existing share/workspace-token paths inherit one auth context.
- Added focused frontend, contract, and Julia assertions for the release-mode boundary.

### Gaps Pending

- Stage 3 must still make Canvas save/run/monitor a true backend lifecycle.
- Stage 5 must still add the fresh-checkout release verification script and live-backend Playwright smoke.
- PR #20 has merged; PR #21 is retargeted to `main`. The primary Documents checkout is restored as a readable Git checkout, but this Codex process still cannot write `.git` lock files because restored `.git` ACLs block metadata writes, so verification and branch updates use fresh temp clones.

### Next Items To Implement

- Keep PR #21 current on `main`, verify Stage 2 gates after each change, and mark it ready after final review.
- Continue with backend-backed Canvas lifecycle and artifact-backed dashboard/explainability behavior.

---

## Checkpoint: AKS-5 Stage 5 Release Verification Blocker Burn-Down - 2026-06-20

### Work Done Till Date

- Docker Desktop access from Codex is restored on the `desktop-linux` context; `docker info` and Compose work from `D:\Julia Project`.
- `smoke:local-metadata` now passes the Docker PostgreSQL lab-team path. The gateway repository imports `LibPQ` normally at module load instead of lazily importing it mid-call, which removes Julia 1.12 world-age failures in PostgreSQL gateway startup.
- `smoke-local-metadata.mjs`, `verify-release.mjs`, and npm-visible Julia scripts now use the repo-local Julia command/depot for standalone Julia subprocesses, avoiding blocked user-global compiled DLLs under `C:\Users\aksha\.julia\compiled`.
- No-skip `npm run verify:release` passed bootstrap, contracts, frontend, Julia tests, local smokes, and live-backend browser smoke before stopping at the expected control-doc sync gate for this code/doc slice.
- After control-doc synchronization, full no-skip `npm run verify:release` passed and wrote `artifacts/release-verification/latest/summary.json`.

### Gaps Pending

- No Docker/PostgreSQL blocker remains for the current release gate.
- PR/Linear evidence still needs to reference the passing summary and live browser artifacts.

### Next Items To Implement

- Use `artifacts/release-verification/latest/summary.json` plus live browser artifacts as final AKS-5/AKS-10 evidence in PR/Linear cleanup.

---

## Checkpoint: AKS-23 Project Creation And Shell Actions First Slice - 2026-06-20

### Work Done Till Date

- Added editable project name, description, and typed local folder path inputs to the `Create New Project` dialog.
- Added validation for short names, reserved filename characters, missing descriptions, non-local paths, parent traversal, and visible project-folder collisions.
- Updated the active workflow name/id and Explorer project artifact state when a local scaffold is created.
- Added browser-granted target-folder selection and scaffold file writes for `Project.toml`, `README.md`, workflow TOML, and `data/raw/.gitkeep`.
- Wired Grid, Share, Help, and avatar controls to local-first dialogs instead of inert buttons.
- Hardened ML Studio against incomplete metric payloads found during browser sanity.

### Gaps Pending

- Project creation writes files through browser-granted folder handles; service-owned gateway scaffold creation from typed paths remains optional future work.
- Route-level error boundaries remain open under AKS-27.

### Next Items To Implement

- Use PR #28 to review the AKS-23 first slice.
- Decide whether browser-granted local scaffold writes satisfy AKS-23 or whether a gateway scaffold endpoint is required before closure.

---

## Checkpoint: AKS-27 Route Resilience First Slice - 2026-06-20

### Work Done Till Date

- Added route-level crash containment for module views so a failed route renders an unavailable state instead of blanking the full app shell.
- Made shared table rendering tolerant of missing row arrays.
- Added explicit empty states for Models and Deploy when live backend lists are empty.
- Guarded Settings backup checkpoint rendering.
- Extended local-appliance frontend coverage across empty Transform, Monitor, ML Studio, Visualize, Models, Deploy, and Settings routes.
- Captured local Playwright/Edge browser sanity for Explorer, ML Studio, Models, Deploy, and Visualize routes.

### Gaps Pending

- A future per-card boundary can be added if product review wants individual cards to isolate failures inside a route.

### Next Items To Implement

- Update PR #29/Linear with final AKS-27 evidence.

---

## Checkpoint: AKS-24 Explorer System Health And Artifacts First Slice - 2026-06-20

### Work Done Till Date

- Closed stale PR #19 and started AKS-24 from current `main` on `codex/aks-24-explorer-system-health-artifacts`.
- Added gateway health polling through existing `/health` data at a 5-second cadence for gateway-backed modes.
- Added health freshness/stale state so failed refreshes keep the last known hardware values visible.
- Consolidated Explorer hardware metrics into one System Health surface backed by runtime health instead of static CPU/RAM/Disk placeholders.
- Added project-specific trust boundary evidence and replaced the generic local-first privacy card.
- Replaced flat project artifact rows with grouped hierarchy rows and explicit path-copy actions.
- Kept compute controls read-only for this first slice while making their runtime-health source and Settings handoff clear.
- Verification passed with focused frontend tests, production build, browser sanity on `/`, `/settings`, and `/data`, control-doc sync, BRD traceability, and diff checks.

### Gaps Pending

- Functional compute settings remain the second AKS-24 slice: contract/gateway persistence, runtime scheduling propagation, and execution evidence are still needed.
- Artifact open-folder behavior remains copy-path only until a real local folder reveal bridge exists.

### Next Items To Implement

- Publish the draft AKS-24 PR.
- Start AKS-24 compute settings after the Explorer UX PR is reviewed.

---

## Checkpoint: AKS-24 Compute Settings Runtime Slice - 2026-06-20

### Work Done Till Date

- Added contract/client support for `GatewayComputeSettings`.
- Added gateway `GET/PUT /api/v1/settings/compute` routes with local metadata file persistence.
- Reflected compute settings into health and workflow execution metadata.
- Added editable Settings controls for backend, CPU worker concurrency, memory limit, GPU preference, and BLAS thread count.
- Preserved existing GPU/stream dispatch metadata while attaching compute settings evidence to executions.
- Verified with focused frontend tests, contract validation, repo-local Julia tests, and production build.

### Gaps Pending

- PR #32 replaced closed stacked PR #31 and merged after PR #30.
- External worker hot-reload remains future runtime depth if product review requires live process reconfiguration beyond gateway-dispatched evidence.

### Next Items To Implement

- Continue with AKS-25 Data estate workflow.

---

## Checkpoint: AKS-25 Data Estate Workflow Slice - 2026-06-20

### Work Done Till Date

- Started `codex/aks-25-data-estate-workflow` after AKS-24 merged to `main`.
- Added contract/OpenAPI fields for active read mode, source options, artifact lineage, quality checks, field roles, workflow readiness, quick EDA plots, and preview rows.
- Extended gateway local-data import/profile evidence for telecom churn and Global Superstore local fixture profiles with CSV, Arrow IPC, Parquet, and DuckDB semantics.
- Reworked Data into a workflow surface for dataset switching, read-mode switching, preview/profile evidence, lineage, quality checks, ML readiness, and quick EDA checks.
- Verified with focused frontend tests, contract validation, production build, and repo-local Julia gateway tests.

### Gaps Pending

- Full external Kaggle download/import UX remains future depth; this slice uses committed deterministic fixture metadata.

### Next Items To Implement

- AKS-26 EDA and ML diagnostic visualization is the follow-on closure slice.

---

## Checkpoint: AKS-26 EDA And ML Diagnostics Slice - 2026-06-20

### Work Done Till Date

- Started `codex/aks-26-eda-ml-diagnostics` after AKS-25 merged to `main`.
- Reworked Visualize into EDA, Dashboard, Model Diagnostics, and Experiment Compare modes.
- Fed EDA from AKS-25 profile fields, quick plots, quality checks, target/readiness, missingness, outliers, and role metadata.
- Preserved local dashboard checkpoint/export and artifact-backed dashboard row behavior.
- Added ML diagnostic and experiment comparison views from existing ML experiment/model evidence.
- Added EDA correlation, outlier, and segment-slice review surfaces.
- Merged PR #34 as `2827ff0` after green `web` and `julia` CI.
- Verified with focused frontend tests, production build, control-doc sync, BRD traceability, and diff check.

### Gaps Pending

- Linear AKS-26 closure remains pending until this final control-doc closure update lands.
- Persisted diagnostic artifact API can be added later only if backend-owned diagnostic storage becomes required.

### Next Items To Implement

- Merge this closure-doc update.
- Confirm Linear has no open LowCodeML backlog issues.

---

## Checkpoint: Codex Review Required Fixes - 2026-06-20

### Work Done Till Date

- Implemented required Codex review fixes for chart readiness, Transform workflow resync, palette-node metadata, workspace summary disk/artifact evidence, DuckDB root-bound SQL, Postgres metadata readiness, and lab-team Postgres startup readiness.
- Added focused frontend assertions and Julia healthcheck assertions for the changed behavior.
- Verification already passed for focused frontend tests, Julia gateway/runtime tests, contract validation, production build, browser local UI checks, and BRD traceability before the final control-doc rerun.

### Gaps Pending

- Final `npm run validate:control-doc-sync`, `git diff --check`, and optional PR/CI evidence remain before closure.

### Next Items To Implement

- Rerun the final gates, then publish the review-fix branch for review.
