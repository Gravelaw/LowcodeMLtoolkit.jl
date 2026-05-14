#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

paths=(
  "infra/argocd/apps"
  "infra/argocd/workloads/platform-deps/overlays/dev"
  "infra/argocd/workloads/api-gateway/overlays/dev"
  "infra/argocd/workloads/execution-service/overlays/dev"
  "infra/argocd/workloads/frontend/overlays/dev"
)

required_files=(
  "infra/argocd/project.yaml"
  "infra/argocd/workloads/api-gateway/base/deployment.yaml"
  "infra/argocd/workloads/api-gateway/base/service.yaml"
  "infra/argocd/workloads/api-gateway/base/configmap.yaml"
  "infra/argocd/workloads/execution-service/base/deployment.yaml"
  "infra/argocd/workloads/execution-service/base/service.yaml"
  "infra/argocd/workloads/execution-service/base/configmap.yaml"
  "infra/argocd/workloads/frontend/base/deployment.yaml"
  "infra/argocd/workloads/frontend/base/service.yaml"
  "infra/argocd/workloads/frontend/base/configmap.yaml"
  "infra/argocd/workloads/platform-deps/base/service-contracts.yaml"
  "infra/argocd/workloads/platform-deps/base/secret-templates.yaml"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "missing required manifest: $file" >&2; exit 1; }
done

if grep -R "placeholder-configmap\|juliaflow-.*-intent\|placeholder workload" infra/argocd/workloads >/tmp/juliaflow-k8s-placeholder-grep.txt 2>/dev/null; then
  cat /tmp/juliaflow-k8s-placeholder-grep.txt >&2
  echo "placeholder workload manifests remain" >&2
  exit 1
fi

if grep -R "kind:[[:space:]]*Application" infra/argocd/apps >/dev/null; then
  grep -A2 'group:[[:space:]]*argoproj.io' infra/argocd/project.yaml | grep -q 'kind:[[:space:]]*Application' || {
    echo "AppProject must whitelist argoproj.io/Application for app-of-apps child resources" >&2
    exit 1
  }
fi

while IFS= read -r kustomization; do
  base_dir="$(dirname "$kustomization")"
  awk '
    /^resources:/ { section="resources"; next }
    /^patches:/ { section="patches"; next }
    /^[A-Za-z0-9_-]+:/ { section="" }
    section == "resources" && /^[[:space:]]*-[[:space:]]+/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]+/, "", line)
      sub(/[[:space:]]+#.*/, "", line)
      gsub(/"/, "", line)
      print line
    }
    section == "patches" && /^[[:space:]]*-[[:space:]]+path:/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]+path:[[:space:]]*/, "", line)
      sub(/[[:space:]]+#.*/, "", line)
      gsub(/"/, "", line)
      print line
    }
  ' "$kustomization" | while IFS= read -r resource; do
    [[ -z "$resource" ]] && continue
    [[ -e "$base_dir/$resource" ]] || { echo "missing resource $resource referenced by $kustomization" >&2; exit 1; }
  done
done < <(find infra/argocd -name kustomization.yaml -print)

validate_yaml_structure() {
  local file="$1"
  awk -v file="$file" '
    BEGIN { doc=1; has_api=0; has_kind=0; nonempty=0; errors=0 }
    function finish_doc() {
      if (nonempty == 0) { return }
      if (has_api == 0) { print file ": document " doc " missing apiVersion" > "/dev/stderr"; errors=1 }
      if (has_kind == 0) { print file ": document " doc " missing kind" > "/dev/stderr"; errors=1 }
    }
    /^[[:space:]]*---[[:space:]]*$/ { finish_doc(); doc++; has_api=0; has_kind=0; nonempty=0; next }
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    { nonempty=1 }
    /^apiVersion:[[:space:]]*[^[:space:]]+/ { has_api=1 }
    /^kind:[[:space:]]*[^[:space:]]+/ { has_kind=1 }
    END { finish_doc(); exit errors }
  ' "$file"
}

render_path() {
  local path="$1"
  local rendered=""
  if command -v kubectl >/dev/null 2>&1; then
    rendered="$(kubectl kustomize "$path")" || { echo "kubectl kustomize failed: $path" >&2; exit 1; }
  elif command -v kustomize >/dev/null 2>&1; then
    rendered="$(kustomize build "$path")" || { echo "kustomize build failed: $path" >&2; exit 1; }
  else
    return 2
  fi
  [[ -n "$rendered" ]] || { echo "empty render: $path" >&2; exit 1; }
  grep -q "kind:" <<<"$rendered" || { echo "render missing kind fields: $path" >&2; exit 1; }
}

rendered_any=0
for path in "${paths[@]}"; do
  echo "validating $path"
  if render_path "$path"; then
    rendered_any=1
  fi
done

if [[ "$rendered_any" -eq 0 ]]; then
  while IFS= read -r yaml; do
    validate_yaml_structure "$yaml"
  done < <(find infra/argocd -name '*.yaml' -type f | sort)
  echo "kubectl/kustomize not found; completed structural YAML, Kustomize reference, AppProject policy, and placeholder checks."
fi

echo "Kubernetes manifest validation passed."
