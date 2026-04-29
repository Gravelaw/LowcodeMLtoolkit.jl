# JuliaFlow Next Steps Plan — 2026-04-29

## Purpose

Carry the post-50-node baseline into the next sessions with explicit sanity, repository cleanup, and BRD delivery order.

## Current Baseline

- Base node pack has 50 registered stable Tier-1 nodes with output-inspecting tests.
- Local tabular materialization is root-confined, `file://` refs are opt-in, and row/column/ref-byte caps are enforced.
- Production reader/writer adapter callback seam exists for Arrow/DataFrames-shaped refs.
- Full verification for current baseline passed: `git diff --check`, extension tests, full Julia tests, BRD traceability validation, JS/contract tests, and frontend build.
- Code-review and security-review passes were collected for the 50-node slice.
- Existing GitHub BRD/license documents were merged from `origin/main`: `BRD_Julia_DataScience_Toolkit_v2.md`, `BRD_Julia_EDA_Toolkit-Claudev0.md`, `business-requirements-v0.3.0.md`, and `LICENSE`.

## Next Execution Order

1. **Sanity and repository cleanup**
   - Review tracked generated artifacts such as `apps/frontend/tsconfig.tsbuildinfo`; decide whether to keep tracked or remove from version control in a dedicated cleanup commit.
   - Review binary/design artifacts under `Revised UI UX/`; either document their purpose or move them to a clearer docs/assets path.
   - Run `git status --short --branch`, `git diff --check`, `npm run validate:brd-traceability`, `npm run test`, `npm run build`, and `julia --project=. tests/julia/runtests.jl` before next release/tag.
   - Confirm GitHub remote is `https://github.com/Gravelaw/LowcodeMLtoolkit.jl` and branch protection/CI status after push.

2. **Production Arrow/DataFrames object-storage adapter**
   - Keep the existing callback seam in `TabularPayload.jl` as the boundary.
   - Add package-backed or service-backed adapters behind explicit configuration; do not add dependencies without a deliberate dependency decision.
   - Preserve local JSON/object-store fallback and root confinement tests.
   - Add adapter contract tests and update `docs/brd-traceability.md` before claiming P0 progress.

3. **Node scale 50 -> 75**
   - Prefer stable or adapter-required nodes with output-inspecting tests.
   - Candidate families: date/time parsing and bucketing, top-N per group, weighted average, right/full joins, lookup enrich, metric definition, dimension mapping, KPI thresholds, chart dataset output.
   - Keep `available_nodes()` exact-count tests aligned with docs.

4. **BI drilldown/viewer/export polish**
   - Add drilldown state model, viewer route/state persistence, richer export variants, and regression tests for filtered/drilled viewer output.

5. **Production hardening lanes**
   - Auth/RBAC: OIDC/JWT validation, persisted users/workspaces/roles, audit query/admin UI.
   - Streaming: Kafka/NATS adapters, durable replay runner, exactly-once proof, sink transactions.
   - GPU: CUDA/KernelAbstractions kernels, device-memory ops, worker isolation, multi-GPU scheduling.

## Documentation Rules For Next Sessions

- Start by reading `docs/project-tracker.md`, latest `docs/checkpoint-log.md`, `docs/TODO.md`, and `docs/brd-traceability.md`.
- Update tracker and checkpoint after every meaningful work block with: work done till date, gaps pending, next items to implement.
- Run `npm run validate:brd-traceability` after TODO or traceability changes.
