# JuliaFlow risk register

2026-11-07 - Repository sync and hygiene (untracked in Linear): adopt
`codex/aks-69-consolidated-candidate` (03f19e1) as the single proposed `main`
state via branch `claude/sync-consolidated-main`. Every `codex/*` branch and
open Codex PR head is an ancestor of it. Hygiene only: remove the accidental
1-byte `mockdesigns/juliaflow` web commit file, replace 15 machine-specific
`known_hosts` paths in brd-traceability with `%USERPROFILE%`, enable the
project-scoped `caveman` Claude Code plugin in `.claude/settings.json`, and add
the [restart audit](restart-audit-2026-11-07.md) plus the previously untracked GPU runtime
assessment. No product behavior, requirement or acceptance status changes.
Hosted CI remains in local execution mode; no release readiness follows.

2026-10-14 - Windows verification follow-up: preserve 941f6fb's failed PostgreSQL
aggregate and live-browser hydration trace. Dataset controls now share the existing
mutation readiness/identity guard, so project hydration cannot enable schema/split
edits while application data is unavailable. Frontend 72 tests and build passed;
actual browser, exact-candidate aggregate and independent rereview remain required.
User-approved task-contained PostgreSQL 16 supports real database verification;
existing Docker/Compose were found under a per-user path, hidden by the isolated
profile, with Docker stopped. Arrow fixture cleanup logged ENOTEMPTY despite
assertions/exit 0; retain as unresolved Windows cleanup evidence. No publication,
release or human acceptance claim; Rolling remains deferred to October 19.
See [Windows runtime verification](verification-windows-runtime-2026-10-14.md).

2026-10-14 - AKS-69 / AKS-58 Windows runtime follow-up: separate bounded strict
Julia preparation from endpoint readiness, retain source-loading tests and require
physical CUDA assertions in normal compiled mode, and report measured live Julia
versions with honest stale/unavailable states. Original cold-start and raw CUDA
failures remain retained. Focused tests pass; exact aggregate and final independent
reviews are pending. Docker daemon absence blocks local container parity; CUDA
runtime/toolkit warning remains unresolved. JF-RT-002/JF-HW-001-002 evidence is
partial; native zoom, human, full fitting and wider platform acceptance remain
open. No release readiness follows. Rolling is deferred until October 19.
See [Windows runtime verification](verification-windows-runtime-2026-10-14.md).

2026-10-11 — AKS-69 local consolidation: preserve tested `5de9f799`; record
PR59’s five already-retained patches and integrate current main `7e725eb`. PR19
is a deliberate stale exclusion with branch/evidence retained. Product/workflow
content is unchanged; exact new-candidate reviews and full verification are pending.
Publication, GitHub merge, retirement and deployment remain on hold. GPU/Windows,
original-board and participant acceptance remain open. See the
[integration reconciliation](integration-consolidation-2026-10-11.md).

2026-10-10 — bounded final UI reconciliation: dark utility header now uses the
approved #202333 surface token; light theme and header/navigation layout unchanged.
Over-limit chart guidance names saved project evidence, avoiding a false promise
that older selected runs appear in the latest-four history view. Final exact
candidate browser/review/fullgate still required; no full-board/human acceptance.

2026-10-10 — independent SEC-A11Y-1 review of9a155ef found quadratic label
amplification; approval withheld. Corrected presentation tables use a single full
column-name key plus compact pair references, with explicit64KiB UTF-8-label /
5,000-row display limits and8MiB HTML/CSV export limits. Oversized views report
unavailability/rejection without changing immutable evidence. Release history
caption also corrected. Failed preliminary browser/harness and original9a review
remain retained; corrected exact-candidate rereviews/browser/fullgate required.

2026-10-10 — authorized AKS-44/AKS-64 accessibility follow-up: strengthen light
status and dark avatar/ready-badge contrast without replacing Wada83 tokens;
use interactive Plotly group semantics and named keyboard-focusable table regions.
Progressive structured tables show immutable Pearson/pair counts, complete scatter
pairs and finite distribution observations with captured axis units; report HTML
adds escaped equivalents and labeled numeric scatter scales. Sequence numbers are
not source row IDs, and renderer-chosen histogram bins are not claimed as stored.
No analysis algorithm, source identity, API payload or nine-section layout changes.
Focused regressions, actual browser zoom/axe/keyboard checks, affected independent
reviews and exact clean-candidate full local gate remain required. Prior866c335
22-phase pass and unexplained original timeout are preserved separately. Human
DA/DS/assistive-technology, full design, physicalGPU/widerplatform acceptance remain
open. No push/PR/hosted/billing change under the account cost pause.

