# JuliaFlow product roadmap — v0.5.0

## 2026-09-22 — AKS-69 local-first CI; hosted Debian paused

The user approved complete local CI execution while keeping hosted Debian diagnosis paused. AKS-69 owns isolated Docker PR/push/release-candidate profiles, workflow parity, streaming logs and durable evidence. GitHub workflows/check/review requirements remain unchanged; PR #56 at e436a7c is unmerged. Its latest hosted Debian result is cancelled, not passed. See [local CI](local-ci.md).

Docker Desktop currently cannot start its Windows inference socket. Non-destructive runtime-directory preservation did not resolve it; no volumes were deleted or factory reset performed. The user subsequently uninstalled Docker; reinstall currently reports MSI detection, with only a reboot-required Docker registry marker found in inspected registrations. Local runner unit/process checks can proceed, but container cold/warm and PostgreSQL-backed platform gates remain unverified. Failures stay visible; no Done or release claim.

After local infrastructure, obtain scoped AKS-41/56 backend review clearance and reconcile AKS-68 evidence, then implement AKS-58. Full AKS-38 persona/release completion is not a prerequisite for bounded hardware work. Continue AKS-59/61, then AKS-60/62/63 in dependency order. Revision 3 design approval is already recorded; participant/accessibility acceptance remains open and frontend implementation frozen.


Date: 2026-09-20 · Owner: Akshay · [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination) · [BRD](../business-requirements-v0.3.0.md) · [next steps](next-steps.md).

The first release is a local hardware-aware data-science workstation on **Windows EXE and Linux/Docker**, with supported GPU preparation, EDA, chart-data computation, fitting, inference and evaluation, plus meaningful CPU-oriented numerical compiler integration. Native NVIDIA adapters and a local opt-in Linux compiler worker on Windows form the initial platform path. CPU-only operation remains supported; other vendors remain honestly detected and unqualified until separately verified.

Milestones express dependency order, not dates. M5 design runs alongside M1–M4. Frontend implementation remains frozen until explicit final design approval, and then consumes verified backend contracts/capabilities. No milestone is complete merely because its documentation exists.

| Milestone | Owned work and issues | Exit / handoff |
| --- | --- | --- |
| M1 Stabilize candidate | Existing AKS-38/41/50/51/52/53–56; substrate AKS-36. Review PRs #40 → #47 → #48 → #49 → #50 → #51 → #52 → #53 → #54 → #55 in their actual stack. | Diagnose latest exact-head Debian failure, retain logs/artifacts, resolve bounded findings and required reviews, integrate only with authorization, verify selected candidate. Do not duplicate existing repairs. |
| M2 Truthful hardware | [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution), linked to AKS-43/56. | Discover real resources and operational capabilities; bind actual device; reject mocks as GPU proof; enforce required-GPU and safe CPU fallback with truthful evidence. |
| M3 Runtime, compiler, scalable data | [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts), [AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code), [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion); reuse AKS-41/42/43/54/56. | Contract-first shared planning, native adapters, memory/movement/retry controls; compiler implementation and compatibility; replace bounded CSV with verified full-file/chunk/row/split semantics. |
| M4 Verify stage acceleration | [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation), [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation), [AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code). | Real native/compiled workloads across six stage categories; CPU/GPU equivalence, supported resource envelopes, explicit unsupported paths and complete performance costs. |
| M5 Complete design, parallel lane | [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), reuse AKS-38/47/48/49. | All routes/personas/states, real-file and compute flows, responsive/accessibility testing and explicit final design approval. |
| M6 Implement approved journeys | Existing AKS-45–49; AKS-42/44/50 support validity, analysis and verification. | Durable cross-route onboarding/state/invalidation, analysis-only and modeling flows, lifecycle/drift/rollback provenance, approved compute UI, hydration protection and persona evidence. |
| M7 Package and certify | [AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release), existing AKS-38/50. | Windows EXE/Linux-Docker offline installation, optional local Windows compiler worker, CPU/NVIDIA hardware matrix, migration and same-candidate Windows/Debian release proof. |

## M1 — Stabilize the existing review candidate

Approved starting point: `c363e0086552334fc2268222550ea031c548b4f9`, draft PR #55. The live readback found all listed PRs open/draft and no submitted reviews; web/Julia pass, Debian #47–51 cancelled and #40/#52–55 failed. [Source ledger](source-reconciliation-2026-09-20.md) records every head/run.

The immediate task is AKS-50's diagnosis of run `35518798354`, Debian job `106099171919`, failed step `Run npm run verify:release`. The latest root cause is **undiagnosed** here; do not reuse #40's missing-browser or earlier migration-fixture explanation. No rerun, merge or code repair occurs in AKS-57. Required scoped review clearance for backend changes precedes M2 implementation; full persona/release review remains a later AKS-38 gate.

Existing remediations already cover auth, path confinement, payload contracts, strict evidence, persisted membership and migration fixture. Reconcile their acceptance and candidate evidence instead of filing duplicate implementations. PR #39 remains the retained unmerged fallback. Preserve original checkouts, refs, user artifacts and signed tooling.

## M2 — Discovery before preference and execution claims

AKS-58 owns newly tracked defects: mock/invented registry can label CPU work as GPU; recorded selection is not bound to CUDA; required-GPU and real-workload fallback are incomplete. The old hardware smoke is limited to one real kernel and one device.

