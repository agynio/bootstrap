#!/usr/bin/env bash

set -euo pipefail

IDENTITY_ID="${IDENTITY_ID:-a3c1e9d2-7f4b-5e1a-9c3d-2b8f6a4e7d10}"
IDENTITY_TYPE="${IDENTITY_TYPE:-IDENTITY_TYPE_USER}"
IDENTITY_GRPC_PORT="${IDENTITY_GRPC_PORT:-50051}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)
DEFAULT_KUBECONFIG_PATH="${REPO_ROOT}/stacks/k8s/.kube/agyn-local-kubeconfig.yaml"

KUBECONFIG_PATH="${KUBECONFIG_PATH:-${KUBECONFIG:-}}"
if [[ -z "${KUBECONFIG_PATH}" ]]; then
  KUBECONFIG_PATH="${DEFAULT_KUBECONFIG_PATH}"
fi

if [[ -z "${IDENTITY_ID}" ]]; then
  echo "Error: IDENTITY_ID is required." >&2
  exit 1
fi

if [[ -z "${IDENTITY_TYPE}" ]]; then
  echo "Error: IDENTITY_TYPE is required." >&2
  exit 1
fi

if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
  echo "Error: kubeconfig not found at ${KUBECONFIG_PATH}." >&2
  exit 1
fi

for cmd in kubectl buf grpcurl; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: required command not found: ${cmd}." >&2
    exit 1
  fi
done

proto_dir=$(mktemp -d)
port_forward_log=$(mktemp)
port_forward_pid=""

cleanup() {
  if [[ -n "${port_forward_pid}" ]]; then
    kill "${port_forward_pid}" >/dev/null 2>&1 || true
  fi
  rm -rf "${proto_dir}" "${port_forward_log}"
}

trap cleanup EXIT

buf export buf.build/agynio/api -o "${proto_dir}"

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n platform \
  port-forward svc/identity "${IDENTITY_GRPC_PORT}:50051" >"${port_forward_log}" 2>&1 &
port_forward_pid=$!

port_forward_ready=0
for _ in $(seq 1 30); do
  if grep -q "Forwarding from" "${port_forward_log}"; then
    port_forward_ready=1
    break
  fi
  if ! kill -0 "${port_forward_pid}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if [[ "${port_forward_ready}" -ne 1 ]]; then
  echo "Error: identity service port-forward failed." >&2
  cat "${port_forward_log}" >&2 || true
  exit 1
fi

payload=$(printf '{"identity_id":"%s","identity_type":"%s"}' "${IDENTITY_ID}" "${IDENTITY_TYPE}")

if output=$(grpcurl -plaintext \
  -import-path "${proto_dir}" \
  -proto agynio/api/identity/v1/identity.proto \
  -d "${payload}" \
  "localhost:${IDENTITY_GRPC_PORT}" \
  agynio.api.identity.v1.IdentityService/RegisterIdentity 2>&1); then
  echo "Registered cluster admin identity ${IDENTITY_ID}."
else
  if grep -q "AlreadyExists" <<<"${output}"; then
    echo "Cluster admin identity ${IDENTITY_ID} already registered."
  else
    echo "Error registering cluster admin identity: ${output}" >&2
    exit 1
  fi
fi