2026-10-10 — adjacent NUM-1 scoped-summary correction: independent review
confirmed that a checksum-bound CSV `[1e-200,2e-200,3e-200]` persisted false zero
mean/std. The finding was recorded and read back on AKS-44 before remediation.
Scoped means use compensated summation to retain finite cancellation terms
(`[1e300,1,-1e300]` now retains 1/3), with unrounded results; summaries calculate standard
deviation using shifted, scaled deviations; genuine constant/cancellation zeros
remain valid and unrepresentable results remain explicitly unavailable. Legacy
unscoped helper semantics remain unchanged. New checksum-bound precision
regressions and independent rereview are required. Prior f4de42a correctness
clearance is superseded. Its aggregate run was canceled after six passed phases
and retained as canceled evidence, not a full pass. Earlier 3165022 results remain
revision-bound. No publication or readiness claim follows from these changes.

2026-10-10 — AKS-44 review corrections: invalid tiny-input Pearson values and
near-constant cancellation can misstate immutable evidence; failed-refresh or
partial-axis draft loss can discard user work; blank unavailable cells can hide
numerical limits. NUM-1/UI-1/UI-2 were recorded/read back before correction.
Reference-shifted/scaled correlation, identity-free draft retention, paired-axis
run/save guards, explicit unavailable labels and regressions address the triggers.
Independent source rereview accepted the corrections within its recorded scope;
fresh exact-candidate aggregate verification remains required. Wider numerical,
cross-process/platform and participant risks are not closed by bounded review or
the earlier `3165022` release pass.

## Current review-method qualification — 2026-10-10

