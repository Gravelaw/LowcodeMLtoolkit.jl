# AKS-69 local integration candidate — 2026-10-11

## Baseline and local integration

The preserved tested snapshot is `5de9f799bfe34eda0b22ffdea5f3afef6431ff6f`
(tree `6194ac188f34846728d9efc81a1f71c50f9e96f5`) on
`codex/aks-44-durable-analyse-data`. Its recorded 22-phase local release pass
belongs to that exact snapshot; it is not automatically evidence for this candidate.
The new branch is `codex/aks-69-consolidated-candidate`. Local integration is
user-authorized; publication, GitHub merge, PR closure, deletion, workflow/settings
changes, hosted CI, tags, releases and deployment remain on hold.

Fresh read-only GitHub checks on 2026-10-11 confirmed:

| Ref | Exact head | State |
| --- | --- | --- |
| main | `7e725eb0e2fe74a4d4d1bec885c31ab546fb6320` | Current remote baseline |
| PR59 | `099bb56f6da8865796f1ab0b2ba8fe5e73d08afa` | Open, based on main |
| PR19 | `25d224ee9efa9e4e58ea0c09b117a1360166b177` | Closed, unmerged |

Main contributes only `mockdesigns/juliaflow`, containing a blank line; it is
retained by an ordinary local merge. PR59 is recorded by a local `ours` merge only
after the patch/content reconciliation below: its useful changes are already
present, so reapplying older files would regress the tested implementation.
The PR59 ancestry merge has the exact tested tree. After the main merge, the only
content difference from that tree is the blank main file, before these documents.
This is local history integration, not a GitHub merge or rewritten history.

## PR59: all five unique commits accounted for

| PR59 commit | Retained replay | Disposition |
| --- | --- | --- |
| `846ae73f1559432361ddacfafe8139691905c6cb` | `42172af66cf730d09de4293ce6f5b3f6160edf1e` | Production/workflow/package/test files byte-identical between these commits; older historical document context not restored |
| `a9ca43d42ca4dae1da465dbbc988666aaa730b34` | `b5cab43` | Patch-equivalent archive round-trip and explicit release gates retained |
| `9520979a647f114fba3c5d3a019a19fe7717b347` | `a88fedd` | Patch-equivalent WSL GC/precompile bounds retained |
| `584ec6b36bf7966dec2da62af028ead47aa5537c` | `26eb267` | Patch-equivalent rejected WebSocket connection-close repair retained |
| `099bb56f6da8865796f1ab0b2ba8fe5e73d08afa` | `3068d79` | Patch-equivalent job-owned WSL swap lifecycle retained |

`git cherry 5de9f799 PR59` marks the last four as equivalent. The first commit's
CI/package/test diff against `42172af` is empty; it differs in patch identity due
to its replay context. Every changed PR59 path relative to common base
`11856e4d85f6c8ee96446687b4b21057733d9750` is accounted for below. No unique
production change is discarded. An external pre-merge inventory records the
PR59 and retained SHA-256 for all 19 paths.

| Path | Disposition against tested 5de9f799 |
| --- | --- |
| `.github/workflows/ci.yml` | Byte-identical; retain local execution policy |
| `.github/workflows/release-candidate.yml` | Byte-identical; retain explicit release gating |
| `Plan.md` | Retain newer plan and historical AKS-69 entry |
| `docs/TODO.md` | Retain newer backlog and historical AKS-69 entry |
| `docs/checkpoint-log.md` | Retain newer checkpoints and historical AKS-69 entry |
| `docs/local-ci.md` | Byte-identical |
| `docs/project-tracker.md` | Retain newer bounded status and historical AKS-69 entry |
| `docs/risk-register.md` | Retain newer open risks and historical AKS-69 entry |
| `package.json` | Retain added Create Project/Analyse Data smoke scripts and pinned Playwright 1.64.0 |
| `scripts/ci/delivery.mjs` | Retain newer mandatory 22 phases, including Create Project and durable analysis |
| `scripts/ci/execution-policy.json` | Byte-identical |
| `scripts/ci/hosted-policy.mjs` | Byte-identical |
| `scripts/ci/job.mjs` | Byte-identical |
| `scripts/ci/workflows.json` | Byte-identical |
| `scripts/ci/wsl-job.sh` | Byte-identical; swap lifecycle retained |
| `scripts/ci/wsl-julia.sh` | Byte-identical; GC/precompile bounds retained |
| `services/api-gateway/src/JuliaFlowApiGateway.jl` | Retain close header plus newer reviewed authorization, real-file, project and analysis behavior |
| `tests/browser/live-backend.spec.ts` | Retain rejection assertion plus explicit persisted target/dataset, selected-dashboard and real evaluation assertions |
| `tests/ci/delivery.test.mjs` | Byte-identical |

## PR19: deliberate exclusion with recovery retained

