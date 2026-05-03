# Next P0 Plan: Production OIDC/RBAC Hardening

Date: 2026-05-03
Mode: `$plan`
Scope: planning artifact only; implementation follows in `$autopilot`/`$ralph` execution.

## Target Result

Move JuliaFlow from thin dev-token RBAC to a production-ready authentication and authorization foundation without breaking existing local/dev, share-token, or workspace-token flows.

## Current Evidence Baseline

- P0 BI viewer polish is complete and traceable.
- P0 Arrow/DataFrames materialization and 150-node baseline are complete, with provider-specific object-store deployment left as hardening risk.
- Existing auth foundation includes contract auth context/roles/permissions, gateway route gates, dashboard share/workspace separation, and durable `audit.action` events.
- Remaining P0 lanes are production OIDC/RBAC, production streaming, and production GPU.

## RALPLAN-DR

### Decision Drivers

- Phase 1 readiness needs production security gates before broad runtime hardening claims.
- The current auth slice is intentionally thin and dev-token oriented.
- Streaming/GPU hardening are important, but both become safer after persisted identity, roles, policy, and audit query surfaces exist.
- Provider-specific cloud object-store work remains blocked on target provider/credential/deployment choice, so keep it as risk/hardening rather than the next implementation lane.

### Options Considered

#### Option A: OIDC/JWT + persisted RBAC/audit query thin slice (Recommended)

Pros:
- Closes highest security gap after BI polish.
- Builds on current auth/audit contracts and gateway route gates.
- Enables safer Hub, streaming, GPU, and deployment hardening later.
- Can be tested with mock JWKS/issuer fixtures without external provider credentials.

Cons:
- Touches contracts, OpenAPI, gateway repository, tests, and likely frontend admin/read surfaces.
- Needs careful fallback handling so dev workflows do not regress.

#### Option B: Production streaming adapters next

Pros:
- Advances runtime depth and exactly-once BRD path.
- Builds on existing fixture/window/checkpoint MVP.

Cons:
- Leaves production auth/policy/audit controls thin while adding more operational surfaces.
- Kafka/NATS deployment details may introduce external-service scope.

#### Option C: Production GPU hardening next

Pros:
- Advances CUDA/KernelAbstractions and multi-GPU BRD goals.

Cons:
- Highest hardware/dependency variability.
- Less useful before identity/policy/audit controls are production-grade.

### Decision

Choose Option A: production OIDC/RBAC hardening as the next P0 implementation lane.

## Implementation Plan

1. Contracts and OpenAPI
   - Add/confirm typed auth provider config, OIDC issuer/JWKS settings, principal claims, workspace-role bindings, resource-policy records, and audit-query DTOs in `packages/contracts/`.
   - Keep `GatewayAuthContext`, roles, permissions, and `audit.action` event compatibility.

2. Gateway auth seam
   - Add JWT/OIDC validation seam with issuer/audience/expiry checks and mockable JWKS/key resolver.
   - Preserve current disabled/dev-token mode for local use.
   - Keep share-token and workspace-token dashboard reads isolated from control-plane bearer auth.

3. Persisted RBAC and policy repository
   - Add file-backed repository records for users, workspaces, role bindings, resource policies, and audit queries.
   - Keep structures PostgreSQL-ready and explicit about tenant/workspace boundaries.

4. Audit query and policy surfaces
   - Add bounded, redacted audit query route for control-plane actions.
   - Add minimal resource-policy management route/surface needed to prove persisted policy enforcement.
   - Avoid exposing raw tokens, headers, or secret-like payload fields.

5. Tests
   - Julia gateway tests: valid OIDC/JWT principal mapping, invalid/missing token `401`, insufficient role `403`, persisted role/policy enforcement, bounded audit query, dev-token fallback, share-token compatibility.
   - Contract tests: OpenAPI/JSON schema compatibility for new auth/audit/policy DTOs.
   - Frontend tests only if a UI/admin read surface is added in the slice.

6. Documentation and traceability
   - Update TODO/BRD traceability only after tests provide evidence.
   - Update tracker, checkpoint, risk register, README/onboarding where behavior changes.

## Risk Register Link

Active risks and mitigation plan live in `docs/risk-register.md`.
Near-term execution should burn down `R-SEC-001` through `R-SEC-004` first.

## Acceptance Criteria

- Valid OIDC/JWT token maps to a principal with workspace role and permissions.
- Invalid/missing/expired token returns `401` for protected control-plane routes.
- Authenticated but unauthorized principal returns `403`.
- Persisted role/policy records affect route authorization in file-backed repository mode.
- Audit query API returns bounded, redacted `audit.action` records.
- Dev-token/disabled auth fallback remains tested.
- Dashboard share-token/workspace-token viewer flows remain unaffected.
- `docs/brd-traceability.md` links code/test evidence before any TODO item is checked.

## Verification Plan

- `git diff --check`
- `npm run validate:brd-traceability`
- `npm run test`
- `npm run build`
- `julia --project=. tests/julia/runtests.jl`

## Suggested Execution Staffing

Solo `$ralph` is enough for the first thin slice. If using `$team`, split:

- Contracts/OpenAPI lane
- Gateway/repository/auth lane
- Tests/docs lane
- Optional frontend admin/read surface lane

Stop condition: all acceptance criteria pass with fresh verification evidence and tracker/checkpoint/traceability synced.
