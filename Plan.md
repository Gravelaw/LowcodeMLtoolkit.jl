# JuliaFlow Current Development Plan

Last updated: 2026-05-28

## Current Phase

JuliaFlow is past local-platform P0, P1, and P2 thin-slice closure. The active development phase is **Provider-Specific GA Proof + Future Module Expansion**.

P0/P1/P2 evidence is tracked in `docs/brd-traceability.md`. Remaining work is not another local scaffold pass; it is provider/live-cluster proof, frontend/runtime module depth, and final hardware-gated GPU closure.

## Current Baseline

- P0 local-platform scope is closed for base nodes, Arrow/DataFrames materialization, BI, auth/RBAC, streaming, and GPU MVP.
- P1 is closed for Hub hardening, component/control-flow contracts, and observability/perf gates.
- P2 is closed for Kustomize-backed ArgoCD workload manifests and provider-neutral dependency seams.
- Repo-local skill surfaces now exist for control-loop, Julia, frontend, and provider-deployment work.
- First frontend module expansion slice is complete: published BI viewer row search filters visible chart rows and filtered CSV export without changing contracts.
- Frontend module expansion follow-up is complete: Monitor now expands executor dataflow stage-policy evidence and per-node executor/branch result details for operator review.
- Julia runtime module expansion now has loop runtime-plan, try/catch runtime-plan, try/catch failure-recovery routing, catch-branch worker execution, DAG branch rescheduling, executor stage-schedule evidence, metadata-only multi-tick executor scheduling, executor node result/error binding, base-extension dataflow binding, authored-node alias coverage, and callback dataflow scheduling-policy evidence slices: covered failed nodes queue catch work, worker-service schedules catch branch DAG stages, execution records carry bounded topological executor schedules, staged executor ticks persist node output/error telemetry, base extension source/transform/sink/aggregate nodes can propagate Arrow IPC payloads through executor callbacks from UI/contract-style base node types, and executor schedule/state payloads expose bounded callback-dataflow policy evidence.
- Governed Hub production-depth proof now records verification evidence, blocks unsafe sandbox/hash/mirror install paths, executes an env-gated allowlisted sandbox fixture, verifies downloaded artifact hashes from a local artifact-store registry, and resolves private/offline mirror refs through a local registry.
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
   - Monitor dataflow policy/result detail slice is complete as of 2026-05-28.
   - Continue canvas/BI/Hub/settings improvements with `juliaflow-frontend-development` plus React/design/visual-test skills when frontend depth is selected again.
   - Preserve route shell, demo fallback, runtime `juliaflow-config.js`, accessibility selectors, and coverage gates.

4. **Julia runtime module expansion**
   - Loop runtime-plan slice is complete as of 2026-05-15.
   - Try/catch runtime-plan slice is complete as of 2026-05-16.
   - Try/catch failure-recovery route slice is complete as of 2026-05-16.
   - Catch-node compute / worker branch-state slice is complete as of 2026-05-17.
   - General DAG branch rescheduling for catch branches is complete as of 2026-05-17.
   - Executor stage-schedule evidence for general workflow DAGs is complete as of 2026-05-17.
   - Metadata-only multi-tick executor scheduling is complete as of 2026-05-17.
   - Executor node result/error binding is complete as of 2026-05-17.
   - Base-extension dataflow callback binding is complete as of 2026-05-18.
   - Executor dataflow authored-alias coverage is complete as of 2026-05-18.
   - Executor dataflow scheduling-policy evidence is complete as of 2026-05-19.
   - Next Julia runtime follow-up: pause unless a narrower production-runtime gap is identified; otherwise return to provider proof or frontend module depth.
   - Use `juliaflow-julia-development`, `julia-coding`, and `julia-debugging`; verify with Julia tests and contract tests.

5. **Governed Hub production depth**
   - Deterministic sandbox/hash/mirror verification slice is complete as of 2026-05-16.
   - Isolated fixture execution / downloaded artifact hash / private-offline mirror registry proof slice is complete as of 2026-05-17.
   - Next Hub follow-up: bind the same sandbox/artifact/mirror proof to a selected external registry or provider mirror when credentials and provider context exist.

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

## Latest Completed Slice — 2026-05-16 Runtime Failure Recovery

**Julia runtime module expansion / try-catch failure-recovery route slice** is complete. Execution status updates that report `failedNodeId` for a node covered by existing try/catch metadata now record `controlFlowRecovery` catch-route evidence and keep the execution non-terminal; failed-node telemetry outside try/catch still transitions normally to failed. The evidence is exposed through contracts, OpenAPI, gateway payloads, Monitor UI, and tests.

Verification evidence for this slice: Julia/frontend/contract tests, build, coverage, control-doc sync, BRD traceability, and diff checks are required before commit.


## Latest Completed Slice — 2026-05-17 Runtime Catch Branch

**Julia runtime module expansion / catch-node branch-state slice** is complete. Recovered try/catch executions now queue bounded catch-branch work, worker-service processes the branch, records `controlFlowBranchState` with worker id, completed catch nodes, and deterministic BI outlet row-count node results, then completes the execution without weakening terminal failure guards. The evidence is exposed through contracts, OpenAPI, gateway payloads, Monitor UI, and tests.

Verification evidence for this slice: Julia/frontend/contract tests, build, coverage, control-doc sync, BRD traceability, and diff checks are required before completion.


## Latest Completed Slice — 2026-05-17 Runtime DAG Branch Rescheduling

