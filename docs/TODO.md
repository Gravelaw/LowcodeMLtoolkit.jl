# JuliaFlow TODO

## 2026-09-30 - local CI/CD continuation (AKS-69)

The user selected local CI with hosted quality jobs skipped while local mode is active, superseding the earlier unchanged-workflow boundary. A tracked execution policy selects local or hosted execution; mapped local quality commands remain mandatory. Local CD means a versioned source-and-built-web package promoted only after a complete clean same-candidate release-candidate run, checksummed evidence and successful cleanup. It is not an offline installer, native Windows/Docker certification, external deployment or permission to merge. No product or hardware gate is waived. Original planning edits and historical evidence are preserved. Full execution results remain pending; see [local CI](local-ci.md).


## 2026-09-25 — M1/M2 active work

- [ ] AKS-69: complete same-candidate local cold/warm PR, push and validation-only release-candidate profiles. The latest mapped WSL web-only PR job passed as a partial run; interrupted full runs remain unresolved. Automatic PR #57 CI passed web, Julia and Debian release at `890d820`, with conditional CUDA skip. Hosted Debian diagnosis is paused.
- [ ] AKS-41/56: retain the scoped Codex backend review at `e436a7c` and obtain a submitted independent GitHub review for integration clearance.
- [ ] AKS-58: resolve the opt-in full worker GPUCompiler failure after the bounded native Windows operation pass; finish CPU/RAM/disk/VRAM pressure cases, persistence/API smoke, WSL parity, exact-candidate platform gates and review. [Current evidence](verification-m2-hardware.md) is a draft with no M2 completion claim.

## 2026-09-23 — AKS-69 reliability candidate

Cross-process retention and verified WSL PostgreSQL cleanup are implemented. Diagnose the Julia precompile stall with isolated fresh/reused depots and process evidence, then run cold/warm full PR, push and validation-only release-candidate profiles at one committed head. Retain all failures and not_run phases. Hosted Debian stays paused.

## 2026-09-23 — AKS-69 WSL execution

Run the full mapped local profiles in the dedicated Ubuntu 24.04 WSL distro, record each phase and skip against the selected commit, and fix only runner infrastructure failures in AKS-69. Preserve product failures under their existing issues. WSL results do not close Docker image/network/mount, native Windows or GitHub required-check gates. Hosted Debian remains paused.

## 2026-09-22 — AKS-69 local-first CI; hosted Debian paused

The user approved complete local CI execution while keeping hosted Debian diagnosis paused. AKS-69 owns isolated Docker PR/push/release-candidate profiles, workflow parity, streaming logs and durable evidence. GitHub workflows/check/review requirements remain unchanged; PR #56 at e436a7c is unmerged. Its latest hosted Debian result is cancelled, not passed. See [local CI](local-ci.md).

Docker Desktop currently cannot start its Windows inference socket. Non-destructive runtime-directory preservation did not resolve it; no volumes were deleted or factory reset performed. The user subsequently uninstalled Docker; reinstall currently reports MSI detection, with only a reboot-required Docker registry marker found in inspected registrations. Local runner unit/process checks can proceed, but container cold/warm and PostgreSQL-backed platform gates remain unverified. Failures stay visible; no Done or release claim.

After local infrastructure, obtain scoped AKS-41/56 backend review clearance and reconcile AKS-68 evidence, then implement AKS-58. Full AKS-38 persona/release completion is not a prerequisite for bounded hardware work. Continue AKS-59/61, then AKS-60/62/63 in dependency order. Revision 3 design approval is already recorded; participant/accessibility acceptance remains open and frontend implementation frozen.


Current handoff: [Revision 3 design evidence](verification-design-r3.md) is reviewable; final design approval is recorded; participant testing remains open. AKS-68 repairs a separately reproduced PostgreSQL test-cleanup failure before the next full M1 gate.

Reconciled 2026-09-20 for [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination). [BRD v0.5.0](../business-requirements-v0.3.0.md), [roadmap](product-roadmap.md) and [acceptance](acceptance-v0.5.0.md) govern current scope. Linear owns delivery status. No new requirement is complete from this documentation revision.

## Active first-release work

