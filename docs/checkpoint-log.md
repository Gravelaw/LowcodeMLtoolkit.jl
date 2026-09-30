# JuliaFlow checkpoint log

2026-09-30 AKS-69/55: release run `jfci-1790783265022-9992c09c` at `9520979`
finished with 16 passing release phases and browser 4 passed / 1 failed
(`ECONNRESET` on rejected cross-origin upgrade). Cleanup and evidence passed;
last three gates not run. CD rejected it with exit 1, no current pointer.
HTTP.jl 1.11.0 minimal probe reproduced 401 then ECONNRESET; adding a close
response header yielded 401 then 403, exit 0. The patched browser suite passed
5/5 tests in 49.6 seconds, exit 0, with automatic process cleanup and the new
close-header assertion. Aggregate same-candidate validation remains pending.
No auth/origin assertion, timeout or retry changed. Automatic review
rejected the Linear diagnosis update; the local record is preserved pending
permission to disclose. The user explicitly authorized continuing the local
repair and aggregate rerun; no alternate external write is authorized.

2026-09-30 AKS-69 resource diagnosis: cold release-candidate `jfci-1790781620409-a973c060` at `846ae73` passed six release phases and repository (100) / worker (221) assertions before the WSL service stopped responding (`0x8007274c`) during gateway tests. The VM reached its configured 4 GiB resident limit; no kernel OOM record was found, so memory pressure is suspected, not proven. Scoped termination of the dedicated distro recovered it. Run status failed, cleanup failed, evidence finalization passed; database storage remains. WSL jobs now use Julia's verified CLI `--heap-size-hint=1500M` and one precompile worker, recorded in job summaries. No tests, skips or deadlines change; recovery needs full rerun.

2026-09-30 AKS-69 follow-up: archive round-trip found Windows tar output uses CRLF; normalize archive entries before checking required files. Regression exercises a real Git archive, built-web copy and extraction. Delivery validates explicit no-skip flags and exact release job commands. Focused delivery tests pass; full product run remains pending.

## 2026-09-30 - local CI/CD continuation (AKS-69)

The user selected local CI with hosted quality jobs skipped while local mode is active, superseding the earlier unchanged-workflow boundary. A tracked execution policy selects local or hosted execution; mapped local quality commands remain mandatory. Local CD means a versioned source-and-built-web package promoted only after a complete clean same-candidate release-candidate run, checksummed evidence and successful cleanup. It is not an offline installer, native Windows/Docker certification, external deployment or permission to merge. No product or hardware gate is waived. Original planning edits and historical evidence are preserved. Full execution results remain pending; see [local CI](local-ci.md).


AKS-69 WSL full cold diagnostic, 2026-09-23: run `jfci-1790185465769-088b455a` at `f912cc7` passed web, Julia, release, PostgreSQL and five live-backend browser tests; bootstrap health became ready in 6.282 seconds after fresh-depot precompilation. The run was manually assisted only after browser assertions passed: an owned Vite descendant survived npm-parent termination and held a pipe open. Verified its command and run-owned working directory, sent targeted SIGTERM, and observed release/control validators finish. The smoke script now signals POSIX process groups. Preserve this assisted outcome as diagnosis and rerun the final candidate unattended. [Hashes and phase boundaries](verification-local-ci-aks69.md).

AKS-69 reliability checkpoint, 2026-09-23: from `ec4d021`, reproduced the completed-summary-before-manifest retention race in code review and added a cross-process finalization lock. A six-finalizer test retained three complete manifests; Windows focused runner tests passed 17 with two platform skips. WSL cleanup now verifies PostgreSQL shutdown and preserves evidence and owned storage on failure. Next: isolated-depot precompile diagnosis, then freeze a candidate for full cold/warm PR, push and validation-only release-candidate profiles. No hosted Debian run or publication.

