# JuliaFlow Local-First Low-Code Data Science Toolkit

## Document Control

- **Date:** 2026-06-16
- **Owner:** Product / Data Platform
- **Version:** 0.4.1 local product-surface refresh
- **Status:** Active BRD direction
- **Supersedes:** v0.3.0 provider/cloud-oriented deployment, storage, Hub, GPU, and explainability priorities; v0.4.0 local-first baseline product-surface gaps

## 1. Purpose

Define business requirements for a 100% local, plug-and-play, low-code data science toolkit powered by a Julia backend. The product is intended for users who cannot depend on cloud resources because of cost, academic procurement delays, offline environments, data residency concerns, or limited infrastructure support.

JuliaFlow must let users create and manage local projects, ingest data, explore it, prepare features, train and evaluate models, explain results, manage a local model registry, deploy local endpoints/jobs/packages, publish local dashboards, checkpoint work, and export reproducibility bundles without requiring cloud accounts, managed object stores, external registries, external APIs, telemetry, or cloud GPU provisioning.

## 2. Product Vision

JuliaFlow is a local analytics appliance for data science:

> A self-contained visual workflow environment that installs locally, initializes its own local data estate, uses local CPU/GPU hardware to the fullest safe extent, explains model behavior, and produces reproducible academic-grade artifacts without cloud dependency.

The product remains extensible enough for lab/team deployments and future cloud compatibility, but the default product promise is local-first.

## 3. Target Users

- **Academic researchers:** need reproducible workflows, explainable outputs, and local operation on lab machines.
- **Students and teaching labs:** need guided workflows, offline-friendly install, and transparent model behavior.
- **University labs:** need shared local servers where cloud procurement is slow or unavailable.
- **Small teams:** need professional data science tooling without cloud spend.
- **Public-sector or regulated users:** need data to remain on local hardware unless explicitly exported.
- **Senior/principal data scientists:** need custom Julia extensibility, hardware controls, auditability, and reproducibility.

## 4. Core Design Principles

1. **Local-first by default:** no cloud account, cloud credential, or managed provider is required for core use.
2. **Plug-and-play install:** a fresh machine can initialize the app, local data folders, local database, services, sample workflows, and health checks with minimal manual steps.
3. **Data stays local:** data, models, logs, checkpoints, dashboards, preferences, API keys, and extension artifacts remain on the local machine unless the user exports or syncs them intentionally.
4. **Hardware-aware execution:** JuliaFlow detects local CPU, memory, disk, and GPU capability and schedules work within safe resource limits.
5. **Explainable by design:** model behavior, feature influence, assumptions, limitations, and evaluation evidence are first-class workflow outputs.
6. **Reproducible by default:** every checkpoint can capture workflow definition, environment, data references, model artifacts, metrics, explainability outputs, and dashboard snapshots.
7. **Code-possible, not code-required:** low-code workflows remain primary, but users can inspect/export Julia representations and add governed custom Julia nodes.
8. **Local product surfaces are first-class:** Explorer, Data, Transform, ML Studio, Models, Deploy, Visualize, and Settings are product modules, not demo-only screens.

## 5. In Scope

### 5.1 Local Appliance Bootstrap

- One-command or installer-based startup for single-machine use.
- Local service initialization for frontend, API gateway, execution service, worker service, data estate, database, and Hub cache.
- Health checks for ports, filesystem permissions, database readiness, worker availability, CPU/GPU detection, and free disk space.
- Starter datasets and workflows that run fully offline after installation.
- Local workspace overview showing CPU/RAM/disk usage, local dataset/model/run counts, project browser, recent local activity, environment/package status, runtime summary, privacy status, workspace storage breakdown, and local compute configuration.
- Installation profiles:
  - `single-user`: filesystem data estate plus DuckDB analytics and lightweight local metadata.
  - `lab-team`: local PostgreSQL for metadata/RBAC/audit plus shared local data estate.
  - `s3-compatible-local`: optional MinIO profile for S3 API compatibility.
  - `developer`: hot-reload services and test fixtures.

### 5.2 Local Data Estate

