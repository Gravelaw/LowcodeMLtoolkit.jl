# M1 integration verification

Owner: AKS-50; documentation preservation: AKS-57. Development baseline only; M2–M7 and v0.5.0 certification remain open.

## Baseline and diagnosis

Separate documentation commit `f3be33e8a3e968e217a0a2ee4a29765c0ab7315a`, parent `c363e0086552334fc2268222550ea031c548b4f9`; main `a0bfc232ac5d855981ff00659ac6302db8b2a285` was 104 commits behind the original candidate.

[PR #55 Debian run](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35518798354), artifact 10608053036: 14,408-byte zip SHA-256 `73b74689ef400550dabe265983cfd7439729142bc026a1e35e114322eecc02f9`. Candidate tree `7309161299eac7811b13a90304947c9eec524684`, hosted Node 25/Julia 1.12. Bootstrap fails with only `fetch failed`; later phases did not run. Original zip/summary/log retained in ignored task evidence.

Windows uses Node 26.3.0, Julia 1.12.6, verified installed npm 11.16.0 through task-local launchers. Docker 29.5.3 restored. No global upgrade/repair. A copied historical manifest lacked JSONSchema (separate environment failure); it was retained, then candidate dependencies instantiated from Project.toml. Generated manifest stays ignored.

| Retained log | SHA-256 / result |
| --- | --- |
| Initial stale-manifest failure | `a738f9148db90d85a7578be5883417871052cd702ea4b049e8632ee6d489bb2f` |
| Original resolved-environment bootstrap | `61f10395efb6c52bd5d66c33365da923c0fb154c88450d78b6ba2ab5b1863a36`; exit 1 after 60.38 s. |
| Instrumented bootstrap | `088ca04e8219807a92ed903f9ab0c02c0489161beadad68d038be9d9192afe27`; `/health` ECONNREFUSED at 60,009 ms, live child in module loading. No state/listener milestone. Cleanup closed with SIGTERM at 60,103 ms. |

The original and diagnostic Windows probes excluded dependency instantiation only after explicit successful setup. Neither is a full release run. The underlying loading cause and hosted confirmation are still open.

## Verification

- Startup lifecycle tests: 12 passed, one POSIX SIGKILL escalation check skipped on Windows and scheduled in CI.
- `npm run validate:contracts`: 43 passed, one POSIX-only skip. Covers success/auth headers, ENOENT, early exit, refusal, malformed/non-ready/hanging responses, deadline, redaction, cleanup and archive integrity.
- All nine archived file hashes match manifests. The new v0.4.1 snapshot has a scoped Git attribute to retain committed bytes across Windows checkouts; snapshot and manifest bytes are unchanged.
- Full clean-candidate Windows and hosted Debian `verify:release`, combined review, required submitted reviews and merge: pending. No failed or skipped gate is reported as passed.

## Preserved stack

| PR | Scope / Linear |
| --- | --- |
| #40 | DataScienceProject substrate; AKS-36/37/39/40–50. |
| #47 | Repository/control validation/CI setup; AKS-51. |
| #48 | Dependency remediation; AKS-52. |
| #49 | Architecture/security/restart review; AKS-38. |
| #50 | Browser/REST/realtime authority; AKS-55. |
| #51 | Managed path confinement; AKS-41. |
| #52 | Compatible project/resource payload validation; AKS-56. |
| #53 | Reject synthetic strict-mode evidence; AKS-53. |
| #54 | Immutable split membership/train-only fitting; AKS-54. |
| #55 | Migration smoke fixture contract; AKS-56. |

Hardware/runtime/compiler/scale, broader analysis/model operations, complete design approval, frontend journeys and packaging remain separately tracked M2–M7 gaps. Current 1,000-row and immutable-split constraints remain. No broad persona issue becomes Done solely through integration.

Rollback uses scoped corrective commits; preserve all existing worktrees, branches, PRs and artifacts. No storage migration, force push, protection changes, tags, releases or deployment reruns.

## Bounded compilation repair

The installed Julia 1.12 Pkg implementation (`should_autoprecompile`) requires compiled modules to be enabled. Both dependency bootstrap and smoke gateway startup forced `--compiled-modules=no`; the original standalone module-load probe completed only after 62,861 ms, already beyond the 60,000 ms readiness deadline. It did not reach state initialization in the original failing run.

Repair: remove that override from the two launcher invocations, using the same normal compiled-module policy as dev:local. Preserve the original MLJ implementation, gateway state/health behavior, all auth and smoke assertions, and 60/90/30-second readiness deadlines. A measured optional-import experiment alone still failed at listener/health readiness and was not retained as a product change.

Normal dependency precompilation completed successfully with recorded CUDA 13.4/13.2 and UTCDateTimes warnings; no GPU-success claim. Compilation-policy-only Windows bootstrap then passed: module loaded 9,807 ms, state ready 18,328 ms, listener/health ready 57,891 ms, authenticated workflow assertions passed. Log SHA-256 `123f4190b6517529fb0250a8aeeabfa025418aaeeef4c4283c83df72247f3ed4`. These timings show limited Windows margin; full clean-candidate Windows/hosted Debian remain required, not inferred.

The first hosted diagnostic candidate (75525e3, run 35526439547, artifact 10610276170) failed a malformed-JSON regression because final deadline abort erased the previous error. Retained zip SHA-256 `bf78852c2e72660b62820769b238dfa30d17cd0d4d15a2d43a67db368f12ee1f`. The fix preserves prior evidence on abort, with an explicit malformed-then-hanging regression. Additional review tests protect multiline configured secrets and limit repeated live stage messages. Latest Windows startup suite: 15 pass, one POSIX-only skip. Full CI tests must exercise POSIX escalation.

## 2026-09-20 — candidate f113e90 gate failure and Revision 3 handoff

Clean Windows `verify:release` at `f113e909` passed setup, contracts, build and workspace tests, then stopped in the Julia repository suite: 100 checks passed, but PostgreSQL test cleanup invoked dynamically loaded LibPQ methods directly and raised world-age errors. Eight artifact files remain retained; summary SHA-256 `2fa3732d7564dbd2b3cf542b37e7819003a23cf578d766f277d4f1e8462f959d`, Julia log SHA-256 `a1c9d6224e4a0d6feb0dece2771dda913c5fa57efdd1503da03956361fbd7122`. Later phases did not run. Separate AKS-68 owns the two-line helper correction to existing world-age-safe repository wrappers, followed by focused real-PostgreSQL and clean full-candidate reruns. No assertions or deadlines are relaxed. Focused real-PostgreSQL verification passed 100 repository and 275 payload checks (375 total); both schema cleanup and connection cleanup completed. Log SHA-256 `4e33f47ebd6ca741b943ebd965342a399ef749ca0fbbcef437fa9a6905aa072d`.

AKS-64 delivered [Revision 3 design and its review package](verification-design-r3.md). All nine routes and both 1,000-row journeys are reviewable; heuristic/prototype checks passed, participant sessions remain zero, final design approval was explicitly granted by the user after reviewability. Frontend implementation stays frozen. Integration review and matching Windows/Debian gates remain open; no merge or release claim.

Hosted diagnosis confirmed on Node 25 / Julia 1.12.7: run 35526799388 at `2d8252e3`, tree `3f12addff5176bb101b5fb1f84d780e41f5a54c4`, clean worktree. Bootstrap retained only `module-loading` at 39 ms; `/health` failed with ECONNREFUSED at 60,001 ms and the live child closed on SIGTERM at 60,516 ms. Artifact 10610387390 ZIP SHA-256 `a4124ed597ce5e636652f96080ef78f06bcdedca04e5b994b5f9b0bca8fe61a4`. Earlier full Julia and base-extension phases passed; later smoke phases did not run. This matches the local module-loading diagnosis without changing deadlines. The normal-compilation candidate still requires its own complete gates.

## 2026-09-21 — first-request compilation boundary

Hosted Node 25 / Julia 1.12 run [35527192291](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35527192291) at f113e909 failed bootstrap despite successful module loading (10.631 s), state initialization (19.428 s) and listener startup (19.434 s). The 60.003 s readiness expiry retained an earlier connection-refusal error; termination output shows LLVM compilation through workspace_artifact_summaries, workspace_summary_payload, healthcheck and route_request. This demonstrates the remaining cold request-compilation boundary, not a missing listener or failed authentication. Artifact 10610038832 ZIP SHA-256: `68ef3b027909a93d711b9c481608a0fab5a9b697eea290ad13e604c1be5f8888`. Clean start/finish were reported; subsequent smoke/browser phases did not run. The later d35f9b4 hosted run was cancelled, and its Windows run was interrupted without a final summary; neither is a pass.

At the user's request, the official [TypeSafe AI skill](https://github.com/typesafe-ai/skills/blob/main/skills/typesafe-ai/SKILL.md) was used with Jev 1.13.0 for a structured evidence classification and next-probe choice. Only normalized timing/stack observations were sent. It selected first-health compilation and a cold route timing probe. This advisory judgment is not executable proof or approval. Retained response SHA-256: `38ff26a885a1084e6bbcfceb43e95d1ca3340e94773e7e83f4c58ce87a8a50d3`.

The gateway entrypoint now imports the existing JuliaFlowMonorepo package instead of re-including gateway source. The package requests precompilation of route_request(GatewayState, HTTP.Request), allowing dependency preparation to retain its compiled code. No dependencies, data fixtures, timeouts, authentication rules, health payloads or runtime assertions change. Precompilation does not execute a request, initialize state or open a listener.

Local Windows fresh-process probes: package load plus first routed health response fell from 28.732 s to 6.819 s (diagnostic probe, not a full release test). Normal npm run smoke:local-bootstrap including dependency preparation passed: modules 2.367 s, state 3.877 s, listener 3.880 s, health ready 11.346 s; authenticated workflow assertions passed. Smoke log SHA-256 `267d621066ddd642de50543caa47d3d9f21b37ffbd6a3b7f6ddd8e05d3a64949`; route probe log SHA-256 `70283107c7c3ee7c62ff77b4768609a00705aa2d1d1ac8af512e126c0e94244d`. Contract suite: 46 pass, one explicit POSIX-only Windows skip. Matching clean-candidate Windows/hosted Debian verification and required reviews remain open. Frontend implementation remains frozen despite the separate design approval.
