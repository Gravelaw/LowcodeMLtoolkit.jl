# JuliaFlow Current Development Plan

Last updated: 2026-06-23

## Current Phase

JuliaFlow is past local-platform P0, P1, and P2 thin-slice closure. The active development phase is **Local-First GA Proof + Explainable Local Appliance Expansion**.

P0/P1/P2 evidence is tracked in `docs/brd-traceability.md`. The core BRD direction now prioritizes a self-contained local appliance for academia and low-resource teams: local install/bootstrap, local product modules, local data estate, local metadata/database modes, local CPU/GPU hardware use, AI explainability, offline Hub, academic reproducibility, and backup/restore. Provider/cloud paths are optional compatibility work, not the core GA gate.

## Current Baseline

- P0 local-platform scope is closed for base nodes, Arrow/DataFrames materialization, BI, auth/RBAC, streaming, and GPU MVP.
- P1 is closed for Hub hardening, component/control-flow contracts, and observability/perf gates.
- P2 is closed for Kustomize-backed ArgoCD workload manifests and provider-neutral dependency seams.
- Repo-local skill surfaces now exist for control-loop, Julia, frontend, and provider-deployment work.
- First frontend module expansion slice is complete: published BI viewer row search filters visible chart rows and filtered CSV export without changing contracts.
- Frontend module expansion follow-up is complete: Monitor now expands executor dataflow stage-policy evidence and per-node executor/branch result details for operator review.
- Julia runtime module expansion now has loop runtime-plan, try/catch runtime-plan, try/catch failure-recovery routing, catch-branch worker execution, DAG branch rescheduling, executor stage-schedule evidence, metadata-only multi-tick executor scheduling, executor node result/error binding, base-extension dataflow binding, authored-node alias coverage, and callback dataflow scheduling-policy evidence slices: covered failed nodes queue catch work, worker-service schedules catch branch DAG stages, execution records carry bounded topological executor schedules, staged executor ticks persist node output/error telemetry, base extension source/transform/sink/aggregate nodes can propagate Arrow IPC payloads through executor callbacks from UI/contract-style base node types, and executor schedule/state payloads expose bounded callback-dataflow policy evidence.
- Governed Hub production-depth proof now records verification evidence, blocks unsafe sandbox/hash/mirror install paths, executes an env-gated allowlisted sandbox fixture, verifies downloaded artifact hashes from a local artifact-store registry, and resolves private/offline mirror refs through a local registry.
- `business-requirements-v0.3.0.md` is now the v0.4.1 local product-surface BRD baseline: no cloud account required, local filesystem/DuckDB first, PostgreSQL for lab/team metadata, optional MinIO only for local S3 compatibility, explainability as core scope, multi-GPU validation conditional on local hardware, and Explorer/Data/Transform/ML Studio/Models/Deploy/Visualize/Settings treated as required local product modules.
- Documentation cleanup removed the user-approved obsolete BRD/planning/checkpoint artifacts, while the active control set remains `business-requirements-v0.3.0.md`, `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, `docs/checkpoint-log.md`, and `docs/brd-traceability.md`.
- Agent prompt hygiene now routes local-first appliance work through a dedicated repo-local skill, replaces stale skill/plugin names with installed plugin skill names, and removes hard-coded model/subagent assumptions from project guidance.
- Local appliance bootstrap proof is complete for the current local-first slice: `dev:local`/`smoke:local-bootstrap` scripts, profile wiring (`single-user`, `lab-team`, `s3-compatible-local`, `developer`), local data-estate zone initialization, gateway health local-appliance evidence, Monitor rendering, sample workflow availability, and JS/Julia/contract smoke evidence are in place. The active development shell supports native Windows Node/Julia and Debian-native Node/Julia; WSL interop through Windows Node remains rejected.
- Local data estate proof is complete for the current local-first slice: managed zone manifests/checksums, Arrow IPC and Parquet artifact-format evidence, quota/used-byte health fields, cleanup and backup hook readiness, DuckDB query binding, Monitor rendering, smoke wrapper, and Julia/frontend/contract coverage are in place.
- Local metadata/database proof is complete for the current local-first slice: gateway `/health` exposes metadata mode/backend/root/readiness/schema/concurrency/capability evidence, Monitor renders the metadata block, `smoke:local-metadata` proves single-user file mode plus live Docker Postgres lab-team mode, and repository tests prove shared Postgres catalog/cursor visibility across repository instances.
- Local hardware runtime proof is complete for the current local-first slice: gateway `/health` exposes hardware profile/backend, bounded CPU scheduler/concurrency/memory-limit evidence, GPU CUDA probe status, hardware/simulated GPU counts, VRAM totals, and per-device summaries; Monitor renders hardware evidence; `smoke:local-hardware` proves CPU fallback with an empty GPU registry plus safe CUDA-smoke skip behavior on non-CUDA machines.
- Explainability and model evidence proof is complete for the current local-first slice: gateway `/health`, checkpoint payloads, and accepted executions now expose deterministic dataset-card, model-card, feature-importance, local-explanation, limitations/warnings, and reproducibility-bundle readiness evidence; Monitor renders the evidence; `smoke:local-explainability` verifies the local surface.
- Academic reproducibility workflow proof is complete for the current local-first slice: gateway export/import routes produce a checksum-protected local JSON bundle with workflow, checkpoint, dataset checksum/card, package/runtime metadata, seeds, model artifact, metrics, explainability outputs, dashboard snapshot, notes, and local-only evidence; `smoke:local-reproducibility` verifies export/reimport into a fresh local repository and rejects tampered bundles.
- Backup/restore and migration proof is complete for the current local-first slice: gateway export/import routes produce a checksum-protected local appliance bundle with workflows, checkpoints, executions, published dashboards, Hub records, auth policy/directory, package/runtime metadata, settings, and data-estate artifact references/checksums; restore rehydrates metadata into a fresh store, reports missing local artifacts and checksum mismatches, and rejects tampered bundles; `smoke:local-migration` verifies the migration path.
- Mock-aligned local product workflow vertical first implementation slice is complete for the frontend shell: Explorer, Data, Transform, ML Studio, Models, Visualize, and local-only Deploy are wired through shared local workspace state and tested end to end in demo mode.
- Backend-backed product-depth actions are complete for Data import/profile, Transform run/history, ML Studio experiment run/history, Models registry register/list, Visualize checkpoint/export, and local Deploy packaging, with contracts, gateway routes, frontend actions, deterministic demo fallback, and local evidence tests.
- AKS-5 Stage 2 release-mode boundary is implemented as a focused follow-up to the bootstrap PR: shared contracts now expose `demo` / `development` / `release` / `local-appliance` runtime mode, fixture provenance, fixture-substitution policy, and unavailable states; gateway `/health` advertises the same contract; the frontend runtime config honors `runtimeMode` plus gateway/OIDC auth token context; release/local-appliance mode reports unavailable or empty backend states instead of silently substituting demo fixture rows; and normal frontend gateway APIs propagate bearer/workspace auth headers with explicit auth failure UI.
- AKS-5 Stage 3 first lifecycle slice is implemented in the modular frontend: Explorer saves workflows through the gateway update API, runs workflows through the gateway execution API, and Monitor renders backend execution records or explicit empty states without release-mode fixture substitution.
- AKS-5 Stage 3 evidence binding is implemented in the modular frontend: Visualize renders published dashboard binding datasets instead of fixture rows, release/local-appliance mode shows explicit no-artifact-row states, and Monitor ties explainability evidence to the latest execution id, workflow id, dataset checksum, model artifact ref, metric, and explanation method.
- AKS-5 Stage 5 release verification is complete for the current release-readiness closure path: `npm run verify:release` provides one release gate with deterministic artifacts and failure classification, full no-skip release verification passes with evidence at `artifacts/release-verification/latest/summary.json`, and `npm run smoke:live-backend-browser` passes against a local gateway/frontend in `local-appliance` mode.
- AKS-13 live workflow metadata recovery is complete for the current frontend slice: release/local-appliance mode treats incomplete workflow metadata as an explicit unavailable/recovery state instead of rendering fixture canvas nodes, while demo/development fallback behavior remains preserved.
- Explorer/Data/Transform mock-parity and interactive local analytics are implemented for the current product-depth slice: Julia/gateway responses now expose Plotly-compatible local chart specs, Explorer uses gateway-backed workspace summaries and artifact evidence, Data has functional local source/read/filter/sort/profile/lineage states, and Transform uses React Flow for an editable node canvas with settings, validation, history, Julia code, logs, before/after preview, and Plotly metric evidence.
- AKS-29 through AKS-35 follow-up hardening is implemented for the current branch: each task has a recorded plan, shared chart readiness is factored into a reusable utility, Explorer exposes workspace/artifact source state, Data source/sampling/readiness behavior is visible and wrapped, Transform node settings are editable with validation evidence, and browser coverage exercises chart stale state, Data sampling, and Transform config validation.
- Data scientist persona readiness analysis is documented in `docs/data-scientist-persona-competition-readiness-report.md`: Titanic, House Prices, and ROGII are treated as reference examples, and the generalized product gap is now explicit for local train/validation/test onboarding, schema/type correction, statistical EDA, validation/test discipline, hyperparameter tuning, and prediction/output export.
- The persona report now also covers four daily local-workstation personas: senior data engineer, principal data scientist, MLOps engineer focused on training/drift/evaluation, and a non-coding user with statistics/ML knowledge. KNIME, Orange, and H2O-style low-code expectations are translated into JuliaFlow-specific gaps for connectors, no-code guided workflows, AutoML/tuning, model registry, drift monitoring, and reproducible local reports.
- Persona-driven architecture review is documented in `docs/persona-architecture-review.md`: the review passes continued planning with conditions, but blocks any daily-workstation readiness claim until JuliaFlow adds a contract-first `DataScienceProject` aggregate, splits gateway product logic into internal modules, introduces typed stats/training/tuning/evaluation/drift job records, and moves route-local frontend state behind project-backed actions.
- Principal multi-reviewer synthesis is documented in `docs/principal-persona-readiness-review.md`: contract/API, gateway/runtime, frontend/UX, data-science validity, security/trust-boundary, and MLOps reviewers all converge on a P0 block for implementation readiness. The next active lane is `DataScienceProject` substrate and persona architecture refactor before deeper ML Studio, Models, Deploy, Monitor, drift, tuning, or broad local connector work.
- The custom inbound GitHub CI webhook receiver was reviewed, archived locally under `.codex-archive/github-ci-webhook-monitor-20260622/`, and removed from the active repo path because public or tunneled workstation endpoints are not an acceptable default local-first monitoring design. If CI visibility remains painful, prefer GitHub-native workflow summaries/status artifacts or a bounded local ETag/backoff watcher.
- AKS-36 first substrate slice is in progress: additive `DataScienceProject` TypeScript/OpenAPI contracts, generated-client coverage, file/PostgreSQL-compatible repository records, thin gateway create/list/read/update routes, repository tests, and focused Julia route smokes now exist. Follow-up slices wire Data schema diagnostics and validation/test controls to the shared project aggregate, persist through `PUT /api/v1/data-science-projects/{projectId}`, harden the project API with negative coverage for missing names, duplicate projects, unsupported schema versions, non-array child records, route/body id mismatches, managed-local dataset source refs, raw local import-root confinement, bounded import file checks, first-pass text-like import content sniffing for obvious credential and sensitive PII markers, and redaction-safe accepted/rejected local import audit evidence, add the first execution-level ML experiment guard requiring project split evidence while rejecting final-test use for training/tuning, add project-backed transform fit/apply evidence that fits only on train and applies frozen state to held-out splits, gate model registration plus local deploy packaging on the same validation evidence, add a project-scoped statistical EDA run route that persists chart/result/code evidence into `statisticalAnalysisRuns`, computes local CSV-backed summary, Pearson/Spearman correlation, OLS, one-way ANOVA, t-test, and chi-square evidence for managed CSV sources, and now writes local code/result artifacts with checksum/size evidence, add a validation-only tuning-study route that persists `trainingPlans`/`tuningStudies` while rejecting final-test use, add a final-evaluation route that requires prior validation-only tuning evidence before using the locked final test split, add a prediction-export route gated on approved final evaluation plus output contract evidence, materializes local prediction files with checksum/size artifact refs, validates requested output columns against the known local scoring schema plus inline output-contract mappings, parses inline output contracts with required-column and source-mapping validation, and now links transform fit/apply, statistical analysis, tuning, final evaluation, prediction export, drift report, and model lifecycle project jobs to persisted local gateway execution evidence, add a drift-report route gated on prediction export evidence, add a typed `projectJobs` ledger across the project-scoped routes, record local CPU/GPU resource evidence on project job records, upsert `DataScienceProject.modelLifecycleRecords` from validated model registration through local deploy packaging, persist `DataScienceProject.modelRegistryRecords` so workflow model registry endpoints prefer project-backed registry state while preserving execution-metadata fallback, add project-scoped model lifecycle actions for approval, deprecation, archive, rollback-ready, rolled-back, and retraining-requested evidence, add a dedicated `load_model_registry_records`/`save_model_registry_record!` repository surface and now back it with physical file/PostgreSQL model registry storage while preserving embedded project-record compatibility, and continue the gateway module split by moving pure project validation/materialization into `JuliaFlowDataScienceProjectCore.jl`, pure project model registry/lifecycle mutation plus workflow-scoped registry list/de-duplication and lifecycle action validation/record construction rules into `JuliaFlowDataScienceProjectRegistry.jl`, model registry metric/tag/payload construction into `JuliaFlowDataScienceProjectRegistryPayloads.jl`, shared project job/resource/execution-evidence construction into `JuliaFlowDataScienceProjectJobs.jl`, statistical EDA helper logic into `JuliaFlowDataScienceProjectStatistics.jl`, local-source/import boundary helpers into `JuliaFlowDataScienceProjectLocalSources.jl`, data catalog/profile helper logic into `JuliaFlowDataScienceProjectCatalog.jl`, prediction-export output-contract/content helper logic into `JuliaFlowDataScienceProjectPredictionExport.jl`, monitoring/drift helper logic into `JuliaFlowDataScienceProjectMonitoring.jl`, deploy package helper logic into `JuliaFlowDataScienceProjectDeploy.jl`, tuning-study helper logic into `JuliaFlowDataScienceProjectTuning.jl`, final-evaluation helper logic into `JuliaFlowDataScienceProjectEvaluation.jl`, transform fit/apply helper logic into `JuliaFlowDataScienceProjectTransforms.jl`, and ML experiment project/split validation helper logic into `JuliaFlowDataScienceProjectExperiments.jl`, all with direct helper tests. This does not close the P0 blocker yet; broader gateway module split, connector-specific trust-boundary policy, redaction previews, worker-backed job orchestration, worker-backed statistical jobs, worker-backed profile/catalog jobs, real tuning/evaluation/scoring/drift/deploy worker-backed execution depth, real rollback/retraining execution jobs, connector-specific output-contract imports beyond inline local request contracts, and broader project-backed frontend state remain open.

## Active Development Order

1. **Local appliance bootstrap proof** - complete for current slice
   - Add a one-command local bootstrap path that starts the frontend, gateway, execution service, worker service, data estate, local metadata, Hub cache, and health checks.
   - Support explicit `single-user`, `lab-team`, `s3-compatible-local`, and `developer` install profiles.
   - Verify fresh local install to sample workflow without cloud credentials.

2. **Local data estate proof** - complete for current slice
   - Initialize managed local zones for raw, processed, features, models, runs, checkpoints, dashboards, logs, and extensions.
   - Prove Parquet/Arrow durable local artifacts plus Arrow IPC runtime payloads through manifest/checksum and artifact-format evidence.
   - Bind DuckDB query acceleration over local files/tables through a generated local query file and health/smoke checks.

3. **Local metadata/database proof** - complete for current slice
   - Keep single-user metadata lightweight and local.
   - Verify local PostgreSQL lab-team mode for concurrent metadata, RBAC, audit, execution history, and shared workflow catalog.
   - Metadata backup/restore and migration integrity remain queued for the later backup/restore lane.

4. **Local hardware runtime proof** - complete for current slice
   - Detect CPU cores, RAM, disk, GPU vendor/runtime, VRAM, CUDA readiness, and selected backend.
   - Verify CPU scheduling, memory-aware worker limits, GPU smoke when available, and explicit CPU fallback when unavailable.
   - Treat multi-GPU as conditional local hardware validation only; hardware-backed CUDA remains opportunistic evidence when a CUDA host is available.

5. **Explainability and model evidence** - complete for current slice
   - Add dataset cards, model cards, global feature importance, local prediction explanations, permutation importance, partial-dependence/ICE-style summaries where practical, and limitations/warnings.
   - Include explainability outputs in checkpoints and reproducibility bundles.

6. **Offline Hub proof** - complete for current slice
   - Gateway health reports local Hub cache/artifact/mirror readiness, local bootstrap initializes offline artifact and mirror registry files, and `npm run smoke:local-offline-hub` exercises local extension registration/install plus unsafe sandbox blocking without external registry access.
   - Make bundled/local extensions install without external registry dependency.
   - Keep checksum verification, sandbox compatibility tests, local artifact cache, and unsafe-extension blocking.

7. **Mock-aligned local product surface** - first frontend vertical complete
   - Explorer, Data, Transform, ML Studio, Models, Deploy, Visualize, and Settings are now explicit BRD product modules.
   - First implementation slice extends the existing frontend shell into Explorer/Data/Transform/ML Studio/Models/Visualize/local Deploy using the same local health, workflow, checkpoint, explainability, dashboard, and runtime evidence.
   - Data, Transform, ML Studio, Models, Visualize, and Deploy now have backend-backed local actions for the current local workflow; continue module depth only through concrete usability gaps before broader product-readiness claims.
   - Explorer/Data/Transform now have the first mock-parity product-quality pass: Plotly-compatible chart specs are generated by Julia/gateway code and rendered locally in the frontend, Explorer shows live workspace/artifact evidence, Data table/profile controls visibly mutate state, and Transform uses a React Flow node-edge canvas.
   - Keep hosted SaaS collaboration, remote managed inference, cloud telemetry, cloud model registries, and external connectors optional unless explicitly enabled.

   **Next active lane from principal review:** implement the `DataScienceProject` substrate and persona architecture refactor first. This means additive contracts/OpenAPI, file-backed project repository, thin gateway project routes, explicit schema/split/validation child records, backward-compatible workflow endpoints, and contract/Julia gateway tests. Do not deepen ML Studio, Models, Deploy, Monitor, drift, tuning, or broad connector behavior until the project aggregate, trust boundaries, typed jobs, and validation gates exist.
   - First implementation slice landed the additive project API substrate and repository/route smoke. Follow-up slices add project-backed schema role/logical-type overrides, validation/test split controls, final-test lock UI, gateway update evidence, negative API/contract validation for malformed project payloads, managed-local dataset source boundary checks, raw local import-root confinement, bounded import file checks, first ML experiment run enforcement for project split evidence plus final-test protection, transform fit/apply records that separate train fitting from held-out application, model registration/deploy packaging gates that require validated experiment evidence, a first project-scoped statistical EDA run record route, a validation-only tuning-study route, a final-evaluation route gated on prior validation-only tuning evidence, a prediction-export route gated on approved final evaluation plus output contract evidence, a drift-report route gated on prediction export evidence, and a typed `projectJobs` ledger for project-scoped route work. Continue with design-review findings, gateway module split, broader local trust-boundary hardening, deeper statistical/tuning/evaluation/scoring/drift execution, execution-backed DS/ML jobs, and remaining project-backed frontend migration before claiming daily-workstation readiness.

8. **Academic reproducibility workflow** - complete for current slice
   - Gateway export/import routes prove offline EDA -> model -> explain -> dashboard -> checkpoint -> export/reimport path.
   - Local bundles capture workflow definition, data checksums, package metadata, seeds, metrics, model artifact evidence, explainability outputs, dashboard snapshot, notes, and checksum validation.

9. **Backup/restore and migration proof** - complete for current slice
   - Prove local data estate backup, metadata backup, checkpoint import/export, workflow bundle import/export, and integrity checks.
   - Keep this distinct from reproducibility JSON bundles: backup/restore should cover local estate and metadata portability.

10. **Frontend module expansion**
   - First BI published-viewer row-search slice is complete as of 2026-05-15.
   - Monitor dataflow policy/result detail slice is complete as of 2026-05-28.
   - Continue canvas/BI/Hub/settings improvements with `juliaflow-frontend-development` plus React/design/visual-test skills when frontend depth is selected again.
   - Preserve route shell, demo fallback, runtime `juliaflow-config.js`, accessibility selectors, and coverage gates.

11. **Julia runtime module expansion**
   - Loop runtime-plan slice is complete as of 2026-05-15.
   - Try/catch runtime-plan slice is complete as of 2026-05-16.
   - Try/catch failure-recovery route slice is complete as of 2026-05-16.
   - Catch-node compute / worker branch-state slice is complete as of 2026-05-17.
   - General DAG branch rescheduling for catch branches is complete as of 2026-05-17.
   - Executor stage-schedule evidence for general workflow DAGs is complete as of 2026-05-17.
   - Metadata-only multi-tick executor scheduling is complete as of 2026-05-17.
   - Executor node result/error binding is complete as of 2026-05-17.
   - Base-extension dataflow callback binding is complete as of 2026-05-18.
   - Executor dataflow authored-alias coverage is complete as of 2026-05-18.
   - Executor dataflow scheduling-policy evidence is complete as of 2026-05-19.
   - Next Julia runtime follow-up: pause unless a narrower production-runtime gap is identified; otherwise return to provider proof or frontend module depth.
   - Use `juliaflow-julia-development`, `julia-coding`, and `julia-debugging`; verify with Julia tests and contract tests.

12. **Provider/cloud compatibility backlog**
   - Kustomize/Kubernetes, S3/GCS/Azure object stores, external Hub registries, enterprise OIDC, and provider dry-runs are optional future paths.
   - Do not treat provider proof as a core GA blocker unless the BRD changes again.

13. **Governed Hub production depth**
   - Deterministic sandbox/hash/mirror verification slice is complete as of 2026-05-16.
   - Isolated fixture execution / downloaded artifact hash / private-offline mirror registry proof slice is complete as of 2026-05-17.
   - External registry/provider mirror work is now optional future compatibility; the next core Hub proof is offline/local install.


## Latest Completed Slice — 2026-06-06 Explainability / Model Evidence

**Explainability/model evidence proof** is complete for the current slice. Gateway health, checkpoint records, and accepted execution records now carry deterministic local evidence: dataset card with source checksum/schema/row count, model card with metrics/config/limitations, feature-importance and local prediction explanation, warnings, and reproducibility-bundle readiness. Monitor renders the evidence, and `npm run smoke:local-explainability` verifies the local appliance surface without cloud or GPU dependencies.

Verification evidence for this slice: `npm run validate:contracts`, `julia --project=. tests/julia/runtests.jl`, `npm run smoke:local-explainability`, `npm run build`, and `npm run test`.

## Latest Completed Slice — 2026-06-17 Academic Reproducibility

**Academic reproducibility workflow proof** is complete for the current slice. Gateway routes now export a local reproducibility bundle and import it into a fresh repository, carrying workflow, checkpoint, data checksum/card, Julia/package/runtime metadata, seeds, model artifact evidence, metrics, explainability output, dashboard snapshot, notes, local-only evidence, and a deterministic checksum. The smoke also rejects a tampered bundle.

Verification evidence for this slice: `npm run smoke:local-reproducibility`, `npm run validate:contracts`, Debian-local `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-06-17 Backup/Restore And Migration

