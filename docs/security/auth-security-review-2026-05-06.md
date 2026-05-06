# Auth/RBAC Security Review — 2026-05-06

## Scope

Reviewed the current auth/RBAC implementation after the persisted directory admin and RS256 OIDC/JWKS slices:

- `services/api-gateway/src/JuliaFlowApiGateway.jl`
- `services/api-gateway/src/JuliaFlowGatewayRepository.jl`
- `packages/contracts/src/index.ts`
- `packages/contracts/openapi/openapi.json`
- `packages/contracts/schemas/events.schema.json`
- `apps/frontend/src/App.tsx`
- `apps/frontend/src/App.test.tsx`
- `tests/julia/runtests.jl`
- `tests/julia/repository_contract_tests.jl`

## Verdict

- Critical findings: 0
- High findings: 0
- Medium findings: 0
- Low / watch findings: 2
- Recommendation: accept this auth hardening state as locally reviewed, but do not mark P0 auth complete until external live-IdP and PostgreSQL runtime evidence are captured.

## Positive Controls Verified

- OIDC mode is isolated behind `JULIAFLOW_AUTH_MODE=oidc`; disabled/dev-token modes remain separate and covered by existing tests.
- Allowed JWT algorithms are explicit through `JULIAFLOW_OIDC_ALLOWED_ALGORITHMS`; unsupported algorithms are rejected.
- HS256 JWKS validation requires `kid` when JWKS is used and has rotation tests.
- RS256 validation uses discovery/JWKS metadata, requires matching `kid`, `kty=RSA`, `alg=RS256`, modulus/exponent material, and a minimum 2048-bit RSA modulus.
- RS256 signatures verify PKCS#1 v1.5 SHA-256 DigestInfo and reject tampered signatures.
- JWT issuer, audience, subject, expiry, and not-before claims are validated.
- Persisted role bindings and resource policies are checked against active directory users/workspaces when directory records exist.
- Runtime contexts are rejected when a populated directory marks the principal or workspace inactive/missing.
- Directory updates reject self-lockout when the caller principal/workspace would be removed or disabled.
- Admin directory/policy routes are protected by `policy:read` / `policy:write`.
- Audit query payloads remain bounded and redacted; frontend tests cover redacted audit rendering.
- Directory/policy mutations produce durable events and audit actions without exposing token material.

## Low / Watch Findings

1. External provider behavior is not smoke-tested in this workspace.
   - Impact: Production IdP interoperability is not proven against a live issuer/JWKS endpoint.
   - Status: Open until provider metadata/credentials are supplied.
   - Required evidence: live discovery/JWKS smoke with `JULIAFLOW_OIDC_DISCOVERY_URL` or provider fixture approved by deployment owner.

2. PostgreSQL auth persistence is schema-ready but not runtime-proven in this workspace.
   - Impact: File-backed behavior is proven, but PostgreSQL auth directory/policy behavior still needs integration evidence.
   - Status: Open until `JULIAFLOW_TEST_POSTGRES_URL` is available.
   - Required evidence: repository/gateway auth policy + directory tests against PostgreSQL backend.

## Security Review Conclusion

The broader local auth security review found no merge-blocking issues after the 2048-bit RS256 modulus hardening. P0 auth remains open only for external live-IdP smoke and PostgreSQL runtime evidence.

## Verification Evidence Used

- `npm run test --workspace apps/frontend -- --run App.test.tsx` PASS
- `julia --project=. tests/julia/runtests.jl` PASS; existing Gateway Repository `Broken 1` unchanged
- `npm run validate:brd-traceability` PASS
- `npm run test` PASS
- `npm run build` PASS
- `git diff --check` PASS