AKS-69 local retention, 2026-09-23: added shared three-completed-run evidence retention for WSL and Docker. Pass/fail/partial summaries remain available for the next two runs; older verified local run directories are removed after a run finalizes. Windows runner tests passed 16 with two platform skips; WSL tests passed 17 with one Windows-only skip. Focused WSL web run `jfci-1790184607879-059e23a7` at `a1c0379` passed as a partial profile and purged nine older completed runs, retaining the current run, prior partial run and prior failed run. One legacy unfinalized `running` directory remains reported as unverified. A direct recursive removal of that directory was rejected by automatic approval review, so it was preserved.

AKS-69 WSL pivot, 2026-09-23: imported a separate verified Ubuntu 24.04.5 WSL distro and installed Node 25.9.0, Julia 1.12.7 and PostgreSQL 16; existing `ubn` was left intact. Added a WSL backend that uses the same mapped commands with per-job clean checkout, PostgreSQL state and evidence. At candidate `af1f87b`, cold PR run `jfci-1790180924900-2f46c765` passed web and Julia, including PostgreSQL-backed tests. Its release job reached `smoke-local-bootstrap` but Julia dependency precompilation ceased making progress and the run was manually terminated after more than eight idle minutes. Later smoke/browser phases were not run. The retained artifact shows no established bootstrap readiness defect. Full WSL release, Windows, Docker and hosted checks remain open.

AKS-69 follow-up: bounded pipe draining and creation-time-scoped Windows descendant cleanup pass focused Windows and WSL tests. Docker cold/warm attempts stop at preflight with all jobs not_run; these are retained infrastructure failures, not release verification.

## 2026-09-22 — AKS-69 local-first CI; hosted Debian paused

The user approved complete local CI execution while keeping hosted Debian diagnosis paused. AKS-69 owns isolated Docker PR/push/release-candidate profiles, workflow parity, streaming logs and durable evidence. GitHub workflows/check/review requirements remain unchanged; PR #56 at e436a7c is unmerged. Its latest hosted Debian result is cancelled, not passed. See [local CI](local-ci.md).

Docker Desktop currently cannot start its Windows inference socket. Non-destructive runtime-directory preservation did not resolve it; no volumes were deleted or factory reset performed. The user subsequently uninstalled Docker; reinstall currently reports MSI detection, with only a reboot-required Docker registry marker found in inspected registrations. Local runner unit/process checks can proceed, but container cold/warm and PostgreSQL-backed platform gates remain unverified. Failures stay visible; no Done or release claim.

After local infrastructure, obtain scoped AKS-41/56 backend review clearance and reconcile AKS-68 evidence, then implement AKS-58. Full AKS-38 persona/release completion is not a prerequisite for bounded hardware work. Continue AKS-59/61, then AKS-60/62/63 in dependency order. Revision 3 design approval is already recorded; participant/accessibility acceptance remains open and frontend implementation frozen.


## 2026-09-21 — resumed AKS-50 request-compilation repair

The user resumed Debian remediation using the TypeSafe AI skill. Hosted f113e909 run 35527192291 disproved sufficiency of the earlier compilation-policy repair: modules loaded at 10.631 s, state initialized at 19.428 s, and the listener started at 19.434 s, but the first health request still exceeded 60 s. The retained termination stack enters LLVM compilation through healthcheck and route_request. The last ECONNREFUSED predates the listening milestone; it does not establish that the listener never opened.

The bounded repair loads the existing JuliaFlowMonorepo package from the gateway entrypoint and precompiles the request dispatcher during dependency preparation. It executes no warmup request, creates no appliance state at package import, and preserves health payloads, authentication, assertions and deadlines. Fresh Windows package routing improved from 28.7 s to 6.8 s through the first successful response; actual npm run smoke:local-bootstrap passed at 11.346 s readiness. Contracts: 46 pass, one POSIX-only Windows skip. Hosted verification and required reviews remain pending; this is not a release or merge clearance. See [retained diagnosis and evidence](verification-m1-integration.md).

## 2026-09-20 — candidate f113e90 gate failure and Revision 3 handoff

