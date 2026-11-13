# JuliaFlow Agent Rules

## Scope and sources of truth

Read [docs/spec/PRODUCT.md](docs/spec/PRODUCT.md) and the relevant
[persona sheet](docs/spec/personas/) before implementation or readiness claims.
`docs/archive/` holds historical snapshots only.

| Source | Owns |
| --- | --- |
| `docs/spec/` | Requirements (PR-xx, NFR-xx), non-goals, roadmap, risks |
| GitHub Issues + the repository's GitHub Project | Scope of each task, priority, status, acceptance |
| GitHub PRs, checks, reviews | Delivery evidence, merges, releases |
| Code and executable tests | Implemented behavior |

No single source proves completion. Never infer it from titles, checkboxes,
commit messages, a merged PR or green CI alone.

## Skills

Discover installed skills; load only what the task needs. Project rules and the
user's authorization override skill procedures.

| Work | Routing |
| --- | --- |
| Julia (any) | `julia-route-engineering-work` first; it selects the planning, workflow, implementation, debugging or domain leaf skill. Verify its signed runtime against the external trust policy; never trim or edit signed files. |
| GitHub | `github` skill and authenticated `gh` |
| Frontend | React guidance; rendered-flow testing for UI behavior |
| Security-sensitive change | An installed scoped security workflow, else the local review procedure in [docs/agent-tooling.md](docs/agent-tooling.md); report the method used and any missing capability |

## Architecture and change safety

- Keep `apps`, `packages`, `services`, `extensions`, `infra`, `scripts`, `tests` boundaries.
- Payload changes are contract-first: TypeScript/OpenAPI, Julia mapping, consumers, fixtures and tests together.
- Keep Arrow IPC between steps and TOML round trips. NASA/JPL Power of 10 applies to core logic.
- `JuliaFlowApiGateway.jl` only composes, routes, authorizes, audits and maps errors; product logic lives in modules.
- Keep the route shell, runtime `juliaflow-config.js`, accessible selectors and coverage gates unless replaced by verified equivalents.
- Release and local-appliance modes never substitute demo, fixture or presentation data for missing backend state.
- Local I/O enforces approved roots, real-path confinement, symlink/junction policy, redaction, identifier checks and checksums.
- Keep success, failure, rejection and error-path tests. Never weaken assertions to pass. CPU is the required path; GPU tests may skip only with a recorded reason.
- Never commit secrets, machine-specific paths, generated outputs or `Manifest.toml`.
- Preserve user edits, worktrees and evidence; never revert unrelated work or bulk-delete unknown files.

## Delivery

1. Work from a GitHub issue; otherwise label the work untracked in the PR. File newly found defects as issues before widening scope.
2. Branch `<agent>/<issue-number>-<scope>`; coherent commits.
3. Move the issue on the GitHub Project: In Progress when work starts, In Review when a PR with local results exists, Done only after merge and verified acceptance.
4. PR body: `Fixes #N`, scope, acceptance covered, verification run, skips/gaps, spec changes, rollback notes.
5. Failing required checks block merge. Resolve review findings by fix, evidence-backed rejection or explicit user acceptance.
6. Never merge, force-push, dismiss reviews, change branch protection, tag, release or deploy without the user's explicit authorization for that action.
7. A requirement change edits `docs/spec/` in the same PR. Read-only tasks change nothing.

## Verification

Run through `npm run`. `npm run test` excludes Julia, browser, extension, smoke and release gates.

| Changed surface | Minimum verification |
| --- | --- |
| Contracts/OpenAPI | `validate:contracts` + affected Julia/frontend tests |
| Julia helpers | Matching `julia:test:*` slice |
| Gateway / persistence / worker | `julia:test:api-gateway` / `julia:test:repository` / `julia:test:worker` |
| Frontend component/state | Focused frontend test + `build` |
| Cross-route workflow | Relevant Playwright or live-backend smoke |
| Julia dependency | `julia:instantiate` + affected Julia tests |
| Release/readiness claim | Full `verify:release`, no skipped product/runtime phases |
| Every change | `git diff --check`; report exact pass/fail/skip |

Local CI runs through EasyCI or `scripts/ci/`; see [docs/local-ci.md](docs/local-ci.md).
Do not revive inbound workstation webhooks or custom GitHub CI monitors.