The user approved [independent local security review](agent-tooling.md#independent-local-security-review)
when a scoped plugin's required capabilities are unavailable. Canonical diff
scanning currently lacks `start_codex_security_prompt_only_scan` after discovery;
retrieved plugin preflight/storage rules remain unchanged. Missing tooling does
not resolve authorization, path, execution, persistence, or evidence risks.
Independent coverage, reproducible controls, finding dispositions, and final
candidate clearance are still required; author self-audit is not approval.

Product commit `3165022190236100d9e0ab85f96c9c74eda94ad7` passed all 22 local
release phases on its exact clean tree. Physical GPU and optional platform checks
retain their skips; participant/accessibility, complete original-board fidelity,
wider runtime/platform, and administrative merge requirements remain open.
Development publication requires its applicable checks and independent reviews;
milestone acceptance and merge/release authorization are separate. This instruction
change closes no product risk and waives no finding or verification gate.

2026-10-10 final preservation correction: selecting another dataset retains saved and unsaved findings linked to their original project-owned runs, clears dataset-specific filters/axes, and prevents selecting a run from another dataset as current evidence. Reports identify each result dataset and verify every referenced source snapshot. Focused frontend/real-route regressions and the new clean-candidate gate must cover this correction; the earlier candidate gate was canceled, not passed.

2026-10-10 — user-authorized Durable Analyse Data implementation (AKS-44, related AKS-47/48/49 and AKS-53 evidence rules), based on unmerged PR #60 at `62d626b599bc49671a6b9f2e7a620b7660b2d7b5`. This is the next product increment after Create Project; release-roadmap M2 hardware and the full BRD local-v1/GPU/compiler/platform requirements remain unchanged. The user's implementation instruction authorizes this bounded Analyse Data UI within the existing nine-section shell.

Measured-source refresh, explicit question/filters/axes, pairwise original-row numeric evidence, immutable checksummed run artifacts and executable replay, separately editable findings, revision-checked saving, and presentation HTML/summary CSV exports are implemented. Saved metadata remains compatible with historical projects; absent historical scope/provenance is not invented. Source/schema changes invalidate current views; modeling still requires separate population/target/split choices. Overlapping project mutations reject explicitly before ownership transfer; no mutex is held during file I/O. Unsaved drafts survive route changes within the current browser session; gateway saves are required for restart durability.

The qualified analysis path remains unquoted CSV ≤1,000 rows / 8 MiB and summary/Pearson correlation on schema-enabled numeric columns. Actual computation is CPU in the gateway, with workerComputed=false; no GPU success is inferred. The signed Julia plugin passed unchanged integrity checks; implementation/debugging/concurrency and React/browser guidance are in use. See [implementation and verification](verification-durable-analysis.md). Exact-candidate gates, independent review, original-board comparison and real user/Data Analyst/Data Scientist acceptance remain distinct requirements; no issue is marked Done and no merge/deployment is claimed.

2026-10-09 — user-approved bounded Create Project increment (AKS-49 hydration acceptance; related AKS-47/48). The explicit task approval permits this Explorer/Data increment while preserving unrelated frontend freeze. Explorer retains its nine sections and adds saved-project selection, Create project and independent optional-folder writing. Project inventory loads independently of workflows, creation uses the existing gateway API and exact returned-ID readback, and uncertain POST outcomes inspect inventory without blind retry or name-only reconciliation. Selection generations reject late opening/import/update results. Reopening uses only saved dataset metadata and states that full profile/preview details are unavailable; it never automatically reimports. Wada #83 light/dark variables, locally bundled Inter, numeric typography and theme-aware labeled charts retain the specified design boundary.

Focused frontend tests and the real empty-repository smoke verify duplicate prevention, failure/readback retry, remembered/explicit selection, bounded CSV profiling, optional-folder rejection, lost POST responses, late import isolation and browser-plus-gateway restart against the same isolated data root. Existing CSV 1,000-row / 8 MiB / unquoted / unique-header / checksum guards are unchanged. Playwright is pinned to 1.64.0 with its compatible managed Chromium; system Chromium is not substituted. The new smoke is a required release phase and local delivery rejects its absence. Final exact-candidate aggregate verification and independent review evidence must pass before any push. User/Data Analyst/Data Scientist acceptance, wider local-v1/GPU qualification, native Windows/Docker certification, merge and deployment remain open. Original approved board images were unavailable; no board comparison is claimed. See [bounded implementation evidence](verification-create-project.md).


2026-10-02 manual-review remediation risks: confirmed project-specific authorization bypass and denied-project collection disclosure, public real-file inventory, replaceable execution/evaluation provenance, incorrect final F1/AUC, mismatched Data identity, generated-code metadata injection and sparse historical rendering failures block combined acceptance. User approved their minimal remediation and limited frontend exception; AKS-41/53/48/56 remain In Progress. Preserve normalized unchanged evidence echoes and historical repository loading while rejecting client-created execution state, check actual inferred/derived project identity before side effects, and do not substitute fixture evidence for withheld live inventory. Baseline `5ceff418` passed 20/20 local phases and browser 5/5; revised code needs new focused runtime controls, independent review and full gate. Other platform, GPU, inherited realtime and unresolved registry-ownership risks are not silently closed.

2026-10-02 tracker recording gate resolved: exact approved profiling follow-up posted to AKS-48 and verified, status In Progress. Source hashes and upstream PR #58 base still match. Development branch publication carries the validated bounded correction and preserved CI replays; full release/platform/GPU qualification, picker/persona acceptance and shared-job provenance/transaction limits remain open. No completion or deployment inference from publication.

2026-10-01 final profiling review/runtime result: four source findings accepted and dedicated HTTP 65/65 plus complete gateway 1,639 pass / zero fail / two root-permission skips passed on unchanged accepted hashes. Invalid-name rejection now proves no managed artifact/project-job mutation; import/update/reload/real-source analysis passes. Existing shared-copy retention on later storage faults, cross-resource transaction limits, full release/hardware/other-platform and broader CSV scope remain open. No publication or release claim.

2026-10-01 second review failure-path correction: malformed import strings now reject before managed file creation; project changes occur on a copy until persistence. Later job/storage faults can leave a verified unreferenced checksum-addressed CSV retained for diagnosis/reuse; no rollback deletes shared files. Repository/worker persistence is not a cross-resource transaction. This bounded policy and the new invalid-name artifact/state regression await HTTP/runtime validation and rereview.

2026-10-01 independent review identified project source round-trip rejection, numeric preview lexical sorting and missing-label collisions. The revised bounded candidate uses real checksum-addressed managed CSV copies for project datasets, typed numeric/null preview and a distinct missing sentinel with collision-free labels. Lightweight regressions pass; actual HTTP update/reload/downstream and broader gateway validation remain pending CI resource clearance and independent rereview. Managed copy materialization is new local I/O and must retain confinement and conflict rejection; no broader ingestion/worker claim.

2026-10-01 isolated profiling correction candidate: local import previously validated a source then displayed hardcoded quality/profile/chart values and invented derived artifact refs. After correcting two failures on the initial candidate, the corrected WSL Julia 1.12.7 affected slice passed 1,501 assertions, zero failed, with two existing root-permission skips; parser (14) and strict HTTP (12) boundaries are included. Larger/quoted/non-CSV files explicitly fail. Review/full release gates, downstream simple CSV limits and source mutation after profiling remain open. The existing worker-tick job record does not establish that a worker computed this gateway-side profile.


WSL memory pressure persists outside Julia's GC heap: the 4 GiB VM exhausted
its default 1 GiB swap in the aggregate rerun. Each Julia job now provisions
3 GiB temporary swap with path/UUID-verified bounded cleanup; failed cleanup
retains storage and blocks promotion. Full unattended verification is pending.

2026-09-30 local release blocker: HTTP.jl closes rejected upgrade connections
without the gateway advertising closure, allowing client reuse to hit
`ECONNRESET`. The minimal probe reproduced the failure; a response-only
`Connection: close` repair preserves 401/403 and origin/auth checks. The patched
browser suite passed 5/5; aggregate release verification remains pending, and failed candidate `9520979`
cannot promote. Tracker disclosure permission remains pending.

2026-09-30 AKS-69 resource diagnosis: cold release-candidate `jfci-1790781620409-a973c060` at `846ae73` passed six release phases and repository (100) / worker (221) assertions before the WSL service stopped responding (`0x8007274c`) during gateway tests. The VM reached its configured 4 GiB resident limit; no kernel OOM record was found, so memory pressure is suspected, not proven. Scoped termination of the dedicated distro recovered it. Run status failed, cleanup failed, evidence finalization passed; database storage remains. WSL jobs now use Julia's verified CLI `--heap-size-hint=1500M` and one precompile worker, recorded in job summaries. No tests, skips or deadlines change; recovery needs full rerun.

## 2026-09-30 - local CI/CD continuation (AKS-69)

The user selected local CI with hosted quality jobs skipped while local mode is active, superseding the earlier unchanged-workflow boundary. A tracked execution policy selects local or hosted execution; mapped local quality commands remain mandatory. Local CD means a versioned source-and-built-web package promoted only after a complete clean same-candidate release-candidate run, checksummed evidence and successful cleanup. It is not an offline installer, native Windows/Docker certification, external deployment or permission to merge. No product or hardware gate is waived. Original planning edits and historical evidence are preserved. Full execution results remain pending; see [local CI](local-ci.md).


## 2026-09-25 — M1/M2 active risks

AKS-69 remains exposed to Windows host interruption and unfinalized full-profile summaries; a partial WSL web pass does not close local-profile verification. Automatic PR #57 CI at `890d820` passed its Debian release job, but physical CUDA skipped and no review/merge or native Windows/Docker claim follows. AKS-58 removes the known registry-to-success misreport. A selected native Windows RTX 5080 completed a bounded allocation, operation, synchronization and readback with matching device identity after a dynamic-load world-age repair, while CUDA.jl still warns of a 13.2/13.4 precompile/runtime mismatch. The opt-in full worker test still fails GPUCompiler kernel compilation in the larger Julia 1.13 process, so complete worker GPU execution is unproven. WSL/Debian parity, pressure cases and broad workflow acceleration remain unproven; exact-head GitHub jobs could not start because of the account payment/spending-limit condition. Required-GPU rejection and CPU-only project evidence remain the safe behavior. [Current hardware record](verification-m2-hardware.md).

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

2026-10-10 accessibility review follow-up: give the existing labeled Visualize capabilities container its semantic group role. Preserve content, navigation and approved palette. Exact-candidate browser/axe and complete release verification remain required; manual SVG contrast and participant acceptance remain separate.
