# AKS-30 Through AKS-35 Implementation Plan

Last updated: 2026-06-20

This document records the per-task plan for the Explorer/Data/Transform parity follow-up work after PR #37. Each task should close only when its implementation evidence and verification evidence are linked through the active control docs.

## AKS-30 Explorer Mock Parity: Live Workspace Overview

Plan:

- Keep Explorer as a dense local workspace command center, not a landing page.
- Use gateway workspace summary as the primary source for CPU/RAM/disk/datasets/models/runs, package/runtime counts, activities, and artifacts.
- Show explicit source and empty states when gateway workspace summary or artifact evidence is unavailable.
- Keep artifact actions honest: copy path works, reveal/open remains disabled until desktop shell integration exists.

Implementation target:

- Explorer displays gateway-vs-fixture source state, artifact count, artifact kind/size/locality, and a no-artifacts empty state.

Verification:

- Browser coverage confirms Explorer route renders Plotly charts and stale chart evidence without blank panels.

## AKS-31 Data Mock Parity: Full Local Data Workspace

Plan:

- Make Data controls visibly mutate local state before adding more connectors.
- Keep unsupported sources disabled with reasons instead of fake-functional.
- Add source selection, filter/sort, sampling, lineage, profile, and readiness behavior that changes the visible preview/profile surface.
- Preserve wrapped ML Readiness text for long recommendations.

Implementation target:

- Data records active source, disabled-source reason text, filtered row counts, and sample-size preview changes.

Verification:

- Unit/browser coverage confirms filter and sampling changes alter visible preview rows and long readiness text remains wrapped.

## AKS-32 Transform Mock Parity: Interactive Pipeline Builder

Plan:

- Keep React Flow as the only workflow canvas layer.
- Make node selection and settings editable, and reflect edits in validation/log evidence.
- Treat unsaved canvas/config edits as warnings until validation passes.
- Keep run/history evidence tied to existing transform run/history behavior.

Implementation target:

- Transform node settings include editable strategy/output fields, validation state changes after edits, and generated logs include selected config.

Verification:

- Unit/browser coverage edits a node config, sees warning state, validates, and sees valid state.

## AKS-33 Gateway And Contracts For Explorer/Data/Transform State

Plan:

- Continue extending existing contracts and gateway responses; do not introduce parallel ad hoc frontend shapes.
- Harden the shared chart contract usage around status, source evidence, export permissions, and stale/empty/error states.
- Keep release/local-appliance behavior explicit for unavailable or stale local evidence.

Implementation target:

- Shared chart utilities classify ready/stale/empty/error specs and are consumed by the renderer.

Verification:

- Unit coverage proves chart readiness classification and stale chart render eligibility.

## AKS-34 Visual QA And Release Verification

Plan:

- Keep desktop/mobile Playwright coverage for Explorer, Data, and Transform.
- Add checks for chart render, stale chart state, data filter/sampling behavior, transform node config editing, validation state, and screenshots.
- Keep live-backend smoke in the gate set for release/local-appliance regressions.

Implementation target:

- Browser spec covers stale chart evidence, Data sample-size changes, Transform config edit/validation, and screenshots.

Verification:

- `npm run test:browser -- tests/browser/local-ui.spec.ts` and `npm run smoke:live-backend-browser`.

## AKS-35 Data ML Readiness Text Overlap Bug

Plan:

- Treat this as a concrete visual regression target inside the Data route.
- Keep readiness values wrapped with `overflow-wrap` and constrained grid behavior.
- Verify with a long recommendation string and browser screenshot coverage.

Implementation target:

- The Data readiness panel uses wrapped key/value text and remains visible in browser screenshots.

Verification:

- Existing browser screenshot plus focused unit coverage for the readiness panel text.
