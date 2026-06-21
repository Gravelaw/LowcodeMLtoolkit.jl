# Project Tracker

## Purpose

This tracker is source of truth for active delivery state.
Agent must read this file before starting material work.
Agent must update this file after each meaningful milestone or direction change.

Tracker always records 3 things:

1. Work done till date
2. Gaps pending
3. Next items to implement

## Project

- Name: `JuliaFlow`
- BRD: `business-requirements-v0.3.0.md` v0.4.1 local product-surface refresh
- Current target phase: `Local-First GA Proof / Explainable Local Appliance`
- Current checkpoint path: `cp/00-foundation -> cp/01-contracts-frozen -> cp/02-alpha-core`
- Last updated: `2026-06-21`

## Work Done Till Date
### AKS-36 Model Lifecycle Records Slice (2026-06-21)

- Added project-backed model lifecycle upsert behavior for validated model registration and local deploy packaging.
- `POST /api/v1/workflows/{workflowId}/models/register` now records the linked `DataScienceProject.modelLifecycleRecords` entry as `validated` when model validation evidence includes a project id.
- `POST /api/v1/workflows/{workflowId}/deploy/package` now advances the same project model lifecycle entry to `deployed` and records the local deploy package id as deployed endpoint evidence.
- Fixed API Gateway test setup drift by resetting `JULIAFLOW_DATA_ESTATE_ROOT` before the foundation data science project flow so managed CSV statistical analysis resolves the intended local fixture.
- Added full Julia API Gateway regression coverage proving lifecycle state moves from `validated` to `deployed` without duplicating the model lifecycle record.
- Verification passed: `node scripts/run-julia.mjs --compiled-modules=no --project=. tests/julia/runtests.jl`; `npm run validate:contracts`; `npm run build`.

### Gaps Pending

- AKS-36 parent is still open. Project-backed model lifecycle records now exist for validated registration and local deploy package evidence, but registry state still lives on execution metadata.
- Gateway module split, execution-backed jobs, worker-backed statistical jobs, real tuning/evaluation/scoring/drift execution, registry repository extraction, rollback/retraining workflow depth, and project-backed frontend migration remain open.

### Next Items To Implement

- Extract model registry state from execution metadata into a first-class project/model repository path.
- Add rollback/retraining lifecycle transitions and scoring artifacts tied to evaluation/export evidence.
- Move deterministic project-scoped routes behind execution-backed worker jobs where appropriate.

### AKS-36 Statistical Artifact Persistence Slice (2026-06-21)

- Persisted project-scoped statistical EDA artifacts for `POST /api/v1/data-science-projects/{projectId}/statistical-analysis/run`.
- Statistical runs now write a local `analysis.jl` code artifact and `results.json` result artifact under the configured local data-estate root from the existing `local://analysis/...` refs.
- `StatisticalAnalysisRun.artifactRefs` and project job `outputRefs` now include local-only code/results refs with SHA-256 checksums, byte sizes, and generated timestamps.
- Extended shared `DataScienceProjectEvidenceRef` contracts/OpenAPI with `sizeBytes`, and `StatisticalAnalysisRun` with `artifactRefs`.
- Added focused Julia route coverage proving code/results files are written and returned refs include checksums/sizes.
- Verification passed: focused Julia statistical artifact persistence smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. Statistical EDA now persists local result/code artifacts, but worker-backed statistical jobs remain open.
- Gateway module split, execution-backed jobs, deeper tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Move statistical execution behind a worker-backed project job path.
- Start gateway internal module extraction for project/data source/statistical analysis handling.
- Replace remaining deterministic tuning/evaluation/scoring/drift route evidence with real execution-backed artifacts.

### AKS-36 Local CSV Remaining Statistical Methods Slice (2026-06-21)

- Extended the local CSV statistical EDA path with Spearman rank correlation, two-sample Welch-style t-test evidence, and chi-square independence evidence.
- Managed local CSV runs now return `spearmanCorrelationMatrix` and `inferentialTests.spearmanCorrelation` when `spearman_correlation` is requested.
- Managed local CSV runs now return `inferentialTests.tTest` for a numeric target grouped by the first requested categorical feature when `t_test` is requested.
- Managed local CSV runs now return `inferentialTests.chiSquare` for the first two requested categorical features when `chi_square` is requested.
- Added focused Julia route coverage proving Spearman, t-test, and chi-square evidence is produced from actual managed CSV values.
- Verification passed: focused Julia local CSV remaining-statistical-methods route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. Local CSV statistical evidence now covers summary, Pearson, Spearman, OLS, one-way ANOVA, t-test, and chi-square, but persisted result artifacts and worker-backed statistical jobs remain open.
- Gateway module split, execution-backed jobs, deeper tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Persist statistical result artifacts instead of only returning record payload evidence.
- Move statistical execution behind a worker-backed project job path.
- Start gateway internal module extraction for project/data source/statistical analysis handling.

### AKS-36 Local CSV Inferential Statistics Slice (2026-06-21)

- Extended the project-scoped statistical EDA route with first local CSV-backed inferential evidence.
- `StatisticalAnalysisRun` contracts/OpenAPI now expose `resultSummary` explicitly for local statistical outputs.
- Managed local CSV runs now compute simple linear OLS evidence for the requested numeric feature/target pair, including intercept, slope, R-squared, SSE, and sample size.
- Managed local CSV runs now compute one-way ANOVA evidence for the requested categorical feature and numeric target, including groups, degrees of freedom, F statistic, and sums of squares.
- Added focused OpenAPI contract coverage for `resultSummary` and Julia route coverage proving OLS/ANOVA evidence is produced from actual managed CSV values.
- Verification passed: focused Julia local CSV inferential-statistics route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`; `npm run validate:contracts`.

### Gaps Pending

- AKS-36 parent is still open. This slice adds first local CSV-backed OLS/ANOVA evidence, but t-test, chi-square, Spearman rank correlation, persisted result artifacts, and worker-backed statistical jobs remain open.
- Gateway module split, execution-backed jobs, deeper tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Add t-test, chi-square, and Spearman evidence or move statistical execution behind a worker-backed job path.
- Persist statistical result artifacts instead of only returning record payload evidence.
- Start gateway internal module extraction for project/data source/statistical analysis handling.

### AKS-36 Local CSV Statistical EDA Slice (2026-06-21)

- Added a data-derived statistical EDA path for `POST /api/v1/data-science-projects/{projectId}/statistical-analysis/run`.
- Project datasets with managed `local://data/...` CSV refs now resolve only inside the configured local data-estate root.
- When the managed CSV exists, the route computes bounded local numeric summaries and a Pearson correlation matrix from the actual file instead of only returning deterministic fixture evidence.
- Statistical analysis run records now include `resultSummary.executionMode = local_csv`, row count, numeric columns, summaries, and correlation matrix while preserving the fixture fallback for unavailable managed CSV sources.
- Added focused Julia route coverage proving the real CSV path returns data-derived summary evidence.
- Verification passed: focused Julia local CSV statistical-analysis route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice adds first real local CSV-backed summary/correlation evidence, but OLS, t-test, chi-square, ANOVA, richer Spearman handling, persisted result artifacts, and worker-backed statistical jobs remain open.
- Gateway module split, execution-backed jobs, deeper tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Extend statistical execution beyond summary/Pearson evidence into OLS and inferential tests.
- Replace remaining deterministic project route evidence with real Julia execution jobs and concrete local artifacts.
- Start gateway internal module extraction for project/data source/statistical analysis handling.

### AKS-36 Local Import Audit Evidence Slice (2026-06-21)

- Added redaction-safe audit evidence for `/api/v1/local-data/import`.
- Successful imports now record `local.data.import` with dataset id, format, target zone, source kind, basename, extension, size, and accepted outcome without storing full local file paths.
- Rejected imports now record `local.data.import.rejected` with sanitized source metadata, rejected outcome, and validation reason for path, size, format, credential, and PII marker failures.
- Added focused Julia route coverage proving accepted and rejected audit events are persisted and do not include full import-root paths or sampled sensitive values.
- Verification passed: focused Julia local-import audit route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice adds import audit decisions, but redaction previews, connector-specific policies, and a fuller local-source threat model remain open.
- Gateway module split, execution-backed jobs, deeper statistical/tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Add connector-specific import policies and redaction-safe source diagnostics.
- Replace deterministic project route evidence with real Julia execution jobs and concrete local artifacts.
- Start gateway internal module extraction for project/data source handling.

### AKS-36 Local Import Content Sniffing Slice (2026-06-21)

- Added first-pass content sniffing for text-like `/api/v1/local-data/import` filesystem sources.
- CSV/JSON/JSONL imports now sample the first 16 KiB and reject obvious credential markers such as API keys, access tokens, bearer authorization, private keys, client secrets, and passwords.
- The same sample pass rejects obvious sensitive PII column markers such as SSN, passport, driver license, credit card, card number, date of birth, and DOB.
- Invalid UTF-8 samples in text-like imports now fail as controlled local data import validation errors instead of falling through as unexpected route failures.
- Added focused Julia route coverage for valid import, credential-content rejection, and PII-content rejection.
- Verification passed: focused Julia content-sniffing route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice adds marker-based content sniffing, but richer audit evidence, redaction previews, connector-specific policies, and a fuller local-source threat model remain open.
- Gateway module split, execution-backed jobs, deeper statistical/tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Add richer audit evidence and redaction-safe import diagnostics.
- Replace deterministic project route evidence with real Julia execution jobs and concrete local artifacts.
- Start gateway internal module extraction for project/data source handling.

### AKS-36 Local Import File Check Slice (2026-06-21)

- Added bounded filesystem import checks for `/api/v1/local-data/import`.
- Raw local file imports now reject empty files, files larger than `JULIAFLOW_IMPORT_MAX_BYTES` (default 512 MiB), unsupported file extensions/formats, and credential/secret-looking filenames.
- Preserved managed `local://` import refs while applying file checks to real filesystem imports.
- Added focused Julia route coverage for valid import, secret-looking filename rejection, oversized file rejection, unsupported extension rejection, and unsupported format rejection.
- Verification passed: focused Julia file-check route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice adds coarse file safety checks, but content sniffing, PII detection, credential scanning inside file contents, richer audit evidence, and connector-specific import policies remain open.
- Gateway module split, execution-backed jobs, deeper statistical/tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Add content sniffing and richer audit evidence for local imports.
- Replace deterministic project route evidence with real Julia execution jobs and concrete local artifacts.
- Start gateway internal module extraction for project/data source handling.

### AKS-36 Raw Local Import Source Boundary Slice (2026-06-21)

- Added `/api/v1/local-data/import` source validation for raw local file intake.
- Local data imports now accept managed `local://` refs or existing filesystem files confined to configured import roots (`JULIAFLOW_IMPORT_ROOTS` plus the local data estate root).
- Rejected remote/provider import URIs, missing local files, and filesystem paths that escape allowed import roots.
- Changed the no-`sourceUri` import default to a managed `local://data/raw/<dataset>.csv` ref instead of an implicit repository fixture path.
- Documented import `sourceUri` behavior in OpenAPI and added focused Julia route coverage for valid confined import, default managed import, remote rejection, and escaped-path rejection.
- Verification passed: `npm run validate:contracts` and focused Julia import-boundary route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice adds import-root confinement, but content-type sniffing, credential scanning/redaction, PII handling, and richer audit evidence remain open before broad connector enablement.
- Gateway module split, execution-backed jobs, deeper statistical/tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Add content validation and richer audit evidence for local imports.
- Replace deterministic project route evidence with real Julia execution jobs and concrete local artifacts.
- Start gateway internal module extraction for project/data source handling.

### AKS-36 DataScienceProject Source Boundary Slice (2026-06-21)

- Added gateway validation for `DataScienceProject.datasets` so project records only accept managed local `local://` source/artifact refs.
- Rejected remote/provider dataset source URIs, traversal-shaped local refs, duplicate dataset ids, missing source refs, and `localOnly=false` dataset records.
- Documented the managed-local source expectation in the OpenAPI `ProjectDataset.sourceUri` and `artifactRef` descriptions.
- Added focused Julia route coverage for valid local refs plus remote, traversal, and non-local dataset rejection.
- Verification passed: `npm run validate:contracts` and focused Julia source-boundary route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice hardens project dataset refs, but raw local file intake still needs a fuller threat model, file size/content checks, credential redaction, and audit coverage before broad connector enablement.
- Gateway module split, execution-backed jobs, deeper statistical/tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Add file size/content checks and richer audit evidence for raw local uploads/imports.
- Replace deterministic project route evidence with real Julia execution jobs and concrete local artifacts.
- Start gateway internal module extraction for project/data source handling.

### AKS-36 Project Job Ledger Slice (2026-06-21)

- Added `DataScienceProjectJobRecord` contracts/OpenAPI schema and `DataScienceProject.projectJobs` persistence for project-scoped data-science workflow jobs.
- Added gateway job-ledger helpers and wired completed job records into transform fit/apply, statistical analysis, tuning study, final evaluation, prediction export, and drift report routes.
- Persisted job records with job type, status, dataset/split/source record linkage, output refs, and start/finish timestamps.
- Added contract assertions and Julia route smoke coverage for the full project chain and reload persistence of the job ledger.
- Verification passed: `npm run validate:contracts` and focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice adds typed project job ledger evidence, but it does not replace deterministic route records with real asynchronous execution workers or resource-aware CPU/GPU job scheduling.
- Gateway module split, broader local source trust-boundary hardening, deeper statistical/tuning/evaluation/scoring/drift execution, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Replace deterministic project route evidence with real Julia execution jobs and concrete local artifacts.
- Start gateway internal module extraction and broader local source trust-boundary hardening.
- Move remaining frontend data-science workflows behind project-backed actions.

### AKS-36 Transform Fit/Apply Semantics Slice (2026-06-21)

- Added TypeScript contracts, OpenAPI path/schema coverage, endpoint-path coverage, typed client support, and repository persistence for project-scoped `transformFitApplyRecords`.
- Added `POST /api/v1/data-science-projects/{projectId}/transforms/fit-apply` to record train-only transform fitting and held-out split application evidence.
- Added gateway validation requiring project/dataset membership, a locked split plan, `fitSplit: train`, and apply splits limited to validation/test/evaluation.
- Persisted transform fit/apply records with leakage checks and local artifact refs for fit state plus held-out apply outputs.
- Added contract assertions and Julia route smoke coverage for valid persistence, reload persistence, non-train fit rejection, and train-as-apply rejection.
- Verification passed: `npm run validate:contracts` and focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice records transform fit/apply semantics, but real Julia transform execution, transform state materialization from actual nodes, UI workflow coverage, and typed execution job lifecycle remain open.
- Gateway module split, local source trust-boundary hardening, execution-backed typed jobs, first-class lifecycle records, and project-backed frontend migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Replace deterministic transform fit/apply evidence with real Julia transform execution and state artifacts.
- Start gateway internal module extraction and local source trust-boundary hardening.
- Add execution-backed typed job runners for the project-backed data-science workflow.

### AKS-36 Drift Report Gate Slice (2026-06-21)

- Added TypeScript contracts, OpenAPI path/schema coverage, endpoint-path coverage, and typed client support for `POST /api/v1/data-science-projects/{projectId}/drift/run`.
- Added a project-scoped gateway drift route that validates project/dataset membership and blocks drift reporting until prediction export evidence exists.
- Created or reused monitoring baselines and persisted drift reports into `DataScienceProject.monitoringBaselines` and `DataScienceProject.driftReports`.
- Added validation evidence to drift reports linking project, dataset, prediction export, evaluation report, and output contract.
- Added contract assertions and Julia route assertions for successful baseline/report persistence and invalid threshold rejection.
- Verification passed: `npm run validate:contracts` and focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice records deterministic drift substrate evidence, but real drift statistics, production baseline refresh semantics, monitoring UI coverage, alert/retraining workflow, and typed drift job lifecycle remain open.
- Transform fit/apply semantics, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Replace deterministic drift evidence with real drift statistics and monitoring artifacts.
- Add transform fit/apply semantics with split/evaluation evidence discipline.
- Start gateway internal module extraction and local source trust-boundary hardening.

### AKS-36 Prediction Export Gate Slice (2026-06-21)

- Added TypeScript contracts, OpenAPI path/schema coverage, endpoint-path coverage, and typed client support for `POST /api/v1/data-science-projects/{projectId}/predictions/export`.
- Added a project-scoped gateway prediction-export route that validates project/dataset membership, requires an approved final-evaluation report, requires final-test evidence on that report, and requires explicit output contract evidence before writing an export record.
- Persisted prediction exports into `DataScienceProject.predictionExports` with local artifact refs, format, row count, output contract, and validation evidence linking the export to the approved evaluation report.
- Added contract assertions and Julia route assertions for successful prediction export persistence, bad format rejection, and missing output contract rejection.
- Verification passed: `npm run validate:contracts` and focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice records deterministic prediction-export substrate evidence, but real model scoring, prediction file materialization, output schema validation, UI workflow coverage, and typed scoring/export job lifecycle remain open.
- Transform fit/apply semantics, drift/evaluation monitoring records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Replace deterministic prediction export evidence with real Julia scoring and export artifacts.
- Add drift records and transform fit/apply semantics with the same split/evaluation evidence discipline.
- Start gateway internal module extraction and local source trust-boundary hardening.

### AKS-36 Final Evaluation Gate Slice (2026-06-21)

- Added TypeScript contracts, OpenAPI path/schema coverage, endpoint-path coverage, and typed client support for `POST /api/v1/data-science-projects/{projectId}/evaluation/run`.
- Added a project-scoped gateway final-evaluation route that validates project/dataset membership, requires a locked split with a nonzero test fraction, requires explicit `finalTestPolicy: use_final_test`, and blocks evaluation when training/tuning prerequisites are missing.
- Required final evaluation to reference a training plan with prior validation-only tuning evidence, preserving the training/tuning final-test boundary before the locked test split is used.
- Persisted final evaluation reports into `DataScienceProject.evaluationReports` with metrics, approval status, local artifact evidence, and validation evidence linking the report to the project, split, and tuning study.
- Added contract assertions and Julia route assertions for successful final-evaluation persistence, bad final-test policy rejection, and missing prerequisite rejection.
- Verification passed: `npm run validate:contracts` and focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. This slice records deterministic final-evaluation substrate evidence, but real Julia evaluation execution, model scoring artifacts, threshold/metric semantics, UI workflow coverage, and typed evaluation job lifecycle remain open.
- Prediction/output export, transform fit/apply semantics, drift/evaluation monitoring records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Replace deterministic final-evaluation metrics with real Julia scoring/evaluation artifacts.
- Add prediction/export and drift records with the same split/final-test evidence discipline.
- Start gateway internal module extraction and local source trust-boundary hardening.

### AKS-36 Validation-Only Tuning Study Slice (2026-06-21)

- Added TypeScript contracts, OpenAPI path/schema coverage, endpoint-path coverage, and typed client support for `POST /api/v1/data-science-projects/{projectId}/tuning/run`.
- Added a project-scoped gateway tuning-study route that validates project/dataset membership, requires split evidence with nonzero validation/test fractions, rejects final-test use, creates or updates a training plan, and persists a deterministic validation-only tuning study into `DataScienceProject.tuningStudies`.
- Added `validationEvidence` to tuning-study records so accepted studies expose project, dataset, split, validation/test fraction, and final-test policy context.
- Added Julia route assertions and contract assertions for successful tuning persistence and final-test misuse rejection.
- Verification passed: `npm run validate:contracts`, focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, and `npm run build`.

### Gaps Pending

- AKS-36 parent is still open. This slice records validation-only tuning substrate evidence, but real Julia hyperparameter optimization, trial artifact execution, UI workflow coverage, and typed tuning job lifecycle remain open.
- Final evaluation, prediction/output export, transform fit/apply semantics, drift/evaluation records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Replace deterministic tuning trials with real Julia tuning execution and persisted trial artifacts.
- Add final-evaluation, prediction/export, and drift records with the same split/final-test gates.
- Start gateway internal module extraction and local source trust-boundary hardening.

### AKS-36 Statistical EDA Run Substrate Slice (2026-06-21)

- Added TypeScript contracts and OpenAPI path/schema coverage for `POST /api/v1/data-science-projects/{projectId}/statistical-analysis/run`.
- Added typed client and endpoint-path coverage for project-scoped statistical analysis runs.
- Added a gateway statistical EDA run route that validates project/dataset membership, validates requested method names, generates local Plotly-compatible chart evidence, and persists the run into `DataScienceProject.statisticalAnalysisRuns`.
- Added controlled 400 responses for invalid statistical analysis requests such as unsupported methods.
- Added Julia route assertions for successful run persistence and unsupported-method rejection.
- Verification passed: `npm run validate:contracts`, focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, and `npm run build`.

### Gaps Pending

- AKS-36 parent is still open. This slice persists deterministic local EDA evidence, but real Julia statistical execution for OLS, t-test, chi-square, ANOVA, Pearson/Spearman correlation, result tables, and UI workflow coverage remains open.
- Hyperparameter tuning, final evaluation, prediction/output export, transform fit/apply semantics, drift/evaluation records, gateway module split, local source trust-boundary hardening, typed jobs, and first-class lifecycle records remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Replace deterministic EDA evidence with real Julia statistical method execution and result artifacts.
- Add typed tuning/final-evaluation/prediction/drift records and validation gates.
- Start gateway internal module extraction and local source trust-boundary hardening.

### AKS-36 Model Promotion And Deploy Validation Gate Slice (2026-06-21)

- Added validation-evidence propagation to model registry records and local deploy package records in TypeScript contracts, OpenAPI, and gateway payloads.
- Changed model registration to require `ml_validation_context` from a validated ML experiment run before creating a registry record.
- Changed local deploy packaging to require the same validation evidence before packaging or fallback-synthesizing model registry details.
- Filtered model registry list synthesis so unvalidated executions are not exposed as promotable model records.
- Added explicit 409 classification for missing model-registration and deploy-package validation evidence.
- Added Julia route assertions for blocked registration/deploy before validation, accepted registration/deploy after validation, and validation evidence on accepted records.
- Verification passed: focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, and `npm run build`.

