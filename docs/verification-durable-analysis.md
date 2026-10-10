# Durable Analyse Data verification

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

## 2026-10-10 independent review corrections

Independent correctness review reproduced NUM-1: tiny finite CSV values yielded
Pearson 1.008264. First-fix rereview additionally reproduced cancellation for
consecutive representable values at offsets 1 and 1e300. Correlation now shifts
each vector by a reference before scaling/centering; only overflowing finite
differences use an original-magnitude scaled fallback. Constant detection uses
actual value equality rather than an underflow-prone unscaled variance. Regression
controls include tiny/ordinary/large scales, positive/negative/nonperfect
association, consecutive-float offsets, opposite extrema, original-row missingness,
and actual scoped CSV evidence. This is an arithmetic correction, not clamping
an invalid answer into range; summary overflow remains explicitly unavailable.

Independent UI review reproduced UI-1 question loss when initial measured refresh
failed, partial-axis loss across remounts, and UI-2 blank unavailable result cells.
The browser-session draft type now carries editable scope text independently of
source identity; run/save still acquire real checksums from a successful measured
refresh. Partial axes block both operations rather than silently disappearing on
save. The UI labels nullish result numbers unavailable without mutating immutable
evidence. Failed-refresh/remount/retry, partial-axis run/save guards and unavailable
cell rendering have focused regressions. All findings were recorded/read back in
AKS-44 before correction; independent final rereview and new aggregate evidence
remain distinct requirements from the earlier `3165022` pass.

Final independent source rereview accepted the corrections: 31 focused numerical
assertions and 726 seeded BigFloat-reference assertions passed; six external UI
regressions and eight workspace tests passed; independent local security passed
35 helper/replay controls, 53 durable route assertions and 15 authorization
controls, with another 35 controls on revised source. Exact reviewed source hashes:
Statistics `81ab58ee07f2a00a2ab5afcc72e8b7740f6bfdbdd9ab27cdd1ef98b742f834dc`;
alignment tests `0194b2c3f55784de428b8ed08043def78a168d5987d3669ba248815198271469`;
AnalyseDataPanel `85699c31d058f50c173024ced2271e8861ed1a83911b3b5087762869bf29dd72`;
workspace tests `f4113a297d56deb54b9423abb3fffeccd8dcb29be66b941677539df6ca39f384`.
Rereview is bounded by its recorded coverage and assumptions; it does not certify
broader acceptance, replace required GitHub approvals or validate an unrun final
aggregate candidate. The earlier failed numerical fix and review-harness error
remain retained evidence rather than passing results.

The user authorized implementation on 2026-10-10 after the fresh rebaseline and milestone plan. The isolated branch starts at unmerged draft PR #60, `62d626b599bc49671a6b9f2e7a620b7660b2d7b5` (tree `9b3d8ae0d51f33a67fb8f00b63549b0ed48005d7`), preserving the M1 Create Project stack. Main remains a separate baseline; this increment does not establish that the stack has merged. AKS-44 and related AKS-47/48/49 remain In Progress, with independent review and broader acceptance open. No remote issue, PR or delivery status is changed by this local implementation.

## Implemented journey

Open or create a project, import a real bounded CSV, select Visualize / EDA, inspect measured data without reimporting, enter a question and explicit filters, optionally choose numeric chart axes, run summaries/Pearson correlation, add editable interpretations linked to immutable run IDs, save the analysis view, and export presentation HTML or summary CSV. Restart browser and gateway against the same data root and reopen the same question, filters, results and findings. Editing a finding advances the workspace revision without replacing the analysis run. Build Model retains the project and requires independent population, target and split choices.

Contracts are additive in TypeScript/OpenAPI/client and Julia repository/payload readers. `JuliaFlowProjectAnalysis.jl` owns bounded source/schema identity, scope computation, findings validation, report rendering and replay capture; the gateway composes authorization, project mutation ownership, artifact verification and persistence. Existing historical projects omit the optional workspace, and absent historical scope/provenance stays unavailable. Changes to source/schema or selected filters invalidate current evidence; immutable historical records remain visible.

The source parser qualification remains unquoted CSV ≤1,000 rows / 8 MiB. At most 64 numeric columns may be enabled, bounding quadratic pair computation; schema/scope canonicalization is iterative and capped at 200,000 tokens. Extreme numeric results become explicitly unavailable with warnings. Numeric columns must be enabled by the persisted schema; ignored/sensitive/ID/categorical fields are excluded. Summary and Pearson correlation are the supported new UI methods. Correlation, legacy OLS and group comparisons now preserve original row alignment when excluding missing/nonfinite values. Constant or insufficient correlation pairs are unavailable, with pair counts and warnings retained. Broader inferential methods are not presented as qualified by this increment.

