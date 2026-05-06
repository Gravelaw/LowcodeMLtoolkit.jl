# JuliaFlow TODO

Last updated: 2026-05-06
Source: BRD gap review against `JuliaFlow_BRD_v1.0.docx` and current code.
Plan: `.omx/plans/brd-gap-review-2026-04-24.md`; current endgame plan: `.omx/plans/repo-brd-endgame-2026-04-25.md`; current next-step plan: `docs/plans/next-p0-oidc-rbac-hardening-2026-05-03.md`; active risks: `docs/risk-register.md`

## P0 — Required Before Phase 1 / Alpha Complete

1. [x] Base node pack first reality pass: 25 Tier-1 base nodes registered; transform/aggregate/model/table nodes materialize inline tabular rows with tests.
2. [x] External-ref materialization seam: base nodes resolve external Arrow-shaped refs via metadata store/loader and file JSON/JSONL fixtures without losing Arrow IPC payload boundaries.
3. [x] Production Arrow/DataFrames materialization: local object-store source/sink roundtrip, callback adapter seam, named service-backed adapter registry, package-backed Arrow/DataFrames local object-store `.arrow`/`.feather`/`.ipc` execution, provider-neutral remote object-store service adapter, and 150 stable base nodes are implemented with tests; provider-specific cloud deployment hardening remains outside this P0 slice.
4. [x] BI chart-data seam: published dashboard chart-data API, typed client path, OpenAPI schema, gateway auth reuse, and viewer row/field rendering.
5. [x] BI published artifact datasets: publish snapshots now persist BI outlet rows and chart-data reads return dataset-backed rows when present.
6. [x] BI semantic/cache/export slice: chart-data now infers dimensions/measures from rows, returns cache/live metadata, and exposes CSV export.
7. [x] BI live/render UX slice: published viewer now supports 5 family previews, manual refresh, live polling for live snapshots, cross-filter selection, and export CSV action.
8. [x] BI interaction hardening slice: realtime invalidation beyond polling, viewer cross-filter selection, filtered export, and selection summaries.
9. [x] BI viewer polish follow-up: published dashboard viewer now supports filter-aware chart/row drilldown, selected-row detail inspection, filtered/full CSV export, and selected-row JSON export with frontend test coverage.
10. [x] Auth/RBAC thin contract slice: auth context types, workspace roles, resource permissions, dev-token gateway gates, dashboard share/workspace separation.
11. [ ] Production OIDC/RBAC hardening: OIDC/JWT validation seam, JWKS/discovery key resolution with rotation tests, persisted role/resource policy repository, bounded audit query API, read-only policy/audit visibility, editable role/resource-policy mutation UX, persisted user/workspace directory admin UX, active directory runtime enforcement, directory self-lockout guard, and RS256 RSA/JWKS discovery validation are implemented; external live-IdP smoke and PostgreSQL runtime evidence remain; broader local security review is documented.
12. [x] Streaming fixture/window/checkpoint MVP: fixture adapter batches, bounded policy batches, window summaries, lag/backpressure/watermark diagnostics, checkpoint offsets.
13. [ ] Streaming production hardening: fixture replay duplicate suppression, committed-offset metadata, idempotency keys, sink transaction IDs, and Kafka/NATS adapter contract metadata are implemented; runtime Kafka/NATS clients, durable replay runner, production watermarking, and external sink transactions remain.
14. [x] GPU execution MVP: hardware registry summary, mock GPU workload execution, CPU fallback, worker execution beyond status promotion.
15. [ ] GPU production hardening: real CUDA/KernelAbstractions kernels, device memory ops, worker isolation guarantees, and multi-GPU scheduling.

## P1 — Next Alpha Hardening

1. [ ] Hub publish/install hardening: artifact hashes, compatibility sandbox command, publish UX, private/offline mirror fixture.
2. [ ] Components/control-flow contracts: containers, components, loop start/end, switch/case, try/catch, parallel chunk validation.
3. [ ] Observability/perf gates: OTel/Prometheus seams, 1,000-node render harness, node dispatch microbench, coverage thresholds.

## P2 — Beta/GA Foundation

1. [ ] Deployment hardening: replace ArgoCD placeholders with real deployments/services/ingress/secrets and Helm/Kustomize production overlays.
2. [x] BRD traceability automation: maintain `docs/brd-traceability.md`; fail milestone claim if TODO item lacks test/evidence links.
3. [x] Node-library scale roadmap: staged taxonomy reached 150 stable nodes with quality tiers and compatibility tests; 300+ ecosystem breadth remains Beta/GA roadmap work.

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
- Biggest gap is not UI shell; remaining biggest gaps are provider-specific cloud deployment hardening, deeper BI drilldown/viewer polish, production OIDC/RBAC, production streaming adapters/exactly-once, and real CUDA GPU compute.
- Any new requirement/change must update contracts, Julia structs/routes, frontend behavior, tests, tracker/checkpoint, and this TODO when relevant.

