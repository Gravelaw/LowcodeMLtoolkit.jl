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
- Last updated: `2026-04-19`

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

### Extension / Node Pack

- Base extension path proven
- Starter representative nodes added/planned in extension lane:
  - passthrough
  - source
  - sink
  - transform
  - basic ML placeholder

### Verification Done

- `npm run test`
- `npm --workspace @juliaflow/frontend run build`
- `julia --project=. tests/julia/runtests.jl`

## Gaps Pending

### Phase 1 Critical Gaps

- BI path now has editable dashboard v0 authoring, but not yet a richer layout/composition/publish flow
- Streaming MVP lifecycle now exists in gateway/runtime, but not yet as a separate durable broker worker service
- GPU dispatch lane now exists for isolated batch worker routing, but no dedicated long-running GPU worker/runtime service exists yet
- Hub v0 skeleton now exists, but publish flow, compatibility matrix, enable/disable lifecycle hardening, and richer marketplace UX are still missing
- Node library breadth still far below Phase 1 target

### Quality / Delivery Gaps

- Remote CI and milestone tags still incomplete for some checkpoints
- Tracker/checkpoint habit only being formalized now
- Repo-wide caveman default is documented, but compliance still depends on session runtime honoring repo instructions and skill availability
- OpenAPI artifact still needs a refresh for the new graph/dashboard/runtime payload surface

## Next Items To Implement

### Next Priority

1. Ensure future sessions honor the new caveman-default repo instruction
2. Refresh OpenAPI for graph/dashboard/runtime payloads, including Hub v0 endpoints
3. Split streaming MVP from in-process gateway handling into a dedicated worker path
4. Deepen GPU lane from isolated dispatch queue into a dedicated worker/service process
5. Expand Hub v0 into compatibility matrix, publish flow, and richer extension management UX

### After That

1. Expand dashboard v0 into multi-panel layout/publish flow
2. Expand starter/base node pack depth toward Alpha node-library target
3. Add durable multi-process realtime/event backbone
4. Begin Beta security/RBAC contract slice

## Working Rule

Before any new job:

- read this tracker
- read latest checkpoint log
- confirm target gap being addressed

After any meaningful job:

- update `Work Done Till Date`
- update `Gaps Pending`
- update `Next Items To Implement`
