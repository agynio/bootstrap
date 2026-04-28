#!/usr/bin/env bash

set -euo pipefail

IDENTITY_ID="${IDENTITY_ID:-a3c1e9d2-7f4b-5e1a-9c3d-2b8f6a4e7d10}"
# Cluster-admin tokens are resolved as users in gateway clusteradminresolver.
IDENTITY_TYPE="${IDENTITY_TYPE:-IDENTITY_TYPE_USER}"
IDENTITY_GRPC_PORT="${IDENTITY_GRPC_PORT:-50051}"
BUF_API_COMMIT="${BUF_API_COMMIT:-c93d50fb004044178f3a64bc851f27c0}"

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

if [[ -z "${BUF_API_COMMIT}" ]]; then
  echo "Error: BUF_API_COMMIT is required." >&2
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

buf export "buf.build/agynio/api:${BUF_API_COMMIT}" -o "${proto_dir}"

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

identity_lookup_payload=$(printf '{"identity_id":"%s"}' "${IDENTITY_ID}")
register_payload=$(printf '{"identity_id":"%s","identity_type":"%s"}' "${IDENTITY_ID}" "${IDENTITY_TYPE}")

extract_identity_type() {
  local response="$1"
  local parsed

  parsed=$(grep -Eo '"identityType"[[:space:]]*:[[:space:]]*"[^"]+"' <<<"${response}" | head -n1 | cut -d '"' -f4)
  if [[ -z "${parsed}" ]]; then
    echo "Error: unable to parse identity type from response: ${response}" >&2
    return 1
  fi

  echo "${parsed}"
}

fetch_identity_type() {
  local output
  local parsed

  if output=$(grpcurl -plaintext \
    -import-path "${proto_dir}" \
    -proto agynio/api/identity/v1/identity.proto \
    -d "${identity_lookup_payload}" \
    "localhost:${IDENTITY_GRPC_PORT}" \
    agynio.api.identity.v1.IdentityService/GetIdentityType 2>&1); then
    parsed=$(extract_identity_type "${output}") || return 1
    echo "${parsed}"
    return 0
  fi

  if grep -q "NotFound" <<<"${output}"; then
    return 2
  fi

  echo "Error retrieving identity type: ${output}" >&2
  return 1
}

register_identity() {
  local output

  if output=$(grpcurl -plaintext \
    -import-path "${proto_dir}" \
    -proto agynio/api/identity/v1/identity.proto \
    -d "${register_payload}" \
    "localhost:${IDENTITY_GRPC_PORT}" \
    agynio.api.identity.v1.IdentityService/RegisterIdentity 2>&1); then
    echo "Registered cluster admin identity ${IDENTITY_ID}."
    return 0
  fi

  if grep -q "AlreadyExists" <<<"${output}"; then
    echo "Cluster admin identity ${IDENTITY_ID} already registered."
    return 0
  fi

  echo "Error registering cluster admin identity: ${output}" >&2
  return 1
}

identity_type=""
if identity_type=$(fetch_identity_type); then
  echo "Cluster admin identity ${IDENTITY_ID} already registered as ${identity_type}."
else
  fetch_status=$?
  if [[ "${fetch_status}" -eq 2 ]]; then
    register_identity
    identity_type=$(fetch_identity_type) || {
      echo "Error: unable to confirm identity type for ${IDENTITY_ID} after registration." >&2
      exit 1
    }
  else
    exit 1
  fi
fi

if [[ "${identity_type}" != "${IDENTITY_TYPE}" ]]; then
  echo "Error: cluster admin identity ${IDENTITY_ID} has type ${identity_type}, expected ${IDENTITY_TYPE}." >&2
  exit 1
fi

echo "Cluster admin identity ${IDENTITY_ID} confirmed as ${IDENTITY_TYPE}."