**Backup/restore and migration proof** is complete for the current slice. Gateway routes now export a local appliance backup bundle and import it into a fresh local repository, carrying workflows, checkpoints, executions, published dashboards, Hub extension records, auth policy/directory, package/runtime metadata, local appliance settings, and data-estate artifact references/checksums. Restore validates the signed backup checksum, reports missing local data artifacts and checksum mismatches, rehydrates metadata state, and rejects tampered bundles.

Verification evidence for this slice: `npm run smoke:local-migration`, `npm run validate:contracts`, repo-local-depot `julia --project=. tests/julia/runtests.jl`, `npm run doctor:debian`, `npm run test`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-06-17 Mock-Aligned Local Product Workflow Vertical

**Mock-aligned local product workflow vertical first implementation** is complete for the frontend shell. The route shell now exposes Explorer, Data, Transform, ML Studio, Models, Visualize, Deploy, Hub, Monitor, and Settings; Explorer remains the workspace/canvas entry point; `/dashboard` links are still accepted through Visualize; and the new local workflow modules render shared local workspace evidence from health, workflow, checkpoints, executions, data-estate, explainability/model cards, dashboards, and local runtime handoff state.

Verification evidence for this slice: `npm run test` and `npm run build`.

## Latest Completed Slice — 2026-06-17 Backend-Backed ML Studio Experiment Actions

