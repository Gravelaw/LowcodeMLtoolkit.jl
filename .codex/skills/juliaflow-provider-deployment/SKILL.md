---
name: juliaflow-provider-deployment
description: Use when adding or reviewing JuliaFlow Kubernetes/ArgoCD/Kustomize provider overlays, secret delivery, live cluster dry-runs, production deployment hardening, or provider-specific PostgreSQL/Kafka/NATS/object-store/OIDC bindings.
---

# JuliaFlow Provider Deployment

Optional compatibility lane under the local-first BRD. Confirm the user wants provider/cloud work before using this skill.

## Scope

- Kustomize/ArgoCD overlays.
- Provider-specific PostgreSQL, Kafka/NATS, object-store, OIDC, gateway health/metrics bindings.
- Live cluster dry-runs and deployment hardening.

## Invariants

- Keep `infra/argocd/apps/*` child app paths stable unless a migration doc and rollback plan exist.
- Do not commit real secrets.
- Do not add fake production StatefulSets for managed dependencies; bind provider-neutral service/secret contracts through overlays.
- API Gateway file backend stays single-replica; multi-replica requires shared repository backend.

## Checks

- `npm run validate:k8s`
- `kubectl apply --dry-run=server -k <overlay>` when cluster access exists.
- Relevant provider smoke: auth, PostgreSQL, Kafka/NATS, object store, gateway health/metrics.
- Use `codex-security:security-scan` for secrets, auth, RBAC, Hub trust, deployment, or supply-chain changes.
