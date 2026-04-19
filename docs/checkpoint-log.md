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
- Test suite green after gateway regression fixes

### Gaps Pending

- BI dashboard path now supports basic editing, but not yet multi-panel layout/publish/share behavior
- Streaming MVP runtime implementation still missing beyond contract shape
- GPU worker lane still missing beyond planner/resource metadata
- Hub v0 still missing
- Durable multi-process event backbone still missing even though in-process subscriber broadcast exists
- Repo instruction change depends on session runtime loading repo instructions and the caveman skill remaining available

### Next Items To Implement

- ensure future sessions honor caveman-default repo instruction
- broker-backed streaming MVP execution slice
- isolated GPU worker lane using existing resource-plan contract
- Hub v0 extension catalog/install skeleton
- OpenAPI refresh for expanded payloads
