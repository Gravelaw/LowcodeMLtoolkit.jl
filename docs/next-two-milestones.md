# Execution plan through M1 and M2

Prepared 2026-09-24 for the request to plan the next two major milestones. Planning owner: Akshay / AKS-57. This is a planning deliverable; milestone completion requires the evidence below. Implementation and delivery states are unchanged.

## Starting point and scope

Use the existing roadmap's **M1: stabilize the candidate** and **M2: truthful hardware discovery and device binding**. The immediate critical path is AKS-69 local verification, bounded AKS-41/56 backend clearance, then AKS-58. Full M1 integration acceptance remains a separate gate and can finish alongside bounded M2 development.

Inspected local revision: `11856e4d85f6c8ee96446687b4b21057733d9750`, branch `codex/aks-69-wsl-reliability`, clean before this planning edit. `Project.toml` declares Julia compatibility `1.10`; the CI mapping selects Julia 1.12.7 and Node 25.9.0. Do not infer all supported Julia versions or Windows/Docker hardware support from that selected WSL environment. Dependencies and manifests need no change for this plan.

Live source readback on 2026-09-24:

| Source | Observed state | Consequence |
| --- | --- | --- |
| [PR #56](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/56) | Open draft at `e436a7cce186735524af4eac04cc9125c04bcb55`; web/Julia success, Debian cancelled, no submitted reviews | Candidate stabilization and integration acceptance remain open |
| [AKS-69](https://linear.app/gravelaw/issue/AKS-69) | High, In Progress, Akshay | Local CI reliability and complete profile evidence are the immediate work |
| [AKS-41](https://linear.app/gravelaw/issue/AKS-41), [AKS-56](https://linear.app/gravelaw/issue/AKS-56) | High, In Review, Akshay; both block AKS-58 | Obtain concrete backend review clearance; issue labels alone do not grant it |
| [AKS-68](https://linear.app/gravelaw/issue/AKS-68) | High, In Review; focused PostgreSQL repair evidence recorded, full integration gates open | Reconcile and verify the existing helper repair instead of duplicating it |
| [AKS-58](https://linear.app/gravelaw/issue/AKS-58) | High, Todo, Akshay; blocks AKS-59 | Future M2 work; full AKS-38 persona/release completion is not its entry dependency |
| [AKS-50](https://linear.app/gravelaw/issue/AKS-50), [AKS-57](https://linear.app/gravelaw/issue/AKS-57) | In Progress | Preserve product acceptance and roadmap coordination ownership |

The local [diagnosis](verification-local-ci-aks69.md) records interrupted full-profile attempts, an intermittent REPL precompile stall, missing final summaries, and retained owned WSL storage. These observations do not establish the origin of Windows control-C termination. A successful earlier assisted run is diagnostic evidence only. Hosted Debian diagnosis remains paused. Frontend implementation remains frozen; Revision 3 design approval and participant/accessibility gaps retain their existing meanings.

## Milestone 1 — Stabilize the candidate

All slices are owned by Akshay through the named issue. A reviewer must be assigned explicitly for backend and integration clearance; no submitted review currently satisfies those gates.

| Order / issue | Bounded work and entry condition | Decisive evidence / exit | Failure handling and rollback |
| --- | --- | --- | --- |
| 1. AKS-69: diagnose interruption | Start from current logs and verified process identities. Distinguish precompile CPU/I/O progress, host termination, launcher exit, job outcome, PostgreSQL cleanup and evidence finalization. Validate one short controlled cancellation before another long run. Inspect `scripts/ci/process.mjs`, `scripts/ci/wsl.mjs`, `scripts/ci/wsl-job.sh`, `scripts/ci/evidence.mjs` and `tests/ci/runner.test.mjs`; edit only the demonstrated boundary. | Reproduction or documented diagnostic boundary; cancellation/failure leaves truthful terminal outcome or explicit recoverable interruption, retained logs, and verified owned-resource disposition. No stale `running` summary counted as success. | Preserve original artifacts and unverified storage. Change only the demonstrated cause. Revert the scoped runner change if failure paths regress; retain evidence. Do not repeat long runs merely because a polling call expires. |
| 2. AKS-69: freeze and verify | After the diagnosed runner fix and focused tests, choose one committed candidate C and explicit base B. Verify source identity and workflow mapping before launch. | Full cold PR, warm cache population plus reused-depot PR, push profile, and validation-only release-candidate profile at C/B. Every job/phase has pass/fail/skip/not-run, cleanup and manifest outcomes. Browser process cleanup must finish unattended. | Any code fix creates a new C and invalidates affected acceptance. Preserve exceptional evidence before rolling retention expires. Failed/skipped phases remain gaps. |
| 3. AKS-41/56/68: backend review | Can prepare while slice 2 runs. Review the existing PR stack and integration diff for auth/origin/path boundaries, TS/OpenAPI/Julia payload compatibility, strict evidence, split semantics and the world-age-safe PostgreSQL cleanup. | Named reviewer, inspected SHA, resolved findings, positive/negative contract and persistence tests, real PostgreSQL cleanup evidence; explicit written clearance for the backend surfaces M2 will consume. | Reuse existing fixes and scope owners. Security or contract rejection blocks M2 entry. Preserve historical payload readers; revert only the reviewed slice if required. |
| 4. AKS-50/69: full M1 integration exit | After local and backend review evidence; restore the existing Docker prerequisite without destructive reset, and resume hosted diagnosis only when the user's pause is lifted. | Required exact-candidate checks and submitted reviews; clean Windows and mapped Linux release verification with real PostgreSQL and no skipped required runtime phases; authorized integration merge and readback; control/Linear reconciliation. | Hosted pause, unavailable Docker, missing review or failing checks prevent full M1 closure. They do not authorize fabricated passes, changed deadlines or automatic Done. Broader persona/packaging criteria remain with their owners. |

**Bounded M2 entry gate:** slices 1–3 produce usable local verification and explicit AKS-41/56 backend clearance, with AKS-68 evidence reconciled. Record the selected backend SHA, exact review scope, remaining platform/release gaps and the agreed dependency disposition in Linear before starting AKS-58. This handoff does not declare M1, AKS-38, AKS-50, or AKS-69 Done. Full M1 exit remains slice 4.

Commands for slice 2 (substitute the frozen C and B; these are future commands, not new passes):

```sh
npm run test:local-ci
npm run ci:local:parity
npm run ci:local:wsl -- --ref C --base B --profile pr --cache cold
npm run ci:local:wsl -- --ref C --base B --profile pr --cache warm
# Repeat the warm command only after its first run populated the keyed cache.
npm run ci:local:wsl -- --ref C --base B --profile pr --cache warm
npm run ci:local:wsl -- --ref C --base B --profile push --cache warm
npm run ci:local:wsl -- --ref C --base B --profile release-candidate --cache warm
```

Use `ci:local` for the corresponding Docker profiles after engine restoration. Run `npm run verify:release` on the clean Windows candidate and the required Linux candidate for full M1 acceptance. WSL results cannot certify Docker image/network/mount behavior or Windows native execution. Profile `push` is local validation; it is not a Git push or publication instruction.

## Milestone 2 — Truthful hardware discovery and binding

Owner: Akshay / AKS-58. Requirements: JF-HW-001, JF-HW-002 and the M2 part of JF-RT-002; acceptance [AC-16, AC-17 and AC-19](acceptance-v0.5.0.md#ac-16). Move implementation to a scoped `codex/aks-58-...` branch only after the entry gate. Future slices below are ordered, and each is reviewable independently.

| Order | Deliverable and implementation boundary | Positive and negative acceptance |
| --- | --- | --- |
| 1. Reproduce false evidence | Add focused failing cases around `gpu_registry` and execution evidence in `services/worker-service/src/JuliaFlowWorkerService.jl`; trace `services/api-gateway/src/JuliaFlowDataScienceProjectJobs.jl` and persisted job consumers. | Invented device IDs and CPU mocks cannot produce hardware-executed GPU evidence. Capture current behavior before repair. |
| 2. Define compatible payloads | Align `packages/contracts/src/index.ts`, `packages/contracts/openapi/openapi.json`, Julia mappings, fixtures, persistence and consumers before producing new fields. Decide additive compatibility versus explicit versioning. | Installed, visible, usable, requested, planned and actually executed remain distinguishable. Historical missing evidence stays unavailable. TS-valid payloads survive OpenAPI and Julia validation; malformed records fail. |
| 3. Inventory and operational probes | Implement CPU/RAM/disk/GPU/runtime inventory and bounded allocation/operation/synchronization probes in focused modules. Keep the gateway responsible for dispatch and authorization. | CPU-only, missing driver, runtime mismatch, inaccessible device, insufficient RAM/disk/VRAM and successful real NVIDIA probe yield distinct truthful results. Other vendors remain detected but unqualified. |
| 4. Bind execution and fallback | Bind the selected physical device before allocation; record requested/planned/actual device and actual stage outcome. Preserve `cuda_required`; allow only supported safe preferred/auto CPU fallback. | Real allocation/operation identifies the selected device; invalid selection rejects or returns an explicit permitted fallback. Required-GPU never silently executes on CPU. Algorithm errors do not become hidden fallback successes. |
| 5. Integrate and qualify | Persist and round-trip evidence through jobs/repository/API and existing consumers, without frontend redesign. Qualify CPU-only and real NVIDIA operation on each claimed platform. | Restart/history preserve evidence; mixed CPU/GPU phases remain separate. No GPU fitting claim from a metrics kernel. Record absent physical-device/driver scenarios as skips, while deterministic rejection tests still run. |

Verification sequence: `npm run validate:contracts`, `npm run julia:test:project-contracts`, `npm run julia:test:worker`, `npm run julia:test:helpers`, `npm run julia:test:repository`, `npm run julia:test:api-gateway`, then `npm run smoke:local-hardware`. Run affected cross-route/live-backend checks if payload consumers change, and the full required candidate integration gates before delivery. Confirm these entry points actually cover the new scenarios; add missing scenario tests before making a coverage claim. A simulated device can test rejection logic but cannot establish hardware success.

M2 exit requires AC-16/17 and M2 evidence round trips from AC-19 proven at a selected commit; CPU-only and claimed real-device results with runtime/device IDs, fixture hashes, operation outputs and declared resource limits; reviewer clearance, required checks and authorized merge; synchronized controls/BRD traceability and Linear criterion readback. Physical hardware absence remains a qualification gap. No blanket speedup, compiler, multi-GPU or six-stage acceleration claim belongs to this exit.

Rollback: disable the defective adapter, preserve valid stored evidence and historical readers, and return explicit CPU/unavailable results only for permitted requests. Preserve required-GPU rejection. Any contract change needs a reviewed compatibility path before producers are enabled; no destructive migration or fabricated history.

## Cadence, decisions and handoff

The next work session should produce the short interruption reproduction and a concrete runner fix decision, then freeze C/B. Prepare the backend review packet concurrently as work activities, without starting hardware implementation early. Reassess after each decisive result; no calendar completion date is credible while host interruption and platform prerequisites remain unresolved.

For every slice retain: issue, owner/reviewer, candidate/base, changed surfaces, commands, fixture/runtime identity, pass/fail/skip counts, log/artifact hashes, cleanup disposition, accepted follow-ups and next action. Local CI writes to `artifacts/local-ci/<run-id>`; use a separately indexed archive for exceptional evidence that must outlive the three-completed-run policy. Never publish source bundles or browser traces automatically.

Full M1 closure depends on lifting the hosted pause and obtaining platform/review evidence. M2 depends on explicit bounded backend clearance and physical hardware qualification. These are execution gates, not missing information that prevents delivering this plan. Merge/release actions require their applicable authorization; this planning task performs none.

After M2, hand the verified inventory/device/evidence contract to AKS-59 shared planning and AKS-61 scalable ingestion, followed by AKS-60/62/63 compiler and stage acceleration. The current two-milestone plan ends at M2 acceptance, while M3–M7 remain in the [product roadmap](product-roadmap.md).

Planning provenance: signed Julia catalog `2.1.0`, digest `996753585e98ac66877932c1569ee2301c9a19cd3e763a3a34860498c837fc6e`, route `852d4455-6651-4a7d-a708-4ed987cf774f`; planning and workflow procedures selected. Repository controls, acceptance scenarios, issue criteria and live GitHub readback above govern this plan.

Plan validation: control-document sync against `11856e4` passed for the two changed documentation paths; BRD traceability passed for 46 existing mappings; all 11 referenced npm scripts and local document links resolved. Whitespace checks passed. Product/runtime tests were not run for this documentation-only plan.
