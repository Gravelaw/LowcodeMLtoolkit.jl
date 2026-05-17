# JuliaFlow TODO

Last updated: 2026-05-17
Source: BRD gap review against `JuliaFlow_BRD_v1.0.docx` and current code.
Plan: `Plan.md`; historical plans: `.omx/plans/brd-gap-review-2026-04-24.md`, `.omx/plans/repo-brd-endgame-2026-04-25.md`, `docs/plans/next-p0-oidc-rbac-hardening-2026-05-03.md`; active lane/risks: `docs/risk-register.md`

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
11. [x] Production OIDC/RBAC hardening: OIDC/JWT validation seam, JWKS/discovery key resolution with rotation tests, persisted role/resource policy repository, bounded audit query API, read-only policy/audit visibility, editable role/resource-policy mutation UX, persisted user/workspace directory admin UX, active directory runtime enforcement, directory self-lockout guard, RS256 RSA/JWKS discovery validation, live Keycloak RS256 smoke, PostgreSQL policy/directory persistence, and bounded audit query evidence are implemented; broader local security review is documented.
12. [x] Streaming fixture/window/checkpoint MVP: fixture adapter batches, bounded policy batches, window summaries, lag/backpressure/watermark diagnostics, checkpoint offsets.
13. [x] Streaming production hardening: fixture replay duplicate suppression, committed-offset metadata, idempotency keys, sink transaction IDs/state, Kafka/NATS adapter contract metadata, durable fixture restart replay from persisted committed offsets, policy-aware monotonic watermark state, live Kafka broker consume/replay smoke, and file-backed fenced sink idempotency evidence are implemented; NATS remains contract-supported unless separately required.
14. [x] GPU execution MVP: hardware registry summary, mock GPU workload execution, CPU fallback, worker execution beyond status promotion.

## P1 — Next Alpha Hardening

1. [x] Hub publish/install hardening: artifact hashes, SHA-256-shaped artifact hash gates, compatibility sandbox command metadata, publish UX, and private/offline mirror fixtures without local-file mirror refs.
2. [x] Components/control-flow contracts: containers, components, switch/case and parallel chunk metadata are contract-backed across TS/OpenAPI/TOML, gateway roundtrip, Julia validation, fixtures, and frontend inspector coverage; loop and try/catch schema/validation shapes exist for future runtime execution semantics.
3. [x] Observability/perf gates: Prometheus `/metrics`, OTel-style gateway/execution trace seams, 1,000-node render harness, node dispatch microbench, and real Vitest v8 coverage thresholds are implemented with P1 validation scripts.

## P2 — Beta/GA Foundation

1. [x] Deployment hardening: ArgoCD placeholders are replaced with Kustomize-backed API Gateway, Execution Service, Frontend, and provider-neutral platform dependency contract manifests; provider-specific production overlays/Helm bindings remain future environment work.
2. [x] BRD traceability automation: maintain `docs/brd-traceability.md`; fail milestone claim if TODO item lacks test/evidence links.
3. [x] Node-library scale roadmap: staged taxonomy reached 150 stable nodes with quality tiers and compatibility tests; 300+ ecosystem breadth remains Beta/GA roadmap work.

## Current Development Phase — Provider-Specific GA Proof / Module Expansion

