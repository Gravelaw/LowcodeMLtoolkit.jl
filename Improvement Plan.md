# JuliaFlow Improvement Plan

Date: 2026-06-17
Status: Planning artifact for the next local-first product-readiness goal
Scope: Suggested improvements 1 through 4 from the post-redesign BRD analysis

## Purpose

This plan turns the current post-merge analysis into an actionable implementation goal. The repo has closed the current core local-first BRD slice and now has a mockup-aligned JuliaFlow Local UI plus fixture-backed Playwright browser tests. The next improvements should harden that work into durable release practice and deepen local-first product quality without expanding optional provider/cloud scope.

The four improvement areas are:

1. CI Browser Gate
2. Optional Live Local Browser Smoke
3. Accessibility And Responsive Hardening
4. Product-Depth Follow-Up

## Current Baseline

- `main` is clean and synced after PR #18.
- Core P0/P1/P2 and current local-first TODO items are checked.
- `npm run validate:control-doc-sync` passes with no working-tree changes.
- `npm run validate:brd-traceability` passes for checked TODO evidence.
- `npm run test:browser` exists and passes locally with fixture-backed mocked gateway routes.
- `.github/workflows/ci.yml` currently runs `npm run build` and `npm run test` in the `web` job, but does not run `npm run test:browser`.
- Optional provider/cloud compatibility and hardware-conditional multi-GPU closure remain out of scope unless explicitly reprioritized or suitable hardware/provider prerequisites appear.

## Non-Goals

- Do not mark optional provider/cloud TODO items complete.
- Do not add real cloud/provider dependencies or credentials.
- Do not make live Julia service startup a required default browser gate.
- Do not replace fixture-backed Playwright tests with a brittle end-to-end dependency on `dev:local`.
- Do not expand multi-GPU work without a host or CI runner with at least two visible CUDA devices.

## Improvement 1: CI Browser Gate

### Objective

Make the existing Playwright browser suite a real CI release gate, not just local verification evidence.

### Current Gap

`package.json` includes:

- `test:browser`
- `test:browser:headed`

`playwright.config.ts` defines desktop and mobile-width Chromium projects and starts Vite on port `4177`.

However, `.github/workflows/ci.yml` does not install Playwright browsers or run `npm run test:browser`.

### Implementation Steps

1. Update `.github/workflows/ci.yml` in the `web` job after `npm install`.
2. Install the Chromium browser dependency used by Playwright.
   - Preferred command: `npx playwright install --with-deps chromium`
   - If GitHub runner dependency installation becomes slow or flaky, consider `npx playwright install chromium` first, then add `--with-deps` only if needed by CI.
3. Add `npm run test:browser` after `npm run test`.
4. Keep `npm run build` before tests so TypeScript and bundling failures fail fast.
5. Preserve the existing `julia` CI job unchanged.
6. Open a PR and confirm the `web` check includes browser test execution.

### Proposed CI Order

```yaml
- run: npm install
- run: npx playwright install --with-deps chromium
- run: npm run build
- run: npm run test
- run: npm run test:browser
```

### Acceptance Criteria

- CI `web` job runs Playwright browser tests on pull requests.
- CI uses the existing mocked gateway routes, not a live Julia gateway.
- Desktop and mobile-width Chromium projects pass in CI.
- Failure artifacts remain available through Playwright screenshots/traces on failure.
- `julia` CI remains independent and unchanged.

### Verification

- `npm run test:browser`
- `npm run build`
- `npm run test`
- PR CI `web` check passes with browser test output visible.
- `npm run validate:control-doc-sync` if any control docs are updated.

### Risks And Mitigations

- Risk: Playwright dependency install increases CI runtime.
  - Mitigation: install only Chromium; keep projects Chromium-only.
- Risk: CI runner lacks system dependencies.
  - Mitigation: use `npx playwright install --with-deps chromium`.
- Risk: browser server port collision.
  - Mitigation: keep isolated port `4177`; Playwright starts one web server per test run.

## Improvement 2: Optional Live Local Browser Smoke

### Objective

Add an opt-in browser smoke path that can verify the redesigned frontend against a live local JuliaFlow stack, while keeping fixture-backed Playwright as the default deterministic gate.

### Current Gap