After installation, inventory and operational probes precede user choice. Preferences must respect real compatibility/memory and existing required-GPU rejection. Native allocations and completion evidence identify the actual device. M2 uses AKS-56-compatible evidence and AKS-43 jobs; the broader M3 contract evolution must not reinterpret old records.

## M3 — Shared runtime and scalable ingestion

AKS-59 owns supported operation planning, versioned inventory/plans/phase evidence, memory caps and safe retry over CPU/CUDA/KernelAbstractions. Producers and consumers evolve together after contract review. Historical absent evidence remains unavailable.

AKS-60 makes Reactant integration mandatory, with Linux/NVIDIA the initial compiler target; meaningful CPU-oriented numerical work is required. AKS-61 replaces the current <=1,000 unquoted-row unique-header path. Keep that guard until verified full-file parsing/materialization, row identity, hashes and immutable split membership survive batching and CPU/GPU transfer. No silent truncation, splitter reinterpretation or fabricated backfill.

## M4 — Stage coverage and measured value

AKS-62 initially targets train-fitted standardization, descriptive/covariance/correlation operations and histogram/bin/aggregate chart data. AKS-63 requires a declared estimator family with real GPU fit, prediction and evaluation; CPU fitting plus GPU metrics is reported as mixed execution.

AKS-60 must compile a meaningful CPU numerical function beyond affine smoke. Initial compatibility target is batched covariance/correlation via Statistics-style routines, with actual package/function/version and preserved semantics fixed before testing. All adapters publish coverage by operation/model/version/dtype/shape and explicit CPU reasons. Model substitution requires explicit user selection with a separate identity.

Declare input/resource envelopes and numerical tolerances; report cold compilation, transfers, kernel/synchronization, end-to-end CPU/GPU timings and memory, including regressions and variability. Demonstrate useful reproducible benefit in declared native and compiler envelopes; no blanket speedup claim. Parsing/I/O and browser chart rendering are separate from accelerated numerical computation.

## M5 — Design can progress in parallel

Penpot Revision 2 is a proposal with six light/dark task-screen pairs and states. Models/Deploy/Monitor/Settings, exhaustive responsive states and representative user testing remain open. AKS-64 tracks the previously untracked design continuation. Its final signoff consumes the actual backend support matrix from M2–M4, while design preparation can proceed earlier.

Preserve System/Light/Dark independently of guidance/density; include keyboard/non-drag/chart-table alternatives and actionable failure states. Correct the 2,000-row sample or label it future scope. A materialized split creates a new plan when changed. Standardization is the current grounded example; custom transforms/composition remain proposed.

Initial load and project switches disable mutations until the actual project resolves; failure offers retry/reselection. AKS-49's reproduced default-project 404 remains unfixed. Direction selection, document approval and prototype QA do not grant final frontend approval.

## M6 — Implement only the approved cross-route product

Reuse AKS-45/46 lifecycle and drift criteria, AKS-47 shared project state, AKS-48 real-file onboarding and AKS-49 guidance/accessibility/hydration. Extend evidence displays for approved compute contracts without duplicating job/runtime ownership. Analysis-only users can finish without training; modeling users get validation/test isolation, explanation, registry and local output.

UI implementation requires recorded final design approval **and** the backend capabilities used by each flow. Backend work can continue while design is pending. Restore/navigation/source changes must invalidate dependent state correctly; never use fixtures as product evidence in release/local-appliance mode.

## M7 — Package and certify one selected candidate

AKS-65 builds the explicitly enabled local Linux/Docker compiler worker on Windows: authenticated, limited to approved roots, no silent provisioning or uploads, safe enable/revoke/restart and useful missing-prerequisite states. Native Windows CPU/GPU operation remains independent. Integration may be prepared after M3–M4, but acceptance belongs to M7.

AKS-66 certifies EXE and Linux/Docker packages on clean/offline installations, CPU-only and NVIDIA hardware, Windows WSL2 Docker GPU access, real resource/failure cases, local PostgreSQL metadata, offline Hub and backup/migration. Same-candidate no-skip Windows/Debian `npm run verify:release` plus the added hardware/compiler/packaging matrix is required. Full selected capabilities, reviews, merge and traceability must be reconciled before Done or release; no release action is authorized now.

## Deferred compatibility

[AKS-67](https://linear.app/gravelaw/issue/AKS-67/deferred-verify-additional-gpu-vendors-and-multi-device-compatibility) is Medium priority: other vendors, real multi-device qualification and future compatibility. Visible devices/upstream support do not certify JuliaFlow. macOS packaging, cloud/provider/enterprise integrations and new source connectors require separately accepted scope. CPU operation and honest unavailable reasons remain available.

## Tracking, verification and rollback

New release issues are High, owned by Akshay, Todo. AKS-57 is In Progress for document/tracker work. Existing owners/priorities/statuses are preserved; no product issue moves to Done. [Acceptance](acceptance-v0.5.0.md) lists scenarios and proportional commands; future commands are explicitly labelled.

Every implementation has a scoped branch and rollback: disable a defective adapter with truthful CPU/unavailable behavior; preserve required-GPU rejection, stored estimator meaning and checksummed artifacts. Version contracts/readers before producers and retain historical records. Packaging rollback preserves workspaces. Document rollback is a scoped revision against the retained v0.4.1 snapshot. No destructive migration is authorized.
