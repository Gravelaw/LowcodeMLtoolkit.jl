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