### Gaps Pending

- AKS-36 parent is still open. This slice covers model registration and local deploy packaging only; hyperparameter tuning, final evaluation, prediction/output export, transform fit/apply semantics, and drift/evaluation records still need validation/test gates.
- Gateway module split, local source trust-boundary hardening, statistical EDA services, typed jobs, first-class model registry repository/lifecycle records, and broader project-backed route migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Add typed tuning/final-evaluation/prediction/drift records and block them when split/final-test evidence is absent or invalid.
- Start gateway internal module extraction for project/catalog/analysis/experiment/registry/monitoring responsibilities.
- Add statistical EDA run records and local source trust-boundary checks before deeper persona workflow features.

### AKS-36 ML Experiment Validation Enforcement Slice (2026-06-21)

- Extended ML experiment run contracts and OpenAPI with optional `projectId`, `splitPlanId`, and `finalTestPolicy`, and added `validationEvidence` to experiment records.
- Updated ML Studio live run requests to send the active `DataScienceProject` id, dataset id, split plan id, and `forbid_final_test` policy.
- Added gateway validation before accepting workflow ML experiment runs: matching project/dataset is required when provided, split plan evidence is required, validation/test fractions must be nonzero, and `use_final_test` is rejected for training/tuning runs.
- Persisted accepted-run validation evidence into execution metadata so experiment run/history payloads can show the project split context that produced the metrics.
- Added contract fixture/schema assertions and Julia route assertions for accepted validation evidence plus missing split and final-test misuse rejection.
- Verification passed: focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`, `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, and `npm run build`.

### Gaps Pending

- AKS-36 parent is still open. This slice guards ML experiment runs only; hyperparameter tuning, model registration, deployment packaging, final evaluation, prediction export, and drift/evaluation records still need validation/test gates.
- Gateway module split, local source trust-boundary hardening, statistical EDA services, typed jobs, model lifecycle records, and broader project-backed Transform/Models/Monitor/Deploy state remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Extend validation/test enforcement to tuning, registration, deployment, final evaluation, and prediction/export paths.
- Start gateway internal module extraction for project/catalog/analysis/experiment/registry/monitoring responsibilities.
- Add statistical EDA run records and local source trust-boundary checks before deeper persona workflow features.

### AKS-36 DataScienceProject API Negative Validation Slice (2026-06-21)

- Hardened gateway `DataScienceProject` materialization to reject unsupported `schemaVersion`, explicit route/body project id mismatches, and non-array child-record fields.
- Classified project validation failures as explicit API responses: 400 for malformed project payloads, 409 for duplicate project creation, and 404 for missing projects.
- Tightened OpenAPI `UpdateDataScienceProjectRequest` from an unbounded object to the documented project update fields.
- Added contract assertions for bounded update schemas and Julia route assertions for missing name, duplicate project, unsupported schema version, invalid child-record array shape, and route/body id mismatch.
- Verification passed: `npm run validate:contracts` and focused Julia negative route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- AKS-36 parent is still open. API payload validation is stronger, but execution-level validation/test enforcement, typed jobs, gateway module split, local source trust boundaries, statistical EDA, lifecycle gates, drift records, and broader project-backed route migration remain open.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in earlier checkpoints.

### Next Items To Implement

- Move validation/test discipline into gateway/execution checks that block tuning, registration, deployment, and final evaluation when split evidence or final-test locks are invalid.
- Start gateway internal module extraction before adding deeper stats, tuning, registry, or drift behavior.
- Add local source trust-boundary checks before enabling broad file/folder/database connectors.

### AKS-36 Data Project Frontend Persistence Slice (2026-06-21)

- Added a `DataScienceProject` aggregate to frontend `AppData` and demo fixtures, including dataset registration, schema contract columns, split plan, validation fold, final-test lock collection, and local reproducibility evidence.
- Loaded data-science projects from the live gateway through `listDataScienceProjects`; release/local-appliance mode now treats an empty project list as unavailable instead of silently substituting the fixture project.
- Added Data route project-backed schema diagnostics with editable logical types, column roles, and nullable flags.
- Added validation/test split controls for strategy, group column, depth column, split fractions, and final-test locking; edits call `updateDataScienceProject` and persist through `PUT /api/v1/data-science-projects/{projectId}` when a gateway is configured.
- Added frontend test coverage for demo schema/type/validation/final-test-lock edits and live gateway project update requests.
- Verification passed: `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx` and `npm run validate:contracts`.

### Gaps Pending

- AKS-36 parent is still open. This slice does not implement gateway module split, local source trust-boundary hardening, execution-level validation/test rejection, statistical EDA calculations, typed training/tuning/evaluation/scoring/drift jobs, model lifecycle gates, or project-backed Transform/ML Studio/Models/Monitor state.
- Full Julia suite remains environment-blocked on this Windows host by application-control policy for generated/JLL DLLs as noted in the previous checkpoint.
- Browser route QA was attempted with `npm run test:browser -- tests/browser/local-ui.spec.ts`, but Playwright could not launch Chromium on this host (`browserType.launch: spawn UNKNOWN`) before reaching app assertions.

### Next Items To Implement

- Move validation/test discipline from UI/API persistence into gateway/execution checks that block tuning, registration, and deployment when split evidence is missing or final test locks are violated.
- Start gateway module split and local import trust-boundary hardening before broad source enablement.

### AKS-36 DataScienceProject Substrate First Slice (2026-06-21)

- Added additive `DataScienceProject` TypeScript contracts and OpenAPI paths for `/api/v1/data-science-projects` and `/api/v1/data-science-projects/{projectId}`.
- Added generated-client surface coverage for list/create/get/update project calls and project endpoint paths.
- Added gateway repository records for `DataScienceProject`, file-backed persistence, PostgreSQL-compatible table/load/save methods, and lazy `LibPQ` loading so file-mode gateway startup does not require PostgreSQL artifacts.
- Added thin gateway create/list/read/update project routes with audit events and 404 handling.
- Added contract assertions, gateway-client fixture coverage, repository contract coverage, and route-level Julia assertions for create/list/get/update/reload behavior.
- Verification passed: `npm run validate:contracts`, `npm run build`, `git diff --check`, and a focused Julia route smoke with `node scripts/run-julia.mjs --compiled-modules=no --project=. -`.

### Gaps Pending

- Parent AKS-36 is not complete: design review closure, gateway product module split, local import trust-boundary hardening, validation/test locks, typed DS/ML jobs, statistical EDA execution, model lifecycle gates, drift records, project-backed frontend state, and persona-flow browser coverage remain open.
- Full `node scripts/run-julia.mjs --project=. tests/julia/runtests.jl` is blocked on this Windows host by application-control policy for generated/JLL DLLs; full suite with `--compiled-modules=no` exceeded the current timeout.

### Next Items To Implement

- Add negative contract/API tests for missing/invalid project fields and project id mismatch.
- Run the required contract/API, security, ML-validity, and MLOps design reviews against the concrete project contract.
- Start gateway module split and local trust-boundary hardening before broad local source enablement.

### Principal Persona Readiness Multi-Review (2026-06-21)

- Added `docs/principal-persona-readiness-review.md`.
- Ran domain-specific read-only reviews in parallel for contract/API, Julia gateway/runtime, frontend/UX workflow, data science/ML validity, security/local trust boundary, and MLOps/model ops.
- Collated the specialist findings through a principal reviewer synthesis.
- Principal gate decision: P0 block for implementation readiness. JuliaFlow can continue design/refactor planning, but it should not claim daily data/ML workstation readiness or deepen ML Studio, Models, Deploy, Monitor, drift, tuning, or broad connector behavior until the project architecture substrate exists.
- Updated `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/architecture.md`, and `docs/persona-architecture-review.md` to make `DataScienceProject` substrate and persona architecture refactor the next active lane.

### Gaps Pending

- No implementation was added for `DataScienceProject`, project repository, gateway module split, typed jobs, validation/test locks, statistical EDA calculations, registry lifecycle gates, drift reports, local import trust hardening, or project-backed frontend modules.
- The principal review requires follow-up design reviews against concrete design artifacts before implementation readiness: contract/API, security threat model, ML validity, MLOps lifecycle, and frontend accessibility/persona-flow.

### Next Items To Implement

- Start with additive `DataScienceProject` contracts/OpenAPI, generated-client coverage, file-backed project repository, and thin gateway project routes.
- Preserve existing workflow/data/ML endpoints as backward-compatible adapters.
- Add negative contract and Julia tests for missing required project fields before claiming the first substrate slice.

### Persona-Driven Architecture Review (2026-06-21)

- Added `docs/persona-architecture-review.md` to review the architecture against the senior data engineer, principal data scientist, MLOps, and non-coding statistics/ML personas.
- The review concluded that JuliaFlow's contract-first/local-first foundation can host the workflows, but daily-workstation readiness should be blocked until a shared `DataScienceProject` aggregate exists across Data, Transform, ML Studio, Models, Monitor, Deploy, and reports.
- Identified required architecture additions: schema/type contracts, validation/test strategy, statistical EDA run records, training/tuning/evaluation/scoring job records, prediction exports, model lifecycle records, monitoring baselines, drift reports, local source trust boundaries, and project-backed frontend actions.
- Identified required refactors: split `JuliaFlowApiGateway.jl` product logic into focused internal modules, separate fixture/demo adapters from local-appliance services, move registry state out of execution metadata, and move route-local frontend state into feature modules after contracts land.

### Gaps Pending

- This is an architecture review only; no `DataScienceProject` contracts, gateway modules, repository records, typed execution jobs, registry lifecycle gates, drift reports, or frontend feature modules were implemented in this slice.
- Existing route-specific product evidence remains useful, but it is not sufficient for daily local-workstation adoption until the architecture substrate is implemented.

### Next Items To Implement

- Start with the contract-first `DataScienceProject` substrate in `packages/contracts/`, OpenAPI, and gateway repository records.
- Refactor gateway internals into chart, data catalog, analysis, experiment, registry, monitoring, and route modules before adding deep persona features.
- Add validation/test lock enforcement and statistical EDA run records before hyperparameter tuning or domain templates.

### Data Scientist Competition Persona Readiness Report (2026-06-20)

- Added `docs/data-scientist-persona-competition-readiness-report.md` to evaluate JuliaFlow against three representative data-science workflows: Titanic binary classification, House Prices tabular regression, and ROGII wellbore/geoscience sequential-spatial regression.
- The review concluded that the app has the correct local-first product skeleton, but still needs a generalized project layer: local train/validation/test import, optional output contract import, schema/type role mapping, task/metric selection, train/validation/test transform alignment, validation/test strategy, and prediction export.
- The report identifies P0/P1/P2 backlog implications across Explorer, Data, Transform, Visualize, ML Studio, Models, Deploy, Monitor, and Settings, with wellbore-specific depth/trajectory/typewell requirements layered on the generalized substrate.
- Updated the report scope to treat Kaggle competitions as examples only and use broader data-science workflow language: train/validation/test separation, editable schema/type diagnostics, statistical EDA, hyperparameter tuning, final test locks, and prediction/export artifacts.
- Extended the report with four daily local-workstation personas: senior data engineer, principal data scientist, MLOps engineer focused on training/drift/evaluation, and non-coding statistics/ML user. The analysis maps KNIME, Orange, and H2O-style low-code expectations into JuliaFlow gaps for local connectors, quality rules, guided no-code workflows, AutoML/tuning, model registry lifecycle, drift/evaluation monitoring, CPU/GPU run evidence, and reproducible reporting.

### Gaps Pending

- The report is analysis only; no new local file picker, schema mapper/type editor, statistical EDA surface, validation/test manager, hyperparameter tuning workflow, or prediction exporter has been implemented in this slice.
- The daily-use persona expansion is analysis only; no new connector pack, data quality rule engine, local scheduling, model registry lifecycle, drift monitor, CPU/GPU run profiler, AutoML recommendation layer, or guided no-code workflow has been implemented in this slice.
- ROGII/wellbore support remains a domain template proposal until the generic tabular competition workflow exists.

### Next Items To Implement

- Convert the report's P0 items into Linear issues or map them to the existing AKS backlog.
- Start with the generic tabular data-science MVP: local dataset wizard, schema/type mapper, statistical EDA, task/metric selector, validation/test workflow, hyperparameter tuning, train/validation/test aligned transforms, and prediction CSV export.
- Add daily-workflow follow-up backlog for data-engineering connectors/quality rules, MLOps evaluation/drift dashboards, model registry lifecycle, CPU/GPU run evidence, and guided no-code defaults.

### AKS-29 Through AKS-35 Parity Hardening (2026-06-20)

- Merged PR #37 into `main` and started the follow-up branch from the updated baseline.
- Recorded per-task plans for AKS-30 through AKS-35 in `docs/aks-30-35-implementation-plan.md` before closing implementation evidence.
- Implemented AKS-29 chart foundation hardening with shared chart readiness/export helpers for ready, stale, empty, and error specs.
- Implemented AKS-30 Explorer hardening with workspace summary source evidence, artifact count, artifact locality, and no-artifact empty state.
- Implemented AKS-31 and AKS-35 Data hardening with active source state, disabled-source reasons, sample-size preview mutation, and wrapped readiness text.
- Implemented AKS-32 Transform hardening with editable node strategy/output settings, unsaved-edit warning state, validation recovery, and config evidence in logs.
- Implemented AKS-34 browser coverage for stale chart evidence, Data sampling, Transform config editing, validation state, and desktop/mobile screenshots.
- Verification passed so far: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `npm run test:browser -- tests/browser/local-ui.spec.ts`, and `git diff --check`.

### Gaps Pending

- Unsupported Data connectors remain disabled until separate gateway handlers are implemented.
- Persisted Transform pipeline editing beyond local view state remains future product depth.
- Final PR publication, CI, live-backend smoke, control-doc sync, and Linear state updates remain pending for this branch.

### Next Items To Implement

- Run `npm run smoke:live-backend-browser`, control-doc validators, and final diff checks.
- Push the branch, open a draft PR, and update Linear AKS-28 through AKS-35 with the PR and verification evidence.

### Explorer/Data/Transform Mock Parity And Interactive Local Analytics (2026-06-20)

- Created Linear parent AKS-28 and child issues AKS-29 through AKS-35 for shared chart foundation, Explorer parity, Data parity, Transform parity, gateway/contracts, visual QA, and the Data ML Readiness text-overlap bug.
- Added contract-first local interactive chart spec types and Julia/gateway helpers that emit Plotly-compatible workspace, data-profile, and transform-run chart evidence.
- Added a lazy local Plotly renderer with loading, empty, error, screen-reader summary, PNG export, and local HTML/spec export behavior.
- Updated Explorer to use gateway-backed workspace summary data, artifact-tree evidence, local activity, local package/runtime blocks, and Plotly mini charts instead of static placeholders.
- Updated Data with local source sections, disabled unsupported connectors with reasons, table/schema/profile/filter/sort/join/transform/sampling/lineage tabs, read-mode/profile refresh behavior, visible filter/sort mutations, Plotly quick EDA charts, and wrapped right-panel readiness text.
- Updated Transform with a React Flow node-edge canvas, searchable grouped palette, node selection/settings, validation/run/history evidence, before/after preview, generated Julia code, logs, artifact output, and Plotly metric charts.
- Verification passed: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `node scripts/run-julia.mjs --project=. tests/julia/runtests.jl`, `npm run test:browser -- tests/browser/local-ui.spec.ts`, and `npm run smoke:live-backend-browser`.

### Gaps Pending

- This slice is a product-quality parity pass, not a full native data-source connector implementation; unsupported sources are intentionally disabled until backed by gateway behavior.
- Plotly rendering is lazy-loaded and local, but the Plotly bundle is still large and should stay isolated from the base shell.
- Transform validation/run evidence is deterministic local gateway/demo evidence; deeper persisted pipeline editing can continue under the AKS-28 child backlog.

### Next Items To Implement

- Finish control-doc validation, commit, push, and open the draft PR for the Explorer/Data/Transform parity branch.
- Continue follow-up work from AKS-29 through AKS-35 rather than expanding scope inside this branch.

### AKS-13 Live Workflow Metadata Recovery (2026-06-20)

- Updated release/local-appliance workflow loading so backend workflow detail must include workflow id, nodes, connections, flow variables, graph layout metadata, and runtime metadata before rendering live canvas/pipeline state.
- In required modes, incomplete workflow metadata now produces an explicit unavailable state with recovery guidance instead of substituting the demo workflow or synthetic canvas nodes.
- Kept demo/development behavior compatible with deterministic fixture fallback for offline demos and local development.
- Updated Transform to show workflow metadata recovery guidance when no backend workflow nodes are available.
- Added focused frontend coverage for incomplete local-appliance metadata and preserved empty backend list behavior with complete workflow metadata.
- Verification passed: `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run test`, `npm run build`, `npm run validate:contracts`, and `npm run smoke:live-backend-browser`.

### Gaps Pending

- Provider/cloud deployment and hardware-gated GPU work remain optional compatibility work unless explicitly reprioritized.
- The live browser smoke passed, but the Julia HTTP server still prints connection-cancel teardown noise after Playwright finishes; this is not a failing gate.

### Next Items To Implement

- Push this AKS-13 branch and open the draft PR after local verification/doc sync passes.
- Keep `artifacts/release-verification/live-backend-browser` as live UI evidence for PR and Linear cleanup.

### AKS-5 Stage 5 Release Verification Implementation (2026-06-19)

- Added `npm run verify:release` as the single release verification entrypoint with deterministic logs/summary artifacts under `artifacts/release-verification/latest`.
- The verifier classifies bootstrap, product, runtime, control-doc, and diff failures and runs install, doctor, contracts, build, tests, Julia tests, local smokes, live browser smoke, control-doc validators, and `git diff --check` unless explicitly skipped.
- Added `npm run smoke:live-backend-browser` with a local gateway, Vite frontend, Playwright live config, and release/local-appliance browser coverage.
- The live smoke verifies no false demo fallback, Data import, Explorer save/run, Monitor execution records, dashboard rows/export, Settings/auth state, deterministic Offline Hub install, and reproducibility bundle export.
- Hardened Windows execution by disabling Julia compiled modules/package images for the live smoke, making `LibPQ` lazy so file-backed gateway runs do not load PostgreSQL binary artifacts, installing Playwright Chromium, and killing spawned process trees on cleanup.
- Adjusted frontend live loading to use backend workflow/dashboard ids instead of fixture ids and de-duplicate dynamic Visualize table columns.

### Gaps Pending

- Full no-skip fresh-checkout `npm run verify:release` remains pending before AKS-5 can be marked complete.
- Julia tests and local smoke suite still need a full release verifier pass on the final Stage 5 PR branch after control docs are updated.
- GitHub PR publication/CI evidence remains pending for this Stage 5 branch.

### Next Items To Implement

- Re-run `npm run verify:release` without skip flags from a fresh checkout or clean temp clone.
- Link passing release verification artifacts in `docs/brd-traceability.md` before closing AKS-5.
- Push the Stage 5 branch and open/update the draft PR after local gates pass.

### AKS-5 Native Windows Bootstrap Compatibility Slice (2026-06-18)

- Restored the release baseline from the GitHub repository in a temp clone after the local `C:\Users\aksha\Documents\LowCodeJulia` folder was confirmed stale and not a Git checkout.
- Confirmed the remote baseline includes the modular frontend, Playwright browser gate, Offline Hub, reproducibility, backup/restore, and migration proof scripts.
- Broadened the local toolchain guard so native Windows Node/Julia and Debian-native Node/Julia are supported, while WSL `/mnt/c` Windows Node interop remains blocked.
- Added `npm run doctor:windows` and `npm run julia:instantiate` for the Windows-native bootstrap path and generated Julia manifest policy.
- Added explicit `dev-local --skip-instantiate` semantics so `--no-deps` remains Docker-only and Julia dependency bypass is deliberate.

### Gaps Pending

- The requested Documents workspace still cannot be restored in place by shell commands in this session because shell writes under `C:\Users\aksha\Documents\LowCodeJulia` fail even though patch writes work; the implementation branch is therefore maintained from the verified temp clone.
- Draft PR publication remains the handoff path for the staged AKS-5 branch.
- Later AKS-5 release-mode/product behavior work remains staged behind this bootstrap compatibility slice.

### Next Items To Implement

- Push the AKS-5 branch and open a draft PR against `main`.
- Continue Stage 2 release/demo mode separation and live-backend browser verification on top of the restored modular frontend baseline.

### Backend-Backed Deploy Packaging Actions (2026-06-17)

- Added the final planned product-depth slice after Visualize checkpoint/export actions.
- Added workflow local deploy package contracts, OpenAPI paths, typed gateway client methods, and client fixture coverage.
- Added gateway `POST /api/v1/workflows/{workflowId}/deploy/package` and `GET /api/v1/workflows/{workflowId}/deploy/packages` routes.
- Deploy package records persist into local execution metadata and carry workflow/model/checkpoint IDs, endpoint URL, service/package refs, package checksum, generated Julia service code, run command, deployment status, and artifact evidence.
- Packaging marks the associated model registry record `local_ready`.
- Updated Deploy to package local services against the gateway when configured and use deterministic demo fallback otherwise.
- Added Deploy package history and artifact evidence in the product view.
- Added Julia gateway route assertions, typed-client contract coverage, OpenAPI assertions, and frontend demo smoke coverage.

### Gaps Pending

- The mock-aligned local product workflow now has backend-backed Data, Transform, ML Studio, Models, Visualize, and Deploy actions for the current local-first slice.
- Provider/cloud deployment remains optional compatibility work and is not part of this local deploy package slice.
- Richer deploy UX such as downloadable package archives or process supervision can follow only when tied to a concrete local workflow need.

### Next Items To Implement

- Finish PR verification/CI/review and merge once green.
- After merge, audit the active BRD/control set for the next highest-value local-first gap instead of reopening provider deployment by default.

### Backend-Backed Visualize Checkpoint/Export Actions (2026-06-17)

