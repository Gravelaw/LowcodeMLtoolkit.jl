# JuliaFlow Repository Guidance

This file is the project-local overlay for `/mnt/c/Users/aksha/OneDrive/Documents/LowCodeJulia`.
Global Codex guidance still applies for general engineering discipline, deterministic local operations, skill routing hygiene, verification posture, and git safety. Keep this file focused on JuliaFlow-specific rules.

## Project Shape

JuliaFlow is a monorepo for a local-first visual low-code analytics platform. Keep top-level files limited to repo-wide coordination, tooling, and manifests. Add code inside the existing product-area directories:

- `apps/frontend/`: React + Vite authoring workspace.
- `packages/contracts/`: source of truth for workflow schema, OpenAPI, JSON-RPC, TS client/types.
- `packages/ui/`: shared React UI primitives.
- `services/api-gateway/`: Julia HTTP gateway and repositories.
- `services/execution-service/`: Julia workflow parsing, planning, validation, execution lifecycle.
- `services/worker-service/`: Julia worker runtime lanes.
- `services/node-sdk/`: Julia node runtime contract and helpers.
- `extensions/base/`: starter Julia node pack.
- `infra/`: Docker Compose, Kubernetes, ArgoCD, CI-related assets.
- `docs/`: architecture, ADRs, releases, tracker/checkpoints, onboarding.
- `tests/`: Julia tests, contract tests, frontend tests, workflow fixtures.
- `src/`: repo-level Julia module entrypoint.
- `scripts/`: runnable helper scripts.

Prefer feature-oriented paths inside these areas over unrelated new root files.

## Standard Commands

Run these commands from native WSL/Linux. For JS tooling, `npm run doctor:wsl-node` must pass before dependency installation, build, test, or frontend development if the environment is uncertain.

- `npm install`: install JS workspace dependencies.
- `npm run dev:frontend`: start frontend dev server.
- `npm run build`: build JS workspaces with build scripts.
- `npm run test`: run JS workspace tests plus contract tests.
- `julia --project=. tests/julia/runtests.jl`: run Julia tests.
- `julia --project=. scripts/run-api-gateway.jl`: start local API gateway.
- `VITE_JULIAFLOW_GATEWAY_BASE_URL=http://127.0.0.1:8088 npm run dev:frontend`: run frontend against live gateway.
- `docker compose -f infra/docker/compose.dev.yml up -d`: start local platform dependencies.

Keep new commands scriptable and consistent with these names.

## Git And PR Workflow

Before starting new implementation work, create a dev branch, push it, and open a draft PR against `main`. Keep new work on the dev branch and update the PR as the work progresses.

## Style And Boundaries

- Use 2-space indentation for TypeScript/React/CSS/JSON/YAML/Markdown; use 4 spaces for Julia.
- Keep files ASCII unless the file already requires Unicode.
- Use `PascalCase` for React components/classes, `camelCase` for TS variables/functions, and idiomatic `snake_case` or Julia naming in Julia.
- Keep shared payload shape changes contract-first in `packages/contracts/`, then align Julia and frontend.
- Preserve Arrow IPC as the inter-node payload boundary.
- Workflow definitions are TOML-backed and validated across frontend/backend boundaries.
- Keep the route shell, demo fallback, runtime `juliaflow-config.js`, accessible selectors, and coverage gates unless intentionally replacing them.

## Core Safety Rules

NASA/JPL Power of 10 discipline is mandatory for core JuliaFlow logic. Apply the global engineering discipline with these repo-specific constraints:

- Use simple, bounded control flow for runtime/service logic.
- Avoid recursion and hidden dynamic allocation in steady-state runtime paths.
- Keep functions short, validated at boundaries, and covered by focused tests.
- Treat warnings, static-analysis findings, lint errors, and failing tests as defects.
- Never commit real secrets or fake production managed services.

## Active End Goal

