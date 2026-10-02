# JuliaFlow project tracker

2026-10-02 AKS-48/53 bounded profiling follow-up: user authorized the repository-required tracker write; comment `08c4e330-3cf1-4823-9b40-cb213cb1c952` posted to existing AKS-48 and read back exactly, issue stays In Progress. Real-file profiling source/runtime gates passed; unchanged reviewed hashes and live PR #58 base permit the authorized development publication handoff. Five AKS-69/55 replays remain distinct and hardware files unchanged. No issue Done, merge or release claim.

2026-10-01 final profiling verification: parent confirmed independent acceptance of all four findings and CI resource clearance. Accepted eight source hashes match after validation. Dedicated HTTP 65/65; complete WSL Julia 1.12.7 affected slice 1,639 pass / zero fail / two existing root-permission skips, exit zero in 674.38 seconds; Node contracts 63 pass / three platform skips; frontend/browser-tooling TypeScript checks pass. Uncommitted isolated candidate awaits authoritative issue/remote branch reconciliation and publication; no GPU/release claim.

2026-10-01 second review: original three findings accepted by source rereview; an invalid datasetName could still leave a failed-import artifact. Request normalization now precedes writes; project mutation uses a deepcopy until save. HTTP regression checks invalid names with unique valid source bytes and unchanged project/job/file state. Later storage failures retain shared managed copies by policy. Final runtime/rereview/publication gates remain open.

2026-10-01 review changes requested: P1 project source contract mismatch and P2 preview/chart correctness addressed in the uncommitted isolated candidate. Actual managed CSV bytes are materialized and checksummed; external source is provenance only. Standalone Julia 32/32, focused Node contracts 9/9, frontend typecheck and diff check pass. HTTP/gateway reruns, independent rereview, authoritative issue ownership and publication remain open. CI/hardware branches preserved.

2026-10-01 local reconciliation candidate (untracked pending Linear readback): `codex/reconcile-profiling` combines PR #58 hardware head with five local AKS-69/55 commits and adds bounded real-file CSV profiling. Corrected WSL Julia 1.12.7 affected gateway slice passed 1,501 assertions, zero failed, two existing root-permission skips (709.85 seconds); Node contracts passed 63, three platform skips. Review and full release gates remain open. No remote write, GPU worker certification, or release claim.


AKS-69 resource lifecycle: scoped WSL swap preparation/cleanup is now in the
runner, replacing manual activation that disappears across distro shutdown.
The real cleanup failure/success probe passed; same-candidate aggregate and
profile validation remain required. No host boot settings were edited.

2026-09-30 AKS-69/55: candidate `9520979` reached all 16 pre-browser release
phases, then failed one of five browser tests on rejected-upgrade connection
reuse. Cleanup/evidence passed and CD rejected promotion. A minimal HTTP probe
isolates the missing close response header; the local transport fix and stronger
browser assertion passed the affected suite (5/5, exit 0); full validation
remains pending. Linear disclosure was
rejected by automatic review; no issue status or completion claim changed.

2026-09-30 AKS-69 resource diagnosis: cold release-candidate `jfci-1790781620409-a973c060` at `846ae73` passed six release phases and repository (100) / worker (221) assertions before the WSL service stopped responding (`0x8007274c`) during gateway tests. The VM reached its configured 4 GiB resident limit; no kernel OOM record was found, so memory pressure is suspected, not proven. Scoped termination of the dedicated distro recovered it. Run status failed, cleanup failed, evidence finalization passed; database storage remains. WSL jobs now use Julia's verified CLI `--heap-size-hint=1500M` and one precompile worker, recorded in job summaries. No tests, skips or deadlines change; recovery needs full rerun.

2026-09-30 AKS-69 follow-up: archive round-trip found Windows tar output uses CRLF; normalize archive entries before checking required files. Regression exercises a real Git archive, built-web copy and extraction. Delivery validates explicit no-skip flags and exact release job commands. Focused delivery tests pass; full product run remains pending.

## 2026-09-30 - local CI/CD continuation (AKS-69)

The user selected local CI with hosted quality jobs skipped while local mode is active, superseding the earlier unchanged-workflow boundary. A tracked execution policy selects local or hosted execution; mapped local quality commands remain mandatory. Local CD means a versioned source-and-built-web package promoted only after a complete clean same-candidate release-candidate run, checksummed evidence and successful cleanup. It is not an offline installer, native Windows/Docker certification, external deployment or permission to merge. No product or hardware gate is waived. Original planning edits and historical evidence are preserved. Full execution results remain pending; see [local CI](local-ci.md).