- Added the next product-depth slice after backend-backed Models registry actions.
- Added dashboard checkpoint-export contracts, OpenAPI path/schemas, and typed gateway client method.
- Added gateway `POST /api/v1/workflows/{workflowId}/dashboards/{dashboardId}/checkpoint-export` route.
- The route composes local dashboard publish, checkpoint creation, and reproducibility bundle export, returning dashboard/checkpoint/bundle artifact refs and checksums.
- Updated Visualize to run checkpoint export against the gateway when configured and use deterministic demo fallback otherwise.
- Added Visualize export history so checkpoint tags, bundle IDs, artifact counts, and bundle checksum prefixes are visible in the product view.
- Added Julia gateway route assertions and frontend demo smoke coverage for the Visualize checkpoint/export action.

### Gaps Pending

- Local Deploy packaging remains the last product-depth follow-up before claiming full mock-aligned product readiness.
- Current Visualize export records expose local artifact evidence; richer downloadable bundle UX can follow after Deploy packaging closes.

### Next Items To Implement

- Continue the local product-depth path with local Deploy packaging actions.
- Keep contracts, Julia tests, frontend tests, build, control-doc sync, BRD traceability, and `git diff --check` in the PR gate set.

### Backend-Backed Models Registry Actions (2026-06-17)

- Added the next product-depth slice after backend-backed ML Studio experiment actions.
- Added workflow model register/list contracts, OpenAPI paths, typed gateway client methods, and client fixture coverage.
- Added gateway `POST /api/v1/workflows/{workflowId}/models/register` and `GET /api/v1/workflows/{workflowId}/models` routes.
- Model registry records are persisted into local execution metadata and carry checkpoint, model, dataset checksum, primary metric, tags, owner, deployment status, and local artifact evidence.
- Updated Models to register models against the gateway when configured and use deterministic demo fallback otherwise.
- Added Julia gateway route assertions and frontend demo smoke coverage for the Models registry action.

### Gaps Pending

- Visualize checkpoint/export depth and local Deploy packaging remain product-depth follow-ups.
- Current model registry records use local execution/explainability evidence; richer registry search/filter UX can follow after Visualize and Deploy close.

### Next Items To Implement

- Continue the local product-depth path with Visualize checkpoint/export before local Deploy packaging.
- Keep contracts, Julia tests, frontend tests, build, control-doc sync, BRD traceability, and `git diff --check` in the PR gate set.

### Backend-Backed ML Studio Experiment Actions (2026-06-17)

- Added the next product-depth slice after backend-backed Data and Transform actions.
- Added workflow ML experiment run/history contracts, OpenAPI paths, typed gateway client methods, and client fixture coverage.
- Added gateway `POST /api/v1/workflows/{workflowId}/ml/experiments/run` and `GET /api/v1/workflows/{workflowId}/ml/experiments` routes.
- Experiment records are tied to local execution/checkpoint state and explainability evidence: dataset/model IDs, dataset checksum, metrics, feature importance, hardware backend, GPU readiness, and local artifact references.
- Updated ML Studio to run experiments against the gateway when configured and use deterministic demo fallback otherwise.
- Added Julia gateway route assertions and frontend demo smoke coverage for the ML Studio experiment action.

### Gaps Pending

- Models registry mutation, Visualize checkpoint/export depth, and local Deploy packaging remain product-depth follow-ups.
- Current experiment records are deterministic local evidence from execution/explainability state; richer MLJ training execution remains future depth work.

### Next Items To Implement

- Continue the local product-depth path with Models registry mutation or Visualize checkpoint/export depth before local Deploy packaging.
- Keep contracts, Julia tests, frontend tests, build, control-doc sync, BRD traceability, and `git diff --check` in the PR gate set.

### Mock-Aligned Local Product Workflow Vertical (2026-06-17)

- Added the first implementation slice for the mock-aligned local product workflow vertical.
- Extended the existing frontend route shell from Canvas/Dashboard into Explorer, Data, Transform, ML Studio, Models, Visualize, Deploy, Hub, Monitor, and Settings.
- Preserved `/dashboard` viewer compatibility by mapping dashboard deep links into the Visualize surface.
- Wired Data, Transform, ML Studio, Models, and local-only Deploy views to shared local workspace state: gateway health, data estate zones/checksums, workflow graph, checkpoints, executions, explainability/model evidence, dashboards, and local runtime endpoints.
- Added focused frontend coverage that walks Explorer -> Data -> Transform -> ML Studio -> Models -> Visualize -> Deploy in demo mode.

### Gaps Pending

- This is a frontend-shell vertical; deeper backend state mutation for data import, transform execution, experiment tracking, model registry CRUD, and deploy packaging remains open.
- Hub, Monitor, and Settings already use shared state, but should be tightened further around the same product journey in follow-up slices.

### Next Items To Implement

- Add backend-backed product state/actions for the vertical, starting with Data import/profile and Transform run/history if product depth remains the priority.
- Re-run full local-first gates after PR #11 is landed and this branch is rebased onto updated `main`.

### Backup/Restore And Migration Proof (2026-06-17)

- Closed the backup/restore and migration lane after PR #10 landed.
- Added gateway export/import routes for local appliance backup bundles.
- Bundle evidence now includes workflows, checkpoints, executions, published dashboards, Hub records, auth policy/directory, package/runtime metadata, local settings, and data-estate artifact references/checksums.
- Restore now validates the signed backup checksum, reports missing local artifacts and checksum mismatches, rehydrates metadata into a fresh local repository, and rejects tampered bundles.
- Added `scripts/smoke-local-migration.mjs`, `scripts/smoke-local-migration.jl`, and `npm run smoke:local-migration` to prove migration without cloud credentials.

### Gaps Pending

- Backup bundles intentionally reference local data-estate files by path/checksum rather than embedding binary artifact bytes.
- Mock-derived product modules still need an implementation vertical before local-first product readiness can be claimed.

### Next Items To Implement

- Start the mock-aligned local product workflow vertical: Explorer/Workspace -> Data -> Transform -> ML Studio/Models -> Visualize -> checkpoint/export, keeping Hub, Monitor, and Settings wired into the same local state.

### Academic Reproducibility Workflow Proof (2026-06-17)

- Closed the academic reproducibility workflow lane after the Offline Hub and mock-aligned BRD product-surface slices.
- Added gateway export/import routes for local reproducibility bundles.
- Bundle evidence now includes workflow definition, checkpoint, dataset reference/checksum, dataset card, Julia/package metadata, runtime config, seeds, model artifact evidence, metrics, explainability output, dashboard snapshot, user notes, local-only flag, and deterministic bundle checksum.
- Added tamper rejection for checksum mismatches.
- Added `scripts/smoke-local-reproducibility.mjs`, `scripts/smoke-local-reproducibility.jl`, and `npm run smoke:local-reproducibility` to prove export/reimport into a fresh local repository without network or cloud credentials.

### Gaps Pending

- Backup/restore and migration remain open and should cover local data estate backup, metadata backup, checkpoint/workflow bundle portability, dashboard/model/package/settings portability, and restore integrity checks.
- Mock-derived product modules still need implementation slices before they can be claimed complete.

### Next Items To Implement

- Start backup/restore and migration proof unless a mock-derived local product module slice is explicitly selected first.

### Mock-Aligned BRD Product Surface Refresh (2026-06-16)

- Compared the eight `mockdesigns/` screens against the current BRD and repository state.
- Updated `business-requirements-v0.3.0.md` so Explorer, Data, Transform, ML Studio, Models, Deploy, Visualize, and Settings are explicit local-first product modules.
- Added mock-derived requirements for local workspace overview, local source connectors, visual transforms, MLJ training, local experiment tracking, model registry, local deployment targets/endpoints, dashboard builder/export, local package/Julia settings, API keys, autosave, and snapshots.
- Reworked stale cloud/provider references so hosted SaaS collaboration, remote managed inference, cloud telemetry, cloud model registries, cloud deployment, external connectors, and external registries remain optional compatibility only.

### Gaps Pending

- This was a BRD/control-doc refresh only; mock-derived features still need implementation slices before they can be claimed complete.
- Academic reproducibility and backup/restore remain open core local-first lanes.

### Next Items To Implement

- Continue with academic reproducibility workflow unless a mock-derived local product module slice is selected first.

### Debian Toolchain / Offline Hub Proof Slice (2026-06-16)

- Closed the sixth local-first GA lane after explainability/model evidence proof.
- Replaced the active Windows/WSL toolchain path with Debian-native checks: `npm run doctor:debian` verifies native Linux/nvm Node and repo-local Juliaup LTS with workspace-local Julia depots.
- Gateway `/health` now exposes local Hub cache readiness, artifact-store path, mirror-registry path, artifact cache root, bundled extension count, installed local extension count, and offline install readiness.
- Local bootstrap initializes offline Hub artifact and mirror registry files under the local appliance cache.
- `npm run smoke:local-offline-hub` verifies local official extension registration/enablement through the gateway router without external registry access and keeps unsafe sandbox commands blocked.
- Frontend Monitor renders Offline Hub readiness and install-proof evidence, with TypeScript/OpenAPI, Julia, frontend, and contract tests covering the expanded surface.
- Dependency hygiene follow-up is closed in this PR branch: `npm audit --audit-level=moderate` reports zero vulnerabilities after the Vite 8 lockfile upgrade.

### Explainability / Model Evidence Proof Slice (2026-06-06)

- Closed the fifth local-first GA lane after local hardware runtime proof.
- Gateway `/health`, checkpoint records, and accepted execution records now expose deterministic explainability evidence: dataset card, model card, feature importance, local prediction explanation, limitations/warnings, and reproducibility-bundle readiness.
- `scripts/dev-local.mjs` smoke checks now reject missing explainability evidence, and `npm run smoke:local-explainability` verifies the local single-user surface without cloud or GPU dependencies.
- Frontend Monitor renders explainability status, model-card metrics, explanation method, and execution-card evidence for operator review.
- TypeScript/OpenAPI contracts, Julia gateway tests, frontend tests, and contract tests cover the expanded evidence surface.



### Local Hardware Runtime Proof Slice (2026-06-03)

- Closed the fourth local-first GA lane after metadata/database proof.
- Gateway `/health` now exposes hardware profile status, selected backend, bounded CPU scheduler policy, CPU worker concurrency, CPU memory limit, CUDA probe status, hardware/simulated GPU counts, VRAM totals, and GPU device summaries.
- `scripts/dev-local.mjs` smoke checks now reject incomplete hardware profile, CPU scheduling, memory-limit, CUDA status, and GPU probe evidence.
- Added `scripts/smoke-local-hardware.mjs` and `npm run smoke:local-hardware` to prove CPU fallback with an empty GPU registry and deterministic CUDA-smoke skip behavior when CUDA is not requested.
- Frontend Monitor renders hardware profile, CPU scheduler/memory limit, GPU probe, and VRAM evidence alongside data-estate and metadata readiness.
- Hardware-backed CUDA and multi-GPU proof remain conditional on available local hardware or CI runners with visible CUDA devices.

### Local Metadata / Database Proof Slice (2026-05-31)

- Closed the third local-first GA lane after the local data estate proof.
- Gateway `/health` now exposes metadata mode, backend, root, readiness, schema status, concurrency status, and metadata capability evidence.
- `scripts/dev-local.mjs` smoke checks now reject incomplete metadata evidence for `single-user` file mode and `lab-team` PostgreSQL mode.
- Added `scripts/smoke-local-metadata.mjs`, `scripts/smoke-local-metadata.jl`, and `npm run smoke:local-metadata` to prove single-user file metadata plus live Docker Postgres lab/team metadata with isolated homes/schemas and smoke-schema cleanup.
- Frontend Monitor renders metadata mode/readiness/concurrency/capabilities next to data-estate and profile evidence.
- Julia repository tests now prove shared PostgreSQL catalog/cursor visibility across two repository instances.
- Metadata backup/restore and migration integrity are intentionally deferred to the later backup/restore lane.

### Local Data Estate Proof Slice (2026-05-30)

- Closed the second local-first GA lane after the bootstrap proof.
- Gateway `/health` now exposes managed data-estate evidence: manifest root, per-zone manifest checksum records, Arrow IPC and Parquet artifact formats, quota/used bytes, cleanup hook status, backup root/status, and DuckDB query binding status/path.
- Local bootstrap smoke now verifies managed manifests, artifact formats, cleanup/backup readiness, and DuckDB binding before accepting the local appliance state.
- Added `scripts/smoke-local-data-estate.mjs` and `npm run smoke:local-data-estate` as a bounded temporary-home proof command.
- Frontend Monitor renders estate manifests, quota, DuckDB query status, and cleanup/backup state for operator review.
- Updated Julia, contract/OpenAPI, and frontend tests for the expanded managed data-estate health surface.

### Local Appliance Bootstrap Proof Slice (2026-05-29 to 2026-05-30)

- Continued from partial local-first bootstrap implementation already in the worktree.
- Added `scripts/dev-local.mjs` and `scripts/smoke-local-bootstrap.mjs` for one-command local bootstrap and bounded smoke execution.
- Added `npm` scripts `dev:local` and `smoke:local-bootstrap` in `package.json`.
- Implemented profile-aware local appliance bootstrap (`single-user`, `lab-team`, `s3-compatible-local`, `developer`) with default `single-user`.
- Local bootstrap now initializes appliance home/data-estate zones (`raw`, `processed`, `features`, `models`, `runs`, `checkpoints`, `dashboards`, `logs`, `extensions`) and wires local env defaults with cloud credentials not required.
- Extended gateway `/health` and cross-layer contracts/OpenAPI for local appliance evidence: profile/home/paths, zone readiness, disk status, local service URLs, Postgres/MinIO profile status, and CPU/GPU readiness/fallback.
- Frontend Monitor now renders the new local appliance health evidence.
- Focused tests were updated in Julia (`tests/julia/runtests.jl`), contracts (`tests/contracts/workflow-schema.test.mjs`), and frontend (`apps/frontend/src/App.test.tsx`) for the expanded health surface.
- Verified in this environment: Julia test suite passed and both new runner scripts passed syntax checks.
- Runtime verification update (2026-05-29, later pass): Windows Node and Julia installs are now present and executable (`C:\\Program Files\\nodejs\\node.exe` -> `v26.2.0`; Windows `julia.exe` reports `1.12.6`). npm workspace gates still require a fresh shell/session PATH propagation before reliable re-run.

### Repository Canvas / Understanding

- Repository canvas completed on `2026-04-19`
- Core docs read:
  - `README.md`
  - `docs/architecture.md`
  - `docs/architecture-overview.md`
  - `docs/project-tracker.md`
  - `docs/checkpoint-log.md`
- Confirmed repo is active monorepo, not minimal scaffold only
- Confirmed current product shape:
  - React authoring frontend
  - shared TS contracts
  - Julia API gateway
  - Julia execution service
  - Julia node SDK + base extension pack
  - local Docker platform deps
  - ArgoCD/Kubernetes deployment path
- Added onboarding map:
  - [docs/repo-onboarding.md](/home/akshayrj00/my_project/docs/repo-onboarding.md)
- Reconciled `AGENTS.md` with actual monorepo structure, commands, and language/tooling conventions
- Reconciled `AGENTS.md` and repo-local skills again on `2026-05-28` so local-first appliance work routes through current installed skills/plugins instead of stale skill names or hard-coded model prompts.
- Reconciled `AGENTS.md` again on `2026-04-19` to make `caveman:caveman` the default session communication mode for this repo

### Foundation / Contracts

- Monorepo foundation created across `apps/`, `services/`, `packages/`, `infra/`, `docs/`, `tests/`
- Shared workflow schema, OpenAPI surface, JSON-RPC protocol, TS contracts created
- Julia node SDK and CPU-first execution service scaffold created
- API gateway supports:
  - workflow list/detail
  - workflow create/import/update
  - workflow execute
  - execution list/detail/status transition
  - checkpoint create/list
  - realtime JSON-RPC websocket endpoint
- File-backed repository and PostgreSQL-ready repository path present
- Checkpoint docs started; the old empty release-note stubs were later removed during documentation cleanup, and current checkpoint evidence lives in `docs/checkpoint-log.md`.

### Frontend / Alpha Workspace

- Frontend moved from foundation dashboard toward authoring-first Alpha workspace
- Three-pane workspace present:
  - left repository / quick-add / flow variables
  - center canvas
  - right inspector
- Live gateway hydration works
- Draft workflow state now editable in frontend
- Quick-add creates real draft nodes in graph
- Flow variables editable in UI
- Selected node config editable in inspector
- Save/update loop wired to gateway
- Run loop wired to gateway
- Frontend now opens realtime websocket subscription to `/api/v1/realtime` when gateway configured
- Realtime node state events now overlay live canvas/runtime status in UI
- Realtime workflow state events now refresh execution rail and workflow snapshot when draft is clean
- Realtime execution state events now update execution rail directly without waiting for full refetch
- Inspector now supports manual connection add/remove actions
- Connection editor now previews compatibility errors for type mismatch, duplicate edges, and occupied target inputs
- Canvas nodes now support drag/drop repositioning inside current draft session
- Canvas positions now persist through contract-first workflow save/load path
- Frontend workflow save/update now sends shared workflow JSON instead of draft-only TOML bridge payloads
- Starter node catalog now covers representative Alpha categories:
  - source
  - filter
  - join
  - aggregate
  - trainer
  - stream source
  - control trigger
  - BI outlet
  - sink
- Dashboard v0 shell now renders workflow-bound dashboard/chart definitions in workspace support panels
- Dashboard v0 composer now supports in-workflow editing for:
  - dashboard name
  - outlet binding
  - dataset key
  - refresh mode
  - chart add/remove
  - chart title/family/field edits
- Hub v0 shell now renders extension catalog entries and install/enable controls in the frontend repository panel
- Demo fallback still works when no gateway configured

### Runtime / Execution

- Execution accept path works through REST and realtime JSON-RPC
- Runtime inputs now supported for execute path:
  - `executionMode`
  - `flowVariables`
- Execution metadata and status history aligned closer to frontend contract
- Realtime gateway notifications now emit full node state set for canvas subscribe and workflow execute flows
- Realtime gateway notifications now emit explicit `execution.state.changed` payloads for latest execution lifecycle state
- Execution records now include resource-plan metadata for CPU/GPU lane assignment
- Workflow/runtime contract now supports batch vs stream mode plus starter source/window/policy metadata
- Realtime gateway now keeps canvas/dashboard subscribers in gateway state and broadcasts save/execution updates beyond request-scoped replies
- New realtime save event contract added:
  - `repository.save.changed`
- Streaming MVP gateway/runtime slice now supports:
  - stream activation on workflow execute
  - source/topic metadata on execution records
  - stream lifecycle states: `active`, `paused`, `stopped`
  - realtime pause/resume/stop handling through JSON-RPC
  - streaming checkpoint notification on stream stop
- Stream executions now surface `streaming_active` runtime state to canvas/rail consumers
- Batch GPU executions now emit a first-class dispatch plan with lane, worker pool, isolation mode, and accelerator metadata
- Gateway now auto-queues GPU-tagged batch workflows onto an isolated GPU worker lane instead of leaving them as passive planner metadata
- Frontend execution rail now surfaces GPU lane dispatch context from gateway execution records
- Local Docker Compose now includes an optional `gpu` profile hook for a dev GPU worker container
- Gateway now exposes Hub v0 catalog/install endpoints with persisted extension records for file and PostgreSQL repository backends
- New `services/worker-service/` module now owns streaming lane activation, stream lifecycle transitions, and GPU queue activation as a dedicated service seam
- API gateway now delegates stream/GPU worker lifecycle mutations through worker-service while keeping repository persistence and realtime fan-out
- Worker-service state now tracks active stream executions and GPU lane ownership separate from transport subscriptions
- New `scripts/run-stream-worker.jl` polls persisted execution records and promotes queued stream jobs in out-of-process mode
- Gateway now supports `JULIAFLOW_STREAM_WORKER_MODE=process` to hand streaming activation off to the stream worker while preserving inline mode for local compatibility
- Docker Compose dev stack now includes a `stream-worker` service entry for file-backed local worker-runtime experiments
- Gateway legacy polling path was added for worker-driven stream status rebroadcast before durable event backbone existed
- Execution payload deserialization now round-trips worker metadata back into internal snake_case form so out-of-process worker updates remain actionable
- New `scripts/run-gpu-worker.jl` now polls persisted GPU executions and promotes queued GPU jobs into active worker-owned runtime state
- Docker Compose `gpu-worker` profile now runs the real GPU worker script instead of a placeholder idle container
- Gateway legacy polling path also covered worker-driven GPU status rebroadcast before durable consumer became primary
- Worker-runtime Phase B slice is now complete: stream and GPU lanes both support queued persisted work, external worker pickup, and gateway-visible realtime propagation
- Milestone A thin event backbone slice now landed:
  - durable event envelope/types added to contracts
  - repo-backed append-only event log added for file and PostgreSQL backends
  - per-consumer cursor persistence added for file and PostgreSQL backends
  - workflow save, execution save, and Hub extension save now dual-write durable events at mutation time
  - stream checkpoint completion now emits durable event records
  - gateway event consumer loop and manual consume path now translate durable events back into existing websocket notifications
  - legacy sync entrypoint now defers to durable event consumer whenever backbone is enabled, reducing duplicate fan-out risk during migration
  - worker-side execution saves now stamp producer identity (`stream-worker`, `gpu-worker`)
  - tests now cover event append/read/cursor/replay/idempotent consumer behavior
- Hub hardening slice now landed:
  - manifest now carries engine compatibility, contract version, supported checkpoints, dependencies, publisher identity, signature placeholder, and release notes reference
  - gateway compatibility evaluator now returns warnings/blockers and persists compatibility snapshots on Hub records
  - enable action now blocks incompatible extensions and marks them `incompatible`
  - Hub register endpoint now persists new extension catalog entries with evaluated compatibility
  - frontend Hub panel now shows compatibility state, blockers, warnings, publisher identity, and richer install/enable/disable affordances
- BI publish/layout thin slice now landed:
  - dashboard draft charts now carry persisted panel layout metadata
  - published dashboard artifact store now exists independently from workflow draft state
  - gateway now exposes publish and get-published-dashboard routes
  - frontend now supports dashboard publish action and published-vs-draft preview toggle
  - tests now cover published dashboard repository persistence plus publish/get gateway routes