**Backend-backed ML Studio experiment actions** are complete for the current product-depth slice. Gateway routes now run and list workflow ML experiments by reusing local execution and explainability evidence, returning dataset/model IDs, dataset checksum, metrics, feature importance, hardware backend, GPU readiness, checkpoint tag, and local artifact references. The TypeScript/OpenAPI client exposes the action, and ML Studio runs it against the gateway or a deterministic demo fallback.

Verification evidence for this slice: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test`, `julia --project=. tests/julia/runtests.jl`, `npm run build`, and `npm run test`.

## Latest Completed Slice — 2026-06-17 Backend-Backed Models Registry Actions

**Backend-backed Models registry actions** are complete for the current product-depth slice. Gateway routes now register and list local model records by persisting registry metadata into execution records with checkpoint, model, dataset checksum, primary metric, tags, owner, deployment status, and local artifact evidence. The TypeScript/OpenAPI client exposes the action, and Models runs it against the gateway or deterministic demo fallback.

Verification evidence for this slice: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test`, `julia --project=. tests/julia/runtests.jl`, `npm run build`, and `npm run test`.

## Latest Completed Slice — 2026-06-17 Backend-Backed Visualize Checkpoint/Export Actions

**Backend-backed Visualize checkpoint/export actions** are complete for the current product-depth slice. Gateway route `POST /api/v1/workflows/{workflowId}/dashboards/{dashboardId}/checkpoint-export` composes dashboard publish, checkpoint creation, and reproducibility bundle export into one local evidence action with dashboard/checkpoint/bundle artifact refs and checksums. The TypeScript/OpenAPI client exposes the action, and Visualize runs it against the gateway or deterministic demo fallback with export history.

