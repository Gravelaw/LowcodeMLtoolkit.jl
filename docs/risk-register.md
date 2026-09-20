# JuliaFlow Risk Register

Last reconciled: 2026-09-20, AKS-51. Linear owns acceptance, assignees, and status; the project maintainer owns unresolved scope/retention decisions. Historical mitigation claims are preserved in the [snapshot](archive/2026-09-20/risk-register.md), not upgraded by this rewrite.

## Active decisions and acceptance risks

AKS-55 remediation now covers launcher credentials, strict runtime fallback rejection, REST origin checks and the previously unguarded realtime upgrade/RPC path. Gateway, auth/realtime, contract, frontend and bootstrap checks pass; candidate review and all three live-browser scenarios pass; hosted checks and delivery review remain open in [the remediation report](blocker-remediation-2026-09-20.md). The shared realtime SDK now supports optional upgrade-protocol credentials, while REST uses its existing token interface. Neither path requires frontend application edits. The approved frontend freeze prevents design work from changing application behavior before final design confirmation.

| Risk | Issue / decision | Current mitigation and remaining gate |
| --- | --- | --- |
| R-DEPENDENCY-001 | AKS-52 | Targeted candidate clean install/audit reports zero findings, versus eight baseline package entries / ten GitHub default-branch alerts. Review/merge and hosted evidence remain open; see dependency remediation report. |
| R-RESTART-001 | AKS-53 / AKS-54 / AKS-55 / AKS-56 | Current review records synthetic analysis fallback, fraction-only split execution/final-test inspection, permissive startup authority, and TS/OpenAPI job requiredness mismatch. Resolve or explicitly accept blockers before deeper feature work; positive checks do not close them. |
| R-CI-RELEASE-001 | AKS-36 / AKS-50 | At audited head `a70ea67`, Debian release failed at browser launch after web/Julia passed. AKS-51 installs locked dependencies before browser binaries in both workflows; exact-head hosted and Windows no-skip proof remains required. |
| R-DOC-001 / R-DOC-002 | AKS-51 | Long repeated histories and a working-tree-only validator obscured committed gaps. Current summaries link hash-verified snapshots; baseline-aware tests enforce committed changes. Review/merge and hosted readback remain open. |
| R-AGENT-001 | AKS-51 | Dated staging pointers and five absent skills are replaced by installed-skill discovery. Preserve the signed nine-skill runtime and external trust policy; signature integrity is not task authorization. |
| R-TRUST-LOCAL-001 | AKS-41 / AKS-55 | Raw-file realpath checks and configured-origin rejection exist; managed read/write child-link confinement and default startup auth/origin authority remain qualified by the current threat model. Folder grants and full backup/redaction acceptance remain open. |
| R-DS-001 / R-ARCH-DS-001 / R-CONTRACT-DS-001 | AKS-36 / AKS-38 | The bounded project substrate exists. Verify remaining persona/design criteria, compatible contracts, domain reviews, and delivery evidence before workstation-readiness claims. |
| R-ML-VALIDITY-001 / R-MLOPS-001 | AKS-42 through AKS-46 | Preserve train/validation/final-test separation, frozen transforms, bounded model evidence, lifecycle gates, and negative cases. Richer model/tuning/drift semantics need separately scoped evidence. |
| R-GATEWAY-MOD-001 | AKS-40 | Presentation and project-route extraction has historical executable evidence; final criterion/review/delivery reconciliation remains open. Do not remove modules or tests as housekeeping. |
| R-FE-001 | AKS-47 through AKS-49 | Preserve route shell, project state, runtime config, selectors, and coverage; final guided workflow/accessibility/browser acceptance remains open. |
| R-GPU-001 / R-HW-001 | Hardware-gated decision | CPU fallback remains explicit. Simulation does not prove CUDA; multi-GPU claims need at least two visible compatible physical devices and required smoke evidence. |
| R-CI-001 | Maintainer | Retired inbound workstation webhooks remain retired; use GitHub-native summaries or bounded polling. |
| R-CLEANUP-001 | AKS-51 | Original changes/refs are backed up. Signed source, evaluation custody, ignored runtime evidence, and unmerged branches are retained. Forced Git-temp deletion was rejected by automatic approval review; do not retry through another mechanism. |

## Retained risk inventory

Every original risk ID remains below so historical mitigations can be located. Status reflects the pre-cleanup register and is not a fresh release certification; active qualifications above take precedence. Full impact, rationale, mitigation, and acceptance history remain in the immutable snapshot.

| ID | Area | Historical status |
| --- | --- | --- |
| R-LOCAL-001 | Bootstrap | Mitigated for the recorded bounded slice |
| R-DATA-001 | Local data estate | Mitigated for the recorded bounded slice |
| R-DB-001 | Local metadata | Mitigated for the recorded bounded slice |
| R-HW-001 | Local hardware | Mitigated for the recorded bounded slice |
| R-XAI-001 | Explainability | Mitigated for the recorded bounded slice |
| R-OFFLINE-001 | Offline Hub | Mitigated for the recorded bounded slice |
| R-PRODUCT-001 | Product surface | Mitigated for the recorded bounded slice |
| R-DS-001 | Data science workflow | Open |
| R-ARCH-DS-001 | Persona architecture | Open |
| R-CONTRACT-DS-001 | Persona contracts | Open |
| R-ML-VALIDITY-001 | ML validity | Open |
| R-TRUST-LOCAL-001 | Local trust boundary | Open |
| R-MLOPS-001 | MLOps lifecycle | Open |
| R-GATEWAY-MOD-001 | Gateway modularity | Open |
| R-REPRO-001 | Academic reproducibility | Mitigated for the recorded bounded slice |
| R-BACKUP-001 | Backup/restore | Mitigated for the recorded bounded slice |
| R-DOC-002 | Documentation hygiene | Mitigated for the recorded bounded slice |
| R-AGENT-001 | Agent routing | Mitigated for the recorded bounded slice |
| R-SEC-001 | OIDC/JWT | Mitigated for the recorded bounded slice |
| R-SEC-002 | Auth compatibility | Mitigated for the recorded bounded slice |
| R-SEC-003 | RBAC persistence | Mitigated for the recorded bounded slice |
| R-SEC-004 | Audit privacy | Mitigated for the recorded bounded slice |
| R-STREAM-001 | Streaming | Mitigated for the recorded bounded slice |
| R-GPU-001 | GPU | Deferred to final hardware-gated phase |
| R-OBS-001 | Observability/perf | Mitigated for the recorded bounded slice |
| R-OBJ-001 | Object storage | Optional |
| R-WC-001 | Components/control-flow | Mitigated for the recorded bounded slice |
| R-HUB-001 | Hub | Mitigated for the recorded bounded slice |
| R-DEP-001 | Deployment | Optional |
| R-FE-001 | Frontend scale | Mitigated for the recorded bounded slice |
| R-RUNTIME-001 | Julia runtime depth | Mitigated for the recorded bounded slice |
| R-DOC-001 | Control docs | Mitigated for the recorded bounded slice |
| R-CI-001 | CI workflow monitoring | Open |

## Scope boundaries

Keep local bootstrap, managed data estate, file/PostgreSQL metadata, local model/explainability evidence, offline Hub, reproducibility, and backup/restore. Metadata support is not database dataset-source execution. Object-store/provider production overlays and enterprise identity remain conditional compatibility work. Keep all previously designed success/failure/rejection coverage.

Update this register when a risk or accepted mitigation changes; maintenance-only edits need no invented new product risk. Link new findings to Linear before expanding committed scope. Do not classify an issue Blocked solely because CI failed, or Done solely because a PR merged.
