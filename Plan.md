# JuliaFlow current development plan

2026-10-02 publication handoff: user-authorized AKS-48 follow-up comment `08c4e330-3cf1-4823-9b40-cb213cb1c952` records the discovered profiling defect, corrections and exact affected evidence; readback confirms In Progress. Accepted source hashes and live PR #58 base remain unchanged. Development publication of `codex/reconcile-profiling` is authorized; merge/deployment/full release and GPU qualification remain open.

2026-10-01 final reviewed profiling candidate validation: all four source findings accepted by independent rereview; accepted eight-file hashes remained unchanged. WSL Julia 1.12.7 dedicated HTTP 65/65; complete affected gateway slice 1,639 pass / zero fail / two existing root-permission skips (674.38 seconds); Node contracts 63 pass / three platform skips; both frontend typechecks passed. Tracker/remote reconciliation and commit/publication remain open. No full-release or hardware qualification claim for this revised tree.

2026-10-01 second review follow-up: normalize/validate every supplied import string before materialization, including datasetName; mutate a project copy before persistence. Shared checksum-addressed CSV copies are retained on later job/storage failure, never deleted as rollback. Added invalid-name HTTP rejection-state/artifact regressions. Final runtime gates and independent acceptance remain open.

2026-10-01 independent review follow-up: the bounded profiling candidate now materializes verified content-addressed managed CSV sources for project imports, retains `importSourceUri` provenance, emits numeric/null previews and separates missing-cell chart buckets from literal categories. Standalone regressions pass 32/32, focused contracts 9/9 and frontend typecheck pass. New import/update/wizard/reload/analysis HTTP regression and the complete affected gateway slice require an explicit CI resource window and reviewer reread; earlier gateway counts apply to the previous candidate. No publication or release claim.

2026-10-01 isolated reconciliation candidate: PR #58 head `6618d19` plus the five local AKS-69/55 commits has a bounded real-file CSV profiling correction in `codex/reconcile-profiling`. It profiles complete unquoted unique-header CSV files up to 1,000 rows / 8 MiB, rejects quoted/malformed/oversize or non-CSV profiling, and no longer reports nonexistent derived artifacts. On WSL Julia 1.12.7 the corrected affected gateway slice passed 1,501 assertions with zero failures and two existing root-permission skips; Node contracts passed 63 with three platform skips. Review, tracker ownership and full release validation remain open; AKS-61 scalable ingestion and AKS-58 full GPU worker remain open. No merge or release claim.


WSL resource follow-up: Julia jobs provision a temporary 3 GiB swap file inside
their owned job directory before execution. Cleanup verifies its path and UUID,
deactivates it, then removes owned storage. This replaces manual activation lost
across WSL shutdown; full profiles must verify the committed runner behavior.

2026-09-30 release blocker: candidate `9520979` passed 16 release phases, then
the live browser suite reported 4 passed / 1 failed on rejected-WebSocket
connection reuse (`ECONNRESET`). Cleanup and evidence finalization passed; no
package promoted. The bounded AKS-55 transport repair advertises connection
closure without changing auth/origin policy. Affected and aggregate verification
remain required before local delivery. Tracker disclosure approval is pending;
the user explicitly authorized continuing the local repair and aggregate rerun.

## 2026-09-30 - local CI/CD continuation (AKS-69)

The user selected local CI with hosted quality jobs skipped while local mode is active, superseding the earlier unchanged-workflow boundary. A tracked execution policy selects local or hosted execution; mapped local quality commands remain mandatory. Local CD means a versioned source-and-built-web package promoted only after a complete clean same-candidate release-candidate run, checksummed evidence and successful cleanup. It is not an offline installer, native Windows/Docker certification, external deployment or permission to merge. No product or hardware gate is waived. Original planning edits and historical evidence are preserved. Full execution results remain pending; see [local CI](docs/local-ci.md).


## 2026-09-25 — bounded M1 review and M2 hardware candidate

AKS-41/56 received a scoped Codex code review at backend SHA `e436a7c` with no critical/high finding. Its written clearance is technical and bounded; no GitHub review was submitted. AKS-69 local runner tests and parity passed, and a mapped WSL web-only PR job passed at candidate `890d820` / base `a0bfc232`. Automatically triggered PR #57 CI at that head passed web, Julia and Debian `verify:release`, including five live-backend browser tests; the conditional physical-CUDA smoke skipped. Complete local cold/warm, push and release-candidate profiles remain open. Hosted Debian diagnosis remains paused. See [M1 diagnosis](docs/verification-local-ci-aks69.md).

