# JuliaFlow — Hardware-aware Local Data Science Workstation

## Document control

- Version: **0.5.0**. Date: **2026-09-20**. Owner: **Akshay / LowCodeML**.
- Status: **Approved requirements and roadmap; implementation and release acceptance open.** This document is not final frontend design approval.
- Canonical filename remains `business-requirements-v0.3.0.md` for existing links and validators.
- Supersedes v0.4.1 at `c363e0086552334fc2268222550ea031c548b4f9`; the [dated immutable snapshot](docs/archive/2026-09-20-brd-v0.4.1/README.md) records exact source bytes and SHA-256. Existing archives are unchanged.
- Coordination: [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination) · [roadmap](docs/product-roadmap.md) · [next steps](docs/next-steps.md) · [acceptance](docs/acceptance-v0.5.0.md) · [sources](docs/source-reconciliation-2026-09-20.md).

## Product promise

JuliaFlow is a local hardware-aware data-science workstation for answering analysis questions and developing reproducible models. After Windows EXE or Linux/Docker installation, it discovers CPU, RAM, working disk and GPU/runtime capabilities, explains usable operations and lets the user choose compute preferences. Supported numerical GPU regions across preparation, EDA, chart-data computation, fitting, inference and evaluation are first-release requirements. Native adapters and compiler integration are both required.

Code is possible but not required. Users manage and prepare data, answer and export an analysis without training a model, or continue through valid modeling, explanation, local deployment and monitoring. Core work is offline and local-only; no cloud account, remote GPU, public registry or telemetry is required. Local service authentication and filesystem controls remain mandatory.

Acceleration coverage is explicit by operation, model/package version, dtype, shape and backend. Compatible CPU-oriented Julia numerical code can use compiler integration; arbitrary packages are not promised to convert. Unsupported regions execute on CPU with reasons where policy permits. A required-GPU request rejects instead of silently weakening its contract. Selected estimators are never silently exchanged for different GPU models.

## People and journeys

| Persona | Required journey |
| --- | --- |
| Programming data scientists | Inspect Julia and provenance, use governed declared custom steps, choose resources, compare compatible runs and export reproducible work. Arbitrary code does not promise reversible visual editing. |
| Non-coding analysts and domain experts | Import real data, correct schema/roles, prepare and analyze it, understand assumptions and save/export findings without code or model fitting. Domain expertise and coding skill are independent. |
| Researchers, students and teaching labs | Guided or compact workflows, protected validation/test boundaries, interpretable evidence, offline templates, repeatable seeds/environments and cross-installation bundles. |
| Data engineers | Confined ingestion, data quality/schema changes, stable row/artifact identity, explicit resource/format limits and failure recovery. |
| MLOps and lab/team users | Evidence-based registry/deploy/rollback, PostgreSQL metadata/RBAC/audit, versioned drift baselines, local endpoint/batch outputs and reproducible retraining review. |

Guidance, density and appearance are independent preferences. Every persona can use System, Light or Dark and may need advanced statistical controls.

## Nine coherent routes

| Route | First-release responsibility |
| --- | --- |
| Explorer | Durable project selection, question/brief, recent work, local privacy, services, storage and hardware health. |
| Data | Real-file onboarding, source grants, full versus sampled scope, schema/type correction and target/id/group/time/depth/sensitive/ignore roles. |
| Transform | Verified fit/apply preparation, learned train-only parameters, row/split provenance, previews and non-drag operations; proposed functions remain unavailable. |
| Visualize | Analysis-first questions, statistical outputs, chart-data scope/units, accessible tables, saved analyses and local dashboard/export without modeling prerequisites. |
| ML Studio | Baselines, supported estimators, valid training/tuning/evaluation, compatible comparisons and phase-level compute evidence. |
| Models | Registry, cards/explanations, artifact integrity and evidence-gated lifecycle transitions. |
| Deploy | Local endpoints/batch jobs and exports, prerequisites, authority and rollback. Cloud deployment is optional. |
| Monitor | Job/resource/failure evidence, valid/stale/missing baselines, drift definitions, review and retraining provenance. |
| Settings | Roots, auth/RBAC, offline extensions, backups, appearance/guidance/density, capabilities/preferences and opt-in local compiler worker. |

