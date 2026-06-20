# Manual UI Review Backlog

Date started: 2026-06-20

Purpose: capture manual in-app browser review findings before converting them into Linear tickets. Keep each item concrete enough to turn into one issue or a small grouped issue.

## Review Scope

- App URL: `http://127.0.0.1:15173/`
- Runtime under review: local hosted JuliaFlow UI
- Review method: user manual walkthrough with browser annotations

## Backlog Triage

Status terms:

- `implemented locally, not yet ticketed`: a fix exists in the current working tree but still needs review, commit/PR routing, and a Linear decision.
- `partially implemented locally, not yet ticketed`: an immediate defect was fixed, but broader product work remains.
- `backlog`: no implementation has been started from this review item.

Recommended grouping before creating Linear tickets:

- Project creation and global shell: `UI-REVIEW-001`, `UI-REVIEW-002`, `UI-REVIEW-007`.
- Explorer local system and artifact evidence: `UI-REVIEW-003`, `UI-REVIEW-004`, `UI-REVIEW-005`, `UI-REVIEW-006`, `UI-REVIEW-008`.
- Data estate and backend/read-mode workflow: `UI-REVIEW-009`, `UI-REVIEW-010`.
- EDA, visualization, and ML lifecycle diagnostics: `UI-REVIEW-012`.
- Route resilience and live-mode empty states: `UI-REVIEW-011`.

Linear tickets created from this grouping:

- `AKS-23`: Manual UI review: project creation and global shell actions.
- `AKS-24`: Manual UI review: Explorer system health, artifacts, and compute settings.
- `AKS-25`: Manual UI review: Data estate source switching and full data workflow.
- `AKS-26`: Manual UI review: EDA and ML diagnostic visualization workspace.
- `AKS-27`: Manual UI review: route resilience and live-mode empty states.

Priority order:

1. Fix repo hygiene from this review pass: decide whether to keep or revert the temporary live-test `juliaflow-config.js` change before committing anything.
2. Keep the two small local fixes together only if the next PR is explicitly a review-cleanup PR: `+ New Project` dialog first slice and `ML Studio` empty live-state fix.
3. Ticket the larger product gaps as separate Linear work, with `UI-REVIEW-010` and `UI-REVIEW-012` treated as core data-science workflow epics rather than small UI polish.
4. Do not mark any BRD/TODO item complete from this manual backlog alone; completed P0/P1/P2 claims still require traceability and verification evidence.

## Current Repo Change Buckets

- `apps/frontend/src/App.tsx`, `apps/frontend/src/components/Shell.tsx`, `apps/frontend/src/views/ExplorerView.tsx`, `apps/frontend/src/styles.css`, `apps/frontend/src/types.ts`, and `apps/frontend/src/App.test.tsx`: AKS-23 implementation slice. This addresses `UI-REVIEW-001`, implements typed project name/description/folder path validation plus browser-granted target-folder scaffold writes for `UI-REVIEW-002`, records scaffolded project artifacts in the Explorer project browser, and gives the Grid/Share/Help/Profile top-bar controls useful local-first dialogs for `UI-REVIEW-007`. A gateway-native scaffold endpoint remains optional if service-owned typed-path writes are required later.
- `apps/frontend/src/views/MlStudioView.tsx` and `apps/frontend/src/App.test.tsx`: local empty-state and partial-metric guards for missing or incomplete ML experiment records. This addresses the immediate blank-screen failures found under `UI-REVIEW-011`, but route-level error boundaries and full live-payload hardening remain open.
- `docs/manual-ui-review-backlog.md`: this manual-review backlog. Keep it as discovery/planning evidence until Linear tickets are created.
- `apps/frontend/public/juliaflow-config.js`: temporary live browser testing override to point at `http://127.0.0.1:18088` and `local-appliance`. This should be reverted before a normal product PR unless we intentionally want to change the default shipped runtime from demo to local appliance.

## Findings

### UI-REVIEW-001 - `+ New Project` Needs A Real Dialog

- Status: implemented locally, tracked by `AKS-23`
- Module: global top bar / Explorer entry point
- Annotated element: `+ New Project`
- Page: `http://127.0.0.1:15173/`
- Problem: clicking `+ New Project` only showed inline feedback and did not open a concrete project-creation surface.
- Expected behavior: clicking `+ New Project` should open a dialog where the user can see where the project will be created and choose whether to proceed.
- Notes: local implementation now adds a `Create New Project` dialog with project template, workspace, profile, metadata backend, workflow version, `Cancel`, and `Create Local Project` actions. `AKS-23` carries the broader project-creation and shell-action follow-up.