- BI viewer/share slice now landed:
  - URL-driven published dashboard viewer state now exists in frontend
  - published dashboard surface now renders read-only chart cards with dataset/version metadata
  - share link action now copies or prints URL for published dashboard viewer
  - frontend tests now cover publish-to-viewer flow
- UI shell + UX refactor slice now landed:
  - frontend moved from one giant showcase page to route-based product shell
  - dedicated primary views now exist for:
    - Canvas
    - Dashboard
    - Hub
    - Monitor
    - Settings
  - canvas keeps authoring-first three-pane mental model while removing roadmap/checkpoint clutter from primary workflow screen
  - dashboard authoring and published viewer now live in dedicated BI workspace
  - Hub moved into dedicated trust/upgrade-aware marketplace surface
  - monitor now surfaces health discovery, worker modes, execution rail, and published artifact summary outside canvas
  - settings now holds roadmap/checkpoint context plus theme/publish defaults
- Contract/backend hardening for UI/UX upgrade now landed:
  - health payload now exposes realtime transport, event backbone mode, consumer poll interval, stream worker mode, and GPU worker mode
  - published dashboards now carry additive share/access metadata:
    - `visibility`
    - `shareToken`
  - workflow-scoped published dashboard listing route now exists
  - durable event schema now includes `dashboard.published`
  - Hub records now carry:
    - trust result
    - upgrade info
    - installed version
  - Hub install action now supports `upgrade`
  - gateway trust policy now blocks enabling unsigned partner extensions
- Frontend node library UX now groups starter nodes by family for denser scanning in canvas sidebar
- Frontend Monitor module expansion now renders executor dataflow stage-policy detail rows and per-node executor/branch result evidence, including callback/dataflow state, readiness barrier, source/sink counts, row counts, output kind, and output-ref counts.
- Repository sanity pass removed tracked `.staging/` skill residue and added `.staging/` to `.gitignore`; tracked BRD/persona binary artifacts remain intentional control/product artifacts.
- Dependency hygiene pass resolved the moderate `ws` audit advisory via lockfile update.
- Core BRD now uses the v0.4.0 local-first baseline in `business-requirements-v0.3.0.md`: local appliance install, local data estate, DuckDB analytics, PostgreSQL lab/team metadata, optional MinIO, local CPU/GPU hardware validation, AI explainability, offline Hub, academic reproducibility bundles, and backup/restore are active direction.

### Alpha Core Contract Deepening

- Workflow contracts, schema, Julia parser, fixtures, and frontend models now support:
  - graph revision
  - node layouts
  - viewport
  - selected node
  - dashboard definitions
  - fixed BI chart families
  - node capability descriptors
  - runtime/streaming metadata
- Gateway contracts now support Hub v0 extension manifest/catalog/install payloads and client endpoints
- Workflow fixtures and tests now exercise graph persistence, dashboard payloads, streaming runtime config, and execution resource planning
- Execution contracts and tests now also exercise dispatch planning and isolated GPU queue metadata
- OpenAPI artifact refreshed for current workflow, execution, checkpoint, and Hub REST payloads
- Repo onboarding and README docs reconciled with current Alpha-core behavior

### Alpha Gap Hardening (2026-04-23)

- Published dashboard read path now validates public share-token access (`shareToken` query)
- Gateway now rejects missing/invalid share token for published public dashboard reads
- Contracts/OpenAPI/gateway client now encode share-token read parameter for published dashboard route
- Frontend viewer now forwards URL share token on published dashboard fetch
- Workspace-scoped published dashboard reads now require `workspaceToken` (env-backed server gate)
- Workspace-scoped published dashboard reads now also accept `Authorization: Bearer <workspace-token>` for server-side private access
- Contracts/OpenAPI/gateway client now include workspace-token read parameter for published dashboard route
- OpenAPI now documents optional dashboard authorization header for published-dashboard reads
- Frontend viewer now forwards URL workspace token on published dashboard fetch
- Frontend viewer can now forward workspace bearer token from env config for workspace dashboard reads
- BI draft workspace now supports dashboard duplicate/remove controls (with single-draft safety guard) for richer multi-dashboard composition
- Gateway health payload now includes:
  - event log size
  - latest event sequence
  - gateway consumer cursor
  - gateway consumer lag
  - event-consumer catch-up percent
  - active stream execution count
  - queued GPU execution count
  - queued stream execution count
  - active GPU execution count
  - GPU worker-owned execution count
  - total queued execution count
  - total running execution count
- Monitor view now renders those runtime diagnostics directly
- Hub trust policy now hardens partner provenance:
  - signature must use `sig:` prefix
  - release notes reference must be present and `https://`
  - publisher identity suffix must be non-empty
  - package reference must use `hub://` scheme for partner extensions
  - signature must include partner publisher identity suffix
- Hub marketplace cards now surface package reference and release notes provenance fields
- Base extension node pack now includes `base.filter_rows` with new extension tests
- Base extension node pack now also includes `base.aggregate_rows` with extension tests
- Gateway Julia tests now also cover:
  - partner release-notes URL trust blocker (`https://` required)
  - partner publisher-identity suffix trust blocker (non-empty required)
  - workspace token gate (missing/invalid/valid)
  - expanded health diagnostics fields (latest event sequence, queued stream, active GPU, worker-owned GPU)
  - partner package-ref scheme trust blocker (`hub://` required)
  - partner signature identity binding trust blocker
- Frontend BI workspace test now covers duplicate/remove dashboard composition flow
- Extension test suite now covers aggregate rows node behavior directly
- Frontend viewer test now covers workspace bearer-auth fetch path
- Julia gateway tests now cover workspace bearer token access (invalid/valid)
- Contracts/frontend/julia tests now cover event-consumer catch-up and total queued/running execution diagnostics
- Autopilot context/spec/impl artifacts captured under `.omx/context/` and `.omx/plans/`

### BRD Gap Review / Planning (2026-04-24)

- Reviewed `JuliaFlow_BRD_v1.0.docx` against current repo code and docs
- Created detailed BRD gap execution plan:
  - `.omx/plans/brd-gap-review-2026-04-24.md`
- Created explicit TODO source aligned to BRD gaps:
  - `docs/TODO.md`
- Verification for planning/doc update completed:
  - `git diff --check`
  - `npm run test`
  - `npm run build`
  - `julia --project=. tests/julia/runtests.jl`
  - `julia --project=. extensions/base/test/runtests.jl`
- Confirmed target milestone remains `cp/02-alpha-core` completion toward Phase 1 / Alpha readiness
- Confirmed largest remaining gaps are runtime/product depth, not route-shell foundation:
  - real base-node behavior and node-library breadth
  - BI chart-data/semantic layer
  - Auth/RBAC beyond env token gates
  - streaming window/checkpoint/backpressure runtime
  - actual GPU compute path
  - Hub publish/install sandbox and mirror path
  - observability/performance/deployment hardening

### Extension / Node Pack

- Base extension path proven
- Starter representative nodes added/planned in extension lane:
  - passthrough
  - source
  - sink
  - transform
  - basic ML placeholder
  - filter rows

### Verification Done

- `npm run test`
- `npm --workspace @juliaflow/frontend run build`
- `julia --project=. tests/julia/runtests.jl`
- `julia --project=. extensions/base/test/runtests.jl`
- `npm run build`


### Base Node Pack Reality Pass (2026-04-24)

- Completed first P0 base node reality pass:
  - base extension registry now exposes 25 Tier-1 nodes
  - added shared inline tabular payload helpers while preserving `format = :arrow_ipc` and `ref` boundary fields
  - select/filter/aggregate/trainer nodes now materialize deterministic inline-row results instead of placeholder forwarding
  - added Tier-1 transform/combine/profile/BI nodes including rename, cast, fill/drop missing, sort, limit, sample, distinct, constant column, row number, concat, inner join, stats, profile, split, ratio, bucketize, and BI outlet
  - extension tests now assert materialized row outputs across all new Tier-1 nodes
- Created BRD traceability artifact:
  - `docs/brd-traceability.md`
- Verification for this slice:
  - `julia --project=. extensions/base/test/runtests.jl`
  - `julia --project=. tests/julia/runtests.jl`


### BI Chart-Data Seam (2026-04-24)

- Added first BI v0 chart-data seam:
  - contracts now define `GatewayDashboardChartDataResponse`
  - gateway client now exposes `getPublishedDashboardChartData`
  - OpenAPI now documents `/api/v1/dashboards/{dashboardId}/charts/{chartId}/data`
  - API gateway now reuses published-dashboard public/workspace auth for chart-data reads
  - chart-data response includes fields, rows, row count, refreshed timestamp, and minimal semantic dimensions/measures
  - frontend viewer now fetches chart data and displays row count + fields per chart
  - Julia and contract tests cover chart-data route/schema/auth behavior


### BI Realtime Invalidation Slice (2026-04-25)

- Added BI interaction hardening on top of viewer cross-filter work:
  - published viewer now refreshes chart data on realtime `dashboard.published` and `dashboard.outlet.updated` notifications
  - viewer keeps active selection/filter summary visible
  - CSV export respects current filtered viewer state
  - frontend tests still pass for share/workspace viewer flows after interaction changes
- Remaining BI gap: deeper drilldown flows and richer viewer/export polish.


### Object-Store Source Sink Roundtrip Slice (2026-04-25)

- Advanced node-execution gap without new dependencies:
  - tabular ref helpers now resolve `object://` and `warehouse://` refs through local store roots
  - arrow table source now materializes rows from local object-store-backed refs when available
  - arrow table sink now persists materialized rows into local object-store-backed refs when store root metadata exists
  - base extension tests now cover source/sink roundtrip over object-store-style refs
  - fresh verification: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass
- Remaining gap: real Arrow/DataFrames readers/writers for object storage plus broader node scale-up.


### BI Live Render UX Slice (2026-04-24)

- Extended published dashboard viewer beyond metadata-only readout:
  - viewer now renders differentiated previews for line, bar, area, table, and metric charts
  - viewer supports manual chart refresh, auto-polls live snapshots, and cross-filter selection
  - per-chart CSV export action now uses gateway CSV endpoint
  - viewer surfaces semantic dimensions/measures and refresh state per chart
  - frontend tests now cover share-token viewer rendering with chart-data fetches
  - fresh verification: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass
- Remaining BI hardening: cache invalidation beyond polling, viewer cross-filter, and richer drilldown/export UX polish.


### GPU Registry Mock Fallback MVP (2026-04-24)

- Extended GPU lane from queue/promotion only into first executable worker path:
  - worker service now exposes GPU registry summary from env-configured devices
  - GPU compute tick completes mock workload execution and writes result metadata
  - CPU fallback path completes GPU-tagged jobs when no GPU registry devices are available
  - gateway health now reports GPU registry device count and fallback availability
  - execution payload/contracts now expose GPU execution path, selected device, workload, registry, and result metadata
  - Julia and contract tests cover mock workload completion, CPU fallback, and gateway sync of completed GPU jobs
  - fresh verification: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass
- Remaining GPU hardening: real CUDA/KernelAbstractions kernels, device memory ops, and multi-GPU scheduling.


### Streaming Fixture Window Checkpoint MVP (2026-04-24)

- Added first real streaming runtime slice beyond lifecycle/status:
  - worker service can process fixture source events in bounded batches
  - stream metadata now records adapter, processed offsets/rows, batch count, consumer lag, backpressure, watermark, window summaries, and checkpoint offsets
  - gateway checkpoint payload now includes replay offsets, watermark, consumer lag, and checkpoint id from worker metadata
  - execution payloads/contracts expose stream diagnostics with camelCase fields
  - Julia and contract tests cover fixture batch processing, window summaries, checkpoint offsets, and typed diagnostic surfaces
  - fresh verification: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass
- Remaining streaming hardening: Kafka/NATS adapters, durable replay runner, exactly-once proof, production watermarking, and sink transactions.


### BI Semantic Cache Export Slice (2026-04-24)

- Added next BI hardening slice behind artifact-backed chart data:
  - chart-data response now infers dimensions/measures from full row fields instead of fixed x/y hints
  - response includes chart semantic metadata, cache key, source version, snapshot time, refresh mode, live/stale flags, and export formats
  - gateway now exposes authenticated CSV export route for published chart data
  - contracts/OpenAPI/client types cover semantic/cache/export fields and CSV endpoint
  - Julia and contract tests cover semantic ordering, cache metadata, and CSV export body
  - fresh verification: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass
- Remaining BI hardening: live refresh/cache invalidation, drilldown/cross-filter, export UX, and full chart rendering behavior.


### BI Published Artifact Dataset Slice (2026-04-24)

- Replaced deterministic-only chart-data seam with published artifact-backed datasets when BI outlet rows are available:
  - published dashboard records now optionally persist `datasets` keyed by dataset key
  - publish path snapshots rows from matching workflow `bi_outlets` entries
  - chart-data route returns stored dataset rows instead of synthetic fallback rows when present
  - contracts/OpenAPI expose published dashboard datasets and shared dataset-row schema
  - Julia and contract tests cover artifact-backed rows, fields, and dataset persistence
  - fresh verification: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass
- Synthetic chart-data fallback remains for dashboards without published datasets.


### External Ref Tabular Materialization Seam (2026-04-24)

- Added storage-backed materialization seam for external Arrow-shaped refs without adding new dependencies:
  - `TabularPayload.jl` now resolves rows from inline payloads, `NodeContext.metadata["tabular_payload_store"]`, `load_tabular_payload` / `load_tabular_rows` callbacks, `tabular_ref_root`, and local `file://` JSON/JSONL fixtures
  - select/filter/aggregate/trainer and Tier-1 table nodes now use context-aware materialization before falling back to explicit non-materialized warnings
  - tests cover external object-ref store materialization and local file-ref materialization while preserving Arrow IPC output payload shape
  - fresh verification: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass
  - production Arrow/DataFrames object-storage adapters remain pending as the next deeper node-execution slice


### Auth/RBAC Thin Slice (2026-04-24)

- Added first Auth/RBAC contract/gateway slice:
  - contracts now define auth mode, workspace roles, resource permissions, and auth context
  - health payload exposes auth mode and dev-fallback status
  - gateway now supports `JULIAFLOW_AUTH_MODE` and `JULIAFLOW_DEV_AUTH_TOKEN` dev-token mode
  - owner/editor/viewer permissions now gate workflow, execution, checkpoint, dashboard publish, and Hub mutation routes
  - public share-token and workspace dashboard-token paths remain separate from workspace RBAC token gates
  - OpenAPI and contract tests now include auth context/health fields
  - Julia gateway tests cover missing token, viewer read, viewer execute denial, editor execute allow, and editor Hub install denial
  - Fresh verification after docs/code sync: `git diff --check`, base extension tests, full Julia tests, `npm run test`, and `npm run build` all pass

### Auth Semantics + Drift Reconciliation (2026-04-25)

- Hardened gateway error taxonomy for current auth and publish/share routes:
  - invalid auth token now returns `401`
  - invalid share/workspace dashboard token now returns `401`
  - permission denials now return `403`
  - Hub install checkpoint conflict now returns `409`
- Synced realtime protocol doc to include `dashboard.published`
- Reconciled stale onboarding claims:
  - BI publish/share flow marked implemented
  - stream/GPU worker paths marked implemented
  - durable event backbone thin slice marked implemented
  - remaining gaps rewritten around production depth instead of missing shell pieces
- Fresh verification after gateway/protocol/doc sync:
  - `julia --project=. tests/julia/runtests.jl`
  - `node tests/contracts/workflow-schema.test.mjs`
  - `npm run test`
  - `npm run build`

### Audit Event Foundation (2026-04-25)

- Added durable `audit.action` event foundation on current auth path:
  - workflow create/import/update/execute now append audit events
  - Hub register/install actions now append audit events
  - dashboard publish and checkpoint create now append audit events
  - execution status transitions now append audit events
- Contracts and event schema now include `audit.action`
- Added Julia audit-route test coverage and contract-schema verification
- Fresh verification after audit-event slice:
  - `julia --project=. tests/julia/runtests.jl`
  - `node tests/contracts/workflow-schema.test.mjs`
  - `npm run test`
  - `npm run build`

### OMX Explore Tooling Fix (2026-04-24)

- Restored `omx explore` readiness for this machine:
  - installed user-local Rust toolchain / `cargo` via rustup so the packaged explore harness can build/run
  - added `~/.codex/.omx-config.json` override `OMX_EXPLORE_SPARK_MODEL=gpt-5.4-mini` so explore avoids unsupported `gpt-5.3-codex-spark` on the current ChatGPT account
- Verification now passes:
  - `cargo --version` -> `cargo 1.95.0`
  - `omx explore --prompt "smoke: answer exact word OK"` -> `OK`
  - `omx doctor` -> Explore Harness ready; 13 passed, 1 warning, 0 failed
- Remaining tooling warning:
  - `omx doctor` reports legacy `~/.agents/skills` exists beside canonical `~/.codex/skills`; leave in place unless user wants duplicate-skill cleanup


### BRD Endgame Traceability Guard (2026-04-25)

- Analyzed repo against `JuliaFlow_BRD_v1.0.docx`, tracker/checkpoint state, `docs/TODO.md`, `docs/brd-traceability.md`, and current implementation surfaces.
- Created current endgame plan:
  - `.omx/plans/repo-brd-endgame-2026-04-25.md`
- Updated `AGENTS.md` with JuliaFlow end-goal delivery rules:
  - BRD/TODO/traceability/tracker/checkpoint are the end-goal control set
  - current P0 order is production Arrow/DataFrames, BI polish, production OIDC/RBAC, streaming production hardening, GPU production hardening
  - TODO completion must be evidence-gated through BRD traceability
- Added BRD traceability automation:
  - `scripts/validate-brd-traceability.mjs`
  - `tests/contracts/brd-traceability.test.mjs`
  - `npm run validate:brd-traceability`
- Reconciled `docs/brd-traceability.md` so checked P0/P1 TODO items link code/doc evidence and test/verification evidence.
- Reconciled stale auth/GPU trace rows to reflect current audit-event and GPU MVP state.
- Marked BRD traceability automation complete in `docs/TODO.md`.
- Fresh verification:
  - `node scripts/validate-brd-traceability.mjs`
  - `node --test tests/contracts/brd-traceability.test.mjs`
  - `npm run validate:contracts`
  - `npm run validate:brd-traceability`
  - `npm run test`
  - `npm run build`
  - `git diff --check`
  - `julia --project=. extensions/base/test/runtests.jl`
  - `julia --project=. tests/julia/runtests.jl`


### BRD Reanalysis / Next-Step Plan (2026-04-28)

- Re-read current project tracker, checkpoint log, TODO, BRD traceability, and prior BRD plans.
- Confirmed then-current Alpha P0 order (GPU count gate superseded on 2026-05-10):
  1. production Arrow/DataFrames object-storage materialization and node scale-up
  2. deeper BI drilldown/viewer/export polish
  3. production OIDC/JWT/RBAC and persisted policy/audit query surfaces
  4. production streaming adapters/replay/exactly-once hardening
  5. final hardware-gated CUDA/KernelAbstractions and multi-GPU hardening
- Created current execution plan:
  - `.omx/plans/repo-brd-next-steps-2026-04-28.md`
- Noted dirty worktree risk: next implementation must capture `git status --short --branch` before edits and avoid reverting unrelated in-flight changes.


### Production Materialization Adapter Seam (2026-04-28)

- Added configurable production materialization adapter seam for base table refs without adding dependencies:
  - reader callbacks: `tabular_ref_reader`, `arrow_table_reader`, `dataframe_reader`
  - writer callbacks: `tabular_ref_writer`, `arrow_table_writer`, `dataframe_writer`
  - optional adapter label: `tabular_adapter_name` / `tabular_materialization_adapter`
- `ArrowTableSourceNode` now records adapter materialization metadata and propagates schema fields returned by reader callbacks.
- `ArrowTableSinkNode` now prefers configured writer callbacks before local JSON fallback and records persistence adapter metadata.
- Local JSON/JSONL and local object-store-style fallback behavior remains intact.
- Hardened adapter seam after verifier review: writer callbacks returning `nothing` now fall back instead of reporting false persistence, local `append` mode preserves existing rows, and object-store/local-root fallback rejects raw and scheme-based `..` path traversal outside configured roots.
- Added `docs/node-library-roadmap.md` with 25 -> 75 -> 150 -> 300+ node scale plan and stable / adapter-required / experimental quality tiers.
- Fresh verification:
  - `git diff --check`
  - `julia --project=. extensions/base/test/runtests.jl`
  - `julia --project=. tests/julia/runtests.jl`
  - `npm run validate:brd-traceability`
  - `npm run test`
  - `npm run build`


### Base Node Scale 35 Stable Nodes (2026-04-28)

- Advanced base node scale from 25 to 35 stable Tier-1 nodes.
- Added 10 tested cleanup/stat prep nodes:
  - `base.trim_strings`
  - `base.normalize_case`
  - `base.replace_values`
  - `base.regex_extract`
  - `base.validate_schema`
  - `base.top_n_rows`
  - `base.group_filter`
  - `base.rolling_mean`
  - `base.rank_rows`
  - `base.percentile_rows`
- Added output-inspecting extension tests for all 10 nodes.
- Regex node now enforces bounded pattern/input checks and blocks nested quantifier/backreference patterns before counting as stable.
- Updated base extension README, TODO, BRD traceability, and node-library roadmap to reflect 35-node baseline.
- Fresh targeted verification:
  - `julia --project=. extensions/base/test/runtests.jl`


### Base Node Scale 50 Stable Nodes (2026-04-29)

- Advanced base node scale from 35 to 50 stable Tier-1 nodes.
- Added 15 tested math/window/join/reshape nodes:
  - `base.coalesce_columns`
  - `base.clip_values`
  - `base.cumulative_sum`
  - `base.rolling_sum`
  - `base.lag_column`
  - `base.string_contains_filter`
  - `base.column_math`
  - `base.null_if`
  - `base.min_max_scale`
  - `base.z_score`
  - `base.left_join_rows`
  - `base.anti_join_rows`
  - `base.union_distinct_rows`
  - `base.unpivot_rows`
  - `base.pivot_rows`
