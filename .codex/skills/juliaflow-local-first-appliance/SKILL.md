---
name: juliaflow-local-first-appliance
description: Use when implementing or reviewing JuliaFlow local-first GA work: one-command local bootstrap, local data estate, DuckDB analytics, local PostgreSQL lab/team metadata, CPU/GPU hardware profiling, explainability/model evidence, offline Hub, academic reproducibility bundles, and backup/restore.
---

# JuliaFlow Local-First Appliance

Use after `juliaflow-control-loop` identifies a local-first BRD gap.

## Active BRD Direction

- No cloud account, managed cloud service, or external registry may be required for the core workflow.
- Default storage is a managed local filesystem data estate with durable Arrow/Parquet artifacts and Arrow IPC runtime payloads.
- DuckDB is for local analytics/query acceleration; PostgreSQL is for lab/team metadata, RBAC, audit, execution history, and shared catalog concurrency.
- MinIO/S3-compatible mode is optional local compatibility, not the default storage requirement.
- CPU execution must work everywhere; GPU use is opportunistic and must report CUDA/runtime readiness plus explicit CPU fallback reasons.
- Explainability, model cards, dataset cards, reproducibility bundles, offline Hub install, and backup/restore are core GA evidence.

## Implementation Order

1. Local appliance bootstrap: install profile, service startup, health checks, local folders, sample workflow, no cloud credentials.
2. Local data estate: zones, manifests, quotas, cleanup, checksums, Arrow/Parquet durability, DuckDB queries.
3. Metadata/database modes: single-user local mode plus PostgreSQL lab/team mode.
4. Hardware runtime: CPU/RAM/disk/GPU profiler, worker limits, CUDA smoke when available, CPU fallback.
5. Explainability/reproducibility: dataset cards, model cards, feature importance, local/global explanations, checkpoint bundle export/reimport.
6. Offline Hub and backup/restore: bundled extension install, artifact cache, checksums, sandbox gates, migration evidence.

## Environment Rule

- Run bootstrap, install, service startup, smoke, build, and test commands from native WSL/Linux. If the shell or Node path is uncertain, run `npm run doctor:wsl-node` before JS tooling and keep generated artifacts/lockfiles from the same WSL toolchain.
- Do not add Windows Node/npm/Vite fallbacks, `wsl.exe` bridge calls, or Windows-path cleanup workarounds unless the user explicitly requests Windows compatibility.

## Use With Installed Skills

- `analysis-engineering-workflow:architect-work` or `analysis-engineering-workflow:review-architecture` for cross-service design.
- `analysis-engineering-workflow:implement-work` and `analysis-engineering-workflow:execute-verify` for scoped edits and checks.
- `julia-engineering-toolkit:julia-coding`, `julia-engineering-toolkit:julia-data-science`, and `julia-engineering-toolkit:julia-debugging` for Julia/runtime/data changes.
- `frontend-design-workflow:frontend-implementation`, `frontend-design-workflow:frontend-visual-qa`, and `lowcode-ml-ui-patterns` for local appliance UI surfaces.
- `codex-security:security-scan` for local trust boundary, extension sandbox, secrets, auth, and supply-chain changes.

## Required Evidence

- Update `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md` for completed slices.
- Run `npm run validate:control-doc-sync`; run `npm run validate:brd-traceability` when TODO/traceability changes.
- Run the smallest relevant Julia/frontend/contract checks for touched code.
