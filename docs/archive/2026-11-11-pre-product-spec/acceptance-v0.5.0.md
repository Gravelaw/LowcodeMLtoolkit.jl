# JuliaFlow v0.5.0 acceptance scenarios

Date: 2026-09-20 · Owner: Akshay · [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination).

These are **future executable acceptance requirements**, not results from this documentation task. The [BRD](../business-requirements-v0.3.0.md) defines behavior; [traceability](brd-traceability.md) assigns each ID and preserves history. Existing tests are starting gates, not presumed coverage of future features.

Each implementation records exact candidate SHA/tree, platform, Julia/package/driver/runtime versions, fixture or real-file checksum, expected/actual result, pass/fail/skip, artifact URI/hash and review. Preserve success/rejection assertions and required-GPU policy. Fix numeric CPU references, tolerances, dtype/shape and algorithm before measuring. Every `future ... gate` below must be implemented and named in its issue before acceptance; it is not an existing npm script.

<a id="ac-01"></a>
## AC-01 — Local-only workstation

Requirement: **JF-LOC-001** · M6–M7 · [AKS-48](https://linear.app/gravelaw/issue/AKS-48/local-dataset-wizard-mvp), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

Scenario and observable: Complete real-file analysis and modeling with networking disabled; verify no required external requests and usable offline recovery.

Verification entry points: `npm run smoke:local-bootstrap`; `npm run smoke:live-backend-browser`; `npm run verify:release`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-02"></a>
## AC-02 — Local authority and confinement

Requirement: **JF-LOC-002** · M1/M7 · [AKS-41](https://linear.app/gravelaw/issue/AKS-41/local-gateway-and-import-trust-boundary-hardening), [AKS-55](https://linear.app/gravelaw/issue/AKS-55/constrain-default-local-gateway-browser-mutation-authority), [AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows).

Scenario and observable: Reject absent/invalid authority, denied origins, traversal and escaping mounts; test permitted operations and redacted diagnostics without secrets.

Verification entry points: `npm run julia:test:local-sources`; `npm run julia:test:api-gateway`; `npm run smoke:local-bootstrap`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-03"></a>
## AC-03 — Durable data and metadata

Requirement: **JF-LOC-003** · M3/M7 · [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

Scenario and observable: Round-trip workflow/project/artifacts, exercise concurrent PostgreSQL metadata, and reject corrupt or unsupported source records without changing existing persistence semantics.

Verification entry points: `npm run validate:contracts`; `npm run julia:test:repository`; `npm run smoke:local-metadata`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-04"></a>
## AC-04 — Offline Hub trust

Requirement: **JF-LOC-004** · M7 · [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

Scenario and observable: Install a trusted local extension offline; reject altered/untrusted/incompatible packages without silent network fetch.

Verification entry points: `npm run smoke:local-offline-hub`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-05"></a>
## AC-05 — Reproducibility and recovery

Requirement: **JF-REP-001** · M6–M7 · [AKS-45](https://linear.app/gravelaw/issue/AKS-45/model-registry-lifecycle-gates-and-first-class-repository), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

Scenario and observable: Restore on another installation; compare checksums/row identity/results within declared tolerance; reject corrupted artifacts, retain explicit missing historical evidence and preserve user data on rollback.

Verification entry points: `npm run smoke:local-reproducibility`; `npm run smoke:local-migration`; `npm run julia:test:repository`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-06"></a>
## AC-06 — Explainability and provenance

Requirement: **JF-EXP-001** · M6 · [AKS-44](https://linear.app/gravelaw/issue/AKS-44/statistical-eda-and-schema-diagnostics-foundation), [AKS-45](https://linear.app/gravelaw/issue/AKS-45/model-registry-lifecycle-gates-and-first-class-repository).

Scenario and observable: Inspect/export an explanation tied to actual dataset/model/run and method; unsupported or missing evidence cannot produce an approval or invented score.

Verification entry points: `npm run smoke:local-explainability`; `npm run julia:test:project-evidence`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-07"></a>
## AC-07 — Nine routes and two complete journeys

Requirement: **JF-UX-001** · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-47](https://linear.app/gravelaw/issue/AKS-47/project-backed-frontend-state-migration), [AKS-48](https://linear.app/gravelaw/issue/AKS-48/local-dataset-wizard-mvp), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline).

Scenario and observable: Complete import-to-saved/exported analysis without training, and import-to-evaluation/registry/local output with evidence; navigate every route without losing state or inventing success.

Verification entry points: `npm run smoke:live-backend-browser`; `npm run build`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-08"></a>
## AC-08 — Appearance independent of assistance

Requirement: **JF-UX-002** · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline).

Scenario and observable: Test OS theme changes and persisted overrides, both themes at each guidance/density combination; essential safety stays visible and controls retain equivalent behavior.

Verification entry points: `npm run test`; `npm run build`; `npm run smoke:live-backend-browser`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-09"></a>
## AC-09 — Accessible responsive interactions

Requirement: **JF-UX-003** · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline), [AKS-50](https://linear.app/gravelaw/issue/AKS-50/persona-flow-browser-and-release-verification-for-datascienceproject).

Scenario and observable: Keyboard-only import/transform/chart/export and lifecycle review; 200% zoom and narrow layouts without hidden required controls; announce errors/focus recovery and explain unsupported operations.

Verification entry points: `npm run test`; `npm run build`; `npm run smoke:live-backend-browser`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-10"></a>
## AC-10 — Resolved-project mutation gate

Requirement: **JF-UX-004** · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline).

Scenario and observable: Delay/fail/race project resolution; assert no request uses placeholder/default/stale identity; successful retry enables only resolved-project actions. Existing 404 race remains unfixed.

Verification entry points: `npm run test`; `npm run smoke:live-backend-browser`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-11"></a>
## AC-11 — Explicit final design approval

Requirement: **JF-UX-005** · M5 before M6 UI · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-38](https://linear.app/gravelaw/issue/AKS-38/design-review-gate-for-p0-architecture-artifacts).

Scenario and observable: Review linked design artifact and approval record; direction selection, mockup QA, documentation approval or green tests cannot authorize frontend edits.

Verification entry points: Design review and persona evidence; `npm run validate:control-doc-sync`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-12"></a>
## AC-12 — Scalable local ingestion

Requirement: **JF-DS-001** · M3 · [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion), [AKS-48](https://linear.app/gravelaw/issue/AKS-48/local-dataset-wizard-mvp).

Scenario and observable: Test 999/1000/1001 plus representative larger files, quoting/newlines/duplicate headers/malformed input/chunk boundaries and memory pressure; reject atomically with no silent truncation.

Verification entry points: `npm run julia:test:local-sources`; `npm run julia:test:splits`; `npm run smoke:local-data-estate`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-13"></a>
## AC-13 — Immutable split and train-only fit

Requirement: **JF-DS-002** · M1/M3/M4 · [AKS-42](https://linear.app/gravelaw/issue/AKS-42/validation-and-test-strategy-contracts-with-enforcement-gates), [AKS-54](https://linear.app/gravelaw/issue/AKS-54/enforce-declared-split-assignments-and-exclude-final-test-data-from), [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion).

Scenario and observable: Mutate final-test labels, reorder groups/time/depth and alter source/checksum; selection and fitted parameters remain train-only; invalid membership/locks reject. Unsupported external/k-fold plans stay unavailable until separately verified.

Verification entry points: `npm run julia:test:splits`; `npm run julia:test:tuning`; `npm run julia:test:project-evidence`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-14"></a>
## AC-14 — Preparation and code boundaries

Requirement: **JF-DS-003** · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline), [AKS-42](https://linear.app/gravelaw/issue/AKS-42/validation-and-test-strategy-contracts-with-enforcement-gates).

Scenario and observable: Show actual before/after scope and train-fitted values; retain checkpoint on one-way conversion to custom code, and never enable proposed transforms as if executable.

Verification entry points: `npm run test`; `npm run build`; `npm run julia:test:splits`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-15"></a>
## AC-15 — Lifecycle and drift validity

Requirement: **JF-ML-001** · M6 · [AKS-45](https://linear.app/gravelaw/issue/AKS-45/model-registry-lifecycle-gates-and-first-class-repository), [AKS-46](https://linear.app/gravelaw/issue/AKS-46/drift-monitoring-baseline-and-retraining-review-records).

Scenario and observable: Reject missing/stale/cross-version evidence and unsafe transitions; prove approved registration/deploy, prediction export and rollback with persisted baseline identity.

Verification entry points: `npm run julia:test:project-evidence`; `npm run julia:test:repository`; `npm run smoke:live-backend-browser`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-16"></a>
## AC-16 — Discovery and usability probes

Requirement: **JF-HW-001** · M2 · [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution).

Scenario and observable: Exercise no GPU, incompatible driver/runtime, inaccessible device, insufficient resources and successful probe; invented/mock registry cannot certify hardware.

Verification entry points: `npm run smoke:local-hardware`; `npm run julia:test:worker`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-17"></a>
## AC-17 — Preferences and actual device binding

Requirement: **JF-HW-002** · M2 · [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution), [AKS-43](https://linear.app/gravelaw/issue/AKS-43/typed-local-jobs-for-data-science-and-ml-workflows).

Scenario and observable: Prove CPU-only path, exact allocation device, requested/planned/actual distinctions, safe permitted CPU fallback and rejection for cuda_required when unavailable/unsupported.

Verification entry points: `npm run julia:test:worker`; `npm run smoke:local-hardware`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-18"></a>
## AC-18 — Supported operation planning

Requirement: **JF-RT-001** · M3 · [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts).

Scenario and observable: Test capability positives/negatives, missing operations, shape/dtype/layout incompatibility and required-GPU rejection before side effects; never claim arbitrary package conversion.

Verification entry points: `npm run validate:contracts`; `npm run julia:test:helpers`; `npm run julia:test:worker`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-19"></a>
## AC-19 — Contract-first phase evidence

Requirement: **JF-RT-002** · M2–M3 · [AKS-43](https://linear.app/gravelaw/issue/AKS-43/typed-local-jobs-for-data-science-and-ml-workflows), [AKS-56](https://linear.app/gravelaw/issue/AKS-56/align-project-job-resource-evidence-contracts-and-validate-runtime), [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts), [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution).

Scenario and observable: Positive/negative payload and persistence round trips including historical absence, mock rejection and fit=cpu/metrics=cuda mixed execution; never infer actual execution from selected backend.

Verification entry points: `npm run validate:contracts`; `npm run julia:test:project-contracts`; `npm run julia:test:repository`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-20"></a>
## AC-20 — Memory, movement and safe retry

Requirement: **JF-RT-003** · M3 · [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts).

Scenario and observable: Force OOM/transfer/worker failure and cancellation; verify no duplicate artifacts or partial success and no retry hiding invalid input, algorithm defects or committed side effects.

Verification entry points: `npm run julia:test:worker`; `npm run julia:test:helpers`; `npm run julia:test:repository`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-21"></a>
## AC-21 — Shared native runtime adapters

Requirement: **JF-RT-004** · M3 · [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts).

Scenario and observable: Execute supported adapter on real CUDA and CPU reference; confirm device/result/synchronization, isolation and unsupported behavior without product logic expanding the gateway.

Verification entry points: `npm run julia:test:worker`; `npm run julia:test:api-gateway`; `npm run smoke:local-hardware`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-22"></a>
## AC-22 — Required compiler integration

Requirement: **JF-RT-005** · M3–M4 · [AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code).

Scenario and observable: Initial candidate: batched covariance/correlation through Statistics-style numerical code. Freeze actual package/function/version and semantics; test varied dtypes/shapes/scalars/control flow, equivalence, cache invalidation and measured performance. Replace incompatible candidate explicitly; no blanket conversion claim.

Verification entry points: `npm run julia:instantiate`; `npm run julia:test:helpers`; `npm run julia:test:worker`; future compiler gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-23"></a>
## AC-23 — Preparation acceleration

Requirement: **JF-ACC-001** · M4 · [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation).

Scenario and observable: CPU/GPU parity for fitting/application, final-test mutation invariance, missing/nonfinite policy and memory/fallback/rejection across declared envelopes.

Verification entry points: `npm run julia:test:splits`; `npm run julia:test:helpers`; future operation benchmark gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-24"></a>
## AC-24 — Analysis and EDA acceleration

Requirement: **JF-ACC-002** · M4 · [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation), [AKS-44](https://linear.app/gravelaw/issue/AKS-44/statistical-eda-and-schema-diagnostics-foundation).

Scenario and observable: Produce measured project-backed analysis without modeling; CPU/GPU equivalence, numerical edge cases and provenance; missing data cannot create synthetic success.

Verification entry points: `npm run julia:test:project-evidence`; `npm run julia:test:helpers`; future operation benchmark gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-25"></a>
## AC-25 — Chart-data acceleration

Requirement: **JF-ACC-003** · M4 · [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation).

Scenario and observable: Compare chart-data arrays against CPU reference on declared inputs; verify actual Julia compute evidence and fallback. Browser rendering speed or screenshots cannot certify this requirement.

Verification entry points: `npm run julia:test:helpers`; `npm run validate:contracts`; future operation benchmark gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-26"></a>
## AC-26 — Supported fitting acceleration

Requirement: **JF-ACC-004** · M4 · [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation).

Scenario and observable: CPU/GPU fit/prediction parity and seed/tolerance policy, train-only inputs, actual fit device evidence, incompatible model/dtype rejection and required-GPU behavior.

Verification entry points: `npm run julia:test:tuning`; `npm run julia:test:splits`; future model hardware gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-27"></a>
## AC-27 — Inference and evaluation acceleration

Requirement: **JF-ACC-005** · M4 · [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation).

Scenario and observable: Verify predictions and MAE/MSE/RMSE/accuracy as applicable against CPU; show CPU fit plus GPU metrics truthfully, reject unavailable evidence and avoid repeated unnecessary transfers.

Verification entry points: `npm run julia:test:tuning`; `npm run julia:test:project-evidence`; future model hardware gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-28"></a>
## AC-28 — Measured benefit and resource envelopes

Requirement: **JF-PERF-001** · M4/M7 · [AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code), [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation), [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

Scenario and observable: Freeze inputs/reference/tolerances before measurements; report repeats/variation and slow cases. Demonstrate reproducible end-to-end benefit for at least one declared native and compiler workload envelope; auto selection uses evidence-aware thresholds.

Verification entry points: future compiler/operation/model benchmark gates; `npm run smoke:local-hardware`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-29"></a>
## AC-29 — First-release platforms and offline install

Requirement: **JF-PKG-001** · M7 · [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

Scenario and observable: Clean-machine CPU-only/NVIDIA install, offline first run, upgrade/rollback/uninstall preserving user artifacts, insufficient disk/RAM/driver recovery and lab metadata/migration tests.

Verification entry points: `npm run smoke:local-bootstrap`; `npm run smoke:local-metadata`; `npm run smoke:local-migration`; `npm run verify:release`. Result: **not run for v0.5.0 acceptance**.

<a id="ac-30"></a>
## AC-30 — Opt-in local compiler worker

Requirement: **JF-PKG-002** · M7 · [AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows).

Scenario and observable: Test disabled/enable/revoke/restart, no Docker/WSL2/GPU, denied origins/credentials/escaping mounts and successful local GPU work. Native CPU/GPU remain usable without worker.

Verification entry points: `npm run julia:test:local-sources`; `npm run julia:test:worker`; future container isolation gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-31"></a>
## AC-31 — Honest deferred compatibility

Requirement: **JF-COMP-001** · Deferred · [AKS-67](https://linear.app/gravelaw/issue/AKS-67/deferred-verify-additional-gpu-vendors-and-multi-device-compatibility).

Scenario and observable: Unavailable vendor/backend reason is explicit; device-count-only and mock placement cannot pass multi-device acceptance. Do not count deferred compatibility as first-release hardware proof.

Verification entry points: `npm run smoke:local-hardware`; future per-device isolation gate. Result: **not run for v0.5.0 acceptance**.

<a id="ac-32"></a>
## AC-32 — Composite release acceptance

Requirement: **JF-REL-001** · M1/M7 · [AKS-38](https://linear.app/gravelaw/issue/AKS-38/design-review-gate-for-p0-architecture-artifacts), [AKS-50](https://linear.app/gravelaw/issue/AKS-50/persona-flow-browser-and-release-verification-for-datascienceproject), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

Scenario and observable: Resolve exact-head Debian failure before integration; record every skipped/unavailable phase as a gap. Green web/Julia, historic Windows runs or documentation validation alone cannot certify release.

Verification entry points: `npm run verify:release`; `npm run validate:control-doc-sync`; `npm run validate:brd-traceability`. Result: **not run for v0.5.0 acceptance**.

## Cross-cutting fixtures and certification

| Fixture / environment | Required evidence |
| --- | --- |
| Bounded/scalable files | 999/1,000/1,001 rows plus declared larger envelopes; quoting/newlines, duplicate headers, malformed rows, missing/nonfinite values, chunk boundaries, full counts/checksums and no truncation. |
| Immutable membership | Train/validation/test identities, repeated groups and unsorted time/depth, final-test-label counterfactuals, source changes, stale plans, incomplete folds/locks and train-only standardization. |
| Hardware failures | No GPU, detected-but-unusable device, invalid selection, driver/runtime mismatch, insufficient VRAM/RAM/disk, unsupported dtype/shape/operation, compiler incompatibility, cancellation and safe/unsafe retry. |
| Numerical comparison | Same algorithm/inputs across CPU, native CUDA/KA and compiler where supported; cold compile, warm runs, transfer, kernel/sync, end-to-end and memory; repeats/variation and cases where CPU is faster. |
| Device identity | Allocation/execution device per phase; reject CPU mocks/invented registry as proof. Future multi-device claims require real work and isolation/contention/failure evidence on each device. |
| Personas/project context | Load/switch delay, lookup failure, retry/reselection and rapid switching cannot target placeholder/stale IDs; analysis-only, programmer, non-coder, researcher/student, data-engineer and lifecycle tasks in both themes with keyboard/zoom/narrow layouts. |
| Packaging | Windows EXE CPU-only/native NVIDIA; Linux/Docker CPU-only/NVIDIA/compiler; explicitly enabled confined Windows WSL2 GPU worker; offline assets, missing prerequisites, install/upgrade/migration/rollback and no data loss. |

Root `npm run test` excludes Julia, browser, hardware, local smokes and full release. M7 requires `npm run verify:release` on the same candidate for Windows and Debian with no skipped required phases, plus new compiler/operation/model/packaging gates. A green legacy script cannot prove requirements it has not yet been extended to exercise.
