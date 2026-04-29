# JuliaFlow TODO

Last updated: 2026-04-29
Source: BRD gap review against `JuliaFlow_BRD_v1.0.docx` and current code.
Plan: `.omx/plans/brd-gap-review-2026-04-24.md`; current endgame plan: `.omx/plans/repo-brd-endgame-2026-04-25.md`; current next-step plan: `.omx/plans/repo-brd-next-steps-2026-04-28.md`

## P0 — Required Before Phase 1 / Alpha Complete

1. [x] Base node pack first reality pass: 25 Tier-1 base nodes registered; transform/aggregate/model/table nodes materialize inline tabular rows with tests.
2. [x] External-ref materialization seam: base nodes resolve external Arrow-shaped refs via metadata store/loader and file JSON/JSONL fixtures without losing Arrow IPC payload boundaries.
3. [ ] Production Arrow/DataFrames materialization: current local object-store source/sink roundtrip and callback adapter seam exist, and base pack has grown to 50 stable nodes, but package-backed Arrow/DataFrames object-storage execution and scale 50 -> 75 -> 150 remain pending.
4. [x] BI chart-data seam: published dashboard chart-data API, typed client path, OpenAPI schema, gateway auth reuse, and viewer row/field rendering.
5. [x] BI published artifact datasets: publish snapshots now persist BI outlet rows and chart-data reads return dataset-backed rows when present.
6. [x] BI semantic/cache/export slice: chart-data now infers dimensions/measures from rows, returns cache/live metadata, and exposes CSV export.
7. [x] BI live/render UX slice: published viewer now supports 5 family previews, manual refresh, live polling for live snapshots, cross-filter selection, and export CSV action.
8. [x] BI interaction hardening slice: realtime invalidation beyond polling, viewer cross-filter selection, filtered export, and selection summaries.
9. [ ] BI viewer polish follow-up: deeper drilldown flows and richer export/viewer UX polish.
10. [x] Auth/RBAC thin contract slice: auth context types, workspace roles, resource permissions, dev-token gateway gates, dashboard share/workspace separation.
11. [ ] Production OIDC/RBAC hardening: JWT/OIDC validation, persisted users/workspaces/roles, audit logs, resource-policy admin UI.
12. [x] Streaming fixture/window/checkpoint MVP: fixture adapter batches, bounded policy batches, window summaries, lag/backpressure/watermark diagnostics, checkpoint offsets.
13. [ ] Streaming production hardening: Kafka/NATS adapters, durable replay runner, exactly-once proof, production watermarking and sink transactions.
14. [x] GPU execution MVP: hardware registry summary, mock GPU workload execution, CPU fallback, worker execution beyond status promotion.
15. [ ] GPU production hardening: real CUDA/KernelAbstractions kernels, device memory ops, worker isolation guarantees, and multi-GPU scheduling.

## P1 — Next Alpha Hardening

1. [ ] Hub publish/install hardening: artifact hashes, compatibility sandbox command, publish UX, private/offline mirror fixture.
2. [ ] Components/control-flow contracts: containers, components, loop start/end, switch/case, try/catch, parallel chunk validation.
3. [ ] Observability/perf gates: OTel/Prometheus seams, 1,000-node render harness, node dispatch microbench, coverage thresholds.

## P2 — Beta/GA Foundation

1. [ ] Deployment hardening: replace ArgoCD placeholders with real deployments/services/ingress/secrets and Helm/Kustomize production overlays.
2. [x] BRD traceability automation: maintain `docs/brd-traceability.md`; fail milestone claim if TODO item lacks test/evidence links.
3. [ ] Node-library scale roadmap: staged taxonomy from 50 -> 75 -> 150 -> 300+ nodes with quality tiers and compatibility tests.

## Review Notes

- 2026-04-24: base node pack now has 25 registered Tier-1 nodes and inline-row materialization tests.
- 2026-04-24: external-ref materialization seam now resolves metadata-store, loader, and file JSON/JSONL row fixtures; production Arrow/DataFrames object-storage execution remains pending.
- 2026-04-24: BI chart-data seam now exists across contracts/OpenAPI/gateway/frontend viewer.
- 2026-04-24: published dashboard artifacts now persist BI outlet dataset rows and chart-data reads return artifact-backed rows when present.
- 2026-04-24: BI chart-data now returns inferred dimensions/measures, cache/live metadata, JSON/CSV export formats, and CSV export route; live refresh/cache invalidation/rendering UX remains pending.
- 2026-04-24: BI published viewer now supports five chart-family previews, refresh control, live polling for live snapshots, and CSV export action; drilldown polish and richer UX polish remain pending.
- 2026-04-25: BI viewer now invalidates chart cache on realtime dashboard publish/outlet updates, keeps selection summary visible, and exports filtered CSV; deeper drilldown polish remains pending.
- 2026-04-24: Auth/RBAC thin slice now exists with contract types, dev-token gateway roles/permissions, and route gates; production OIDC/JWT/persisted policy remains pending.
- 2026-04-24: streaming fixture/window/checkpoint MVP now processes fixture batches with window summaries, lag/backpressure/watermark diagnostics, and checkpoint offsets; Kafka/NATS and exactly-once proof remain pending.
- 2026-04-24: GPU execution MVP now includes registry-aware worker execution, mock workload completion metadata, and CPU fallback; real CUDA kernels and multi-GPU scheduling remain pending.
- Current route shell, durable event log, Hub trust gates, BI publish/viewer, monitor diagnostics, and worker-lane lifecycle are valuable Alpha foundations.
- Biggest gap is not UI shell; remaining biggest gaps are production Arrow/DataFrames node execution, deeper BI drilldown/viewer polish, production OIDC/RBAC, production streaming adapters/exactly-once, real CUDA GPU compute.
- Any new requirement/change must update contracts, Julia structs/routes, frontend behavior, tests, tracker/checkpoint, and this TODO when relevant.

- 2026-04-25: BRD traceability automation now validates every checked P0/P1 TODO item against `docs/brd-traceability.md` code/test evidence links.
- 2026-04-28: production materialization adapter seam now supports configured reader/writer callbacks for Arrow/DataFrames-shaped refs with tests; package-backed object-store adapters and node scale 25 -> 75 -> 150 remain pending.
- 2026-04-28: base pack scale advanced from 25 to 35 stable Tier-1 nodes with cleanup/stat prep nodes and output-inspecting tests; scale 35 -> 75 -> 150 remains pending.

- 2026-04-29: base pack scale advanced from 35 to 50 stable Tier-1 nodes with math/window/join/reshape nodes and output-inspecting tests; scale 50 -> 75 -> 150 remains pending.
