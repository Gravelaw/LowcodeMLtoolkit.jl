---
name: juliaflow-julia-development
description: Use when implementing, debugging, or reviewing JuliaFlow Julia services, node SDK, execution/runtime logic, extensions, GPU/stream workers, Project.toml/Manifest.toml changes, Julia syntax questions, or Julia package/API usage.
---

# JuliaFlow Julia Development

## Scope

- Gateway/repository: `services/api-gateway/src/`
- Execution parser/planner/validation: `services/execution-service/src/`
- Worker lanes: `services/worker-service/src/`, `scripts/run-*-worker.jl`
- Node SDK: `services/node-sdk/src/`
- Base nodes: `extensions/base/src/`

## Invariants

- Keep TS/OpenAPI/JSON schema and Julia structs/mappers aligned.
- Preserve Arrow IPC inter-node boundary.
- Use bounded worker modes for long-running workers, e.g. `JULIAFLOW_WORKER_ONCE=1`.

## Checks

- `julia --project=. tests/julia/runtests.jl`
- `julia --project=. extensions/base/test/runtests.jl` when touching base extensions.
- Npm contract/typecheck gates when payload shapes change.