- 2026-04-25: BRD traceability automation now validates every checked P0/P1 TODO item against `docs/brd-traceability.md` code/test evidence links.
- 2026-04-28: production materialization adapter seam now supports configured reader/writer callbacks for Arrow/DataFrames-shaped refs with tests; package-backed local object-store adapters exist; provider-specific cloud deployment hardening remains pending.
- 2026-04-28: base pack scale advanced from 25 to 35 stable Tier-1 nodes with cleanup/stat prep nodes and output-inspecting tests; scale 35 -> 75 -> 150 remains pending.

- 2026-04-29: base pack scale advanced from 35 to 50 stable Tier-1 nodes with math/window/join/reshape nodes and output-inspecting tests.
- 2026-04-30: base pack scale advanced from 50 to 75 stable Tier-1 nodes with date/time, group/window, join/enrich, BI-prep, profile, hash, and whitespace nodes plus output-inspecting tests; named service-backed adapter registry mitigates dependency-choice risk, while remote/cloud object-store adapters and scale 100 -> 150 remain pending.

- 2026-04-30: base pack scale advanced from 75 to 100 stable Tier-1 nodes and package-backed Arrow/DataFrames local object-store materialization now reads/writes `.arrow`, `.feather`, and `.ipc` refs behind `enable_arrow_dataframe_adapter`; remote/cloud object-store adapters and scale 100 -> 150 remain pending.

- 2026-05-01: base pack scale advanced from 100 to 125 stable Tier-1 nodes with advanced stats, ML scoring, stream prep, and Hub/package helper nodes plus output-inspecting tests; remote/cloud object-store adapters and scale 125 -> 150 remain pending.

- 2026-05-01: provider-neutral remote object-store service adapter now transfers Arrow IPC base64 envelopes for remote refs, and base pack reached 150 stable nodes with quality/governance/streaming/GPU-helper additions plus output-inspecting tests.
- 2026-05-03: BI published viewer now adds filter-aware chart/row drilldown, selected-row detail inspection, filtered/full CSV export controls, and selected-row JSON export.
- 2026-05-03: planning update selects production OIDC/JWT/RBAC hardening as the next P0 lane, with streaming and GPU production hardening queued after; see `docs/plans/next-p0-oidc-rbac-hardening-2026-05-03.md` and `docs/risk-register.md`.
- 2026-05-03: production OIDC/RBAC first slice adds HS256 OIDC-style JWT validation seam, persisted role/resource policies, bounded/redacted audit action query API, OpenAPI/TS contracts, and Julia/contract tests; live IdP JWKS/RSA and admin UI hardening remain before P0 item 11 can be checked.
- 2026-05-03: OIDC/JWT hardening now supports discovery/JWKS key resolution with `kid` lookup and rotation tests for HS256 JWKS fixtures; RSA/live IdP validation and admin UI remain before P0 item 11 can be checked.

- 2026-05-04: Settings now includes read-only security admin visibility for auth mode, OIDC discovery/JWKS status, role bindings, resource policies, and redacted audit actions; editable admin UX and RSA/live IdP validation remain before P0 item 11 can be checked.

- 2026-05-04: Settings security admin now supports editable role-binding and resource-policy draft mutations, saves through the persisted auth-policy API, and has frontend coverage for update payloads; RSA/live IdP validation and persisted user/workspace directory UI remain before P0 item 11 can be checked.

- 2026-05-05: Auth directory admin slice adds persisted user/workspace directory contracts, file/PostgreSQL-ready repository support, gateway read/update API with audit events, Settings directory editing UX, active directory runtime enforcement, directory self-lockout guard, frontend coverage, and Julia route/repository tests; external live-IdP smoke and PostgreSQL runtime evidence remain before P0 item 11 can be checked; broader local security review is documented.

- 2026-05-06: RS256 RSA/JWKS validation slice adds no-new-dependency PKCS#1 v1.5 SHA-256 signature verification against discovery/JWKS metadata, valid/tampered RS256 tests, and keeps external live-IdP smoke, PostgreSQL runtime evidence, and broader security review pending before P0 item 11 can be checked.

- 2026-05-06: Broader local auth security review documented no critical/high/medium findings after the 2048-bit RS256 modulus hardening; external live-IdP smoke and PostgreSQL runtime evidence remain before P0 item 11 can be checked.

- 2026-05-06: Streaming exactly-once fixture slice adds committed-offset metadata, sink transaction IDs, idempotency keys, replay duplicate suppression, Kafka/NATS adapter contract metadata, contract/OpenAPI fields, and Julia/contract coverage; runtime Kafka/NATS clients, durable replay runner, production watermarking, and external sink transactions remain before P0 item 13 can be checked.
