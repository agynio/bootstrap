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
  domain="$(prompt_with_default "Domain" "${DEFAULT_DOMAIN}")"
else
  echo "Domain provided via DOMAIN environment variable: ${domain}"
fi

port="${PORT:-}"
if [[ -z "${port}" ]]; then
  port="$(prompt_with_default "Port" "${DEFAULT_PORT}")"
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

echo "\nUsing domain: ${domain}"
echo "Using port:   ${port}\n"

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
  echo "=== Completed ${stack} stack ===\n"
}

run_stack "k8s"
run_stack "system"
run_stack "routing"
run_stack "platform"

echo "All stacks applied successfully."
