---
name: juliaflow-frontend-development
description: Use when implementing or reviewing JuliaFlow frontend canvas, BI/dashboard viewer, Hub, monitor, settings, React/Vite tests, UI state, runtime config, accessibility, visual QA, or frontend performance.
---

# JuliaFlow Frontend Development

## Use with
- `frontend-design-workflow:frontend-implementation` for React/Vite implementation, responsive layout, accessibility, and verification.
- `frontend-design-workflow:frontend-architecture` before large UI/state/routing shifts.
- `frontend-design-workflow:frontend-visual-qa` for Playwright/screenshot/layout checks after meaningful UI changes.
- `frontend-design-workflow:frontend-accessibility-review` for keyboard, screen reader, forms, charts, and WCAG risk review.
- `lowcode-ml-ui-patterns` for workflow-builder, dataset/model, experiment, explainability, and analytics-product UI patterns.

## Repo boundaries
- App: `apps/frontend/src/`.
- Shared contracts: `packages/contracts/`.
- Shared UI primitives: `packages/ui/`.

## Rules
- Contracts first for payload shapes; frontend must consume shared types/client where practical.
- Run frontend install, dev, test, build, coverage, and visual QA commands from native WSL/Linux; if uncertain, run `npm run doctor:wsl-node` before `npm install`, `npm run test`, `npm run build`, or dev server work.
- Preserve route shell and demo fallback unless scope explicitly removes it.
- Keep runtime gateway config path working: `juliaflow-config.js` overrides Vite env fallback.
- Avoid brittle tests: prefer role/label/view-specific selectors over broad duplicate text.
- For local-first appliance UX, avoid cloud-first assumptions; expose local data estate, hardware readiness, offline Hub, explainability, reproducibility, and backup/restore states as first-class workflows.

## Required checks
- `npm run test` for frontend behavior.
- `npm run build` for typecheck/build.
- `npm run validate:coverage` or `npm run validate:p1` when coverage/perf gates are touched.
