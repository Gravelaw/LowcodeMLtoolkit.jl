# JuliaFlow project tracker

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

2026-10-10 — independent review remediation: AKS-44 records NUM-1 (tiny/near-constant
Pearson precision), UI-1 (failed-refresh/partial-axis draft preservation) and UI-2
(unavailable numeric-cell labels), with readback In Progress. Corrections and
focused regression tests are implemented locally; independent correctness/UI/local
security reviewers accepted the revised source hashes with recorded coverage and
limits. Browser QA on the preceding product passed
keyboard refresh/focus, console/overlay identity checks and 720 CSS-pixel reflow
equivalent to 200% on a 1440px viewport; actual browser zoom/assistive-technology
acceptance remains untested. New source requires its own clean-candidate aggregate
gate. No publication, acceptance, merge or Done claim follows from these fixes.

## Current review handoff — 2026-10-10

The user approved capability-aware project instructions, including the separate
[independent local security-review procedure](agent-tooling.md#independent-local-security-review).
Canonical Codex Security diff scan remains unavailable: tool discovery did not
expose `start_codex_security_prompt_only_scan`. Plugin procedures, signed Julia
trust checks, test assertions, and historical records remain intact. No canonical
scan or independent approval is fabricated.

Clean product candidate `3165022190236100d9e0ab85f96c9c74eda94ad7` / tree
`78dd180424d634e3cc0441151a85ac624e4adf18` passed all 22 local release phases.
Retained evidence recheck matched 32 handoff/browser files and 23 release files.
This documentation-only update does not extend that exact-candidate result to a
new commit. Independent correctness/UI/security review remains the next bounded
action; findings and final checks must be resolved before development publication.
Participant/accessibility, original-board, GPU/platform acceptance, administrative
merge requirements, merge, and deployment remain separate open gates.

Fresh authenticated GitHub reads confirm main `7e725eb0e2fe74a4d4d1bec885c31ab546fb6320`
and open draft PR60 at `62d626b599bc49671a6b9f2e7a620b7660b2d7b5`, based on
`codex/reconcile-profiling` at `4d71f1ec18cc3ab7551723fd7ba21f77fc26da31`.
Branch-protection access still returned 403 on the review readback. No external
tracker state, PR, push, merge, deployment, tag, or release changed in this update.

2026-10-10 final preservation correction: selecting another dataset retains saved and unsaved findings linked to their original project-owned runs, clears dataset-specific filters/axes, and prevents selecting a run from another dataset as current evidence. Reports identify each result dataset and verify every referenced source snapshot. Focused frontend/real-route regressions and the new clean-candidate gate must cover this correction; the earlier candidate gate was canceled, not passed.

2026-10-10 — user-authorized Durable Analyse Data implementation (AKS-44, related AKS-47/48/49 and AKS-53 evidence rules), based on unmerged PR #60 at `62d626b599bc49671a6b9f2e7a620b7660b2d7b5`. This is the next product increment after Create Project; release-roadmap M2 hardware and the full BRD local-v1/GPU/compiler/platform requirements remain unchanged. The user's implementation instruction authorizes this bounded Analyse Data UI within the existing nine-section shell.

Measured-source refresh, explicit question/filters/axes, pairwise original-row numeric evidence, immutable checksummed run artifacts and executable replay, separately editable findings, revision-checked saving, and presentation HTML/summary CSV exports are implemented. Saved metadata remains compatible with historical projects; absent historical scope/provenance is not invented. Source/schema changes invalidate current views; modeling still requires separate population/target/split choices. Overlapping project mutations reject explicitly before ownership transfer; no mutex is held during file I/O. Unsaved drafts survive route changes within the current browser session; gateway saves are required for restart durability.

The qualified analysis path remains unquoted CSV ≤1,000 rows / 8 MiB and summary/Pearson correlation on schema-enabled numeric columns. Actual computation is CPU in the gateway, with workerComputed=false; no GPU success is inferred. The signed Julia plugin passed unchanged integrity checks; implementation/debugging/concurrency and React/browser guidance are in use. See [implementation and verification](verification-durable-analysis.md). Exact-candidate gates, independent review, original-board comparison and real user/Data Analyst/Data Scientist acceptance remain distinct requirements; no issue is marked Done and no merge/deployment is claimed.

2026-10-09 — user-approved bounded Create Project increment (AKS-49 hydration acceptance; related AKS-47/48). The explicit task approval permits this Explorer/Data increment while preserving unrelated frontend freeze. Explorer retains its nine sections and adds saved-project selection, Create project and independent optional-folder writing. Project inventory loads independently of workflows, creation uses the existing gateway API and exact returned-ID readback, and uncertain POST outcomes inspect inventory without blind retry or name-only reconciliation. Selection generations reject late opening/import/update results. Reopening uses only saved dataset metadata and states that full profile/preview details are unavailable; it never automatically reimports. Wada #83 light/dark variables, locally bundled Inter, numeric typography and theme-aware labeled charts retain the specified design boundary.

Focused frontend tests and the real empty-repository smoke verify duplicate prevention, failure/readback retry, remembered/explicit selection, bounded CSV profiling, optional-folder rejection, lost POST responses, late import isolation and browser-plus-gateway restart against the same isolated data root. Existing CSV 1,000-row / 8 MiB / unquoted / unique-header / checksum guards are unchanged. Playwright is pinned to 1.64.0 with its compatible managed Chromium; system Chromium is not substituted. The new smoke is a required release phase and local delivery rejects its absence. Final exact-candidate aggregate verification and independent review evidence must pass before any push. User/Data Analyst/Data Scientist acceptance, wider local-v1/GPU qualification, native Windows/Docker certification, merge and deployment remain open. Original approved board images were unavailable; no board comparison is claimed. See [bounded implementation evidence](verification-create-project.md).


2026-10-02 browser positive-fixture correction: exact candidate `035d51526f59` run `jfci-1790938118881-73bbc357` passed 16 release phases then browser 4/5. Archived evaluation response records AUC 1.0, F1 0.0 and approved=false at the unchanged 0.1 threshold; prediction export correctly rejected with 409. The live source fixture now separates the classifier feature values while preserving all 30 rows, churn labels, contract groups and tenure. Browser assertions explicitly require approved=true and F1 >= 0.1 before the positive export workflow. This is a test fixture repair; product approval, provenance and negative metric guards remain unchanged. Revised browser/full exact-candidate verification remains pending; no promotion/publication/acceptance claim.

2026-10-02 remediation verification follow-up: clean candidate `f009ff0` started the existing mapped warm push profile `jfci-1790933741546-a9a0c6c2`. Contracts/build passed; frontend Vitest reported 34 pass/3 fail because the new mismatch assertions landed in the demo test and the strict appliance mock omitted required workflow graph metadata. Corrected those test fixtures while preserving negative no-PUT and positive matching-edit assertions. Renamed a new Julia test alias to avoid the builtin Core namespace. The isolated first-candidate Julia run remains active and unchanged; preserve its terminal outcome/cleanup evidence. Revised candidate requires its own verification and independent review; no acceptance/publication/promotion claim.

2026-10-02 authorized eight-finding remediation started: explicit user approval at 09:04 UTC includes the narrow frontend exception; AKS-41/53/48/56 scope was recorded and read back In Progress before implementation. A fresh independent read-only investigator confirmed all eight boundaries and legitimate compatibility requirements. Disjoint source ownership coordinates gateway policy/privacy, executed evidence, metrics/generated code and UI identity/history fixes; heavy tests remain serialized. Preserved clean baseline `5ceff418` run `jfci-1790923907277-9d35c43a` passed 20/20, browser 5/5, cleanup/evidence passed and all 329 retained hashes matched. New fixes remain unverified; no Done, new promotion, merge or deploy claim.

2026-10-02 AKS-69 canonical browser regression: full exact `3872be2` local release run `jfci-1790919229814-4b3570c3` failed after 16 passed phases because grouped fit/apply lacked an explicit target role. Browser 4/5; cleanup/evidence passed and all 70 retained hashes matched. The bounded five-line test repair selects `churn` as target through the persisted Data UI, retaining every grouping/checksum/final-lock/auth assertion and timeout. Independently reviewed correction passed the complete five-browser suite in `jfci-1790923131805-a84b4022` (45.2 seconds), with cleanup passed. AKS-69 description records/readbacks this fixture defect and remains In Progress. Create a clean local test/control-only candidate for the required full rerun; no production/frontend implementation change. Approved manual review accounted for all 154 combined changed paths and found unresolved product authorization/evidence/UI findings; runtime success cannot waive them. No replacement publication, package promotion, merge or deployment.

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

## October 2 remediation fixture validation follow-up

The first mapped warm push at f009ff0 failed frontend fixture assertions and new gateway policy setup. Main gateway 1089/1089, repository 100/100 and worker 216/216 passed; new policy tests had 41 passes, 11 failures and 2 errors after three create fixtures omitted required splitPlans.createdAt. Corrected the schema-complete policy and server-owned-evidence fixtures and added creation diagnostics, preserving rejection and legitimate-control assertions. No product guard changed. Cleanup and evidence finalization passed; all 33 retained hashes verified. AKS-69 records the defect and regression repair scope; issue remains In Progress. Focused new tests, final independent patch review and a complete exact-candidate release gate remain pending. No promotion or publication.

## October 2 evidence regression correction

Focused f17cd58 metric/code-generation checks passed 131/131. Policy checks passed 85 assertions; one test expected 400 for the unchanged baseline 500 ambiguity mapping, corrected to assert the exact existing error and unchanged state. Server-owned aggregate admission passed 35/35; strict genuine producer tests exposed source resolver mismatch: artifact resolution added a data/ directory to local://data/raw references. Use the existing confined dataset reader for the original-source checksum check at all three consumers while retaining report/model artifact resolvers and every identity, producer and digest check. Map the new server-owned execution evidence and executed-training-plan admission errors to HTTP400. AKS-53 records the regression correction; required focused rerun, full profile, final independent review and exact release remain pending. Failed diagnostics and cleanup receipts retained; no promotion/publication.

## October 2 independent review closure correction

The fresh read-only final review traced all eight boundaries on 786e817 and found no confirmed surviving MAN-1 through MAN-7 bypass. Its one remaining Low MAN-8 finding was independently confirmed: optional historical split fractions rendered invented zero percentages. Data now renders unavailable for omitted/nonfinite fractions and preserves recorded values including genuine0%. Added rendered missing, nonfinite and75%/25%/0% controls. AKS-56 records this bounded correction within the approved frontend exception. The earlier786e817 mapped push continues from its isolated snapshot; it cannot certify this changed candidate. Independent delta readback, required exact-candidate checks and full20-phase release remain pending. No acceptance, promotion or publication.
