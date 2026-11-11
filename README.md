# JuliaFlow

JuliaFlow is a monorepo for a visual low-code analytics platform built in Julia. This repository now reflects the Phase 1 / Alpha core slice from the BRD execution plan:

- React frontend authoring workspace with draft editing, realtime status sync, dashboard v0 drilldown/export viewer, and Hub v0 controls
- Shared workflow contracts, OpenAPI spec, and JSON-RPC protocol docs
- Typed TypeScript gateway client for frontend and integration lanes
- Julia node SDK, execution service with graph/dashboard/runtime models, and repository-backed HTTP gateway with realtime and Hub routes
- CI workflow, checkpoint script, ADR, and local development scaffolding

## Repository Layout

The product spec is [docs/spec/PRODUCT.md](docs/spec/PRODUCT.md); tasks are
tracked in GitHub Issues and the repository GitHub Project. Agent/tooling procedures are documented in
[docs/agent-tooling.md](docs/agent-tooling.md). Superseded concept BRDs and
historical control documents are preserved in indexed archives
([2026-09-20](docs/archive/2026-09-20/README.md),
[2026-11-11](docs/archive/2026-11-11-pre-product-spec/README.md)); their readiness statements
refer to their recorded versions, not the current checkout.

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

- Native Windows PowerShell or Debian-compatible Linux shell
- Node.js via native Windows Node or native Linux/nvm Node; run `npm run doctor:windows` or `npm run doctor:debian` to verify
- npm workspaces used for bootstrap because `pnpm` is not installed in current environment
- Julia compatible with `Project.toml`, either on PATH or provided through `JULIAFLOW_JULIA_CMD`
- Julia manifests are generated, not committed; use `npm run julia:instantiate` or `julia --project=. -e "using Pkg; Pkg.instantiate()"` from a fresh checkout

## Commands

```bash
npm install
npm run doctor:windows
npm run doctor:debian
npm run julia:instantiate
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

See [docs/spec/PRODUCT.md](docs/spec/PRODUCT.md) for the roadmap and next implementation items.

## Gateway

Foundation gateway starts from local workflow fixture and persists workflows, checkpoints, and execution jobs under `tmp/gateway-store` by default.

```bash
julia --project=. scripts/run-api-gateway.jl
```

Gateway auth modes remain explicit for local and production-hardening paths:

```bash
# local/dev default: dev_token, or disabled for trusted local-only smoke tests
JULIAFLOW_AUTH_MODE=dev_token JULIAFLOW_DEV_AUTH_TOKEN=dev-secret julia --project=. scripts/run-api-gateway.jl

# production-hardening OIDC/JWKS path using discovery metadata + HS256 JWKS fixtures
JULIAFLOW_AUTH_MODE=oidc \
JULIAFLOW_OIDC_DISCOVERY_PATH=/path/to/openid-configuration.json \
JULIAFLOW_OIDC_AUDIENCE=juliaflow-gateway \
JULIAFLOW_OIDC_ALLOWED_ALGORITHMS=HS256 \
julia --project=. scripts/run-api-gateway.jl
```

OIDC discovery/JWKS support is mockable and tested for key rotation. Live IdP RSA/JWKS hardening and admin UI surfaces remain open; track them as GitHub issues.

Live Keycloak + PostgreSQL auth smoke evidence:

```bash
./scripts/smoke-keycloak-postgres-auth.sh
```

The smoke provisions Keycloak/PostgreSQL from `infra/docker/compose.dev.yml`, obtains a real RS256 token, starts the gateway with `JULIAFLOW_GATEWAY_BACKEND=postgres`, exercises protected auth directory/policy/audit routes, and prints JSON evidence.

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

Streaming live Kafka smoke:

```bash
./scripts/smoke-kafka-streaming.sh
```

The smoke uses the dev Compose Kafka broker, captures consumed records into JSONL, then drives Julia committed-offset replay and fenced sink idempotency proof.

GPU CUDA/KernelAbstractions smoke:

```bash
# one-device smoke; useful evidence, not enough for final multi-GPU closure
JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=0 julia --project=. scripts/smoke-cuda-kernel.jl

# final hardware-gated phase; requires >=2 visible CUDA devices
JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1 julia --project=. scripts/smoke-cuda-kernel.jl
```

Streaming note:

- `JULIAFLOW_STREAM_WORKER_MODE=inline` keeps stream activation inside gateway for fast local dev
- `JULIAFLOW_STREAM_WORKER_MODE=process` queues stream executions for `scripts/run-stream-worker.jl`
- gateway durable event consumer now fans out worker-driven state changes over realtime when event backbone is enabled
- queued GPU executions can be promoted by `scripts/run-gpu-worker.jl`, with gateway consuming worker durable events for realtime rebroadcast
