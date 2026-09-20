# JuliaFlow TODO

Last reconciled: 2026-09-20 (AKS-38).

Linear owns acceptance and delivery status. Checked items below preserve historical bounded-slice claims and their 46 existing traceability checks; they do not certify the current PR head. Full descriptions remain in [the immutable snapshot](archive/2026-09-20/TODO.md).

## Active acceptance gaps

- [ ] **Approved remediation and design split:** AKS-55, the managed-path AKS-41 patch, AKS-56 and AKS-53 are In Review in draft PRs #50 through #53. Their exact heads have passing hosted web/Julia checks. The Debian gates failed at local-bootstrap startup on #52 and an incomplete migration-smoke registry fixture on #53; the fixture correction is a separate AKS-56 follow-up, and full release proof remains open. AKS-54 now persists and verifies split membership across preparation, training, tuning and final evaluation; focused and integration verification is underway on its own branch. See [remediation evidence](blocker-remediation-2026-09-20.md). Design direction selection and final design approval are separate gates; frontend implementation remains frozen.

- [ ] **AKS-52 dependency remediation:** compatible targets from PRs #41–#46 and aligned Vitest/coverage pass clean audit and local gates; review/merge and exact-head hosted readback remain open. See [evidence](dependency-remediation-2026-09-20.md).
- [ ] **AKS-53 / AKS-54 review blockers:** reject synthetic analysis success in release/local-appliance mode; enforce declared split membership and final-test isolation before deeper feature development. Product repairs are separate follow-ups.
- [ ] **AKS-55 / AKS-56 review blockers:** constrain default browser mutation authority and align resource-evidence contracts with runtime payload validation. See [current review and criterion matrix](restart-review-2026-09-20.md) and [threat model](restart-threat-model-2026-09-20.md).
- [ ] **AKS-37 / AKS-39 delivery:** corrected from Done to In Review; their substrate is in unmerged PR #40. Preserve implementation evidence and close only after composite Done requirements.

- [ ] **AKS-51 housekeeping:** review/merge the cleanup and control-validator changes; report hosted checks and local retention exceptions. Preserve user edits, tooling evidence, runtime environments, and unmerged work.
- [ ] **AKS-36 / AKS-50 RC closeout:** obtain clean no-skip Windows and hosted Debian release summaries bound to the same candidate head, resolve required reviews under AKS-38, and reconcile child criteria, blockers, merge, and evidence before Done. The last observed PR #40 head was `a70ea67`; web/Julia passed and the Debian browser phase failed. No new readiness claim.
- [ ] **AKS-38 reviews:** current sequential agent review is recorded for contracts, security, ML validity, MLOps and frontend/personas. Review the report and resolve/explicitly accept blockers; human approval is not claimed.
- [ ] **AKS-40 / AKS-41 boundaries:** reconcile the verified module extraction and managed-file validation with remaining security acceptance, folder-grant/redaction requirements, and review evidence. Database, watched-folder, USB, and cloud source execution remain out of scope unless separately prioritized.
- [ ] **AKS-42 / AKS-43 / AKS-44 validity and jobs:** reconcile schema/split locks, train-only fit/apply, validation-only tuning, typed execution evidence, statistical EDA, and final-test negative paths against their acceptance criteria.
- [ ] **AKS-45 / AKS-46 lifecycle:** reconcile registry, drift, rollback/retraining, final evaluation, prediction export, and local deploy evidence. Broader model families/preprocessing/tuning/drift require separately scoped proof.
- [ ] **AKS-47 / AKS-48 / AKS-49 frontend:** reconcile project state, Dataset Wizard, guided no-code flow, accessibility, and final browser/persona acceptance.
- [ ] **Hardware claims:** CPU fallback is explicit; successful CUDA/multi-GPU execution requires compatible real hardware evidence. Simulation or a requested GPU lane is not hardware proof.

PR #39 remains an unmerged fallback until PR #40 merges, per the pre-existing RC plan. Provider/cloud compatibility remains optional. No merge, tag, prerelease, or deployment is authorized by this checklist.