JuliaFlow must create and manage a local data estate with stable folder zones:

- `raw/` for imported original files.
- `processed/` for cleaned datasets.
- `features/` for feature tables and derived datasets.
- `models/` for trained model artifacts.
- `runs/` for run logs, metrics, and intermediate outputs.
- `checkpoints/` for workflow and artifact snapshots.
- `dashboards/` for published local BI datasets.
- `logs/` for local audit and service logs.
- `extensions/` for bundled and locally installed Hub artifacts.

Durable analytical data should prefer Parquet for local columnar storage and Arrow IPC for runtime node payload exchange. DuckDB should be used for local analytical querying over local files and managed local tables.

### 5.3 Local Database Modes

JuliaFlow must support two local database modes:

- **Single-user mode:** DuckDB for analytics plus lightweight metadata persistence for workflow catalog, execution history, checkpoints, and settings.
- **Lab/team mode:** local PostgreSQL for concurrent metadata writes, users, workspaces, RBAC policies, audit logs, execution history, and shared workflow catalog.
- The v1.0 RC source-execution scope is deliberately narrower: confined `local_file` imports and managed-local (`local://`) artifacts are enabled. Watched-folder, SQLite, DuckDB, PostgreSQL, MySQL, USB, and cloud source execution remain visible only as disabled capabilities with explicit reasons until their connector-specific confinement, authorization, provenance, redaction, and negative tests are complete. PostgreSQL remains supported as the lab/team metadata backend; that does not imply PostgreSQL dataset-source execution.

DuckDB must not be treated as the only database for every multi-process service concern. PostgreSQL is preferred when multiple services or users need concurrent metadata writes.

### 5.4 CRISP-DM Workflow Coverage

JuliaFlow must cover:

- Business understanding: project brief, success criteria, constraints, assumptions.
- Data understanding: local file ingestion, schema inference, profiling, quality checks, bias/drift screens.
- Data preparation: filter, join, aggregate, pivot, type casting, missing-value handling, feature engineering.
- Modeling: baseline interpretable models, common regression/classification/clustering/time-series models, custom Julia nodes, CPU/GPU execution where supported.
- Evaluation: train/validation/test splits, cross-validation, metrics, error analysis, slice analysis, calibration.
- Deployment/output: local batch scoring, local dashboard publishing, model artifact export, reproducibility bundle export.

Cloud deployment is not required for v1 local-first GA.

### 5.5 Local Product Modules

JuliaFlow must provide a cohesive local application surface with the following modules.

#### 5.5.1 Explorer / Workspace

- Local workspace overview with system health, local environment, package status, runtime summary, storage breakdown, local project browser, and recent local activity.
- Project creation/opening, workspace path selection, active project metadata, and local project folder visibility.
- Local privacy/security status confirming offline mode, no telemetry, no remote compute, and no silent data transfer.
- Local compute controls showing CPU threads, BLAS/backend, GPU readiness, acceleration availability, and active jobs.

#### 5.5.2 Data

- Local data-source browser that enables confined local files and managed-local artifacts for v1.0 RC, while presenting watched-folder, SQLite, DuckDB, PostgreSQL, MySQL, USB, and cloud sources as disabled with explicit enablement requirements.
- Dataset view tabs for table, schema, profile, filters, sort, joins, transforms, sampling, and lineage.
- Column search, filter controls, page size, local refresh, local data profile, data-quality warnings, file path/size/modified metadata, and exportable column summary.
- Julia code preview for local data loading/profiling operations.
- Data handling status that confirms local-only storage, in-memory/local processing, and no uploads to external APIs.

#### 5.5.3 Transform

- Visual transformation pipeline canvas with run, validate, zoom, metrics, and per-step selection controls.
- Transform library grouped by cleaning, encoding, feature engineering, combine, and aggregate operations.
- Required built-in transform families include missing-value cleanup, duplicate removal, text trimming/standardization, outlier handling, type casting, categorical encoding, one-hot encoding, label/target encoding, date feature extraction, binning, mathematical transforms, lag/rolling windows, joins, unions, appends, grouping, pivots, and window aggregates.
- Transform settings panel with strategy options, per-column controls, preview-on-data action, and advanced settings.
- Before/after data preview, pipeline metrics, generated Julia code, logs, custom transform creation, and history/lineage view.