AKS-69 / M1 and AKS-58 / M2 checkpoint, 2026-09-25: scoped Codex AKS-41/56 backend review at `e436a7c` found no critical/high issue; a submitted independent GitHub review and full integration gates remain open. At `890d820` / `a0bfc232`, the mapped WSL web-only PR run passed as a partial profile, while interrupted full profiles remain unresolved. Automatic PR #57 CI at `890d820` passed web, Julia and Debian release including five live-backend browser tests; physical CUDA skipped. AKS-58 is In Progress in draft PR #58: registry hints are simulated, visible NVIDIA inventory is separate from an operation-proven device, CPU project jobs report CPU, and required GPU rejects unsupported execution. Windows Julia 1.13.0 ordinary worker, project-contract, repository, helper, API, CPU smoke and TS contract slices passed; a selected physical RTX 5080 passed bounded CUDA probe and affine output/device verification, with a CUDA.jl precompile/runtime warning still present. The opt-in full worker test fails GPUCompiler kernel compilation in the larger process, so full worker GPU acceptance remains open. Exact-head GitHub jobs did not start because of an account payment/spending-limit condition. Complete WSL and same-candidate gates, then obtain submitted review. [M2 record](verification-m2-hardware.md).

AKS-69 WSL cold diagnosis, 2026-09-23: full PR run `jfci-1790185465769-088b455a` at `f912cc7` passed all mapped jobs, including bootstrap readiness and five browser tests. It needed a targeted manual stop of an owned Vite preview descendant after the tests because npm-parent-only cleanup left the output pipe open. The smoke cleanup repair is now in the candidate; an unattended exact-head cold/warm rerun is required. Fresh-depot `REPL` and 282-package precompilation progressed; no deadlock or deadline repair was justified. [Evidence record](verification-local-ci-aks69.md).

AKS-69 WSL reliability candidate, 2026-09-23: concurrent evidence finalization now serializes completion, retention and manifest writes across processes; an active run cannot become purge-eligible during its own finalization. WSL PostgreSQL shutdown must be verified before owned job storage removal, with its log copied first. Cleanup and evidence-finalization failures are reported separately from executed test outcomes and cause a nonzero runner exit. Six-process retention regression passed; full WSL profiles and precompile diagnosis remain pending. Hosted Debian remains paused.

AKS-69 local evidence retention, 2026-09-23: user requested a rolling three-run logger window. WSL and Docker runners now purge only verified completed local CI run directories older than the newest three after finalization. The current summary records recent statuses and purged IDs; active/unverified directories are left for manual review. Focused WSL web run `jfci-1790184607879-059e23a7` at `a1c0379` verified nine completed-run purges, three retained completed runs and one unfinalized legacy exception. Earlier local artifact paths have expired under this policy. GitHub checks and separately governed historical evidence are unaffected.

AKS-69 WSL pivot, 2026-09-23: the user selected a dedicated Ubuntu 24.04 WSL instance to run local CI while Docker reinstall reports MSI detection. The distro uses verified Canonical image bytes and Node 25.9.0 / Julia 1.12.7 / PostgreSQL 16. Cold PR run `jfci-1790180924900-2f46c765` at `af1f87b` passed web and Julia; the release job was manually stopped at Julia precompilation within `smoke-local-bootstrap`, before readiness assertions, with later phases not_run. Exact logs and summaries are retained under `artifacts/local-ci/` in the AKS-69 worktree. Full WSL, Docker-specific, Windows-native and GitHub gates remain open.

AKS-69 focused verification: Windows runner 13 pass / 1 POSIX skip; WSL Node 25.9.0 runner 13 pass / 1 Windows-only skip. New Windows descendant cleanup is directly verified. Existing npm test passed (workspace tests plus contracts: 58 pass / 2 POSIX skips), build passed, workflow parity and control/BRD/whitespace gates passed. Container image, service isolation, cold/warm product suites and native Windows full release are not verified while Docker is unavailable.

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


Reconciled 2026-09-20 · [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination) · Owner: Akshay.

## Current delivery

The separately committed AKS-57 document revision (`f3be33e`) updates the canonical BRD to internal v0.5.0, rewrites Plan/roadmap/next steps, maps 32 requirement IDs to issues and acceptance, and preserves the dated v0.4.1 snapshot and 46 historical mappings. AKS-50 now adds bounded startup diagnostics on the isolated integration branch; frontend implementation remains frozen. [Verification record](verification-brd-v0.5.0.md).

| Lane | Current state | Next bounded action |
| --- | --- | --- |
| Documentation / AKS-57 | Separate documentation commit preserved; snapshot checkout fix verified | Review artifact and verified Linear readback; preserve open product/release gates. |
| M1 / existing AKS-38/41/50/51/52/53–56 | Remediation drafts #40/#47–55 unmerged, no submitted reviews; web/Julia pass, Debian cancelled/failed | Hosted diagnostic boundary confirmed; verify the compilation and AKS-68 cleanup repairs on matching Windows/Debian candidate. |
| M2 / AKS-58 | Todo / High | Real discovery, actual binding, strict GPU/fallback and resource evidence. |
| M3 / AKS-59/60/61 | Todo / High | Runtime/contracts/compiler and scalable data, after bounded prerequisite clearance. |
| M4 / AKS-60/62/63 | Todo / High | Verify all six numerical stage categories plus meaningful CPU-function compilation and benchmarks. |
| M5 / AKS-64 | In Progress / High, Revision 2 retained | Complete nine-route/state/persona design in parallel; explicit final approval remains required. |
| M6 / existing AKS-45–49 | Existing In Progress statuses preserved; frontend frozen | After approval, implement onboarding/state/hydration, analysis/model/lifecycle and compute UI. |
| M7 / AKS-65/66 | Todo / High | Local Windows compiler worker and offline Windows EXE/Linux-Docker/hardware/release certification. |
| Deferred / AKS-67 | Todo / Medium | Qualify additional vendors/devices separately. |