Clean Windows `verify:release` at `f113e909` passed setup, contracts, build and workspace tests, then stopped in the Julia repository suite: 100 checks passed, but PostgreSQL test cleanup invoked dynamically loaded LibPQ methods directly and raised world-age errors. Eight artifact files remain retained; summary SHA-256 `2fa3732d7564dbd2b3cf542b37e7819003a23cf578d766f277d4f1e8462f959d`, Julia log SHA-256 `a1c9d6224e4a0d6feb0dece2771dda913c5fa57efdd1503da03956361fbd7122`. Later phases did not run. Separate AKS-68 owns the two-line helper correction to existing world-age-safe repository wrappers, followed by focused real-PostgreSQL and clean full-candidate reruns. No assertions or deadlines are relaxed. Focused real-PostgreSQL verification passed 100 repository and 275 payload checks (375 total); both schema cleanup and connection cleanup completed. Log SHA-256 `4e33f47ebd6ca741b943ebd965342a399ef749ca0fbbcef437fa9a6905aa072d`.

AKS-64 delivered [Revision 3 design and its review package](verification-design-r3.md). All nine routes and both 1,000-row journeys are reviewable; heuristic/prototype checks passed, participant sessions remain zero, final design approval was explicitly granted by the user after reviewability. Frontend implementation stays frozen. Integration review and matching Windows/Debian gates remain open; no merge or release claim.

## AKS-50 bounded repair ready for candidate verification

Normal dependency and gateway compilation fixes the reproduced Windows bootstrap with original MLJ code: module load 9.807 s, state ready 18.328 s, health ready 57.891 s; all existing smoke assertions pass within unchanged deadlines. Source compilation previously exceeded 60 s before state initialization. The smaller two-invocation policy correction is retained; optional-import experiments remain only in evidence. Startup diagnostic regressions pass 15 checks, with one explicit POSIX-only Windows skip. Docker/PostgreSQL is ready. Full same-candidate Windows/Debian gates and combined/required reviews remain pending and block merge. [Exact diagnosis and retained outcomes](verification-m1-integration.md).


## 2026-09-20 — AKS-50 preserved integration and startup diagnostics

Preserved separate AKS-57 commit `f3be33e` and created isolated `codex/aks-50-stabilize-integration` without rebasing/squashing. Retained PR #55 Debian artifact 10608053036 with verified SHA-256. Original Windows startup reproduces the 60-second failure. Diagnostics locate module loading, before state/listener milestones, with a live child and ECONNREFUSED; cleanup closes pipes and process. Underlying repair and hosted confirmation remain open.

Contract suite: 43 pass, one explicit POSIX termination skip on Windows. Startup coverage includes success, spawn/early-exit failures, refusal, invalid/non-ready responses, deadline, redaction and cleanup. Snapshot-scoped Git attributes repair Windows CRLF conversion without changing the original BRD snapshot or its manifest; all nine archive hashes pass. Candidate dependencies instantiated after retaining a stale-manifest failure. Existing npm CLI verified with task-local launchers; no global repair. Docker engine restored, metadata gates pending.

Hosted diagnostic run 35526439547 failed the new malformed-JSON assertion because its final deadline abort replaced the earlier SyntaxError. Preserve the earlier diagnosis on abort; add a hanging-retry regression without changing assertions/timeouts. The artifact is retained under SHA-256 `bf78852c2e72660b62820769b238dfa30d17cd0d4d15a2d43a67db368f12ee1f`. Startup rerun: 13 passed, one POSIX-only Windows skip. Next: confirm hosted bootstrap diagnosis, establish the smallest repair, run full clean same-candidate Windows/Debian verification and combined review. AKS-64 design proceeds independently; frontend frozen. No merge/release claim. [Verification](verification-m1-integration.md).

## 2026-09-20 — AKS-57 BRD v0.5.0 and roadmap/tracker implementation

Started clean at approved `c363e0086552334fc2268222550ea031c548b4f9` in an isolated worktree; branch `codex/aks-57-brd-v050-roadmap`. Scope is documents and authorized Linear updates only. BRD internal v0.5.0 keeps its canonical filename; the exact v0.4.1 Git blob is retained in a new dated SHA-256 snapshot. Existing archives, source artifacts, signed tooling, inherited product files and 46 historical mappings remain preserved.

