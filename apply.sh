#!/usr/bin/env bash

set -euo pipefail

DEFAULT_DOMAIN="agyn.dev"
DEFAULT_PORT="2496"
DEFAULT_OIDC_ISSUER_URL="https://mockauth.dev/r/301ebb13-15a8-48f4-baac-e3fa25be29fc/oidc"
DEFAULT_OIDC_CLIENT_ID="client_MU95KU3gHQf5Ir7p"
DEFAULT_OIDC_CLIENT_SECRET="XPKka2i9uzISrKZ95zxli8sY51BK4eTJ"
KUBECONFIG_PATH="stacks/k8s/.kube/agyn-local-kubeconfig.yaml"

auto_approve="false"

usage() {
  cat <<'EOF'
Usage: ./apply.sh [-y]

Options:
  -y    Run terraform apply with -input=false -auto-approve for all stacks.
        Uses default domain/port values and merges kubeconfig automatically.

Environment variables:
  DOMAIN  Override the ingress domain (default: agyn.dev)
  PORT    Override the ingress port (default: 2496)
  OIDC_ISSUER_URL     Override the OIDC issuer URL (default: https://mockauth.dev/r/301ebb13-15a8-48f4-baac-e3fa25be29fc/oidc)
  OIDC_CLIENT_ID      Override the OIDC client ID (default: client_MU95KU3gHQf5Ir7p)
  OIDC_CLIENT_SECRET  Override the OIDC client secret (default: XPKka2i9uzISrKZ95zxli8sY51BK4eTJ)
EOF
}

while getopts ":yh" opt; do
  case "${opt}" in
    y)
      auto_approve="true"
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -gt 0 ]]; then
  usage >&2
  exit 1
fi

prompt_with_default() {
  local prompt_text="$1"
  local default_value="$2"
  local value

  if ! read -r -p "${prompt_text} [${default_value}]: " value; then
    echo "Error: failed to read ${prompt_text,,} from input. Provide it via environment variables or run interactively." >&2
    exit 1
  fi
  if [[ -z "${value:-}" ]]; then
    printf '%s' "${default_value}"
  else
    printf '%s' "${value}"
  fi
}

domain="${DOMAIN:-}"
if [[ -z "${domain}" ]]; then
  if [[ "${auto_approve}" == "true" ]]; then
    domain="${DEFAULT_DOMAIN}"
    echo "Domain defaulting to ${domain} (auto-apply mode)."
  else
    domain="$(prompt_with_default "Domain" "${DEFAULT_DOMAIN}")"
  fi
else
  echo "Domain provided via DOMAIN environment variable: ${domain}"
fi

port="${PORT:-}"
if [[ -z "${port}" ]]; then
  if [[ "${auto_approve}" == "true" ]]; then
    port="${DEFAULT_PORT}"
    echo "Port defaulting to ${port} (auto-apply mode)."
  else
    port="$(prompt_with_default "Port" "${DEFAULT_PORT}")"
  fi
else
  echo "Port provided via PORT environment variable: ${port}"
fi

if ! [[ "${port}" =~ ^[0-9]+$ ]]; then
  echo "Error: Port must be an integer." >&2
  exit 1
fi

if (( port < 1 || port > 65535 )); then
  echo "Error: Port must be between 1 and 65535." >&2
  exit 1
fi

oidc_issuer_url="${OIDC_ISSUER_URL:-}"
if [[ -z "${oidc_issuer_url}" ]]; then
  if [[ "${auto_approve}" == "true" ]]; then
    oidc_issuer_url="${DEFAULT_OIDC_ISSUER_URL}"
    echo "OIDC issuer URL defaulting to ${oidc_issuer_url} (auto-apply mode)."
  else
    oidc_issuer_url="$(prompt_with_default "OIDC issuer URL" "${DEFAULT_OIDC_ISSUER_URL}")"
  fi