### UI-REVIEW-002 - New Project Dialog Needs Project Name, Description, And Folder Path Inputs

- Status: implemented locally, tracked by `AKS-23`
- Module: global top bar / New Project dialog
- Annotated element: `Create New Project` dialog
- Page: `http://127.0.0.1:15173/`
- Problem: the dialog shows the current template/workspace metadata, but the user cannot enter a new project name, add a project description, or choose/specify where the project will be created.
- Expected behavior: the dialog should let the user enter a project name, add a short project description, and specify the target folder path for the new local project.
- Notes: local implementation now supports typed project name, required description, typed local folder path, reserved-character/path-traversal/collision validation, browser target-folder grants where supported, filesystem scaffold writes through the File System Access API, workflow rename, and scaffold artifact rows in Explorer. Typed paths remain a staged fallback when the browser cannot grant write access. A gateway-native scaffold endpoint and recent-location history can be added later if required.

### UI-REVIEW-003 - Explorer Hardware Metrics Must Poll Live Hardware State

- Status: backlog
- Module: Explorer / Local Workspace Overview
- Annotated element: CPU Usage, RAM Usage, and Disk Space metric cards
- Page: `http://127.0.0.1:15173/`
- Problem: the CPU, RAM, and disk cards currently show static values, so changes in local hardware usage are not reflected in the dashboard.
- Expected behavior: these cards should poll live local hardware state and update the displayed CPU usage, RAM usage, disk capacity/free space, and supporting details without requiring a page reload.
- Notes: implementation should define the polling source and cadence, likely through the local gateway health/hardware endpoint or a dedicated hardware metrics endpoint. It should handle unavailable metrics with clear fallback text, avoid excessive polling, and keep the UI stable while values update.

### UI-REVIEW-004 - Explorer Privacy And Security Card Feels Irrelevant To The Project

- Status: backlog
- Module: Explorer / Local Workspace Overview
- Annotated element: `Privacy & Security (Local-First)` card
- Page: `http://127.0.0.1:15173/`
- Problem: the card reads as generic product reassurance and does not feel relevant to the current project context.
- Expected behavior: replace or revise this section so it provides project-specific local trust/security information, or remove it from the Explorer project overview if it does not support the user's current workflow.
- Notes: candidate replacements include project data locations, local artifact boundaries, active credentials/auth state, dataset privacy flags, local backup status, or links to Settings security details. Avoid generic marketing copy in the operational Explorer dashboard.

### UI-REVIEW-005 - Consolidate Explorer Hardware Metrics With System Health

- Status: backlog
- Module: Explorer / Local Workspace Overview
- Annotated element: `System Health` card and top CPU/RAM/Disk metric cards
- Page: `http://127.0.0.1:15173/`
- Problem: the dashboard shows CPU, RAM, and disk metrics twice: once as top metric placards and again inside the `System Health` card.
- Expected behavior: consolidate hardware/system metrics into one coherent area. Either move the CPU/RAM/Disk placards into the `System Health` widget, or move/promote the `System Health` widget upward so it becomes the primary hardware summary.
- Notes: coordinate this with `UI-REVIEW-003`, since live polling should update the consolidated metrics in one place rather than maintaining duplicate displays.

### UI-REVIEW-006 - Local Project Browser Needs Hierarchical Artifact View And Open Actions

- Status: backlog
- Module: Explorer / Local Project Browser
- Annotated element: `Local Project Browser` card
- Page: `http://127.0.0.1:15173/`
- Problem: artifacts are shown as a flat table of long paths, which makes the project structure hard to scan and does not provide a direct way to open a folder or artifact location.
- Expected behavior: replace or augment the flat table with a clearer artifact/path browser, such as a hierarchical folder tree, grouped artifact categories, or expandable path rows.
- Notes: include small open-folder/open-directory actions where appropriate. The design should make artifact locations, file types, sizes, and status easy to scan without horizontal scrolling.

### UI-REVIEW-007 - Top-Bar Utility Buttons Need Purposeful Actions Or Dialogs

