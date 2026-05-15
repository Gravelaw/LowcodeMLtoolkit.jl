---
name: juliaflow-frontend-development
description: Use when implementing or reviewing JuliaFlow frontend canvas, BI/dashboard viewer, Hub, monitor, settings, React/Vite tests, UI state, runtime config, accessibility, visual QA, or frontend performance.
---

# JuliaFlow Frontend Development

## Use with
- `build-web-apps:react-best-practices` for React patterns and performance.
- `build-web-apps:frontend-testing-debugging` for rendered UI/test/debug loops.
- `visual-ralph` / `visual-verdict` for significant visual redesign or pixel/UX matching.
- `design` before large UI/UX architecture shifts.

## Repo boundaries
- App: `apps/frontend/src/`.
- Shared contracts: `packages/contracts/`.
- Shared UI primitives: `packages/ui/`.

## Rules
- Contracts first for payload shapes; frontend must consume shared types/client where practical.
- Preserve route shell and demo fallback unless scope explicitly removes it.
- Keep runtime gateway config path working: `juliaflow-config.js` overrides Vite env fallback.
- Avoid brittle tests: prefer role/label/view-specific selectors over broad duplicate text.

## Required checks
- `npm run test` for frontend behavior.
- `npm run build` for typecheck/build.
- `npm run validate:coverage` or `npm run validate:p1` when coverage/perf gates are touched.