## Historical bounded-slice checklist

## P0 — Required Before Phase 1 / Alpha Complete

1. [x] Base node pack first reality pass: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] External-ref materialization seam: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Production Arrow/DataFrames materialization: historical bounded-slice evidence in `docs/brd-traceability.md`.
4. [x] BI chart-data seam: historical bounded-slice evidence in `docs/brd-traceability.md`.
5. [x] BI published artifact datasets: historical bounded-slice evidence in `docs/brd-traceability.md`.
6. [x] BI semantic/cache/export slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
7. [x] BI live/render UX slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
8. [x] BI interaction hardening slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
9. [x] BI viewer polish follow-up: historical bounded-slice evidence in `docs/brd-traceability.md`.
10. [x] Auth/RBAC thin contract slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
11. [x] Production OIDC/RBAC hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
12. [x] Streaming fixture/window/checkpoint MVP: historical bounded-slice evidence in `docs/brd-traceability.md`.
13. [x] Streaming production hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
14. [x] GPU execution MVP: historical bounded-slice evidence in `docs/brd-traceability.md`.

## P1 — Next Alpha Hardening

1. [x] Hub publish/install hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] Components/control-flow contracts: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Observability/perf gates: historical bounded-slice evidence in `docs/brd-traceability.md`.

## P2 — Beta/GA Foundation

1. [x] Deployment hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] BRD traceability automation: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Node-library scale roadmap: historical bounded-slice evidence in `docs/brd-traceability.md`.

## Current Development Phase — Local-First GA Proof / Explainable Local Appliance

1. [x] BRD local-first strategy refresh: historical bounded-slice evidence in `docs/brd-traceability.md`.
2. [x] Agent prompt hygiene: historical bounded-slice evidence in `docs/brd-traceability.md`.
3. [x] Local appliance bootstrap proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
4. [x] Local data estate proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
5. [x] Local metadata/database proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
6. [x] Local hardware runtime proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
7. [x] Explainability/model evidence proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
8. [x] Offline Hub proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
9. [x] Mock-aligned BRD product surface refresh: historical bounded-slice evidence in `docs/brd-traceability.md`.
10. [x] Academic reproducibility workflow: historical bounded-slice evidence in `docs/brd-traceability.md`.
11. [x] Backup/restore and migration proof: historical bounded-slice evidence in `docs/brd-traceability.md`.
12. [x] Frontend module expansion / BI viewer row-search slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
13. [x] Frontend module expansion follow-up: historical bounded-slice evidence in `docs/brd-traceability.md`.
14. [x] Mock-aligned local product workflow vertical: historical bounded-slice evidence in `docs/brd-traceability.md`.
15. [x] Backend-backed Data and Transform product actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
16. [x] Backend-backed ML Studio experiment actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
17. [x] Backend-backed Models registry actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
18. [x] Backend-backed Visualize checkpoint/export actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
19. [x] Backend-backed Deploy packaging actions: historical bounded-slice evidence in `docs/brd-traceability.md`.
20. [x] Mockup-aligned local-only UI redesign and browser automation: historical bounded-slice evidence in `docs/brd-traceability.md`.
21. [x] AKS-5 Stage 3 save/run/monitor lifecycle first slice: historical bounded-slice evidence in `docs/brd-traceability.md`.
22. [x] AKS-5 Stage 3 dashboard/explainability evidence binding: historical bounded-slice evidence in `docs/brd-traceability.md`.
23. [x] AKS-5 Stage 5 release verification closure: historical bounded-slice evidence in `docs/brd-traceability.md`.
24. [x] AKS-13 live workflow metadata recovery: historical bounded-slice evidence in `docs/brd-traceability.md`.
25. [x] Explorer/Data/Transform mock parity and interactive local analytics: historical bounded-slice evidence in `docs/brd-traceability.md`.
26. [x] AKS-29 through AKS-35 parity hardening: historical bounded-slice evidence in `docs/brd-traceability.md`.
