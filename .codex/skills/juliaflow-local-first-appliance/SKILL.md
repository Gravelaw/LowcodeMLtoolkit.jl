---
name: juliaflow-local-first-appliance
description: Use when implementing or reviewing JuliaFlow local-first GA work: one-command local bootstrap, local data estate, DuckDB analytics, local PostgreSQL lab/team metadata, CPU/GPU hardware profiling, explainability/model evidence, offline Hub, academic reproducibility bundles, and backup/restore.
---

# JuliaFlow Local-First Appliance

Use after `juliaflow-control-loop` identifies a local-first BRD gap. Follow the local-first order in `AGENTS.md`.

## Invariants

- Core workflow must not require cloud accounts, managed cloud services, or external registries.
- Default storage is managed local filesystem with durable Arrow/Parquet artifacts and Arrow IPC runtime payloads.
- DuckDB is local analytics; PostgreSQL is lab/team metadata, RBAC, audit, execution history, and shared catalog concurrency.
- MinIO/S3-compatible mode is optional local compatibility.
- CPU execution must work everywhere; GPU use is opportunistic with explicit readiness/fallback evidence.
- Explainability, reproducibility, offline Hub, and backup/restore are core GA evidence.

## Evidence

- Update control docs listed in `AGENTS.md` for completed slices.
- Run `npm run validate:control-doc-sync`.
- Run `npm run validate:brd-traceability` after TODO or traceability changes.
- Run the smallest relevant Julia/frontend/contract checks for touched code.
