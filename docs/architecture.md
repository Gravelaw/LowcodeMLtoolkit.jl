# JuliaFlow Architecture Overview

## Planes

- User plane: React frontend in `apps/frontend/`
- Contract plane: shared workflow schema, OpenAPI, JSON-RPC, event contracts in `packages/contracts/`
- Execution plane: Julia node SDK and execution planner in `services/node-sdk/` and `services/execution-service/`
- API plane: gateway stub in `services/api-gateway/`
- Extension plane: official and partner node packs under `extensions/`
- Infra plane: local compose, Kubernetes, GitOps, CI in `infra/` and `.github/workflows/`

## Foundation Decisions

- Workflow definitions are TOML-backed and validated against shared schema
- Inter-node payload boundary is Arrow IPC only
- Execution planner is CPU-first in Phase 0 and ready for GPU affinity expansion
- Checkpoints gate risky work through tags, release notes, and rollback evidence

## Next BRD Expansions

- Add persistence and execution state stores
- Add WebSocket runtime hub and streaming runtime
- Add BI outlet to SSE update path
- Add extension compatibility matrix and Hub publish flow

## Persona-Driven Architecture Direction

The daily local-workstation persona review adds a new architecture constraint before deeper Data, Transform, ML Studio, Models, Monitor, and Deploy work:

- Add a contract-first `DataScienceProject` aggregate in `packages/contracts/` for dataset roles, schema/type overrides, validation/test strategy, statistical EDA runs, feature pipeline refs, training/tuning/evaluation records, prediction exports, model lifecycle, and drift reports.
- Keep route views as projections over the shared project state rather than independent owners of dataset, transform, experiment, registry, and monitor state.
- Split `services/api-gateway/src/JuliaFlowApiGateway.jl` product-depth logic into focused internal modules for health, chart specs, data catalog, statistical analysis, experiments, registry, monitoring, and route dispatch before adding persona features.
- Preserve local-first trust boundaries for file/folder/database source access, including root confinement, explicit disabled states, local credential policy, and audit events.

Architecture review sources: `docs/persona-architecture-review.md` and `docs/principal-persona-readiness-review.md`. The principal review blocks implementation readiness until the `DataScienceProject` substrate, internal gateway module split, typed jobs, validity gates, and local trust-boundary hardening are complete.

