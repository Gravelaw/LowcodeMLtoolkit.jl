# JuliaFlow Current Development Plan

Last reconciled: 2026-09-20, AKS-38 restart review.

AKS-55, the managed-path AKS-41 patch, AKS-56, AKS-53 and AKS-54 are locally verified and In Review in draft PRs #50 through #54. Hosted web/Julia checks pass on #50-#53; #54 web passes while Julia/Debian verification remains open. Debian failed at local-bootstrap startup on #52 and an incomplete migration-smoke registry fixture on #53. The separate AKS-56 fixture correction passes local migration smoke; fresh hosted platform proof and human review remain open. AKS-54 reuses persisted membership across preparation, training, tuning and final evaluation, with 1,492 final gateway/boundary assertions and five live-browser scenarios passing. The approved backend remediation sequence is implemented; the next bounded action is review and same-head verification, followed by the remaining lifecycle and persona acceptance. [Remediation evidence](docs/blocker-remediation-2026-09-20.md) records each bounded change. Development stays in the current task at Astra Medium; a separate Astra Extra High task owns design concepts/mockups only (Penpot authorized after Figma quota). All frontend implementation is frozen until explicit final design approval. No merge or release is authorized.

Dependency preparation now stacks on AKS-51: [AKS-52 evidence](docs/dependency-remediation-2026-09-20.md) records compatible advisory fixes, a clean audit, and verification repairs. Review/merge remains required. Current-code AKS-38 review has identified AKS-53 (synthetic analysis fallback) and AKS-54 (split membership/final-test isolation) as product follow-ups before deeper feature development; those dependency/review PRs contain no product repair or release claim.

The [current-code review and acceptance matrix](docs/restart-review-2026-09-20.md) supersedes June 21 current-state conclusions and adds AKS-55 (default local browser authority) and AKS-56 (job contract consistency). Decision: restart bounded remediation; keep deeper persona development and readiness claims gated by these findings and remaining AKS-41/45/46/48/49/50 evidence. Review is agent-authored, not human approval.

## Current phase and evidence

The priority remains Local-First GA Proof and the AKS-36 DataScienceProject architecture lane. The governed BRD is `business-requirements-v0.3.0.md` (internal baseline v0.4.1). Local CPU operation, managed files, explainability, reproducibility, and backup/restore are core; provider/cloud integrations are optional compatibility work.

The bounded RC implementation exists on draft [PR #40](https://github.com/Gravelaw/LowcodeMLtoolkit.jl/pull/40). At the last audited head `a70ea67`, web and Julia checks passed but the hosted Debian release gate failed because the expected Playwright browser was absent. Historical Windows success belongs to its recorded commit, not every subsequent change. AKS-36 remains In Progress in the 2026-09-20 Linear readback.

Implemented boundaries include the project contracts, repository/routes, validation locks, typed jobs, managed-file controls, bounded model/lifecycle evidence, and project-backed frontend surfaces. Their existence does not close acceptance, review, merge, or platform-evidence gaps. [TODO](docs/TODO.md), [risks](docs/risk-register.md), and [traceability](docs/brd-traceability.md) retain those distinctions.

## Ordered work

1. **AKS-51 repository maintenance:** preserve active work and immutable evidence; remove only proven redundant refs/output; consolidate guidance; enforce committed-PR control-document checks; repair dependency/browser setup ordering. Deliver as a separate reviewable branch based on the current PR #40 head.
2. **AKS-36 / AKS-50 release proof:** after reviewing the setup repair, obtain no-skip Windows and hosted Debian evidence bound to the same candidate commit/tree. Resolve required AKS-38 reviews and linked acceptance gaps before merge or readiness claims.
3. **Child-ticket reconciliation:** verify AKS-40 through AKS-49 criteria against code, negative-path tests, domain review, and browser/persona evidence. Linear currently lists these as In Progress; cleanup must not promote them to Done.
4. **Subsequent feature depth:** richer preprocessing/tuning/model families, broader drift semantics, and new connectors require a separately prioritized issue and explicit product evidence. Do not infer them from bounded RC results.

PR #39 remains an unmerged fallback until PR #40 merges. AKS-37 and AKS-39 were corrected to In Review after their Done comments were verified to rely on unmerged PR #40. Implementation evidence is retained; merge and complete acceptance remain open.

## Constraints and next action

Preserve Arrow IPC and TOML boundaries, contract-first changes, explicit CPU fallback, current auth/import controls, and no fixture substitution in release/local-appliance mode. Database, watched-folder, USB, and cloud dataset source execution are not enabled by the current bounded proof. Compatible CUDA/multi-GPU success is conditional and unclaimed. Core logic retains the NASA/JPL Power of 10 requirement.

The next bounded actions are review of AKS-51/52 and the current AKS-38 report, then the approved AKS-55/41, AKS-56, AKS-53, AKS-54 sequence, lifecycle and real-file persona acceptance, and finally AKS-50 same-head platform closeout. Logical authorized integration order is #40 → #47 → #48 → the AKS-38 review PR, with blockers resolved in the chosen candidate before #40 can merge. No merge or release is authorized here. Use [AGENTS.md](AGENTS.md) and [tooling guidance](docs/agent-tooling.md) for verification.

## Historical evidence

The previous 600-plus-line plan and accumulated completed-slice narratives are preserved byte-for-byte in [the 2026-09-20 archive](docs/archive/2026-09-20/README.md), with source commit and SHA-256 manifest. Historical milestones remain in TODO and traceability; their old runtime paths and status statements are not current readiness evidence.
