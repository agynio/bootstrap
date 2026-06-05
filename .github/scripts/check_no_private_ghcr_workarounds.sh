#!/usr/bin/env bash

set -euo pipefail

forbidden_pattern='GHCR_(USERNAME|TOKEN)|ghcr_(username|token)|ghcr_image_pull_secrets|ghcr-pull|argocd_repository_credentials|imagePullSecrets|dockerconfigjson|repo[[:space:]]*=[[:space:]]*"ghcr\.io/agynio/charts"|repo_url[[:space:]]*=[[:space:]]*"oci://ghcr\.io/agynio/charts/egress'

if grep -RInE \
  --exclude='check_no_private_ghcr_workarounds.sh' \
  --exclude-dir='.terraform' \
  "${forbidden_pattern}" \
  .github/workflows/bootstrap.yml apply.sh stacks/platform; then
  echo "Private GHCR workarounds are not allowed for public bootstrap charts/images." >&2
  exit 1
fi

if ! grep -Eq 'repo[[:space:]]*=[[:space:]]*"ghcr\.io"' stacks/platform/main.tf; then
  echo 'Expected host-level Argo CD GHCR repository repo = "ghcr.io".' >&2
  exit 1
fi

if ! grep -Eq 'enable_oci[[:space:]]*=[[:space:]]*true' stacks/platform/main.tf; then
  echo 'Expected Argo CD GHCR repository enable_oci = true.' >&2
  exit 1
fi

if ! grep -Eq 'chart[[:space:]]*=[[:space:]]*local\.egress_chart_name' stacks/platform/main.tf; then
  echo 'Expected egress app to use chart = local.egress_chart_name.' >&2
  exit 1
fi

if ! grep -Eq 'chart[[:space:]]*=[[:space:]]*local\.egress_gateway_chart_name' stacks/platform/main.tf; then
  echo 'Expected egress-gateway app to use chart = local.egress_gateway_chart_name.' >&2
  exit 1
fi
