# Local Source Threat Model

Date: 2026-07-08

## Scope

This threat model covers AKS-36 local-first data-science project inputs and outputs:

- browser-to-localhost mutation routes
- local file/folder source grants
- managed `local://` refs
- output-contract JSON imports
- backup/export metadata
- PostgreSQL schema/table identifiers
- object-store compatibility hooks
- local artifact checksum handling

Provider/cloud connectors, public webhook receivers, and tunneled workstation endpoints are out of scope for AKS-36 and must remain unavailable unless explicitly reprioritized.

## Trust Boundaries

- Browser UI to gateway: mutation routes must require the configured local auth/dev-token behavior and reject unexpected origins where CORS enforcement is active. When `JULIAFLOW_CORS_ALLOW_ORIGIN` is set to a concrete local origin, browser requests from any other origin are rejected before route mutation.
- Gateway to filesystem: raw local files must resolve under configured import roots, must not traverse outside those roots, and must reject symlinks or junctions rather than following redirected filesystem entries.
- Managed data estate: `local://` refs are allowed only for managed local artifacts with bounded paths and no traversal-shaped segments. Materialized project artifacts must record file-stream checksum evidence rather than trusting caller-provided bytes.
- Output contracts: imports must be JSON, size bounded, checksum-validated when a checksum is supplied, and stored with redacted provenance.
- Database identifiers: PostgreSQL repository schema names and local import connector `databaseSchema`/`databaseTable` values use an allowlisted identifier rule before connection, SQL execution, or source use. Future database connector fields must use the same policy before enablement.
- Object stores: S3/GCS/Azure source options remain backend-visible but disabled by default; S3-compatible local mode can only move to available when `JULIAFLOW_OBJECT_STORE_COMPATIBILITY=local_compatibility`.
- Backup/export: bundles should include enough metadata for restore and review while avoiding raw secrets, sensitive samples, or full rejected local paths. Local backup export is owner-only because it carries restore-capable auth metadata.

## Abuse Cases And Required Controls

| Abuse case | Required control | Evidence owner |
| --- | --- | --- |
| Browser page drives localhost mutation without expected auth/origin | Auth/CORS tests for allowed and rejected requests, including configured-origin rejection | Gateway route tests |
| Local import escapes configured root with `..`, symlink, or junction | Realpath confinement and symlink/junction rejection | `JuliaFlowDataScienceProjectLocalSources` tests |
| User imports credential or sensitive local file | Sensitive filename checks, text sniffing, redacted rejection audit | Local-source tests |
| Unsupported or mismatched connector appears usable | Connector/source consistency checks; disabled backend state with reason | Local-source helper, frontend, and route tests |
| Output contract leaks full local path or sensitive preview | Redacted provenance and checksum-only evidence | Prediction export tests |
| Local backup exports sensitive auth metadata to non-owners | Owner-only backup export and redacted auth review metadata | Gateway route tests |
| PostgreSQL identifier injection | Identifier allowlist and route/repository tests for schema/table fields | Repository tests; import route tests; `PostgreSQLGatewayRepository` schema guard |
| Local import audit hides full paths but lacks reviewable redaction evidence | Explicit redaction-preview metadata for accepted and rejected import events | Local-source tests; import route tests |
| Object-store hook runs unexpectedly in local appliance | Explicit compatibility flag and unavailable state | Gateway/catalog tests; Data disabled-state tests |
| Artifact restore trusts changed bytes | Checksum/size verification and mismatch report | Migration smoke |
| Materialized project artifact checksum is computed only from buffered content | File-stream checksum helper and `streaming_file_sha256` artifact evidence | Local-source tests; project artifact smokes |

## Acceptance Gate

AKS-36 cannot claim broad local dataset onboarding readiness until every enabled local source path has a documented policy, negative tests, and redacted audit evidence. Unsupported connectors must stay visible but disabled with a reason.

Current enabled import policies are `managed_local` for existing confined `local://data` files and `local_file` for approved filesystem paths. DuckDB remains a managed read mode after import, not a source-import connector. PostgreSQL source import remains unavailable until query execution and redacted connection provenance are implemented.