- Registered and exported the new node types and node keys from the base extension.
- Added output-inspecting extension tests for all 15 nodes.
- Hardened local file materialization: `file://` refs now require `allow_file_refs = true` and configured root confinement; input/output row, column, and ref-byte caps are enforced by metadata limits with defaults.
- Updated base extension README, TODO, BRD traceability, node-library roadmap, and autopilot plan artifacts to reflect 50-node baseline.
- Fresh targeted verification:
  - `julia --project=. extensions/base/test/runtests.jl`



### GitHub Push Prep And Next-Step Plan (2026-04-29)

- Added a post-50-node next-step handoff so future sessions could resume from the baseline; the standalone handoff file was later removed during documentation cleanup.
- Plan included sanity/repo cleanup, GitHub integration checks, production Arrow/DataFrames adapter work, node scale 50 -> 75, BI polish, and production hardening lanes; generated `*.tsbuildinfo` files are ignored and the old UI/UX archive was removed during documentation cleanup.
- GitHub target repository verified with `gh repo view Gravelaw/LowcodeMLtoolkit.jl`; authenticated account has admin permission.
- Existing remote BRD/license documents were merged into local `main` without force-pushing over GitHub history.

## Gaps Pending

### Local-First Active Gap (2026-06-06)

- Local appliance bootstrap, data estate, metadata/database, hardware runtime, and explainability/model evidence are mitigated for current thin slices.
- Active local-first product gap moves to offline Hub proof: bundled/local extension install without external registry dependency, checksum verification, sandbox tests, local artifact cache, and unsafe-extension blocking.
- Broader export/reimport reproducibility bundles remain queued for the academic reproducibility lane; backup/restore integrity remains queued for the backup/restore lane.

### Phase 1 / Alpha Critical Gaps

- Base node pack now has 50 tested Tier-1 nodes with inline, external-ref fixture, local object-store roundtrip materialization, and production reader/writer adapter callbacks, but remains below BRD Phase 1 target (`150 core nodes`) and still needs package-backed Arrow/DataFrames object-storage execution
- GPU path now has registry-aware mock workload execution and CPU fallback, but not real CUDA/KernelAbstractions-backed node execution or multi-GPU scheduling yet
- Streaming path now has lifecycle, worker queue semantics, fixture adapter batches, window summaries, watermarks, lag/backpressure diagnostics, and checkpoint offsets, but not Kafka/NATS adapters, durable replay runner, or exactly-once proof yet
- BI path has draft dashboards, publish snapshots, viewer/share, 5 chart-family contracts, artifact-backed chart datasets, inferred semantic/cache metadata, CSV export, differentiated viewer renderers with live polling, and realtime invalidation beyond polling, but still lacks deeper drilldown and richer export/viewer polish
- Auth/RBAC now has a thin dev-token role/permission gateway slice, but production OIDC/JWT validation, persisted users/workspaces/roles, audit logs, and resource-policy UI are not implemented yet
- Auth route semantics are cleaner now (`401`/`403`/`409` for common current cases), and durable audit events now exist for current mutating control-plane actions, but production OIDC/JWT validation, persisted users/workspaces/roles, audit log query/admin UI, and resource-policy UI are not implemented yet
- Hub has compatibility/trust/upgrade gates, but lacks publish/search/rate workflows, hash-verified package install, sandbox compatibility tests, and private mirror flow
- Components/metanodes and control-flow nodes are not first-class runtime/schema concepts yet
- Observability/performance/deployment remain scaffold-level versus BRD requirements for OTel/Prometheus/Grafana, 1,000-node canvas perf, coverage thresholds, Helm/K8s production paths

### Quality / Delivery Gaps

- Remote CI and checkpoint tags still incomplete for some milestones
- OpenAPI covers REST surfaces, but websocket/realtime transport remains outside REST spec
- `docs/TODO.md` and future `docs/brd-traceability.md` must stay in sync with every new requirement/change

## Next Items To Implement

### Immediate Next Steps (Post 2026-06-06 Slice)

1. Start offline Hub proof with bundled/local extension install, local artifact cache, checksum verification, sandbox tests, and unsafe-extension blocking without external registry dependency.
2. Preserve `npm run smoke:local-explainability` plus prior local-first smokes as regression gates for the appliance path.
3. Keep export/reimport reproducibility and backup/restore integrity queued for their later lanes.

### Next Priority

1. Continue sanity/repo cleanup through the active control docs, then implement package-backed Arrow/DataFrames object-storage adapters on top of the new reader/writer seam and continue node scale 50 -> 75 -> 150
2. Implement deeper BI drilldown and richer viewer/export polish
3. Harden Auth/RBAC with production OIDC/JWT, persisted policy, and audit events
4. Implement production streaming adapters/replay/exactly-once hardening
5. Defer CUDA/multi-GPU hardening to the final hardware-gated GPU phase

### After That

1. Harden Hub publish/install sandbox, artifact hashes, and private mirror
2. Add components/control-flow contracts and validation
3. Add observability/perf/coverage gates
4. Replace ArgoCD/K8s placeholders with real deployable manifests
5. Maintain BRD traceability and TODO evidence links for every milestone

## Working Rule

Before any new job:

- read this tracker
- read latest checkpoint log
- confirm target gap being addressed

After any meaningful job:

- update `Work Done Till Date`
- update `Gaps Pending`
- update `Next Items To Implement`

### Base Node Scale 75 Stable Nodes (2026-04-30)

- Advanced base node scale from 50 to 75 stable Tier-1 nodes without adding dependencies.
- Added 25 tested nodes across date/time prep, grouping/window transforms, joins/enrichment, BI prep, profile/hash, and text cleanup:
  - `base.dedupe_by_key`
  - `base.value_counts`
  - `base.missingness_summary`
  - `base.parse_date`
  - `base.date_bucket`
  - `base.date_parts`
  - `base.split_column`
  - `base.top_n_per_group`
  - `base.weighted_average`
  - `base.group_row_number`
  - `base.moving_min`
  - `base.moving_max`
  - `base.cumulative_count`
  - `base.right_join_rows`
  - `base.full_join_rows`
  - `base.semi_join_rows`
  - `base.lookup_enrich`
  - `base.metric_definition`
  - `base.dimension_mapping`
  - `base.kpi_threshold`
  - `base.chart_dataset`
  - `base.boolean_flag`
  - `base.type_profile`
  - `base.row_hash`
  - `base.normalize_whitespace`
- Registered and exported the new node types and node keys from the base extension.
- Added output-inspecting extension tests for all 25 new nodes.
- Preserved no-new-dependency path because package-backed Arrow/DataFrames adapter dependency approval was not explicit.
- Fresh targeted verification:
  - `julia --project=. extensions/base/test/runtests.jl`

### Updated Gaps Pending (2026-04-30)

- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 75 -> 150 with stable/adapter-required test evidence.
- Deeper BI drilldown/viewer/export polish remains pending.
- Production OIDC/JWT validation, persisted policy/audit query/admin UI, streaming production hardening, GPU production hardening, Hub hardening, observability/perf, and deployment hardening remain pending.

### Updated Next Items To Implement (2026-04-30)

- Implement package-backed or service-backed Arrow/DataFrames object-store adapter when dependency decision is available.
- Continue node scale from 75 -> 150 with stable/adapter-required tested nodes.
- Run full verification after integrated changes: `git diff --check`, extension tests, full Julia tests, `npm run validate:brd-traceability`, `npm run test`, and `npm run build`.


### Materialization Risk Mitigation (2026-04-30)

- Added explicit risk register and mitigation plan for the dependency-choice risk around production Arrow/DataFrames materialization:
  - `.omx/plans/prd-materialization-risk-mitigation-2026-04-30.md`
  - `.omx/plans/test-spec-materialization-risk-mitigation-2026-04-30.md`
  - risk addendum in `.omx/plans/repo-brd-analysis-next-steps-2026-04-30.md`
- Implemented no-new-deps named service-backed adapter registry in `TabularPayload.jl`:
  - registry keys: `tabular_adapter_registry`, `tabular_materialization_adapters`, `tabular_service_adapters`
  - adapter selection: `tabular_adapter_name` / `tabular_materialization_adapter`
  - reader method keys: `reader`, `read`, `read_rows`, `tabular_ref_reader`, `arrow_table_reader`, `dataframe_reader`
  - writer method keys: `writer`, `write`, `write_rows`, `tabular_ref_writer`, `arrow_table_writer`, `dataframe_writer`
  - optional scheme guards: `schemes` / `supported_schemes`
- Added extension tests proving `object://` source materialization and `warehouse://` sink persistence through named service-backed adapters.
- Kept package-backed Arrow/DataFrames TODO unchecked; this mitigates dependency-choice risk but does not overclaim full package-backed production completion.

### Base Node Scale 100 And Arrow/DataFrames Materialization (2026-04-30)

- Advanced base node scale from 75 to 100 stable Tier-1 nodes.
- Added 25 tested nodes across column shaping, string transforms, numeric transforms, grouped aggregates, bucket/encoding helpers, BI metric cards, dashboard summary, and row-to-column summary:
  - `base.drop_columns`
  - `base.keep_columns_matching`
  - `base.copy_column`
  - `base.concat_columns`
  - `base.substring_column`
  - `base.string_length`
  - `base.regex_replace`
  - `base.round_number`
  - `base.absolute_value`
  - `base.log_transform`
  - `base.percent_change`
  - `base.lead_column`
  - `base.cumulative_mean`
  - `base.group_sum`
  - `base.group_mean`
  - `base.group_min`
  - `base.group_max`
  - `base.group_count`
  - `base.group_percent_of_total`
  - `base.bucket_by_thresholds`
  - `base.quantile_bucket`
  - `base.one_hot_encode`
  - `base.metric_cards`
  - `base.dashboard_summary`
  - `base.rows_to_columns`
- Completed the package-backed local Arrow/DataFrames materialization slice:
  - Added `Arrow.jl`, `DataFrames.jl`, and `Tables.jl` to root and base extension projects.
  - Added root-confined `.arrow`, `.feather`, and `.ipc` source reads via `Arrow.Table` + `DataFrame` when `enable_arrow_dataframe_adapter = true`.
  - Added root-confined sink writes via `Arrow.write` + `Tables.columntable` when `enable_arrow_dataframe_adapter = true`.
  - Preserved JSON/JSONL fallback, direct callbacks, and service-backed registry precedence.
- Added extension tests for every new node and package-backed Arrow/DataFrames source/sink roundtrip.

### Updated Gaps Pending (2026-04-30)

- Base node library still needs scale from 100 -> 150 stable/adapter-required nodes for the Phase 1 breadth target.
- Remote/cloud object-storage adapters remain pending; current package-backed path is local-root/object-store-style and root-confined.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Updated Next Items To Implement (2026-04-30)

- Continue node scale from 100 -> 150 with tested stable/adapter-required nodes.
- Add remote/cloud object-store service adapter deployment evidence or cloud package integration for production stores.
- Run full verification after integrated changes: `git diff --check`, extension tests, full Julia tests, `npm run validate:brd-traceability`, `npm run test`, and `npm run build`.

### Base Node Scale 125 Stable Nodes (2026-05-01)

- Advanced base node scale from 100 to 125 stable Tier-1 nodes.
- Added 25 tested nodes across advanced stats, ML scoring/evaluation, streaming prep, and Hub/package helper categories:
  - `base.correlation`
  - `base.covariance`
  - `base.histogram`
  - `base.outlier_flag`
  - `base.standardize_columns`
  - `base.train_test_split`
  - `base.linear_score`
  - `base.classification_threshold`
  - `base.confusion_matrix`
  - `base.regression_metrics`
  - `base.kmeans_assign`
  - `base.pca_project`
  - `base.event_time_assign`
  - `base.watermark_flag`
  - `base.tumbling_window`
  - `base.sliding_window`
  - `base.stream_aggregate`
  - `base.dedupe_event_id`
  - `base.sink_transaction_marker`
  - `base.extension_manifest_validate`
  - `base.compatibility_report`
  - `base.package_hash_verify`
  - `base.object_store_list`
  - `base.dataset_version`
  - `base.schema_drift`
- Registered/exported all new node keys and node types.
- Added output-inspecting extension tests for all 25 new nodes.
- Preserved the remote/cloud object-store gap as open because no provider/credential/dependency decision was supplied.

### Updated Gaps Pending (2026-05-01)

- Base node library still needs scale from 125 -> 150 stable/adapter-required nodes.
- Remote/cloud object-storage adapter integration remains pending beyond the current root-confined local object-store-style path.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Updated Next Items To Implement (2026-05-01)

- Continue node scale from 125 -> 150 with tested stable/adapter-required nodes.
- Add remote/cloud object-store service adapter evidence or cloud package integration once provider/credential decision exists.
- Run full verification after integrated changes: `git diff --check`, extension tests, full Julia tests, `npm run validate:brd-traceability`, `npm run test`, and `npm run build`.

### Remote Adapter And 150 Stable Nodes (2026-05-01)

- Added provider-neutral remote object-store materialization adapter on the central `TabularPayload.jl` seam:
  - enable flag: `enable_remote_object_store_adapter = true`
  - adapter metadata: `remote_object_store_adapter`, `cloud_object_store_adapter`, or `object_store_service_adapter`
  - supported schemes default to `s3://`, `gs://`, `az://`, `https://`, and `http://`
  - remote transfer format: Arrow IPC bytes encoded as base64 in a JSON envelope
  - transport path is mockable for tests and can fall back to HTTP endpoint POST when configured
- Preserved direct callback, named registry, local Arrow/DataFrames, and JSON/JSONL fallback paths.
- Advanced base node scale from 125 to 150 stable Tier-1 nodes.
- Added 25 tested quality, governance, feature engineering, streaming, and GPU-helper nodes:
  - `base.column_presence`
  - `base.null_rate`
  - `base.duplicate_rate`
  - `base.cardinality`
  - `base.column_select_by_type`
  - `base.time_since_previous`
  - `base.sessionize_events`
  - `base.window_lag_delta`
  - `base.rolling_std`
  - `base.expanding_max`
  - `base.cross_join_rows`
  - `base.append_metadata`
  - `base.mask_column`
  - `base.tokenize_column`
  - `base.explode_list`
  - `base.json_extract_field`
  - `base.dataset_lineage`
  - `base.policy_tag`
  - `base.access_decision`
  - `base.gpu_capability_flag`
  - `base.batch_id_assign`
  - `base.replay_offset`
  - `base.exactly_once_key`
  - `base.sink_commit_plan`
  - `base.feature_vector`
- Added output-inspecting tests for all new nodes and remote adapter source/sink paths.

### Updated Gaps Pending (2026-05-01)

- Provider-specific cloud object-store deployments/credentials and production deployment manifests remain pending hardening work.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming adapters, production GPU kernels, Hub hardening, observability/perf, and deployment hardening remain pending.
- 300+ ecosystem breadth remains Beta/GA roadmap work after the 150-node Phase 1 baseline.

### Updated Next Items To Implement (2026-05-01)

- Move to the next P0 BRD lane: BI drilldown/viewer/export polish or production OIDC/RBAC hardening.
- Add provider-specific cloud deployment evidence for remote object-store adapters when target provider/credentials are available.
- Keep full verification loop for every milestone: `git diff --check`, extension tests, full Julia tests, `npm run validate:brd-traceability`, `npm run test`, and `npm run build`.

### BI Drilldown And Export Polish (2026-05-03)

### Work Done Till Date

- Added published dashboard drilldown UX on top of existing chart-data rows.
- Chart datapoint/table/metric interactions now open a read-only selected-row detail panel without mutating dashboard drafts.
- Viewer now exposes filtered CSV export, full CSV export, and selected-row JSON export from the published dashboard surface.
- Share-token published viewer test now covers drilldown, filtered export, and selected-row JSON export.
- Updated TODO and BRD traceability to mark the P0 BI viewer polish follow-up complete with code/test evidence.

### Gaps Pending

- Future BI work can add richer visual renderers, server-side drill paths, scheduled exports, and downloadable files.
- Production OIDC/RBAC, production streaming adapters, production GPU kernels, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Move to next P0 lane: production OIDC/JWT/RBAC hardening or production streaming adapter/replay/exactly-once hardening.
- Keep verified thin-slice delivery with docs, traceability, tests, and checkpoint sync.

### Next P0 Planning: Production OIDC/RBAC Hardening (2026-05-03)

### Work Done Till Date

- Reviewed the post-BI-polish control docs and confirmed the remaining unchecked P0 lanes are production OIDC/RBAC, production streaming, and production GPU hardening.
- Selected production OIDC/JWT/RBAC hardening as the next P0 lane because it reduces the highest cross-cutting security risk before expanding production streaming/GPU surfaces.
- Created a next-P0 OIDC/RBAC hardening plan with decision drivers, alternatives, acceptance criteria, implementation steps, and verification plan; the standalone plan file was later removed during documentation cleanup after its history was preserved here and in the checkpoint log.
- Added `docs/risk-register.md` to make active BRD delivery risks and mitigations explicit.

### Gaps Pending

- Production auth still needs OIDC/JWT validation, persisted users/workspaces/roles, persisted resource policies, bounded/redacted audit query surfaces, and minimal admin/read surfaces.
- Streaming production hardening remains pending for Kafka/NATS adapters, replay runner, exactly-once proof, production watermarking, and sink transactions.
- GPU production hardening remains pending for CUDA/KernelAbstractions kernels, worker isolation, device memory operations, and multi-GPU scheduling.
- Provider-specific object-store deployment evidence, Hub hardening, observability/perf gates, and deployment hardening remain future lanes.

### Next Items To Implement

- Execute the OIDC/RBAC thin-slice plan contract-first: update shared contracts/OpenAPI before gateway and frontend behavior.
- Add a mockable JWT/OIDC validation seam with issuer/audience/expiry checks while preserving disabled/dev-token fallback.
- Add persisted file-backed users/workspaces/roles/resource policies and bounded/redacted audit query APIs with tests.
- Keep TODO/BRD traceability unchecked until code and test evidence exist, then run `npm run validate:brd-traceability` before claiming any milestone.

### OIDC/RBAC First Production-Hardening Slice (2026-05-03)

### Work Done Till Date

- Added OIDC-style JWT auth mode behind `JULIAFLOW_AUTH_MODE=oidc` with HS256 fixture validation for issuer, audience, expiry, not-before, subject, role, workspace, and signature.
- Added persisted auth policy records for role bindings and resource policies in the file repository plus PostgreSQL-ready schema support.
- Added policy read/update and bounded redacted audit action query routes with OpenAPI and TypeScript contract coverage.
- Added Julia gateway tests for missing/invalid OIDC tokens, persisted role binding override, resource-policy enforcement, audit query, redaction, and file persistence.

### Gaps Pending

- Live-provider JWKS/RSA validation or selected IdP adapter remains pending before full production OIDC can be claimed.
- Persisted users/workspaces admin model and resource-policy admin UI remain pending.
- Broader security review, frontend admin UX tests, and PostgreSQL-backed auth policy evidence remain pending.
- Streaming and GPU production hardening remain queued after the security lane.

### Next Items To Implement

- Add selected-provider JWKS/RSA validation or a documented IdP adapter seam with key-rotation tests.
- Add minimal persisted users/workspaces/admin UI surface for role and resource-policy management.
- Keep P0 item 11 unchecked until live-provider validation and admin UI/resource-policy management evidence exist.

### OIDC Discovery/JWKS Rotation Hardening (2026-05-03)

### Work Done Till Date

- Extended OIDC auth from env-secret HS256 validation to discovery/JWKS source resolution via `JULIAFLOW_OIDC_DISCOVERY_PATH`/`URL` and `JULIAFLOW_OIDC_JWKS_PATH`/`URL`.
- Added `kid`-based JWKS key lookup for `oct`/HS256 keys, constant-time signature comparison, allowed-algorithm gating, and healthcheck metadata for OIDC discovery/JWKS configuration.
- Added Julia rotation tests proving old JWKS keys fail after rotation and new keys pass.
- Updated README/onboarding docs and contract/OpenAPI health/config surfaces.

### Gaps Pending

- RSA/live IdP validation remains pending because no provider/dependency choice is configured yet.
- Persisted users/workspaces admin model and resource-policy/audit admin UI remain pending.
- PostgreSQL-backed auth policy runtime evidence and broader security review remain pending.

### Next Items To Implement

- Add selected-provider RSA/JWKS validation or a documented IdP adapter with provider metadata/key-rotation fixtures.
- Add admin UI for users/workspaces/role bindings/resource policies and audit query browsing.
- Keep P0 auth TODO unchecked until live-provider and admin UI evidence exists.

### Security Admin Policy/Audit Visibility (2026-05-04)

### Work Done Till Date

- Added read-only Settings security admin panel for auth mode, OIDC discovery/JWKS configuration, allowed algorithms, persisted role bindings, resource policies, and redacted audit actions.
- Loaded policy and audit query APIs as optional gateway calls so unauthenticated/local shells do not fall back when admin routes are unavailable.
- Extended frontend gateway mock coverage for policy/audit data and Settings assertions.

### Gaps Pending

- RSA/live IdP validation remains pending.
- Editable persisted users/workspaces/resource-policy admin UX remains pending.
- PostgreSQL-backed auth policy runtime evidence and broader security review remain pending.

### Next Items To Implement

- Add editable admin UX for users/workspaces/role bindings/resource policies with validation and tests.
- Add RSA/live IdP adapter or provider fixture once dependency/provider choice is clear.
- Keep P0 auth TODO unchecked until live-provider and editable admin evidence exists.


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

### Repo BRD Reanalysis And Pending Implementation Plan (2026-05-05)

### Work Done Till Date

- Re-read current control docs, latest `.omx` plans/context/reviews/state, and implementation markers against `JuliaFlow_BRD_v1.0.docx`.
- Confirmed current `main` is clean against `origin/main` during analysis.
- Confirmed completed P0 evidence remains: production Arrow/DataFrames materialization + provider-neutral remote object-store adapter, 150 base nodes, BI drilldown/export polish, auth thin/admin policy slices, streaming fixture MVP, and GPU mock-worker MVP.
- Created `.omx/plans/repo-brd-pending-implementation-plan-2026-05-05.md` as the active pending-work plan.