PR19 was closed as stale before AKS-24, with an explicit instruction to re-review
useful Settings/browser-control ideas on the newer branch rather than merge it
as-is. Its five unique commits are `66b46c2`, `c7d2fa2`, `a6588b9`, `3340fd5`,
and `25d224e`. The branch and exact audit reference are retained; no deletion or
automatic revival is authorized. All 27 changed paths are classified here:

| Paths | Disposition |
| --- | --- |
| `.github/workflows/ci.yml` | Exclude obsolete hosted fixture gate and Node-version policy changes; current approved policy retained |
| `Improvement Plan.md`, `Plan.md`, `docs/TODO.md`, `docs/brd-traceability.md`, `docs/checkpoint-log.md`, `docs/project-tracker.md`, `docs/risk-register.md` | Exclude obsolete planning/status context; retained history permits recovery |
| `apps/frontend/src/App.test.tsx`, `apps/frontend/src/App.tsx`, `apps/frontend/src/components/Shell.tsx`, `apps/frontend/src/components/ui.tsx`, `apps/frontend/src/styles.css` | Exclude obsolete shell/UI changes against evolved nine-section Explorer, design and accessibility implementation |
| `apps/frontend/src/views/DataView.tsx`, `DeployView.tsx`, `MlStudioView.tsx`, `ModelsView.tsx`, `TransformView.tsx`, `VisualizeView.tsx` in that same views directory | Exclude old route controls; real current workflows and regression gates retained |
| `apps/frontend/src/views/SettingsView.tsx` | Exclude local-feedback-only saved/path-picker/writability claims; current compute settings call persisted backend controls. Actual path-picker/writability controls remain a future deliberate scope decision |
| `package.json`, `playwright.config.ts`, `playwright.local.config.ts`, `scripts/run-browser-local-smoke.mjs`, `tests/browser/local-live.spec.ts`, `tests/browser/local-ui.spec.ts` | Exclude obsolete launch/config/fixture journeys; retain current generic and real live-backend browsers |
| `tests/browser/iris-linear-cycle.spec.ts` | Exclude fabricated checksums, artifacts and regression metrics labeled AUC/F1; useful real regression user journey belongs to future model acceptance, with correct target/split and real numerical evidence |

This does not assert every old UI idea is implemented. In particular, real path
controls and a correctly measured end-to-end regression journey remain follow-ups,
not acceptance proven by the discarded fixtures. No new feature scope is invented
or issue marked Done. Parent record maintenance owns Linear synchronization.

## Verification and remaining acceptance

Freeze the local candidate commit/tree before review and testing. Require separate
correctness, UI and independent local security reviews against the exact delta,
including reconciliation evidence and exclusions. Security review follows
`docs/agent-tooling.md`; it is not canonical Codex Security clearance. Check
`test:local-ci`, `validate:control-doc-sync -- --base main`, BRD traceability and
whitespace, then the complete clean-candidate `verify:release` with no phase skip
flags. Save results externally against the exact SHA, so adding test conclusions
does not silently change the reviewed candidate. At document creation these
candidate-specific checks and reviews are pending; prior passes are historical.

The Julia engineering catalog passed the external-trust verifier with status ok,
signed true, catalog 2.1.0 and unchanged pinned digests. Routed skills:
`julia-manage-project-workflow`, `julia-write-maintain-code`. Historical signer
identity/install provenance is accepted risk, not independently verified.

Preserve full BRD local v1, stock-package GPU capabilities, all nine navigation
sections, Explorer layout, Wada83 light/dark palette and immutable analysis evidence
separate from editable findings. There are no product, dependency, algorithm,
contract or workflow changes in this integration delta. Physical NVIDIA/Windows
qualification, original-board comparison, real Data Analyst/Data Scientist and
assistive-technology acceptance, and wider platform qualification remain open.
A cloud no-GPU rejection does not validate a physical GPU. Hosted policy success
with quality jobs skipped is not product validation. Administrative protection
requirements remain uncertain after the recorded 403 lookup.

## Staged publication and retirement plan — not executed

1. Finish exact-candidate local reviews and full verification; retain failures and
   every unrun/skipped condition. Resolve findings before proceeding.
2. After explicit publication authorization, refresh remote heads, review branch
   workflow triggers and publish only the verified development candidate. Under
   the inspected workflow a non-main branch without a PR does not trigger those
   checked-in push workflows; this is not a zero-account-cost guarantee.
3. If explicitly authorized, open a reviewable PR against freshly integrated main,
   attach exact local evidence and reconcile required GitHub reviews/checks and
   administrative requirements. A draft PR still triggers the policy job; local
   mode skips hosted quality jobs and does not waive applicable requirements.
4. Merge on GitHub only with separate explicit authorization, resolved blockers,
   applicable approvals/checks and fresh exact-head evidence. Main push can trigger
   CI. No tag, release, deployment or settings action is implied.
5. Only after verified integration and explicit retirement approval, enumerate each
   superseded PR/branch with exact ancestry/content proof and recovery refs; close
   or delete individually. Preserve ignored evidence/environments and active
   worktrees. PR19 stays a retained historical exclusion unless separately chosen
   for retirement. Do not treat this local merge as completed remote cleanup.