All new work is assigned to Akshay. Original project description remains intact with a dated v0.5.0 appendix and linked roadmap. Existing issue descriptions get scoped requirement pointers; priorities/owners/statuses are preserved. New dependencies are read back; no comments/messages to people or product Done transitions. [Issue links, exact PR heads and evidence limits](source-reconciliation-2026-09-20.md).

Current gaps: <=1,000 unquoted rows; immutable materialized plans; broader transforms/composition proposed; AKS-49 hydration 404 unfixed; mock GPU labels/device-binding gaps; no compiler or broad training proof; incomplete design approval/persona coverage; no same-candidate full release/hardware/package proof. Older local 1,492 assertions and five browser scenarios retain revision attribution and PostgreSQL skip.

## AKS-50 integration execution

One integration PR and merge commit are authorized after required checks and reviews. Original Windows bootstrap failed after 60.38 seconds; diagnostics show `/health` ECONNREFUSED while the child is alive in module loading at the unchanged 60-second deadline. Cleanup closes the child and pipes. Root-cause repair and hosted confirmation remain open. Hosted diagnostic tests exposed deadline-abort error replacement; the correction preserves the earlier failure and adds a hanging-retry regression (13 startup checks pass; one POSIX-only Windows skip). Docker is restored; metadata/full release checks are pending. [Evidence and gates](verification-m1-integration.md).

## Retained historical tracker context

The following AKS-51-era entries remain historical; their “current” statements and next actions are superseded by the v0.5.0 tracker above.

## AKS-51 scope and evidence

- Preserved the original AGENTS edits, the detached Playwright CI patch, branch SHA inventory, and a verified Git bundle outside the repository. Original checkout contents remain user-owned.
- Deleted 15 remote branch tips only after merged-PR head and zero-ahead-of-main verification; readback confirmed removal. Enabled automatic deletion of future merged branches. Main, all open-PR branches, and the closed-unmerged branch are retained.
- Deleted five obsolete local branches after confirming their tips exactly match merged PR heads, their trees match the corresponding merge commits, and those merges are contained in main. The original refs remain recoverable from the verified bundle. Pruned stale remote-tracking refs.
- Compact AGENTS and current plan/TODO/risks replace repeated histories and missing skills. Eight exact source blobs from `a70ea67` are retained under `docs/archive/2026-09-20/`, including the two concept BRDs moved out of the root. SHA-256 manifest checks preserve original bytes, all 46 checked milestone titles, and every original risk ID.
- Control validation now combines a committed baseline with local changes, fails unavailable CI baselines, preserves required files, excludes only untracked designated outputs, and requires documentation proportionate to product versus maintenance changes. Tests exercise positive and rejection cases in real temporary Git repositories.
- Both hosted release paths install locked JavaScript dependencies before Playwright binaries. Checkout history supports committed-diff validation. No product assertions, timeouts, or release phases are weakened.

Local verification: `npm run test` passes 22 frontend tests and 21 contract/maintenance tests, including 11 control-validator and 3 archive tests; `npm run build`, all 10 desktop/mobile Chromium tests, workflow lint, and both control validators pass. BRD traceability retains 46 checked items. The checkpoint records skips and any subsequent hosted results. These are maintenance checks, not new product/release acceptance.

## Retention exceptions and remaining gaps

The 423 MiB Git temporary-file deletion encountered read-only files; forced deletion was rejected by automatic approval review. Files remain retained, not reclaimed. Tooling source/evaluation custody, link-backed test material, model caches, and worktrees attached to existing Codex tasks or containing ignored evidence/environments remain preserved rather than being declared disposable. The original staging bundle is not a product dependency after routing changes, but is retained for cross-harness/tooling provenance.

PR #39 remains the explicitly retained unmerged fallback until PR #40 merges. No issue is marked Done, no PR is merged, and no tag/release/deployment/protection change is part of this maintenance slice.

## Historical tracker

[The pre-cleanup tracker](archive/2026-09-20/project-tracker.md) retains prior scope, evidence, and decisions. [The archive index](archive/2026-09-20/README.md) binds those bytes to their source commit and checksums. Current acceptance is owned by Linear and the current control set.