### Gaps Pending

- P0 auth remains open: RSA/live IdP validation, persisted users/workspaces directory UI/model, PostgreSQL auth-policy runtime evidence, and broader security review.
- P0 streaming remains open: Kafka/NATS adapters, durable replay runner, exactly-once proof, production watermarking, and sink transactions.
- Final hardware-gated GPU item remains open: real CUDA/KernelAbstractions kernels, device memory operations, worker isolation guarantees, and multi-GPU scheduling.
- P1/P2 remain: Hub publish/install hardening, components/control-flow contracts, observability/perf gates, and deployment hardening.

### Next Items To Implement

- Start Stage 1 of `.omx/plans/repo-brd-pending-implementation-plan-2026-05-05.md`: persisted users/workspaces directory admin model, PostgreSQL runtime evidence, RSA/live IdP dependency decision, and security review.
- Keep `docs/TODO.md` P0 item 11 unchecked until all code/test/review evidence is linked in `docs/brd-traceability.md` and `npm run validate:brd-traceability` passes.

### Auth Directory Admin Slice (2026-05-05)

### Work Done Till Date

- Added persisted user/workspace directory model and API for the auth admin lane.
- Added file-backed and PostgreSQL-ready repository support for `auth-directory.json` / `auth_directory`.
- Added `GET/PUT /api/v1/admin/auth/directory` behind policy permissions plus `auth.directory.changed` durable events and `auth.directory.update` audit actions.
- Settings now loads and edits directory users/workspaces alongside role/resource policies.
- Added frontend, contract, Julia route, and repository coverage for directory reads, writes, policy-reference validation, active directory runtime enforcement, and directory self-lockout prevention.

### Gaps Pending

- RSA/live IdP validation remains pending.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Broader security review remains pending before checking P0 auth complete.
- Streaming and GPU production hardening remain queued after auth/security depth.

### Next Items To Implement

- Run full verification and code review for this auth-directory slice.
- Add dependency-expert/security-reviewed RSA/live IdP path or documented adapter fixture.
- Add PostgreSQL runtime evidence when DB credentials/service are available.
- Keep P0 auth TODO unchecked until live-provider, PostgreSQL runtime, and security-review evidence exist.

### Auth Directory Admin Verification And Review (2026-05-06)

### Work Done Till Date

- Completed local code review after native review subagents hit usage limits.
- Added active directory runtime enforcement for authenticated OIDC/dev-token contexts when directory records exist.
- Added directory self-lockout prevention so a directory update cannot remove/disable the caller principal or workspace when those sets are present.
- Re-ran full frontend, Julia, contract, build, traceability, and whitespace verification.
- Stored review artifact at `.omx/reviews/code-review-p0-auth-directory-admin-2026-05-06.md`.

### Gaps Pending

- RSA/live IdP validation remains pending.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Broader security review remains pending before checking P0 auth complete.
- Streaming and GPU production hardening remain queued after auth/security depth.

### Next Items To Implement

- Decide/implement RSA/JWKS live-provider validation path with security/dependency review.
- Run PostgreSQL auth directory/policy evidence when DB credentials/service are available.
- Keep P0 auth TODO unchecked until live-provider, PostgreSQL runtime, and security-review evidence exist.

### RS256 OIDC/JWKS Validation Slice (2026-05-06)

### Work Done Till Date

- Added no-new-dependency RS256 JWT verification against OIDC discovery/JWKS metadata.
- Implemented RSA JWK (`kty=RSA`, `n`, `e`, `kid`) lookup, BigInt RSA public verification, and PKCS#1 v1.5 SHA-256 digest validation in the gateway.
- Preserved existing HS256 JWKS rotation and dev-token/share-token/workspace-token behavior.
- Added Julia tests for valid RS256 JWKS token acceptance and tampered RS256 signature rejection.
- Created autopilot planning artifacts `.omx/plans/prd-p0-auth-rs256-live-idp-2026-05-06.md` and `.omx/plans/test-spec-p0-auth-rs256-live-idp-2026-05-06.md`.

### Gaps Pending

- External live-IdP smoke remains pending because no provider credentials/metadata target were supplied.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Broader security review remains pending before checking P0 auth complete.
- Streaming and GPU production hardening remain queued after auth/security depth.

### Next Items To Implement

- Run full verification and code review for the RS256 slice.
- Add external IdP smoke evidence when provider/credentials are available.
- Run PostgreSQL auth directory/policy evidence when DB credentials/service are available.
- Keep P0 auth TODO unchecked until live-provider, PostgreSQL runtime, and security-review evidence exist.

### RS256 OIDC/JWKS Verification And Review (2026-05-06)

### Work Done Till Date

- Completed local code review for the RS256 OIDC/JWKS validation slice.
- Added review-driven hardening: RSA modulus must be at least 2048 bits.
- Re-ran full frontend, Julia, contract, build, traceability, and whitespace verification.
- Stored review artifact at `.omx/reviews/code-review-p0-auth-rs256-live-idp-2026-05-06.md`.

### Gaps Pending

- External live-IdP smoke remains pending because no provider credentials/metadata target were supplied.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Broader security review remains pending before checking P0 auth complete.
- Streaming and GPU production hardening remain queued after auth/security depth.

### Next Items To Implement

- Run PostgreSQL auth directory/policy evidence when DB credentials/service are available.
- Add external IdP smoke evidence when provider/credentials are available.
- Run broader auth security review before marking P0 auth complete.
- If auth evidence remains credential-blocked, proceed to next P0 lane: streaming production hardening.

### Auth Security Review (2026-05-06)

### Work Done Till Date

- Completed broader local auth/RBAC security review after the directory admin and RS256 JWKS slices.
- Documented review artifact at `docs/security/auth-security-review-2026-05-06.md`.
- Found no critical, high, or medium findings.
- Recorded remaining watch items as external live-IdP smoke and PostgreSQL runtime evidence.

### Gaps Pending

- External live-IdP smoke remains pending because no provider credentials/metadata target were supplied.
- PostgreSQL runtime evidence remains pending until `JULIAFLOW_TEST_POSTGRES_URL` is available and run.
- Streaming and GPU production hardening remain queued after auth/security depth.

### Next Items To Implement

- Run PostgreSQL auth directory/policy evidence when DB credentials/service are available.
- Add external IdP smoke evidence when provider/credentials are available.
- If auth evidence remains credential-blocked, proceed to next P0 lane: streaming production hardening.

### Streaming Exactly-Once Fixture Slice (2026-05-06)

### Work Done Till Date

- Started the next P0 lane after auth evidence became credential-blocked.
- Added committed-offset metadata, sink transaction IDs, and idempotency keys to streaming fixture batch processing.
- Added duplicate replay suppression via `replay_stream_fixture_batch!` so replays below the committed offset do not double-count processed rows.
- Exposed exactly-once/replay metadata in gateway execution payloads, TypeScript contracts, and OpenAPI.
- Added Julia worker coverage and contract assertions for the new streaming metadata.

### Gaps Pending

- Kafka/NATS adapters remain pending.
- Durable replay runner across process restarts remains pending beyond fixture duplicate suppression.
- Production watermarking and external sink transactions remain pending.
- GPU production hardening remains queued after streaming depth.

### Next Items To Implement

- Add Kafka/NATS adapter contract fixtures without introducing runtime dependencies.
- Add durable replay runner evidence across restart using persisted checkpoint offsets.
- Add production watermark and external sink transaction tests before checking P0 streaming complete.

### Streaming Adapter Contract Slice (2026-05-06)

### Work Done Till Date

- Added Kafka/NATS adapter contract metadata without adding runtime broker dependencies.
- Captured replay mode, delivery semantics, watermark mode, Kafka topic/group/bootstrap fields, and NATS subject/durable/server fields in stream execution metadata.
- Exposed adapter contract metadata through gateway payloads, TypeScript contracts, and OpenAPI.
- Added Julia worker tests for Kafka and NATS adapter contract metadata plus contract schema assertions.

### Gaps Pending

- Runtime Kafka/NATS clients remain pending until dependency/provider approval.
- Durable replay runner across process restarts remains pending beyond fixture duplicate suppression.
- Production watermarking and external sink transactions remain pending.
- GPU production hardening remains queued after streaming depth.

### Next Items To Implement

- Add durable replay runner evidence across restart using persisted checkpoint offsets.
- Add runtime Kafka/NATS clients after dependency/provider decision.
- Add production watermark and external sink transaction tests before checking P0 streaming complete.

### Streaming Restart Replay Slice (2026-05-07)

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

### Streaming Watermark Transaction State Slice (2026-05-07)

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

### GPU Production-Hardening Prep Slice (2026-05-07)

### Work Done Till Date

- Started the next unblocked P0 GPU lane after streaming runtime dependencies remained provider/dependency-gated.
- Extended existing GPU dispatch/worker metadata with scheduler policy, placement reason, requested device, worker capacity, selected device, fallback reason, and worker isolation state.
- Added deterministic multi-device placement for the no-new-dependency worker path: requested device matches are honored, no-request placement uses sorted device IDs, invalid requests select a deterministic GPU fallback with explicit reason, and empty registries retain CPU fallback.
- Updated TypeScript contracts, OpenAPI, gateway execution payload mapping, and Julia coverage for multi-device placement and fallback metadata.

### Gaps Pending

- Real CUDA/KernelAbstractions kernels and device-memory operations remain pending until dependency and hardware/CI approval.
- Runtime multi-GPU isolation guarantees remain simulated metadata, not production hardware evidence.
- Final hardware-gated GPU item remains unchecked until real kernel/device-memory evidence exists.

### Next Items To Implement

- Run full JS/build/traceability/diff verification for this prep slice.
- Decide CUDA/KernelAbstractions dependency and hardware/CI gate before implementing real GPU kernels.
- Add optional bounded GPU worker smoke evidence with `JULIAFLOW_WORKER_ONCE=1 julia --project=. scripts/run-gpu-worker.jl` when local state makes it useful.

### BRD Reanalysis And Next-Step Plan (2026-05-07)

### Work Done Till Date

- Re-read tracker, checkpoint, TODO, traceability, risk register, architecture/onboarding docs, BRD docx excerpts, and current implementation seams.
- Saved current repo-vs-BRD next-step plan at `.omx/plans/repo-brd-next-steps-2026-05-07.md`.
- Verified BRD traceability validator and whitespace diff check pass during planning.

### Gaps Pending

- Current GPU production-hardening prep slice is still uncommitted and needs full Julia/JS/build verification before new feature scope.
- Auth live-IdP/PostgreSQL evidence, streaming live broker/sink evidence, and real CUDA/KernelAbstractions evidence remain open.

### Next Items To Implement

- Finish verification and review for the existing GPU prep slice.
- If CUDA/KernelAbstractions dependency/hardware gate is approved, add a small real GPU kernel smoke path behind explicit gates.
- If GPU/runtime dependencies remain blocked, move to unblocked P1 Hub publish/install hardening.

### GPU Production-Hardening Prep Verification (2026-05-08)

### Work Done Till Date

- Completed full verification for the current no-new-dependency GPU production-hardening prep slice.
- Verified Julia, JS, build, BRD traceability, whitespace, and bounded GPU worker smoke evidence.
- Confirmed the slice remains honest: it improves deterministic placement/dispatch metadata but does not claim real CUDA/KernelAbstractions execution.

### Gaps Pending

- Real CUDA/KernelAbstractions kernels, device-memory operations, hardware-backed isolation, and multi-GPU scheduling evidence remain pending.
- Auth live-IdP/PostgreSQL and streaming live broker/sink evidence remain credential/provider/dependency-gated.

### Next Items To Implement

- Proceed to code review for the verified GPU prep diff.
- If review is clean and GPU dependencies/hardware are approved, plan/implement a gated real GPU kernel smoke.
- If GPU gate remains blocked, pivot to unblocked P1 Hub publish/install hardening.

### GPU Prep Review Fixes (2026-05-08)

### Work Done Till Date

- Addressed code-review findings for GPU requested-device alias drift and stale tracker timestamp.
- Added canonical matching for existing GPU request formats such as `nvidia:1`, `cuda:1`, `nvidia1`, and `cuda:nvidia1`.
- Added explicit CPU fallback, placement fallback, and request-satisfied metadata to reduce observability ambiguity.
- Added regression coverage for flow-variable dispatch override and `nvidia:1` alias placement.

### Gaps Pending

- Real CUDA/KernelAbstractions kernels, device-memory operations, hardware-backed isolation, and multi-GPU scheduling evidence remain pending.
- Contract capacity objects are still intentionally loose until real GPU backend shape is known.

### Next Items To Implement

- Rerun Julia/JS/build/traceability/diff verification after review fixes.
- Rerun code review and require `APPROVE` plus architecture `CLEAR` before completing autopilot.
- If clean, choose next lane: gated CUDA/KernelAbstractions smoke when approved, otherwise P1 Hub publish/install hardening.

### GPU Prep Review Fix Verification (2026-05-08)

### Work Done Till Date

- Reran full verification after review fixes.
- Evidence passed: Julia suite, npm test, npm build, BRD traceability validator, diff whitespace check, and bounded GPU worker smoke.

### Gaps Pending

- Real CUDA/KernelAbstractions kernel/device-memory evidence remains pending before final GPU production closure.
- Final code-review rerun is still required before autopilot can close clean.

### Next Items To Implement

- Rerun code review on the fixed diff.
- If clean, mark autopilot complete and leave final GPU production closure open for real-compute evidence.
- If review finds remaining issues, return to planning with findings.

### GPU Prep Autopilot Completion (2026-05-08)

### Work Done Till Date

- Completed autopilot loop for GPU production-hardening prep stabilization.
- Code review rerun returned `APPROVE` with zero issues; architecture rerun returned `CLEAR`.
- Final slice now includes deterministic GPU request alias matching, flow-variable dispatch override alignment, explicit CPU/placement fallback metadata, contracts/OpenAPI mapping, tests, and synced control docs.

### Gaps Pending

- Final hardware-gated GPU item remains open for real CUDA/KernelAbstractions kernel, device-memory, hardware-backed isolation, and multi-GPU scheduling evidence.
- Auth live-IdP/PostgreSQL and streaming live broker/sink evidence remain provider/dependency-gated.

### Next Items To Implement

- If CUDA/KernelAbstractions dependency and hardware gate is approved, implement a small gated real GPU kernel smoke.
- Otherwise proceed to unblocked P1 Hub publish/install hardening.
- Keep running BRD traceability validation whenever TODO/traceability state changes.

---

## Update: Hub Publish/Install Hardening — 2026-05-09

### Work Done Till Date

- Closed P1 Hub publish/install hardening for Alpha metadata depth.
- Added Hub manifest artifact hashes, compatibility sandbox command metadata, and private/offline mirror refs across TS contracts, OpenAPI, Julia gateway/repository persistence, and frontend Hub UI.
- Added partner trust/compatibility blockers for missing/invalid SHA-256-shaped artifact hashes, missing sandbox command, and invalid mirror schemes.
- Added frontend publish sample UX for a private mirror extension and gateway registration roundtrip coverage.

### Gaps Pending

- Future Hub production depth still needs actual sandbox command execution, downloaded artifact hash verification, real private registry mirror smoke, and marketplace rating/search/governance workflows.
- External/provider gates remain: live IdP/PostgreSQL evidence, Kafka/NATS/live sink evidence, and real CUDA/KernelAbstractions hardware evidence.

### Next Items To Implement

- If no external providers/hardware are approved, proceed to P1 components/control-flow contracts or observability/perf gates.
- If approval arrives, prioritize real CUDA/KernelAbstractions smoke or live provider evidence for the remaining external/final hardware gates.

### Hub Hardening Review Fix Completion (2026-05-09)

### Work Done Till Date

- Review follow-up completed for Hub publish/install hardening.
- Hardened lifecycle gates, all-publisher artifact hash enforcement, manifest shape handling, local-file mirror rejection, and enabled-extension disable parity.
- Verification passed after fixes: `npm run test`, `julia --project=. tests/julia/runtests.jl`, `npm run build`, `npm run validate:brd-traceability`, and `git diff --check`.

### Gaps Pending

- Hub still needs future production-depth sandbox execution and artifact download verification.
- Remaining P0 gates require external providers/hardware.

### Next Items To Implement

- Commit Hub hardening slice.
- Proceed to P1 components/control-flow contracts or observability/perf gates if no external gate opens.

### Remaining P0 Live-Evidence Harness Slice (2026-05-09)

### Work Done Till Date

- Added gated live-evidence harnesses for the three still-open P0 lanes without marking TODO completion:
  - `scripts/smoke-keycloak-postgres-auth.sh` provisions Keycloak/PostgreSQL from dev Compose, obtains a real RS256 bearer token, starts the gateway on PostgreSQL, exercises protected auth directory/policy/audit routes, and emits JSON evidence.
  - `scripts/smoke-kafka-streaming.sh` produces/consumes real Kafka messages through the dev Compose broker, captures them as JSONL evidence, and drives the Julia stream replay/sink idempotency path.
  - `scripts/smoke-cuda-kernel.jl` runs a gated CUDA + KernelAbstractions vector kernel and can require multi-GPU evidence with `JULIAFLOW_REQUIRE_MULTI_GPU=1`.
- Added CUDA and KernelAbstractions as explicit Julia dependencies for the gated GPU real-compute path.
- Added a worker-service Kafka JSONL adapter seam plus file-backed fenced sink idempotency state so captured live broker messages can be replayed from committed offsets without duplicate sink writes.
- Added Julia regression coverage for Kafka adapter replay/restart flow and duplicate sink suppression using local JSONL evidence.

### Gaps Pending

- P0 items 11, 13, and 15 remain unchecked until live smokes pass and evidence is linked in `docs/brd-traceability.md`.
- Current host has one visible NVIDIA GPU, so final GPU multi-GPU scheduling evidence still needs a host/CI runner with at least two visible CUDA devices.
- Keycloak/PostgreSQL and Kafka live smokes require local Docker services to be running and healthy.

### Next Items To Implement

- Run `scripts/smoke-keycloak-postgres-auth.sh` and capture pass output before closing auth P0.
- Run `scripts/smoke-kafka-streaming.sh` and capture pass output before closing streaming P0.
- Run `JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1 julia --project=. scripts/smoke-cuda-kernel.jl` on a two-GPU CUDA host before final GPU production closure.
- If any live smoke fails, fix the concrete blocker and keep TODO P0 items open.

### Auth And Streaming P0 Live Evidence Closure (2026-05-09)

### Work Done Till Date

- Ran and passed `./scripts/smoke-keycloak-postgres-auth.sh` against local Compose Keycloak + PostgreSQL.
  - Evidence: real Keycloak RS256 token, PostgreSQL-backed gateway, protected workflow route, auth directory save/load, auth policy save/load, and redacted audit query with `auth.policy.update`.
- Ran and passed `./scripts/smoke-kafka-streaming.sh` against local Compose Kafka.
  - Evidence: live Kafka produce/consume, committed-offset replay after worker restart, duplicate replay suppression, and 3-row fenced file-sink output.
- Updated TODO and BRD traceability to close P0 auth/RBAC item 11 and P0 streaming item 13 with linked code/test/smoke evidence.

### Gaps Pending

- Final hardware-gated GPU item remains open: single-GPU CUDA/KernelAbstractions smoke passes, but full closure requires >=2 visible CUDA devices for multi-GPU scheduling evidence.
- Provider-specific external IdP, managed PostgreSQL, managed Kafka/NATS, and cloud sink deployments should repeat these smokes before production rollout.

### Next Items To Implement

- Obtain/run a >=2 CUDA device host or CI runner and execute `JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1 julia --project=. scripts/smoke-cuda-kernel.jl`.
- If multi-GPU evidence passes, update GPU TODO/traceability and rerun final gates.
- Otherwise keep final GPU production closure open and proceed only with non-GPU-unblocked work.

### GPU Hardware Constraint Rephase — 2026-05-10

### Work Done Till Date

- Reclassified GPU production hardening / multi-GPU closure from near-term P0 into a Final Hardware-Gated Phase because full closure depends on >=2 visible CUDA devices.
- Kept auth/RBAC and Kafka streaming local-platform P0 closures intact.
- Preserved one-device CUDA/KernelAbstractions smoke as useful evidence, but documented it as insufficient for final multi-GPU scheduling and hardware isolation closure.
- Updated TODO, BRD traceability, risk register, README, onboarding, tracker, and checkpoint wording to reflect the new ordering.

### Gaps Pending

- Final GPU production closure still needs a host/CI runner with >=2 visible CUDA devices.
- Required final evidence remains: `JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1 julia --project=. scripts/smoke-cuda-kernel.jl`, hardware-backed worker isolation proof, and multi-GPU scheduling evidence linked in traceability.
- Provider-specific auth, PostgreSQL, Kafka/NATS, sink, and object-store deployments should still repeat local smokes before production rollout.

### Next Items To Implement

- Continue unblocked P1/P2 lanes: components/control-flow contracts, observability/perf gates, deployment hardening, or provider-specific object-store proof.
- Return to final GPU closure only when >=2-device CUDA hardware/CI is available.
- After any future GPU closure change, update TODO/traceability and rerun `npm run validate:brd-traceability` plus relevant Julia/worker smokes.

### P0 Closure Verification And Commit Prep — 2026-05-10

### Work Done Till Date

- Verified `docs/TODO.md` P0 section has 14/14 checked items after moving GPU multi-GPU closure to the Final Hardware-Gated Phase.
- Re-ran local-platform P0 evidence smokes:
  - `./scripts/smoke-keycloak-postgres-auth.sh` passed with Keycloak RS256, PostgreSQL repository backend, protected route access, policy/directory persistence, and audit evidence.
  - `./scripts/smoke-kafka-streaming.sh` passed with live Kafka consume, committed offset 3, duplicate replay suppression, and 3-row fenced sink output.
- Re-ran final gates: Julia suite, npm tests, npm build, BRD traceability validator, diff whitespace check, bounded GPU worker smoke, and one-device CUDA/KernelAbstractions smoke.

### Gaps Pending

