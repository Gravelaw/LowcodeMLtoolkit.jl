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
- Manual connection authoring/removal delivered in inspector
- Compatibility preview now blocks invalid edge types, duplicate edges, and occupied target inputs
- Test suite green after gateway regression fixes

### Gaps Pending

- Drag/drop node placement not built
- Realtime execution lifecycle still shallow beyond current workflow/node pulse
- BI dashboard v0 still missing
- Streaming MVP still missing
- GPU lane still missing
- Hub v0 still missing

### Next Items To Implement

- deepen realtime execution/event model
- merge/use starter node pack expansion
- minimal BI dashboard v0