**Julia runtime module expansion / DAG branch rescheduling slice** is complete. Recovered try/catch executions now derive deterministic catch-branch DAG stages from workflow connections, execute independent catch nodes before dependent BI outlet nodes, persist `branchStages` / `stageResults`, and surface branch-stage progress in Monitor without changing broader executor semantics.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-16 Hub

**Governed Hub production depth / deterministic sandbox-hash-mirror proof slice** is complete. Hub extension records now carry `verification` evidence; install/enable/upgrade evaluate bounded sandbox command shape, deterministic artifact hash proof, and `mirror://` / `private://` mirror refs; unsafe commands, hash mismatches, and unsupported mirrors are blocked while disable remains a safe remediation action.

Verification evidence for this slice: Julia/frontend/contract tests, build, coverage, control-doc sync, BRD traceability, and diff checks are required before commit.


## Latest Completed Slice — 2026-05-17 Runtime Executor Schedule

**Julia runtime module expansion / executor stage-schedule slice** is complete. Execution records now derive a bounded topological `executorSchedule` for general workflow DAGs with stage indexes, node IDs, lanes, worker pools, readiness barriers, max concurrency, and scheduler policy. Gateway payloads, TS/OpenAPI contracts, Monitor UI, and tests expose the evidence without implementing asynchronous multi-tick execution.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.


## Latest Completed Slice — 2026-05-17 Runtime Multi-Tick Executor

**Julia runtime module expansion / metadata-only multi-tick executor slice** is complete. Worker-service now advances CPU batch executions over existing `executorSchedule` one bounded stage per tick: accepted to queued, queued to running, running stage progress through append-only events, and final stage to completed. Gateway payloads, TS/OpenAPI contracts, Monitor UI, and tests expose `executorState` without executing real node compute.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.


## Latest Completed Slice — 2026-05-17 Runtime Executor Node Results

**Julia runtime module expansion / executor node result-error binding slice** is complete. Worker-service executor ticks now accept bounded workflow/node execution callbacks, persist per-stage and flattened node output telemetry under `executorState`, and fail fast with failed-node/error metadata when a staged node errors. Gateway payloads, TS/OpenAPI contracts, Monitor UI, and tests expose node-result and error details while keeping full base-extension dataflow execution as a future slice.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.


## Latest Completed Slice — 2026-05-18 Runtime Executor Dataflow

**Julia runtime module expansion / base-extension dataflow binding slice** is complete. The base extension now exposes an `ExecutorDataflowState` plus `execute_executor_dataflow_node!` callback helper that resolves registered base nodes, builds `NodeContext` inputs from upstream executor outputs, executes real source/transform/sink nodes, stores downstream Arrow IPC payloads, and returns executor node-result telemetry with row counts/output refs/persisted refs. Worker-service staged executor ticks can use this callback seam without changing stream/GPU ownership.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.



## Latest Completed Slice — 2026-05-19 Runtime Executor Dataflow Policy

**Julia runtime module expansion / executor dataflow scheduling-policy evidence slice** is complete. Executor schedule stages and staged executor state now expose a bounded `dataflowPolicy` / `dataflow_policy` evidence object for callback-bound dataflow, including policy name, callback/dataflow enabled flags, readiness barrier, eligible/source/sink node IDs, lanes, worker pools, max concurrency, and bounded status. Gateway payload mapping, TypeScript contracts, OpenAPI, Monitor UI, Julia tests, and frontend tests were updated without changing stream/GPU ownership.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`, `npm --workspace @juliaflow/frontend run test -- App.test.tsx`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-28 Frontend Monitor Detail

**Frontend module expansion follow-up / Monitor executor dataflow detail slice** is complete. The Monitor execution rail now expands executor schedule dataflow policies by stage and renders per-node executor and catch-branch result details, including node IDs, output kind, row counts, output-ref counts, callback/dataflow flags, and readiness barrier evidence. Repo garbage sanity also removed tracked `.staging/` skill residue and ignored future staging folders; dependency hygiene resolved the moderate `ws` audit advisory through `npm audit fix`.

Verification evidence for this slice: `npm --workspace @juliaflow/frontend run test -- App.test.tsx`, `npm audit --audit-level=moderate`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-18 Runtime Executor Dataflow Aliases

**Julia runtime module expansion / executor dataflow authored-alias coverage slice** is complete. The base extension executor helper now resolves approved UI/contract-style base node types such as `JuliaFlow.Base.CSVReader`, `JuliaFlow.Base.ColumnSelect`, `JuliaFlow.Base.AggregateRows`, and `JuliaFlow.Base.ArrowSink` to canonical registry keys, normalizes port/config defaults from authored workflow ports, and preserves Arrow IPC payload flow through staged executor callbacks. Runtime tests now prove an alias-authored source -> select -> aggregate -> sink chain completes through worker-service executor ticks.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `julia --project=. extensions/base/test/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

## Latest Completed Slice — 2026-05-17 Hub

**Governed Hub production depth / isolated sandbox-artifact-mirror proof slice** is complete. Hub install/enable/upgrade now optionally executes only allowlisted Julia extension test fixtures when `JULIAFLOW_HUB_SANDBOX_EXECUTE=1`, verifies declared artifact hashes against a local JSON artifact-store registry, rejects missing artifact entries, resolves `mirror://` / `private://` refs through a local mirror registry, and surfaces sandbox/artifact/mirror verification details in the Hub UI.

Verification evidence for this slice: `julia --project=. tests/julia/runtests.jl`, `npm run test`, `npm run build`, `npm run validate:coverage`, `npm run validate:control-doc-sync`, `npm run validate:brd-traceability`, and `git diff --check`.

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
