# JuliaFlow Agent Rules

## Scope And Authority

This file contains durable repository-specific execution rules. Current scope,
priority, and delivery status live in `Plan.md`, `docs/TODO.md`, and
`docs/risk-register.md`. Read those files before substantive implementation or
readiness claims.

Use one source of truth for each kind of state:

- Linear owns project scope, issues, bugs, features, priority, ownership,
  dependencies, acceptance criteria, and delivery status.
- GitHub owns branches, commits, pull requests, reviews, GitHub Actions checks,
  merges, releases, and deployment evidence.
- Repository control documents own requirements traceability, architecture
  decisions, accepted risks, and local verification evidence.
- Code and executable tests remain authoritative for implemented behavior.

No system independently proves completion. A Linear issue is Done only when its
acceptance criteria, GitHub delivery state, and required repository evidence agree.

## Architecture Invariants

- Preserve product boundaries under `apps`, `packages`, `services`, `extensions`,
  `infra`, `scripts`, and `tests`. Prefer feature-oriented paths inside them over
  new root-level files.
- Shared payload changes are contract-first. Align TypeScript contracts, OpenAPI,
  applicable schemas, Julia route and repository mappings, frontend consumers,
  fixtures, and tests.
- Preserve TOML workflow round trips and Arrow IPC as the inter-node payload
  boundary.
- Keep `JuliaFlowApiGateway.jl` focused on composition, routing, authorization,
  auditing, error mapping, and module dispatch. Put product logic in focused
  modules.
- Preserve the route shell, runtime `juliaflow-config.js`, accessible selectors,
  and coverage gates unless intentionally replacing them with verified equivalents.
- Release and `local-appliance` modes must never substitute demo, fixture, or
  presentation-only evidence for missing backend state.
- Provider and cloud integrations remain optional compatibility work unless the
  current control documents explicitly prioritize them.

## Change Safety

- Preserve pre-existing working-tree changes. Never revert unrelated edits. Read
  overlapping changes and integrate with them.
- Do not commit secrets, machine-specific paths, generated artifacts, or
  `Manifest.toml`. `Project.toml` owns checked-in Julia dependencies.
- Validate local file access through configured roots, real-path confinement,
  symlink and junction policy, redaction, connector policy, identifier validation,
  and checksum controls.
- Preserve designed success, failure, rejection, and error-path test coverage.
  Isolate mutable fixtures instead of weakening or deleting assertions.
- Keep CPU fallback behavior explicit and tested. Hardware-dependent GPU checks may
  skip only when the reason is recorded and no GPU capability is claimed.

## Work Tracking And Delivery

### Before Implementation

- Resolve the Linear issue or explicitly state that the work is untracked. Read its
  acceptance criteria, dependencies, blockers, priority, parent project, and linked
  risks.
- Reconcile the issue with `Plan.md`, `docs/TODO.md`, and `docs/risk-register.md`.
- Do not silently expand scope. Record newly discovered bugs, risks, or follow-up
  features in Linear before treating them as committed work.
- For tracked implementation, use a branch containing the issue identifier, such as
  `codex/aks-36-datascienceproject-substrate`.
- Do not create or modify branches, Linear issues, GitHub comments, commits, pushes,
  pull requests, merges, or releases during read-only work or without authorization.

### During Implementation

- Keep commits scoped to one coherent concern where practical.
- Reference the Linear identifier in the branch and pull request, and in relevant
  control-document evidence.
- Move Linear work to In Progress only when design, implementation, or verification
  has actually started.
- Record blockers when they affect scope, acceptance, ownership, or schedule.
- Fix newly discovered defects in scope or record them as linked Linear issues with
  severity, reproduction evidence, and affected acceptance criteria.
- Do not close acceptance gaps by weakening tests or by substituting fixture evidence
  in release or `local-appliance` mode.

### Pull Requests And CI

- A pull request must link its Linear issue and state implemented scope, acceptance
  criteria covered, verification run, known gaps and skips, control-document
  changes, and rollback or migration considerations where applicable.
- GitHub Actions success proves only the checks that ran. It does not prove release
  readiness when browser, local smoke, hardware, security, extension, or
  control-document gates were absent or skipped.
- Failing required checks block merge. Review findings remain open until implemented,
  rejected with evidence, or explicitly accepted by an authorized reviewer.
- Do not merge, force-push, dismiss reviews, rerun deployments, or modify branch
  protection without explicit authorization.

### Status Reconciliation

- `Todo`: accepted work exists, but implementation has not started.
- `In Progress`: design, implementation, or verification work has started.
- `In Review`: a reviewable pull request exists and required local checks are
  reported.