Reconciled the three source tasks, source/design artifacts, official Reactant/CUDA/Docker constraints and live GitHub/Linear. All PRs #40/#47–55 are open drafts with zero submitted reviews and web/Julia success; Debian #47–51 cancelled, #40/#52–55 failed. Latest #55 run 35518798354 fails verify:release; root cause is not diagnosed here. Prior 1,492 gateway/boundary assertions and five browser scenarios remain historical with PostgreSQL skipped. No fresh product pass is claimed.

Implemented 32 stable requirements, M1–M7 roadmap with parallel M5 design, bounded next action and success/rejection acceptance. Added AKS-57 High/In Progress coordination and AKS-58–66 High/Todo release requirements plus AKS-67 Medium/Todo deferred compatibility, all Akshay. Existing work reused and owners/priorities/statuses preserved. Project context retained with v0.5.0 appendix; readback verifies issues/dependencies and project. No product Done transitions or messages/comments to people.

Frontend remains frozen until explicit final design approval. GPU preparation/EDA/chart-data/fitting/inference/evaluation and meaningful CPU-oriented compiler integration are mandatory first-release gates; unsupported regions keep CPU reasons and required-GPU rejection. Windows EXE/Linux-Docker, native NVIDIA plus opt-in authenticated/confined local Windows compiler worker are selected platforms. Current 1,000-row/immutable-plan safeguards stay; AKS-49 hydration remains unfixed.

Documentation checks, archive/link/mapping integrity and final readback: [verification](verification-brd-v0.5.0.md). Direct Node repository validators are authorized because npm launcher points to a missing CLI; no system repair/install. Product tests, browser/Julia/hardware/compiler/packaging and full release gates are not run. No publication, merge, tag, release, deployment or destructive cleanup.

Next bounded action: AKS-50 exact-head Debian diagnosis, then bounded M1 review/integration/verification; AKS-64 design may progress in parallel. Rollback is a scoped documentation revision using the retained snapshot and explicit tracker correction, no data migration.

## Earlier checkpoint records

Entries below are retained unchanged from the baseline and retain their original revisions, outcomes and temporal meaning.

## 2026-09-20 - AKS-56 migration smoke fixture correction

Base `7e89658` / draft PR #54. Debian run `35515125167` reached local migration smoke and rejected its incomplete registry seed under the existing contract. The seed now supplies the required fields with explicit storage-fixture model/metric labels; no production validation, backup assertion or timeout is changed. `npm run smoke:local-migration` passes on Windows: one workflow and one model-registry record restored, with the expected missing artifact reported. Control-document and BRD checks accompany the separate maintenance PR. Fresh hosted release results, review and merge remain open.


## 2026-09-20 - AKS-54 persisted split membership locally verified

Base `142f3eb` / draft PR #53. New checksummed Arrow membership artifacts bind the source and locked plan to concrete train/validation/test rows. Training, tuning, evaluation and built-in numeric standardization reuse those rows; train-only feature eligibility and estimator decisions do not inspect final-test labels. Grouped, time and depth strategies preserve group/order boundaries. Incomplete locks/folds, altered membership, changed source bytes and unsupported strategies reject before successful result jobs. Historical unproven membership is not backfilled. Final verification passes 1,072 API, 37 authority, 261 real-evidence and 122 split assertions in 588.88 seconds, including real route and existing-UI grouped selection, repository round trips and fixed-membership counterfactuals. Five live-browser scenarios pass. Focused helper/contract/frontend checks, build and control validators pass; one PostgreSQL integration skip remains explicit. Draft PR #54 at `7e89658` is In Review; hosted Julia/Debian checks and human review remain open. Frontend application files remain frozen.

AKS-53 is now In Review in draft PR #53. Hosted web/Julia checks pass for #50-#53. The exact-head Debian #52 release gate failed during local-bootstrap startup; logs/artifacts are retained and AKS-50 has the follow-up. No release claim or merge authorization.

## 2026-09-20 — AKS-53 real evidence guards locally verified