- Status: implemented locally, tracked by `AKS-23`
- Module: global top bar
- Annotated element: `Grid`, `Share`, `?`, and avatar buttons
- Page: `http://127.0.0.1:15173/`
- Problem: the top-bar utility buttons appear clickable but do not provide useful user-facing behavior.
- Expected behavior: each visible utility action should either open a useful screen/dialog or be removed until it has a real purpose.
- Planning notes:
  - `Grid`: could open a project/app switcher, module launcher, or dashboard layout selector.
  - `Share`: in local-first mode should open a local export/share dialog, such as project bundle export, reproducibility bundle, backup package, or copy local project path. It should not imply cloud sharing unless configured.
  - `?`: should open contextual help for the current module, including what the screen shows, common actions, and links to local docs.
  - Avatar: should open a local profile/workspace menu with profile, auth mode, local home, settings shortcut, and possibly sign-out/lock actions if auth is enabled.
- Notes: these actions should be tied to concrete local-first workflows and should avoid placeholder toasts. Consider grouping this into one Linear epic with separate child tickets per top-bar action if the scope grows.
- Local implementation: Grid opens a module launcher, Share opens local export/share actions, Help opens workspace guidance with Settings shortcut, and the avatar opens local profile/runtime details. Deeper export execution, contextual per-module docs, and auth-aware profile actions remain open if `AKS-23` scope expands.

### UI-REVIEW-008 - Local Compute Settings Must Be Functional And Reflected In Workflows

- Status: backlog
- Module: Explorer / Local Compute and Settings / Compute And Autosave
- Annotated element: `Local Compute` card
- Page: `http://127.0.0.1:15173/`
- Problem: the `Local Compute` card displays compute backend, threads, BLAS, and GPU/CPU fallback values, but it is unclear whether these are connected to Settings or whether changing Settings affects application performance or data-science workflows.
- Expected behavior: compute-related settings should be configurable in Settings, reflected back in Explorer, and applied to relevant workflow execution paths such as transforms, ML training, model registration, and runtime scheduling.
- Verification needed: confirm whether current Settings controls mutate any persisted runtime configuration, whether the gateway/workers consume that configuration, and whether workflow execution records show the selected backend/thread/GPU/BLAS policy.
- Notes: if the current card is read-only/static, create implementation work to add real settings persistence, runtime propagation, and user-visible execution evidence. Include unavailable/unsupported hardware states when GPU or BLAS choices cannot be applied.

### UI-REVIEW-009 - Data Local Source Selector Needs Clear Backend Semantics And Real Switching

- Status: backlog
- Module: Data / Local Source Selector
- Annotated element: `Local Source Selector`
- Page: `http://127.0.0.1:15173/data`
- Problem: the selector shows CSV file, Arrow IPC, and DuckDB view options, but it is unclear what selecting them does or whether the user can actually switch between local storage/query backends.
- Expected behavior: clarify whether this control selects data source format, query backend, persistent compute backend, or read path. If it is meant to switch modes, selecting CSV/Arrow/DuckDB should update the active data read/query path and visibly change the downstream preview/profile/evidence.
- Verification needed: determine whether the current UI is static, whether it calls any gateway endpoint, and whether DuckDB/Arrow selections affect reads, profiling, transforms, or persisted local artifacts.
- Notes: possible model: CSV as raw source, Arrow IPC as fast in-memory/inter-node boundary, DuckDB as persistent local query/compute view. The UI should expose status, current active selection, and backend-specific capabilities/limitations rather than listing all options as inert cards.

### UI-REVIEW-010 - Data Dashboard Needs A Complete Data Science And Data Engineering Workflow

- Status: backlog
- Module: Data dashboard
- Annotated element: full `Data` page
- Page: `http://127.0.0.1:15173/data`
- Problem: the Data dashboard still feels incomplete for practical data-science and data-engineering work. It shows a source selector, sample rows, profile summary, field quality, guarantees, and generated code, but it lacks the interactive workflow needed to ingest, validate, profile, compare, transform-readiness-check, and route datasets through the rest of the app.
- Expected data-science capabilities:
  - dataset selection and switching across multiple imported datasets
  - schema inference with column types, nullable counts, distinct counts, missing values, outliers, target/label selection, and feature-role assignment
  - distribution summaries and quick plots for numeric/categorical/date columns
  - train/test split preview, leakage checks, target balance, and modeling-readiness warnings
  - ability to mark columns as ID, feature, label, timestamp, sensitive, ignored, or derived
- Expected data-engineering capabilities:
  - import wizard for local CSV/Parquet/Arrow/SQLite/DuckDB paths and optional Kaggle download/import
  - storage mode selection with clear semantics: raw source, Arrow IPC artifact, Parquet artifact, DuckDB table/view
  - artifact lineage showing raw -> processed -> features paths with checksums and row counts
  - data quality rules, validation results, failed-row samples, and quarantine/retry states
  - refresh/re-profile action, persist-as-Arrow/Parquet action, register-DuckDB-view action, and open artifact folder action
  - connection between selected dataset and downstream Transform, ML Studio, Visualize, and Deploy workflows
