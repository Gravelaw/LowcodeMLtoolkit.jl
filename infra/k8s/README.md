# Kubernetes Deployment Surface

JuliaFlow now has a P2 thin deployment-hardening surface under `infra/argocd/`.

## Current Coverage

- API Gateway: Deployment, Service, runtime ConfigMap, secret-ref template, dev Ingress, `/health` probes, `/metrics` scrape annotations.
- Execution Service: Deployment, internal Service, runtime ConfigMap, checkpoint/object-store/broker secret-ref template.
- Frontend: Deployment, Service, gateway URL ConfigMap, dev Ingress.
- Platform dependencies: `juliaflow` Namespace plus provider-neutral service/secret contracts for PostgreSQL, Redis, Kafka, object storage, and Keycloak/OIDC.

## Validation

```bash
npm run validate:k8s
```

The validator renders all ArgoCD apps and workload overlays with `kubectl kustomize` when `kubectl` is available. On hosts without `kubectl` or standalone `kustomize`, it still checks structural YAML, Kustomize resource references, AppProject app-of-apps policy, and placeholder-only workload manifests.

## Production Provider Work

The P2 slice intentionally avoids fake in-repo production StatefulSets for PostgreSQL, Kafka, Keycloak, MinIO, or Redis. Production overlays should bind the stable service/secret contracts to chosen managed services, operator releases, or Helm charts and then run provider-specific smoke tests.
