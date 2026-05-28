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