else
  echo "OIDC issuer URL provided via OIDC_ISSUER_URL environment variable: ${oidc_issuer_url}"
fi

oidc_client_id="${OIDC_CLIENT_ID:-}"
if [[ -z "${oidc_client_id}" ]]; then
  if [[ "${auto_approve}" == "true" ]]; then
    oidc_client_id="${DEFAULT_OIDC_CLIENT_ID}"
    echo "OIDC client ID defaulting to ${oidc_client_id} (auto-apply mode)."
  else
    oidc_client_id="$(prompt_with_default "OIDC client ID" "${DEFAULT_OIDC_CLIENT_ID}")"
  fi
else
  echo "OIDC client ID provided via OIDC_CLIENT_ID environment variable: ${oidc_client_id}"
fi

oidc_client_secret="${OIDC_CLIENT_SECRET:-}"
if [[ -z "${oidc_client_secret}" ]]; then
  if [[ "${auto_approve}" == "true" ]]; then
    oidc_client_secret="${DEFAULT_OIDC_CLIENT_SECRET}"
    echo "OIDC client secret defaulting to ${oidc_client_secret} (auto-apply mode)."
  else
    oidc_client_secret="$(prompt_with_default "OIDC client secret" "${DEFAULT_OIDC_CLIENT_SECRET}")"
  fi
else
  echo "OIDC client secret provided via OIDC_CLIENT_SECRET environment variable: ${oidc_client_secret}"
fi

printf '\nUsing domain: %s\nUsing port:   %s\n\n' "${domain}" "${port}"

run_stack() {
  local stack="$1"
  shift
  local extra_args=("$@")

  echo "=== Initializing ${stack} stack ==="
  local init_cmd=(terraform -chdir="stacks/${stack}" init)
  if [[ "${auto_approve}" == "true" ]]; then
    init_cmd+=(-input=false)
  fi
  "${init_cmd[@]}"

  echo "=== Applying ${stack} stack ==="
  local apply_cmd=(terraform -chdir="stacks/${stack}" apply)

  if [[ "${stack}" == "k8s" ]]; then
    apply_cmd+=(-var "domain=${domain}" -var "port=${port}")
  fi

  if [[ "${stack}" == "platform" ]]; then
    apply_cmd+=(
      -var "oidc_issuer_url=${oidc_issuer_url}"
      -var "oidc_client_id=${oidc_client_id}"
      -var "oidc_client_secret=${oidc_client_secret}"
    )
  fi

  if [[ "${#extra_args[@]}" -gt 0 ]]; then
    apply_cmd+=("${extra_args[@]}")
  fi

  if [[ "${auto_approve}" == "true" ]]; then
    apply_cmd+=(-input=false -auto-approve)
  fi

  "${apply_cmd[@]}"
  printf '=== Completed %s stack ===\n\n' "${stack}"
}

should_merge_kubeconfig() {
  local response

  if [[ "${auto_approve}" == "true" ]]; then
    return 0
  fi

  if ! read -r -p "Merge k3d kubeconfig into ~/.kube/config? [Y/n]: " response; then
    echo "Warning: failed to read response; skipping kubeconfig merge." >&2
    return 1
  fi

  case "${response}" in
    [Nn]* )
      return 1
      ;;
    * )
      return 0
      ;;
  esac
}