Verification evidence for this slice: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test`, and `julia --project=. tests/julia/runtests.jl`; full `npm run test`, `npm run build`, control-doc validators, and `git diff --check` remain in the final PR gate.

## Latest Completed Slice — 2026-06-17 Backend-Backed Deploy Packaging Actions

**Backend-backed Deploy packaging actions** are complete for the current product-depth slice. Gateway routes now generate and list local-only deploy package records from workflow/model/checkpoint evidence, mark the model registry record `local_ready`, and return endpoint, service code, package refs, checksums, run command, and local artifact evidence. The TypeScript/OpenAPI client exposes the action, and Deploy runs it against the gateway or deterministic demo fallback with package history.

Verification evidence for this slice: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test`, and `julia --project=. tests/julia/runtests.jl`; full `npm run test`, `npm run build`, control-doc validators, and `git diff --check` remain in the final PR gate.


## Latest Completed Slice — 2026-06-03 Local Hardware Runtime

**Local hardware runtime proof** is complete for the current slice. Gateway health now exposes local hardware profile status, selected backend (`cpu`, `cuda`, or `simulated_cuda`), bounded CPU scheduler policy, worker concurrency, CPU memory limit, CUDA probe status, hardware/simulated GPU counts, VRAM totals, and per-device summaries. The Monitor renders the hardware evidence, `npm run smoke:local-hardware` proves CPU fallback with an empty GPU registry and deterministic CUDA-smoke skip behavior when CUDA is not requested, and contract/frontend/Julia coverage pins the expanded health surface.