Base `3308a87` / draft PR #52. Strict release/local-appliance actions reject missing, unsuitable and synthetic result evidence before saving completed jobs or result artifacts. Project changes are staged on copies. Stored fallback approvals cannot enable export, registration, lifecycle approval or deployment. Retraining uses measured local trials; training preflight rejects unavailable sources before execution acceptance and strict metrics contain measured values only. Browser verification exposed and corrected native-classifier dispatch that previously hid behind baseline evaluation and synthetic drift. Final verification passes: gateway 1,069, authority 37, real-evidence boundary 261 (including unreadable-file checks), tuning 152, repository 53 plus one explicit PostgreSQL integration skip, project contract boundary 275, Node contracts 30, frontend tests 27 and build. All four browser scenarios pass in 28.4 seconds. Control-document sync, BRD traceability and diff checks pass. CUDA cache/runtime and world-age warnings are retained; no GPU hardware-success claim. No frontend source edits. AKS-54 membership/fit-state design has started; implementation follows on a separate branch.


## 2026-09-20 — AKS-56 compatible project contracts locally verified

Base `268561d` / draft PR #51. Runtime project children use the local OpenAPI reference closure; populated resource evidence is strict, historical missing/empty evidence remains unavailable, and new execution producers require evidence. Request and file/PostgreSQL write boundaries reject malformed records before mutation. A mixed native/JSON3 persistence round-trip failure was found and corrected without weakening validation. Julia dependency instantiation, TypeScript client/compiler tests and build pass. Final checks: gateway 1,069 plus 37 authority assertions; project boundary 275; repository 53 plus one explicit PostgreSQL integration skip; worker 221; jobs 51; core 13; contracts 30; frontend 27; live browser 3/3. Redacted prediction-contract response evidence is distinct from the private input URI. Control-document, BRD and diff checks pass. Hosted candidate checks and review remain open. No frontend edits or storage migration.

## 2026-09-20 � AKS-41 managed path confinement under verification

Baseline `ea765a7` / draft PR #50. AKS-55 is In Review with local checks passing. The next issue-specific branch confines managed source/output paths, backup checks and appliance metadata bootstrap through one canonical boundary. Existing root aliases and missing ordinary outputs remain valid. Local sources pass 36 existing + 87 boundary checks with no skips; tuning passes 152 checks; appliance bootstrap passes. The single candidate review completed; both confirmed findings have passing regressions. Full gateway verification passes 1,069 API and 37 authority assertions; control-document sync, BRD traceability and diff checks pass; draft publication and hosted review remain open; see the [remediation report](blocker-remediation-2026-09-20.md). No merge or release.

## 2026-09-20 — AKS-55 browser authority locally verified

Started from `87aa8166` on a new issue-specific branch. Baseline local-appliance probe accepted an untrusted-origin, unauthenticated project creation (201). Launcher token/bootstrap and gateway REST/realtime boundaries are patched without frontend application edits. API gateway: 1,069 pass; boundary: 37 pass; realtime: 73 pass; audit/OIDC: 46 pass; cleanup: 5 pass; contracts: 26 pass; frontend: 27 pass. Bootstrap and runtime-config checks pass. The independent candidate review completed and its confirmed findings were fixed; all three final live-browser scenarios pass, including log checks for connection errors and leaked credentials. Control-document sync against `87aa8166`, BRD traceability and diff checks pass. Draft PR publication and hosted review remain open. [Remediation report](blocker-remediation-2026-09-20.md) records compatibility and remaining gates. No merge, release, dependency change or destructive migration.

Separate Astra Extra High task created for editable Figma concepts from the same snapshot; current development uses Astra Medium. Direction selection permits only further design work; frontend implementation requires explicit final design approval.

## 2026-09-20 — AKS-38 current-code review and restart backlog