- [ ] **M1 / AKS-38/41/50/51/52/53–56:** PR #56 preserves the stack and separate AKS-57 revision. The hosted f113e909 follow-up reaches the listener but times out during first-request compilation. Package dispatcher precompilation passes local bootstrap at 11.346 s; hosted confirmation is pending. Finish same-candidate Windows/Debian verification, combined review and merge gates; retain all failure artifacts and open M2–M7 criteria.
- [ ] **M2 / AKS-58, with AKS-43/56:** real CPU/RAM/disk/GPU/runtime discovery and operation probes, user preference, actual device binding, strict required-GPU rejection and truthful fallback/resource evidence.
- [ ] **M3 / AKS-59/60/61:** contract-first runtime/capabilities/planning/phase evidence, native and required compiler integration, safe memory/movement/retry, scalable local ingestion replacing <=1,000 unquoted rows without losing row/split/checksum semantics.
- [ ] **M4 / AKS-60/62/63:** verified GPU preparation/EDA/chart-data/fitting/inference/evaluation, meaningful CPU numerical package/function compilation beyond affine smoke, numerical equivalence and cold/transfer/kernel/end-to-end/resource benchmarks.
- [ ] **M5 / AKS-64, parallel:** finish all nine routes and real-file/compute/immutable-split/hydration states, independent themes/guidance/density, responsive/accessibility/persona testing and explicit final design approval.
- [ ] **M6 / AKS-45–49:** implement later approved analysis-only/modeling journeys, shared project state/invalidation, lifecycle/drift provenance, onboarding and compute UI. Frontend remains frozen; AKS-49's placeholder-project 404 is unfixed.
- [ ] **M7 / AKS-65/66 plus AKS-38/50:** explicitly enabled authenticated/confined local Windows Linux/Docker compiler worker; Windows EXE/Linux-Docker offline packages, CPU/NVIDIA hardware, migration and same-candidate Windows/Debian no-skip release proof.
- [ ] **Deferred / AKS-67:** separately verify other vendors and real multi-device execution; keep honest detection and CPU operation meanwhile.
- [ ] **Existing criterion reconciliation:** AKS-36 In Progress; AKS-37/38/39/41/51–56 In Review; AKS-40/42–50 In Progress. Preserve existing owners/priorities/statuses, candidate evidence and remaining security/ML/persona/release criteria.

Current materialized plans, assignments, folds and locks are immutable. Changed source/split creates a new plan. Numeric train-fitted standardization exists; custom transforms/automatic pipeline composition and larger data remain proposed. Revision 3 uses the supported 1,000-row example. Historical absent evidence stays unavailable.

PR #39 is retained as unmerged fallback; optional connectors/providers stay disabled/unavailable until their own gates pass. Integration publication and a merge commit are authorized only after required verification and review; deployment reruns, tags and releases are not authorized. [Source ledger](source-reconciliation-2026-09-20.md) qualifies all current claims.

## Historical bounded-slice checklist

## P0 — Required Before Phase 1 / Alpha Complete

1. [x] Base node pack first reality pass: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] External-ref materialization seam: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Production Arrow/DataFrames materialization: historical bounded-slice evidence in `docs/brd-traceability.md`.
4. [x] BI chart-data seam: historical bounded-slice evidence in `docs/brd-traceability.md`.
5. [x] BI published artifact datasets: historical bounded-slice evidence in `docs/brd-traceability.md`.
6. [x] BI semantic/cache/export slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
7. [x] BI live/render UX slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
8. [x] BI interaction hardening slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
9. [x] BI viewer polish follow-up: historical bounded-slice evidence in `docs/brd-traceability.md`.
10. [x] Auth/RBAC thin contract slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
11. [x] Production OIDC/RBAC hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
12. [x] Streaming fixture/window/checkpoint MVP: historical bounded-slice evidence in `docs/brd-traceability.md`.
13. [x] Streaming production hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
14. [x] GPU execution MVP: historical bounded-slice evidence in `docs/brd-traceability.md`.

## P1 — Next Alpha Hardening

1. [x] Hub publish/install hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] Components/control-flow contracts: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Observability/perf gates: historical bounded-slice evidence in `docs/brd-traceability.md`.

## P2 — Beta/GA Foundation

1. [x] Deployment hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] BRD traceability automation: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Node-library scale roadmap: historical bounded-slice evidence in `docs/brd-traceability.md`.

## Current Development Phase — Local-First GA Proof / Explainable Local Appliance

1. [x] BRD local-first strategy refresh: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] Agent prompt hygiene: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Local appliance bootstrap proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
4. [x] Local data estate proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
5. [x] Local metadata/database proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
6. [x] Local hardware runtime proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
7. [x] Explainability/model evidence proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
8. [x] Offline Hub proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
9. [x] Mock-aligned BRD product surface refresh: historical bounded-slice evidence in `docs/brd-traceability.md`.
10. [x] Academic reproducibility workflow: historical bounded-slice evidence in `docs/brd-traceability.md`.
11. [x] Backup/restore and migration proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
12. [x] Frontend module expansion / BI viewer row-search slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
13. [x] Frontend module expansion follow-up: historical bounded-slice evidence in `docs/brd-traceability.md`.
14. [x] Mock-aligned local product workflow vertical: historical bounded-slice evidence in `docs/brd-traceability.md`.
15. [x] Backend-backed Data and Transform product actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
16. [x] Backend-backed ML Studio experiment actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
17. [x] Backend-backed Models registry actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
18. [x] Backend-backed Visualize checkpoint/export actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
19. [x] Backend-backed Deploy packaging actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
20. [x] Mockup-aligned local-only UI redesign and browser automation: historical bounded-slice evidence in `docs/brd-traceability.md`.
21. [x] AKS-5 Stage 3 save/run/monitor lifecycle first slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
22. [x] AKS-5 Stage 3 dashboard/explainability evidence binding: historical bounded-slice evidence in `docs/brd-traceability.md`.
23. [x] AKS-5 Stage 5 release verification closure: historical bounded-slice evidence in `docs/brd-traceability.md`.
24. [x] AKS-13 live workflow metadata recovery: historical bounded-slice evidence in `docs/brd-traceability.md`.
25. [x] Explorer/Data/Transform mock parity and interactive local analytics: historical bounded-slice evidence in `docs/brd-traceability.md`.
26. [x] AKS-29 through AKS-35 parity hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
