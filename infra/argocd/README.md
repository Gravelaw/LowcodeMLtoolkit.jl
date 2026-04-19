# JuliaFlow ArgoCD / GitOps Scaffold

## Purpose

This directory provides foundation GitOps scaffold for JuliaFlow Phase 0. It is intentionally light: ArgoCD project, root app-of-apps, and placeholder workload applications that match current repository shape.

Current apps represented:

- platform dependencies
- API Gateway
- Execution Service
- Frontend

Workloads are placeholders today. They create namespaced config objects that document deployment intent until real Kubernetes manifests or Helm charts land.

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

## Bootstrap

Apply in this order after ArgoCD itself is installed in cluster:

```bash
kubectl apply -f infra/argocd/project.yaml
kubectl apply -f infra/argocd/root-application.yaml
```

`root-application.yaml` points ArgoCD at `infra/argocd/apps/`, which then manages child `Application` resources.
Before bootstrap, replace placeholder `repoURL: https://example.invalid/juliaflow.git` in root and child applications with actual git remote used by cluster.

## Sync Order

Sync waves keep bootstrap deterministic:

- wave `0`: `platform-deps`
- wave `10`: `api-gateway`, `execution-service`
- wave `20`: `frontend`

This matches current foundation dependency order: namespace and shared platform services first, runtime services next, UI last.

## Promotion Model

- `overlays/dev/` is scaffolded now and should match checkpoint validation clusters.
- Add `overlays/staging/` and `overlays/prod/` later without changing child app names.
- Promote by git commit and checkpoint tag, not by kubectl patching live resources.

## Expected Next Steps

- Replace placeholder config maps with real Deployments, Services, Ingress, Secrets references, and StatefulSets or Helm releases.
- Move shared namespace and common labels into reusable Kustomize bases once more apps exist.
- Add image automation only after checkpoint tagging and rollback evidence are stable.
- Keep ArgoCD app boundaries aligned with lane ownership so rollback can happen by subsystem.

## Checkpoint Use

Recommended GitOps checkpoint mapping:

- `cp/00-foundation`: project + root app + placeholder workload apps
- `cp/01-contracts-frozen`: add contract version labels/annotations to runtime manifests
- `cp/02-alpha-core`: replace service placeholders with live frontend/api/execution deployments
- `cp/03+`: introduce separate BI, streaming, hub, and observability applications as contracts mature
