# JuliaFlow Risk Register

Last updated: 2026-05-06

This register tracks active BRD delivery risks that should be burned down through thin, verified slices. It complements `docs/TODO.md`, `docs/brd-traceability.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md`.

## Current Risk Focus

Next implementation lane: production OIDC/RBAC hardening.
Near-term burn-down target: `R-SEC-001` through `R-SEC-004`.

| ID | Area | Risk | Impact | Likelihood | Mitigation | Next Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-SEC-001 | OIDC/JWT | External IdP/provider choice or JWKS behavior creates dependency ambiguity. | Production auth cannot be claimed safely. | Medium | Mockable OIDC/JWT validation now includes discovery/JWKS source resolution, `kid` lookup, HS256 key-rotation tests, and no-new-dependency RS256 RSA/JWKS signature verification with valid/tampered-token tests. | Add external live-IdP smoke evidence. | Partially mitigated |
| R-SEC-002 | Auth compatibility | Production auth changes break dev-token, disabled-auth, share-token, or workspace-token flows. | Existing demos/tests and BI viewer access regress. | Medium | OIDC mode is isolated behind `JULIAFLOW_AUTH_MODE=oidc`; existing dev-token and dashboard-token tests continue to pass. | Keep fallback/share-token regression tests in every auth hardening pass. | Mitigated for first slice |
| R-SEC-003 | RBAC persistence | Users/workspaces/roles/resource policies drift between contracts, file repo, and PostgreSQL-ready shapes. | Authorization behavior becomes inconsistent across storage backends. | Medium | Auth policy DTOs, file-backed persistence, PostgreSQL schema-ready tables, route enforcement, read-only Settings visibility, editable Settings role/resource-policy mutation UX, persisted user/workspace directory admin UX, active directory runtime enforcement, and directory self-lockout guard now exist. | Add PostgreSQL integration runtime evidence when DB credentials are available. | Partially mitigated |
| R-SEC-004 | Audit privacy | Audit query/admin UI leaks raw tokens, headers, or sensitive payload data. | Security/privacy incident risk. | Medium | Bounded redacted audit action query API exists; Settings now shows audit/policy/directory visibility, editable policy/directory mutations, and frontend tests cover redacted audit rendering plus update payloads without exposing secrets. | Broader local security review is complete; keep external IdP/PG smoke evidence before P0 completion. | Mitigated for policy/directory admin UI |
| R-STREAM-001 | Streaming | Kafka/NATS replay and exactly-once proof are not production-grade beyond fixture/window/checkpoint MVP. | Streaming P0 cannot be claimed complete. | Medium | Fixture duplicate-replay suppression, committed offsets, idempotency keys, sink transaction IDs, and Kafka/NATS adapter contract metadata now have Julia/contract coverage. | Add runtime Kafka/NATS clients, restart replay runner, production watermarking, and external sink transaction tests. | Partially mitigated |
| R-GPU-001 | GPU | Real CUDA/KernelAbstractions kernels need hardware/dependency validation beyond mock worker execution. | GPU P0 remains demo-grade. | Medium | Keep CPU fallback; add bounded kernel abstraction tests and optional hardware smoke path guarded by env. | CUDA/KA smoke evidence or skipped-hardware test contract with CPU fallback proof. | Open |
| R-OBJ-001 | Object storage | Provider-specific S3/GCS/Azure deployments and credentials are not proven despite provider-neutral remote adapter. | Production cloud materialization claim remains incomplete for real providers. | Medium | Treat provider deployment as hardening; add target-provider config and credential test only when provider is selected. | Provider-specific integration fixture or deployment manifest evidence. | Open |
| R-HUB-001 | Hub | Partner package sandboxing, artifact hashes, private/offline mirrors, and publish UX remain incomplete. | Governed Hub install/publish remains alpha. | Medium | Keep trust-policy gates; add hash verification, sandbox command fixtures, and private mirror tests in P1 lane. | Hub publish/install tests with hash, sandbox, and offline mirror fixtures. | Open |

## Risk Burn-Down Order

1. Production OIDC/RBAC: `R-SEC-001` to `R-SEC-004`.
2. Streaming production hardening: `R-STREAM-001`.
3. GPU production hardening: `R-GPU-001`.
4. Provider-specific object-store deployment: `R-OBJ-001` once provider/credential target exists.
5. Hub publish/install hardening: `R-HUB-001` in P1.
