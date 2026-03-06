#!/usr/bin/env bash

set -euo pipefail

CHART_VERSION="${CHART_VERSION:-2.2.2}"
CHART_REPO_URL="${CHART_REPO_URL:-https://helm.twun.io}"
CHART_NAME="docker-registry"
TARGET_REGISTRY="${TARGET_REGISTRY:-ghcr.io/agynio/charts}"

if ! command -v helm >/dev/null 2>&1; then
  echo "Error: helm is required to publish the chart." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

helm repo add twuni "$CHART_REPO_URL" --force-update >/dev/null
helm repo update twuni >/dev/null
helm pull "twuni/${CHART_NAME}" --version "$CHART_VERSION" --destination "$tmp_dir" >/dev/null
helm push "$tmp_dir/${CHART_NAME}-${CHART_VERSION}.tgz" "oci://${TARGET_REGISTRY}"
