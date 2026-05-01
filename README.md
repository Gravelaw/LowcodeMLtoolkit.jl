# JuliaFlow

JuliaFlow is a monorepo for a visual low-code analytics platform built in Julia. This repository now reflects the Phase 1 / Alpha core slice from the BRD execution plan:

- React frontend authoring workspace with draft editing, realtime status sync, dashboard v0, and Hub v0 controls
- Shared workflow contracts, OpenAPI spec, and JSON-RPC protocol docs
- Typed TypeScript gateway client for frontend and integration lanes
- Julia node SDK, execution service with graph/dashboard/runtime models, and repository-backed HTTP gateway with realtime and Hub routes
- CI workflow, checkpoint script, ADR, and local development scaffolding

## Repository Layout

- `apps/frontend/` React + Vite application shell
- `packages/contracts/` shared TypeScript contracts and protocol specs
- `packages/ui/` shared React UI primitives
- `services/node-sdk/` Julia node SDK interfaces and helpers
- `services/execution-service/` Julia execution planner and CPU-only runner
- `services/worker-service/` worker-lane lifecycle service for streaming and GPU dispatch orchestration
- `services/api-gateway/` Julia API gateway, repository abstraction, file store adapter, PostgreSQL adapter, and HTTP surface
- `extensions/base/` official starter base node pack with 150 stable Tier-1 nodes plus local and remote-service Arrow/DataFrames materialization
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
julia --project=. scripts/run-stream-worker.jl
julia --project=. scripts/run-gpu-worker.jl
```

Frontend can target a live Julia gateway during local dev:

```bash
VITE_JULIAFLOW_GATEWAY_BASE_URL=http://127.0.0.1:8088 npm run dev:frontend
```

To exercise the out-of-process streaming lane, start gateway in process mode and run the stream worker in a second shell:

```bash
JULIAFLOW_STREAM_WORKER_MODE=process julia --project=. scripts/run-api-gateway.jl
julia --project=. scripts/run-stream-worker.jl
```

GPU lane worker:

```bash
julia --project=. scripts/run-gpu-worker.jl
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
- `GET /api/v1/hub/extensions`
- `POST /api/v1/hub/extensions/{extensionId}/install`
- `WebSocket /api/v1/realtime`

Streaming note:

- `JULIAFLOW_STREAM_WORKER_MODE=inline` keeps stream activation inside gateway for fast local dev
- `JULIAFLOW_STREAM_WORKER_MODE=process` queues stream executions for `scripts/run-stream-worker.jl`
- gateway durable event consumer now fans out worker-driven state changes over realtime when event backbone is enabled
- queued GPU executions can be promoted by `scripts/run-gpu-worker.jl`, with gateway consuming worker durable events for realtime rebroadcast