merge_kubeconfig() {
  local repo_root
  local generated_config
  local kube_dir
  local target_config
  local kubeconfig_env
  local merged

  repo_root="$(pwd)"
  generated_config="${repo_root}/${KUBECONFIG_PATH}"
  kube_dir="${HOME}/.kube"
  target_config="${kube_dir}/config"

  if ! command -v kubectl >/dev/null 2>&1; then
    echo "Warning: kubectl not found; skipping kubeconfig merge." >&2
    return 0
  fi

  if [[ ! -f "${generated_config}" ]]; then
    echo "Warning: generated kubeconfig not found at ${generated_config}; skipping kubeconfig merge." >&2
    return 0
  fi

  mkdir -p "${kube_dir}"
  if [[ ! -f "${target_config}" ]]; then
    touch "${target_config}"
  fi

  kubeconfig_env="${KUBECONFIG:-}"
  kubeconfig_env="${kubeconfig_env}:${target_config}:${generated_config}"

  if ! merged=$(KUBECONFIG="${kubeconfig_env}" kubectl config view --merge --flatten); then
    echo "Error: failed to merge kubeconfig; leaving existing config unchanged." >&2
    return 1
  fi

  if ! printf '%s\n' "${merged}" >"${target_config}"; then
    echo "Error: failed to write merged kubeconfig to ${target_config}." >&2
    return 1
  fi
  echo "Merged k3d kubeconfig into ${target_config}."
}

declare -a step_names=()
declare -a step_durations=()
step_started_at=0

format_duration() {
  local total_seconds="$1"
  local minutes
  local seconds

  if (( total_seconds < 60 )); then
    printf '%ss' "${total_seconds}"
    return
  fi

  minutes=$(( total_seconds / 60 ))
  seconds=$(( total_seconds % 60 ))
  printf '%sm %ss' "${minutes}" "${seconds}"
}

step_start() {
  local label="$1"

  step_started_at="${SECONDS}"
  printf '[TIMING] \xE2\x96\xB6 %s\n' "${label}"
}

step_end() {
  local label="$1"
  local elapsed
  local formatted_duration

  elapsed=$(( SECONDS - step_started_at ))
  step_names+=("${label}")
  step_durations+=("${elapsed}")
  formatted_duration="$(format_duration "${elapsed}")"
  printf '[TIMING] \xE2\x9C\x94 %s completed in %s\n' "${label}" "${formatted_duration}"
}

