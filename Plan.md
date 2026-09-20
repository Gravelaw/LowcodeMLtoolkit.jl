# JuliaFlow Current Development Plan

Last reconciled: 2026-09-20, AKS-51.

## Current phase and evidence

The priority remains Local-First GA Proof and the AKS-36 DataScienceProject architecture lane. The governed BRD is `business-requirements-v0.3.0.md` (internal baseline v0.4.1). Local CPU operation, managed files, explainability, reproducibility, and backup/restore are core; provider/cloud integrations are optional compatibility work.

The bounded RC implementation exists on draft [PR #40](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/40). At the last audited head `a70ea67`, web and Julia checks passed but the hosted Debian release gate failed because the expected Playwright browser was absent. Historical Windows success belongs to its recorded commit, not every subsequent change. AKS-36 remains In Progress in the 2026-09-20 Linear readback.

Implemented boundaries include the project contracts, repository/routes, validation locks, typed jobs, managed-file controls, bounded model/lifecycle evidence, and project-backed frontend surfaces. Their existence does not close acceptance, review, merge, or platform-evidence gaps. [TODO](docs/TODO.md), [risks](docs/risk-register.md), and [traceability](docs/brd-traceability.md) retain those distinctions.

## Ordered work

1. **AKS-51 repository maintenance:** preserve active work and immutable evidence; remove only proven redundant refs/output; consolidate guidance; enforce committed-PR control-document checks; repair dependency/browser setup ordering. Deliver as a separate reviewable branch based on the current PR #40 head.
2. **AKS-36 / AKS-50 release proof:** after reviewing the setup repair, obtain no-skip Windows and hosted Debian evidence bound to the same candidate commit/tree. Resolve required AKS-38 reviews and linked acceptance gaps before merge or readiness claims.
3. **Child-ticket reconciliation:** verify AKS-40 through AKS-49 criteria against code, negative-path tests, domain review, and browser/persona evidence. Linear currently lists these as In Progress; cleanup must not promote them to Done.
4. **Subsequent feature depth:** richer preprocessing/tuning/model families, broader drift semantics, and new connectors require a separately prioritized issue and explicit product evidence. Do not infer them from bounded RC results.

PR #39 remains an unmerged fallback until PR #40 merges, consistent with the prior delivery plan. AKS-37 and AKS-39 are reported Done in Linear; this maintenance pass does not independently re-certify their delivery history.

## Constraints and next action

Preserve Arrow IPC and TOML boundaries, contract-first changes, explicit CPU fallback, current auth/import controls, and no fixture substitution in release/local-appliance mode. Database, watched-folder, USB, and cloud dataset source execution are not enabled by the current bounded proof. Compatible CUDA/multi-GPU success is conditional and unclaimed. Core logic retains the NASA/JPL Power of 10 requirement.

The next bounded action is review of AKS-51 with local checks and hosted results reported separately. No merge, tag, version bump, prerelease, deployment, or branch-protection change is part of housekeeping. Use [AGENTS.md](AGENTS.md) for skill routing and proportional verification; [tooling guidance](docs/agent-tooling.md) explains baseline-aware checks.

## Historical evidence

The previous 600-plus-line plan and accumulated completed-slice narratives are preserved byte-for-byte in [the 2026-09-20 archive](docs/archive/2026-09-20/README.md), with source commit and SHA-256 manifest. Historical milestones remain in TODO and traceability; their old runtime paths and status statements are not current readiness evidence.
