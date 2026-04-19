# JuliaFlow

JuliaFlow is a monorepo foundation for a visual low-code analytics platform built in Julia. This repository now contains Phase 0 bootstrap assets from the BRD execution plan:

- React frontend shell for workflow canvas and milestone dashboard
- Shared workflow contracts, OpenAPI spec, and JSON-RPC protocol docs
- Julia node SDK and CPU-first execution service prototype
- CI workflow, checkpoint script, ADR, and local development scaffolding

## Repository Layout

- `apps/frontend/` React + Vite application shell
- `packages/contracts/` shared TypeScript contracts and protocol specs
- `packages/ui/` shared React UI primitives
- `services/node-sdk/` Julia node SDK interfaces and helpers
- `services/execution-service/` Julia execution planner and CPU-only runner
- `services/api-gateway/` Julia API gateway stub and protocol surface
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
```

## Checkpoints

Use checkpoint script to capture tagged milestones with release note stubs:

```bash
./scripts/create-checkpoint.sh cp/00-foundation
```

See [docs/checkpoints.md](/home/akshayrj00/my_project/docs/checkpoints.md) for required evidence before tagging.

