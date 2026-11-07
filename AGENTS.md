# JuliaFlow Agent Rules

## Authority and scope

Read `Plan.md`, `docs/TODO.md`, and `docs/risk-register.md` before implementation
or readiness claims. They describe current scope; archived snapshots are historical.

| Source | Owns |
| --- | --- |
| Linear, project LowCodeML (`AKS-`) | Scope, priority, ownership, dependencies, acceptance, delivery status |
| GitHub | Branches, commits, PRs, reviews, checks, merges, releases, deployment evidence |
| Repository control documents | Requirements traceability, architecture, risks, local verification |
| Code and executable tests | Implemented behavior |

No single source proves completion. Read external state before writing and read it
back afterward. Report the resulting state; never infer completion from titles,
checkboxes, commit messages, a merged PR, or CI success alone.

## Skills and tools

Discover currently installed skills; load only those needed for the task.
Project rules and the user's authorization take precedence over skill procedures.

| Work | Routing |
| --- | --- |
| Julia work | `julia-route-engineering-work` first; verify its signed runtime against the external trust policy |
| Planning / environments / CI | Router selects `julia-plan-project-work` or `julia-manage-project-workflow` |
| Julia implementation / failures | Router selects `julia-write-maintain-code` or `julia-debug-code` |
| Concurrency / performance / native / macros | Load the matching Julia domain skill only when relevant |
| GitHub | `github` skill and authenticated `gh`; MCP only for capabilities unavailable through `gh` |
| Linear | `linear` skill and discovered Linear MCP tools |
| Frontend | Relevant React guidance; rendered-flow testing/debugging for UI behavior |
| Security-sensitive changes | A scoped installed security workflow when its required capabilities are available; otherwise the independent local security-review procedure in `docs/agent-tooling.md` |

Use installed-plugin discovery, not dated `.staging` paths. Keep the nine-skill
Julia runtime intact; do not trim signed files. The router loads the shared
engineering contract once; direct leaf invocation follows that leaf's integrity
and contract instructions. See [tooling guidance](docs/agent-tooling.md).
For a missing skill, check the open ecosystem with `find-skills` before authoring.
A connector failure does not authorize bypassing external state or inventing it.

Report the selected security-review method and missing capabilities. Independent
local review is a separate project procedure, not a canonical Codex Security
scan. When invoking a plugin, preserve its preflight, scan ownership, artifact
storage, and completion rules; do not change vendor instructions or invent scan
IDs, canonical artifacts, or clearance. Julia signature/hash checks and external
trust policy remain mandatory.

## Architecture and change safety

- Preserve `apps`, `packages`, `services`, `extensions`, `infra`, `scripts`, and
  `tests` boundaries; prefer feature-oriented modules over new root files.
- Shared payload changes are contract-first: align TypeScript, OpenAPI/schemas,
  Julia mappings, frontend consumers, fixtures, and tests.
- Preserve TOML round trips and Arrow IPC between nodes. NASA/JPL Power of 10
  remains mandatory for core logic under the current plan.
- Keep `JuliaFlowApiGateway.jl` focused on composition, routing, authorization,
  auditing, error mapping, and module dispatch; put product logic in modules.
- Preserve route shell, runtime `juliaflow-config.js`, accessible selectors, and
  coverage gates unless deliberately replacing them with verified equivalents.
- Release/local-appliance modes must not replace missing backend state with demo,
  fixture, or presentation-only evidence. Provider/cloud work stays optional
  unless current control documents explicitly prioritize it.
- Preserve user edits, worktrees, and retained evidence. Read overlapping changes
  and integrate them; never revert unrelated work or broadly clean unknown files.
- Do not commit secrets, machine-specific paths, generated outputs, or
  `Manifest.toml`; `Project.toml` owns checked-in Julia dependencies.
- Enforce configured roots, real-path confinement, symlink/junction policy,
  redaction, connector policy, identifier validation, and checksums for local I/O.
- Preserve success, failure, rejection, and error-path coverage. Isolate mutable
  fixtures rather than weakening assertions. Keep CPU fallback explicit/tested;
  GPU checks may skip only with a recorded reason and no hardware-success claim.

## Tracking and delivery

1. Resolve the Linear issue and read its criteria, blockers, dependencies,
   priority, project, and risks; otherwise explicitly label work untracked.
2. Reconcile it with the current plan, TODO, and risk register. Record newly
   discovered defects or follow-ups in Linear before committing to their scope.