- `Blocked`: an external dependency or accepted decision prevents meaningful
  progress; link the blocker and required resolution.
- `Done`: acceptance criteria are satisfied, required checks pass, the pull request
  is merged, blockers and required reviews are resolved, evidence is linked, and
  required control documents agree.
- `Canceled` or `Duplicate`: record the decision and replacement or superseding issue.

A draft pull request, green CI run, merged pull request, document checkbox, or commit
message does not independently make a Linear issue Done.

Before moving a Linear issue to Done:

1. Confirm every acceptance criterion against code or executable evidence.
2. Confirm required GitHub checks passed and the pull request was merged.
3. Confirm unresolved review findings and blockers are cleared or explicitly accepted.
4. Update required control documents and BRD traceability.
5. Run proportional verification and report every skipped check.
6. Link the pull request, verification evidence, and accepted follow-up issues in
   Linear.

Read external status before writing to Linear or GitHub. After an external update,
read it back and report the resulting state. Never infer completion from titles,
commit messages, document checkboxes, or CI status alone.

## Commands

Prefer repository scripts over direct platform-specific commands.

- Install JavaScript dependencies: `npm install`
- Check the host toolchain: `npm run doctor:windows` or `npm run doctor:debian`
- Instantiate Julia dependencies: `npm run julia:instantiate`
- Validate contracts: `npm run validate:contracts`
- Run JavaScript workspace and contract tests: `npm run test`
- Run the authoritative Julia suite: `npm run julia:test`
- Time the Julia suite: `npm run julia:test:timed`
- Run focused Julia suites: `npm run julia:test:helpers`, `npm run julia:test:tuning`,
  `npm run julia:test:local-sources`,
  `npm run julia:test:repository`, `npm run julia:test:worker`, or
  `npm run julia:test:api-gateway`
- Build the frontend and workspaces: `npm run build`
- Run browser tests: `npm run test:browser`
- Run the live-backend browser smoke: `npm run smoke:live-backend-browser`
- Run the full release gate: `npm run verify:release`
- Check patch formatting: `git diff --check`

`npm run test` does not include the Julia, browser, extension, local smoke, or full
release gates. Do not describe it as the complete repository test suite.

## Proportional Verification

Run at least the gates required by the changed surface:

| Changed surface | Required minimum evidence |
| --- | --- |
| Contracts or OpenAPI | `npm run validate:contracts` plus affected Julia and frontend tests |
| Julia helper logic | Corresponding focused `julia:test:*` slice |
| Gateway routes | `npm run julia:test:api-gateway` |
| Repository persistence | `npm run julia:test:repository` |
| Worker behavior | `npm run julia:test:worker` |
| Frontend component or state | Focused frontend test plus `npm run build` |
| Cross-route user workflow | Relevant Playwright or live-backend smoke |
| Julia dependency | `npm run julia:instantiate` plus affected Julia tests |
| TODO or traceability status | Both control-document validators |
| Release or readiness claim | `npm run verify:release` with no skipped product or runtime phases |
| Every implementation | `git diff --check` and exact reporting of skipped gates |

Report exactly what passed, failed, and was skipped. CI success alone is not
release-readiness evidence.

## Governance And Control Documents

The governed control set is:

- `business-requirements-v0.3.0.md`
- `Plan.md`
- `docs/TODO.md`
- `docs/risk-register.md`
- `docs/brd-traceability.md`
- `docs/project-tracker.md`
- `docs/checkpoint-log.md`

- Do not mark P0, P1, or P2 work complete without code and verification evidence in
  `docs/brd-traceability.md`.
- Update control documents for completed slices, changed risks, milestone decisions,
  or status changes. Read-only reviews do not require control-document churn.
- Tracker and checkpoint updates must identify work completed, gaps remaining, and
  the next bounded action.
- Run `npm run validate:control-doc-sync` when closing governed implementation work.
- Run `npm run validate:brd-traceability` after TODO or traceability changes.
- These validators check document structure and synchronization, not the truth of an
  implementation claim. Verify every cited artifact and test result.

## External Automation Boundaries

- Linear-to-GitHub automation may suggest or apply `In Review` when a pull request is
  ready, but it must not mark work Done solely because a pull request merged.
- CI failure may add delivery-risk evidence, but it must not automatically classify
  an issue as Blocked without a real external dependency.
- A closed, unmerged pull request must return to an explicitly chosen Linear state.
- Deployment failures should create or reopen linked bug work rather than rewriting
  completed issue history.
- Do not revive inbound workstation webhooks or custom-node GitHub CI monitors.
  Prefer GitHub-native checks, summaries, and bounded local polling with backoff.