The active BRD direction is local-first GA: a Julia-native workflow canvas, Arrow IPC node boundary, CPU/GPU execution on local hardware, local data estate, local metadata/database modes, integrated BI, AI explainability, governed offline Hub, academic reproducibility, backup/restore, and local trust boundaries.

The active control set is:

- `business-requirements-v0.3.0.md`
- `Plan.md`
- `docs/TODO.md`
- `docs/risk-register.md`
- `docs/brd-traceability.md`
- `docs/project-tracker.md`
- `docs/checkpoint-log.md`

Before meaningful implementation, read the latest tracker/checkpoint/TODO/traceability state and identify the active BRD gap. Prefer this local-first order unless the user says otherwise:

1. Local appliance bootstrap.
2. Managed local data estate with Arrow/Parquet artifacts and DuckDB acceleration.
3. Local metadata/database modes, including PostgreSQL lab/team mode.
4. Local hardware runtime proof with CPU/GPU profiling and explicit CPU fallback.
5. Explainability/model evidence and academic reproducibility bundle.
6. Offline Hub proof.
7. Backup/restore and migration evidence.

Preserve the thin-slice strategy: keep existing dev/demo fallbacks while adding production-depth local-first paths behind explicit seams and tests.

## Completion Rules

- Do not mark `docs/TODO.md` P0/P1/P2 items complete unless `docs/brd-traceability.md` links code/doc evidence plus test/verification evidence.
- For completed slices, phases, milestone claims, or substantive reviews, update `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md`.
- Tracker and checkpoint updates must include: work done till date, gaps pending, and next items to implement.
- Run `npm run validate:control-doc-sync` before claiming completion when non-control files changed.
- Run `npm run validate:brd-traceability` after TODO or traceability changes.
- Keep README/onboarding docs, contracts, OpenAPI, Julia code, frontend code, tests, tracker, checkpoint, risk register, and traceability synchronized for the touched scope.

## Skill Routing

Use only available skills. Prefer the repo-local skills under `.codex/skills/` plus installed global/plugin skills, and keep context lean.

- `juliaflow-control-loop`: BRD/TODO/checkpoint work, milestone closure, traceability, cross-layer delivery.
- `juliaflow-local-first-appliance`: local bootstrap, data estate, DuckDB/PostgreSQL modes, hardware proof, explainability, offline Hub, reproducibility, backup/restore.
- `juliaflow-julia-development`: Julia services, node SDK, worker runtime, base extensions, Julia package/API/debugging work.
- `juliaflow-frontend-development`: React/Vite canvas, BI, Hub, monitor, settings, runtime config, frontend tests, visual QA.
- `juliaflow-provider-deployment`: optional provider/cloud compatibility only; do not prioritize unless explicitly requested.
- `analysis-engineering-workflow:*`: planning, architecture, implementation, verification, review, and debugging gates.
- `julia-engineering-toolkit:*`: Julia coding, data science, and debugging support.
- `frontend-design-workflow:*` and `lowcode-ml-ui-patterns`: major frontend/UI work.
- `codex-security:security-scan`: auth, secrets, RBAC, OIDC/JWT, Hub trust, deployment, extension sandbox, or supply-chain surfaces.

Use multi-agent tools only when available, independent, and clearly owned. Do not delegate shared-file edits without explicit ownership.

## Verification Defaults

- Frontend: `npm run test`, `npm run build`, plus coverage/audit/visual evidence when relevant.
- Julia runtime/services: `julia --project=. tests/julia/runtests.jl`; include extension tests when touched.
- Contracts/OpenAPI: `npm run test` or `npm run validate:contracts`.
- Deployment: `npm run validate:k8s`.
- Control docs: `npm run validate:control-doc-sync` and, when applicable, `npm run validate:brd-traceability`.
- Long-running workers: use bounded mode such as `JULIAFLOW_WORKER_ONCE=1`.

## Useful Docs

- `README.md`
- `docs/architecture.md`
- `docs/architecture-overview.md`
- `docs/repo-onboarding.md`
