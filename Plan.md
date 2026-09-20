# JuliaFlow current development plan

Reconciled 2026-09-20 for [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination). Canonical [BRD v0.5.0](business-requirements-v0.3.0.md) · [product roadmap](docs/product-roadmap.md) · [next steps](docs/next-steps.md).

## Scope and current truth

The approved product is a **local hardware-aware data-science workstation**, delivered first as Windows EXE and Linux/Docker. Supported GPU numerical preparation, EDA, chart-data computation, fitting, inference and evaluation, plus meaningful compiler integration, are first-release requirements. NVIDIA is first; CPU-only operation and explicit unsupported/fallback reasons remain required. Windows compiler execution uses an explicitly enabled local authenticated/confined Linux/Docker worker.

This task delivers documents and Linear tracking only from `c363e0086552334fc2268222550ea031c548b4f9`. It changes no product code, schema, dependency or design board. Frontend implementation is frozen until the user explicitly approves the final design.

Live GitHub readback: PR #40 and #47–55 are open drafts, without submitted reviews. Web/Julia pass; Debian #47–51 cancelled and #40/#52–55 failed. PR #55's latest failed `verify:release` step is not diagnosed here. Earlier 1,492 gateway/boundary assertions and five browser scenarios retain their original revision attribution and PostgreSQL skip. They do not certify this release. [Evidence and decisions](docs/source-reconciliation-2026-09-20.md).

Current execution is <=1,000 unquoted CSV rows with unique headers; split plans/membership/folds/locks are immutable and changed sources/splits need new plans. Numeric train-fitted standardization exists; broader transforms/composition remain proposed. Worker source retains mock GPU evidence and missing actual device binding. The older single-device KA smoke does not prove training/compiler/multi-GPU readiness.

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

No dates are invented. AKS-67 is deferred Medium-priority compatibility; new release work AKS-58–66 is High-priority Todo, owned by Akshay. Existing issue priorities/owners/statuses remain; no issue completion follows from this rewrite.

## Next bounded action

Under existing AKS-50, inspect the latest logs and artifacts for [run 35518798354](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35518798354) at `c363e008`, identify the first failing product/runtime boundary, and scope a root-cause repair without weakening assertions/timeouts or rerunning deployments. Refresh head/checks first. The [next-steps plan](docs/next-steps.md) defines the handoff, commands, acceptance and integration/approval boundaries.

In parallel, AKS-64 can refine design only: remaining lifecycle/settings routes, compute preference/coverage, real-file onboarding, <=1,000-row current sample, new-plan split semantics and project-loading guards. The existing 404 hydration race remains unfixed; controls must ultimately wait for real identity on initial load and project switch.

## Invariants and gates

Preserve local trust/auth, confined roots, symlink/junction policy, redaction, identifiers/checksums, offline operation, PostgreSQL metadata, explainability and reproducibility/backup. Keep optional connectors/cloud optional and unsupported execution visibly disabled. Preserve signed Julia tooling, user artifacts, original checkouts/worktrees and immutable evidence.

[Acceptance scenarios](docs/acceptance-v0.5.0.md), [TODO](docs/TODO.md), [risks](docs/risk-register.md) and [traceability](docs/brd-traceability.md) distinguish candidate evidence, requirements, designs and deferred work. M7 requires complete selected capabilities and no skipped required phases; green documentation/web/Julia checks or historical Windows evidence do not replace release proof.

[Historical plan archive](docs/archive/2026-09-20/README.md) and [v0.4.1 BRD snapshot](docs/archive/2026-09-20-brd-v0.4.1/README.md) retain prior statements without promoting them.
