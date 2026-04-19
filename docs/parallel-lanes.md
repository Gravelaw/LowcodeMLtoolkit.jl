# Parallel Lane Ownership

## Rule

Freeze shared contracts before widening agent swarm. Contract changes land only on checkpoint branches with explicit review.

## Lanes

- Lane A: `apps/frontend/`, `packages/ui/` for canvas, dashboard designer, config dialogs
- Lane B: `packages/contracts/openapi/`, `services/api-gateway/` for REST and auth gateway
- Lane C: `services/execution-service/`, `services/node-sdk/` for planner, worker protocol, Arrow IPC
- Lane D: `extensions/` for official node packs after SDK freeze
- Lane E: streaming runtime and checkpoint service once execution events freeze
- Lane F: BI service and semantic layer once BI outlet contract freezes
- Lane G: Hub service and compatibility matrix
- Lane H: `infra/`, `.github/workflows/`, `scripts/` for DevEx, deploy, observability

## Merge Guardrails

- One lane owns one write set
- Generated clients and source contracts never change in same unreviewed patch
- Checkpoint tags mark safe rollback points before cross-lane merges

