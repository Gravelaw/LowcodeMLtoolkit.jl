# JuliaFlow

JuliaFlow is a monorepo foundation for a visual low-code analytics platform built in Julia. This repository now contains Phase 0 bootstrap assets from the BRD execution plan:

- React frontend shell for workflow canvas and milestone dashboard
- Shared workflow contracts, OpenAPI spec, and JSON-RPC protocol docs
- Typed TypeScript gateway client for frontend and integration lanes
- Julia node SDK, CPU-first execution service prototype, repository-backed HTTP gateway, and PostgreSQL-ready persistence adapter
- CI workflow, checkpoint script, ADR, and local development scaffolding

## Repository Layout

- `apps/frontend/` React + Vite application shell
- `packages/contracts/` shared TypeScript contracts and protocol specs
- `packages/ui/` shared React UI primitives
- `services/node-sdk/` Julia node SDK interfaces and helpers
- `services/execution-service/` Julia execution planner and CPU-only runner
- `services/api-gateway/` Julia API gateway, repository abstraction, file store adapter, PostgreSQL adapter, and HTTP surface
- `extensions/base/` placeholder for official base node pack
- `infra/` local compose and Kubernetes scaffolding
- `docs/` ADRs, checkpoints, architecture notes
- `tests/` contract and Julia test entry points

## Tooling

- Node.js `25.9.0`
- npm workspaces used for bootstrap because `pnpm` is not installed in current environment
- Julia `1.12.6`

## Commands

```bash
npm install
npm run dev:frontend
npm run build
npm run test
julia --project=. tests/julia/runtests.jl
julia --project=. scripts/run-api-gateway.jl
```

Frontend can target a live Julia gateway during local dev:

```bash
VITE_JULIAFLOW_GATEWAY_URL=http://127.0.0.1:8088 npm run dev:frontend
```

## Checkpoints

Use checkpoint script to capture tagged milestones with release note stubs:

```bash
./scripts/create-checkpoint.sh cp/00-foundation
```

See [docs/checkpoints.md](/home/akshayrj00/my_project/docs/checkpoints.md) for required evidence before tagging.

## Gateway

Foundation gateway starts from local workflow fixture and persists workflows, checkpoints, and execution jobs under `tmp/gateway-store` by default.

```bash
julia --project=. scripts/run-api-gateway.jl
```

Backend selection:

```bash
JULIAFLOW_GATEWAY_BACKEND=file julia --project=. scripts/run-api-gateway.jl
JULIAFLOW_GATEWAY_BACKEND=postgres \
JULIAFLOW_DATABASE_URL='postgresql://user:pass@localhost:5432/juliaflow' \
julia --project=. scripts/run-api-gateway.jl
```

Browser access for local frontend dev is enabled with permissive CORS by default. Override origin if needed:

```bash
JULIAFLOW_CORS_ALLOW_ORIGIN=http://127.0.0.1:5173 julia --project=. scripts/run-api-gateway.jl
```

Routes available now:

- `GET /health`
- `GET /api/v1/workflows`
- `POST /api/v1/workflows`
- `POST /api/v1/workflows/import`
- `GET /api/v1/workflows/{workflowId}`
- `PUT /api/v1/workflows/{workflowId}`
- `POST /api/v1/workflows/{workflowId}/execute`
- `GET /api/v1/executions`
- `GET /api/v1/executions/{executionId}`
- `POST /api/v1/executions/{executionId}/status`
- `GET /api/v1/checkpoints`
- `POST /api/v1/checkpoints`
