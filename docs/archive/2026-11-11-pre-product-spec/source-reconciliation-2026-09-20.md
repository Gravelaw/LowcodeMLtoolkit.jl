# JuliaFlow v0.5.0 source reconciliation

Date: 2026-09-20. Owner: Akshay. Coordination: [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination). Initial reconciliation was completed by 16:48 UTC; final issue/project and PR #55 readback was checked at 16:58 UTC, with dependency-text readback at 16:59 UTC. These are dated observations, not a live monitor.

## Authority and preserved baseline

Linear LowCodeML owns criteria, dependencies, ownership and status; GitHub owns revisions/reviews/checks/merges; current control documents own requirements and traceability; code/tests own implemented behavior. Source tasks and Penpot are supporting context. Approval of this documentation revision does not approve frontend implementation or a release.

This isolated worktree began clean at `c363e0086552334fc2268222550ea031c548b4f9`, approved PR #55 baseline, and uses `codex/aks-57-brd-v050-roadmap`. No newer product code was integrated. The original checkout, inherited files, other worktrees, signed runtime and user artifacts are preserved. Shared Git metadata was used only to create the authorized worktree branch.

The canonical BRD's internal v0.4.1 Git blob is preserved in [the new dated snapshot](archive/2026-09-20-brd-v0.4.1/README.md), SHA-256 `cbaa6f90255cca7383fd8f8dfee8a97211562a01caf5e31499e60398091b396b`, 27,775 bytes. Existing [archive manifest](archive/2026-09-20/manifest.json) and all 46 historical TODO/traceability mappings are retained.

## Source tasks and artifacts reviewed

