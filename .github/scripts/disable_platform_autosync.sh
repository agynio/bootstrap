#!/usr/bin/env bash

set -euo pipefail

ARGO_NAMESPACE=${ARGO_NAMESPACE:-argocd}
PLATFORM_APPLICATION=${PLATFORM_APPLICATION:-platform}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
readonly KUBECONFIG_PATH="$REPO_ROOT/stacks/k8s/.kube/agyn-local-kubeconfig.yaml"

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  printf 'Unable to locate kubeconfig at %s\n' "$KUBECONFIG_PATH" >&2
  exit 1
fi

kubectl --kubeconfig "$KUBECONFIG_PATH" \
  -n "$ARGO_NAMESPACE" patch application "$PLATFORM_APPLICATION" \
  --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"enabled":false}}}}'

printf 'Disabled automated sync for Argo CD application %s/%s.\n' "$ARGO_NAMESPACE" "$PLATFORM_APPLICATION"