AKS-58 is in progress on the scoped hardware branch. It now separates simulated, visible and operation-proven devices; CPU project work and worker fallback evidence are explicit. A selected native Windows RTX 5080 completed the bounded probe and affine operation with verified output/device after repairing Julia dynamic-load world age; CUDA.jl still warns of a 13.2/13.4 precompile/runtime mismatch. The opt-in full worker test fails GPUCompiler kernel compilation in its larger Julia 1.13 process, so complete worker GPU execution is still open. Complete the [M2 evidence record](docs/verification-m2-hardware.md), WSL physical probe, full same-candidate gates and required review before any M2 acceptance or Done claim. No frontend implementation is authorized by this entry.

## 2026-09-23 — dedicated WSL execution for AKS-69

Docker Desktop reinstall remains blocked by an MSI-detection message. The user directed a dedicated WSL instance as the immediate local CI backend. Ubuntu 24.04.5, Node 25.9.0, Julia 1.12.7 and PostgreSQL 16 are isolated from the existing `ubn` distro. Run the existing mapped workflow commands and retain exact results; WSL cannot close Docker-specific, native Windows, hosted GitHub or review gates. Hosted Debian diagnosis remains paused. [WSL runner and limitations](docs/local-ci.md).

## 2026-09-22 — AKS-69 local-first CI; hosted Debian paused

The user approved complete local CI execution while keeping hosted Debian diagnosis paused. AKS-69 owns isolated Docker PR/push/release-candidate profiles, workflow parity, streaming logs and durable evidence. GitHub workflows/check/review requirements remain unchanged; PR #56 at e436a7c is unmerged. Its latest hosted Debian result is cancelled, not passed. See [local CI](docs/local-ci.md).

Docker Desktop currently cannot start its Windows inference socket. Non-destructive runtime-directory preservation did not resolve it; no volumes were deleted or factory reset performed. The user subsequently uninstalled Docker; reinstall currently reports MSI detection, with only a reboot-required Docker registry marker found in inspected registrations. Local runner unit/process checks can proceed, but container cold/warm and PostgreSQL-backed platform gates remain unverified. Failures stay visible; no Done or release claim.

After local infrastructure, obtain scoped AKS-41/56 backend review clearance and reconcile AKS-68 evidence, then implement AKS-58. Full AKS-38 persona/release completion is not a prerequisite for bounded hardware work. Continue AKS-59/61, then AKS-60/62/63 in dependency order. Revision 3 design approval is already recorded; participant/accessibility acceptance remains open and frontend implementation frozen.


Reconciled 2026-09-20 for [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination). Canonical [BRD v0.5.0](business-requirements-v0.3.0.md) · [product roadmap](docs/product-roadmap.md) · [next steps](docs/next-steps.md).

## Scope and current truth

The approved product is a **local hardware-aware data-science workstation**, delivered first as Windows EXE and Linux/Docker. Supported GPU numerical preparation, EDA, chart-data computation, fitting, inference and evaluation, plus meaningful compiler integration, are first-release requirements. NVIDIA is first; CPU-only operation and explicit unsupported/fallback reasons remain required. Windows compiler execution uses an explicitly enabled local authenticated/confined Linux/Docker worker.

The separate AKS-57 documentation commit `f3be33e` is preserved. Authorized M1 integration now proceeds in PR #56 with startup diagnostics and a bounded compilation-policy repair. Revision 3 design approval is recorded; frontend implementation remains frozen under the approved integration scope.

Live GitHub readback: PR #40 and #47–55 are open drafts, without submitted reviews. Web/Julia pass; Debian #47–51 cancelled and #40/#52–55 failed. PR #55's retained bootstrap failure is reproduced locally: disabled compiled modules make module loading exceed the 60-second deadline. Normal dependency precompilation and gateway compilation restore the local smoke without changing deadlines/assertions. Hosted diagnostic run 35526799388 confirms module loading at deadline; full repaired-candidate gates remain open. Earlier 1,492 gateway/boundary assertions and five browser scenarios retain their original revision attribution and PostgreSQL skip. They do not certify this release. [Evidence and decisions](docs/source-reconciliation-2026-09-20.md).

