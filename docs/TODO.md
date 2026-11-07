# JuliaFlow TODO

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

2026-10-10 — AKS-44 review corrections: NUM-1 uses stable shifted/scaled Pearson
arithmetic for tiny, near-constant and opposite-extrema finite inputs. UI-1 retains
unmeasured/partial-axis drafts and rejects incomplete-axis run/save; UI-2 displays
unavailable numeric results explicitly. Recorded findings and negative/legitimate
regressions have independent final source rereview acceptance. A new clean-candidate
full release gate is still required before publication; earlier `3165022` evidence
stays revision-bound. Broader acceptance and required GitHub reviews remain open.

## Current review and publication tasks — 2026-10-10

- [ ] Obtain independent final-candidate correctness/UI/security review for
  Durable Analyse Data. Use an available scoped installed workflow or the approved
  [independent local procedure](agent-tooling.md#independent-local-security-review);
  missing canonical scan tooling is not a waiver of substantive review.
- [ ] Resolve findings and verify the final publication candidate. Retain the
  full aggregate gate: clean product commit `3165022` passed all 22 phases; this
  documentation revision is not a new product run or independent clearance.
- [ ] Publish a reviewed development branch/draft PR only after its required
  checks and reviews pass; verify remote revision, stack, checks, and review state.
- [ ] Obtain actual participant/accessibility acceptance, complete original-board
  comparison, and finish GPU/platform qualification for their applicable milestones.
  These remain open and do not automatically block bounded development publication.

Canonical diff scanning currently lacks `start_codex_security_prompt_only_scan`
after discovery. Plugin preflight/storage rules and signed Julia integrity checks
remain intact. Merge needs applicable checks/reviews and explicit action approval;
deployment, tags, and releases remain separately authorized. No issue is Done.
Historical entries below retain their dated context; current routing and gate
separation follow [AGENTS.md](../AGENTS.md).

2026-10-10 final preservation correction: selecting another dataset retains saved and unsaved findings linked to their original project-owned runs, clears dataset-specific filters/axes, and prevents selecting a run from another dataset as current evidence. Reports identify each result dataset and verify every referenced source snapshot. Focused frontend/real-route regressions and the new clean-candidate gate must cover this correction; the earlier candidate gate was canceled, not passed.

- [ ] Verify and review the Durable Analyse Data increment, then obtain user/persona acceptance; preserve wider GPU/platform/release gates.

2026-10-10 — user-authorized Durable Analyse Data implementation (AKS-44, related AKS-47/48/49 and AKS-53 evidence rules), based on unmerged PR #60 at `62d626b599bc49671a6b9f2e7a620b7660b2d7b5`. This is the next product increment after Create Project; release-roadmap M2 hardware and the full BRD local-v1/GPU/compiler/platform requirements remain unchanged. The user's implementation instruction authorizes this bounded Analyse Data UI within the existing nine-section shell.

Measured-source refresh, explicit question/filters/axes, pairwise original-row numeric evidence, immutable checksummed run artifacts and executable replay, separately editable findings, revision-checked saving, and presentation HTML/summary CSV exports are implemented. Saved metadata remains compatible with historical projects; absent historical scope/provenance is not invented. Source/schema changes invalidate current views; modeling still requires separate population/target/split choices. Overlapping project mutations reject explicitly before ownership transfer; no mutex is held during file I/O. Unsaved drafts survive route changes within the current browser session; gateway saves are required for restart durability.

The qualified analysis path remains unquoted CSV ≤1,000 rows / 8 MiB and summary/Pearson correlation on schema-enabled numeric columns. Actual computation is CPU in the gateway, with workerComputed=false; no GPU success is inferred. The signed Julia plugin passed unchanged integrity checks; implementation/debugging/concurrency and React/browser guidance are in use. See [implementation and verification](verification-durable-analysis.md). Exact-candidate gates, independent review, original-board comparison and real user/Data Analyst/Data Scientist acceptance remain distinct requirements; no issue is marked Done and no merge/deployment is claimed.

- [ ] Complete final exact-candidate gates, reviews and later user/persona acceptance for the bounded Create Project increment; do not close AKS-49 based on this increment alone.

2026-10-09 — user-approved bounded Create Project increment (AKS-49 hydration acceptance; related AKS-47/48). The explicit task approval permits this Explorer/Data increment while preserving unrelated frontend freeze. Explorer retains its nine sections and adds saved-project selection, Create project and independent optional-folder writing. Project inventory loads independently of workflows, creation uses the existing gateway API and exact returned-ID readback, and uncertain POST outcomes inspect inventory without blind retry or name-only reconciliation. Selection generations reject late opening/import/update results. Reopening uses only saved dataset metadata and states that full profile/preview details are unavailable; it never automatically reimports. Wada #83 light/dark variables, locally bundled Inter, numeric typography and theme-aware labeled charts retain the specified design boundary.

Focused frontend tests and the real empty-repository smoke verify duplicate prevention, failure/readback retry, remembered/explicit selection, bounded CSV profiling, optional-folder rejection, lost POST responses, late import isolation and browser-plus-gateway restart against the same isolated data root. Existing CSV 1,000-row / 8 MiB / unquoted / unique-header / checksum guards are unchanged. Playwright is pinned to 1.64.0 with its compatible managed Chromium; system Chromium is not substituted. The new smoke is a required release phase and local delivery rejects its absence. Final exact-candidate aggregate verification and independent review evidence must pass before any push. User/Data Analyst/Data Scientist acceptance, wider local-v1/GPU qualification, native Windows/Docker certification, merge and deployment remain open. Original approved board images were unavailable; no board comparison is claimed. See [bounded implementation evidence](verification-create-project.md).


- [ ] Complete the user-approved eight-finding manual remediation in AKS-41/53/48/56: resolved-project policy checks and filtered listing, private health inventory, server-owned executed evidence with real bindings, actual F1/AUC, exact Data identity, safe generated Julia metadata and sparse-history views. Prove original triggers reject or render safely and legitimate controls remain; obtain independent final-patch review and new exact-candidate full local release evidence. Keep unrelated frontend work frozen and project acceptance open.

- [ ] Publish and verify the reviewed `codex/reconcile-profiling` development branch. AKS-48 follow-up was recorded and read back on 2026-10-02 (comment `08c4e330-3cf1-4823-9b40-cb213cb1c952`), with status In Progress. Required affected checks/review passed on unchanged source hashes. No merge/deployment or full release/GPU completion is authorized or claimed.

- [ ] Complete authoritative issue/remote development-branch reconciliation and publication handoff for the accepted profiling correction. Final dedicated HTTP 65/65 and complete gateway slice 1,639 pass / zero fail / two existing root-permission skips; full Node contracts 63 pass / three platform skips and both frontend typechecks passed. Preserve reviewed source hashes; no merge/deploy/release qualification inferred.

- [ ] Verify the second-review failure-path fix: invalid null/number/object/array/empty datasetName must return 400 without changing project/jobs or managed artifacts. All import strings now validate before materialization. Run the dedicated HTTP and complete affected gateway gates after CI resource clearance; obtain reviewer acceptance on final hashes.

- [ ] Validate and independently rereview the three profiling review fixes: managed source round-trip/downstream compatibility, typed numeric/null preview and separate missing/category identity. Standalone Julia 32/32, focused contracts 9/9 and frontend typecheck pass; new HTTP integration and full affected gateway slice wait for the CI owner's resource window. Retained earlier gateway evidence does not certify this revised tree.

- [ ] Review and track the isolated 2026-10-01 real-file CSV profiling correction. It replaces fixture-backed import display on a bounded <=1,000-row / 8 MiB unquoted CSV path, rejects unsupported formats, and records only the actual source artifact. Corrected WSL Julia 1.12.7 gateway slice: 1,501 pass / zero fail / two existing root-permission skips; Node contracts: 63 pass / three platform skips. Full release gates remain pending; assign the correction to the appropriate AKS-48/61 scope after tracker readback.


- [ ] Verify full profiles with automatic job-owned WSL swap preparation and
  cleanup. The 64 MiB cleanup probe passed both mismatch preservation and valid
  deactivation/removal. No host configuration or test deadline changes.

- [ ] Validate the AKS-55 rejected-WebSocket connection-close repair: preserve
  exact 401/403 and unchanged-state assertions, authorized realtime success,
  then rerun full same-candidate local profiles before promotion. Candidate
  `9520979` failed 1/5 browser tests after 16 passing release phases; cleanup and
  evidence passed. Linear diagnosis update was not authorized; keep it local.
  The user explicitly authorized the repair and aggregate rerun.

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

2026-10-10 accessibility review follow-up: give the existing labeled Visualize capabilities container its semantic group role. Preserve content, navigation and approved palette. Exact-candidate browser/axe and complete release verification remain required; manual SVG contrast and participant acceptance remain separate.
