# JuliaFlow next steps — bounded execution handoff

Date: 2026-09-20 · Owner: Akshay · [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination) · [roadmap](product-roadmap.md).

## Immediate lane: verify and review integration PR #56

AKS-50 owns [PR #56](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/56), preserving PR #40/#47–55 and separate AKS-57 documentation commit `f3be33e`. Publication and merge commit are authorized after the gates below. The original c363e008 Debian artifact and all local failing probes remain retained. [Diagnosis and results](verification-m1-integration.md).

1. Confirm the corrected startup under hosted Node 25/Julia 1.12. Local reproduction shows disabled compiled modules bypass dependency precompilation and exceed the unchanged 60-second deadline. The normal compilation policy passes the Windows smoke with original MLJ code, authentication and assertions.
2. Run full `verify:release` on clean Windows and hosted Debian at the same candidate, retaining every failure/skip and artifact. Docker/PostgreSQL is restored; required metadata checks must actually run.
3. Complete combined contracts, local security, split/ML, lifecycle and regression review. Resolve blockers and required submitted reviews; inaccessible protection APIs or admin access do not waive review/check requirements.
4. If main/candidate changes, refresh integration and repeat affected verification. Merge commit only; read back merge SHA/tree, checks and all superseded PR states. Reconcile Linear criterion by criterion, preserving source branches/evidence and M2–M7 gaps.

No force push, protection changes, tags, releases or deployment reruns. Frontend implementation remains frozen. This establishes a development baseline, not v0.5.0 certification.

## Following lane: M2 then M3/M4

After bounded M1 backend clearance, start [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution) with operation probes and device binding. Connect actual resource evidence to AKS-43/56 without manufacturing history. Then [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts) establishes common capabilities/plans, safe movement/retry and versioned interfaces; [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion) replaces the 1,000-row bound while retaining row/split/checksum semantics.

[AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code) implements a required Reactant compiler capability on supported Linux/NVIDIA inputs; freeze a meaningful CPU numerical function and reference before benchmarking. [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation) and [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation) cover the six stage categories with native adapters and declared envelopes. No compiler package is installed or schema altered by AKS-57.

Use [AC-12 through AC-28](acceptance-v0.5.0.md#ac-12) for scalable input, split, hardware, compatibility, equivalence and performance failures. Every new slice includes positive/negative checks, exact versions and resource evidence, explicit CPU reasons and preserved required-GPU rejection.

## Parallel lane: M5 design only

[AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval) owns the continuation of [Penpot Revision 2](https://design.penpot.app/#/workspace?team-id=ceed1600-61c0-8087-8007-e64ef71f5ffb&file-id=d8ac01df-6646-81d2-8008-aafe1c7924ba&page-id=a3ebef02-2fe2-80f8-8008-aafdca5313c5).

Complete Models/Deploy/Monitor/Settings and responsive/persona coverage; design real-file and compute discovery/preference/support states. Keep themes independent of guidance/density. Show actual limits, immutable split/new-plan behavior, standardization as the supported example and proposed transforms honestly. Define loading guards and retry/reselection for AKS-49's initial-load/switch race.

Capture **explicit final user design approval** as its own evidence. AKS-64 is In Progress in its existing design task; preserve Revision 2 and deliver the new editable revision, portable package and persona scripts. Prototype checks are separate from actual participant testing. Only later approved M6 work implements UI, reusing AKS-45–49 scope.

## Packaging and verification handoff

[AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows) covers the explicitly enabled local Linux/Docker Windows compiler worker; [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release) owns package certification. Their future acceptance includes CPU-only/native NVIDIA/compiled Linux/Windows WSL2 Docker, offline assets, insufficient resource/driver failure, authentication/confinement and backup/migration.

Run existing relevant npm gates from [acceptance](acceptance-v0.5.0.md), add missing compiler/operation/model/container/installer tests before claiming coverage, and complete no-skip same-candidate Windows/Debian `verify:release` plus required hardware. Current hardware absence is a recorded gap, never a passing release.

## Documentation-task closeout

Review the preserved AKS-57 commit, requirement mappings and [Linear/source readback](source-reconciliation-2026-09-20.md). Direct Node control validators are permitted because the system npm launcher still references a missing npm CLI; no global tooling repair or dependency install is needed. Existing archives and 46 mappings remain intact. Publication and product execution are separate later actions.