The actual new computation is CPU in the gateway, recorded as such with Julia version, algorithm version and `workerComputed=false`. Generated Julia captures the source algorithms, schema and request, verifies the supplied CSV checksum, and recomputes the evidence. It requires Julia/JSON3/SHA and the original source file. It is separate from a packaged runtime or a source-inclusive project export.

Findings are draft text, independent of server-owned immutable results. Dataset selection retains saved and unsaved findings from project-owned runs and clears dataset-specific filters/axes; each finding shows its original dataset. A historical finding may reference another dataset within this project, while current selected evidence must match the active dataset. Reports label each result dataset and verify each referenced source snapshot. Saves check the expected revision; conflicting revisions preserve saved state. A short mutex protects per-project mutation ownership, then is released before bounded I/O. A second overlapping mutation rejects with 409; cleanup releases ownership on success or failure. Auth and project policy checks happen before ownership disclosure. This is one gateway process's protection, not distributed transactions. Save/storage/job operations still have inherited cross-resource transaction limits; unreferenced verified artifacts may remain after a later failure and must not be deleted blindly.

HTML escapes user content and includes measured summaries, scatter evidence, full scope/chart/correlation/provenance and warnings. CSV protects formula-leading string cells. Export rechecks source/schema and artifact checksums and compares verified result contents with stored immutable records. The original CSV file is excluded; selected chart values and aggregate evidence are included. Presentation exports are distinct from reopenable project packages. Unsaved drafts survive route changes in the current browser session and warn on page unload; only gateway saves survive a new browser session.

## Executable checks and retained evidence

- `tests/julia/statistics_alignment_tests.jl`: staggered-missingness correlation/OLS reference and grouped/degenerate controls.
- `tests/julia/durable_analysis_tests.jl`: real authenticated route/create/import/profile/run/save/reload/export, malformed input, ownership conflict/cleanup, revision conflicts, aggregate bypass rejection, source/schema/role guards, report escaping/CSV formula safety, fresh-process generated-code replay, source/artifact/stored-result tampering.
- `apps/frontend/src/analysis-workspace.test.tsx`: measured identity, duplicate prevention, failure preservation, independent drafts/saves, scope invalidation and unsaved route recovery. Existing project creation/boundary/navigation tests remain.
- `tests/contracts/project-payload.test.mjs` and typed-client fixtures: encoded project binding, preserved scope/revision, historical readers and complete OpenAPI references.
- `npm run smoke:durable-analysis`: fresh empty repository, actual managed CSV, selected row identities, save/report download, light/dark/mobile rendering, browser-plus-gateway restart, identical immutable run and recoverable finding, note-only revision update, zero automatic reimports, late import/project-switch regression. Failures retain screenshots/UI text as well as logs.
- Required checks: `npm run build`, `npm test`, `npm run validate:contracts`, `npm run test:local-ci`, `npm run julia:test:api-gateway`, full Julia repository/base-extension checks, `npm run validate:control-doc-sync -- --base 62d626b599bc49671a6b9f2e7a620b7660b2d7b5`, `npm run validate:brd-traceability`, and `git diff --check`.

The clean-candidate `npm run verify:release` now has 22 required phases, including both Create Project and Durable Analyse Data browser smokes. Authoritative exact commit/tree, pass/fail/skips and logs are in the generated `artifacts/release-verification/latest/summary.json`; no prior run count certifies a changed candidate. Local delivery rejects absent/failed/skipped phases. Hardware probes and optional platform checks inside a phase retain their own skips and do not become hardware certification.

Final retained run: clean commit `3165022190236100d9e0ab85f96c9c74eda94ad7`, tree
`78dd180424d634e3cc0441151a85ac624e4adf18`, passed all 22 release phases with no
runner phase skips. Frontend: 61 pass; contracts: 66 pass/one Windows skip; Julia:
3,495 pass/one optional unconfigured PostgreSQL scaffold skip; extension: 471 pass.
Separate metadata smoke passed 45 file-backed and 44 PostgreSQL assertions. Live
backend browser passed five scenarios; Create passed nine checks; durable analysis
passed eleven checks, including both-process restart and finding-only save.
Hardware orchestration passed with CPU fallback; physical CUDA/probe checks were
skipped, not validated. Follow-up checksum verification matched all 32 retained
handoff/browser files and 23 release files. Documentation-only instruction changes
are validated separately and do not turn this result into a new exact-commit run.

