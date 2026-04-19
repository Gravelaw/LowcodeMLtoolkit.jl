# JuliaFlow Repo Onboarding

## What This Project Is

`JuliaFlow` is a monorepo for a visual low-code analytics platform.

Current product shape:

- React frontend for workflow authoring and monitoring
- shared TypeScript contracts for workflow/API/realtime shapes
- Julia API gateway for workflow CRUD, execution admission, and checkpoint APIs
- Julia execution service for workflow parsing, validation, planning, and execution records
- Julia node SDK plus extension packs for pluggable node behavior
- local platform dependencies for future persistence, auth, object storage, and streaming paths

This repo is already beyond bare scaffold. It is in `cp/02-alpha-core` according to tracker/checkpoint docs.

## Mental Model

User edits flow in frontend.
Frontend talks to gateway over REST now, JSON-RPC/realtime path prepared.
Gateway stores workflows and execution/checkpoint records.
Execution service parses TOML workflow, validates DAG, builds execution plan/stages, and emits execution record.
Node SDK defines stable node contract.
Extension packs provide actual node implementations.

## Main Directories

- `apps/frontend/`
  React + Vite authoring UI
- `packages/contracts/`
  shared workflow schema, OpenAPI, JSON-RPC protocol, TS client/types
- `packages/ui/`
  shared React UI primitives
- `services/api-gateway/`
  Julia HTTP gateway and repository adapters
- `services/execution-service/`
  Julia workflow parser, validator, planner, execution record logic
- `services/node-sdk/`
  Julia node contract and runtime types
- `extensions/base/`
  official starter node pack
- `infra/docker/`
  local dependency stack
- `infra/argocd/`
  GitOps deployment path
- `docs/`
  architecture, checkpoints, tracker, ADRs
- `tests/`
  Julia tests, contract tests, frontend tests, workflow fixtures

## Key Files To Read First

- [README.md](/home/akshayrj00/my_project/README.md)
- [docs/architecture.md](/home/akshayrj00/my_project/docs/architecture.md)
- [docs/architecture-overview.md](/home/akshayrj00/my_project/docs/architecture-overview.md)
- [docs/project-tracker.md](/home/akshayrj00/my_project/docs/project-tracker.md)
- [docs/checkpoint-log.md](/home/akshayrj00/my_project/docs/checkpoint-log.md)

Code entrypoints:

- [src/JuliaFlowMonorepo.jl](/home/akshayrj00/my_project/src/JuliaFlowMonorepo.jl)
- [apps/frontend/src/App.tsx](/home/akshayrj00/my_project/apps/frontend/src/App.tsx)
- [services/api-gateway/src/JuliaFlowApiGateway.jl](/home/akshayrj00/my_project/services/api-gateway/src/JuliaFlowApiGateway.jl)
- [services/api-gateway/src/JuliaFlowGatewayRepository.jl](/home/akshayrj00/my_project/services/api-gateway/src/JuliaFlowGatewayRepository.jl)
- [services/execution-service/src/JuliaFlowExecutionService.jl](/home/akshayrj00/my_project/services/execution-service/src/JuliaFlowExecutionService.jl)
- [services/node-sdk/src/JuliaFlowNodeSDK.jl](/home/akshayrj00/my_project/services/node-sdk/src/JuliaFlowNodeSDK.jl)
- [extensions/base/src/JuliaFlowBaseExtension.jl](/home/akshayrj00/my_project/extensions/base/src/JuliaFlowBaseExtension.jl)

## Frontend Today

Frontend is authoring-first workspace, not landing page.

Current UI shape in `apps/frontend/src/App.tsx`:

- left rail for repository / quick-add / flow variables
- center canvas
- right inspector
- execution/checkpoint rail
- live gateway hydration when `VITE_JULIAFLOW_GATEWAY_BASE_URL` set
- demo fallback when no gateway configured or gateway load fails

Current status:

- workflow draft editing exists
- quick-add creates nodes
- flow variables editable
- inspector config editable
- save/update loop wired
- run loop wired

Still missing:

