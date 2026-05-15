---
name: juliaflow-control-loop
description: Use for JuliaFlow BRD/TODO/checkpoint driven implementation planning, milestone closure, traceability updates, and cross-layer delivery decisions. Trigger when work touches BRD gaps, docs/project-tracker.md, docs/checkpoint-log.md, docs/TODO.md, docs/brd-traceability.md, or milestone completion claims.
---

# JuliaFlow Control Loop

Use before meaningful JuliaFlow roadmap work.

## Required intake
1. Read `docs/project-tracker.md`, latest `docs/checkpoint-log.md`, `docs/TODO.md`, and `docs/brd-traceability.md`.
2. Identify active BRD gap and target stage.
3. Keep thin-slice strategy: dev/demo fallback stays; production path added behind explicit seam and tests.
4. Do not check TODO P0/P1/P2 items unless traceability has code/doc evidence plus test evidence.

## Delivery rule
- Sync docs, contracts, Julia, frontend, infra, and tests in same slice when boundary changes.
- Update tracker and checkpoint after meaningful work with: work done, gaps pending, next items.
- Run `npm run validate:control-doc-sync` before claiming any slice/phase/review complete.
- Run `npm run validate:brd-traceability` after TODO/traceability changes.

## Stop condition
Evidence gathered, review clean, residual gaps explicitly recorded.
