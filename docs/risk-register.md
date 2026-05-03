# JuliaFlow Risk Register

Last updated: 2026-05-03

This register tracks active BRD delivery risks that should be burned down through thin, verified slices. It complements `docs/TODO.md`, `docs/brd-traceability.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md`.

## Current Risk Focus

Next implementation lane: production OIDC/RBAC hardening.
Near-term burn-down target: `R-SEC-001` through `R-SEC-004`.

| ID | Area | Risk | Impact | Likelihood | Mitigation | Next Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-SEC-001 | OIDC/JWT | External IdP/provider choice or JWKS behavior creates dependency ambiguity. | Production auth cannot be claimed safely. | Medium | Build mockable OIDC/JWT validation seam first; validate issuer/audience/expiry/roles with fixtures; avoid new dependency unless explicitly justified. | Gateway tests for valid, expired, wrong-issuer, wrong-audience, and missing-key tokens. | Open |
| R-SEC-002 | Auth compatibility | Production auth changes break dev-token, disabled-auth, share-token, or workspace-token flows. | Existing demos/tests and BI viewer access regress. | Medium | Preserve fallbacks behind explicit config; add regression tests for dev-token and published-dashboard token paths. | Passing Julia/frontend tests proving fallback and viewer compatibility. | Open |
| R-SEC-003 | RBAC persistence | Users/workspaces/roles/resource policies drift between contracts, file repo, and PostgreSQL-ready shapes. | Authorization behavior becomes inconsistent across storage backends. | Medium | Define contract-first DTOs; add file-backed repository tests; keep IDs/workspace boundaries explicit. | Contract tests plus gateway repository tests for persisted bindings/policies. | Open |
| R-SEC-004 | Audit privacy | Audit query/admin UI leaks raw tokens, headers, or sensitive payload data. | Security/privacy incident risk. | Medium | Redact sensitive fields at write/query boundary; bound query limits; test token/header absence. | Audit query tests for redaction, limit, and action/target/time filters. | Open |
| R-STREAM-001 | Streaming | Kafka/NATS replay and exactly-once proof are not production-grade beyond fixture/window/checkpoint MVP. | Streaming P0 cannot be claimed complete. | Medium | After auth lane, add adapter fixtures, deterministic replay runner, idempotent sink transaction tests, and watermark evidence. | Replay/exactly-once tests across restart and duplicate batches. | Open |
| R-GPU-001 | GPU | Real CUDA/KernelAbstractions kernels need hardware/dependency validation beyond mock worker execution. | GPU P0 remains demo-grade. | Medium | Keep CPU fallback; add bounded kernel abstraction tests and optional hardware smoke path guarded by env. | CUDA/KA smoke evidence or skipped-hardware test contract with CPU fallback proof. | Open |
| R-OBJ-001 | Object storage | Provider-specific S3/GCS/Azure deployments and credentials are not proven despite provider-neutral remote adapter. | Production cloud materialization claim remains incomplete for real providers. | Medium | Treat provider deployment as hardening; add target-provider config and credential test only when provider is selected. | Provider-specific integration fixture or deployment manifest evidence. | Open |
| R-HUB-001 | Hub | Partner package sandboxing, artifact hashes, private/offline mirrors, and publish UX remain incomplete. | Governed Hub install/publish remains alpha. | Medium | Keep trust-policy gates; add hash verification, sandbox command fixtures, and private mirror tests in P1 lane. | Hub publish/install tests with hash, sandbox, and offline mirror fixtures. | Open |

## Risk Burn-Down Order

1. Production OIDC/RBAC: `R-SEC-001` to `R-SEC-004`.
2. Streaming production hardening: `R-STREAM-001`.
3. GPU production hardening: `R-GPU-001`.
4. Provider-specific object-store deployment: `R-OBJ-001` once provider/credential target exists.
5. Hub publish/install hardening: `R-HUB-001` in P1.
