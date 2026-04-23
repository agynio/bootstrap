#!/usr/bin/env bash

set -euo pipefail

TOTAL_TIMEOUT=${TOTAL_TIMEOUT:-180}
POLL_INTERVAL=${POLL_INTERVAL:-10}
PLATFORM_NAMESPACE=${PLATFORM_NAMESPACE:-platform}
PORT_FORWARD_LOCAL_PORT=${PORT_FORWARD_LOCAL_PORT:-18080}
PORT_FORWARD_READY_TIMEOUT=${PORT_FORWARD_READY_TIMEOUT:-30}
PORT_FORWARD_LOG=${PORT_FORWARD_LOG:-/tmp/telegram-gateway-port-forward.log}
EXPECTED_STATUS_HEADLINE="Misconfigured"
BUF_SCHEMA="buf.build/agynio/api"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
readonly KUBECONFIG_PATH="$REPO_ROOT/stacks/k8s/.kube/agyn-local-kubeconfig.yaml"

log() {
  printf '[%(%Y-%m-%dT%H:%M:%SZ)T] %s\n' -1 "$1"
}

dump_diagnostics() {
  log "Collecting diagnostics before exit"
  if [[ ! -f "$KUBECONFIG_PATH" ]]; then
    log "Unable to locate kubeconfig at $KUBECONFIG_PATH"
    return
  fi
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get pods -o wide || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" \
    get deploy,rs,pods -l app.kubernetes.io/name=telegram-connector -o wide || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" \
    logs -l app.kubernetes.io/name=telegram-connector --tail=200 || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" \
    logs -l app.kubernetes.io/name=gateway --tail=200 || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" \
    logs -l app.kubernetes.io/name=apps --tail=200 || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" \
    get events --sort-by=.lastTimestamp | tail -n 80 || true
  if [[ -f "$PORT_FORWARD_LOG" ]]; then
    log "Port-forward log (tail)"
    tail -n 200 "$PORT_FORWARD_LOG" || true
  fi
  cleanup_port_forward
}

start_port_forward() {
  log "Starting gateway port-forward on localhost:${PORT_FORWARD_LOCAL_PORT}"
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" \
    port-forward "svc/gateway-gateway" "${PORT_FORWARD_LOCAL_PORT}:8080" \
    >"$PORT_FORWARD_LOG" 2>&1 &
  PORT_FORWARD_PID=$!
}

cleanup_port_forward() {
  if [[ -n "${PORT_FORWARD_PID:-}" ]]; then
    kill "$PORT_FORWARD_PID" 2>/dev/null || true
    wait "$PORT_FORWARD_PID" 2>/dev/null || true
  fi
}

wait_for_port_forward() {
  local deadline

  deadline=$((SECONDS + PORT_FORWARD_READY_TIMEOUT))
  while (( SECONDS < deadline )); do
    if (echo >/dev/tcp/127.0.0.1/"$PORT_FORWARD_LOCAL_PORT") >/dev/null 2>&1; then
      return 0
    fi
    if [[ -n "${PORT_FORWARD_PID:-}" ]] && ! kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
      log "Port-forward process exited early"
      if [[ -f "$PORT_FORWARD_LOG" ]]; then
        tail -n 200 "$PORT_FORWARD_LOG" || true
      fi
      return 1
    fi
    sleep 1
  done
  log "Timeout waiting for port-forward to start"
  if [[ -f "$PORT_FORWARD_LOG" ]]; then
    tail -n 200 "$PORT_FORWARD_LOG" || true
  fi
  return 1
}

buf_gateway_call() {
  local method=$1
  local payload=$2

  buf curl --schema "$BUF_SCHEMA" \
    --header "Authorization: Bearer ${CLUSTER_ADMIN_TOKEN}" \
    --data "$payload" \
    "${GATEWAY_BASE_URL}/agynio.api.gateway.v1.AppsGateway/${method}"
}