Verification evidence for this slice: `npm run doctor:wsl-node`, `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- App.test.tsx`, `npm run smoke:local-hardware`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run smoke:local-bootstrap`, `npm run smoke:local-data-estate`, `npm run smoke:local-metadata`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`. This historical doctor command now delegates to the Debian doctor in current repo state.

## Latest Completed Slice — 2026-05-31 Local Metadata / Database

**Local metadata/database proof** is complete for the current slice. Gateway health now exposes metadata mode/backend/root/readiness/schema/concurrency/capability evidence for file-backed `single-user` and PostgreSQL-backed `lab-team` operation. The Monitor renders the metadata evidence, `npm run smoke:local-metadata` proves single-user file metadata plus live Docker Postgres lab-team metadata, and Julia repository coverage proves shared Postgres catalog/cursor visibility between two repository instances.

Verification evidence for this slice: `npm run doctor:wsl-node`, `npm run smoke:local-bootstrap`, `npm run smoke:local-data-estate`, `npm run smoke:local-metadata`, `npm run validate:contracts`, `julia --project=. tests/julia/runtests.jl`, `npm --workspace @juliaflow/frontend run test -- App.test.tsx`, plus pending full `npm run test`, `npm run build`, control-doc sync, BRD traceability, and diff checks before final commit. This historical doctor command now delegates to the Debian doctor in current repo state.

## Latest Completed Slice — 2026-05-30 Local Data Estate

**Local data estate proof** is complete for the current slice. Gateway health now exposes managed manifest/checksum status, Arrow IPC and Parquet artifact formats, quota/used bytes, cleanup and backup hook readiness, and a DuckDB query binding over local processed Parquet files. The local smoke command verifies these fields, and the Monitor renders the new managed-estate evidence.

Verification evidence for this slice: `npm run smoke:local-data-estate`, `npm run validate:contracts`, `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-15

**Frontend module expansion / BI viewer row-search slice** is complete. Published dashboard viewers now support a viewer-wide row search applied after chart cross-filters, clear row-search controls, row-search status, and filtered CSV export that respects both the selected chart filter and search term.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- App.test.tsx` passed locally before full gate execution.


## Latest Completed Slice — 2026-05-15 Runtime

**Julia runtime module expansion / loop runtime-plan slice** is complete. Loop control-flow metadata now validates start-to-end reachability, derives bounded body node IDs from the workflow DAG, emits additive `controlFlowPlan` execution evidence through contracts/gateway/frontend, and keeps node compute execution unchanged.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl` and `npm run test` passed before full gate execution.

## Latest Completed Slice — 2026-05-16 Runtime

**Julia runtime module expansion / try-catch runtime-plan slice** is complete. Try/catch metadata now emits additive `controlFlowPlan` execution evidence with try and catch body node IDs through contracts/gateway/frontend, while node-level failure catching remains a deliberate future executor expansion.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl` and `npm run test` passed before full gate execution.

## Latest Completed Slice — 2026-05-16 Runtime Failure Recovery

**Julia runtime module expansion / try-catch failure-recovery route slice** is complete. Execution status updates that report `failedNodeId` for a node covered by existing try/catch metadata now record `controlFlowRecovery` catch-route evidence and keep the execution non-terminal; failed-node telemetry outside try/catch still transitions normally to failed. The evidence is exposed through contracts, OpenAPI, gateway payloads, Monitor UI, and tests.

Verification evidence for this slice: Julia/frontend/contract tests, build, coverage, control-doc sync, BRD traceability, and diff checks are required before commit.


## Latest Completed Slice — 2026-05-17 Runtime Catch Branch

**Julia runtime module expansion / catch-node branch-state slice** is complete. Recovered try/catch executions now queue bounded catch-branch work, worker-service processes the branch, records `controlFlowBranchState` with worker id, completed catch nodes, and deterministic BI outlet row-count node results, then completes the execution without weakening terminal failure guards. The evidence is exposed through contracts, OpenAPI, gateway payloads, Monitor UI, and tests.

Verification evidence for this slice: Julia/frontend/contract tests, build, coverage, control-doc sync, BRD traceability, and diff checks are required before completion.


## Latest Completed Slice — 2026-05-17 Runtime DAG Branch Rescheduling

**Julia runtime module expansion / DAG branch rescheduling slice** is complete. Recovered try/catch executions now derive deterministic catch-branch DAG stages from workflow connections, execute independent catch nodes before dependent BI outlet nodes, persist `branchStages` / `stageResults`, and surface branch-stage progress in Monitor without changing broader executor semantics.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-16 Hub

**Governed Hub production depth / deterministic sandbox-hash-mirror proof slice** is complete. Hub extension records now carry `verification` evidence; install/enable/upgrade evaluate bounded sandbox command shape, deterministic artifact hash proof, and `mirror://` / `private://` mirror refs; unsafe commands, hash mismatches, and unsupported mirrors are blocked while disable remains a safe remediation action.

Verification evidence for this slice: Julia/frontend/contract tests, build, coverage, control-doc sync, BRD traceability, and diff checks are required before commit.


## Latest Completed Slice — 2026-05-17 Runtime Executor Schedule

**Julia runtime module expansion / executor stage-schedule slice** is complete. Execution records now derive a bounded topological `executorSchedule` for general workflow DAGs with stage indexes, node IDs, lanes, worker pools, readiness barriers, max concurrency, and scheduler policy. Gateway payloads, TS/OpenAPI contracts, Monitor UI, and tests expose the evidence without implementing asynchronous multi-tick execution.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.


## Latest Completed Slice — 2026-05-17 Runtime Multi-Tick Executor

**Julia runtime module expansion / metadata-only multi-tick executor slice** is complete. Worker-service now advances CPU batch executions over existing `executorSchedule` one bounded stage per tick: accepted to queued, queued to running, running stage progress through append-only events, and final stage to completed. Gateway payloads, TS/OpenAPI contracts, Monitor UI, and tests expose `executorState` without executing real node compute.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.


## Latest Completed Slice — 2026-05-17 Runtime Executor Node Results

**Julia runtime module expansion / executor node result-error binding slice** is complete. Worker-service executor ticks now accept bounded workflow/node execution callbacks, persist per-stage and flattened node output telemetry under `executorState`, and fail fast with failed-node/error metadata when a staged node errors. Gateway payloads, TS/OpenAPI contracts, Monitor UI, and tests expose node-result and error details while keeping full base-extension dataflow execution as a future slice.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.


