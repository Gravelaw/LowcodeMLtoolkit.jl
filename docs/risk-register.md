# JuliaFlow risk register

2026-09-30 local release blocker: HTTP.jl closes rejected upgrade connections
without the gateway advertising closure, allowing client reuse to hit
`ECONNRESET`. The minimal probe reproduced the failure; a response-only
`Connection: close` repair preserves 401/403 and origin/auth checks. The patched
browser suite passed 5/5; aggregate release verification remains pending, and failed candidate `9520979`
cannot promote. Tracker disclosure permission remains pending.

2026-09-30 AKS-69 resource diagnosis: cold release-candidate `jfci-1790781620409-a973c060` at `846ae73` passed six release phases and repository (100) / worker (221) assertions before the WSL service stopped responding (`0x8007274c`) during gateway tests. The VM reached its configured 4 GiB resident limit; no kernel OOM record was found, so memory pressure is suspected, not proven. Scoped termination of the dedicated distro recovered it. Run status failed, cleanup failed, evidence finalization passed; database storage remains. WSL jobs now use Julia's verified CLI `--heap-size-hint=1500M` and one precompile worker, recorded in job summaries. No tests, skips or deadlines change; recovery needs full rerun.

## 2026-09-30 - local CI/CD continuation (AKS-69)

The user selected local CI with hosted quality jobs skipped while local mode is active, superseding the earlier unchanged-workflow boundary. A tracked execution policy selects local or hosted execution; mapped local quality commands remain mandatory. Local CD means a versioned source-and-built-web package promoted only after a complete clean same-candidate release-candidate run, checksummed evidence and successful cleanup. It is not an offline installer, native Windows/Docker certification, external deployment or permission to merge. No product or hardware gate is waived. Original planning edits and historical evidence are preserved. Full execution results remain pending; see [local CI](local-ci.md).


## 2026-09-23 — AKS-69 finalization risk

Simultaneous finalizers could remove a completed run while its checksum manifest was still being written. A cross-process lock now covers completion and retention, with a six-process regression. PostgreSQL stop must be verified before WSL job storage removal; cleanup and evidence failures remain visible separately from test outcomes. Full profile, Docker and Windows evidence is still required.

## 2026-09-23 — WSL execution boundary

AKS-69 now has a dedicated Ubuntu 24.04 WSL execution path because Docker Desktop cannot reinstall. Its source image and tool versions are pinned or recorded; every run needs clean-source, database, browser and evidence checks. WSL shares the Windows host kernel/network and mounts Windows drives, so this path cannot replace Docker isolation or platform packaging evidence. Keep release/review/required-check gaps open; hosted Debian diagnosis stays paused.

## 2026-09-22 — AKS-69 local-first CI; hosted Debian paused

The user approved complete local CI execution while keeping hosted Debian diagnosis paused. AKS-69 owns isolated Docker PR/push/release-candidate profiles, workflow parity, streaming logs and durable evidence. GitHub workflows/check/review requirements remain unchanged; PR #56 at e436a7c is unmerged. Its latest hosted Debian result is cancelled, not passed. See [local CI](local-ci.md).

Docker Desktop currently cannot start its Windows inference socket. Non-destructive runtime-directory preservation did not resolve it; no volumes were deleted or factory reset performed. The user subsequently uninstalled Docker; reinstall currently reports MSI detection, with only a reboot-required Docker registry marker found in inspected registrations. Local runner unit/process checks can proceed, but container cold/warm and PostgreSQL-backed platform gates remain unverified. Failures stay visible; no Done or release claim.

After local infrastructure, obtain scoped AKS-41/56 backend review clearance and reconcile AKS-68 evidence, then implement AKS-58. Full AKS-38 persona/release completion is not a prerequisite for bounded hardware work. Continue AKS-59/61, then AKS-60/62/63 in dependency order. Revision 3 design approval is already recorded; participant/accessibility acceptance remains open and frontend implementation frozen.


Reconciled 2026-09-20 for [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination). Owner: Akshay / LowCodeML. Current [BRD](../business-requirements-v0.3.0.md), [roadmap](product-roadmap.md), [sources](source-reconciliation-2026-09-20.md) and Linear own current qualifications. Historical rows below remain historical.

## Active risks and release gates

