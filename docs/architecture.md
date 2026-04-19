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