During development, a cold browser startup exceeded its existing readiness limit while Julia dependencies compiled. Dependencies and the package were prepared separately, then the unchanged deadline was reused. An existing five-second frontend navigation test timed out during concurrent compilation; the isolated test and subsequent complete 55-test frontend run passed without changing timeouts/assertions. Browser checks caught exact accessible-label ambiguity and long-checksum mobile overflow; those product fixes precede final candidate verification. Review also found dataset selection clearing findings. The correction preserves findings across selections and adds real-route/reload/export and frontend regressions. The c481d46 clean gate was canceled during Julia integration to fix this; it is not a full pass. The 4f2102c gate then caught a legacy statistical-request regression: schema lookup incorrectly preceded the scoped-request branch. Schema requirements now apply only to explicit scoped requests; existing real-evidence and demo fallback controls are retained unchanged. A later full gate reproduced the existing five-second navigation timeout when multiple jsdom files competed for CPU. Sequential file scheduling did not resolve it and was reverted. The monolithic shell-and-nine-routes test is split into independent creation, launcher/export, help/profile, data, modeling, visualization and deployment/monitoring/settings journeys, and navigation role queries are scoped to the accessible sidebar; all existing assertions and five-second deadlines remain. The first two-case split still timed out under the full runner, so each journey now has its own setup. The first complete runtime run was blocked by this executor’s absent default home; an explicit local JULIAFLOW_HOME resolves startup. Live browser regression then exposed its old assumption that dashboard checkpointing is available in EDA. The test now selects Dashboard explicitly and still verifies successful checkpointing; analysis uses its own workspace save. Earlier failed/canceled logs are preserved, not recategorized as passes.

## Design, tooling and acceptance

The nine-section Explorer shell, existing layout and explicit Wada #83 palette are preserved: Violet Blue `#40456A`, Olive Buff `#C1C494`, dark canvas `#141622`, surface `#202333`, action `#ABB1E3`, locally bundled Inter and monospace numeric evidence. Charts retain table/data alternatives. Selected Revision 3 analysis/export PNGs were materialized and inspected in the planning environment; screenshots are reviewed against the stated tokens and bounded workflow. There is no claim of complete original-board fidelity, screen-reader participant acceptance or real user/Data Analyst/Data Scientist approval. The inherited sidebar's static Julia-version label and unrelated demo presentation surfaces are not runtime qualification evidence.

The installed Julia harness passed unchanged signature/hash verification (`status: ok`, `signed: true`, catalog 2.1.0, runtime 0.2.0+codex.20260823220300). Manifest `996753585e98ac66877932c1569ee2301c9a19cd3e763a3a34860498c837fc6e`; release `97d0e341d80e952cd0eed6aa2b731545d1ebc96c226ff3c637f2621860cf496b`; signer `40c6ad7d4b0186c00360ddc1f9afb7ab8e5d186d046322486788b78fe13fdac4`. Router binding `baf2feca-1f1f-47d5-a73d-2fbfef93405a` selected implementation/debugging skills; concurrent-systems guidance was also loaded for mutation ownership. Planning/workflow, React guidance and frontend testing guidance informed the work. The user previously accepted unknown signer provenance for this exact bundle; historical signer identity is not independently verified and trust settings remain unchanged.

The full BRD local v1 remains required, including stock package GPU capability, scalable ingestion/runtime/compiler/acceleration lanes, native Windows EXE/Linux Docker, physical hardware and persona qualification. This increment does not reduce that scope to a CPU-only pilot. Full release-roadmap M2–M7 acceptance, independent final review, administrative merge requirements, merge and deployment remain open. Shell GitHub authentication now works; fresh authenticated reads confirm unchanged main and open draft PR60. The earlier authentication failure is historical. Branch-protection readback returned 403, so administrative merge requirements remain uncertain; no remote publication is claimed.

## Approved review method and publication gates

The user approved the capability-aware project procedure on 2026-10-10.
Canonical Codex Security diff scanning is unavailable because discovery did not
expose `start_codex_security_prompt_only_scan`. The installed bundle's actual
preflight and artifact-storage instructions were retrieved; scan ownership and
those rules remain mandatory for a canonical scan. No scan ID, canonical artifact,
assessment, or clearance is fabricated.

Use an available scoped installed workflow or the separate
[independent local review](agent-tooling.md#independent-local-security-review).
The implementing agent's focused source audit is not independent approval.
Required correctness/UI/security review, finding disposition, and full final
exact-candidate aggregate verification remain development-publication gates.
Participant/accessibility acceptance, complete original-board fidelity, physical
GPU and wider platform qualification remain separately tracked milestone criteria.
Publication does not satisfy them; merge needs its applicable checks/reviews and
explicit authorization, with deployment/tags/releases separately authorized.

Rollback: retain project/store/artifact backups, return to the baseline for new work, and preserve the optional workspace and immutable artifacts before allowing an older reader to rewrite a project. Do not delete the managed CSV or historical evidence as part of a UI rollback.
