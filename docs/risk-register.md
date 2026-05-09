# JuliaFlow Risk Register

Last updated: 2026-05-09

This register tracks active BRD delivery risks that should be burned down through thin, verified slices. It complements `docs/TODO.md`, `docs/brd-traceability.md`, `docs/project-tracker.md`, and `docs/checkpoint-log.md`.

## Current Risk Focus

Next implementation lane: GPU real-compute decision/gated smoke if CUDA/KernelAbstractions dependency and hardware approval exists; otherwise unblocked P1 components/control-flow contracts or observability/perf gates.
Near-term burn-down target: `R-GPU-001` only after dependency/hardware approval; otherwise continue P1 controls or observability gates. Auth live-IdP/PostgreSQL, streaming Kafka/NATS, and live sink evidence remain credential/dependency-gated.

| ID | Area | Risk | Impact | Likelihood | Mitigation | Next Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-SEC-001 | OIDC/JWT | External IdP/provider choice or JWKS behavior creates dependency ambiguity. | Production auth cannot be claimed safely. | Medium | Mockable OIDC/JWT validation now includes discovery/JWKS source resolution, `kid` lookup, HS256 key-rotation tests, and no-new-dependency RS256 RSA/JWKS signature verification with valid/tampered-token tests. | Add external live-IdP smoke evidence. | Partially mitigated |
| R-SEC-002 | Auth compatibility | Production auth changes break dev-token, disabled-auth, share-token, or workspace-token flows. | Existing demos/tests and BI viewer access regress. | Medium | OIDC mode is isolated behind `JULIAFLOW_AUTH_MODE=oidc`; existing dev-token and dashboard-token tests continue to pass. | Keep fallback/share-token regression tests in every auth hardening pass. | Mitigated for first slice |
| R-SEC-003 | RBAC persistence | Users/workspaces/roles/resource policies drift between contracts, file repo, and PostgreSQL-ready shapes. | Authorization behavior becomes inconsistent across storage backends. | Medium | Auth policy DTOs, file-backed persistence, PostgreSQL schema-ready tables, route enforcement, read-only Settings visibility, editable Settings role/resource-policy mutation UX, persisted user/workspace directory admin UX, active directory runtime enforcement, and directory self-lockout guard now exist. | Add PostgreSQL integration runtime evidence when DB credentials are available. | Partially mitigated |
| R-SEC-004 | Audit privacy | Audit query/admin UI leaks raw tokens, headers, or sensitive payload data. | Security/privacy incident risk. | Medium | Bounded redacted audit action query API exists; Settings now shows audit/policy/directory visibility, editable policy/directory mutations, and frontend tests cover redacted audit rendering plus update payloads without exposing secrets. | Broader local security review is complete; keep external IdP/PG smoke evidence before P0 completion. | Mitigated for policy/directory admin UI |
| R-STREAM-001 | Streaming | Kafka/NATS replay and exactly-once proof are not production-grade beyond fixture/window/checkpoint MVP. | Streaming P0 cannot be claimed complete. | Medium | Fixture duplicate-replay suppression, committed offsets, idempotency keys, sink transaction IDs/state, Kafka/NATS adapter contract metadata, fixture restart replay from persisted committed offsets, and policy-aware monotonic watermark state now have Julia/contract coverage. | Add runtime Kafka/NATS clients and live external sink transaction backend evidence; live broker restart proof remains dependency/provider-gated. | Partially mitigated |
| R-GPU-001 | GPU | Real CUDA/KernelAbstractions kernels need hardware/dependency validation beyond mock worker execution. | GPU P0 remains demo-grade. | Medium | CPU fallback remains available; no-new-dependency prep now records deterministic placement, requested/selected device, fallback reason, scheduler policy, and worker isolation/capacity metadata with Julia/contract evidence plus full local verification and bounded GPU-worker smoke. | CUDA/KA smoke evidence or skipped-hardware test contract with CPU fallback proof after dependency/hardware approval. | Partially mitigated |
| R-OBJ-001 | Object storage | Provider-specific S3/GCS/Azure deployments and credentials are not proven despite provider-neutral remote adapter. | Production cloud materialization claim remains incomplete for real providers. | Medium | Treat provider deployment as hardening; add target-provider config and credential test only when provider is selected. | Provider-specific integration fixture or deployment manifest evidence. | Open |
| R-HUB-001 | Hub | Partner package sandboxing, artifact hashes, private/offline mirrors, and publish UX needed hardening beyond initial trust shell. | Governed Hub install/publish can drift without artifact and mirror metadata checks. | Medium | Manifest now carries SHA-256-shaped artifact hashes, sandbox command metadata, and private/offline mirror refs with local-file mirror refs rejected; partner trust/compatibility blockers, gateway publish registration, frontend publish UX, and Julia/frontend/contract tests are in place. | Future evidence: execute sandbox commands, verify downloaded artifacts against hashes, and test real private registry mirrors. | Mitigated for Alpha publish/install metadata |

## Risk Burn-Down Order

1. Production OIDC/RBAC: `R-SEC-001` to `R-SEC-004`.
2. Streaming production hardening: `R-STREAM-001`.
3. GPU production hardening: `R-GPU-001` real CUDA/KernelAbstractions slice after dependency/hardware gate.
4. Provider-specific object-store deployment: `R-OBJ-001` once provider/credential target exists.
5. Hub publish/install metadata hardening: `R-HUB-001` mitigated for Alpha; revisit for real sandbox execution and artifact download verification.