1. [ ] Provider-specific deployment proof: add selected staging/prod overlays, secret delivery integration, server-side dry-run evidence, and auth/PostgreSQL/Kafka-or-NATS/object-store/gateway smokes.
2. [ ] Provider-specific object-store proof: run remote Arrow IPC materialization against selected S3/GCS/Azure-compatible target with externally supplied credentials and linked evidence.
3. [x] Frontend module expansion / BI viewer row-search slice: published dashboard viewer row search now filters visible chart rows and filtered CSV exports while preserving route shell, demo fallback, runtime config, and coverage gates.
4. [x] Julia runtime module expansion / loop runtime-plan slice: loop control-flow metadata now validates reachable bounded loop bodies and emits additive execution `controlFlowPlan` evidence across Julia, gateway, contracts, and Monitor UI.
5. [x] Julia runtime module expansion / try-catch runtime-plan slice: try/catch control-flow metadata now emits additive execution `controlFlowPlan` evidence with try/catch body node ids across Julia, gateway, contracts, and Monitor UI.
6. [x] Julia runtime module expansion follow-up / try-catch failure-recovery slice: failed-node telemetry for a try node now records bounded `controlFlowRecovery` catch-route evidence without terminal-failing, while uncaught failed-node telemetry still transitions to failed.
7. [x] Julia runtime module expansion follow-up / catch-node branch-state slice: worker-service now executes bounded catch branches after recovery, records `controlFlowBranchState`, surfaces deterministic catch-node BI outlet row-count results, and completes recovered executions.
8. [x] Julia runtime module expansion follow-up / DAG branch rescheduling slice: worker-service now derives bounded catch-branch DAG stages, executes independent catch nodes before dependent BI outlet nodes, persists `branchStages` / `stageResults`, and surfaces branch-stage progress in Monitor.
9. [x] Julia runtime module expansion follow-up / executor stage-schedule slice: execution records now expose bounded topological `executorSchedule` evidence with stages, lanes, worker pools, readiness barriers, max concurrency, and Monitor rendering.
10. [ ] Julia runtime module expansion follow-up: add true asynchronous multi-tick executor scheduling beyond additive stage evidence.
11. [x] Governed Hub production depth / deterministic sandbox-hash-mirror proof slice: Hub records now include install-time verification evidence; install/enable/upgrade block unsafe sandbox command shapes, artifact hash mismatches, and unsupported mirrors while disable remains a remediation path.
12. [x] Governed Hub production depth follow-up: execute allowlisted sandbox commands in an isolated fixture runner, verify downloaded artifacts against declared hashes from an artifact-store registry, and prove private/offline mirror refs through a mirror registry.
13. [ ] Governed Hub external registry/provider proof: bind sandbox/artifact/mirror verification to a selected external Hub registry or provider mirror when credentials and provider context exist.
14. [x] Control-doc sync automation: `AGENTS.md` now requires Plan/TODO/risk/tracker/checkpoint updates for every completed slice/phase/review, and `npm run validate:control-doc-sync` enforces the guard when non-control changes.

## Final Hardware-Gated Phase

1. [ ] GPU production hardening / multi-GPU closure: deterministic multi-device placement metadata, requested/selected device reporting, explicit fallback reasons, scheduler policy, worker isolation/capacity metadata, and one-device CUDA/KernelAbstractions smoke evidence exist; final closure is intentionally last because full hardware-backed worker isolation and multi-GPU scheduling proof requires a host/CI runner with >=2 visible CUDA devices.

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
- 2026-05-09: Hub publish/install hardening now adds manifest artifact hashes, sandbox command metadata, private/offline mirror refs, partner trust/compatibility blockers, gateway publish registration, frontend publish sample UX, and Julia/frontend/contract coverage; future Hub work should execute sandbox commands and verify downloaded artifacts against hashes.