Every route needs actionable loading, empty, denied, error and unsupported states, responsive layouts and accessible keyboard/non-drag operation. Preserve the route shell, runtime `juliaflow-config.js`, selectors and coverage unless an approved replacement proves equivalent behavior.

## Evidence language and current truth

| Classification | Meaning |
| --- | --- |
| Delivered / merged behavior | Requires merged revision plus criterion-specific executable evidence. Historical completion is limited to its source; no v0.5.0 requirement is newly certified here. |
| Locally verified review candidate | Bounded behavior tested at recorded revisions in open draft PRs. Platform, review and merge gates remain open. |
| Approved requirement | Normative v0.5.0 obligation; approval does not assert implementation. |
| Proposed design | Penpot concepts and unimplemented capabilities, not production evidence or final design approval. |
| Deferred compatibility | Other vendors, macOS packaging, cloud/provider expansion and multi-device qualification beyond selected first-release scope. |

The approved baseline is PR #55 `c363e008`. Current execution supports at most **1,000 unquoted CSV data rows with unique headers**. The 2,000-row design sample is incompatible today. Split plans/assignments/folds/locks are immutable; source or split changes require a new plan. Numeric train-fitted standardization exists in the candidate; broader custom transforms and automatic pipeline composition remain proposed.

Earlier remediation records 1,492 gateway/boundary assertions and five browser scenarios at their original revisions, with PostgreSQL integration skipped. These are not fresh release results. Source still contains mock-derived worker GPU metadata and unbound recorded device selection. One KA CUDA smoke passed on one RTX 5080 in the older `efe6d32` assessment with a CUDA 13.4/13.2 warning; a compiled-modules-disabled diagnostic failed. Broad training, compiler and multi-GPU proof is absent. [Exact revisions/checks/limits](docs/source-reconciliation-2026-09-20.md).

## Stable requirements

These are new v0.5.0 IDs. Existing FR/NFR labels and all 46 historical checklist mappings remain in [traceability](docs/brd-traceability.md), without renumbering or promotion. Every ID maps to a milestone, issue and scenario. All are required for the selected first release except explicitly deferred JF-COMP-001.

### JF-LOC-001 — Local-only workstation

Core analysis/modeling, artifacts and settings work locally with no cloud account, telemetry, network or automatic uploads once installation media is available.

