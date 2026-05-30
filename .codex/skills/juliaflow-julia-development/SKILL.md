---
name: juliaflow-julia-development
description: Use when implementing, debugging, or reviewing JuliaFlow Julia services, node SDK, execution/runtime logic, extensions, GPU/stream workers, Project.toml/Manifest.toml changes, Julia syntax questions, or Julia package/API usage.
---

# JuliaFlow Julia Development

## Use with
- Global `julia-coding` for idiomatic Julia, modules, Pkg, syntax, package structure.
- Global `julia-debugging` for stack traces, type instability, allocation/performance regressions.
- Official Julia docs first for syntax/API uncertainty; community sources only as troubleshooting support.

## Repo boundaries
- Gateway/repository: `services/api-gateway/src/`.
- Execution parser/planner/validation: `services/execution-service/src/`.
- Worker lanes: `services/worker-service/src/` plus `scripts/run-*-worker.jl`.
- Node SDK: `services/node-sdk/src/`.
- Base nodes: `extensions/base/src/`.

## Required checks
- Keep TS/OpenAPI/JSON schema and Julia structs/mappers aligned.
- Preserve Arrow IPC inter-node boundary.
- Run Julia service tests and any npm-backed contract/typecheck steps from native WSL/Linux; avoid mixing Windows Julia/Node artifacts with WSL-generated manifests, lockfiles, or caches.
- For long-running workers use bounded mode, e.g. `JULIAFLOW_WORKER_ONCE=1`.
- Run `julia --project=. tests/julia/runtests.jl` for Julia service changes; add extension tests when touching `extensions/base/`.

## NASA Power-of-10 application
Simple bounded control flow, validated inputs, checked returns, side-effect-free assertions, narrow scope, short functions, no hidden steady-state allocation in runtime hot paths.