#### 5.5.4 ML Studio

- Local MLJ-centered training workspace for classification, regression, clustering, ranking, and time-series workflows where supported.
- Algorithm, model type, target column, split strategy, and shuffle controls.
- Feature selection, hyperparameter configuration, optional local auto-tuning, and train action with no remote compute.
- Metric cards and visual diagnostics including accuracy, F1, ROC AUC, precision, recall, log loss, ROC curve, confusion matrix, feature importance, metric comparison, and cross-validation evidence where applicable.
- Pipeline step visualization and local experiment tracker with searchable/filterable run history.
- Julia ecosystem visibility for installed modeling packages such as MLJ.jl, EvoTrees.jl, XGBoost.jl, Flux.jl, and comparable local Julia packages.

#### 5.5.5 Models

- Local model registry with search, filters, tags, owner, type, version, status, primary metric, update time, and local deployment status.
- Model import and train-new-model entry points.
- Model comparison across versions and models, performance-over-version charts, drift summary, and monitoring summary.
- Model detail panel with performance metrics, algorithm/framework, training data size, model path, local storage status, tags, artifacts, and training lineage.
- Artifact access for model binaries, metadata, metrics, and training configuration, with download/copy-path actions that never require a cloud registry.

#### 5.5.6 Deploy

- Local deployment targets for desktop app, REST API, batch inference job, local Docker container, edge device, and air-gapped package.
- Deployment pipeline stages for validate, build, test, package, staging-local deploy, and production-local deploy.
- Generated Julia API code using local Julia web tooling where appropriate.
- Local endpoint status with protocol, host, port, version, uptime, latency, throughput, error rate, and recent local request logs.
- Deployment configuration for environment variables, hardware, scaling, and security.
- Deployed artifacts, local runtime environment summary, local scaling summary, and explicit indicators for LAN-accessible, offline-capable, and this-machine-only modes.

#### 5.5.7 Visualize

- Local dashboard builder over local datasets with add chart, add text, save locally, export PNG, export HTML, and local-only share/export controls.
- Chart types include line, bar, area, scatter, histogram, pie, treemap, heatmap, map, gauge, table, and text.
- Chart properties panel with data, style, annotation, and advanced tabs.
- Dataset column browser, calculated-column creation, grid/auto/freeform layouts, snap-to-grid, filters, sorting, series configuration, and local data information.
- Dashboard-local Julia transform panel with runnable code, output selection, preview data, and local execution status.

#### 5.5.8 Settings

- Profile, workspace paths, project defaults, theme/accent/UI-density preferences, notifications, package environment, Julia version, compute resources, autosave, export preferences, security/privacy, access control, local API keys, and backups/snapshots.
- Workspace settings must keep data, models, cache, temp, exports, autosaves, and backups in explicit local paths.
- Project defaults must include default project location, data folder, model folder, new-project template, and default file format.
- Package environment settings must support local environments, local package mirrors, offline package use, and environment management.
- Julia settings must show active Julia version, executable path, compatibility status, and offline update checks.
- Security/privacy settings must expose no-telemetry, no-data-sharing, local logs only, and crash-report controls with private defaults.
- Access control must support single-user defaults, optional multi-user mode, workspace lock/passcode, and local-user allowance.
- Local API keys must be scoped to this device or LAN and should be managed without cloud key services.
- Backups/snapshots must support local automatic snapshots, retention settings, backup location, and create-now action.

### 5.6 Local Hardware Runtime

JuliaFlow must detect and report:

- CPU core count and thread capacity.
- Available RAM and memory pressure.
- Disk capacity and free working space.
- GPU availability, vendor, driver/runtime readiness, VRAM, and selected backend.
- CUDA readiness for NVIDIA systems where available.

Runtime requirements:

