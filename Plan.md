# JuliaFlow Current Development Plan

Last updated: 2026-05-16

## Current Phase

JuliaFlow is past local-platform P0, P1, and P2 thin-slice closure. The active development phase is **Provider-Specific GA Proof + Future Module Expansion**.

P0/P1/P2 evidence is tracked in `docs/brd-traceability.md`. Remaining work is not another local scaffold pass; it is provider/live-cluster proof, frontend/runtime module depth, and final hardware-gated GPU closure.

## Current Baseline

- P0 local-platform scope is closed for base nodes, Arrow/DataFrames materialization, BI, auth/RBAC, streaming, and GPU MVP.
- P1 is closed for Hub hardening, component/control-flow contracts, and observability/perf gates.
- P2 is closed for Kustomize-backed ArgoCD workload manifests and provider-neutral dependency seams.
- Repo-local skill surfaces now exist for control-loop, Julia, frontend, and provider-deployment work.
- First frontend module expansion slice is complete: published BI viewer row search filters visible chart rows and filtered CSV export without changing contracts.
- Julia runtime module expansion now has loop and try/catch runtime-plan slices: both produce bounded additive execution evidence without changing node compute execution.
- Final multi-GPU closure remains intentionally deferred until a runner with `>=2` visible CUDA devices exists.

## Active Development Order

1. **Provider-specific deployment proof**
   - Add staging/prod overlays for chosen providers.
   - Bind secret delivery without committing real secrets.
   - Run `kubectl apply --dry-run=server -k ...` against a configured cluster.
   - Repeat auth, PostgreSQL, Kafka/NATS, object-store, gateway health, and metrics smokes.

2. **Provider-specific object-store proof**
   - Prove S3/GCS/Azure-compatible Arrow IPC materialization with real credentials supplied externally.
   - Keep provider-neutral adapter seam and local fallbacks intact.

3. **Frontend module expansion**
   - First BI published-viewer row-search slice is complete as of 2026-05-15.
   - Continue canvas/BI/Hub/monitor/settings improvements with `juliaflow-frontend-development` plus React/design/visual-test skills when frontend depth is selected again.
   - Preserve route shell, demo fallback, runtime `juliaflow-config.js`, accessibility selectors, and coverage gates.

4. **Julia runtime module expansion**
   - Loop runtime-plan slice is complete as of 2026-05-15.
   - Try/catch runtime-plan slice is complete as of 2026-05-16.
   - Next Julia runtime follow-up: deeper worker-runtime or failure-driven node execution behavior.
   - Use `juliaflow-julia-development`, `julia-coding`, and `julia-debugging`; verify with Julia tests and contract tests.

5. **Governed Hub production depth**
   - Execute sandbox commands, verify downloaded artifacts against hashes, and test private/offline registry mirrors.

6. **Final hardware-gated GPU closure**
   - Only when `>=2` visible CUDA devices exist, run `JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1 julia --project=. scripts/smoke-cuda-kernel.jl`.
   - Link hardware-backed worker isolation and multi-GPU scheduling evidence before checking final GPU item.


## Latest Completed Slice — 2026-05-15

**Frontend module expansion / BI viewer row-search slice** is complete. Published dashboard viewers now support a viewer-wide row search applied after chart cross-filters, clear row-search controls, row-search status, and filtered CSV export that respects both the selected chart filter and search term.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- App.test.tsx` passed locally before full gate execution.


## Latest Completed Slice — 2026-05-15 Runtime

**Julia runtime module expansion / loop runtime-plan slice** is complete. Loop control-flow metadata now validates start-to-end reachability, derives bounded body node IDs from the workflow DAG, emits additive `controlFlowPlan` execution evidence through contracts/gateway/frontend, and keeps node compute execution unchanged.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl` and `npm run test` passed before full gate execution.

## Latest Completed Slice — 2026-05-16 Runtime

**Julia runtime module expansion / try-catch runtime-plan slice** is complete. Try/catch metadata now emits additive `controlFlowPlan` execution evidence with try and catch body node IDs through contracts/gateway/frontend, while node-level failure catching remains a deliberate future executor expansion.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl` and `npm run test` passed before full gate execution.

## Required Skills By Lane

- BRD/control docs: `juliaflow-control-loop`
- Julia services/runtime/nodes: `juliaflow-julia-development`, `julia-coding`, `julia-debugging`
- Frontend/UI: `juliaflow-frontend-development`, `build-web-apps:react-best-practices`, `build-web-apps:frontend-testing-debugging`, `design`, `visual-ralph`, `visual-verdict`
- Deployment/provider proof: `juliaflow-provider-deployment`
- Review: `code-review`; use `security-review` for auth/secrets/RBAC/deployment/Hub trust

Use native subagents for independent bounded lanes only: `explore`, `researcher`, `dependency-expert`, `executor`, `test-engineer`, `architect`, `critic`, and `code-reviewer`.

## Verification Matrix

| Lane | Required evidence |
| --- | --- |
| Control docs / TODO / traceability | `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, tracker/checkpoint update |
| Frontend | `npm run test`, `npm run build`, relevant coverage/perf gate |
| Julia runtime/services | `julia --project=. tests/julia/runtests.jl`, targeted extension tests when applicable |
| Deployment | `npm run validate:k8s`, server-side dry-run when cluster exists |
| Provider proof | Live smoke output for selected provider; no real secrets in git |
| GPU final | `JULIAFLOW_CUDA_SMOKE=1 JULIAFLOW_REQUIRE_MULTI_GPU=1` on `>=2` visible CUDA devices |

## Non-Negotiables

- NASA/JPL Power of 10 remains mandatory for core logic.
- `packages/contracts/` remains the cross-layer source of truth.
- Arrow IPC remains the inter-node payload boundary.
- No real secrets in git.
- No fake production StatefulSets for managed provider services.
- Do not mark TODO P0/P1/P2 or final hardware items complete without traceability evidence and verification evidence.
- Control-doc sync automation is mandatory: every completed slice, phase, or review must update `Plan.md`, TODO, risks, tracker, and checkpoint, then pass `npm run validate:control-doc-sync`.