- 2026-05-09: Remaining P0 live-evidence harness slice adds reproducible Keycloak/PostgreSQL, Kafka, and CUDA/KernelAbstractions smoke scripts plus worker-service Kafka JSONL replay and file-backed sink idempotency regression coverage. Auth and streaming live smokes passed locally and are linked in traceability; GPU still requires >=2 visible CUDA devices for full closure.
- 2026-05-10: GPU production hardening / multi-GPU closure moved out of P0 into the Final Hardware-Gated Phase because GPU count is an environment constraint; local one-device CUDA/KernelAbstractions evidence remains useful but cannot close multi-GPU scheduling proof.
- 2026-05-12: Components/control-flow contracts now add container, component, switch/case, loop, try/catch, and parallel chunk metadata shapes across contracts/OpenAPI/TOML, gateway request/response mapping, Julia parser/serializer/validator, fixture coverage, and frontend inspector visibility; future work should add full runtime semantics for loops and try/catch execution.
- 2026-05-12: Observability/perf first gate adds Prometheus-style `/metrics`, OpenAPI path evidence, a 1,000-node/500-connection render harness, and a Julia dispatch microbench wired through `npm run validate:perf`; coverage thresholds and fuller OTel integration remain before P1 item 3 can be checked.
- 2026-05-13: Observability/perf final P1 gate adds OTel-style trace/span seams, OpenAPI/TS health/execution trace fields, `@vitest/coverage-v8` real frontend coverage thresholds, dependency-free cross-surface coverage inventory, and `npm run validate:p1`; P1 item 3 is now checked with traceability evidence.
- 2026-05-14: P2 deployment hardening replaces placeholder ArgoCD workload intent ConfigMaps with Kustomize bases/dev overlays for API Gateway, Execution Service, Frontend, and provider-neutral platform dependency service/secret contracts; `npm run validate:k8s` validates structural YAML, Kustomize references, AppProject app-of-apps policy, placeholder removal, and renders with `kubectl kustomize` or `kustomize build` when available.
- 2026-05-14: Current development phase is Provider-Specific GA Proof plus frontend/Julia module expansion; see `Plan.md`. P0/P1/P2 local-platform slices are closed, while provider overlays/smokes, object-store proof, frontend depth, Julia runtime depth, Hub production verification, and final multi-GPU evidence remain open.
- 2026-05-14: Control-doc sync automation added: `AGENTS.md` mandates Plan/TODO/risk/tracker/checkpoint updates after slice/phase/review completion and `npm run validate:control-doc-sync` guards non-control changes.
- 2026-05-15: Frontend module expansion first slice adds BI published-viewer row search across visible chart rows, clear row-search controls, search-aware row counts, and filtered CSV export respecting both chart filter and search term.
- 2026-05-15: Julia runtime module expansion first slice adds bounded loop runtime-plan evidence: loop start/end reachability validation, body node derivation, gateway persistence/payload mapping, TS/OpenAPI `controlFlowPlan`, and Monitor UI rendering.
- 2026-05-16: Julia runtime module expansion try/catch slice adds bounded try/catch runtime-plan evidence: try/catch body node IDs now persist through Julia execution records, gateway payload mapping, TS/OpenAPI `controlFlowPlan`, and Monitor UI rendering; failure-driven node execution remains future work.
- 2026-05-16: Governed Hub production-depth deterministic proof slice adds `verification` evidence to Hub contracts/API records, blocks install/enable/upgrade on bounded sandbox command rejection, artifact hash mismatch, or unsupported mirror refs, and keeps disable as the remediation path; real isolated sandbox execution and downloaded artifact/private registry proof remain follow-up work.
- 2026-05-16: Julia runtime try/catch failure-recovery slice turns failed-node telemetry for covered try nodes into bounded `controlFlowRecovery` catch-route evidence while preserving normal failed transitions for uncaught nodes.
- 2026-05-17: Julia runtime catch-node branch-state slice executes bounded catch branches in worker-service, records `controlFlowBranchState` with worker id, completed catch node IDs, deterministic BI outlet row-count node results, and completes recovered executions.
- 2026-05-17: Julia runtime DAG branch rescheduling slice derives bounded catch-branch stages from workflow connections, executes independent catch nodes before dependent catch nodes, persists `branchStages` / `stageResults`, and renders branch-stage progress in Monitor.
- 2026-05-17: Julia runtime executor stage-schedule slice adds bounded topological `executorSchedule` evidence with stage indexes, node IDs, lanes, worker pools, readiness barriers, max concurrency, and Monitor rendering; true asynchronous multi-tick execution remains future work.
- 2026-05-17: Governed Hub isolated sandbox/artifact/mirror proof executes only allowlisted Julia extension test fixtures under `JULIAFLOW_HUB_SANDBOX_EXECUTE=1`, verifies downloaded artifact bytes through `JULIAFLOW_HUB_ARTIFACT_STORE`, resolves private/offline mirror refs through `JULIAFLOW_HUB_MIRROR_REGISTRY`, blocks missing artifacts/mirrors, and renders verification details in Hub cards.
- Any new requirement/change must update contracts, Julia structs/routes, frontend behavior, tests, tracker/checkpoint, and this TODO when relevant.

- 2026-04-25: BRD traceability automation now validates every checked P0/P1/P2 TODO item against `docs/brd-traceability.md` code/test evidence links.
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

- 2026-05-07: Streaming restart replay slice proves fixture worker recovery by syncing a fresh worker service from persisted executions and replaying from the committed checkpoint offset without reprocessing prior rows; runtime Kafka/NATS clients, production watermarking, and external sink transactions remain before P0 item 13 can be checked.

- 2026-05-07: Streaming watermark/transaction state slice honors processing-time vs event-time watermark policy with monotonic committed watermark metadata, exposes gateway/contract fields, and records fenced sink transaction state with Julia/contract coverage; runtime Kafka/NATS clients and live external sink backend evidence remain before P0 item 13 can be checked.

- 2026-05-07: GPU production-hardening prep adds deterministic multi-device placement metadata, requested/selected device reporting, explicit fallback reasons, scheduler policy, worker isolation/capacity metadata, contract/OpenAPI fields, and Julia coverage; Final hardware-gated GPU item remains unchecked until >=2-device CUDA/KernelAbstractions scheduling and hardware isolation evidence exists.

- 2026-05-08: Full verification for GPU production-hardening prep passed (`julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:brd-traceability`, `git diff --check`) plus bounded `JULIAFLOW_WORKER_ONCE=1` GPU worker smoke; Final hardware-gated GPU item remains unchecked until >=2-device CUDA/KernelAbstractions scheduling and hardware isolation evidence exists.