The current Playwright tests intercept gateway calls to `http://127.0.0.1:8088/**`. This is correct for deterministic CI, but it does not exercise a real `dev:local` gateway/frontend integration path.

### Design Principle

Live local browser smoke must be optional. It should be useful for release candidates and local appliance validation, but it should not block normal CI unless the local stack is explicitly started and available.

### Implementation Steps

1. Add a separate Playwright config or project for live local smoke.
   - Option A: `playwright.local.config.ts`
   - Option B: keep one config and use `JULIAFLOW_BROWSER_LIVE=1` to disable mocks.
2. Add a new root script:
   - `test:browser:local`
3. Keep the default `test:browser` script fixture-backed.
4. Create a live smoke spec that:
   - Does not install route mocks.
   - Reads gateway base URL from `JULIAFLOW_GATEWAY_BASE_URL` or `VITE_JULIAFLOW_GATEWAY_BASE_URL`.
   - Navigates through the same core routes.
   - Verifies that at least one real gateway-backed health/workflow response is reflected in the UI.
5. Document prerequisites:
   - Start local stack first, likely with `npm run dev:local`.
   - Confirm gateway is reachable at `http://127.0.0.1:8088`.
6. Ensure live smoke has a clear skip/fail mode.
   - If explicit live flag is absent, skip.
   - If explicit live flag is present and gateway is unreachable, fail.

### Proposed Script

```json
"test:browser:local": "JULIAFLOW_BROWSER_LIVE=1 playwright test --config playwright.local.config.ts"
```

If cross-platform shell support becomes necessary, implement a small Node wrapper script rather than relying on inline environment variables.

### Acceptance Criteria

- `npm run test:browser` remains deterministic and mocked.
- `npm run test:browser:local` exists as an explicit opt-in path.
- Live smoke never silently passes when explicitly requested and gateway is unavailable.
- Live smoke validates runtime `juliaflow-config.js` or environment base URL wiring.
- No provider/cloud service is required.

### Verification

- `npm run test:browser`
- With local stack running: `npm run test:browser:local`
- Without local stack and with live flag enabled: confirm the command fails clearly.
- `npm run build`
- `npm run test`

### Risks And Mitigations

- Risk: live smoke becomes flaky due to port contention or service startup timing.
  - Mitigation: keep it opt-in; do not run in default CI.
- Risk: live smoke duplicates fixture journey too much.
  - Mitigation: keep live smoke narrow: health, route shell, one gateway-backed action.
- Risk: service startup is slow.
  - Mitigation: assume stack is already running; avoid starting all services inside Playwright initially.

## Improvement 3: Accessibility And Responsive Hardening

### Objective

Raise confidence that the redesigned JuliaFlow Local UI is usable across keyboard, screen-reader landmarks, action feedback states, and mobile-width layouts.

### Current Gap

The current browser tests verify:

- App loads in real Chromium.
- `100% Local` status is visible.
- Sidebar navigation reaches the redesigned routes.
- Synthetic data and route-specific evidence render.
- Backend-backed actions display success feedback under mocked gateway routes.
- Desktop and mobile-width Chromium projects run.
- Major console errors fail tests.

They do not yet deeply verify:

- Focus order.
- Active navigation semantics beyond basic route reachability.
- Landmark structure.
- Action feedback announcement semantics.
- Mobile route ergonomics beyond route content visibility.
- Keyboard-only operation for core flows.

### Implementation Steps

1. Add stable accessibility selectors or semantics where needed.
   - Keep current accessible route buttons.
   - Add `aria-live` or `role="status"` for action feedback messages.
   - Ensure active nav remains `aria-current="page"`.
2. Expand Playwright tests with an accessibility/responsive spec.
3. Test keyboard navigation:
   - Tab from top of app to navigation.
   - Activate routes with `Enter` or `Space`.
   - Activate primary route actions with keyboard.
4. Test landmarks:
   - Sidebar has `aria-label="JuliaFlow Local navigation"`.
   - Main workspace is discoverable as main content.
   - `100% Local` remains a visible status region.
5. Test action feedback:
   - Data import feedback appears and is exposed as status/live region.
   - Transform/ML/Models/Visualize/Deploy actions show distinct feedback.
