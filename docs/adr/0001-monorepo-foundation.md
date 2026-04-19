# ADR 0001: Monorepo Foundation and Contract Freeze

## Status

Accepted

## Context

JuliaFlow BRD requires many services and feature lanes to move in parallel after shared contracts stabilize. Repository started empty, with no source tree, no workflow schema, and no version-control policy.

## Decision

- Use monorepo with `apps/`, `packages/`, `services/`, `extensions/`, `infra/`, `docs/`, `tests/`
- Freeze workflow contract in `packages/contracts/schemas/workflow.schema.json`
- Freeze REST surface in `packages/contracts/openapi/openapi.json`
- Freeze realtime JSON-RPC protocol in `packages/contracts/protocol/jsonrpc.json`
- Enforce Arrow IPC as only inter-node payload format in node SDK
- Capture milestone evidence through checkpoint tags and release notes before risky merges

## Consequences

- Feature teams can work on disjoint paths with fewer merge conflicts
- Contract-first development reduces rewrite risk for frontend and backend
- Bootstrap uses npm workspaces because `pnpm` is not yet installed locally
- Future checkpoint `cp/01-contracts-frozen` should protect shared schemas from ad hoc edits

