# Agent tooling and maintenance

Project policy lives in [AGENTS.md](../AGENTS.md). Skills supply procedures, not scope or permission.

## Discovery and integrity

Use the host's installed skill catalog. JuliaFlow needs the nine-skill Julia engineering runtime, and GitHub operations for ordinary backend delivery. React, browser testing, or scoped security skills are loaded only when the changed surface warrants them. Other installed skills need not be uninstalled or loaded for this project.

For Julia, resolve the installed `julia-route-engineering-work` skill and its runtime root, then follow its external-trust integrity check before routing. The shared contract is `shared/common-engineering-contract.md` relative to that runtime. Leaf `references/common-engineering-contract.md` files are generated direct-invocation copies. Do not edit a signed runtime, vendor arbitrary individual skill folders, or bootstrap trust from the package being verified.

Do not encode account names, OAuth scopes, tool counts, plugin cache versions, or staging directories in project rules. Discover current tools and report missing/unauthorized capabilities. For pi/OpenCode users, retain the complete separately distributed harness bundle and verify it independently; it is not a JuliaFlow product dependency.

## Independent local security review

Use this project procedure when a scoped installed security workflow's required
capabilities are unavailable. Discover capabilities before choosing the method,
record the missing capability, and keep the plugin's own preflight and storage
rules intact whenever that plugin is invoked. Missing scan tooling does not
waive substantive review. This procedure produces an independent local review,
not a canonical Codex Security scan or plugin clearance.

1. Identify the exact repository, baseline, candidate commit/tree (or checksummed
   uncommitted patch), and changed-file inventory. Keep the reviewed input fixed;
   inspect deleted source at the baseline and supporting code when relevant.
2. Record a scoped threat model: assets, actors, entry points, trust boundaries,
   realistic abuse cases, assumptions, and exclusions. Account for every changed
   source file and explain any excluded non-source changes.
3. Review applicable dependency/supply-chain, authentication/authorization,
   paths/files/symlinks/races, process execution/generated code, serialization and
   deserialization, persistence/concurrency, and export/redaction boundaries.
   Follow changed behavior into relevant dependencies without turning the review
   into an unrelated repository audit.
4. Validate suspected findings with reproducible negative and legitimate-control
   tests in isolated, authorized environments. Retain exact commands, input
   identities, results, skips, limitations, and evidence. Do not weaken assertions
   or substitute fixtures for actual execution claims.
5. Require a reviewer separate from the implementation author: a human or an
   explicitly authorized review agent. Record reviewer identity, method, exact
   reviewed revision/patch, coverage and gaps, findings, dispositions, and verdict.
   Author self-audit and automated test success are not independent approval.
   Delegation must be explicitly authorized by the user or applicable instructions;
   this procedure alone does not authorize spawning review agents.
6. Track confirmed defects as GitHub issues before committing to remediation scope.
   Resolve each finding by a fix and regression evidence, evidence-backed
   rejection, or explicit authorized acceptance. Review relevant changes again
   after fixes and bind final clearance to the final candidate. Do not label
   incomplete coverage or an unresolved finding as approval.

Keep local review records and ordinary test evidence identifiable by method and
candidate; never fabricate plugin scan IDs, canonical reports, or scan artifacts.
Plugin-managed scan artifacts must still use the plugin's prescribed storage.
Project review does not replace required submitted GitHub reviews or administrative
merge requirements. Development publication, milestone acceptance, merge, and
release remain separate gates under [AGENTS.md](../AGENTS.md).

## Superseded guidance

The old `juliaflow-control-loop`, `juliaflow-local-first-appliance`, `juliaflow-julia-development`, `juliaflow-frontend-development`, and `juliaflow-provider-deployment` files are not present in the inspected checkout or global skill roots. Their historical references are retained only in the [archive](archive/2026-09-20/README.md). Current project rules plus the installed domain skills replace that routing.

The GitHub skill was locally authored; installation provenance is a tooling-maintainer concern. Neither its presence nor an old provenance claim establishes current connector authentication.

## Spec and archives

Requirements live in `docs/spec/`; a requirement change edits the spec in the same PR. Archived snapshots under `docs/archive/` are never edited; their bytes are checked by `tests/contracts/control-doc-archive.test.mjs`, included in contract tests.

## Cleanup boundaries

Preserve active worktrees, patches, detached commits, signed packages, and evaluation evidence before removing anything. Use explicit path inventories and SHA recovery records for branch deletions. A clean Git status is insufficient for retiring a worktree containing ignored evidence or environments. Keep runtime depots and optional product dependencies until a separate measured change proves they can be removed.