## Latest Completed Slice — 2026-05-18 Runtime Executor Dataflow

**Julia runtime module expansion / base-extension dataflow binding slice** is complete. The base extension now exposes an `ExecutorDataflowState` plus `execute_executor_dataflow_node!` callback helper that resolves registered base nodes, builds `NodeContext` inputs from upstream executor outputs, executes real source/transform/sink nodes, stores downstream Arrow IPC payloads, and returns executor node-result telemetry with row counts/output refs/persisted refs. Worker-service staged executor ticks can use this callback seam without changing stream/GPU ownership.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.



## Latest Completed Slice — 2026-05-19 Runtime Executor Dataflow Policy

**Julia runtime module expansion / executor dataflow scheduling-policy evidence slice** is complete. Executor schedule stages and staged executor state now expose a bounded `dataflowPolicy` / `dataflow_policy` evidence object for callback-bound dataflow, including policy name, callback/dataflow enabled flags, readiness barrier, eligible/source/sink node IDs, lanes, worker pools, max concurrency, and bounded status. Gateway payload mapping, TypeScript contracts, OpenAPI, Monitor UI, Julia tests, and frontend tests were updated without changing stream/GPU ownership.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`, `npm --workspace @juliaflow/frontend run test -- App.test.tsx`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-28 Frontend Monitor Detail

**Frontend module expansion follow-up / Monitor executor dataflow detail slice** is complete. The Monitor execution rail now expands executor schedule dataflow policies by stage and renders per-node executor and catch-branch result details, including node IDs, output kind, row counts, output-ref counts, callback/dataflow flags, and readiness barrier evidence. Repo garbage sanity also removed tracked `.staging/` skill residue and ignored future staging folders; dependency hygiene resolved the moderate `ws` audit advisory through `npm audit fix`.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- App.test.tsx`, `npm audit --audit-level=moderate`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-28 BRD Local-First Baseline

**BRD local-first strategy refresh** is complete. The core Markdown BRD now makes local appliance operation the GA direction: filesystem/DuckDB local data estate, PostgreSQL lab/team mode, optional MinIO profile, local CPU/GPU hardware validation, offline Hub, explainability/model evidence, academic reproducibility bundles, and backup/restore. Provider-specific cloud deployment, cloud object stores, external Hub registries, enterprise identity, and cloud multi-GPU closure are downgraded to optional compatibility paths.

Verification evidence for this slice: `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-18 Runtime Executor Dataflow Aliases

**Julia runtime module expansion / executor dataflow authored-alias coverage slice** is complete. The base extension executor helper now resolves approved UI/contract-style base node types such as `JuliaFlow.Base.CSVReader`, `JuliaFlow.Base.ColumnSelect`, `JuliaFlow.Base.AggregateRows`, and `JuliaFlow.Base.ArrowSink` to canonical registry keys, normalizes port/config defaults from authored workflow ports, and preserves Arrow IPC payload flow through staged executor callbacks. Runtime tests now prove an alias-authored source -> select -> aggregate -> sink chain completes through worker-service executor ticks.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-17 Hub

**Governed Hub production depth / isolated sandbox-artifact-mirror proof slice** is complete. Hub install/enable/upgrade now optionally executes only allowlisted Julia extension test fixtures when `JULIAFLOW_HUB_SANDBOX_EXECUTE=1`, verifies declared artifact hashes against a local JSON artifact-store registry, rejects missing artifact entries, resolves `mirror://` / `private://` refs through a local mirror registry, and surfaces sandbox/artifact/mirror verification details in the Hub UI.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-06-16 Agent Skill Frontmatter Repair

**Agent prompt hygiene follow-up / repo-local skill YAML repair** is complete. The `juliaflow-local-first-appliance` skill description frontmatter is now quoted so its colon-bearing trigger text remains valid YAML and the skill can be discovered without changing local-first routing guidance. The control-doc sync validator now uses status-based child-process handling so normal git stdout does not fail validation.

Verification evidence for this slice: local repo-skill frontmatter check, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`. Official `skill-creator` validation remains blocked until `PyYAML` is available in the Python environment.

## Latest Completed Slice — 2026-06-16 Mock-Aligned BRD Product Surface Refresh

**Mock-aligned BRD product surface refresh** is complete. The BRD now captures mock-only local product requirements for Explorer/workspace overview, Data import/profile/lineage, Transform pipeline/code preview/history, ML Studio training/experiments, Models registry/drift/lineage, local Deploy targets/endpoints, Visualize dashboard builder/export, and Settings for local paths/packages/Julia/compute/security/API keys/snapshots. Stale cloud/provider wording was tightened so hosted SaaS collaboration, remote managed inference, cloud telemetry, cloud model registries, cloud deployment, and external connectors remain optional compatibility rather than core local-first requirements.

Verification evidence for this doc-only slice: `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-06-16 Debian Toolchain And Offline Hub Proof

**Debian toolchain rectification and Offline Hub proof are complete for the current slice.** The repo now uses `npm run doctor:debian`, native Linux/nvm Node, and a repo-local Juliaup LTS install with workspace-local Julia depots. Gateway health exposes local Hub cache readiness, artifact-store and mirror-registry paths, bundled extension count, and locally installed extension count. Local bootstrap initializes the offline Hub cache registry files. `npm run smoke:local-offline-hub` runs in-process through the gateway router, registers and enables a local official extension through a local artifact cache and mirror registry, then verifies an unsafe sandbox command remains blocked.

Verification evidence for this slice: `npm run doctor:debian`, `npm run smoke:local-offline-hub`, Debian-local `julia --project=. tests/julia/runtests.jl`, `npm run validate:contracts`, `npm run test`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, `npm audit --audit-level=moderate`, and `git diff --check`.

## Latest Completed Slice — 2026-06-18 AKS-5 Native Windows Bootstrap Compatibility

**AKS-5 bootstrap compatibility is complete for the first staged PR slice.** The restored GitHub baseline contains the modular frontend, Playwright browser gate, Offline Hub, reproducibility, and backup/restore scripts. The toolchain guard now allows native Windows Node alongside Debian-native Node, while still rejecting WSL `/mnt/c` Windows Node interop. `dev-local` now has an explicit `--skip-instantiate` flag so `--no-deps` remains Docker-only, and the generated Julia manifest policy is documented through `npm run julia:instantiate`.

Verification evidence for this slice: `npm run doctor:windows`, `npm run validate:contracts`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice - 2026-06-19 AKS-5 Stage 3 Save/Run/Monitor Lifecycle

