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
NASA/JPL Power of 10 discipline is mandatory for all core JuliaFlow logic. Do not remove or weaken these rules. When adding core logic, follow the Power of 10 discipline in a repository-friendly form:
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

### Default Session Communication Mode

Keep repository communication concise and high-signal by default. Use the `caveman` skill only when the user explicitly asks for caveman mode and that skill is available.

Requirements:
- prefer brief, compressed, high-signal responses in all commentary and final messages
- keep technical accuracy intact while reducing filler

### Required Skill Routing For Future Modules

Use the repo-local skills under `.codex/skills/` plus global skills when available. Invoke only the relevant subset; keep context lean.

- `juliaflow-control-loop`: default for BRD/TODO/checkpoint-driven work, milestone closure, traceability, and cross-layer module delivery.
- `juliaflow-local-first-appliance`: local appliance bootstrap, local data estate, DuckDB/PostgreSQL local modes, CPU/GPU hardware proof, explainability/model evidence, offline Hub, academic reproducibility, and backup/restore.
- `juliaflow-julia-development`: Julia services, node SDK, worker runtime, base extensions, Julia syntax/package questions, `Project.toml` / `Manifest.toml`, and performance/debugging work.
- `juliaflow-frontend-development`: React/Vite canvas, BI viewer, Hub, monitor, settings, route shell, runtime config, frontend tests, visual QA, and frontend performance.
- `juliaflow-provider-deployment`: optional provider/cloud compatibility only, including Kustomize/ArgoCD overlays, secret delivery, live cluster dry-runs, and provider-specific object-store/auth/broker bindings.
- `analysis-engineering-workflow:plan-work`, `analysis-engineering-workflow:architect-work`, `analysis-engineering-workflow:review-architecture`, `analysis-engineering-workflow:implement-work`, `analysis-engineering-workflow:execute-verify`, and `analysis-engineering-workflow:post-execution-review`: use for broad planning, architecture, implementation, verification, and review gates.
- `julia-engineering-toolkit:julia-coding`, `julia-engineering-toolkit:julia-data-science`, and `julia-engineering-toolkit:julia-debugging`: use with `juliaflow-julia-development`; prefer official Julia docs for syntax/API/Pkg behavior and use community sources only for troubleshooting/package discovery.
- `frontend-design-workflow:frontend-implementation`, `frontend-design-workflow:frontend-architecture`, `frontend-design-workflow:frontend-visual-qa`, `frontend-design-workflow:frontend-accessibility-review`, and `lowcode-ml-ui-patterns`: use with `juliaflow-frontend-development` for major frontend/UI work.
- `codex-security:security-scan`: use for auth, secrets, RBAC, OIDC/JWT, Hub trust, deployment, extension sandbox, or supply-chain surfaces.

For large module work, plan before edits and use multi-agent tools only when they are available and the lanes are independent with explicit ownership:

- `explore`: fast repo map and symbol lookup
- `researcher`: official docs/version-aware external facts
- `dependency-expert`: dependency/package/SDK selection
- `executor`: implementation in scoped files
- `test-engineer`: regression and test design
- `architect` / `critic`: boundary, risk, and tradeoff review
- `code-reviewer` or framework/security review skill: merge-readiness review

Parallelize only independent lanes. Do not delegate shared-file edits without clear ownership. Integrate results locally and own final verification.

### Future Module Development Rules

- Start with the current tracker/checkpoint/TODO/traceability state; do not rely on stale memory.
- Keep `packages/contracts/` as source of truth before changing Julia or frontend payloads.
- For Julia work, keep functions short, typed enough for clarity, validated at boundaries, and covered by `julia --project=. tests/julia/runtests.jl`.
- For frontend work, keep route shell/demo fallback unless intentionally replaced, prefer accessible role/label selectors, and run `npm run test` plus `npm run build`.
- For deployment work, never commit real secrets, never fake production managed services, and run `npm run validate:k8s`.
- For milestone claims, update TODO/traceability/tracker/checkpoint together and run `npm run validate:brd-traceability`.
- For every completed slice, phase, or review, update `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md`; then run `npm run validate:control-doc-sync`.

### Session Learnings To Keep

- For scoped repo-local implementation slices, prefer enough reasoning to cover the touched risk; reserve deeper architecture/security review for security-sensitive work, distributed guarantees, local data durability, reproducibility, extension sandboxing, or multi-system tradeoffs.
- For general code generation, test updates, and contract plumbing, use the active configured model/tooling; avoid hard-coding model names in repo guidance.
- When smoke-testing long-running worker scripts such as `scripts/run-gpu-worker.jl` or `scripts/run-stream-worker.jl`, set `JULIAFLOW_WORKER_ONCE=1` (or equivalent bounded mode) so verification does not hang the session.

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


## JuliaFlow End-Goal Delivery Rules

JuliaFlow end goal is the BRD-defined local-first visual low-code analytics platform: Julia-native workflow canvas, Arrow IPC node boundary, CPU/GPU execution on local hardware, local data estate, local metadata/database modes, integrated BI, AI explainability, governed offline Hub, academic reproducibility, backup/restore, and local trust boundaries. Treat `business-requirements-v0.3.0.md`, `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/brd-traceability.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md` as the end-goal control set.

Before any meaningful implementation:

1. Read `docs/project-tracker.md`, latest `docs/checkpoint-log.md`, `docs/TODO.md`, and `docs/brd-traceability.md`.
2. Identify the active BRD gap and target stage before editing.
3. Prefer the current local-first order unless the user says otherwise:
   - local appliance bootstrap
   - managed local data estate with Arrow/Parquet artifacts and DuckDB acceleration
   - local metadata/database modes, including PostgreSQL lab/team mode
   - local hardware runtime proof with CPU/GPU profiling and explicit CPU fallback
   - explainability/model evidence and academic reproducibility bundle
   - offline Hub proof
   - backup/restore and migration evidence
4. For broad BRD/P0 work, use the strongest available planning, architecture review, and validation workflow rather than a hard-coded model name.
5. Preserve the thin-slice strategy: keep existing dev/demo fallbacks while adding local-first production-depth paths behind explicit seams and tests.

Completion rules for any slice, phase, review, or milestone claim:

- Do not mark `docs/TODO.md` P0/P1/P2 items complete unless `docs/brd-traceability.md` links code/doc evidence and test/verification evidence.
- Update `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md` whenever a new slice, phase, or review is completed. This is mandatory even for instruction-only or review-only work.
- Run `npm run validate:control-doc-sync` before claiming completion; it must pass when non-control files changed.
- Run `npm run validate:brd-traceability` after changing TODO or BRD traceability state.
- Keep `Plan.md`, `docs/TODO.md`, `docs/brd-traceability.md`, `docs/risk-register.md`, `docs/project-tracker.md`, `docs/checkpoint-log.md`, README/onboarding docs, contracts, OpenAPI, Julia code, frontend code, and tests synchronized for the touched scope.
- After a meaningful work block, update tracker and checkpoint with the three mandatory fields: work done till date, gaps pending, next items to implement.

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
