# JuliaFlow next steps — bounded execution handoff

Date: 2026-09-20 · Owner: Akshay · [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination) · [roadmap](product-roadmap.md).

## Immediate lane: M1 exact-candidate diagnosis

**Existing owner issue: AKS-50**, with AKS-38 review and AKS-51/52/53–56 remediation dependencies. Starting baseline is draft PR #55 `c363e0086552334fc2268222550ea031c548b4f9`. Do not replace it silently with newer code or older control documents.

1. Refresh PR #55 head, base, review state and all exact-head checks through authenticated `gh`; read AKS-50 criteria and linked findings. If head changed, record both revisions and decide which candidate the bounded investigation tests.
2. Inspect [run 35518798354](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35518798354), Debian job `106099171919`, failed step `Run npm run verify:release`, including retained phase summaries and child diagnostics. Root cause is undiagnosed in AKS-57; do not copy an earlier browser/bootstrap/migration explanation.
3. Reproduce the first failing boundary proportionately on the appropriate platform, preserving evidence. A fix must target the cause and preserve required assertions, phases and timeouts. Reuse AKS-50/56 when their criteria own it; record genuinely new defects before broadening scope.
4. Keep a coherent issue branch and exact SHA/tree/fixture evidence. Run affected gate(s), then control validation and required candidate verification. Local Windows success cannot stand in for Debian.
5. Present bounded review evidence with remaining skips/gaps. Integration order follows #40 → #47 → #48 → #49 → #50 → #51 → #52 → #53 → #54 → #55 and actual branch bases; integrate only with explicit authorization. Required failing checks block merge.

Read-only entry points for the subsequent implementation task:

```text
gh pr view 55 --json number,state,isDraft,headRefOid,baseRefName,reviews,statusCheckRollup
gh run view 35518798354 --json headSha,conclusion,url,jobs
gh run view 35518798354 --job 106099171919 --log-failed
```

These are a handoff, not a CI rerun request. No product tests or root-cause repair were performed in this documentation task. No deployment rerun, merge, force-push, release or frontend approval is granted.

## Following lane: M2 then M3/M4

After bounded M1 backend clearance, start [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution) with operation probes and device binding. Connect actual resource evidence to AKS-43/56 without manufacturing history. Then [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts) establishes common capabilities/plans, safe movement/retry and versioned interfaces; [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion) replaces the 1,000-row bound while retaining row/split/checksum semantics.

[AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code) implements a required Reactant compiler capability on supported Linux/NVIDIA inputs; freeze a meaningful CPU numerical function and reference before benchmarking. [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation) and [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation) cover the six stage categories with native adapters and declared envelopes. No compiler package is installed or schema altered by AKS-57.

Use [AC-12 through AC-28](acceptance-v0.5.0.md#ac-12) for scalable input, split, hardware, compatibility, equivalence and performance failures. Every new slice includes positive/negative checks, exact versions and resource evidence, explicit CPU reasons and preserved required-GPU rejection.

## Parallel lane: M5 design only

[AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval) owns the continuation of [Penpot Revision 2](https://design.penpot.app/#/workspace?team-id=ceed1600-61c0-8087-8007-e64ef71f5ffb&file-id=d8ac01df-6646-81d2-8008-aafe1c7924ba&page-id=a3ebef02-2fe2-80f8-8008-aafdca5313c5).

Complete Models/Deploy/Monitor/Settings and responsive/persona coverage; design real-file and compute discovery/preference/support states. Keep themes independent of guidance/density. Show actual limits, immutable split/new-plan behavior, standardization as the supported example and proposed transforms honestly. Define loading guards and retry/reselection for AKS-49's initial-load/switch race.

Capture **explicit final user design approval** as its own evidence. This issue's Todo status does not erase earlier design exploration; future completion work has not started here. Only later approved M6 work implements UI, reusing AKS-45–49 scope.

## Packaging and verification handoff

[AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows) covers the explicitly enabled local Linux/Docker Windows compiler worker; [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release) owns package certification. Their future acceptance includes CPU-only/native NVIDIA/compiled Linux/Windows WSL2 Docker, offline assets, insufficient resource/driver failure, authentication/confinement and backup/migration.

Run existing relevant npm gates from [acceptance](acceptance-v0.5.0.md), add missing compiler/operation/model/container/installer tests before claiming coverage, and complete no-skip same-candidate Windows/Debian `verify:release` plus required hardware. Current hardware absence is a recorded gap, never a passing release.

## Documentation-task closeout

Review the local AKS-57 diff, requirement mappings and [Linear/source readback](source-reconciliation-2026-09-20.md). Direct Node control validators are permitted because the system npm launcher still references a missing npm CLI; no global tooling repair or dependency install is needed. Existing archives and 46 mappings remain intact. Publication and product execution are separate later actions.