- CPU parallel execution with configurable worker counts.
- Memory-aware scheduling and bounded worker queues.
- GPU execution when a supported local GPU is available.
- CPU fallback when GPU is unavailable or unsupported.
- Explicit fallback reason in execution records.
- Multi-GPU execution only when the local machine actually has multiple visible GPUs.

### 5.7 AI Explainability And Model Transparency

Explainability is core scope.

JuliaFlow must support explainability outputs for applicable modeling workflows:

- Global feature importance.
- Local prediction explanation.
- Permutation feature importance for model-agnostic inspection.
- Partial dependence and individual conditional expectation style views where practical.
- Confusion matrix, residual/error analysis, calibration, and slice-level metrics.
- Baseline interpretable model comparison before opaque model promotion.
- Model card generation with inputs, metrics, data version, limitations, ethical caveats, and intended use.
- Dataset card generation with schema, lineage, missingness, sensitive columns, quality checks, and known limitations.
- Explanation export inside checkpoints and reproducibility bundles.
- Warnings when explainability is unavailable, unstable, expensive, or not meaningful for a selected model/data shape.

Explainability should be grounded in trustworthiness principles: transparency, interpretability, documentation, reproducibility, and auditability.

### 5.8 Offline Hub And Extension Management

JuliaFlow Hub must work without an external registry for core use:

- Bundled official extensions.
- Local extension folder install.
- Local artifact cache.
- Offline package mirror support.
- Checksum verification for extension artifacts.
- Sandboxed compatibility tests.
- Blocking of unsigned or unsafe local extensions by default.
- Optional external registry support only as a future compatibility path.

### 5.9 Security, Governance, And Local Trust Boundaries

Core security requirements:

- Local admin bootstrap.
- Local-only auth mode for single-user use.
- Optional lab/team RBAC.
- Local audit logs.
- No real secrets committed to project files.
- Encrypted local credential storage where credentials are used.
- Safe local filesystem path handling.
- Extension sandbox controls.
- Explicit data residency guarantee.
- No telemetry or data sharing by default.
- Local API keys and LAN access controls for local services.
- Workspace lock/passcode controls where local access control is enabled.

Cloud IAM, enterprise OIDC, and provider secret managers are optional extensions, not local-first GA requirements.

### 5.10 Backup, Restore, And Migration

JuliaFlow must support:

- Local data estate backup.
- Local database backup.
- Local automatic snapshots with configurable interval and retention.
- Checkpoint export/import.
- Workflow bundle export/import.
- Dashboard, model, package-environment, and settings export/import where needed for migration.
- Lab-machine migration path.
- Integrity checks for restored artifacts.

### 5.11 Academic Reproducibility Bundle

Every major run/checkpoint should be exportable as a reproducibility bundle containing:

- Workflow definition.
- Data references and checksums.
- Dataset/profile cards.
- Julia package/environment metadata.
- Random seeds and runtime configuration.
- Model artifact.
- Metrics and evaluation outputs.
- Explainability outputs.
- Dashboard snapshot.
- User notes and assumptions.

## 6. Out Of Scope For Local-First GA

The following are removed or downgraded from core GA:

- Provider-specific cloud deployment proof.
- AWS/GCS/Azure object-store proof.
- External Hub registry/provider mirror proof.
- Cloud IAM as a required dependency.
- Cloud GPU provisioning or cloud multi-GPU scheduling proof.
- Kubernetes/ArgoCD production overlays as a required product path.
- Real-time sub-second online inference at cloud scale.
- Full managed MLOps replacement.
- Hosted SaaS collaboration, cloud telemetry, cloud model registry, and remote managed inference as required product paths.

Optional/future:

- Kubernetes lab-server deployment.
- S3-compatible local MinIO profile.
- Cloud provider adapters.
- Enterprise OIDC/SSO.
- External registry sync.
- Optional connectors to GitHub, Slack, Amazon S3, remote databases, and similar services when explicitly enabled by the user or administrator.

## 7. Non-Functional Requirements

