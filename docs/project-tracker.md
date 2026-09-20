# JuliaFlow Project Tracker

Last reconciled: 2026-09-20.

Approved restart execution: AKS-55, the managed-path AKS-41 patch, AKS-56 and AKS-53 are In Review in draft PRs #50 through #53. Their exact heads have passing hosted web/Julia checks. The Debian gates failed at local-bootstrap startup on #52 and an incomplete migration-smoke registry fixture on #53; the fixture correction is a separate AKS-56 follow-up, and full release proof remains open. AKS-54 now persists and verifies split membership across preparation, training, tuning and final evaluation; focused and integration verification is underway on its own branch. The isolated design task owns mockups only; no frontend implementation before explicit final design approval. See [remediation evidence](blocker-remediation-2026-09-20.md).

| Work | Verified delivery state | Next bounded action |
| --- | --- | --- |
| AKS-36 DataScienceProject | Linear In Progress; PR #40 draft at audited head `a70ea67`; web/Julia green, Debian release browser failure | Review the setup repair, then obtain same-head platform evidence and resolve acceptance/review/merge gates |
| AKS-38 | Current five-concern agent review and acceptance matrix prepared against `f9e10f3` | Review documentation PR; resolve AKS-53–56 and existing acceptance gaps; no human approval claimed |
| AKS-40–AKS-50 | Mixed delivery: AKS-41 managed-path draft is In Review; the criterion matrix retains other function/evidence gaps | Follow the ordered restart backlog in the dated review |
| AKS-37 / AKS-39 | Corrected to In Review after verifying Done relied on unmerged PR #40 | Complete criterion/review/check/merge gates; preserve historical evidence |
| AKS-51 repository cleanup | Local implementation verified on an isolated branch based on PR #40 | Review the scoped stacked PR and report hosted results separately |
| AKS-52 npm advisories | Compatible candidate implemented; clean audit and local verification pass | Review stacked draft PR, read hosted checks; leave #41–#46 open until approved integration |
| AKS-53–AKS-56 | AKS-53/55/56 In Review; AKS-54 implementation under verification | Verify split isolation, publish its separate draft, then reassess review and release blockers |

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
