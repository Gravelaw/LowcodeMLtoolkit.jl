# Repository Guidelines

## Project Structure & Module Organization
This repository is an active monorepo for `JuliaFlow`, a visual low-code analytics platform. Keep top-level files limited to repo-wide coordination, tooling, and manifests. Add new code in the existing product-area directories and preserve contract-first boundaries between frontend, shared contracts, Julia services, extensions, and infra.

Current layout:
- `apps/frontend/` React + Vite authoring workspace
- `packages/contracts/` shared workflow schema, OpenAPI, JSON-RPC protocol, and TS client/types
- `packages/ui/` shared React UI primitives
- `services/api-gateway/` Julia HTTP gateway and repository adapters
- `services/execution-service/` Julia workflow parser, planner, validation, and execution lifecycle logic
- `services/node-sdk/` Julia node runtime contract and helpers
- `extensions/base/` starter Julia node pack
- `infra/` Docker Compose, Kubernetes, ArgoCD, CI-related infra assets
- `docs/` architecture notes, ADRs, releases, tracker/checkpoints, onboarding docs
- `tests/` Julia tests, contract tests, frontend tests, and workflow fixtures
- `src/` repo-level Julia module entrypoint
- `scripts/` runnable helper scripts such as gateway bootstrap

Keep modules small and cohesive. Prefer feature-oriented paths inside each product area, for example `services/api-gateway/src/` or `apps/frontend/src/`, over unrelated new root files.

## Build, Test, and Development Commands
Tooling already exists. Prefer these repo-standard commands and keep new commands scriptable and predictable.

Repo-level commands:
- `npm install` to install JS workspace dependencies
- `npm run dev:frontend` to start frontend dev server
- `npm run build` to build JS workspaces that expose build scripts
- `npm run test` to run JS workspace tests plus contract tests
- `julia --project=. tests/julia/runtests.jl` to run Julia test suite
- `julia --project=. scripts/run-api-gateway.jl` to start local Julia API gateway
- `VITE_JULIAFLOW_GATEWAY_BASE_URL=http://127.0.0.1:8088 npm run dev:frontend` to run frontend against live gateway

Infra helpers:
- `docker compose -f infra/docker/compose.dev.yml up -d` to start local platform dependencies

Keep command names consistent and scriptable.

## Coding Style & Naming Conventions
Use consistent formatting and keep files ASCII unless the project already requires Unicode.

Indentation guidance:
- TypeScript/React/CSS/JSON/YAML/Markdown: 2 spaces
- Julia: 4 spaces, matching current codebase style

Language guidance:
- React code lives under `apps/frontend/` and shared TS code under `packages/`
- Julia service and SDK code lives under `services/`, `extensions/`, and `src/`
- Keep workflow/API/shared schema changes aligned across frontend contracts and Julia implementations

Naming guidance:
- Directories and modules: lowercase with hyphens or underscores
- Classes and components: `PascalCase`
- Functions and variables: `camelCase` in TS/React, `snake_case` or idiomatic Julia naming in Julia code
- Markdown docs: descriptive uppercase names when conventional, for example `README.md`

Prefer existing repo conventions over introducing a new style in touched files.

## Safety-Critical Coding Rules
When adding core logic, follow the Power of 10 discipline in a repository-friendly form:
- Use simple control flow only. Avoid `goto`, recursion, and similar hard-to-review jumps.
- Give every loop a clear static upper bound.
- Do not add dynamic allocation in steady-state runtime paths after startup or initialization.
- Keep functions short; target roughly one screen or about 60 lines.
- Use assertions for impossible states, and keep them side-effect free.
- Declare data in the narrowest practical scope.
- Always validate inputs and always check non-void return values.
- Keep preprocessor use minimal; prefer simple includes and simple macros only.
- Restrict pointer complexity; avoid hidden indirection and function pointers unless the project explicitly requires them.
- Build with the strictest warning settings available and treat warnings as defects. Run static analysis regularly.

## Testing Guidelines
Place tests under `tests/` or next to source when the local toolchain already does that.

Current patterns:
- Frontend tests under `apps/frontend/src/*.test.tsx`
- Julia tests under `tests/julia/`
- Contract tests under `tests/contracts/`
- Extension tests under `extensions/base/test/`

New features should include tests for primary behavior and key edge cases. If a change is not testable yet, explain the gap in the pull request.

## Commit & Pull Request Guidelines
Git history is not available in this workspace, so no repository-specific commit pattern can be inferred. Use short, imperative commit messages such as `Add API client skeleton` or `Set up test harness`.

Pull requests should include:
- a clear summary of the change
- any setup or verification steps
- linked issue numbers when relevant
- screenshots or sample output for UI or CLI changes

## Agent-Specific Notes
Do not assume missing tooling exists. Read current architecture and onboarding docs before making broad repo changes.

Useful docs:
- `README.md`
- `docs/architecture.md`
- `docs/architecture-overview.md`
- `docs/repo-onboarding.md`

Important repo constraints:
- Shared contracts in `packages/contracts/` are source of truth for cross-layer payload shapes
- Workflow definitions are TOML-backed and validated across frontend/backend boundaries
- Inter-node payload boundary is Arrow IPC only
- API gateway currently offers working file-backed persistence and PostgreSQL-ready repository path
- Realtime/frontend sync and richer graph editing are still in-progress alpha areas

## Tracker And Checkpoint Rule

Every project must create and maintain both:

- `docs/project-tracker.md`
- `docs/checkpoint-log.md`

These are mandatory project-control files, not optional docs.

### Required Contents

Both files must always record these 3 things:

1. work done till date
2. gaps pending
3. next items to implement

### Startup Rule For New Projects

Before starting meaningful implementation on any new project, agent must:

1. create `docs/project-tracker.md` if missing
2. create `docs/checkpoint-log.md` if missing
3. write initial entries for:
   - work done till date
   - gaps pending
   - next items to implement
4. read both files before starting job execution

### Ongoing Rule

Before each new job, agent must:

1. read latest tracker
2. read latest checkpoint entry
3. confirm target gap or target milestone being worked on

After each meaningful work block, agent must update both files with:

1. what changed / work done till date
2. what gaps still remain
3. what should be implemented next

### Checkpoint Rule

Use checkpoint log to capture major milestones or major state changes.
Each checkpoint entry should align with release/checkpoint docs when those exist.
If tracker and checkpoint disagree, agent must reconcile them before continuing.