- **Local performance:** interactive previews under 2 seconds on sampled local data; batch workflows should use available CPU/GPU within configured resource caps.
- **Resource safety:** default worker limits must avoid exhausting RAM, VRAM, or disk.
- **Offline operation:** core workflows, bundled extensions, starter datasets, and sample runs must work without internet after installation media is available.
- **Reliability:** checkpointed runs, restartable services, and clear recovery prompts.
- **Portability:** Debian/Linux is the active development baseline; Windows and macOS remain product portability aspirations, with GPU support depending on platform/vendor maturity.
- **Usability:** guided mode for students/junior users, expert mode for advanced users, accessible canvas, clear error messages.
- **Security:** safe local defaults, explicit trust boundaries, no silent external uploads.
- **Maintainability:** package/version pinning, local diagnostics, health reports, and upgrade/migration checks.
- **Local UI completeness:** core local product modules must be usable without hidden cloud-only dependencies.

## 8. Architecture Direction

### 8.1 Default Local Architecture

- React/Vite frontend served locally.
- Julia API gateway.
- Julia execution service.
- Julia worker service.
- Local filesystem data estate.
- DuckDB for analytical query acceleration.
- File-backed or lightweight local metadata for single-user mode.
- Arrow IPC runtime payload boundary.
- Parquet/Arrow durable local artifacts.
- Offline Hub artifact cache.
- Local model registry, local deployment runtime, local dashboard artifacts, local package environment, and local settings store.

### 8.2 Lab/Team Architecture

- Same core services as default mode.
- Local PostgreSQL for metadata, RBAC, audit, execution history, and shared workflow catalog.
- Shared local data estate on workstation/server storage.
- Optional MinIO only when S3 API compatibility is needed.

### 8.3 Optional Compatibility Architecture

- Kustomize/Kubernetes, cloud providers, managed object stores, external registries, and enterprise identity providers remain optional future integrations.

## 9. Recommended Technology Choices

- **Runtime and services:** Julia, HTTP.jl, JSON3.jl, DataFrames.jl, Arrow.jl, Tables.jl.
- **Local analytics:** DuckDB for local OLAP and Parquet querying.
- **Metadata:** lightweight local metadata in single-user mode; PostgreSQL in lab/team mode.
- **Durable data:** Parquet for analytical tables; Arrow IPC for runtime payloads.
- **Low-code ML:** MLJ.jl ecosystem for model selection/training, with local package integrations such as EvoTrees.jl, XGBoost.jl, Flux.jl, and comparable Julia packages where appropriate.
- **Local API deployment:** Julia-native local web serving such as Genie.jl or HTTP.jl for generated local REST endpoints.
- **GPU:** CUDA.jl for NVIDIA, KernelAbstractions.jl for backend-portable kernels where practical.
- **Explainability:** model-native coefficients/importances, permutation importance, SHAP-style explanations where available, partial dependence/ICE style summaries where practical.
- **Packaging:** Docker Compose profiles for local service variants; future desktop packaging may evaluate Tauri/Electron plus Julia bundling constraints.

## 10. Success Metrics

- Fresh local install to first successful sample workflow in under 30 minutes.
- No cloud credentials required for core demo, EDA, modeling, dashboard, and checkpoint workflows.
- Local data estate initialized and health-checked automatically.
- At least one complete offline CRISP-DM workflow ships as a starter template.
- Explorer, Data, Transform, ML Studio, Models, Deploy, Visualize, and Settings modules expose local-first status and complete core workflows without internet.
- Users can import/profile local data, build transforms, train a local model, inspect the local registry, deploy a local endpoint or batch job, and build/export a dashboard without remote services.
- Reproducibility bundle exports and reimports successfully on another local install.
- GPU smoke runs when compatible hardware exists; CPU fallback is explicit when it does not.
- Model card and explanation outputs generated for supported modeling workflows.
- Local audit/dependency/security checks pass before release.