Acceptance: [AC-01](docs/acceptance-v0.5.0.md#ac-01) · M6–M7 · [AKS-48](https://linear.app/gravelaw/issue/AKS-48/local-dataset-wizard-mvp), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

### JF-LOC-002 — Local authority and confinement

Authenticated local mutations, expected origins, approved real paths, symlink/junction policy, owner-only or redacted exports, encrypted credential storage, audit and lab/team RBAC apply to all new compute boundaries.

Acceptance: [AC-02](docs/acceptance-v0.5.0.md#ac-02) · M1/M7 · [AKS-41](https://linear.app/gravelaw/issue/AKS-41/local-gateway-and-import-trust-boundary-hardening), [AKS-55](https://linear.app/gravelaw/issue/AKS-55/constrain-default-local-gateway-browser-mutation-authority), [AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows).

### JF-LOC-003 — Durable data and metadata

Preserve Arrow IPC between nodes and TOML round trips, managed data zones and checksums, single-user metadata and local PostgreSQL lab/team metadata. Retain Parquet/Arrow analytical artifacts and local-query direction; metadata support does not enable database source connectors.

Acceptance: [AC-03](docs/acceptance-v0.5.0.md#ac-03) · M3/M7 · [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

### JF-LOC-004 — Offline Hub trust

Bundled/local extensions, cache and offline mirror work without a public registry; verify artifact checksums, trust and sandboxed compatibility; unsigned/unsafe extensions are blocked by default.

Acceptance: [AC-04](docs/acceptance-v0.5.0.md#ac-04) · M7 · [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

### JF-REP-001 — Reproducibility and recovery

Export/import workflow, source hashes, split/fit state, seeds, package/runtime versions, actual compute, cards, metrics/explanations, dashboards and notes. Backup filesystem and metadata, offer scheduled snapshot retention and restore/migration integrity.

Acceptance: [AC-05](docs/acceptance-v0.5.0.md#ac-05) · M6–M7 · [AKS-45](https://linear.app/gravelaw/issue/AKS-45/model-registry-lifecycle-gates-and-first-class-repository), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

### JF-EXP-001 — Explainability and provenance

Supported models provide meaningful global/local explanations, permutation importance, coefficient/importances and applicable residual/calibration/slice/PDP/ICE views, dataset/model cards, assumptions and limits; unsupported methods show reasons.

Acceptance: [AC-06](docs/acceptance-v0.5.0.md#ac-06) · M6 · [AKS-44](https://linear.app/gravelaw/issue/AKS-44/statistical-eda-and-schema-diagnostics-foundation), [AKS-45](https://linear.app/gravelaw/issue/AKS-45/model-registry-lifecycle-gates-and-first-class-repository).

### JF-UX-001 — Nine routes and two complete journeys

Explorer, Data, Transform, Visualize, ML Studio, Models, Deploy, Monitor and Settings share durable project context. Support independent analysis-only and modeling/lifecycle journeys for code-capable and non-coding users.

Acceptance: [AC-07](docs/acceptance-v0.5.0.md#ac-07) · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-47](https://linear.app/gravelaw/issue/AKS-47/project-backed-frontend-state-migration), [AKS-48](https://linear.app/gravelaw/issue/AKS-48/local-dataset-wizard-mvp), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline).

### JF-UX-002 — Appearance independent of assistance

System, Light and Dark select appearance only; guidance, density and Julia inspection are independent. Preserve selection/project/task and series identity when changing any setting.

Acceptance: [AC-08](docs/acceptance-v0.5.0.md#ac-08) · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline).

### JF-UX-003 — Accessible responsive interactions

Essential workflows support keyboard and non-drag alternatives, visible focus, accessible dialogs/tabs, chart text/table alternatives, labelled units/scope, responsive narrow layouts and zoom, and actionable empty/loading/error/unavailable states.

Acceptance: [AC-09](docs/acceptance-v0.5.0.md#ac-09) · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline), [AKS-50](https://linear.app/gravelaw/issue/AKS-50/persona-flow-browser-and-release-verification-for-datascienceproject).

### JF-UX-004 — Resolved-project mutation gate

Disable project mutations on initial load and project switch until actual project identity/context resolves. Failure keeps mutations disabled and exposes Retry loading and Choose another project.

Acceptance: [AC-10](docs/acceptance-v0.5.0.md#ac-10) · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline).

### JF-UX-005 — Explicit final design approval

Complete remaining lifecycle/settings routes, real-file compute states, responsive/accessibility and representative persona tests. Record explicit user approval of final design before frontend implementation.

Acceptance: [AC-11](docs/acceptance-v0.5.0.md#ac-11) · M5 before M6 UI · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-38](https://linear.app/gravelaw/issue/AKS-38/design-review-gate-for-p0-architecture-artifacts).

### JF-DS-001 — Scalable local ingestion

Replace the current <=1,000 unquoted-row unique-header execution bound with verified streaming/batched ingestion, full-file row identity/checksums, schema and resource envelopes. Keep current safeguards until verified replacement.

Acceptance: [AC-12](docs/acceptance-v0.5.0.md#ac-12) · M3 · [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion), [AKS-48](https://linear.app/gravelaw/issue/AKS-48/local-dataset-wizard-mvp).

### JF-DS-002 — Immutable split and train-only fit

Reuse concrete checksummed assignments, folds and locks across fit/tune/evaluate and CPU/GPU batches. Source or split changes create a new plan. Preserve whole-group/time/depth isolation and final-test policy.

Acceptance: [AC-13](docs/acceptance-v0.5.0.md#ac-13) · M1/M3/M4 · [AKS-42](https://linear.app/gravelaw/issue/AKS-42/validation-and-test-strategy-contracts-with-enforcement-gates), [AKS-54](https://linear.app/gravelaw/issue/AKS-54/enforce-declared-split-assignments-and-exclude-final-test-data-from), [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion).

### JF-DS-003 — Preparation and code boundaries

Expose verified train-fitted numeric standardization and learned parameters. Broader custom transforms, pipeline composition, imputation, joins/aggregations/pivots and arbitrary Julia round trips remain proposed until scoped and verified; governed custom steps declare inputs/outputs.

Acceptance: [AC-14](docs/acceptance-v0.5.0.md#ac-14) · M5–M6 · [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval), [AKS-49](https://linear.app/gravelaw/issue/AKS-49/guided-no-code-workflow-and-accessibility-baseline), [AKS-42](https://linear.app/gravelaw/issue/AKS-42/validation-and-test-strategy-contracts-with-enforcement-gates).

### JF-ML-001 — Lifecycle and drift validity

Registry promotion, deployment/export, monitoring and retraining consume real versioned evaluation, split, model/source, metric-definition and rollback evidence. Show no/stale/incompatible drift baseline honestly.

Acceptance: [AC-15](docs/acceptance-v0.5.0.md#ac-15) · M6 · [AKS-45](https://linear.app/gravelaw/issue/AKS-45/model-registry-lifecycle-gates-and-first-class-repository), [AKS-46](https://linear.app/gravelaw/issue/AKS-46/drift-monitoring-baseline-and-retraining-review-records).

### JF-HW-001 — Discovery and usability probes

After EXE/Docker installation discover CPU cores/threads, RAM/pressure, disk/working space, GPU vendor/device/VRAM and driver/runtime; distinguish installed, visible, initialized and successfully probed capabilities.

Acceptance: [AC-16](docs/acceptance-v0.5.0.md#ac-16) · M2 · [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution).

### JF-HW-002 — Preferences and actual device binding

Offer CPU-only, supported auto/preferred GPU and required-GPU policy consistent with existing public names; confirm preference after discovery, apply caps and bind selected physical device before allocation.

Acceptance: [AC-17](docs/acceptance-v0.5.0.md#ac-17) · M2 · [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution), [AKS-43](https://linear.app/gravelaw/issue/AKS-43/typed-local-jobs-for-data-science-and-ml-workflows).

### JF-RT-001 — Supported operation planning

Register operation/model/package/version, CPU/native/compiler implementations, compatible dtypes/shapes/layouts, memory needs and retry policy; plan supported regions and report explicit CPU reasons for unsupported regions.

Acceptance: [AC-18](docs/acceptance-v0.5.0.md#ac-18) · M3 · [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts).

### JF-RT-002 — Contract-first phase evidence

Design inventory/plans/phase evidence across TS/OpenAPI/Julia/repository/frontend before producer changes. Record requested/planned/actual backend, actual device, version, timings, memory, fallback/error and provenance after synchronization; absent historical evidence remains unavailable.

Acceptance: [AC-19](docs/acceptance-v0.5.0.md#ac-19) · M2–M3 · [AKS-43](https://linear.app/gravelaw/issue/AKS-43/typed-local-jobs-for-data-science-and-ml-workflows), [AKS-56](https://linear.app/gravelaw/issue/AKS-56/align-project-job-resource-evidence-contracts-and-validate-runtime), [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts), [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution).

### JF-RT-003 — Memory, movement and safe retry

Respect RAM/VRAM/disk headroom, bounded queues/chunks, buffer lifetimes and cancellation; minimize validated transfers while preserving Arrow boundaries. CPU retry is limited to pure/idempotent work after classified recoverable backend/resource failure.

Acceptance: [AC-20](docs/acceptance-v0.5.0.md#ac-20) · M3 · [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts).

### JF-RT-004 — Shared native runtime adapters

Use CUDA.jl and KernelAbstractions for supported numerical execution on Windows and Linux; share operation planning and evidence across workers and data-science modules; keep gateway composition/routing focused.

Acceptance: [AC-21](docs/acceptance-v0.5.0.md#ac-21) · M3 · [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts).

### JF-RT-005 — Required compiler integration

Integrate Reactant as initial compiler candidate on Linux/NVIDIA for meaningful compatible CPU-oriented numerical package/function regions beyond affine smoke. Publish coverage/incompatibilities; compiler capability is a first-release gate.

Acceptance: [AC-22](docs/acceptance-v0.5.0.md#ac-22) · M3–M4 · [AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code).

### JF-ACC-001 — Preparation acceleration

Accelerate supported numerical preparation beginning with train-fitted standardization and held-out application, retaining learned parameters and row identity; CPU-only I/O/control regions have explicit reasons.

Acceptance: [AC-23](docs/acceptance-v0.5.0.md#ac-23) · M4 · [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation).

### JF-ACC-002 — Analysis and EDA acceleration

Accelerate supported reductions/statistical numerical regions, initially descriptive aggregates and covariance/correlation, with data scope, assumptions and unsupported-method reasons.

Acceptance: [AC-24](docs/acceptance-v0.5.0.md#ac-24) · M4 · [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation), [AKS-44](https://linear.app/gravelaw/issue/AKS-44/statistical-eda-and-schema-diagnostics-foundation).

### JF-ACC-003 — Chart-data acceleration

Accelerate supported histogram/bin/aggregate/chart-data computations; distinguish them from browser chart rendering. Retain units, sample/full-data scope, checksum and accessible alternatives.

Acceptance: [AC-25](docs/acceptance-v0.5.0.md#ac-25) · M4 · [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation).

### JF-ACC-004 — Supported fitting acceleration

Provide GPU fitting for at least one declared supported estimator family while preserving estimator identity/semantics; existing unsupported MLJ fits remain visibly CPU. Never silently swap a model.

Acceptance: [AC-26](docs/acceptance-v0.5.0.md#ac-26) · M4 · [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation).

### JF-ACC-005 — Inference and evaluation acceleration

Provide supported GPU inference, scoring and evaluation with per-phase evidence separate from fitting; preserve final-test locks, metrics and result provenance.

Acceptance: [AC-27](docs/acceptance-v0.5.0.md#ac-27) · M4 · [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation).

### JF-PERF-001 — Measured benefit and resource envelopes

Measure cold compilation, warm execution, host-device transfers, kernels/synchronization and end-to-end CPU/GPU cost plus peak memory. Publish tested shapes/dtypes/sizes/versions/hardware and limits; no universal speedup promise.

Acceptance: [AC-28](docs/acceptance-v0.5.0.md#ac-28) · M4/M7 · [AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code), [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation), [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

### JF-PKG-001 — First-release platforms and offline install

Ship Windows EXE plus Linux/Docker with local service/data/metadata startup, offline assets and diagnostics; native Windows GPU adapters and CPU operation are required. Probe hardware then ask preferences. macOS packaging is deferred.

Acceptance: [AC-29](docs/acceptance-v0.5.0.md#ac-29) · M7 · [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

### JF-PKG-002 — Opt-in local compiler worker

Windows offers an explicitly enabled local Linux/Docker compiler worker, authenticated and confined to approved data roots. Explain WSL2/GPU/runtime prerequisites; no silent container provisioning, uploads or remote compute.

Acceptance: [AC-30](docs/acceptance-v0.5.0.md#ac-30) · M7 · [AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows).

### JF-COMP-001 — Honest deferred compatibility

NVIDIA is the first release target. Detect other vendors but keep CPU operation until separately verified. Any later multi-GPU claim requires real work on each device, isolation and scheduling evidence.

Acceptance: [AC-31](docs/acceptance-v0.5.0.md#ac-31) · Deferred · [AKS-67](https://linear.app/gravelaw/issue/AKS-67/deferred-verify-additional-gpu-vendors-and-multi-device-compatibility).

### JF-REL-001 — Composite release acceptance

Same-candidate Windows and hosted Debian full verify:release, selected hardware/compiler/packaging gates, required review/merge, criterion evidence and synchronized traceability/Linear are all required.

Acceptance: [AC-32](docs/acceptance-v0.5.0.md#ac-32) · M1/M7 · [AKS-38](https://linear.app/gravelaw/issue/AKS-38/design-review-gate-for-p0-architecture-artifacts), [AKS-50](https://linear.app/gravelaw/issue/AKS-50/persona-flow-browser-and-release-verification-for-datascienceproject), [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release).

## Runtime and interface boundaries

Future inventory/capability/planning/phase-evidence interfaces are **contract-first**: TypeScript/OpenAPI/schema and version policy, Julia mappings/validation, repository compatibility, consumers/fixtures, then producers and approved frontend displays. This task changes no production schemas, dependencies or code. Missing/empty historical evidence stays unavailable and must not be backfilled from current hardware or policy.

Preserve `apps`, `packages`, `services`, `extensions`, `infra`, `scripts` and `tests` boundaries. A shared runtime module is proposed under services; the gateway retains composition, routing, authorization, audit and error mapping. Preserve NASA/JPL Power of 10 for core logic, bounded queues, Arrow IPC and TOML. CPU parsing/I/O/control work is reported separately from numerical acceleration.

CUDA.jl and KernelAbstractions form the native foundation. Reactant is the initial compiler candidate; upstream documents NVIDIA acceleration on Linux and supported numerical raising. Windows combines native GPU paths with an explicitly enabled local Linux/Docker compiler worker. Docker Desktop's Windows GPU path requires WSL2. These are source constraints, not JuliaFlow certification. [Reactant configuration](https://enzymead.github.io/Reactant.jl/stable/introduction/configuration), [raising](https://enzymead.github.io/Reactant.jl/stable/tutorials/raising), [CUDA workflow](https://cuda.juliagpu.org/stable/usage/workflow/), [Docker GPU prerequisites](https://docs.docker.com/desktop/features/gpu/).

A compiler example must preserve the function/algorithm's meaning and perform useful numerical work. Initial validation target: batched covariance/correlation through Statistics-style CPU routines; AKS-60 must fix the actual compatible function/package/version. If incompatible, document the reason and choose an explicit meaningful alternative. An affine kernel, unexecuted research or renamed native implementation cannot close this milestone.

## Local storage, trust and compatibility

Keep managed `raw/`, `processed/`, `features/`, `models/`, `runs/`, `checkpoints/`, `dashboards/`, `logs/` and `extensions/` zones. Arrow/Parquet analytical artifacts and local DuckDB querying remain architectural direction; file/lightweight metadata serves single-user use and PostgreSQL serves lab/team concurrency. Current dataset connectors remain confined local-file/managed-local: watched-folder, USB, SQLite/DuckDB/PostgreSQL/MySQL dataset sources and cloud execution remain disabled with reasons until connector-specific authority, confinement, provenance and negative tests pass.

Preserve local credentials, audit/redaction, identifier checks, checksums, offline Hub trust, data residency and owner-controlled backup/restore. Optional MinIO, Kubernetes/ArgoCD, provider stores, external registries, cloud IAM/enterprise SSO and remote deployment do not replace local acceptance.

## Success measures and release decision

Retain targets of first sample workflow within 30 minutes after installation media is available and sampled previews under 2 seconds **on a published reference resource envelope**. Record machine, data size, cold/warm state and measurement method. These are acceptance targets, not measured results or delivery dates. Persona studies record completion, wrong turns, recovery, time and correct interpretation of evidence.

Release requires analysis-only and modeling journeys, acceleration across all six stage categories, meaningful compiler integration, real hardware/fallback/resource evidence, offline Windows EXE/Linux-Docker packaging and complete same-candidate Windows/Debian verification. Review, merge, acceptance and Linear/control reconciliation remain separate gates. No skipped required hardware test counts as success.

The [roadmap](docs/product-roadmap.md) governs M1–M7. M5 design runs in parallel with backend work; explicit final approval gates M6 frontend implementation. No deadline, merge, release or frontend approval is invented by this revision.
