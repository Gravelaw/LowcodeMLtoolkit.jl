# Agent tooling and maintenance

Project policy lives in [AGENTS.md](../AGENTS.md). Skills supply procedures, not scope or permission.

## Discovery and integrity

Use the host's installed skill catalog. JuliaFlow needs the nine-skill Julia engineering runtime, GitHub operations, and Linear operations for ordinary backend delivery. React, browser testing, or scoped security skills are loaded only when the changed surface warrants them. Other installed skills need not be uninstalled or loaded for this project.

For Julia, resolve the installed `julia-route-engineering-work` skill and its runtime root, then follow its external-trust integrity check before routing. The shared contract is `shared/common-engineering-contract.md` relative to that runtime. Leaf `references/common-engineering-contract.md` files are generated direct-invocation copies. Do not edit a signed runtime, vendor arbitrary individual skill folders, or bootstrap trust from the package being verified.

Do not encode account names, OAuth scopes, tool counts, plugin cache versions, or staging directories in project rules. Discover current tools and report missing/unauthorized capabilities. For pi/OpenCode users, retain the complete separately distributed harness bundle and verify it independently; it is not a JuliaFlow product dependency.

## Superseded guidance

The old `juliaflow-control-loop`, `juliaflow-local-first-appliance`, `juliaflow-julia-development`, `juliaflow-frontend-development`, and `juliaflow-provider-deployment` files are not present in the inspected checkout or global skill roots. Their historical references are retained only in the [archive](archive/2026-09-20/README.md). Current project rules plus the installed domain skills replace that routing.

GitHub and Linear skills were locally authored; installation provenance is a tooling-maintainer concern. Neither their presence nor an old provenance claim establishes current connector authentication.

## Control-document gate

`npm run validate:control-doc-sync -- --base <base-ref>` combines the merge-base-to-HEAD diff with staged, unstaged, and relevant untracked changes. GitHub PR/push events supply the baseline automatically; an unavailable baseline is an error. Other workflows may explicitly supply `JULIAFLOW_CONTROL_DOC_BASE`. A new branch/tag push with an all-zero prior SHA must provide a deliberate baseline; it cannot silently pass a working-tree-only check.

Product/dependency changes require the five current control documents. Maintenance scripts, tests, CI, and ignore configuration require tracker/checkpoint evidence. BRD changes additionally require traceability. Documentation-only corrections do not require invented status updates. The validator always requires the governed files to exist and never ignores a tracked path because it looks like local output.

Designated local tooling/cache prefixes are excluded only for untracked files. Images under `docs/images/` remain visible. Run the BRD gate after TODO/traceability changes. Archive hashes are checked by `tests/contracts/control-doc-archive.test.mjs`, included in contract tests.

## Cleanup boundaries

Preserve active worktrees, patches, detached commits, signed packages, and evaluation evidence before removing anything. Use explicit path inventories and SHA recovery records for branch deletions. A clean Git status is insufficient for retiring a worktree containing ignored evidence or environments. Keep runtime depots and optional product dependencies until a separate measured change proves they can be removed.
