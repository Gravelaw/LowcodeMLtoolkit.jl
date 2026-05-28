---
name: juliaflow-provider-deployment
description: Use when adding or reviewing JuliaFlow Kubernetes/ArgoCD/Kustomize provider overlays, secret delivery, live cluster dry-runs, production deployment hardening, or provider-specific PostgreSQL/Kafka/NATS/object-store/OIDC bindings.
---

# JuliaFlow Provider Deployment

## Scope
Provider-specific deployment work after P2 thin manifests. Under the v0.4.0 local-first BRD, provider/cloud deployment is optional compatibility work, not a core GA blocker.

## Rules
- Keep `infra/argocd/apps/*` child app paths stable unless a migration doc and rollback plan exist.
- Do not commit real secrets.
- Do not add fake production StatefulSets for managed dependencies; bind provider-neutral service/secret contracts through overlays.
- API Gateway file backend stays single-replica; multi-replica requires shared repository backend.
- Confirm the user explicitly wants provider/cloud compatibility before spending effort here; otherwise prefer `juliaflow-local-first-appliance`.

## Required checks
- `npm run validate:k8s`.
- `kubectl apply --dry-run=server -k <overlay>` when cluster access exists.
- Provider smoke relevant to changed seam: auth, PostgreSQL, Kafka/NATS, object store, gateway health/metrics.
- Update `docs/risk-register.md`, tracker, checkpoint, and traceability when evidence changes.
- Use `codex-security:security-scan` for secrets, auth, RBAC, Hub trust, deployment, or supply-chain changes.
