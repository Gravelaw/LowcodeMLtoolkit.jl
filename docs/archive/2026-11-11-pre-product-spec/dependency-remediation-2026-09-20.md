# AKS-52 dependency remediation

Baseline: `ebeebfeb26357414e8243d216885cfb577001730` (PR #47), stacked on PR #40. Date: 2026-09-20. This is dependency and verification maintenance, not release certification.

## Advisory reconciliation

Live GitHub default-branch alerts: ten alerts (six high, four moderate). The baseline locked installation reports eight affected package entries (four high, four moderate); these counts use different units. The candidate clean locked installation reports zero vulnerabilities. Advisory absence is not proof of application security.

| Package | Advisory IDs (GHSA) | Candidate | Existing PR | Exposure considered |
| --- | --- | --- | --- | --- |
| postcss | r28c-9q8g-f849; fxqj-rqcc-2cmp | 8.5.25 | #41 | Build-time CSS/source-map processing; untrusted source input is a prerequisite |
| nanoid | 28wg-ghj8-5hjv; 2v37-7h3g-55p8 | 3.3.18 | #42 | Transitive PostCSS identifier generation; no application exploit established |
| browserslist | 73wf-gq98-2v4g; c83g-rgw3-j3cx | 4.28.9 | #43 | Babel/browser-target build processing |
| vitest / @vitest/mocker | 82fw-gwwq-j7x9 | 4.1.11 | #44 | Development/test tooling; coverage package is also affected transitively |
| smol-toml | 7w5x-hrqm-74c2 | 1.7.1 | #45 | TOML parsing in contract/maintenance workflows; preserve round-trip tests |
| baseline-browser-mapping | w5vr-8v7q-w6rv | 2.11.22 | #46 | Browser-target metadata dependency |

The candidate covers the target versions of PRs #41–#46. Leave those PRs open until approved integration. PR #44 changes its manifest request but retains a 4.1.8 locked Vitest entry in its current diff; it is not adequate proof of remediation alone. This candidate aligns Vitest, its internal packages, and coverage-v8 at 4.1.11. npm regenerates supporting dependencies and hoists the Vitest subtree; no blanket audit fix, Julia dependency, public API, schema, or stored-data change is included.

## Verification infrastructure

The frontend launcher hard-coded `node_modules/vitest/vitest.mjs` inside the workspace. After npm hoisting, the original command fails with MODULE_NOT_FOUND. The scripts now use npm's local executable resolution (`vitest`), which works with the locked workspace install.

Coverage failed on the unchanged baseline (77.73% statements, 67.15% branches) and the initial upgraded candidate (76.75%, 67.15%). Five added tests cover backend graph/dashboard preservation, execution failure/queue/stream reasons, checkpoint tags, and control-flow recovery evidence. Numeric thresholds, surface requirements, assertions and timeout budgets remain unchanged. Final coverage: statements 79.68%, branches 73.21%, functions 79.12%, lines 81.57%; the surface gate passes.

## Local evidence

Windows x64, Node 26.3.0, npm 12.0.0. Raw command logs and before/after audit JSON are retained in the task's external evidence directory (not committed). Evidence applies to the dependency/test tree in this change; subsequent documentation-only commits do not change that tree.

| Command | Result |
| --- | --- |
| `npm ci` | Passed; clean locked install, zero audit findings |
| `npm audit --json` | Passed; zero high/moderate/low/critical findings |
| `npm run validate:contracts` | Passed: 21 contract/maintenance tests, including archive integrity |
| `npm run test` | Passed: 27 frontend + 21 contract/maintenance tests |
| `npm run build` | Passed; existing large Plotly chunk warning |
| `npm run validate:coverage` | Passed, including surface gate; initial failures retained above |
| `npm run test:browser` | Passed: 10 desktop/mobile Chromium cases; mocked gateway suite, not live-backend proof |

Control validators and whitespace checks are recorded in the checkpoint. Browser plugin/skill is absent; repository Playwright is used as requested. UI flows cover route navigation, onboarding/role/split controls, keyboard tabs and transform outline, dialogs and mock-backed actions. These checks do not certify real grouped split execution or unavailable backend behavior.

Hosted baseline run 35501646027 at `ebeebfeb`: web and Julia passed; Debian was still executing `verify:release` at the latest read during preparation. Do not duplicate or interrupt it. New PR checks must be read at their actual head. Full no-skip Windows/Debian release closeout remains outside this slice.

Rollback: revert only the AKS-52 maintenance commit(s). No migration expected. Retain the original checkouts, PR #39, existing dependency PRs, signed tooling and immutable archives.