- No near-term P0 TODO item remains unchecked.
- Final Hardware-Gated Phase GPU closure remains pending until >=2 visible CUDA devices are available for multi-GPU scheduling and hardware isolation evidence.
- Provider-specific production deployment smokes still need repeat evidence on selected external providers.

### Next Items To Implement

- Commit the verified P0 closure/live-evidence slice.
- Continue unblocked P1/P2 work unless a >=2-device CUDA runner becomes available.
- Repeat provider-specific auth/streaming/object-store smokes before production rollout.

### Components/Control-Flow Contract Slice — 2026-05-12

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

### Observability/Perf First Gate Slice — 2026-05-12

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


### P2 Deployment Hardening — 2026-05-14

### Work Done Till Date

- Replaced ArgoCD placeholder workload intent ConfigMaps with Kustomize bases and dev overlays for API Gateway, Execution Service, Frontend, and provider-neutral platform dependency seams.
- API Gateway now has Deployment, Service, runtime ConfigMap, optional secret-ref template, dev Ingress, `/health` probes, `/metrics` scrape annotations, and deployable dev defaults using file-backed storage plus required dev-token auth so empty provider secrets do not grant owner fallback access.
- Execution Service now has Deployment, internal Service, runtime ConfigMap, checkpoint/object-store/broker secret-ref template, and `scripts/run-execution-service.jl` exposing real `/health` and `/metrics` endpoints on port 8090.
- Frontend now has Deployment, Service, dev Ingress, a mounted `juliaflow-config.js` runtime ConfigMap, and app code that reads runtime gateway config before Vite build-time fallback.
- Platform dependency base now keeps the namespace and declares stable service/secret contracts for PostgreSQL, Redis, Kafka, object storage, and Keycloak/OIDC without committing fake production StatefulSets or real credentials.
- Added `npm run validate:k8s` via `scripts/validate-k8s-manifests.sh`; it renders with `kubectl kustomize` or `kustomize build` when available, otherwise performs structural YAML, Kustomize reference, AppProject app-of-apps policy, and placeholder checks.

### Gaps Pending

- Provider-specific production overlays remain future work for selected managed PostgreSQL, Redis, Kafka/NATS, object storage, and OIDC/Keycloak providers.
- Live cluster proof (`kubectl apply --dry-run=server -k ...`) is pending because this host has no configured `kubectl`/cluster; local validation covers structural YAML and ArgoCD policy only.
- Final hardware-gated GPU closure remains blocked on >=2 visible CUDA devices.

### Next Items To Implement

- Add staging/prod provider overlays after provider choices and secret delivery mechanism are selected.
- Repeat auth, streaming, object-store, and gateway smoke tests against the target provider/cluster before GA deployment claims.
- Keep P2 manifests in CI via `npm run validate:k8s` plus existing `npm run test`, `npm run build`, and BRD traceability gates.

### Agent Guidance / Future Module Skill Routing — 2026-05-14

### Work Done Till Date

- Updated `AGENTS.md` with a concise required skill-routing map for future JuliaFlow modules.
- Added repo-local skills for BRD control-loop work, Julia development, frontend development, and provider deployment hardening under `.codex/skills/`.
- Reaffirmed NASA/JPL Power of 10 as mandatory for all core JuliaFlow logic and preserved subagent/parallel-lane guidance for independent bounded work.

### Gaps Pending

- Future provider-specific deployment overlays still need live cluster proof and selected secret delivery integration.
- Future frontend-heavy slices should use the new frontend skill plus visual/design/test skills and keep test coverage current.
- Future Julia-heavy slices should use the Julia skill with official docs/syntax validation and Julia test evidence.

### Next Items To Implement

- Use `juliaflow-control-loop` before the next roadmap module implementation.
- Use `juliaflow-provider-deployment` for selected-provider overlays or object-store deployment proof.
- Use `juliaflow-frontend-development` for the next substantial canvas/BI/Hub frontend pass.

### Current Phase Plan Sync — 2026-05-14

### Work Done Till Date

- Created `Plan.md` as the current plan for the Provider-Specific GA Proof / Module Expansion phase.
- Updated `docs/TODO.md` to point at `Plan.md` and added open current-phase items for provider deployment proof, provider object-store proof, frontend expansion, Julia runtime expansion, and governed Hub production depth.
- Updated `docs/risk-register.md` with current-phase focus plus frontend-scale and Julia-runtime-depth risks.

### Gaps Pending

- Provider/live-cluster evidence remains pending: selected overlays, secret delivery, server-side dry-run, and provider smokes.
- Frontend and Julia runtime expansion remain open module lanes and need evidence per slice.
- Final multi-GPU hardware closure remains blocked until >=2 visible CUDA devices exist.

### Next Items To Implement

- Start provider-specific deployment proof or object-store proof when provider/cluster/credential target exists.
- Otherwise select the next frontend or Julia runtime module slice and run through the relevant repo-local skill and test gates.
- Keep `Plan.md`, TODO, risks, tracker, checkpoint, and traceability synchronized after each phase change.

### Control-Doc Sync Guard — 2026-05-14

### Work Done Till Date

- Added `scripts/validate-control-doc-sync.mjs` and `npm run validate:control-doc-sync`.
- Updated `AGENTS.md` and `juliaflow-control-loop` so every completed slice, phase, or review must update `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md`.
- Updated `Plan.md`, TODO, and risk register to reflect the new guard.
- Verified the guard with `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, `node --test tests/contracts/brd-traceability.test.mjs`, `npm run test`, `npm run build`, and `git diff --check`.

### Gaps Pending

- The guard enforces changed-file coverage, not semantic correctness; agents still must write accurate evidence and not rubber-stamp docs.
- CI should include `npm run validate:control-doc-sync` in future release gates.

### Next Items To Implement

- Run `npm run validate:control-doc-sync` before every completion claim or commit that changes non-control files.
- Pair it with `npm run validate:brd-traceability` when TODO or traceability changes.
- Keep using repo-local skills to decide which docs need semantic updates.


### Frontend Module Expansion / BI Viewer Row-Search Slice — 2026-05-15

### Work Done Till Date

- Selected the unblocked frontend module expansion lane because provider-specific GA proof still needs external provider/cluster/credential context.
- Added published-dashboard viewer row search that applies after existing chart cross-filters.
- Added clear row-search controls, row-search status, search-aware chart row counts, and filtered CSV export that respects both active chart filter and row search.
- Added frontend regression coverage for share-token viewer search and search-aware CSV export.

### Gaps Pending

- Provider-specific deployment proof and provider object-store proof still need selected external targets and credentials.
- Julia runtime module expansion remains open for loop/try-catch execution semantics.
- Governed Hub production depth remains open for sandbox execution and artifact hash verification.
- Final GPU closure remains blocked until >=2 visible CUDA devices are available.

### Next Items To Implement

- Run full frontend/build/control-doc verification for this BI viewer slice.
- Then continue the next implementable lane: Julia runtime module expansion or another frontend/Hub slice if runtime scope is deferred.
- Keep provider-specific proof queued until a cluster/provider/secret-delivery target exists.


### Julia Runtime Module Expansion / Loop Runtime-Plan Slice — 2026-05-15

### Work Done Till Date

- Implemented the first Julia runtime module expansion slice for loop control-flow planning.
- Loop metadata now validates that `start_node_id` can reach `end_node_id` in the workflow DAG and rejects unreachable loop bodies.
- Execution records now emit additive `control_flow_plan` / `controlFlowPlan` evidence with loop id, iteration mode, max iterations, start/end nodes, bounded flag, and body node ids.
- Gateway persistence/payload mapping, TS/OpenAPI contracts, Monitor UI rendering, fixture coverage, Julia tests, and frontend/contract tests are aligned.

### Gaps Pending

- Try/catch runtime execution semantics remain open as the next Julia runtime follow-up.
- Provider-specific deployment/object-store proof still lacks live provider, cluster, and credential context.
- Governed Hub production depth remains open for sandbox execution and artifact hash verification.
- Final GPU closure remains blocked until >=2 visible CUDA devices are available.

### Next Items To Implement

- Run full verification: Julia suite, npm test/build, control-doc sync, BRD traceability, and diff check.
- Next repo-local implementation lane should be try/catch runtime semantics unless provider access appears first.
- Keep loop planning additive until node-level compute execution semantics are deliberately expanded.

### Julia Runtime Module Expansion / Try-Catch Runtime-Plan Slice — 2026-05-16

### Work Done Till Date

- Implemented the next Julia runtime module expansion slice for try/catch control-flow planning.
- Try/catch metadata now emits additive `controlFlowPlan` evidence with ordered try and catch node IDs.
- Gateway persistence/payload mapping, TS/OpenAPI contracts, Monitor UI rendering, foundation fixture coverage, Julia tests, frontend tests, contract tests, and traceability docs are aligned.

### Gaps Pending

- Failure-driven node execution semantics remain open; this slice does not catch runtime node failures or branch executor state.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credential context.
- Governed Hub sandbox/hash verification remains pending.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Run full verification: Julia suite, npm test/build, coverage, control-doc sync, BRD traceability, and diff check.
- Continue with deeper worker-runtime or failure-driven node execution semantics if runtime depth remains the selected lane.
- Keep provider-specific proof queued until live target access exists.


### Governed Hub Production Depth / Deterministic Sandbox-Hash-Mirror Proof Slice — 2026-05-16

### Work Done Till Date

- Implemented the governed Hub production-depth deterministic proof slice.
- Hub extension records now expose `verification` evidence for sandbox, artifacts, mirrors, blockers, and evaluation time across contracts, OpenAPI, repository payloads, gateway responses, and frontend Hub cards.
- Install/enable/upgrade now block unsafe sandbox command shapes, deterministic artifact hash mismatches, missing artifact hash proof, and unsupported mirror refs while preserving disable as a remediation path.
- Frontend Hub UI now surfaces verification status and blockers, and tests cover the trust/blocking state.

### Gaps Pending

- Real sandbox command execution still needs an isolated runner instead of request-path arbitrary command execution.
- Downloaded artifact hash verification and real private/offline registry mirror proof remain future Hub follow-up work.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credential context.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Run and preserve full verification: Julia suite, npm test/build, coverage, control-doc sync, BRD traceability, diff check, security review, and code review.
- Next Hub follow-up should add an isolated sandbox runner and downloaded-artifact verification when registry/mirror fixtures are available.
- Otherwise continue deeper runtime execution semantics or provider proof once external access exists.


### Julia Runtime Module Expansion / Try-Catch Failure-Recovery Route Slice — 2026-05-16

### Work Done Till Date

- Implemented the next Julia runtime module expansion slice for failure-driven try/catch route evidence.
- Execution status updates with `failedNodeId` for a node covered by try/catch metadata now record bounded `controlFlowRecovery` evidence with control id, failed node id, catch node ids, status, and bounded flag.
- Failed-node telemetry outside any try block still follows the normal terminal failed transition.
- Contracts, OpenAPI, gateway payload mapping, Monitor UI, Julia tests, frontend tests, and contract tests were updated.

### Gaps Pending

- Real catch-node compute execution and worker-runtime branch state remain pending.
- Provider-specific deployment/object-store proof still requires external provider, cluster, and credential context.
- Governed Hub real sandbox/download/mirror proof still requires isolated runner and registry/mirror fixtures.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

### Next Items To Implement

- Run full verification: Julia suite, npm test/build, coverage, control-doc sync, BRD traceability, and diff check.
- Continue runtime depth with catch-node compute or worker branch-state execution if no provider access exists.
- Keep the recovery route additive until real node compute execution is deliberately expanded.

### Julia Runtime Module Expansion / Catch-Node Branch-State Slice — 2026-05-17

#### Work Done Till Date

- Implemented bounded catch-branch worker execution after try/catch recovery.
- Recovered executions now queue catch branch work, worker-service processes catch nodes, records `controlFlowBranchState`, and completes the recovered execution.
- Branch state includes worker id, catch/completed node IDs, failed node ID, bounded status, and deterministic BI outlet row-count node results.
- Contracts, OpenAPI, gateway mapping, Monitor UI, Julia tests, frontend tests, contract tests, PRD/test-spec artifacts, TODO, traceability, risk register, and checkpoint docs were updated.

#### Gaps Pending

- Provider-specific deployment/object-store proof still requires external provider, cluster, and credentials.
- General DAG branch rescheduling beyond the bounded catch-node worker tick remains future runtime work.
- Real Hub isolated sandbox/download/private-mirror proof remains future work.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

#### Next Items To Implement

- Complete full gate execution and code review for this slice.
- If no provider access exists, choose between general DAG branch rescheduling or Hub isolated sandbox/download proof as the next repo-local lane.
- Keep provider proof queued until target provider/cluster/secret context is available.

### Governed Hub Production Depth / Isolated Sandbox-Artifact-Mirror Proof Slice (2026-05-17)

#### Work Done Till Date

- Implemented the next risk-first Hub production-depth slice after provider deployment/object-store risks were blocked by missing external provider, cluster, and credential context.
- Hub install/enable/upgrade now executes only allowlisted Julia extension test fixtures when `JULIAFLOW_HUB_SANDBOX_EXECUTE=1`; arbitrary manifest commands remain rejected.
- Added local artifact-store registry verification for downloaded artifact bytes and mirror-registry resolution for `mirror://` / `private://` refs, including negative blockers for missing artifact and mirror entries.
- Frontend Hub cards now render sandbox/artifact/mirror verification details.
- Added `extensions/labs/test/runtests.jl` plus Julia and frontend regression coverage; Autopilot PRD/test-spec artifacts were created under `.omx/plans/`.

#### Gaps Pending

- Provider-specific deployment and object-store proof still require external provider, cluster, and credentials.
- External Hub registry/provider mirror proof remains pending until registry/provider context exists.
- General DAG branch rescheduling remains future runtime work.
- Final multi-GPU closure remains hardware-gated on >=2 visible CUDA devices.

#### Next Items To Implement

- If provider context appears, burn down `R-DEP-001` / `R-OBJ-001` with staging/prod overlays, secret delivery, server-side dry-run, and provider smokes.
- Otherwise continue the next repo-local lane: general DAG branch rescheduling or frontend/Hub module polish.
- Keep `JULIAFLOW_HUB_SANDBOX_EXECUTE` env-gated and allowlisted; do not execute arbitrary manifest commands.

---

## Update: Runtime DAG Branch Rescheduling Slice — 2026-05-17

### Work Done Till Date

- Completed the next unblocked Julia runtime module expansion step after provider/deployment and external registry lanes remained credential/context gated.
- Worker-service catch-branch execution now derives deterministic DAG stages from catch-node workflow connections, preserving bounded execution by catch node count.
- Branch evidence now includes `branchStages`, `branchStageIndex`, `branchStageCount`, and per-stage `stageResults` through Julia metadata, gateway payload mapping, TS/OpenAPI contracts, and Monitor UI.
- Added regression coverage for independent catch nodes executing before a dependent BI outlet node with row-count evidence.

### Gaps Pending

- Broader multi-node executor scheduling beyond completed catch-branch DAG stages remains future runtime work.
- Provider-specific deployment proof and remote object-store proof still require selected provider, cluster, and credentials.
- External Hub registry/provider mirror proof still requires provider or registry context.
- Final GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Run final control-doc validators, diff check, code review, then commit/push the verified runtime DAG branch slice.
- If provider/credential context appears, prioritize provider-specific deployment and object-store proof; otherwise continue broader runtime executor scheduling or frontend/Hub polish.
- Keep runtime additions additive and evidence-backed across contracts, Julia, frontend, and tests.

---

## Update: Runtime Executor Stage-Schedule Slice — 2026-05-17

### Work Done Till Date

- Completed the next Julia runtime module expansion step after provider/deployment, object-store, external registry, and GPU final gates remained externally blocked.
- Execution records now include bounded topological `executorSchedule` evidence for general workflow DAG stages.
- Schedule evidence records stage indexes, node IDs, resource lanes, worker pools, readiness barriers, max concurrency, bounded status, and scheduler policy.
- Gateway mapping, TS/OpenAPI contracts, Monitor rendering, Julia tests, frontend tests, TODO, risks, traceability, and plan were updated together.

### Gaps Pending

- True asynchronous multi-tick executor scheduling remains future runtime work; this slice is additive evidence, not a full executor rewrite.
- Provider-specific deployment proof and remote object-store proof still require selected provider, cluster, and credentials.
- External Hub registry/provider mirror proof still requires registry/provider context.
- Final GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Complete full verification, clean code review, commit, push, and remote publication verification.
- If provider/credential context appears, prioritize provider-specific deployment and object-store proof.
- Otherwise continue runtime depth with true asynchronous multi-tick executor scheduling or choose frontend/Hub polish if runtime scope should pause.

---

## Update: Runtime Multi-Tick Executor Slice — 2026-05-17

### Work Done Till Date

- Completed the next Julia runtime module expansion step after provider/deployment, object-store, external registry, and GPU final gates remained externally blocked.
- Worker-service now advances CPU batch executions over existing `executorSchedule` metadata one bounded stage per tick.
- New `executorState` metadata records queued/running/completed state, current stage, stage count, active/completed node IDs, completed stage indexes, worker id, bounded status, and stage results.
- Gateway mapping, TS/OpenAPI contracts, Monitor rendering, Julia tests, frontend tests, TODO, risks, traceability, and plan were updated together.

### Gaps Pending

- Real node compute/output/error handling inside executor stage ticks remains future runtime work; this slice is metadata-only scheduling behavior.
- Provider-specific deployment proof and remote object-store proof still require selected provider, cluster, and credentials.
- External Hub registry/provider mirror proof still requires registry/provider context.
- Final GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Complete full verification, clean code review, commit, push, and remote publication verification.
- If provider/credential context appears, prioritize provider-specific deployment and object-store proof.
- Otherwise continue runtime depth by binding real node execution/output/error handling into staged executor ticks.

---

## Update: Runtime Executor Node Result-Error Binding Slice — 2026-05-17

### Work Done Till Date

- Completed the next unblocked `R-RUNTIME-001` slice after provider deployment, object-store, external registry, and GPU gates remained externally blocked.
- Worker-service staged executor ticks now accept a bounded workflow/node execution callback and persist node output telemetry in `executorState.stageResults[*].node_results` plus flattened `executorState.node_results`.
- Executor ticks now fail fast on callback errors, transition the execution to `failed`, and record failed-node/error metadata for gateway and Monitor consumers.
- Gateway mapping, TS/OpenAPI contracts, Monitor rendering, Julia tests, frontend tests, TODO, risks, traceability, and plan were updated together.

### Gaps Pending

- Full base-extension dataflow execution and payload propagation through the executor callback seam remain future runtime work.
- Provider-specific deployment proof and remote object-store proof still require selected provider, cluster, and credentials.
- External Hub registry/provider mirror proof still requires registry/provider context.
- Final GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Complete full verification, clean code review, commit, push, and remote publication verification.
- If provider/credential context appears, prioritize provider-specific deployment and object-store proof.
- Otherwise continue runtime depth by binding the callback seam to full base-extension dataflow/payload propagation, or switch to frontend/Hub polish if runtime scope should pause.

---

## Update: Runtime Executor Base-Extension Dataflow Binding Slice — 2026-05-18

### Work Done Till Date

- Completed the next unblocked `R-RUNTIME-001` slice after provider deployment, object-store, external registry, and GPU gates remained externally blocked.
- Base extension now exposes an `ExecutorDataflowState` and `execute_executor_dataflow_node!` helper for executor callbacks.
- The helper resolves registered base nodes, builds `NodeContext` inputs from upstream executor outputs, executes source/transform/sink nodes, stores Arrow IPC payloads for downstream nodes, and returns row/output/persisted-ref telemetry.
- Julia runtime tests now prove staged executor ticks can run a real base source -> filter -> sink chain and persist executor node results.
- Extension tests now prove the helper runs base source/filter nodes directly.

### Gaps Pending

- Broader callback-bound dataflow coverage across all base nodes and production scheduling policies remains future runtime work.
- Provider-specific deployment proof and remote object-store proof still require selected provider, cluster, and credentials.
- External Hub registry/provider mirror proof still requires registry/provider context.
- Final GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Complete full verification, clean code review, commit, push, and remote publication verification.
- If provider/credential context appears, prioritize provider-specific deployment and object-store proof.
- Otherwise continue runtime depth by broadening callback-bound dataflow coverage and production scheduling policy evidence, or switch to frontend/Hub polish if runtime scope should pause.

---

## Update: Runtime Executor Dataflow Authored-Alias Coverage Slice — 2026-05-18

### Work Done Till Date

- Completed the next unblocked `R-RUNTIME-001` slice after provider deployment, object-store, external registry, and GPU gates remained externally blocked.
- Base extension executor callbacks now resolve approved UI/contract-style base node aliases to canonical registry keys.
- Callback config normalization now derives source/sink/transform port defaults from authored workflow ports and maps source `path` / sink `destination` fallback fields to runtime config.
- Julia runtime tests now prove an alias-authored source -> select -> aggregate -> sink chain completes through staged executor ticks with Arrow IPC payload propagation and executor node-result telemetry.
- Extension tests now prove direct alias-authored source -> select -> sink helper execution.

### Gaps Pending

- Production scheduling policy evidence for callback-bound executor dataflow remains future runtime work.
- Provider-specific deployment proof and remote object-store proof still require selected provider, cluster, and credentials.
- External Hub registry/provider mirror proof still requires registry/provider context.
- Final GPU closure remains hardware-gated on `>=2` visible CUDA devices.

### Next Items To Implement

- Complete full verification, clean code review, commit, push, and remote publication verification.
- If provider/credential context appears, prioritize provider-specific deployment and object-store proof.
- Otherwise continue runtime depth with production scheduling policy evidence for callback-bound executor dataflow, or switch to frontend/Hub polish if runtime scope should pause.

---

## Update: Runtime Executor Dataflow Scheduling-Policy Evidence Slice — 2026-05-19

### Work Done Till Date

