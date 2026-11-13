# Current local-appliance threat model

Date: 2026-09-20. Repository: Gravelaw/LowcodeMLtoolkit.jl. Version: `f9e10f3a3e5fd3c48e601e9252047de49c8bf2df`. Scope: AKS-38 browser/gateway, local import/managed artifacts, backup, PostgreSQL identifiers and optional object-store boundaries. Sequential agent analysis, not an independent audit or exploit certification. The July 8 model remains historical; current qualifications below take precedence.

## Overview

React communicates with the Julia HTTP gateway. The gateway authenticates and dispatches routes, delegates project helpers, and persists file-backed project/job/model records. Managed datasets and output artifacts live in the local data estate. Optional PostgreSQL metadata does not enable database dataset imports.

| Component | Source |
| --- | --- |
| Startup/environment | `scripts/dev-local.mjs:200` |
| Gateway authority and route dispatch | `services/api-gateway/src/JuliaFlowApiGateway.jl:1638`, 7309, 7350 |
| Project materialization | `services/api-gateway/src/JuliaFlowDataScienceProjectCore.jl:102` |
| File import/artifact boundary | `services/api-gateway/src/JuliaFlowDataScienceProjectLocalSources.jl:27`, 174, 256 |
| Persistent payloads and database identifiers | `services/api-gateway/src/JuliaFlowGatewayRepository.jl:902`, 1449 |

| Deployment or workflow | Resource/capability | Configuration and precedence | Safe effective location/value | Readers/writers/recipients | Enforcing control / qualification |
| --- | --- | --- | --- | --- | --- |
| `dev:local` | Gateway owner authority | caller env AUTH_MODE, otherwise disabled (`dev-local.mjs:222`) | local service, owner permissions in disabled mode | Browser caller reaching local service | Loopback default; wildcard default CORS and disabled auth leave R3/AKS-55 |
| Direct gateway | Gateway auth | AUTH_MODE otherwise dev_token (gateway:1226); configured token read at 1259 | token value deliberately omitted | Gateway auth resolver | Required mode rejects absent configuration; dev fallback is not equivalent to required auth |
| Managed dataset read | File contents | HOME then DATA_ESTATE_ROOT (gateway:574–579), `local://data/` suffix | data-root / URI suffix | Analysis/tuning/evaluation helpers | Root realpath plus lexical confinement; redirected child policy unresolved (R5) |
| Raw-file import | Local input bytes | Data root plus IMPORT_ROOTS (local sources:27) | canonical path under configured roots | Local gateway import | requested/canonical equality, root check, file size/extension, credential/PII sample rejection (local sources:147–200) |
| Managed output | Generated artifacts | same data root; `local://` suffix (local sources:277) | data-root / suffix; e.g. transforms/project/run | Gateway output writer | lexical confinement, file-stream checksum at 99; nearest-existing-parent redirection remains R5 |
| Backup export | Restore-capable auth/project data | local-backups route (gateway:7481) | response bundle, sensitive values omitted from this model | caller with backup read AND write | owner has both, editor/viewer lack write (gateway:1183); disabled auth gives owner and inherits R3 |
| PostgreSQL metadata | SQL schema | constructor schema, validated again before connect (repository:1449, 1580) | allowlisted SQL identifier; connection secret omitted | configured repository connection | identifier validation before interpolation; live service integration not run |
| Optional object-store | Compatibility hooks | OBJECT_STORE_COMPATIBILITY default disabled (gateway:1237) | unavailable unless explicit local_compatibility | optional hook caller | flag is capability gating, not provider authentication; no cloud dataset connector proof |

## Trust boundaries and assumptions

Assets are local files, credentials in restore bundles, project/job provenance, immutable dataset/model artifacts, and integrity of metrics used for model promotion. Expected invariants: browser mutations require intended local authority; paths stay inside configured roots including redirected entries; secrets/full rejected paths are not exposed by routine audit; checksums bind bytes; unavailable inputs never become completed release evidence.

Actors include the legitimate local operator, a browser page from an untrusted origin, and a contributor/process able to place files within a permitted import/managed directory. The latter does not automatically control the operator account, gateway configuration or all local files. An arbitrary internet caller is not assumed to reach loopback. Browser private-network restrictions and OS exposure remain deployment prerequisites.

The raw import boundary differs from managed URI reads/writes; the same root configuration does not prove equivalent confinement. Sample-based secret screening is bounded detection, not complete data-loss prevention. A schema role named sensitive is not proof that every export removes its values. Project write permission permits user-authored child dictionaries; provenance validity must be enforced separately from authentication (Core:10, 102–135).

No repository SECURITY.md supplied a different governing trust policy; AGENTS.md supplies configured-root, realpath, redaction, checksum and no-fixture invariants. No production credentials were accessed and no attack payload was sent to another service.

## Attack surfaces, mitigations and attacker stories

| Priority | Scenario/capability gain | Prerequisites | Impact | Existing controls | Required mitigation / evidence |
| --- | --- | --- | --- | --- | --- |
| P1 | Untrusted browser invokes default local owner mutations or backup export | Browser can reach local service; default disabled auth and wildcard origin | Local state mutation or sensitive bundle disclosure | Loopback; configured auth/origin paths have rejection tests | AKS-55; default-startup origin/credential tests. Source-confirmed configuration; exploit not run |
| P1 conditional | Managed URI follows a redirected child outside data root | Actor can plant a link/junction under managed root | Gateway reads/writes beyond declared boundary | URI traversal rejection and lexical root containment | AKS-41 R5; canonical target/parent confinement and symlink/junction tests; consumers require review |
| P1 integrity | Caller supplies malformed or self-approved project evidence | Authorized project writer | Invalid model/metric decisions, contract inconsistency | Route permission and some lifecycle gates | AKS-45/56; distinguish imported assertions from produced evidence, validate payloads and provenance |
| P0 product integrity | Missing input produces plausible synthetic analysis output | Legitimate action with absent/unusable source | Invalid validation, promotion or monitoring claims | Some ordinary list/import paths isolate fixtures; warning metadata exists | AKS-53; reject unavailable in required modes, preserve demo separately |
| Lower residual | Raw path traversal, invalid identifiers, unsupported provider paths | Caller controls import/identifier input | Unauthorized resource use if guard fails | realpath/raw-root checks, identifier allowlist, connector rejection, streaming SHA | Preserve success and rejection tests; no new exploit established |
| Conditional | Restore artifact bytes differ from declared checksum | Corrupted/untrusted bundle | Wrong reconstructed runtime/model state | checksum helpers and existing migration design | Current full migration/service matrix not rerun; do not infer a pass from helper tests |

## Severity calibration

Critical would require evidence of remotely reachable unauthenticated broad compromise; that is not established here. High is appropriate for default browser mutation authority if the documented local reachability prerequisite holds, or for a demonstrated managed-root escape with a less-trusted writer. Medium applies to bounded provenance/contract disagreement without an additional privilege crossing. Low covers limited information or usability defects with no sensitive capability gain. Priority P0 on synthetic analysis is a release/ML-validity priority, not a CVSS claim.

Configured-origin tests do not validate default-origin security; a passing positive live-browser scenario does not validate hostile origins or missing-input behavior. The review leaves those distinctions explicit.
