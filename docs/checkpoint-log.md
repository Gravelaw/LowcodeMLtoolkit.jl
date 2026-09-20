# JuliaFlow Checkpoint Log

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
