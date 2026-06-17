---
name: juliaflow-frontend-development
description: Use for JuliaFlow React/Vite frontend, BI, Hub, Monitor, settings, tests, and visual QA.
---

# JuliaFlow Frontend Development

## Scope

- App: `apps/frontend/src/`
- Shared contracts: `packages/contracts/`
- Shared UI primitives: `packages/ui/`

## Invariants

- Contract-first for payload shapes; consume shared types/client where practical.
- Preserve route shell, demo fallback, and `juliaflow-config.js` runtime override.
- Prefer role/label/view-specific selectors over broad duplicate text.
- Surface local-first states clearly: data estate, hardware readiness, offline Hub, explainability, reproducibility, backup/restore.

## Checks

- `npm run test`
- `npm run build`
- `npm run validate:coverage` or `npm run validate:p1` when coverage/perf gates are touched.
