# JuliaFlow restart audit — 2026-11-07

Read-only audit of the local Windows checkout and GitHub
(`Gravelaw/LowcodeMLtoolkit.jl`) before development restarts. Nothing was
merged, pushed, closed or deleted. Work is untracked in Linear.

## 1. Headline

- **Real state of the project lives on a branch nobody has a PR for.**
  `origin/codex/aks-69-consolidated-candidate` (`03f19e1`, 2026-10-14) is 163
  commits ahead of `origin/main` and 0 behind. Every `codex/*` branch (local and
  remote) is an ancestor of it — verified with `git merge-base --is-ancestor`.
- **`main` is frozen at PR #38** plus one accidental web commit (`7e725eb`, adds a
  1-byte `mockdesigns/juliaflow`).
- **24 open PRs**: 16 stacked Codex drafts (#39, #40, #47–#60), all superseded by
  the tip, none reviewed; 8 Dependabot PRs (#41–#46 already satisfied in the tip,
  #61 vite / #62 source-map-js still needed — 16 open Dependabot alerts, 7 high).
- **The local checkout is stale**: current branch `codex/aks-36…` is 3 behind
  origin; local `main` is 1 behind. No local branch has commits missing from
  GitHub. So "syncing" = adopt the tip, not push local.
- **The spec is not ready to restart from** (see §4).

## 2. GitHub cleanup

| Item | Finding | Action |
|---|---|---|
| Tip branch | `aks-69-consolidated-candidate`, no PR, never run in CI | Open one PR tip → `main`, merge (no squash) |
| Hosted CI | Tip sets `scripts/ci/execution-policy.json` `"mode": "local"` → julia/web/debian gates **skipped** on GitHub | Decide: re-enable hosted gates, or attach local `verify:release` evidence |
| Debian release gate | Failed/cancelled on #40, #47–#56 (`npm run verify:release`, 20 min fail / 3 h timeout); #58 failed on billing limit | Root cause unknown; confirm billing |
| Codex PRs #39–#40, #47–#60 | All superseded by tip | Close with link to the merge PR |
| Dependabot #41–#46 | Versions already in tip lockfile | Close |
| Dependabot #61, #62 | Not in tip | Rebase + merge after tip |
| `improvement/browser-live-settings-depth` | 5 commits **not** in tip (browser CI gate, settings appliance controls, Iris regression journey) | Review before deleting |
| Branch protection | None (private repo on free plan → 403) | Accept, or go public/Pro |
| Secret / code scanning | Disabled | Enable secret scanning if available |
| Machine paths in tracked docs | ~50 hits (user-profile `.ssh\known_hosts` ×44, checkout root, …) on old `main` docs; on the tip only `docs/brd-traceability.md` (15) outside `docs/archive/` | Scrubbed in the sync branch (`%USERPROFILE%`); archive left byte-exact |
| Large blobs | 8 `mockdesigns/ChatGPT Image Jun*.png` (1.2–1.4 MB each), `docs/assets/revised-ui-ux-personas.zip` | Move/rename; LFS optional |
| Secrets | None found (only test fixtures: test JWT, `dev-secret`, keycloak `owner-secret` default) | None |
| Releases / tags / issues | None | — |

## 3. Local cleanup

| Item | Size | Action |
|---|---|---|
| `.git` garbage (19 `tmp_obj_*`) | 422 MB | `git gc --prune=now` |
| `.staging` (ignored) | 829 MB | Keep only the Julia skills bundle (2 MB) — move it to a stable path; delete rest |
| `.omo`, `review-tmp-semantic-aggregate`, `.codegraph`, `.codex-*.log`, caches, `apps/frontend/dist` | ~260 MB | Delete |
| `artifacts/` | 67 MB | Archive or delete |
| `.julia-depot` + `.juliaup` | 4.3 GB | Keep while used |
| 14 Codex worktrees (under the user's `.codex\worktrees\`) | — | 12 clean → remove. 2 dirty: `2a51` (ci.yml adds `npm install` before playwright), `a770` (docs/next-steps.md +4, new docs/next-two-milestones.md). Both edits are already in the tip (ci.yml uses `npm ci`; next-steps entry and milestones doc exist); diffs backed up outside the repo |
| Uncommitted `AGENTS.md` (+72, skills/integrations section) | — | Points at an **ignored** `.staging` path → fix path, then commit |
| Untracked `docs/gpu-runtime-assessment-2026-09-20.md`, `docs/images/*.png` | 24 KB, 1.5 MB | Commit under an issue or archive |
| New `.claude/settings.json` (caveman plugin enabled, project scope) | — | Commit if the plugin should apply to every clone |
| Ignore rules split between `.gitignore` and `.git/info/exclude` | — | Consolidate into `.gitignore` |
| Legacy BRDs at root (`JuliaFlow_BRD_v1.0.docx`, `BRD_Julia_EDA_Toolkit-Claudev0.md`) | — | Already moved to `docs/archive/` in tip |

Reclaimable without touching the Julia toolchain: ~1.5 GB.

Code-structure debt (for later, size L): `tests/julia/runtests.jl` 7,885 lines,
`JuliaFlowApiGateway.jl` 7,681 (8,187 in tip), `TierOneTableNodes.jl` 4,193,
`packages/contracts/src/index.ts` 3,184. Docs debt (M–L): `project-tracker.md`
4,532 + `checkpoint-log.md` 4,986 lines with heavy duplication; three overlapping
persona reviews; two architecture docs.

## 4. Product spec review

**Latest spec:** BRD v0.5.0 (2026-09-20, "Hardware-aware Local Data Science
Workstation"), only on the tip branch — `main` still has v0.4.1. The file is
still named `business-requirements-v0.3.0.md`.

**Verdict:** strong engineering-safety thinking (path confinement, honest CPU
fallback, final-test lock, no fixture-as-evidence), weak product thinking. Five
specs have drifted from a KNIME-scale SaaS (docx v1.0) to a local appliance
(v0.4.1) to a GPU/compiler research programme (v0.5.0).

Top issues (verified ones marked ✔):

1. **Release gate is a research programme over a toy data path.** v0.5.0 gates
   release on GPU acceleration across six stage categories plus Reactant compiler
   integration, while CSV execution reads at most 1,000 rows
   (`JuliaFlowDataScienceProjectStatistics.jl:52` `max_rows = 1_000`) ✔.
2. **"Complete" capabilities are fixtures.** Explainability is a hardcoded dict in
   `JuliaFlowApiGateway.jl:~514-524` ✔ — and it ranks `amount` as top feature
   while `amount` is the model target ✔ (target leakage in the demo). DuckDB is a
   generated `.sql` text file; no DuckDB/Parquet dependency. GPU registry defaults
   to `mock:nvidia0`.
3. **No canonical spec**: docx v1.0, Claude v0, v0.4.1, v0.5.0, and Plan.md
   (which still claims streaming/GPU MVP/ArgoCD "closed") contradict each other.
4. **No positioning.** v0.4.1/v0.5.0 name no competitor (KNIME, Orange, Dataiku,
   Pluto/Genie). No answer to "why Julia low-code over free KNIME/Orange?".
5. **Five–six personas, no primary one.**
6. **Process written as product requirements** (Linear sync, approval records,
   contract-first rules, hydration bug fixes as requirements, NASA Power-of-10).
7. **Untestable criteria**: "meaningful", "supported", "where practical"; every
   v0.5.0 acceptance row says "not run"; numeric targets deferred to an
   unpublished envelope.
8. **Missing NFRs**: dataset size envelope, memory, latency, Julia cold-start
   (the real UX risk), numeric reproducibility tolerance.
9. **Scope creep still "in"**: 6 deploy targets, Hub + sandboxed extensions,
   PostgreSQL RBAC, MinIO, 150 base nodes, Windows EXE + Docker.
10. **Governance overhead** far beyond a solo developer: 7 control docs, ~50 docs
    on the tip, 5 docs updated per slice.

**Recommended canonical spec:** one `docs/spec/PRODUCT.md` (≤ 8 pages): problem
and wedge · positioning · MVP journey with numeric acceptance · ~15 functional
requirements in Given/When/Then · NFR table · non-goals · architecture
constraints (Arrow IPC, TOML, contracts-first) · roadmap · open decisions.
Process rules live only in `AGENTS.md`; replace tracker/checkpoint-log with
Linear + `CHANGELOG.md`.

**Keep:** local/offline; confined file import; `DataScienceProject` aggregate;
immutable splits + final-test lock; train-only fit; MLJ (linear/logistic, then
EvoTrees); honest CPU fallback; Arrow IPC + TOML; reproducibility bundle;
Explorer/Data/Transform/Visualize/ML Studio routes.
**Cut:** docx and Claude v0 BRDs (archive), Reactant gate and compiler worker,
MinIO, Kustomize/ArgoCD, streaming, edge/Docker deploy targets, Power-of-10
mandate, tracker/checkpoint logs, hardcoded explainability.
**Defer:** all GPU (JF-ACC-*), Hub/extensions, PostgreSQL RBAC, Windows EXE,
Models/Deploy/Monitor routes, backup/migration; DuckDB/Parquet — implement or
stop claiming.

## 5. Decisions needed before restart

1. **Wedge + primary persona**: non-coding analyst (vs Orange/KNIME) *or* Julia
   data scientist wanting a visual layer over MLJ (vs Pluto).
2. **MVP journey + data envelope** (e.g. CSV/Parquet ≤ 1 GB / 10 M rows on a
   16 GB laptop, profile → transform → MLJ baseline → holdout eval → explain →
   export, under N minutes).
3. **GPU/compiler**: release gate or later differentiator (recommend later).
4. **Canonical branch**: adopt the consolidated tip as new `main`?
5. **Governance budget**: which control docs survive.

## 6. Proposed sync sequence (needs approval at each external step)

1. Local: save/discard the 2 dirty worktrees; remove 12 clean worktrees; `git gc`.
2. Local: `git fetch`; check out the tip; carry over the `AGENTS.md` edit
   (fixed path), `.claude/settings.json`, and chosen untracked docs on a new
   branch off the tip.
3. GitHub: open one PR tip → `main` (with the hygiene fixes: delete
   `mockdesigns/juliaflow`, scrub machine paths); decide hosted-CI policy; merge.
4. GitHub: close #39–#40, #47–#60, #41–#46 as superseded; merge #61/#62; review
   then delete `improvement/browser-live-settings-depth`; delete merged branches.
5. Local: reset local `main` to `origin/main`; delete stale local branches.
   Result: local `main` == `origin/main`, one branch, no open stale PRs.
6. Then spec rewrite (§4) before any new feature work.
