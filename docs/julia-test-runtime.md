# Julia Test Runtime Notes

Last updated: 2026-07-09

`tests/julia/runtests.jl` remains the authoritative Julia service/runtime gate. It is a monolithic integration suite, so local runs are expected to exceed five minutes when the API Gateway section is included.

## Current Commands

- Full authoritative gate: `npm run julia:test`
- Timed full gate: `npm run julia:test:timed`
- Data-science helper slice: `npm run julia:test:helpers`
- Gateway repository slice: `npm run julia:test:repository`
- Worker service slice: `npm run julia:test:worker`
- API Gateway slice: `npm run julia:test:api-gateway`
- Available slice labels: `node scripts/time-julia-runtests.mjs --list`

The timed and slice commands generate a temporary instrumented copy of `tests/julia/runtests.jl`. They preserve the checked-in test file and only add top-level timing markers plus optional top-level testset guards in the temporary copy.

## 2026-07-08 Runtime Finding

The slow path is not a hang. A local focused run showed the API Gateway top-level testset executing 1,049 assertions and taking about 6 minutes 19 seconds after Julia load. The full Julia gate passed in about 7 minutes 15 seconds, with the API Gateway section accounting for about 5 minutes 20 seconds of testset time.

The previous full-suite failure was caused by shared mutable test state: the CORS allowed-origin mutation queued the same execution id that later transition-status assertions expected to queue. The test now creates a fresh execution for CORS preflight and mutation checks, preserving the intended allowed-origin, rejected-origin, valid transition, and invalid-transition coverage.

## 2026-07-09 Runtime Update

After adding dependency-backed MLJ/MLJLinearModels package-fit verification, `npm run julia:test` passed in about 9 minutes 5 seconds. The API Gateway testset still dominates at about 5 minutes 29 seconds; the data-science tuning helper block now takes about 1 minute 52 seconds because it verifies actual package-backed `MLJ.LinearRegressor` and `MLJ.LogisticClassifier` local CPU fit/scoring evidence. This is expected verification cost, not a hang.

## Follow-Up Structure Recommendation

The next structural improvement should split `tests/julia/runtests.jl` into included subsystem files while preserving assertions and fixtures:

- data-science helpers
- execution service
- gateway repository
- worker service
- API Gateway route scenarios
- realtime
- auth and OIDC

The API Gateway section should be split into scenario testsets with independent `GatewayState` fixtures where mutation order matters. That would reduce local feedback time and make failures easier to reproduce without weakening pass/fail/error coverage.
