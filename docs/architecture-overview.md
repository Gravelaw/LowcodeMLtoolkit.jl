# JuliaFlow Architecture Implementation Guide

## Purpose

This document expands `docs/architecture.md` with implementation-ready detail for Phase 0 foundation. It captures architecture already present in repository and defines boundaries for next checkpoints. It is intentionally contract-first: shared schemas and service interfaces stabilize before feature lanes scale out.

## Current Foundation

JuliaFlow foundation is organized around five core layers:

1. `apps/frontend/`
   React + Vite shell for workflow canvas, milestone views, and future dashboard surfaces.
2. `packages/contracts/`
   Shared workflow schema, OpenAPI surface, JSON-RPC protocol, and TypeScript contract exports.
3. `services/api-gateway/`
   HTTP and realtime boundary for frontend, auth, workflow listing, and execution requests.
4. `services/execution-service/`
   CPU-first workflow loader, DAG planner, and execution admission point.
5. `services/node-sdk/` and `extensions/`
   Julia node runtime contract and extension packs that must honor Arrow IPC boundaries.

Supporting platform services currently defined for local development live in `infra/docker/compose.dev.yml`: PostgreSQL, Redis, MinIO, Kafka, and Keycloak.

## System Shape

```text
React Frontend
  -> REST / JSON-RPC
API Gateway
  -> workflow metadata, execution requests, auth/session boundary
Execution Service
  -> workflow TOML load, DAG planning, execution admission
Node SDK + Extensions
  -> node config, schema inference, execute hooks, stream hooks
Platform Dependencies
  -> PostgreSQL | Redis | Kafka | MinIO | Keycloak
```

## Frozen Contracts

These files are current source of truth. Changes here must be deliberate and checkpointed:

- Workflow schema: `packages/contracts/schemas/workflow.schema.json`
- Event schema: `packages/contracts/schemas/events.schema.json`
- OpenAPI surface: `packages/contracts/openapi/openapi.json`
- Realtime protocol: `packages/contracts/protocol/jsonrpc.json`
- TS contract exports: `packages/contracts/src/index.ts`
- Julia node runtime contract: `services/node-sdk/src/JuliaFlowNodeSDK.jl`

Contract rules:

- Workflow definitions remain schema-first and round-trip testable.
- API Gateway speaks REST for durable control-plane actions and JSON-RPC for canvas/runtime subscriptions.
- Inter-node payload boundary stays Arrow IPC only. Raw `DataFrame`, `Dict`, or `Vector` payload passing across service boundaries is out of bounds.
- New services must consume shared contracts, not redefine them locally.

## Runtime Responsibilities

### Frontend

- Render workflow canvas and checkpoint status from contract package.
- Call REST endpoints for workflow catalog and execution actions.
- Hold websocket/json-rpc session for live workflow and dashboard updates.

### API Gateway

- Validate external payloads against shared contracts.
- Present stable control-plane API to frontend and future external clients.
- Broker auth and future RBAC decisions before runtime calls.

### Execution Service

- Load workflow definitions from TOML-backed format.
- Build topologically sorted execution plan.
- Route node execution through Node SDK abstractions.
- Expand later into GPU scheduling, streaming, checkpoint recovery, and planner heuristics.

### Node SDK and Extensions

- Define stable node lifecycle: `configure`, `infer_output_schema`, `execute`, `on_stream_event`.
- Keep node implementations isolated from orchestration concerns.
- Package official and community nodes behind versioned extension packs.

## Checkpoint-Aligned Build Order

- `cp/00-foundation`: repo skeleton, contracts, frontend shell, CPU planner, CI, docs
- `cp/01-contracts-frozen`: freeze workflow/API/realtime/node interfaces and guard them with contract tests
- `cp/02-alpha-core`: canvas interaction, persistence, base node pack growth, service hardening
- `cp/03-alpha-gpu-bi`: GPU lane, BI outlet path, chart surfaces
- `cp/04+`: streaming, security, hub, enterprise deploy paths, scale work

Parallel implementation starts only after `cp/01-contracts-frozen`. Before that, contract owners and docs/infra owners should move in serial.

## Deployment Direction

- Local dev remains Docker Compose driven during foundation.
- Cluster delivery moves to ArgoCD app-of-apps under `infra/argocd/`.
- Kubernetes runtime path should keep platform dependencies, core services, and frontend deployables in separate ArgoCD applications so checkpoint rollback can happen by app and tag, not manual file revert.

## Update Rule

Update this document when any of these change:

- shared contract file paths
- service ownership or service count
- control-plane/runtime boundary
- deployment topology or checkpoint sequencing
