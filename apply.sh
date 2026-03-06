#!/usr/bin/env bash

set -euo pipefail

DEFAULT_DOMAIN="agyn.dev"
DEFAULT_PORT="2496"

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

printf '\nUsing domain: %s\nUsing port:   %s\n\n' "${domain}" "${port}"

run_stack() {
  local stack="$1"

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
  local temp_config
  local kubeconfig_env

  repo_root="$(pwd)"
  generated_config="${repo_root}/stacks/k8s/.kube/agyn-local-kubeconfig.yaml"
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

  temp_config="$(mktemp "${kube_dir}/config.tmp.XXXXXX")"
  kubeconfig_env="${KUBECONFIG:-}"
  kubeconfig_env="${kubeconfig_env}:${target_config}:${generated_config}"

  if ! KUBECONFIG="${kubeconfig_env}" kubectl config view --merge --flatten >"${temp_config}"; then
    echo "Error: failed to merge kubeconfig; leaving existing config unchanged." >&2
    rm -f "${temp_config}"
    return 1
  fi

  mv "${temp_config}" "${target_config}"
  echo "Merged k3d kubeconfig into ${target_config}."
}

run_stack "k8s"
run_stack "system"
run_stack "routing"
run_stack "platform"

echo "All stacks applied successfully."

if should_merge_kubeconfig; then
  merge_kubeconfig
else
  echo "Skipping kubeconfig merge."
fi