Current execution is <=1,000 unquoted CSV rows with unique headers; split plans/membership/folds/locks are immutable and changed sources/splits need new plans. Numeric train-fitted standardization exists; broader transforms/composition remain proposed. Worker source retains mock GPU evidence and missing actual device binding. The older single-device KA smoke does not prove training/compiler/multi-GPU readiness.

Latest gate: clean Windows f113e90 stopped at PostgreSQL test cleanup after 100 passing repository checks; AKS-68 repairs the dynamic LibPQ invocation boundary. Full verification must restart on the next candidate. [Revision 3 design](docs/verification-design-r3.md) is reviewable with final design approval recorded and participant testing pending.

Current AKS-50 follow-up (2026-09-21): hosted f113e909 reached listener startup but exceeded readiness while compiling the first health request. Loading the existing package and precompiling its dispatcher passes local bootstrap at 11.346 s; matching hosted evidence and required reviews remain open. [Detailed evidence](docs/verification-m1-integration.md).

## Ordered implementation and parallel design

| Milestone | Scope | Tracking and dependency |
| --- | --- | --- |
| M1 | Latest exact-head Debian diagnosis, scoped review, remediation integration and verification | Reuse AKS-38/41/50/51/52/53–56 and AKS-36; preserve PR stack #40 → #47–55. |
| M2 | Real discovery, selected-device execution, required-GPU/fallback and actual resource evidence | AKS-58, linked to AKS-43/56; bounded M1 backend review clearance first. |
| M3 | Shared runtime/contracts, compiler integration, memory/data movement and scalable ingestion | AKS-59/60/61; preserve Arrow/TOML and AKS-54 membership. |
| M4 | Verified native and compiler acceleration for all six required numerical stage categories | AKS-60/62/63; equivalence, benchmarks and explicit coverage/resource limits. |
| M5, parallel | Complete nine-route design, personas, compute coverage, immutable splits, hydration, responsive/accessibility | AKS-64 with AKS-38/47–49; final signoff consumes actual capabilities. |
| M6 | Approved cross-route analysis/modeling flows, onboarding/state and lifecycle/drift provenance | Reuse AKS-45–49; UI waits for explicit final design approval and required backend capabilities. |
| M7 | Windows EXE/Linux-Docker, local Windows compiler worker, offline installs, migration and full certification | AKS-65/66 plus AKS-38/50; same-candidate Windows/Debian and required hardware tests. |

No dates are invented. AKS-67 is deferred Medium-priority compatibility; AKS-64 design is In Progress; other new release work AKS-58–66 remains High-priority Todo, owned by Akshay. Existing issue priorities/owners/statuses remain; no issue completion follows from this rewrite.

## Next bounded action

Finish AKS-69 WSL runner reliability and same-candidate local profiles first. Then perform bounded AKS-41/56 backend review with AKS-68 evidence and relevant AKS-38 findings before AKS-58 begins. Native Windows, Docker-specific and hosted GitHub gates remain separately open; hosted Debian diagnosis is paused. Preserve all source branches and evidence. [Diagnosis and exact results](docs/verification-m1-integration.md).

In parallel, AKS-64 can refine design only: remaining lifecycle/settings routes, compute preference/coverage, real-file onboarding, <=1,000-row / 8 MiB current sample, new-plan split semantics and project-loading guards. The existing 404 hydration race remains unfixed; controls must ultimately wait for real identity on initial load and project switch.

## Invariants and gates

Preserve local trust/auth, confined roots, symlink/junction policy, redaction, identifiers/checksums, offline operation, PostgreSQL metadata, explainability and reproducibility/backup. Keep optional connectors/cloud optional and unsupported execution visibly disabled. Preserve signed Julia tooling, user artifacts, original checkouts/worktrees and immutable evidence.

[Acceptance scenarios](docs/acceptance-v0.5.0.md), [TODO](docs/TODO.md), [risks](docs/risk-register.md) and [traceability](docs/brd-traceability.md) distinguish candidate evidence, requirements, designs and deferred work. M7 requires complete selected capabilities and no skipped required phases; green documentation/web/Julia checks or historical Windows evidence do not replace release proof.

[Historical plan archive](docs/archive/2026-09-20/README.md) and [v0.4.1 BRD snapshot](docs/archive/2026-09-20-brd-v0.4.1/README.md) retain prior statements without promoting them.
