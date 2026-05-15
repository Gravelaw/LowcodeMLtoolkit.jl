---
name: juliaflow-provider-deployment
description: Use when adding or reviewing JuliaFlow Kubernetes/ArgoCD/Kustomize provider overlays, secret delivery, live cluster dry-runs, production deployment hardening, or provider-specific PostgreSQL/Kafka/NATS/object-store/OIDC bindings.
---

# JuliaFlow Provider Deployment

## Scope
Provider-specific deployment work after P2 thin manifests.

## Rules
- Keep `infra/argocd/apps/*` child app paths stable unless a migration doc and rollback plan exist.
- Do not commit real secrets.
- Do not add fake production StatefulSets for managed dependencies; bind provider-neutral service/secret contracts through overlays.
- API Gateway file backend stays single-replica; multi-replica requires shared repository backend.

## Required checks
- `npm run validate:k8s`.
- `kubectl apply --dry-run=server -k <overlay>` when cluster access exists.
- Provider smoke relevant to changed seam: auth, PostgreSQL, Kafka/NATS, object store, gateway health/metrics.
- Update `docs/risk-register.md`, tracker, checkpoint, and traceability when evidence changes.
