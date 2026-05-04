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

- Implement live refresh/cache invalidation and renderer/export UX, or move to production OIDC/RBAC / streaming MVP depending P0 priority
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

- Implement production streaming adapters/replay/exactly-once hardening or move to GPU execution MVP depending P0 priority
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

- Implement production CUDA/multi-GPU hardening or move back to production Arrow/DataFrames / OIDC hardening depending P0 priority
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

- Implement BI interaction hardening or move to production Arrow/DataFrames / OIDC hardening depending P0 priority
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

- Implement real Arrow/DataFrames object-storage adapters or move to production OIDC/RBAC depending P0 priority
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

- Implement deeper BI drilldown and richer viewer/export polish or move to production Arrow/DataFrames / OIDC hardening depending P0 priority
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

- Added `docs/next-steps-plan-2026-04-29.md` for future-session handoff.
- Plan records sanity/repo cleanup, GitHub integration checks, production Arrow/DataFrames adapter work, node scale 50 -> 75, BI polish, and production hardening lanes.
- Verified GitHub target with `gh repo view Gravelaw/LowcodeMLtoolkit.jl`; authenticated account has admin permission.
- Merged existing remote BRD/license documents into local `main` instead of force-pushing over GitHub history.

### Gaps Pending

- Repo cleanup still needs a dedicated pass for generated tracked artifacts, binary/design assets, and release-tag/CI hygiene.
- Package-backed Arrow/DataFrames object-storage adapter implementation remains pending.
- Node library still needs scale from 50 -> 75 -> 150 with stable/adapter-required test evidence.
- BI drilldown/viewer/export polish, production OIDC/RBAC, production streaming, production GPU, Hub hardening, observability/perf, and deployment hardening remain pending.

### Next Items To Implement

- Start next session with `docs/next-steps-plan-2026-04-29.md`.
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
- Added `docs/plans/next-p0-oidc-rbac-hardening-2026-05-03.md` with risk-aware execution plan and acceptance criteria.
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