| Risk | Owner issue / milestone | Evidence, mitigation and remaining acceptance |
| --- | --- | --- |
| R-CI-RELEASE-001 | AKS-50/38, M1/M7 | c363e008 bootstrap failure reproduced: disabling compiled modules bypasses Pkg precompilation and exceeds readiness during source loading. Normal compilation alone passes Windows at 57.9 s but hosted f113e909 still fails during first-health request compilation after listener startup. Package dispatcher precompilation improves local bootstrap to 11.346 s; hosted confirmation remains open. Full Windows/hosted Debian verification and required review remain blocking gates; keep deadlines and assertions. |
| R-RESTART-001 / R-DEPENDENCY-001 | AKS-41/51/52/53–56, M1 | Candidate auth/path/contracts/strict-evidence/split/fixture repairs and dependency preparation are in unmerged drafts. Earlier local passes are revision-bound; no submitted reviews. Reuse existing scope and obtain integration/review/platform evidence. |
| R-GPU-001 / R-HW-001 | AKS-58, M2 | Mock/invented registry can overstate GPU work, device selection is not bound, required-GPU and real fallback have gaps. Real inventory/probe/binding and negative tests required; single old KA smoke is insufficient. GPU stage coverage is now mandatory first-release work. |
| R-COMPILER-001 | AKS-60/65, M3/M4/M7 | Reactant NVIDIA path documented on Linux; numerical compatibility and performance unverified. Require meaningful function compilation, equivalence/cache/control-flow tests and full costs. Native Windows uses adapters plus opt-in local Linux worker; no universal conversion. |
| R-COMPUTE-CONTRACT-001 | AKS-43/56/59, M2/M3 | Requested backend is not actual evidence. Version inventory/capability/plans/phase records across all producers/consumers; historical absence remains unavailable, no backfill. |
| R-COMPUTE-RESOURCE-001 | AKS-59/62/63, M3/M4 | RAM/VRAM/disk exhaustion, transfers and unsafe retry can corrupt results or cost more than CPU. Bounded queues, measured envelopes, pure/idempotent retry, cancellation and atomic artifacts; no hidden algorithm-error retry. |
| R-ACCELERATION-001 | AKS-60/62/63, M4 | Affine or metrics-only proof can obscure missing preparation/EDA/chart-data/training/inference/evaluation. Verify all six categories with equivalent CPU reference and actual phase evidence; preserve estimator semantics. |
| R-DATA-SCALE-001 | AKS-61/54, M3 | Current <=1,000 unquoted rows and unique headers remain bounded; Revision 3 now matches 1,000 rows. Preserve guard until verified scalable parser/materialization, checksums and immutable row/split semantics pass; no truncation. |
| R-ML-VALIDITY-001 / R-MLOPS-001 | AKS-42/45/46/54/63, M1/M4/M6 | Train-only fit, held-out/final-test isolation, immutable plans, model/baseline identity and real lifecycle evidence must survive batching/device changes. Reject stale/missing/synthetic evidence; no model swap. |
| R-FE-001 / R-DESIGN-APPROVAL-001 | AKS-64/47–50, M5/M6 | Revision 3 has nine routes, 68 theme pairs and reviewable journeys/recovery/responsive states; explicit final design approval recorded; participant sessions remain zero. Retain prototype limitations and perform participant/assistive-technology tests. Freeze frontend implementation until explicit approval. |
| R-PROJECT-HYDRATION-001 | AKS-49/64, M5/M6 | Default-project mutation 404 reproduced before hydration. Design and then implement initial-load/switch mutation disable, actual identity gate and retry/reselection. Test waits do not fix the race. |
| R-TRUST-LOCAL-001 / R-WORKER-LOCAL-001 | AKS-41/55/65, M1/M7 | Existing candidate auth/path fixes do not certify container mounts/IPC. Explicit enablement, authentication, approved roots, junction/escape rejection, credential redaction and revoke/restart tests; no silent provision/upload/remote compute. |
| R-PACKAGING-001 / R-OFFLINE-001 | AKS-66, M7 | No current EXE/Linux-Docker offline, CPU/NVIDIA/compiler and Windows WSL2 package certification. Require clean install/upgrade/recovery, prerequisite failures, metadata/Hub/backup/migration and same-candidate full release matrix. |
| R-COMPATIBILITY-001 | AKS-67, deferred | Other vendor detection/upstream support and two visible GPUs are not device execution proof. Keep CPU/unavailable behavior; qualify every claimed backend/device separately. |
| R-DS-001 / R-ARCH-DS-001 / R-CONTRACT-DS-001 / R-GATEWAY-MOD-001 | AKS-36/38/40/43/59 | Preserve project/module boundaries, Arrow IPC/TOML and focused gateway composition; code, criteria, review and product flows all required. |
| R-DOC-001 / R-DOC-002 / R-AGENT-001 | AKS-57/51 | Dated source/check readbacks and 32 requirement scenarios distinguish requirements from proof; preserve 46 mappings and hashes. Signed tooling verified against external trust; no signed files edited. |
| R-CLEANUP-001 / R-CI-001 | AKS-51 / maintainer | Preserve user-owned worktrees/artifacts, existing archive bytes and retained cleanup exceptions. No retry of prior rejected deletion, inbound webhooks or custom-node CI monitor. |