**AKS-5 Stage 3 save/run/monitor lifecycle is complete for the first thin slice.** The modular frontend now treats Explorer as a real workflow lifecycle entry point: Save calls the gateway workflow update API, Run calls the gateway execution API and records the returned execution id, and the new Monitor route renders backend execution records, latest execution status, completed-node evidence, and explicit no-execution empty states. Release/local-appliance mode keeps empty execution lists empty instead of substituting fixture executions, while demo/development modes keep deterministic fixture behavior where allowed.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- App.test.tsx`. The dashboard artifact-row and executed-run explainability follow-up is tracked in the next Stage 3 slice below.

## Latest Completed Slice - 2026-06-19 AKS-5 Stage 3 Dashboard/Explainability Evidence Binding

**AKS-5 Stage 3 dashboard/explainability evidence binding is complete for the modular frontend slice.** Visualize now renders rows from the published dashboard binding dataset and reports an explicit no-artifact-row state when release/local-appliance gateways return dashboards without persisted dataset rows. Monitor now renders executed-run explainability evidence from the latest execution record, including execution id, workflow id, dataset checksum prefix, model artifact ref, primary metric, and explanation method.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- App.test.tsx` and `npm run build`. Remaining AKS-5 work moves to Stage 5: live-backend browser QA and the single fresh-checkout release verification pipeline.

## Latest Completed Slice - 2026-06-19 AKS-5 Stage 5 Release Verification

**AKS-5 Stage 5 release verification implementation** now has a scriptable release gate and live-backend browser smoke. The verifier writes `artifacts/release-verification/latest/summary.json` plus per-command logs, separates bootstrap/product/runtime/control-doc failures, and runs bootstrap, contracts, frontend, Julia, local smoke, browser, control-doc, and diff gates unless explicitly skipped. The live browser smoke starts a local file-backed gateway and Vite frontend on isolated ports, verifies release/local-appliance UI behavior without demo substitution, and covers workflow save/run, Monitor, dashboard rows/export, Settings/auth state, deterministic Offline Hub install, and reproducibility export.

The Docker/PostgreSQL blocker is resolved for the current Windows Codex session. `docker info` now works on the Docker Desktop `desktop-linux` context, `npm run smoke:local-metadata` passes through both single-user file metadata and lab-team PostgreSQL metadata, and the release verifier plus npm Julia helper scripts now run Julia phases with the repo-local `.julia-depot` so Windows application-control policy does not load blocked DLLs from `C:\Users\aksha\.julia\compiled`. The PostgreSQL repository imports `LibPQ` at module load to avoid Julia 1.12 world-age failures during gateway startup.

Verification evidence for this slice: `npm run smoke:live-backend-browser`, `npm run smoke:local-metadata`, `npm run build`, `npm run test`, and full no-skip `npm run verify:release` with passing summary at `artifacts/release-verification/latest/summary.json`. The release verifier passed bootstrap, contracts, frontend, Julia repo tests, base extension tests, all local smokes, live-backend browser smoke, control-doc sync, BRD traceability, and `git diff --check`.

## Latest Completed Slice - 2026-06-20 AKS-13 Live Workflow Metadata Recovery

**AKS-13 live workflow metadata recovery** is complete for the current frontend slice. Release/local-appliance workflow loading now validates backend workflow detail before rendering the live canvas path and reports incomplete metadata as an unavailable state with recovery guidance instead of substituting fixture workflow nodes. Demo/development modes still keep deterministic fixture fallback for offline demos.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run test`, `npm run build`, `npm run validate:contracts`, and `npm run smoke:live-backend-browser` with artifacts at `artifacts/release-verification/live-backend-browser`.

## Latest Completed Slice - 2026-06-20 Explorer/Data/Transform Mock Parity

**Explorer/Data/Transform mock-parity and interactive local analytics** are complete for this focused product-depth slice. Contracts now include local interactive Plotly chart specs, Julia/gateway responses attach workspace, data-profile, and transform-run chart evidence, Explorer renders gateway-backed workspace summaries and artifact trees, Data exposes functional local sources, tabs, filter/sort/read-mode/profile/lineage state, and Transform uses React Flow for node-edge editing with settings, validation, run/history, before/after preview, generated Julia code, logs, artifact output, and local metric charts. Linear tracks the follow-up backlog under AKS-28 with child issues AKS-29 through AKS-35.

Verification evidence for this slice: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `node scripts/run-julia.mjs --project=. tests/julia/runtests.jl`, `npm run test:browser -- tests/browser/local-ui.spec.ts`, `npm run smoke:live-backend-browser`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice - 2026-06-20 AKS-29 Through AKS-35 Parity Hardening

**AKS-29 through AKS-35 parity hardening** is complete for this branch. `docs/aks-30-35-implementation-plan.md` records the per-task plan for AKS-30 through AKS-35 before closure. The implementation factors chart readiness/export behavior into a shared utility, adds stale chart evidence handling, exposes Explorer workspace/artifact source state and empty artifact behavior, makes Data active source and sampling state visible, keeps unsupported sources disabled with reasons, preserves wrapped ML Readiness text, and makes Transform node strategy/output settings editable with validation/log evidence.

Verification evidence for this slice: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `npm run test:browser -- tests/browser/local-ui.spec.ts`, `npm run smoke:live-backend-browser`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice - 2026-06-20 AKS-23 Project Creation And Shell Actions

**AKS-23 project creation and global shell actions are complete.** The frontend slice expands the New Project dialog from template confirmation into editable project name, description, typed local folder path inputs, native target-folder grants through the browser File System Access API, scaffold file writes for granted folders, workflow identity updates, and Explorer scaffold artifact rows. Grid, Share, Help, and Profile top-bar controls now open concrete local-first dialogs. The slice also hardens ML Studio against incomplete live experiment metrics found during browser sanity.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `git diff --check`, and a local Playwright/Edge sanity pass against `/`, `/ml-studio`, and `/visualize`. A future gateway-native scaffold endpoint can still be added if the product needs service-owned writes from typed paths, but the browser path now supports real local file creation after explicit folder permission.

## Latest Completed Slice - 2026-06-20 AKS-27 Route Resilience

**AKS-27 route resilience is complete.** The frontend slice adds a route-level error boundary around module views so one route failure renders an actionable unavailable state without blanking the global shell. It also hardens live empty states for Models, Deploy, Settings, and shared tables so empty or partial backend payloads no longer require first records to exist.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, `git diff --check`, and local Playwright/Edge browser sanity on `/`, `/ml-studio`, `/models`, `/deploy`, and `/visualize`.

## Completed Slice - 2026-06-20 AKS-24 Explorer System Health And Artifacts

**AKS-24 first slice is merged for Explorer live health and artifact UX.** Explorer now uses the existing gateway `/health` contract for a promoted System Health area, polls gateway-backed health every 5 seconds, keeps deterministic fixture health in demo mode, and marks health stale without discarding the last known values when polling fails. The duplicate static CPU/RAM/Disk placards are removed, the generic privacy/security card is replaced by project-specific local trust boundary evidence, the Local Project Browser is grouped into a hierarchical artifact view with path-copy actions, and Local Compute is explicitly read-only runtime-health evidence with a Settings link.

Verification evidence for this slice: PR #30 GitHub checks, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, browser sanity on `/`, `/settings`, and `/data`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`. AKS-24 later closed fully with the compute settings runtime slice.

