# JuliaFlow project tracker

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
