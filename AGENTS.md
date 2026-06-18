# JuliaFlow Repository Guidance

Project-local overlay for `C:\Users\aksha\Documents\LowCodeJulia`.
Global Codex guidance owns engineering discipline, deterministic operations, native Windows/Debian execution, failure escalation, skill-routing hygiene, verification posture, and git safety. Keep this file JuliaFlow-specific.

## Repo Shape

Use existing product-area directories:

- `apps/frontend/`: React + Vite authoring workspace.
- `packages/contracts/`: workflow schema, OpenAPI, JSON-RPC, TS client/types.
- `packages/ui/`: shared React UI primitives.
- `services/api-gateway/`: Julia HTTP gateway and repositories.
- `services/execution-service/`: Julia workflow parsing, planning, validation, execution lifecycle.
- `services/worker-service/`: Julia worker runtime lanes.
- `services/node-sdk/`: Julia node runtime contract and helpers.
- `extensions/base/`: starter Julia node pack.
- `infra/`: Docker Compose, Kubernetes, ArgoCD, CI assets.
- `docs/`: architecture, tracker/checkpoints, onboarding.
- `tests/`: Julia, contract, frontend, and workflow fixtures.
- `src/`: repo-level Julia module entrypoint.
- `scripts/`: runnable helper scripts.

Prefer feature-oriented paths inside these areas over unrelated new root files.

## Commands

- `npm install`
- `npm run doctor:windows`
- `npm run doctor:debian`
- `npm run julia:instantiate`
- `npm run dev:frontend`
- `npm run build`
- `npm run test`
- `npm run validate:contracts`
- `julia --project=. tests/julia/runtests.jl`
- `julia --project=. scripts/run-api-gateway.jl`
- `VITE_JULIAFLOW_GATEWAY_BASE_URL=http://127.0.0.1:8088 npm run dev:frontend`
- `docker compose -f infra/docker/compose.dev.yml up -d`

Keep new commands scriptable and consistent with existing names.

## Git And PR Workflow

Before new implementation work, create a dev branch, push it, and open a draft PR against `main`. Keep work on the dev branch and update the PR as it progresses.

## Repo Invariants

- TS/React/CSS/JSON/YAML/Markdown use 2-space indentation; Julia uses 4 spaces.
- Keep shared payload changes contract-first in `packages/contracts/`, then align Julia and frontend.
- Preserve Arrow IPC as the inter-node payload boundary.
- Workflow definitions are TOML-backed and validated across frontend/backend boundaries.
- Preserve route shell, demo fallback, runtime `juliaflow-config.js`, accessible selectors, and coverage gates unless intentionally replacing them.
- Never commit real secrets or fake production managed services.

## Active Goal

Current BRD direction is local-first GA: local appliance bootstrap, managed local data estate, local metadata/database modes, local hardware runtime, explainability/model evidence, offline Hub, academic reproducibility, backup/restore, and local trust boundaries. Provider/cloud paths are optional compatibility work unless explicitly re-prioritized.

Active control set:

- `business-requirements-v0.3.0.md`
- `Plan.md`
- `docs/TODO.md`
- `docs/risk-register.md`
- `docs/brd-traceability.md`
- `docs/project-tracker.md`
- `docs/checkpoint-log.md`

Preferred local-first order:

1. Local appliance bootstrap.
2. Managed local data estate with Arrow/Parquet artifacts and DuckDB acceleration.
3. Local metadata/database modes, including PostgreSQL lab/team mode.
4. Local hardware runtime proof with CPU/GPU profiling and explicit CPU fallback.
5. Explainability/model evidence and academic reproducibility bundle.
6. Offline Hub proof.
7. Backup/restore and migration evidence.

## Completion Gates

- Do not mark `docs/TODO.md` P0/P1/P2 items complete unless `docs/brd-traceability.md` links code/doc evidence and verification evidence.
- For completed slices, phases, milestone claims, or substantive reviews, update `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md`.
- Tracker/checkpoint updates must state work done, gaps pending, and next items.
- Run `npm run validate:control-doc-sync` before completion claims when non-control files changed.
- Run `npm run validate:brd-traceability` after TODO or traceability changes.

## Skill Index

- `juliaflow-control-loop`: BRD/TODO/checkpoint closure and traceability.
- `juliaflow-local-first-appliance`: local-first GA appliance proof work.
- `juliaflow-julia-development`: Julia services, runtime, workers, node SDK, and extensions.
- `juliaflow-frontend-development`: React/Vite canvas, BI, Hub, Monitor, settings, and frontend tests.
- `juliaflow-provider-deployment`: optional provider/cloud compatibility.
- Installed plugin skills: use only when available and directly matched to the task.

Use multi-agent tools only when available, independent, and clearly owned. Do not delegate shared-file edits without explicit ownership.