## 11. Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Hardware variability across academic machines | Install/run failures and inconsistent performance | Hardware profiler, preflight checks, conservative defaults, CPU fallback |
| GPU driver/CUDA mismatch | GPU workflows fail or confuse users | Driver/runtime diagnostics, CUDA smoke, clear fallback reasons |
| DuckDB concurrent write limits | Metadata corruption or service contention in team mode | Use DuckDB primarily for analytics; use PostgreSQL for lab/team metadata |
| Local disk exhaustion | Failed runs or corrupted artifacts | Quotas, cleanup tools, disk preflight, retention policies |
| Local data loss | Loss of research artifacts | Backup/restore workflow, checksum manifests, export bundles |
| Offline package availability | Install cannot complete without internet | Bundled official extensions, local artifact cache, offline mirror docs |
| Extension sandbox escape | Security incident on local machine | Signed/checksummed extensions, sandbox tests, safe defaults |
| Explainability misuse | Users overtrust explanations | Warnings, method notes, uncertainty/limitations in model cards |
| Cross-platform installer complexity | Poor adoption | Start with Docker Compose/local scripts, then mature desktop installers |
| Academic reproducibility gaps | Results cannot be defended or rerun | Environment capture, seeds, data checksums, model cards, export bundles |
| Mock/product surface drift | Product requirements omit visible local-app workflows | Keep BRD product modules aligned with mock designs and retire stale cloud-first assumptions |

## 12. Revised Implementation Priority

1. **Local appliance bootstrap:** one-command local stack, health checks, local folders, starter workflow.
2. **Local data estate proof:** filesystem zones, Parquet/Arrow roundtrip, DuckDB query path.
3. **Local metadata/database proof:** single-user metadata plus optional PostgreSQL lab/team mode.
4. **Local hardware runtime proof:** CPU scheduling, GPU detection, CUDA smoke when available, CPU fallback.
5. **Explainability and model evidence:** model cards, dataset cards, feature importance, local/global explanations, reproducibility bundle integration.
6. **Offline Hub proof:** bundled/local extensions, checksum verification, sandbox compatibility.
7. **Mock-aligned local product surface:** Explorer, Data, Transform, ML Studio, Models, Deploy, Visualize, and Settings requirements tracked as local-first product modules.
8. **Academic reproducibility workflow:** full offline EDA -> model -> explain -> dashboard -> export path.
9. **Backup/restore and migration:** local data estate and metadata portability.

## 13. Add / Remove / Rework Summary

### Add

- Local appliance install and health-check requirement.
- Managed local data estate.
- DuckDB local analytics path.
- PostgreSQL local lab/team mode.
- Offline Hub and extension cache.
- AI explainability and model transparency section.
- Dataset cards, model cards, and reproducibility bundles.
- Backup/restore and local migration.
- Hardware profiler and CPU/GPU fallback evidence.
- Mock-aligned local modules for Explorer, Data, Transform, ML Studio, Models, Deploy, Visualize, and Settings.
- Local model registry, local deployment runtime, local dashboard builder/export, local package environment, local API keys, autosave, and local snapshots.

### Remove From Core GA

- Provider-specific deployment proof.
- AWS/GCS/Azure object-store proof.
- External Hub registry/provider mirror proof.
- Cloud GPU and cloud multi-GPU closure.
- Cloud IAM/OIDC as a required dependency.
- Kubernetes/ArgoCD as required production path.
- Hosted SaaS collaboration, remote managed inference, cloud telemetry, and cloud model registries as required paths.

### Rework

- Object storage becomes local data estate first; MinIO is optional.
- Deployment becomes local appliance first; cloud is future compatibility.
- GPU closure becomes conditional local hardware validation.
- Hub registry becomes offline/local first.
- Security becomes local trust/data residency first, enterprise identity optional.
- Explainability becomes a release requirement for supported model workflows.
- Frontend surface becomes a required local product experience, not a temporary demo shell.

## 14. Source Notes

This baseline is informed by current public documentation and risk guidance:

- NIST AI Risk Management Framework for trustworthy AI, explainability, and transparency.
- DuckDB documentation on local analytics, Parquet support, extension security, and concurrency constraints.
- Apache Arrow documentation for columnar memory and IPC format.
- MinIO documentation on single-node single-drive limitations.
- CUDA.jl and KernelAbstractions.jl documentation for local GPU enablement and CPU/GPU backend strategy.
- scikit-learn model inspection documentation and SHAP-style explainability references for model explanation patterns.
