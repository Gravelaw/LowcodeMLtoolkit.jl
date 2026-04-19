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
- Inspector now supports manual connection add/remove actions
- Connection editor now previews compatibility errors for type mismatch, duplicate edges, and occupied target inputs
- Demo fallback still works when no gateway configured

### Runtime / Execution

- Execution accept path works through REST and realtime JSON-RPC
- Runtime inputs now supported for execute path:
  - `executionMode`
  - `flowVariables`
- Execution metadata and status history aligned closer to frontend contract
- Realtime gateway notifications now emit full node state set for canvas subscribe and workflow execute flows

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

- No real drag-and-drop node placement yet
- Inspector edits save through TOML serialization bridge, but not yet full durable graph editor model
- BI path is visible, but dashboard designer v0 not yet real
- Streaming MVP not yet real
- GPU support not yet real execution path
- Hub v0 not yet started
- Node library breadth still far below Phase 1 target

### Quality / Delivery Gaps

- Remote CI and milestone tags still incomplete for some checkpoints
- Tracker/checkpoint habit only being formalized now

## Next Items To Implement

### Next Priority

1. Deepen realtime state beyond current node/workflow pulse into richer execution lifecycle updates
2. Merge starter base extension node pack into active branch if not already present
3. Build minimal BI dashboard v0 shell from BI outlet path
4. Canvas drag/drop positioning
5. Deepen graph editor model beyond TOML bridge semantics

### After That

1. Canvas drag/drop positioning
2. Streaming MVP starter slice
3. GPU execution lane starter slice
4. Hub v0 skeleton

## Working Rule

Before any new job:

- read this tracker
- read latest checkpoint log
- confirm target gap being addressed

After any meaningful job:

- update `Work Done Till Date`
- update `Gaps Pending`
- update `Next Items To Implement`
