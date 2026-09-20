# JuliaFlow Checkpoint Log

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