6. Test mobile ergonomics:
   - At 390x844, navigation buttons remain visible and usable.
   - Route headings are visible after navigation.
   - No key content is hidden behind sticky header or sidebar.
7. Consider targeted component changes if tests reveal missing semantics.

### Suggested Playwright Assertions

- `await expect(page.getByRole("navigation", { name: /JuliaFlow Local/i })).toBeVisible();`
- `await expect(page.getByRole("main")).toBeVisible();`
- `await expect(page.getByRole("button", { name: "Data" })).toHaveAttribute("aria-current", "page");`
- `await page.keyboard.press("Tab");`
- `await page.keyboard.press("Enter");`
- `await expect(page.getByRole("status", { name: /action feedback/i })).toContainText(...)`

### Acceptance Criteria

- Core route navigation works by keyboard.
- Active route is announced through `aria-current="page"`.
- Action feedback is exposed through a live/status region.
- Mobile-width route navigation remains usable.
- No new console errors are introduced.
- Existing visual density and mockup alignment remain intact.

### Verification

- `npm run test:browser`
- `npm --workspace @juliaflow/frontend run test -- App.test.tsx`
- `npm run build`
- Optional manual browser pass on 1440x1000 and 390x844.

### Risks And Mitigations

- Risk: adding accessible labels changes test selectors.
  - Mitigation: prefer additive semantics and keep existing route button names stable.
- Risk: over-testing exact layout makes tests brittle.
  - Mitigation: assert usability and visibility, not pixel-perfect positions.
- Risk: mobile layout requires CSS refinements.
  - Mitigation: keep changes scoped to responsive rules and stable dimensions.

## Improvement 4: Product-Depth Follow-Up

### Objective

Pick one concrete local-first workflow and deepen it beyond static/synthetic product cards, while preserving the mockup-aligned shell, backend action seams, and deterministic test coverage.

### Recommended Product-Depth Lane

Start with Settings, then Data, then Transform. This order is pragmatic:

1. Settings controls local appliance trust boundaries, paths, package environment, API keys, and backup behavior.
2. Data is the first user workflow after workspace setup.
3. Transform depends on richer data profile/lineage state.

### Candidate A: Settings Local Appliance Controls

#### Scope

Deepen Settings into a real local appliance control surface.

#### Features

- Workspace path controls:
  - data root
  - models root
  - backups root
  - exports root
- Package environment panel:
  - active environment
  - Julia executable path
  - manifest status
  - offline package cache status
- Compute settings:
  - CPU thread limit
  - memory limit display
  - GPU readiness/fallback state
- Privacy/security:
  - no telemetry
  - local logs only
  - local API keys scoped to this device or LAN
- Backup/snapshot controls:
  - create snapshot
  - retention setting
  - backup status
  - last backup evidence

#### Backend Considerations

Use existing health/backup evidence first. Add contracts only if a true mutation endpoint is needed.

#### Acceptance Criteria

- Settings exposes concrete local paths and backup state from existing local health evidence.
- API key UI does not store or display real secrets.
- Backup/snapshot controls use deterministic demo fallback unless a real endpoint already exists.
- Tests cover UI state and fallback behavior.

### Candidate B: Data Module Local Workflow Depth

#### Scope

Make Data feel like a practical local dataset workspace rather than a static profile/table view.

#### Features

- Dataset table tabs:
  - Rows
  - Schema
  - Profile
  - Lineage
- Column search/filter.
- Local refresh action.
- Dataset quality warnings.
- File metadata:
  - path
  - size
  - modified time
  - checksum
- Export column summary.
- Data profile action backed by existing `importDataProfile`.

#### Backend Considerations

Prefer existing `POST /api/v1/local-data/import` and deterministic fallback. Add new routes only if the UI needs persisted dataset catalog behavior.

#### Acceptance Criteria

- User can inspect rows, schema, profile, and lineage in one route.
- Import/profile action keeps working against gateway and fallback.
- Browser tests verify tabs/search/action feedback.

### Candidate C: Transform Pipeline Editing Depth

#### Scope

Make Transform support basic local pipeline editing and preview behavior.

#### Features

- Select transform node.
- Show node-specific settings.
- Add transform from library into the pipeline.
- Preview transform on synthetic rows.
- Show before/after row count and artifact refs.
- Preserve generated Julia code panel.