| Source | What was read | Authority / limits |
| --- | --- | --- |
| [JuliaFlow frontend redesign — Figma…](codex://threads/01a0be93-36a9-7df3-b4d0-61b166f9876d) | Compact user/final messages, Revision 2 research and backend refinement notes | User requires one workspace in both themes, independent guidance/density. Six task-screen pairs plus state boards exist in the reported design revision; Models/Deploy/Monitor/Settings, responsive completeness, user testing and final approval remain open. No fresh live-board QA performed here. |
| [Prepare JuliaFlow development restart](codex://threads/01a0be5f-1eeb-7c62-85ac-30df9acef60e) | User/final messages and baseline [remediation](blocker-remediation-2026-09-20.md), [restart review](restart-review-2026-09-20.md), [threat model](restart-threat-model-2026-09-20.md) | Backend remediation authorization and original local results; does not authorize frontend work. Draft stack and checks refreshed below. |
| [Analyze Julia GPU runtime support](codex://threads/01a0bee9-7470-7961-9a95-3a80d8cb947a) | User/final messages and original `gpu-runtime-assessment-2026-09-20.md`, preserved at its source | Assessment inspected older `efe6d32b73d0beb1d0e7179cc9a7c7e6a32802df`; native Windows diagnostic results are historical and limited. Its optional-Reactant proposal is superseded by the approved mandatory compiler milestone. |
| [Penpot Revision 2](https://design.penpot.app/#/workspace?team-id=ceed1600-61c0-8087-8007-e64ef71f5ffb&file-id=d8ac01df-6646-81d2-8008-aafe1c7924ba&page-id=a3ebef02-2fe2-80f8-8008-aafdca5313c5) | Source-task report plus local research/constraint text and review-package hash | Editable design source, illustrative data/plots. No board edits or final approval. Future design continuation now tracked by AKS-64. |

Source artifact custody (retrievable through the linked source tasks; hashes checked here, original files unmodified):

| Artifact basename / source task | SHA-256 |
| --- | --- |
| `gpu-runtime-assessment-2026-09-20.md` / GPU task | `8f96a6b1e44b90b16d3cd061d45e1488e77c8b0fd1d7e4a324abfd09be6120b5` |
| `rework-v2/research-and-rework.md` / design task | `8303f7dbc3d394e53d0c52625a0aadcc1ebca650931567ddbd9e24d66193da36` |
| `rework-v2/backend-constraints-next-refinement.md` / design task | `00632a9b0704fe7fe7199c2685d454c05d6dd3c528b9404741eb98cb571da1bd` |
| `rework-v2/JuliaFlow-rework-v2-review.zip` / design task | `d6bcf8e380ae17570a27dfa79f217c955526f221c743ed956494147d13b4dc6f` |

Portable repository paths and source-task URLs replace machine-specific artifact locations. The zip was hashed, not re-certified or edited.

## Live GitHub readback

Authenticated `gh pr view <number> --json number,state,isDraft,headRefOid,baseRefName,url,reviews,statusCheckRollup` read every row. All are **OPEN, draft**, all have **zero submitted reviews**, and both **web and julia completed SUCCESS** on their listed heads. Debian outcomes differ:

| PR | Exact head | Base branch | Debian | Run |
| --- | --- | --- | --- | --- |
| [#40](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/40) | `a70ea67eda343655f70fe336c294f8ec9e638889` | `main` | failure | [31877877976](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/31877877976) |
| [#47](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/47) | `ebeebfeb26357414e8243d216885cfb577001730` | `codex/aks-36-datascienceproject-substrate` | cancelled | [35501646027](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35501646027) |
| [#48](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/48) | `f9e10f3a3e5fd3c48e601e9252047de49c8bf2df` | `codex/aks-51-repository-cleanup` | cancelled | [35505962100](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35505962100) |
| [#49](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/49) | `87aa8166f5ac13c3d78e9a6a330d31268088c69b` | `codex/aks-52-dependency-remediation` | cancelled | [35506623055](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35506623055) |
| [#50](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/50) | `ea765a754e7981f19a594739fc5647991c25b937` | `codex/aks-38-restart-review` | cancelled | [35509777116](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35509777116) |
| [#51](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/51) | `268561dee69bf18e4bce2c1a1eae51d7279f3cbd` | `codex/aks-55-local-browser-authority` | cancelled | [35510495164](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35510495164) |
| [#52](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/52) | `3308a87c2813ff942a368939c79b045e3fb875c0` | `codex/aks-41-managed-path-confinement` | failure | [35514099917](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35514099917) |
| [#53](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/53) | `142f3eb8b9e6ef720bb1efce26e591ba7df3b440` | `codex/aks-56-project-payload-contracts` | failure | [35515125167](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35515125167) |
| [#54](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/54) | `7e89658b09e75b4847fb6b2b8aeb3f5aa5182c3a` | `codex/aks-53-reject-synthetic-evidence` | failure | [35518199704](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35518199704) |
| [#55](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/55) | `c363e0086552334fc2268222550ea031c548b4f9` | `codex/aks-54-persisted-split-membership` | failure | [35518798354](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35518798354) |

PR #55 has Debian job [106099171919](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/35518798354/job/106099171919), failed at **Run npm run verify:release**; `gh run view 35518798354 --json headSha,conclusion,url,jobs` confirmed the same SHA and step. Latest root cause remains **undiagnosed** in this documentation task. Earlier missing-browser/bootstrap/migration failures are historical explanations, not a diagnosis of this run. No CI reruns, reviews, publication, merges or releases occurred here.

No delivered/merged v0.5.0 capability is certified. Historic Done issues and prior Windows success require their original evidence and fresh selected-candidate verification; none substitutes for this stack's open platform/review gates.

## Live Linear reconciliation

Project: [LowCodeML](https://linear.app/gravelaw/project/lowcodeml-76b77ebe606f), ID `a0a0fa31-7c18-4cbb-a196-8fe82ff257e2`. Owner of new work: Akshay. Current issues were read with criteria and relations before updates.

| Observed state | Existing issues |
| --- | --- |
| In Progress | AKS-36, AKS-40, AKS-42–50 |
| In Review | AKS-37, AKS-38, AKS-39, AKS-41, AKS-51–56 |

Existing priority, owner and status are preserved. New requirements are mapped onto existing acceptance where appropriate; no duplicate M1 repair or duplicate M6 implementation issue is created. New scope:

| Issue | Milestone / ownership | State / priority |
| --- | --- | --- |
| [AKS-57](https://linear.app/gravelaw/issue/AKS-57/0-juliaflow-brd-v050-and-first-release-roadmap-coordination) | Documentation and roadmap coordination, Akshay | In Progress / High; local review artifact, no PR publication requested |
| [AKS-58](https://linear.app/gravelaw/issue/AKS-58/m2-discover-real-hardware-and-bind-actual-gpu-execution) | Discover real hardware and bind actual GPU execution, Akshay | Todo / High |
| [AKS-59](https://linear.app/gravelaw/issue/AKS-59/m3-shared-capability-planner-memory-safety-and-execution-contracts) | Shared capability planner, memory safety and execution contracts, Akshay | Todo / High |
| [AKS-60](https://linear.app/gravelaw/issue/AKS-60/m3-m4-integrate-reactant-for-meaningful-cpu-numerical-code) | Integrate Reactant for meaningful CPU numerical code acceleration, Akshay | Todo / High |
| [AKS-61](https://linear.app/gravelaw/issue/AKS-61/m3-replace-bounded-csv-execution-with-verified-scalable-ingestion) | Replace bounded CSV execution with verified scalable ingestion, Akshay | Todo / High |
| [AKS-62](https://linear.app/gravelaw/issue/AKS-62/m4-accelerate-preparation-eda-and-chart-data-computation) | Accelerate preparation, EDA and chart-data computation, Akshay | Todo / High |
| [AKS-63](https://linear.app/gravelaw/issue/AKS-63/m4-verify-supported-gpu-fitting-inference-and-evaluation) | Verify supported GPU fitting, inference and evaluation, Akshay | Todo / High |
| [AKS-64](https://linear.app/gravelaw/issue/AKS-64/m5-complete-nine-route-design-and-obtain-explicit-final-approval) | Complete nine-route design and obtain explicit final approval, Akshay | Todo / High |
| [AKS-65](https://linear.app/gravelaw/issue/AKS-65/m7-opt-in-confined-local-linux-compiler-worker-on-windows) | Opt-in confined local Linux compiler worker on Windows, Akshay | Todo / High |
| [AKS-66](https://linear.app/gravelaw/issue/AKS-66/m7-certify-windows-exe-and-linux-docker-offline-release) | Certify Windows EXE and Linux Docker offline release, Akshay | Todo / High |
| [AKS-67](https://linear.app/gravelaw/issue/AKS-67/deferred-verify-additional-gpu-vendors-and-multi-device-compatibility) | Verify additional GPU vendors and multi-device compatibility, Akshay | Todo / Medium |

New issue descriptions contain requirement IDs, scope, dependencies, success/rejection scenarios, verification commands, evidence limits and rollback. Dependency relations use returned UUIDs with issue readback. AKS-58 requires bounded M1 backend clearance; AKS-38 remains related because its full persona/release review continues later, avoiding an implied requirement to finish frontend before hardware work. AKS-64 has no prerequisite preventing parallel design; final signoff must reconcile actual backend capability.

The project description retains all original context and appends the dated product promise and linked AKS-57 roadmap. New future work remains Todo. Existing issue reconciliation adds requirement/roadmap pointers and the final-design gate without changing owners, priorities or statuses. AKS-47/48/49 now have AKS-64 as the explicit final-design dependency; AKS-64 relates to AKS-58/59/61 for capability and ingestion inputs while design preparation remains parallel. Final list comparison found no status/owner/priority changes to existing AKS-36–56. No comments or messages were sent to other people, and no product issue was marked Done.

## Confirmed runtime and design constraints

| Boundary | Evidence and decision |
| --- | --- |
| CSV | `services/api-gateway/src/JuliaFlowDataScienceProjectSplits.jl` reads at most 1,002 lines, accepts 1–1,000 data rows, rejects quoted input and duplicate/empty headers. AKS-61 replaces this only after row/split/checksum/resource verification; current safeguards stay. |
| Splits and transforms | AKS-54 candidate persists assignments/folds/locks and train-only numeric standardization. Changed source/split needs a new plan. External/k-fold/incomplete plans and unimplemented custom transforms remain unavailable. Design sample 2,000 rows / 1,400 training rows is proposed, not supported runtime scale. |
| Hydration | Source task reproduced default-project mutation 404 before real project resolution. Waiting in a test is not a frontend fix. AKS-49 remains open; M5/M6 require initial/switch loading gates and retry/reselection. |
| GPU worker | `JuliaFlowWorkerService.jl` at c363e008 still defaults registry to `mock:nvidia0`, supports CPU mock workloads and passes only values to its CUDA workload without binding recorded placement. This turn read source; the executed mock/invented-device probe belongs to efe6d32. AKS-58 tracks discovery, actual binding, strict policy and safe fallback defects. |
| Historical hardware | Julia 1.12.6 normal KA smoke at efe6d32 passed on one RTX 5080 Laptop GPU: eight inputs, sum 80, device count 1. CUDA 13.4/13.2 warning remained; compiled-modules-disabled diagnostic failed with InvalidIRError. No current training/Reactant/multi-device proof; no hardware probe rerun here. |
| Model semantics | Inspected MLJ fitting is CPU; selected tuning metrics have bounded CUDA reductions. GPU metrics cannot certify GPU fitting. Preserve model identity and explicit CPU reasons. |
| Contracts | AKS-56 candidate preserves historical absent/empty resource evidence as unavailable and validates populated records. New inventory/capability/planning/phase interfaces require TS/OpenAPI/Julia/repository/frontend coordination; no schemas change now. |
| Environment | Approved `Project.toml` declares Julia compat `1.10`, CUDA `5`, KernelAbstractions `0.9`, MLJ `0.23.2` and MLJLinearModels `0.10.2`. These bounds are not certification of every allowed combination. No new dependency resolution/install performed. |

Original local remediation: [report](blocker-remediation-2026-09-20.md) attributes 1,072 API + 37 authority + 261 real-evidence + 122 split assertions (1,492 total) and five browser scenarios to its bounded candidate sequence ending PR #54 `7e89658`. PR #55 adds a separately tested migration fixture. PostgreSQL integration was skipped. All remain historical local evidence, not fresh full-release or v0.5.0 results.

## Refreshed primary technical sources

Read 2026-09-20; upstream support must be rechecked when implementation pins versions.

- [Reactant configuration](https://enzymead.github.io/Reactant.jl/stable/introduction/configuration): NVIDIA compiler path on Linux. Upstream lists additional backend support, which does not establish JuliaFlow vendor compatibility. No native Windows compiler support is assumed.
- [Reactant raising](https://enzymead.github.io/Reactant.jl/stable/tutorials/raising): supported scalar-loop/kernel raising provides a path for numerical regions, not arbitrary package conversion.
- [CUDA workflow](https://cuda.juliagpu.org/stable/usage/workflow/): GPU arrays, unsupported operations and scalar indexing require explicit porting/validation.
- [Docker Desktop Windows GPU](https://docs.docker.com/desktop/features/gpu/): WSL2 and supported NVIDIA GPU prerequisites inform the explicitly enabled local worker requirement.

Choosing Reactant, the initial covariance/correlation example and per-stage adapters is a product/planning decision grounded in these constraints; it is not an upstream guarantee of compatibility or speedup.

## Tool integrity and verification

Installed Julia catalog verified with the packaged integrity command against the external trust policy: version `2.1.0`, manifest digest `996753585e98ac66877932c1569ee2301c9a19cd3e763a3a34860498c837fc6e`, signed status OK. Router `89228c46-991d-4f26-93eb-47669c02f71b` selected `julia-plan-project-work`; signed files remained untouched.

The sandboxed GitHub authentication check failed; authorized read-only elevated `gh` queries succeeded. Branch creation needed access to shared worktree Git metadata and succeeded under the authorized scoped escalation. No automatic approval rejection occurred.

System `npm --version` fails because its launcher resolves a missing roaming npm CLI. Node `v26.3.0` is available. Direct repository validators are used, as authorized; no global repair or package install. Final documentation checks and readback are recorded in [AKS-57 verification](verification-brd-v0.5.0.md). Product, Julia, browser, GPU/compiler, installer and release gates are not run for this documentation-only change.
