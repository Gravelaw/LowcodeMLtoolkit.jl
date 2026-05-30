---
name: juliaflow-control-loop
description: Use for JuliaFlow BRD/TODO/checkpoint driven planning, milestone closure, traceability updates, and cross-layer delivery decisions.
---

# JuliaFlow Control Loop

Use before meaningful JuliaFlow roadmap work or completion claims.

## Control Set

`business-requirements-v0.3.0.md`, `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/brd-traceability.md`, `docs/project-tracker.md`, `docs/checkpoint-log.md`.

## Workflow

1. Read tracker, latest checkpoint, TODO, and traceability.
2. Identify active BRD gap and target stage.
3. Prefer the local-first order in `AGENTS.md` unless the user says otherwise.
4. Use `juliaflow-local-first-appliance` for local-first GA lanes.
5. Keep thin slices: preserve dev/demo fallback; add production-depth seams with tests.

## Completion

- Sync docs, contracts, Julia, frontend, infra, and tests when a boundary changes.
- Do not check TODO P0/P1/P2 items without traceability code/doc and verification evidence.
- Update tracker/checkpoint with work done, gaps pending, and next items.
- Run `npm run validate:control-doc-sync`.
- Run `npm run validate:brd-traceability` after TODO or traceability changes.