- Candidate Kaggle test datasets:
  - `barun2104/telecom-churn` (`telecom_churn.csv`, about 129 KB): small binary classification dataset for import, profiling, target selection, feature typing, transform, ML training, model evidence, and dashboard checks.
  - `abbas829/global-superstore-sales-dataset` (`Global Superstore.csv`, about 12.4 MB): transactional sales dataset for larger CSV import, DuckDB querying, date/category/numeric profiling, aggregations, visualization, export, and performance checks.
- Notes: use these two datasets as acceptance fixtures for the end-to-end workflow. The Data dashboard should make it obvious which dataset is active, which local artifacts were created, which backend/read mode is active, and what next action the user can take.

### UI-REVIEW-011 - Module Routes Need Empty Live States And Route-Level Crash Containment

- Status: partially implemented locally, tracked by `AKS-27`
- Module: global route shell / ML Studio / all modules
- Observed page: `http://127.0.0.1:15173/visualize`
- Problem: while assessing the current app state, the browser showed a blank screen even though the frontend and gateway ports were still listening. The runtime error came from `MlStudioView` reading `experiment.modelKind` when live local-appliance data had no ML experiment records.
- Immediate local fix: `ML Studio` now renders a `No ML Experiments Yet` empty state when the backend returns an empty experiment list, displays `n/a` for missing optional metrics instead of crashing, and the existing local-appliance empty-list regression test now covers this route. AKS-27 now also adds route-level crash containment, shared table row guards, and empty-state coverage for Models, Deploy, Settings, Transform, Monitor, Visualize, and ML Studio.
- Expected behavior: every module should handle empty or incomplete live backend payloads with an actionable unavailable/empty state. A single module card or route should not be able to blank the whole shell.
- Follow-up needed: add route-level error boundaries around module views, review all module views for first-item assumptions, and align unavailable-state copy with runtime mode so release/local-appliance modes show recovery guidance instead of demo fixture content.

### UI-REVIEW-012 - Visualize Must Support EDA And ML Diagnostic Workflows, Not Just Dashboard Snapshots

- Status: backlog
- Module: Visualize / Data / ML Studio
- Annotated element: full `Visualize` page
- Page: `http://127.0.0.1:15173/visualize`
- Problem: the current Visualize page is framed as a dashboard snapshot/export surface. That is not enough for a data-science and ML lifecycle because users also need exploratory analysis, model diagnostics, and training/evaluation visualizations.
- Expected EDA visualization capabilities:
  - column-level distribution charts for numeric, categorical, datetime, and boolean fields
  - missing-value heatmap or matrix, null-rate bars, and duplicate/uniqueness checks
  - correlation matrix, pairwise scatter/hexbin views, grouped summaries, and outlier plots
  - target/label balance, class stratification, leakage hints, and feature-role overlays
  - filter/slice controls so users can inspect segments before training or transformation
- Expected ML diagnostic visualization capabilities:
  - train/validation learning curves and bias/variance tradeoff views
  - ROC, precision-recall, confusion matrix, calibration, residuals/error distribution, and threshold tuning
  - feature importance, SHAP/partial dependence style explanations where supported locally
  - experiment comparison across algorithms, seeds, folds, hyperparameters, and hardware backends
  - drift/performance monitoring charts that connect trained models to later Monitor results
- Product shape:
  - Visualize should likely become a multi-mode workspace with tabs such as `EDA`, `Dashboard`, `Model Diagnostics`, and `Experiment Compare`, or the app should split EDA/diagnostics into dedicated screens while keeping Visualize for publishable dashboards.
  - Data should feed EDA directly after import/profile, and ML Studio should feed diagnostics after training.
  - Dashboard export should remain, but it should be only one workflow, not the whole visualization story.
- Verification needed: inspect current gateway/contracts for available profile, experiment, metric, and dashboard payloads. Add or extend contracts only if existing payloads cannot represent EDA chart specs and ML diagnostic artifacts.
- Notes: acceptance should include at least the churn classification dataset and the Superstore transactional dataset from `UI-REVIEW-010`, with EDA charts generated before modeling and model diagnostic charts generated after training.

## Pending Annotations

Add new findings below this line as browser annotations come in.
