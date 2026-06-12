#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  IDENTITY_ID
  SECRET_NAME
  ZITI_CLI_LINUX_AMD64_SHA256
  ZITI_CLI_LINUX_ARM64_SHA256
  ZITI_CLI_VERSION
  ZITI_NAMESPACE
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required environment variable: ${var_name}" >&2
    exit 1
  fi
done

workdir=$(mktemp -d)
export ZITI_CONFIG_DIR="$workdir/config"
trap 'rm -rf "$workdir"' EXIT

arch=$(uname -m)
case "$arch" in
  x86_64|amd64)
    ziti_arch="amd64"
    ziti_sha="$ZITI_CLI_LINUX_AMD64_SHA256"
    ;;
  aarch64|arm64)
    ziti_arch="arm64"
    ziti_sha="$ZITI_CLI_LINUX_ARM64_SHA256"
    ;;
  *)
    echo "Unsupported OpenZiti CLI architecture: $arch" >&2
    exit 1
    ;;
esac

archive="$workdir/ziti.tar.gz"
curl -fsSL "https://github.com/openziti/ziti/releases/download/v${ZITI_CLI_VERSION}/ziti-linux-${ziti_arch}-${ZITI_CLI_VERSION}.tar.gz" -o "$archive"
printf '%s  %s\n' "$ziti_sha" "$archive" | sha256sum -c - >&2
tar -xzf "$archive" -C "$workdir"
ziti="$workdir/ziti"

enrollment_id=$("$ziti" edge create enrollment ott "$IDENTITY_ID" --jwt-output-file "$workdir/enrollment.jwt" --output-json | jq -r '.data.id')
if [[ -z "$enrollment_id" || "$enrollment_id" == "null" ]]; then
  echo "OpenZiti enrollment creation did not return an enrollment id" >&2
  exit 1
fi

"$ziti" edge enroll --jwt "$workdir/enrollment.jwt" --out "$workdir/identity.json" >&2

kubectl --namespace "$ZITI_NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-file="identity.json=$workdir/identity.json" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f - >&2