Historical mitigation labels do not satisfy v0.5.0 release gates. In particular, the historical deferred-GPU language below is superseded by required M2–M4/M7 NVIDIA stage/compiler coverage; only additional-vendor/multi-device compatibility remains deferred.

## Retained risk inventory

Every original risk ID remains below so historical mitigations can be located. Status reflects the pre-cleanup register and is not a fresh release certification; active qualifications above take precedence. Full impact, rationale, mitigation, and acceptance history remain in the immutable snapshot.

| ID | Area | Historical status |
| --- | --- | --- |
| R-LOCAL-001 | Bootstrap | Mitigated for the recorded bounded slice |
| R-DATA-001 | Local data estate | Mitigated for the recorded bounded slice |
| R-DB-001 | Local metadata | Mitigated for the recorded bounded slice |
| R-HW-001 | Local hardware | Mitigated for the recorded bounded slice |
| R-XAI-001 | Explainability | Mitigated for the recorded bounded slice |
| R-OFFLINE-001 | Offline Hub | Mitigated for the recorded bounded slice |
| R-PRODUCT-001 | Product surface | Mitigated for the recorded bounded slice |
| R-DS-001 | Data science workflow | Open |
| R-ARCH-DS-001 | Persona architecture | Open |
| R-CONTRACT-DS-001 | Persona contracts | Open |
| R-ML-VALIDITY-001 | ML validity | Open |
| R-TRUST-LOCAL-001 | Local trust boundary | Open |
| R-MLOPS-001 | MLOps lifecycle | Open |
| R-GATEWAY-MOD-001 | Gateway modularity | Open |
| R-REPRO-001 | Academic reproducibility | Mitigated for the recorded bounded slice |
| R-BACKUP-001 | Backup/restore | Mitigated for the recorded bounded slice |
| R-DOC-002 | Documentation hygiene | Mitigated for the recorded bounded slice |
| R-AGENT-001 | Agent routing | Mitigated for the recorded bounded slice |
| R-SEC-001 | OIDC/JWT | Mitigated for the recorded bounded slice |
| R-SEC-002 | Auth compatibility | Mitigated for the recorded bounded slice |
| R-SEC-003 | RBAC persistence | Mitigated for the recorded bounded slice |
| R-SEC-004 | Audit privacy | Mitigated for the recorded bounded slice |
| R-STREAM-001 | Streaming | Mitigated for the recorded bounded slice |
| R-GPU-001 | GPU | Deferred to final hardware-gated phase |
| R-OBS-001 | Observability/perf | Mitigated for the recorded bounded slice |
| R-OBJ-001 | Object storage | Optional |
| R-WC-001 | Components/control-flow | Mitigated for the recorded bounded slice |
| R-HUB-001 | Hub | Mitigated for the recorded bounded slice |
| R-DEP-001 | Deployment | Optional |
| R-FE-001 | Frontend scale | Mitigated for the recorded bounded slice |
| R-RUNTIME-001 | Julia runtime depth | Mitigated for the recorded bounded slice |
| R-DOC-001 | Control docs | Mitigated for the recorded bounded slice |
| R-CI-001 | CI workflow monitoring | Open |

## Scope boundaries

Keep local bootstrap, managed data estate, file/PostgreSQL metadata, local model/explainability evidence, offline Hub, reproducibility, and backup/restore. Metadata support is not database dataset-source execution. Object-store/provider production overlays and enterprise identity remain conditional compatibility work. Keep all previously designed success/failure/rejection coverage.

Update this register when a risk or accepted mitigation changes; maintenance-only edits need no invented new product risk. Link new findings to Linear before expanding committed scope. Do not classify an issue Blocked solely because CI failed, or Done solely because a PR merged.
