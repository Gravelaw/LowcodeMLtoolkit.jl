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
- BRD: `JuliaFlow_BRD_v1.0.docx`
- Current target phase: `Phase 1 / Alpha`
- Current checkpoint path: `cp/00-foundation -> cp/01-contracts-frozen -> cp/02-alpha-core`
- Last updated: `2026-04-29`

## Work Done Till Date

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
- Checkpoint docs started:
  - [cp-00-foundation](/home/akshayrj00/my_project/docs/releases/cp-00-foundation.md)
  - [cp-01-contracts-frozen](/home/akshayrj00/my_project/docs/releases/cp-01-contracts-frozen.md)

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
- Confirmed current Alpha P0 order remains:
  1. production Arrow/DataFrames object-storage materialization and node scale-up
  2. deeper BI drilldown/viewer/export polish
  3. production OIDC/JWT/RBAC and persisted policy/audit query surfaces
  4. production streaming adapters/replay/exactly-once hardening
  5. production CUDA/KernelAbstractions and multi-GPU hardening
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

- Added `docs/next-steps-plan-2026-04-29.md` so future sessions can resume from the post-50-node baseline.
- Plan includes sanity/repo cleanup, GitHub integration checks, production Arrow/DataFrames adapter work, node scale 50 -> 75, BI polish, and production hardening lanes; generated `*.tsbuildinfo` files are ignored and the UI/UX archive is kept under `docs/assets/`.
- GitHub target repository verified with `gh repo view Gravelaw/LowcodeMLtoolkit.jl`; authenticated account has admin permission.

## Gaps Pending

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

### Next Priority

1. Complete sanity/repo cleanup from `docs/next-steps-plan-2026-04-29.md`, then implement package-backed Arrow/DataFrames object-storage adapters on top of the new reader/writer seam and continue node scale 50 -> 75 -> 150
2. Implement deeper BI drilldown and richer viewer/export polish
3. Harden Auth/RBAC with production OIDC/JWT, persisted policy, and audit events
4. Implement production streaming adapters/replay/exactly-once hardening
5. Implement production CUDA/multi-GPU hardening for GPU execution path

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
