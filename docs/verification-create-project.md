# Bounded Create Project verification

This increment starts from reviewed `4d71f1ec18cc3ab7551723fd7ba21f77fc26da31` and addresses the AKS-49 hydration acceptance within the user's explicit Explorer/Data approval. It does not complete the whole issue or the broader local v1. Linear readback on 2026-10-09 confirmed AKS-49 In Progress and its delayed/failed/rapid-switch/retry criteria; no tracker state was changed.

## Behavior and limits

- Inventory is independent of workflow availability; an empty backend renders no fixture project. Valid remembered selection and explicit selection survive loading; stale inventories/openings cannot override a new selection/creation.
- Create requires a name; optional description is persisted by the existing API. No modeling choices or filesystem folder are required. Save confirmation follows authorized GET of the exact returned ID.
- In-flight submissions are guarded synchronously. A rejected request preserves inputs; an uncertain response refreshes inventory and blocks repeat creation. Known creation with failed readback retries opening only. Optional folder selection/writing has separate feedback/retry.
- Imports use the resolved displayed project ID and existing source constraints. Late asynchronous results do not replace a switched project's view. Reopen uses persisted identity/reference/checksum/count/schema and labels unavailable profile/preview/code rather than inventing details or reimporting.
- Wada #83 uses Violet Blue `#40456A`, Olive Buff `#C1C494`, light gray canvas/white surfaces, and dark `#141622` canvas / `#202333` surface / `#ABB1E3` action. Inter ships locally through Fontsource, avoiding runtime font downloads. Selected navigation retains weight/border plus color; chart traces have labels and adapt text/surfaces to theme.

## Executable evidence

`apps/frontend/src/project-creation.test.tsx` covers empty inventory, distinct successive creations, duplicate clicks, uncertain/rejected POST, readback-only retry, remembered/cleared selection, late creation/opening, folder failure and refresh-versus-create ordering. Existing app/project-boundary tests retain their original behavior coverage while using explicit readback and imports for live data.

`npm run smoke:create-project` starts the existing gateway with `load_state` on a fresh repository (no project/workflow seeding), writes a CSV test input, drives the real browser UI, validates persisted checksums/count/schema, closes and restarts browser plus gateway against the same root, and verifies metadata equality with zero automatic import requests. It additionally tests actual successful creation with its response deliberately lost, inventory inspection without name matching/retry, and delayed import completion after selection changes. Injected transport/permission failures are recorded separately from real persistence proof.

The smoke retains its isolated data root and writes logs, screenshots and summary to `JULIAFLOW_CREATE_EVIDENCE_ROOT` or its temporary default. It stops owned servers/browser in `finally`. Runtime evidence is local and not committed. `verify:release` and local delivery now require this phase; full release validation requires a clean exact commit. No lint command is configured; TypeScript, build, unit/contracts, browser, control gates and diff checks are applicable.

Candidate dependencies were instantiated with Julia 1.12.7 using the existing flow; JSONSchema 1.5.0, MLJ 0.23.3 and MLJLinearModels 0.10.4 resolved within candidate compat and imported successfully. The generated local Manifest remains untracked. Playwright 1.64.0 and managed Chromium 156.0.8078.4 revision 1248 match Microsoft's versioned browser manifest; both managed full-binary/headless-shell probes passed.

Independent correctness/UI reviews identified and drove corrections to late inventories, repeated creations, selection races, unavailable profile claims, folder feedback, dark contrast and announced validation errors. Final review and aggregate results belong to the exact candidate evidence, not earlier counts.

Before the clean candidate gate, both independent reviewers approved this bounded increment after fixes. Focused execution passed 50 frontend tests, 65 Node tests (one existing platform skip), 10 desktop/mobile browser tests, TypeScript/build, and the real smoke's nine checks. The smoke also checks saved optional description, required-name announcement, Escape/focus restoration, mobile overflow and mobile theme switching. Full no-skip aggregate execution remains necessary on the committed candidate before publication.

## Tooling authorization and remaining acceptance

The installed Julia bundle's unchanged verifier returned `status: ok`, `signed: true`, catalog 2.1.0, manifest `996753585e98ac66877932c1569ee2301c9a19cd3e763a3a34860498c837fc6e`, release `97d0e341d80e952cd0eed6aa2b731545d1ebc96c226ff3c637f2621860cf496b`. Router binding: `954dd34d-f1b3-4122-ad7e-ca7626ac6fa0`; selected concurrent-systems and code-maintenance procedures. The user explicitly accepted unknown signer identity/installation history for this exact bundle/task at 2026-10-09 17:22 UTC. Hash/signature checks and trust settings were retained; independent historical provenance is not claimed.

Original approved board images were not accessible in this execution environment, so screenshots were reviewed against the specified palette/layout, without board-fidelity certification. Assistive-technology participant sessions, user and independent Data Analyst/Data Scientist acceptance remain later gates. GPU/compiler/wider local-v1 requirements remain unchanged. No merge, deployment or permission changes are authorized.