- true drag/drop placement
- manual connection authoring/removal
- realtime subscription wiring
- richer durable graph model

## Contracts Layer

Contracts in `packages/contracts/` are repo source of truth for shared shapes.

Important files:

- `schemas/workflow.schema.json`
- `schemas/events.schema.json`
- `openapi/openapi.json`
- `protocol/jsonrpc.json`
- `src/index.ts`

Important contract ideas:

- workflow definitions round-trip between JSON shape and TOML-backed runtime format
- gateway exposes REST for durable control-plane actions
- realtime protocol exists for websocket/json-rpc path
- workflow statuses and gateway execution statuses are separate concepts

## Julia Runtime Layers

### Node SDK

`services/node-sdk/` defines:

- port schemas
- node config normalization
- execution devices
- node context/result
- abstract node lifecycle

Important rule:

- inter-node payload boundary must be Arrow IPC

### Execution Service

`services/execution-service/` handles:

- TOML workflow loading
- workflow parsing into Julia structs
- DAG validation
- execution plan generation
- parallel stage generation
- execution lifecycle/status history records

Current execution shape is CPU-first, with GPU hints already modeled.

### API Gateway

`services/api-gateway/` handles:

- `/health`
- workflow list/detail/create/import/update
- workflow execute
- execution list/detail/status transition
- checkpoint list/create
- realtime socket entrypoint

Persistence:

- file repository works today
- PostgreSQL repository path/scaffold exists

Default local store:

- `tmp/gateway-store/`

Gateway bootstrap script:

- [scripts/run-api-gateway.jl](/home/akshayrj00/my_project/scripts/run-api-gateway.jl)

Default boot behavior:

- loads `tests/contracts/fixtures/foundation.workflow.toml`
- stores data under `tmp/gateway-store`
- serves on `127.0.0.1:8088`

## Extension Pack

Base extension in `extensions/base/` proves node-pack architecture.

Starter nodes present:

- Arrow passthrough
- Arrow table source
- Arrow table sink
- Select columns
- Linear model trainer

This is seed for larger node library planned in Alpha.

## Local Dev Commands

Install JS deps:

```bash
npm install
```

Run frontend:

```bash
npm run dev:frontend
```

Run gateway:

```bash
julia --project=. scripts/run-api-gateway.jl
```

Point frontend at gateway:

```bash
VITE_JULIAFLOW_GATEWAY_BASE_URL=http://127.0.0.1:8088 npm run dev:frontend
```

Run JS tests:

```bash
npm run test
```

Run Julia tests:

```bash
julia --project=. tests/julia/runtests.jl
```

## Infra Picture

Local compose file defines dependency stack for future/full local platform:

- PostgreSQL
- Redis
- MinIO
- Kafka
- Keycloak

See:

- [infra/docker/compose.dev.yml](/home/akshayrj00/my_project/infra/docker/compose.dev.yml)

Deployment direction:

- Docker Compose for local dev
- ArgoCD app-of-apps for cluster path
- Kubernetes manifests/scaffold under `infra/argocd/` and `infra/k8s/`

## Example Workflow Fixture

Good quick sample:

- [tests/contracts/fixtures/foundation.workflow.toml](/home/akshayrj00/my_project/tests/contracts/fixtures/foundation.workflow.toml)

It shows current runtime model:

- workflow metadata
- flow variables
- nodes with execution hints/config/ports
- typed connections
- TOML-backed durable format

## Current Delivery Stage

Per tracker and checkpoint log:

- foundation done
- contract freeze done
- alpha-core in progress

Already working:

- monorepo structure
- contracts
- gateway CRUD/execute/checkpoints
- execution planning
- frontend authoring shell
- starter extension pack
- test suites

Big gaps still open:

- realtime frontend sync
- connection authoring UX
- drag/drop placement
- BI dashboard v0
- streaming MVP
- GPU runtime lane
- Hub v0

## Known Repo Hygiene Gap

`AGENTS.md` still describes repo as minimal and no-app-source-tree. That no longer matches reality. Update that file before relying on it as current structure guide.
