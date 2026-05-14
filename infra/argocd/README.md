# JuliaFlow ArgoCD / GitOps Manifests

## Purpose

This directory provides GitOps deployment manifests for the JuliaFlow P2 deployment-hardening slice. It keeps the existing app-of-apps topology while replacing placeholder workload intent ConfigMaps with renderable Kustomize workloads for:

- platform dependency contracts
- API Gateway
- Execution Service
- Frontend

The manifests are intentionally provider-neutral. They define stable Kubernetes seams, runtime config, secret templates, Deployments, Services, and dev Ingresses without committing real credentials or pretending to own production managed databases/brokers/IdPs.

## Directory Layout

```text
infra/argocd/
  project.yaml
  root-application.yaml
  apps/
    kustomization.yaml
    *.yaml
  workloads/
    <app>/
      base/
      overlays/dev/
```

Child `Application` paths remain stable:

- `infra/argocd/workloads/platform-deps/overlays/dev`
- `infra/argocd/workloads/api-gateway/overlays/dev`
- `infra/argocd/workloads/execution-service/overlays/dev`
- `infra/argocd/workloads/frontend/overlays/dev`

## Workload Shape

### Platform dependencies

`platform-deps` owns the `juliaflow` namespace plus provider-neutral service and secret contracts:

- `juliaflow-postgres:5432`
- `juliaflow-redis:6379`
- `juliaflow-kafka:9092`
- `juliaflow-object-store:9000`
- `juliaflow-keycloak:8080`

Provider overlays should bind these seams to managed services, operator-owned workloads, or ExternalName/Endpoint resources. The base does not ship fake StatefulSets for production services.

### API Gateway

API Gateway renders:

- `Deployment` running `scripts/run-api-gateway.jl`
- `Service` on port `8088`
- runtime `ConfigMap`
- optional secret-ref template for PostgreSQL/OIDC values; dev defaults use file-backed storage and dev-token auth
- dev `Ingress`
- `/health` probes and `/metrics` scrape annotations

Dev overlay keeps API Gateway at one replica because file-backed storage is the safe no-secret default. Multi-replica provider overlays should switch to PostgreSQL or another shared repository backend.

### Execution Service

Execution Service renders:

- `Deployment` running `scripts/run-execution-service.jl` with `/health` and `/metrics` endpoints
- internal `Service` on port `8090`
- runtime `ConfigMap`
- secret-ref template for checkpoint/object-store/broker values

Future worker/RPC depth can extend this HTTP seam without changing the ArgoCD app boundary.

### Frontend

Frontend renders:

- `Deployment`
- `Service` on port `80`
- runtime `juliaflow-config.js` ConfigMap mounted into the static frontend, with dev URL supplied by the dev overlay patch
- dev `Ingress`

## Validation

Run:

```bash
npm run validate:k8s
```

When `kubectl` is installed, the script runs `kubectl kustomize` for the app-of-apps and all workload dev overlays. Without `kubectl` or standalone `kustomize`, it performs structural YAML checks, Kustomize resource-reference checks, AppProject app-of-apps policy checks, and placeholder rejection.

Optional live cluster proof when a cluster is configured:

```bash
kubectl apply --dry-run=server -k infra/argocd/workloads/api-gateway/overlays/dev
kubectl apply --dry-run=server -k infra/argocd/workloads/execution-service/overlays/dev
kubectl apply --dry-run=server -k infra/argocd/workloads/frontend/overlays/dev
kubectl apply --dry-run=server -k infra/argocd/workloads/platform-deps/overlays/dev
```

## Bootstrap

Apply in this order after ArgoCD itself is installed in cluster:

```bash
kubectl apply -f infra/argocd/project.yaml
kubectl apply -f infra/argocd/root-application.yaml
```

`root-application.yaml` points ArgoCD at `infra/argocd/apps/`, which manages child `Application` resources. Before bootstrap, replace placeholder `repoURL: https://example.invalid/juliaflow.git` in root and child applications with the real git remote used by the cluster.

## Sync Order

Sync waves keep bootstrap deterministic:

- wave `0`: `platform-deps`
- wave `10`: `api-gateway`, `execution-service`
- wave `20`: `frontend`

## Promotion Model

- `overlays/dev/` is the validated P2 thin slice.
- Add provider-specific `overlays/staging/` and `overlays/prod/` later without changing child app names.
- Promote by git commit and checkpoint tag, not by kubectl patching live resources.
- Keep secrets out of git; populate secret templates through sealed-secret, external-secret, ArgoCD plugin, or provider-native secret delivery in target overlays.