- Completed the next unblocked `R-RUNTIME-001` slice after provider deployment, object-store, external registry, and GPU gates remained externally blocked.
- Executor schedule stages now include bounded callback-dataflow policy evidence with policy name, readiness barrier, eligible/source/sink node IDs, lanes, worker pools, max concurrency, and enabled flags.
- Worker-service executor state now carries aggregated dataflow policy evidence while staged ticks progress and complete.
- Gateway payload mapping, TypeScript contracts, OpenAPI schemas, Monitor UI, Julia tests, frontend tests, TODO, risk register, traceability, and plan were updated together.

### Gaps Pending

- Provider-specific deployment proof and remote object-store proof still require selected provider, cluster, and credentials.
- External Hub registry/provider mirror proof still requires registry/provider context.
- Final GPU closure remains hardware-gated on `>=2` visible CUDA devices.
- Frontend module depth remains available as the next unblocked local lane if provider context remains absent.

### Next Items To Implement

- Complete full verification, clean code review, commit, push, and remote publication verification.
- If provider/credential context appears, prioritize provider-specific deployment and object-store proof.
- Otherwise continue frontend module expansion, especially Monitor operational depth for executor policy/results or BI/Hub polish.

---

## Agent Prompt Hygiene And Skill Routing Cleanup (2026-05-28)

### Work Done Till Date

- Compared project-level `AGENTS.md` against repo-local skills and currently installed plugin skills.
- Found stale references to unavailable skill names (`build-web-apps:*`, `visual-ralph`, `visual-verdict`, `code-review`, `security-review`, `$ralplan`, `$autopilot`) plus hard-coded model guidance.
- Added `.codex/skills/juliaflow-local-first-appliance/SKILL.md` for the revised local-first BRD implementation lane.
- Updated repo-local control-loop, frontend, and provider-deployment skills to route through installed plugin skill names and the local-first BRD priority order.
- Simplified `AGENTS.md` so it delegates procedural detail to repo-local and installed skills instead of duplicating stale prompts.

### Gaps Pending

- Local appliance bootstrap and other local-first product proofs remain implementation work.
- Future plugin/skill inventory changes may require another prompt hygiene sweep.

### Next Items To Implement

- Start local appliance bootstrap proof using `juliaflow-control-loop` plus `juliaflow-local-first-appliance`.

---

## Update: Agent Prompt Hygiene Skill Frontmatter Repair — 2026-06-16

### Work Done Till Date

- Quoted `.codex/skills/juliaflow-local-first-appliance/SKILL.md` description frontmatter so the `work: one-command` trigger text is valid YAML.
- Hardened `scripts/validate-control-doc-sync.mjs` to read git output via status-based child-process handling after `execFileSync` threw despite status `0` in the current environment.
- Confirmed all repo-local skill frontmatter blocks still expose required `name` and `description` keys.

### Gaps Pending

- Official `skill-creator` validation still depends on `PyYAML`, which is not installed in the current Python environment.

### Next Items To Implement

- Re-run official skill validation after project or user environment dependencies provide `PyYAML`.

---

## Update: Offline Hub Proof Implementation Staged — 2026-06-16

### Work Done Till Date

- Added gateway health evidence for local Hub cache readiness, artifact-store path, mirror-registry path, artifact cache root, bundled extension count, and locally installed extension count.
- Updated local appliance bootstrap to initialize offline Hub artifact and mirror registry files under the local Hub cache.
- Added `npm run smoke:local-offline-hub`, which runs the gateway router in-process, registers a local official extension from a local artifact cache, enables it through offline mirror resolution, and verifies an unsafe sandbox command is blocked.
- Exposed Offline Hub readiness in the Monitor health panel and aligned TypeScript/OpenAPI/test fixtures.
- Rectified the development shell for Debian by adding `npm run doctor:debian`, repo-local Juliaup support, and workspace-local Julia depots; the compatibility `doctor:wsl-node` script now delegates to the Debian doctor.
- Verified with `npm run doctor:debian`, `npm run smoke:local-offline-hub`, Debian-local `julia --project=. tests/julia/runtests.jl`, `npm run validate:contracts`, `npm run test`, `npm run build`, control-doc sync, BRD traceability, and diff checks.

### Gaps Pending

- Offline Hub TODO item 8 is closed for the current local-first slice.
- External Hub registry/provider mirror proof remains optional compatibility work.
- The Babel/esbuild/Vite dependency advisories are resolved in this PR branch; `npm audit --audit-level=moderate` reports zero vulnerabilities after the Vite 8 lockfile upgrade.

### Next Items To Implement

- Start academic reproducibility workflow: offline EDA -> model -> explain -> dashboard -> checkpoint -> export/reimport with package, seed, checksum, metric, model, explanation, dashboard, and notes evidence.

---

## Update: Backend-Backed Data And Transform Product Actions — 2026-06-17

### Work Done Till Date

- Merged PR #12 after `web` and `julia` CI passed, then opened draft PR #13 from updated `main`.
- Added `POST /api/v1/local-data/import` to return local data-estate profile evidence with dataset ID normalization, schema/profile summary, manifest checksum evidence, DuckDB status, checksum, and local artifact ref.
- Added `POST /api/v1/workflows/{workflowId}/transforms/run` and `GET /api/v1/workflows/{workflowId}/transforms/history` to tie transform runs to workflow nodes, execution records, checkpoints, and local artifact evidence.
- Added shared TypeScript client types/methods and OpenAPI paths/schemas for the Data and Transform actions.
- Updated Data and Transform views to call the gateway actions when configured and deterministic demo fallback otherwise.
- Added focused contract, frontend, and Julia gateway coverage.

### Gaps Pending

- ML Studio experiment tracking, Models registry mutation, Visualize checkpoint/export depth, and local Deploy packaging remain product-depth follow-ups.
- Provider/cloud deployment remains optional compatibility work and was intentionally not expanded.
- Hardware-backed CUDA and multi-GPU evidence remain conditional on available local hardware.

### Next Items To Implement

- Complete final verification, commit, push, and PR #13 CI/review workflow.
- Continue the local product-depth path with ML Studio experiment tracking or Models registry mutation before Deploy packaging.

---

## Update: Mockup-Aligned Local UI And Browser Automation — 2026-06-17

### Work Done Till Date

- Rebuilt the frontend around the light JuliaFlow Local mockup language: fixed local sidebar, persistent `100% Local` status strip, compact white panels, purple primary actions, green local/privacy indicators, and right-side detail panels.
- Split the monolithic app surface into shared shell/card/table/status components, deterministic local fixture data, and dedicated route views for Explorer, Data, Transform, ML Studio, Models, Visualize, Deploy, and Settings.
- Preserved runtime `juliaflow-config.js` gateway lookup, deterministic demo fallback, route navigation, and backend-backed action buttons for Data import/profile, Transform runs, ML experiments, Models registry, Visualize checkpoint export, and Deploy packaging.
- Added Playwright browser automation with `npm run test:browser` and `npm run test:browser:headed`, using mocked gateway routes and local-only synthetic workflow data across desktop Chromium and mobile-width Chromium.
- Updated focused frontend unit coverage for route navigation, runtime gateway config, and action fallback behavior.

### Gaps Pending

- This slice does not expand provider/cloud deployment, external connectors, cloud registries, or hardware-gated multi-GPU evidence.
- Future UI work should be driven by concrete local-first usability gaps, visual polish, or accessibility findings rather than optional cloud compatibility.

### Next Items To Implement

- Keep `npm run test:browser` in the frontend release gate.
- Run the full repo gate set before PR completion, including contracts, Julia tests, frontend tests, build, control-doc sync, BRD traceability, and diff whitespace checks.

---

## Update: AKS-5 Stage 2 Release-Mode Boundary - 2026-06-18

### Work Done Till Date

- Added shared runtime-mode, fixture-provenance, fixture-substitution, and unavailable-state contracts for `demo`, `development`, `release`, and `local-appliance`.
- Exposed the runtime contract from gateway `/health` with `JULIAFLOW_RUNTIME_MODE` support.
- Extended frontend runtime config to honor `runtimeMode`, `gatewayAuthToken`, `oidcAccessToken`, workspace id, and workspace role; release/local-appliance mode now surfaces unavailable, empty, or auth-failure backend states instead of silently substituting deterministic demo fixtures.
- Added focused contract, Julia, and frontend tests for the release-mode boundary.

### Gaps Pending

- AKS-5 Stage 3 real save/run/monitor lifecycle remains pending.
- Live-backend Playwright QA and the single fresh-checkout release verification script remain pending Stage 5 work.
- PR #20 has merged; PR #21 is retargeted to `main`. The primary Documents checkout is restored as a readable Git checkout, but this Codex process still cannot write `.git` lock files because restored `.git` ACLs block metadata writes, so verification and branch updates use fresh temp clones.

### Next Items To Implement

- Keep PR #21 current on `main`, verify Stage 2 gates after each change, and mark it ready after final review.
- Start Stage 3: backend-backed Canvas save/run/monitor plus artifact-backed dashboard/explainability behavior.

---

## Update: AKS-5 Stage 3 Save/Run/Monitor Lifecycle - 2026-06-19

### Work Done Till Date

- Continued from `main` after PR #21 merge on branch `akshayjain00/aks-5-stage-3-real-workflow-lifecycle`.
- Added Explorer workflow lifecycle actions: Save calls the gateway workflow update API, and Run calls the gateway workflow execution API.
- Added execution records to frontend state and gateway loading, using `/api/v1/executions` when a gateway is configured.
- Added a Monitor route that renders backend execution records, latest execution status, completed-node evidence, and explicit no-execution empty states.
- Preserved fixture substitution only where runtime mode permits it; release/local-appliance mode keeps empty execution lists empty.
- Added focused frontend coverage for Monitor navigation, demo fallback save/run labels, gateway save/run calls, and local-appliance empty execution records.

### Gaps Pending

- Dashboard chart/export data is not yet bound to persisted execution artifact datasets.
- Explainability evidence still needs executed-workflow/dataset-checksum/model-artifact/metric/output binding for Stage 3 closure.
- Live-backend browser QA and the single fresh-checkout release verification job remain Stage 5 work.

### Next Items To Implement

- Complete the dashboard artifact-backed dataset path for Stage 3.
- Complete executed-run explainability evidence binding and then expand live-backend browser QA.

---

## Update: AKS-5 Stage 3 Dashboard/Explainability Evidence Binding - 2026-06-19

### Work Done Till Date

- Continued from the merged Stage 3 lifecycle branch on `akshayjain00/aks-5-stage-3-dashboard-explainability-evidence`.
- Updated Visualize so dashboard rows come from the published dashboard binding dataset rather than direct local fixture rows.
- Added release/local-appliance no-artifact-row behavior when a backend dashboard has no persisted dataset rows.
- Updated Monitor to render executed-run explainability evidence from the latest execution record, including execution id, workflow id, dataset checksum prefix, model artifact ref, primary metric, and explanation method.
- Added focused frontend coverage for artifact-backed dashboard rows, no-data release behavior, and executed-run explainability evidence.

### Gaps Pending

- Stage 5 live-backend browser QA remains pending.
- The single fresh-checkout release verification script/CI job remains pending before AKS-5 closure.

### Next Items To Implement

- Build the Stage 5 release verification pipeline and live-backend browser smoke.
- Keep PRs focused and do not mark AKS-5 closed until fresh-checkout verification evidence exists.

---

## Update: AKS-5 Stage 5 Release Verification Blocker Burn-Down - 2026-06-20

### Work Done Till Date

- Confirmed Docker Desktop daemon access now works from Codex via the `desktop-linux` context; `docker info` and Docker Compose are reachable.
- Fixed the lab-team PostgreSQL metadata smoke blocker by importing `LibPQ` at gateway repository module load, avoiding Julia 1.12 world-age failures during `LibPQ.Connection`, result iteration, and connection cleanup.
- Aligned `scripts/smoke-local-metadata.mjs` with other local smokes so standalone Julia repository checks use the repo-local `.julia-depot` instead of the user-global compiled cache.
- Aligned `scripts/verify-release.mjs` direct Julia phases with the repo-local Julia command/depot, avoiding the Windows application-control block on `C:\Users\aksha\.julia\compiled\v1.12\TimeZonesRecipesBaseExt\Nhpny_ZEv1y.dll`.
- Added `scripts/run-julia.mjs` and routed `npm run julia:instantiate` plus `npm run perf:dispatch` through it, so npm-visible Julia commands also avoid the blocked user-global compiled cache.
- Verified `npm run smoke:local-metadata` passes for single-user file metadata and Docker PostgreSQL lab-team metadata.
- Ran no-skip `npm run verify:release`; it passed bootstrap, contracts, frontend build/test, Julia repo tests, base extension tests, all local smokes, and live-backend browser smoke before failing at `validate-control-doc-sync` because this code slice needed documentation updates.
- Reran full no-skip `npm run verify:release` after control-doc synchronization; it passed with summary evidence at `artifacts/release-verification/latest/summary.json`.

### Gaps Pending

- No Docker/PostgreSQL release-verification blocker remains in the current Codex session.
- Follow-up is PR/Linear reconciliation and review, not additional blocker diagnosis.

### Next Items To Implement

- Update Linear AKS-5/AKS-10 and PR evidence with `artifacts/release-verification/latest/summary.json`.
- Keep the repo-local Julia depot wrapper pattern in future npm-visible Julia subprocesses so user-global compiled cache policy does not affect release gates.

---

## Update: AKS-23 Project Creation And Shell Actions First Slice - 2026-06-20

### Work Done Till Date

- Continued from the manual UI review backlog on branch `codex/aks-23-project-shell-actions`.
- Expanded `+ New Project` into a project-creation dialog with editable project name, required description, typed local folder path, reserved-character/path-traversal/collision validation, workflow identity updates, and scaffold artifact rows shown in Explorer.
- Added browser-native target-folder selection through the File System Access API and writes `Project.toml`, `README.md`, workflow TOML, and `data/raw/.gitkeep` into the granted local folder.
- Wired top-bar `Grid`, `Share`, `?`, and avatar controls to local-first dialogs for module launching, local export/share actions, workspace help, and profile/runtime details.
- Moved Explorer project artifact rows into shared app state so created project scaffolds are reflected immediately.
- Hardened ML Studio metric rendering so incomplete live experiment metric payloads display `n/a` instead of blanking the route.

### Gaps Pending

- Service-owned project scaffold creation from typed paths remains optional future work if product review requires gateway-side writes instead of browser-granted folder writes.
- Top-bar Share currently queues local bundle intent in the frontend; deeper export execution should connect to the reproducibility/backup endpoints in a later slice.
- AKS-27 still needs route-level error boundaries and a full first-item assumption sweep across modules.

### Next Items To Implement

- Review PR #28 for the AKS-23 project creation and shell-action slice.
- After PR #28 review, move AKS-23 to Done if browser-granted local scaffold writes satisfy acceptance; otherwise add a follow-up gateway scaffold endpoint for service-owned typed-path writes.

---

## Update: AKS-27 Route Resilience First Slice - 2026-06-20

### Work Done Till Date

- Started AKS-27 on branch `codex/aks-27-route-resilience` with draft PR #29.
- Added a route-level error boundary around active module views so a module render failure produces an actionable unavailable state while preserving the JuliaFlow shell.
- Hardened shared `DataTable` so missing row arrays do not crash table rendering.
- Added empty-state guards for Models when no registry records exist, Deploy when no package records exist, and Settings when no checkpoint is available.
- Extended local-appliance frontend coverage so empty backend lists remain empty across Transform, Monitor, ML Studio, Visualize, Models, Deploy, and Settings.
- Captured local Playwright/Edge browser sanity for Explorer, ML Studio, Models, Deploy, and Visualize routes.

### Gaps Pending

- Route-level error boundaries are in place, but a broader per-card boundary can be considered later if individual cards should fail independently inside a route.

### Next Items To Implement

- Update PR #29 and Linear AKS-27 with final evidence before marking ready for review.

---

## Update: AKS-24 Explorer System Health And Artifacts First Slice - 2026-06-20

### Work Done Till Date

- Closed stale GitHub PR #19 after confirming it had a dirty merge state against current `main` and overlapped with newer AKS-23/AKS-27 frontend work.
- Started AKS-24 on branch `codex/aks-24-explorer-system-health-artifacts` and moved Linear AKS-24 to In Progress.
- Added gateway-backed health freshness fields to app state and poll existing `/health` every 5 seconds when a gateway is configured.
- Preserved deterministic fixture health in demo mode and marks gateway health stale without discarding the last known values when polling fails.
- Reworked Explorer so static CPU/RAM/Disk placards and the duplicate System Health widget become one promoted runtime-sourced System Health area.
- Replaced generic Privacy & Security content with project-specific trust boundary evidence for local home, data estate root, metadata, auth mode, backup, and runtime provenance.
- Replaced the flat Local Project Browser table with grouped artifact hierarchy rows, inferred artifact kinds, status, size, and path-copy actions.
- Kept Local Compute read-only in this first PR but made it explicitly sourced from runtime health and linked to Settings.
- Verified the slice with focused frontend tests, production build, browser sanity on `/`, `/settings`, and `/data`, control-doc sync, BRD traceability, and diff checks.

### Gaps Pending

- AKS-24 is not complete until compute settings become configurable, persisted, propagated into workflow execution, and visible in execution/experiment evidence.
- Real OS folder reveal/open-directory behavior remains deferred until a native desktop bridge or browser-supported local handle is available; current artifact actions truthfully copy paths.

### Next Items To Implement

- Open a draft PR for the first AKS-24 Explorer health/artifact slice.
- Plan AKS-24 second PR for contract-first compute settings persistence and runtime propagation.

---

## Update: AKS-24 Compute Settings Runtime Slice - 2026-06-20

### Work Done Till Date

- Started stacked branch `codex/aks-24-compute-settings-runtime` from the PR #30 branch so compute settings stay separate from the Explorer health/artifact PR.
- Added shared contract types for `GatewayComputeSettings` and update requests plus typed gateway client methods for `GET/PUT /api/v1/settings/compute`.
- Added gateway file-backed compute settings persistence under the local metadata root.
- Reflected persisted compute settings in gateway health and local hardware profile fields.
- Added Settings controls for backend, worker concurrency, memory limit, GPU preference, and BLAS thread count.
- Added workflow execution metadata evidence through `computeSettingsApplied` while preserving existing GPU and stream dispatch metadata.
- Verified the slice with focused frontend tests, contract validation, repo-local Julia tests, and production build.

### Gaps Pending

- PR #32 replaced the closed stacked PR #31 and merged into `main`.
- Runtime worker processes still read applied policy through gateway execution evidence; deeper hot-reconfiguration of already-running external worker processes remains future runtime depth if required.

### Next Items To Implement

- Continue with AKS-25 Data estate workflow.

---

## Update: AKS-25 Data Estate Workflow Slice - 2026-06-20

### Work Done Till Date

- Started `codex/aks-25-data-estate-workflow` from updated `main` after AKS-24 merged.
- Extended the Data import/profile contract and OpenAPI schema with active read mode, source options, artifact lineage, quality checks, field roles, workflow readiness, quick EDA plots, and preview rows.
- Extended the gateway local-data import/profile response with deterministic telecom churn and Global Superstore fixture evidence and CSV, Arrow IPC, Parquet, and DuckDB read-mode semantics.
- Reworked the Data route from static source cards into dataset catalog, read-mode selector, profile refresh, preview rows, field roles/quality, lineage, quality checks, ML readiness, and quick EDA checks.
- Verified the slice so far with focused frontend tests, contract validation, production build, and repo-local Julia gateway tests.

### Gaps Pending

- PR review/CI/merge are still pending before AKS-25 can close in Linear.
- Download/import UX for full external Kaggle datasets remains represented by deterministic fixture metadata in this slice; no large raw Kaggle files are committed.

### Next Items To Implement

- Close AKS-26 in Linear and confirm no open LowCodeML backlog issues remain.

---

## Update: AKS-26 EDA And ML Diagnostics Slice - 2026-06-20

### Work Done Till Date

- Started `codex/aks-26-eda-ml-diagnostics` from updated `main` after AKS-25 merged.
- Reworked Visualize into EDA, Dashboard, Model Diagnostics, and Experiment Compare modes.
- Fed EDA from AKS-25 data profile evidence: field roles, missingness, outliers, quality checks, target/readiness, and quick plots.
- Preserved dashboard rows, chart properties, checkpoint/export actions, and no-artifact dashboard empty states.
- Added model diagnostic surfaces for ROC/PR/calibration, confusion matrix, threshold review, and feature importance from ML experiment evidence.
- Added experiment comparison for model, dataset, hardware, AUC/F1, learning curve, residual/error distribution, and drift/model registry linkage.
- Added EDA correlation, outlier, and segment-slice review surfaces.
- Merged PR #34 as `2827ff0` after green `web` and `julia` CI.
- Verified the slice with focused frontend tests, production build, control-doc sync, BRD traceability, and diff check.

### Gaps Pending

- Linear AKS-26 closure remains pending until this final control-doc closure update lands.
- Deeper persisted diagnostic artifact contracts can follow only if later backend requirements need diagnostics stored independently of existing profile/experiment/dashboard evidence.

### Next Items To Implement

- Merge this closure-doc update.
- Move AKS-26 to Done and confirm no open LowCodeML backlog issues remain.

---

## Update: Codex Review Required Fixes - 2026-06-20

### Work Done Till Date

- Reviewed Outlook/GitHub Codex bot findings and compared them against current `main`.
- Fixed stale chart readiness so zero-trace stale specs show empty state instead of mounting/exporting blank Plotly charts.
- Fixed Transform React Flow state to reset when the live workflow identity changes.
- Preserved metadata and settings for palette-created Transform nodes.
- Fixed gateway workspace summary disk usage to use managed data-estate `usedBytes`.
- Replaced hard-coded churn workspace artifacts with summaries derived from actual local data-estate files.
- Generated DuckDB binding SQL with an absolute managed-root Parquet glob and refreshed managed generated files when content changes.
- Made Postgres metadata readiness follow the actual repository backend instead of only the selected local profile.
- Added bounded Postgres readiness waiting after `docker compose up -d` for `dev:local --profile lab-team`.

### Gaps Pending

- Control-doc sync must be rerun after this tracker/checkpoint update.
- No new product capability is claimed; this is a review-fix hardening slice.

### Next Items To Implement

- Rerun verification gates and open/merge the review-fix PR after checks pass.