if ! CLUSTER_ADMIN_TOKEN=$(terraform -chdir="$REPO_ROOT/stacks/platform" output -raw cluster_admin_api_token); then
  log "Unable to read cluster admin API token"
  exit 1
fi
if [[ -z "$CLUSTER_ADMIN_TOKEN" ]]; then
  log "Cluster admin API token is empty"
  exit 1
fi

if ! TELEGRAM_INSTALLATION_ID=$(terraform -chdir="$REPO_ROOT/stacks/apps" output -json app_installation_ids | jq -r '.telegram // empty'); then
  log "Unable to read telegram installation ID"
  exit 1
fi
if [[ -z "$TELEGRAM_INSTALLATION_ID" || "$TELEGRAM_INSTALLATION_ID" == "null" ]]; then
  log "Telegram installation ID is empty"
  exit 1
fi

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  log "Unable to locate kubeconfig at $KUBECONFIG_PATH"
  exit 1
fi

start_port_forward
trap cleanup_port_forward EXIT
if ! wait_for_port_forward; then
  dump_diagnostics
  exit 1
fi

GATEWAY_BASE_URL="http://127.0.0.1:${PORT_FORWARD_LOCAL_PORT}"

installation_request=$(jq -n --arg id "$TELEGRAM_INSTALLATION_ID" '{id:$id}')
audit_request=$(jq -n --arg id "$TELEGRAM_INSTALLATION_ID" --argjson pageSize 50 '{installationId:$id, pageSize:$pageSize}')

deadline=$((SECONDS + TOTAL_TIMEOUT))

while (( SECONDS < deadline )); do
  outstanding=()

  if ! installation_response=$(buf_gateway_call "GetInstallation" "$installation_request"); then
    outstanding+=("waiting for installation status (gateway call failed)")
  else
    if ! status=$(jq -r '.installation.status // empty' <<<"$installation_response" 2>/dev/null); then
      outstanding+=("unable to parse installation status response")
    elif [[ -z "$status" ]]; then
      outstanding+=("waiting for installation status")
    else
      headline=$(printf '%s\n' "$status" | head -n 1 | tr -d '\r')
      if [[ "$headline" != "$EXPECTED_STATUS_HEADLINE" ]]; then
        outstanding+=("installation status headline is ${headline:-empty} (expected ${EXPECTED_STATUS_HEADLINE})")
      fi
    fi
  fi

  if ! audit_response=$(buf_gateway_call "ListInstallationAuditLogEntries" "$audit_request"); then
    outstanding+=("waiting for installation audit log entries (gateway call failed)")
  else
    if ! entries_count=$(jq -r '.entries | length' <<<"$audit_response" 2>/dev/null); then
      outstanding+=("unable to parse audit log entries response")
    elif ! [[ "$entries_count" =~ ^[0-9]+$ ]]; then
      outstanding+=("invalid audit log entry count: $entries_count")
    elif (( entries_count < 1 )); then
      outstanding+=("waiting for audit log entries")
    fi

    if ! matching_entries=$(jq -r '[.entries[]? | select(.message | contains("configuration_invalid")) | select(.level == "INSTALLATION_AUDIT_LOG_LEVEL_ERROR")] | length' <<<"$audit_response" 2>/dev/null); then
      outstanding+=("unable to parse configuration_invalid audit log entries")
    elif ! [[ "$matching_entries" =~ ^[0-9]+$ ]]; then
      outstanding+=("invalid configuration_invalid audit log count: $matching_entries")
    elif (( matching_entries < 1 )); then
      outstanding+=("waiting for configuration_invalid audit log entry")
    fi
  fi

  if (( ${#outstanding[@]} == 0 )); then
    log "Telegram installation status and audit log verified"
    exit 0
  fi

  time_left=$((deadline - SECONDS))
  log "Pending conditions (time left ${time_left}s):"
  for msg in "${outstanding[@]}"; do
    log "  - ${msg}"
  done
  sleep "$POLL_INTERVAL"
done

log "Timeout (${TOTAL_TIMEOUT}s) exceeded while verifying telegram installation status"
dump_diagnostics
exit 1