## Completed Slice - 2026-06-20 AKS-24 Compute Settings Runtime

**AKS-24 second slice is merged.** The gateway now exposes contract-first compute settings through `GET/PUT /api/v1/settings/compute`, persists settings under the local metadata root, reflects applied settings in `healthcheck`, and attaches `computeSettingsApplied` plus dispatch policy evidence to workflow executions without overwriting GPU/stream dispatch metadata. Settings now lets users edit backend, CPU worker concurrency, memory limit, GPU preference, and BLAS thread count, then saves those settings through the gateway or stages them locally in demo mode.

Verification evidence for this slice: PR #32 GitHub `web` and `julia` checks, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run validate:contracts`, `node scripts/run-julia.mjs --project=. tests/julia/runtests.jl`, and `npm run build`. The direct `julia --project=. tests/julia/runtests.jl` command is still blocked by Windows application-control policy against the user-global compiled cache, so repo-local Julia verification uses the project wrapper.

## Completed Slice - 2026-06-20 AKS-25 Data Estate Workflow

**AKS-25 is merged.** The Data import/profile contract now carries active read-mode, source options, artifact lineage, quality checks, field roles, workflow readiness, quick EDA plots, and preview rows. The gateway local-data import/profile response returns deterministic telecom churn and Global Superstore fixture evidence with CSV, Arrow IPC, Parquet, and DuckDB semantics. The Data route now supports dataset switching, read-mode switching, profile refresh, lineage, quality/readiness, and quick EDA evidence instead of static source cards.

Verification evidence: PR #33 GitHub `web` and `julia` checks, `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run validate:contracts`, `npm run build`, and `node scripts/run-julia.mjs --project=. tests/julia/runtests.jl`.

## Latest Closed Slice - 2026-06-20 AKS-26 EDA And ML Diagnostics

**AKS-26 is closed by PR #34 (`2827ff0`).** Visualize now starts as a multi-mode workspace with EDA, Dashboard, Model Diagnostics, and Experiment Compare tabs. EDA consumes AKS-25 data profile fields, quality checks, target/readiness, quick plots, correlation/outlier review, and segment slices; dashboard checkpoint/export remains available; diagnostics show ROC/PR/calibration, confusion matrix, threshold, and feature-importance surfaces from ML experiment evidence; experiment comparison summarizes model, dataset, hardware, AUC/F1, learning-curve, residual, and drift-link views.

Verification evidence: PR #34 `web` and `julia` checks passed; local gates passed with `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `npm run build`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`. Linear AKS-26 is ready for Done closure after this control-doc closure update.

## Latest Completed Slice — 2026-06-17 Backend-Backed Product Actions

**Backend-backed Data and Transform product actions are complete for the current local product-depth slice.** Gateway routes now support local data import/profile evidence and workflow transform run/history evidence backed by local appliance health, workflow nodes, execution state, and deterministic local artifact refs. Shared contracts/OpenAPI expose typed client methods, and the Data/Transform views call those actions while preserving demo fallback, runtime `juliaflow-config.js`, route compatibility, accessible selectors, and local-first behavior.

Verification evidence for this slice: `npm run validate:contracts`, `npm --workspace @juliaflow/frontend run test`, `julia --project=. tests/julia/runtests.jl`, `npm run build`, `npm run test`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-06-17 Mockup-Aligned Local UI And Browser Automation

**Mockup-aligned local-only UI redesign and browser automation are complete for the current frontend product-readiness slice.** The frontend now uses a light JuliaFlow Local appliance shell with a left sidebar, persistent `100% Local` status strip, compact white workspace panels, purple primary actions, green privacy/local indicators, right-side detail panels, deterministic local-only fixtures, and split route/view components for Explorer, Data, Transform, ML Studio, Models, Visualize, Deploy, and Settings. Runtime `juliaflow-config.js` gateway lookup and demo fallback remain intact, and Data/Transform/ML/Models/Visualize/Deploy actions still call the shared gateway client when configured.

Playwright is now a first-class browser gate via `npm run test:browser`, covering desktop Chromium and mobile-width Chromium journeys with mocked gateway routes and synthetic local workflow data. The default browser gate is deterministic and does not require a Julia gateway process.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- App.test.tsx`, `npm run build`, and `npm run test:browser`.

## Required Skills By Lane

## Latest Review Fix Slice - 2026-06-20 Codex Review Required Fixes

**Codex review required fixes are implemented for the current Explorer/Data/Transform and local appliance follow-up branch.** The slice fixes stale-empty chart classification, React Flow Transform resync on workflow identity changes, palette-created node settings retention, managed data-estate disk usage in workspace summary, local artifact summaries derived from actual data-estate files, root-bound DuckDB query SQL generation, Postgres metadata readiness based on the actual repository backend, and bounded Postgres readiness waiting for `dev:local --profile lab-team`.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- --run src/App.test.tsx`, `node scripts/run-julia.mjs --project=. tests/julia/runtests.jl`, `npm run validate:contracts`, `npm run build`, `npm run test:browser -- tests/browser/local-ui.spec.ts`, and `npm run validate:brd-traceability`. `npm run validate:control-doc-sync` initially failed as expected before this control-doc update and must pass before closure.

- BRD/control docs: `juliaflow-control-loop`.
- Local-first GA: `juliaflow-local-first-appliance`.
- Julia services/runtime/nodes: `juliaflow-julia-development`.
- Frontend/UI: `juliaflow-frontend-development`.
- Deployment/provider proof: `juliaflow-provider-deployment` only for explicit optional provider/cloud compatibility.
- Review/security/GitHub/plugin work: use an installed plugin skill only when it is available and directly matches the task.

Use multi-agent tools for independent bounded lanes only when available and ownership is clear; otherwise keep work integrated in the current agent session.

## Verification Matrix

| Lane | Required evidence |
| --- | --- |
| Control docs / TODO / traceability | `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, tracker/checkpoint update |
| Frontend | `npm run test`, `npm run build`, relevant coverage/perf gate |
| Julia runtime/services | `julia --project=. tests/julia/runtests.jl`, targeted extension tests when applicable |
| Deployment | `npm run validate:k8s`, server-side dry-run when cluster exists |
| Provider proof | Live smoke output for selected provider; no real secrets in git |
| GPU final | `JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1` on `>=2` visible CUDA devices |

## Non-Negotiables

- NASA/JPL Power of 10 remains mandatory for core logic.
- `packages/contracts/` remains the cross-layer source of truth.
- Arrow IPC remains the inter-node payload boundary.
- No real secrets in git.
- No fake production StatefulSets for managed provider services.
- Do not mark TODO P0/P1/P2 or final hardware items complete without traceability evidence and verification evidence.
- Control-doc sync automation is mandatory: every completed slice, phase, or review must update `Plan.md`, TODO, risks, tracker, and checkpoint, then pass `npm run validate:control-doc-sync`.