3. Use `codex/<issue-key>-<scope>` branches and coherent commits for tracked work.
   Read-only tasks must not mutate branches, trackers, comments, or delivery state.
4. Start In Progress when design, implementation, or verification begins. Record
   real blockers affecting scope, ownership, acceptance, or schedule.
5. PRs link `Fixes AKS-xx` and state scope, acceptance covered, verification,
   skips/gaps, control-document changes, and relevant migration/rollback notes.
6. Failing required checks block merge. Resolve findings by implementation,
   evidence-backed rejection, or authorized acceptance. Never weaken tests or
   substitute fixtures to close release gaps.
7. Do not merge, force-push, dismiss reviews, rerun deployments, modify branch
   protection, tag, or release without explicit authorization for that action.

Development push and draft PR publication require the applicable exact-candidate
checks and required independent correctness, UI, and security review through an
available approved method. Unresolved findings block publication unless resolved
by implementation, evidence-backed rejection, or explicit authorized acceptance.
Preserve any increment-specific full aggregate verification requirement.
Participant, accessibility, original-board, GPU, and wider platform acceptance
remain milestone requirements; they block bounded development publication only
when the increment explicitly requires them before publication. A development
PR does not satisfy those criteria or establish readiness. Merge still requires
applicable checks/reviews, resolution of merge blockers, and explicit action
authorization; deployment, tags, and releases remain separately authorized.

| Linear state | Required meaning |
| --- | --- |
| Todo | Accepted work, not started |
| In Progress | Design, implementation, or verification underway |
| In Review | Reviewable PR exists and required local results are reported |
| Blocked | Real external dependency/decision prevents progress; link resolution |
| Done | Every condition in the checklist below is satisfied |
| Canceled / Duplicate | Record the decision and replacement/superseding issue |

Before Done: verify every criterion against code/executable evidence; confirm
required checks and merge; resolve reviews/blockers; synchronize control documents
and BRD traceability; report proportional checks and every skip; link PR, evidence,
and accepted follow-ups in Linear. A closed unmerged PR needs an explicitly chosen
Linear state. Automated merge events must not mark work Done by themselves.

## Verification and control documents

Prefer scripts in `package.json` over platform-specific commands. `npm run test`
excludes Julia, browser, extension, local smoke, and full release gates.

| Changed surface | Minimum verification |
| --- | --- |
| Contracts/OpenAPI | `validate:contracts` plus affected Julia/frontend tests |
| Julia helpers | Corresponding focused `julia:test:*` slice |
| Gateway / persistence / worker | `julia:test:api-gateway` / `julia:test:repository` / `julia:test:worker` |
| Frontend component/state | Focused frontend test and `build` |
| Cross-route workflow | Relevant Playwright or live-backend smoke |
| Julia dependency | `julia:instantiate` and affected Julia tests |
| TODO/traceability | `validate:control-doc-sync` and `validate:brd-traceability` |
| Release/readiness claim | Full `verify:release`, no skipped product/runtime phases |
| Every implementation | `git diff --check`; exact pass/fail/skip reporting |

Run table entries through `npm run`. The governed set is the root
`business-requirements-v0.3.0.md`, `Plan.md`, and `docs/{TODO,risk-register,
brd-traceability,project-tracker,checkpoint-log}.md`.

- Product/dependency changes update plan, TODO, risks, tracker, and checkpoint.
  BRD changes also update traceability. Maintenance-only scripts/tests/CI/ignore
  changes require tracker/checkpoint evidence; update scope/risks when affected.
- Documentation-only corrections need no fabricated product-status changes.
  Read-only reviews require no control-document churn.
- P0/P1/P2 completion requires code and verification in BRD traceability.
  Structural validators do not prove the truth of cited implementation evidence.
- For committed work, run `npm run validate:control-doc-sync -- --base <base-ref>`.
  CI reads the event baseline and must fetch history; missing baselines fail.
  Without a baseline, the command explicitly checks working-tree changes only.
- Keep current summaries concise. Preserve historical evidence in indexed,
  hash-verified archives; do not edit snapshots or erase acceptance gaps.
- Tracker/checkpoint records identify completed work, remaining gaps, and the next
  bounded action. CI failures alone do not imply Blocked; deployment failures
  create/reopen linked bug work rather than rewriting completed issue history.
- Do not revive inbound workstation webhooks or custom-node GitHub CI monitors.
  Use GitHub-native checks/summaries or bounded local polling with backoff.