#### Backend Considerations

Use existing `runWorkflowTransform` for execution. Keep editing state local until workflow persistence is explicitly needed.

#### Acceptance Criteria

- User can add/select a transform step locally.
- Preview evidence updates deterministically.
- Gateway-backed run still works when configured.
- Browser and unit tests cover add/select/run behavior.

### Recommended First Product-Depth Slice

Implement Candidate A: Settings Local Appliance Controls.

Reasoning:

- It directly supports local trust boundaries in the BRD.
- It is less likely to require new backend contracts than Data or Transform.
- It complements the new mockup-aligned shell and local appliance positioning.
- It can add meaningful product depth without touching provider/cloud scope.

### Product-Depth Verification

For whichever candidate is selected:

- `npm --workspace @juliaflow/frontend run test -- App.test.tsx`
- `npm run test:browser`
- `npm run build`
- `npm run test`
- `npm run validate:control-doc-sync`
- `npm run validate:brd-traceability`
- `git diff --check`

If contracts or Julia routes change:

- `npm run validate:contracts`
- `julia --project=. tests/julia/runtests.jl`

## Suggested Implementation Order

1. CI Browser Gate
   - Smallest and most important hardening task.
   - Makes existing browser work enforceable on every PR.

2. Accessibility And Responsive Hardening
   - Builds directly on the browser gate.
   - Low backend risk.

3. Optional Live Local Browser Smoke
   - Useful after browser CI is stable.
   - Keep opt-in to avoid CI flake.

4. Product-Depth Follow-Up: Settings Local Appliance Controls
   - Deepens local appliance readiness without adding provider scope.

## Branch And PR Strategy

Use separate PRs unless the user requests a combined implementation.

### PR 1: CI Browser Gate

- Files likely touched:
  - `.github/workflows/ci.yml`
  - possibly `package.json` if a helper script is needed
- Checks:
  - CI `web`
  - `npm run test:browser`
  - `npm run build`
  - `npm run test`

### PR 2: Accessibility And Responsive Hardening

- Files likely touched:
  - `apps/frontend/src/components/Shell.tsx`
  - `apps/frontend/src/components/ui.tsx`
  - route views as needed
  - `apps/frontend/src/styles.css`
  - `tests/browser/local-ui.spec.ts`
  - possible new browser spec
- Checks:
  - `npm run test:browser`
  - `npm --workspace @juliaflow/frontend run test -- App.test.tsx`
  - `npm run build`

### PR 3: Optional Live Local Browser Smoke

- Files likely touched:
  - `package.json`
  - `playwright.local.config.ts` or equivalent
  - `tests/browser/local-live.spec.ts`
  - possible docs or control docs
- Checks:
  - `npm run test:browser`
  - optional local `npm run test:browser:local`

### PR 4: Settings Product-Depth Slice

- Files likely touched:
  - `apps/frontend/src/views/SettingsView.tsx`
  - `apps/frontend/src/fixtures/local-fixtures.ts`
  - `apps/frontend/src/App.test.tsx`
  - `tests/browser/local-ui.spec.ts`
  - control docs if claiming completion
- Checks:
  - frontend/browser/build gates
  - contracts/Julia only if backend contracts change

## Completion Rules

For any implemented slice:

- Update `Plan.md`, `docs/TODO.md`, `docs/risk-register.md`, `docs/project-tracker.md`, `docs/checkpoint-log.md`, and `docs/brd-traceability.md` only when making a completion claim or changing tracked scope.
- Do not mark optional provider/cloud or multi-GPU TODOs complete.
- Run `npm run validate:control-doc-sync` before completion claims.
- Run `npm run validate:brd-traceability` after TODO or traceability edits.
- Keep `git diff --check` clean.

## Definition Of Done For This Improvement Goal

The full improvement goal can be considered complete when:

- CI runs the fixture-backed Playwright browser suite by default.
- Browser tests include accessibility and responsive checks for the redesigned local UI.
- An optional live local smoke path exists and is documented or self-describing.
- One local-first product module, preferably Settings, has meaningful product-depth controls and tests beyond static route rendering.
- All relevant validation gates pass.
- Control docs reflect only completed work and keep provider/cloud plus multi-GPU items optional or gated.