print_timing_summary() {
  local header_step="Step"
  local header_duration="Duration"
  local total_label="Total"
  local max_label_len=${#header_step}
  local max_duration_len=${#header_duration}
  local -a formatted_durations=()
  local i
  local label
  local duration
  local total_elapsed
  local total_duration
  local line_width
  local border_line
  local divider_line

  for i in "${!step_names[@]}"; do
    label="${step_names[$i]}"
    duration="$(format_duration "${step_durations[$i]}")"
    formatted_durations+=("${duration}")

    if (( ${#label} > max_label_len )); then
      max_label_len=${#label}
    fi

    if (( ${#duration} > max_duration_len )); then
      max_duration_len=${#duration}
    fi
  done

  if (( ${#total_label} > max_label_len )); then
    max_label_len=${#total_label}
  fi

  total_elapsed=$(( SECONDS - global_start ))
  total_duration="$(format_duration "${total_elapsed}")"
  if (( ${#total_duration} > max_duration_len )); then
    max_duration_len=${#total_duration}
  fi

  line_width=$(( max_label_len + 2 + max_duration_len ))

  border_line="$(printf '%*s' "${line_width}" '')"
  border_line="${border_line// /=}"
  divider_line="$(printf '%*s' "${line_width}" '')"
  divider_line="${divider_line// /-}"

  printf '%s\n' "${border_line}"
  printf '%-*s  %-*s\n' "${max_label_len}" "${header_step}" "${max_duration_len}" "${header_duration}"
  printf '%s\n' "${divider_line}"

  for i in "${!step_names[@]}"; do
    printf '%-*s  %-*s\n' "${max_label_len}" "${step_names[$i]}" "${max_duration_len}" "${formatted_durations[$i]}"
  done

  printf '%s\n' "${divider_line}"
  printf '%-*s  %-*s\n' "${max_label_len}" "${total_label}" "${max_duration_len}" "${total_duration}"
  printf '%s\n' "${border_line}"
}

global_start="${SECONDS}"

step_start "stack:k8s"
run_stack "k8s"
step_end "stack:k8s"

step_start "stack:system"
run_stack "system"
step_end "stack:system"

step_start "install-ca-cert"
./install-ca-cert.sh -y "$(pwd)/local-certs/ca-agyn-dev.pem"
step_end "install-ca-cert"

step_start "stack:routing"
run_stack "routing"
step_end "stack:routing"

step_start "stack:deps"
run_stack "deps"

echo "=== Waiting for ArgoCD applications to sync ==="
for app in cert-manager trust-manager ziti-controller; do
  echo "--- Waiting for ${app} ---"
  synced=0
  for i in $(seq 1 60); do
    sync_status=$(kubectl --kubeconfig "${KUBECONFIG_PATH}" \
      -n argocd get application "${app}" \
      -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    health_status=$(kubectl --kubeconfig "${KUBECONFIG_PATH}" \
      -n argocd get application "${app}" \
      -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

    if [[ "${sync_status}" == "Synced" && "${health_status}" == "Healthy" ]]; then
      echo "${app}: Synced and Healthy"
      synced=1
      break
    fi
    echo "  ${app}: sync=${sync_status} health=${health_status} (${i}/60)"
    sleep 10
  done

  if [[ "${synced}" -ne 1 ]]; then
    echo "ERROR: ${app} did not become Synced+Healthy within timeout"
    echo "--- Full Application status ---"
    kubectl --kubeconfig "${KUBECONFIG_PATH}" \
      -n argocd get application "${app}" -o yaml 2>&1 || true
    echo "--- ${app} namespace pods ---"
    ns=$(kubectl --kubeconfig "${KUBECONFIG_PATH}" \
      -n argocd get application "${app}" \
      -o jsonpath='{.spec.destination.namespace}' 2>/dev/null || echo "unknown")
    kubectl --kubeconfig "${KUBECONFIG_PATH}" \
      -n "${ns}" get pods -o wide 2>&1 || true
    echo "--- ${app} namespace events ---"
    kubectl --kubeconfig "${KUBECONFIG_PATH}" \
      -n "${ns}" get events --sort-by='.lastTimestamp' 2>&1 | tail -30 || true
    exit 1
  fi
done
step_end "stack:deps"

step_start "stack:ziti"
echo "=== Waiting for OpenZiti Controller secret ==="
for i in $(seq 1 30); do
  ZITI_ADMIN_PASSWORD=$(kubectl --kubeconfig "${KUBECONFIG_PATH}" \
    -n ziti get secret ziti-controller-admin-secret \
    -o go-template='{{index .data "admin-password" | base64decode}}' 2>/dev/null) && break
  echo "Waiting for ziti-controller admin secret... (${i}/30)"
  sleep 5
done

if [[ -z "${ZITI_ADMIN_PASSWORD:-}" ]]; then
  echo "ERROR: Could not retrieve ziti-controller admin password" >&2
  exit 1
fi

echo "=== Waiting for OpenZiti Management API ==="
management_ready=0
for i in $(seq 1 60); do
  if curl -sk "https://ziti-mgmt.${domain}:${port}/edge/management/v1/version" >/dev/null 2>&1; then
    echo "OpenZiti Management API is ready."
    management_ready=1
    break
  fi
  echo "Waiting for OpenZiti Management API... (${i}/60)"
  sleep 5
done

if [[ "${management_ready}" -ne 1 ]]; then
  echo "ERROR: OpenZiti Management API did not become ready." >&2
  exit 1
fi

ZITI_EXIT=0
run_stack "ziti" -var "ziti_admin_password=${ZITI_ADMIN_PASSWORD}" || ZITI_EXIT=$?

if [ "${ZITI_EXIT}" -ne 0 ]; then
  echo "=== Ziti stack failed (exit code: ${ZITI_EXIT}). Dumping diagnostics ==="
  echo "--- Router pod status ---"
  kubectl --kubeconfig "${KUBECONFIG_PATH}" \
    -n ziti get pods -l app.kubernetes.io/name=ziti-router -o wide 2>&1 || true
  echo "--- Router pod describe ---"
  kubectl --kubeconfig "${KUBECONFIG_PATH}" \
    -n ziti describe pod -l app.kubernetes.io/name=ziti-router 2>&1 | tail -60 || true
  echo "--- Router pod logs ---"
  kubectl --kubeconfig "${KUBECONFIG_PATH}" \
    -n ziti logs -l app.kubernetes.io/name=ziti-router --tail=100 2>&1 || true
  echo "--- Controller client service ---"
  kubectl --kubeconfig "${KUBECONFIG_PATH}" \
    -n ziti get svc -l app.kubernetes.io/name=ziti-controller -o wide 2>&1 || true
  echo "--- Router events ---"
  kubectl --kubeconfig "${KUBECONFIG_PATH}" \
    -n ziti get events --sort-by='.lastTimestamp' --field-selector reason!=Pulled 2>&1 | tail -20 || true
  exit "${ZITI_EXIT}"
fi
step_end "stack:ziti"

step_start "enroll-ziti-management"
if kubectl --kubeconfig "${KUBECONFIG_PATH}" -n platform get secret ziti-certs >/dev/null 2>&1; then
  echo "ziti-certs secret already exists; skipping ziti-management enrollment."
  step_end "enroll-ziti-management"
else
  if ! command -v ziti >/dev/null 2>&1; then
    echo "ERROR: ziti CLI not found; install the OpenZiti CLI before running apply.sh." >&2
    exit 1
  fi

  kubectl --kubeconfig "${KUBECONFIG_PATH}" create namespace platform --dry-run=client -o yaml | \
    kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f -

  tmp_dir="$(mktemp -d)"
  cleanup_enroll_dir() {
    rm -rf "${tmp_dir}"
  }
  trap cleanup_enroll_dir EXIT

  jwt_file="${tmp_dir}/ziti-management.jwt"
  identity_file="${tmp_dir}/ziti-management.json"

  jwt_b64=$(kubectl --kubeconfig "${KUBECONFIG_PATH}" \
    -n ziti get secret ziti-management-enrollment \
    -o jsonpath='{.data.enrollmentJwt}' 2>/dev/null || true)
  if [[ -z "${jwt_b64}" ]]; then
    echo "ERROR: ziti-management enrollment token not found." >&2
    exit 1
  fi

  printf '%s' "${jwt_b64}" | base64 --decode >"${jwt_file}"

  ziti edge enroll --jwt "${jwt_file}" --out "${identity_file}"

  tls_key=$(jq -r '.id.key' "${identity_file}" | sed 's/^pem://')
  tls_cert=$(jq -r '.id.cert' "${identity_file}" | sed 's/^pem://')
  ca_cert=$(jq -r '.id.ca' "${identity_file}" | sed 's/^pem://')

  if [[ -z "${tls_key}" || -z "${tls_cert}" || -z "${ca_cert}" ]]; then
    echo "ERROR: failed to extract ziti-management certificates from identity." >&2
    exit 1
  fi

  kubectl --kubeconfig "${KUBECONFIG_PATH}" -n platform create secret generic ziti-certs \
    --from-literal=tls.crt="${tls_cert}" \
    --from-literal=tls.key="${tls_key}" \
    --from-literal=ca.crt="${ca_cert}" \
    --dry-run=client -o yaml | kubectl --kubeconfig "${KUBECONFIG_PATH}" apply -f -

  cleanup_enroll_dir
  trap - EXIT
  step_end "enroll-ziti-management"
fi

step_start "stack:data"
run_stack "data"
step_end "stack:data"

step_start "stack:platform"
run_stack "platform"
step_end "stack:platform"

echo "All stacks applied successfully."

if should_merge_kubeconfig; then
  step_start "merge-kubeconfig"
  merge_kubeconfig
  step_end "merge-kubeconfig"
else
  echo "Skipping kubeconfig merge."
fi

print_timing_summary