Reviewed dependency candidate `f9e10f3a3e5fd3c48e601e9252047de49c8bf2df` (draft PR #48), stacked on #47/#40. [Current review](restart-review-2026-09-20.md) supersedes June 21 current-state conclusions without editing historical documents; [threat model](restart-threat-model-2026-09-20.md) distinguishes configured controls from default startup and managed-reference gaps. This is a sequential agent review, not independent human approval.

Recorded blockers AKS-53 (synthetic evidence), AKS-54 (split execution/final-test isolation), AKS-55 (default browser authority), AKS-56 (resource-evidence contract consistency). Existing AKS-41/45/46/48/49/50 criteria retain managed-path, provenance, baseline-identity, real-file onboarding, accessibility and release gaps. No product repairs are included. AKS-37/39 corrected from Done to In Review after reading their July 4 completion comments and confirming PR #40 is unmerged and substrate commit `dd80817` is not in main.

Windows Julia 1.12.6 (explicit binary), Node 26.3.0/npm 12.0.0: instantiate passes; local-sources 36/36; tuning 152/152 (CUDA 13.4/13.2 runtime/precompile mismatch warning, no GPU success claim); repository 53 pass plus one explicit PostgreSQL integration skip because no test database URL was supplied. API gateway slice completed with 1,069 passes, zero skips (420.29 seconds including load). Live-backend browser smoke passes one scenario (25.8s, summary 2026-09-20T10:47:43.801Z). Its prepared managed-data positive path does not cover the new negative-path findings. Raw logs and summary remain in external task evidence. An initial worktree-local Juliaup 1.13 probe was stopped; its results are excluded.

Draft review PR #49 is stacked on dependency PR #48; AKS-40–50 received individual acceptance reconciliation comments with readback. AKS-36 retains In Progress status with explicit blocked-by relations to AKS-53–56. Its deeper-readiness gate remains blocked; this does not prevent bounded remediation. The final local results apply to product/dependency/test tree `f9e10f3`; the review branch only changes documentation.

Review control checks pass against explicit base `f9e10f3`; BRD validator passes with historical 46-item inventory; whitespace passes. No archive bytes changed. Dependency PR #48 web check passed in run 35505962100; Julia/Debian remain pending. Parent run 35501646027 has web/Julia passed and Debian still running, with no final artifact yet. No check was rerun or interrupted. Full Windows/Debian release closeout remains outside scope.

Decision: restart only bounded remediation and review; deeper persona features await blocker resolution/explicit acceptance. Review order and eventual authorized integration order are recorded in the review. Retain PR #39, PRs #41–#46, user edits, all worktrees and signed tooling. No storage cleanup or blocked deletion retry. Rollback is a scoped documentation revert; no migration.

## 2026-09-20 — AKS-52 dependency remediation and verification repairs

Baseline `ebeebfeb26357414e8243d216885cfb577001730`; isolated AKS-52 branch. [Dependency report](dependency-remediation-2026-09-20.md) maps all ten GitHub alerts/eight npm package entries and PRs #41–#46 to compatible fixed versions. Audit after clean locked install is zero. Vitest and coverage are aligned at 4.1.11; npm executable resolution repairs the reproduced hard-coded launcher failure. Five meaningful tests repair baseline coverage gaps without lowering any gate.

Windows Node 26.3.0/npm 12.0.0: clean install, contract tests (21), workspace tests (27 frontend plus 21 contracts), build, coverage (79.68% statements / 73.21% branches), and ten mocked-gateway desktop/mobile browser tests pass. Initial baseline/candidate coverage failures and launcher failure are retained in external task logs. Both control validators use the explicit cleanup baseline; whitespace is checked before and after commit. Full release verification is not run or claimed. Julia review slices and live-backend evidence belong to the separate AKS-38 review.

Signed Julia catalog verification passed against external trust: version 2.1.0, manifest `996753585e98ac66877932c1569ee2301c9a19cd3e763a3a34860498c837fc6e`; route `e82600b0-6b90-4ed3-af3c-932803660873` selected debug/workflow skills. No signed files changed. A local Juliaup wrapper initially selected 1.13.0 during environment preparation; that probe was stopped and retained, and review tests explicitly select the existing 1.12.6 binary. No Julia dependency or tracked manifest change.

PR #47 hosted run 35501646027 remains in progress at the last read; web/Julia passed. Larger source-confirmed gaps are recorded as AKS-53/54, not silently repaired. Rollback is scoped maintenance revert, with no migration. No merges, releases, tags, deployment reruns, retained-worktree or storage cleanup.

## 2026-09-20 — AKS-51 repository housekeeping and governance repair

Implementation baseline: `a70ea67eda343655f70fe336c294f8ec9e638889` from draft PR #40. The original checkout and pre-existing edits are preserved; implementation uses a separate AKS-51 worktree/branch.

### Completed changes

- Fresh GitHub comparisons allowed removal of 15 already-merged branches; deletion readback succeeded. Recovery SHAs are in the local maintenance inventory. Automatic merged-branch deletion is now enabled.
- Removed five obsolete local branches after exact merged-head/tree-equivalence checks and main containment of their merge commits; recovery bundle retains the refs. Pruned stale remote-tracking refs.
- Removed volatile/stale skill routing and repeated policies from AGENTS; current planning/risk/tracker guidance links historical snapshots instead of repeating them.
- Preserved eight source blobs with SHA-256 and byte-size evidence under `docs/archive/2026-09-20/`. Concept BRDs moved into that archive; the active governed BRD retains its path.
- Added baseline-aware control-document checks and real-Git regression tests. Product and dependency changes keep the five-document requirement; maintenance requires tracker/checkpoint evidence; documentation-only edits no longer require fabricated status churn.
- Added narrow tooling/cache ignores, preserving visibility of user-owned documentation images and all tracked paths.
- Installed project-locked JavaScript dependencies before browser binaries in both hosted release workflows; history and an explicit tag-workflow baseline support committed-diff validation.

### Local verification

- Git integrity check before housekeeping: passed, no corrupt/missing objects; dangling history was retained. Recovery bundle verification passed.
- Signed staged and installed Julia runtime: external-trust verification passed before use; no signed files were modified.
- `npm ci`: passed; npm audit reported eight existing affected package entries, tracked separately in AKS-52 (Todo).
- `node --test tests/contracts/control-doc-sync.test.mjs`: 11 passed, zero skipped.
- `node --test tests/contracts/control-doc-archive.test.mjs`: 3 passed, zero skipped; all 46 original checked titles and original risk IDs retained.
- `npm run test`: passed 22 frontend tests and 21 contract/maintenance tests, zero skips.
- `npm run build`: passed; existing large Plotly bundle warning remains.
- Project-local `npx playwright install chromium` followed by `npm run test:browser`: all 10 desktop/mobile Chromium tests passed. This fixture-backed UI gate is not the live-backend release smoke.
- `actionlint .github/workflows/ci.yml .github/workflows/release-candidate.yml`: passed.
- `npm run validate:control-doc-sync -- --base a70ea67eda343655f70fe336c294f8ec9e638889`: passed.
- `npm run validate:brd-traceability`: passed for 46 historical checked items.
- `node --check scripts/validate-control-doc-sync.mjs`: passed.
- `git diff --check`: passed after removing a trailing blank line from the compact TODO.

### Remaining work and constraints

Publish the locally verified stacked PR and read hosted status. Final staged whitespace/archive-byte checks run before commit. The authoritative Julia suite, base-extension suite, Docker/local-runtime smokes, live-backend browser smoke, and full no-skip release verifier were not rerun locally for this maintenance-only change. These release gates are not replaced by the checks above. Exact-head no-skip Windows/Debian evidence remains an AKS-36/AKS-50 acceptance gate.

Forced removal of the 19 read-only Git temporary objects was rejected by automatic approval review (`blocked by policy`); no reclamation is claimed. Retain tooling custody/source, signed packages, ignored runtime/evidence worktrees, PR #39, and unmerged PR #19's branch. No merge, tag, release, deployment, or protection changes.

## Earlier checkpoints

[Full pre-cleanup checkpoint history](archive/2026-09-20/checkpoint-log.md) is preserved byte-for-byte with [source and hash manifest](archive/2026-09-20/manifest.json). Historical success belongs to its recorded commit/platform and is not evidence for the current candidate.
