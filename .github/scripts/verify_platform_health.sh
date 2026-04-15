#!/usr/bin/env bash

set -euo pipefail

TOTAL_TIMEOUT=${TOTAL_TIMEOUT:-1200}
POLL_INTERVAL=${POLL_INTERVAL:-10}
PLATFORM_NAMESPACE=${PLATFORM_NAMESPACE:-platform}
ARGO_NAMESPACE=${ARGO_NAMESPACE:-argocd}
ZITI_NAMESPACE=${ZITI_NAMESPACE:-ziti}
DEFAULT_DOMAIN="agyn.dev"
DEFAULT_PORT="2496"
POD_TERMINAL_FAILURE_GRACE_CYCLES=${POD_TERMINAL_FAILURE_GRACE_CYCLES:-5}
POD_CRASH_BACKOFF_GRACE_CYCLES=${POD_CRASH_BACKOFF_GRACE_CYCLES:-5}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
readonly KUBECONFIG_PATH="$REPO_ROOT/stacks/k8s/.kube/agyn-local-kubeconfig.yaml"
ZITI_MGMT_ENDPOINT=${ZITI_MGMT_ENDPOINT:-}
ZITI_OVERLAY_SERVICES=(gateway)
ZITI_OVERLAY_ROLE_CHECKS=("runner-services")

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  printf 'Unable to locate kubeconfig at %s\n' "$KUBECONFIG_PATH" >&2
  exit 1
fi

REQUIRED_APPS_JSON='["cert-manager","trust-manager","ziti-controller","ziti-management","registry-mirror","minio","platform-db","threads-db","chat-db","identity-db","runners-db","metering-db","identity","authorization","gateway","runners","notifications-redis","notifications","metering","threads","chat","k8s-runner"]'

deadline=$((SECONDS + TOTAL_TIMEOUT))
pod_terminal_failures_streak=0
pod_crash_backoffs_streak=0

log() {
  printf '[%(%Y-%m-%dT%H:%M:%SZ)T] %s\n' -1 "$1"
}

dump_diagnostics() {
  log "Collecting diagnostics before exit"
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get pods -o wide || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" describe pods || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ARGO_NAMESPACE" get applications.argoproj.io -o yaml | grep -E "(name:|status:)" | sed -n '1,200p' || true
}

dump_ziti_diagnostics() {
  log "Collecting Ziti diagnostics before exit"
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" get pods -o wide || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" describe pods || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" \
    logs -l app.kubernetes.io/name=ziti-controller --tail=50 || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" \
    logs -l app.kubernetes.io/name=ziti-router --tail=50 || true
}

fail_with_diagnostics() {
  dump_diagnostics
  exit 1
}

join_lines() {
  local input=$1
  if [[ -z "$input" ]]; then
    echo ""
    return
  fi
  echo "$input" | paste -sd ', ' -
}

resolve_ziti_management_endpoint() {
  local domain
  local port

  if [[ -n "$ZITI_MGMT_ENDPOINT" ]]; then
    printf '%s' "$ZITI_MGMT_ENDPOINT"
    return 0
  fi

  domain="${DOMAIN:-$DEFAULT_DOMAIN}"
  port="${PORT:-$DEFAULT_PORT}"

  printf 'https://ziti-mgmt.%s:%s/edge/management/v1' "$domain" "$port"
}

ziti_authenticate() {
  local username=$1
  local password=$2
  local payload
  local response

  payload=$(jq -n --arg username "$username" --arg password "$password" '{username:$username,password:$password}')
  if ! response=$(curl -sk --fail -X POST "${ZITI_MGMT_ENDPOINT}/authenticate?method=password" \
    -H 'Content-Type: application/json' -d "$payload"); then
    return 1
  fi

  jq -r '.data.token // empty' <<<"$response" 2>/dev/null
}

ziti_api_get() {
  local token=$1
  local path=$2

  curl -sk --fail -H "zt-session: ${token}" "${ZITI_MGMT_ENDPOINT}${path}"
}

jq_unhealthy_pods() {
  jq -r '
    [.items[] | select(
      (.status.phase // "") != "Running" or
      any(.status.containerStatuses[]?; (.ready // false) | not)
    ) | "\(.metadata.name) (phase=\(.status.phase // "Unknown"))"]
    | .[]?'
}

jq_crash_backoffs() {
  jq -r '
    [.items[] as $pod |
      (($pod.status.containerStatuses // []) + ($pod.status.initContainerStatuses // [])) as $statuses |
      [$statuses[]? | select((.state.waiting.reason? // "") as $reason | ($reason == "CrashLoopBackOff" or $reason == "ImagePullBackOff" or $reason == "ErrImagePull"))]
      as $crash |
      select($crash | length > 0)
      | "\($pod.metadata.name) (reason=\($crash[0].state.waiting.reason))"
    ] | .[]?'
}

ZITI_MGMT_ENDPOINT=$(resolve_ziti_management_endpoint)

while (( SECONDS < deadline )); do
  time_left=$((deadline - SECONDS))

  jobs_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get jobs -o json 2>/dev/null || echo '{"items": []}')
  deployments_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get deployments -o json 2>/dev/null || echo '{"items": []}')
  sts_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get statefulsets -o json 2>/dev/null || echo '{"items": []}')
  pods_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get pods -o json 2>/dev/null || echo '{"items": []}')
  apps_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ARGO_NAMESPACE" get applications.argoproj.io -o json 2>/dev/null || echo '{"items": []}')
  ziti_controller_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" \
    get pods -l app.kubernetes.io/name=ziti-controller -o json 2>/dev/null || echo '{"items": []}')
  ziti_router_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" \
    get pods -l app.kubernetes.io/name=ziti-router -o json 2>/dev/null || echo '{"items": []}')

  degraded_apps=$(jq -r --argjson required "$REQUIRED_APPS_JSON" '
    [.items[]? | select(.metadata.name as $n | $required | index($n) != null)
     | select((.status.health.status // "Unknown") == "Degraded")
     | "\(.metadata.name): \(.status.health.message // "degraded")"]
    | .[]?' <<<"$apps_json")
  if [[ -n "$degraded_apps" ]]; then
    log "Detected degraded Argo CD applications"
    echo "$degraded_apps"
    fail_with_diagnostics
  fi

  job_failures=$(jq -r '
    [.items[] | select(((.status.conditions // []) | any(.type == "Failed" and .status == "True")) or ((.status.failed // 0) > 0))
     | "\(.metadata.name) (failed=\(.status.failed // 0))"]
    | .[]?' <<<"$jobs_json")
  if [[ -n "$job_failures" ]]; then
    log "Detected failed Jobs in namespace ${PLATFORM_NAMESPACE}"
    echo "$job_failures"
    fail_with_diagnostics
  fi

  pod_terminal_failures=$(jq -r '
    [.items[] as $pod |
      ($pod.status.phase // "") as $phase |
      select($phase == "Failed" or $phase == "Unknown")
      | "\($pod.metadata.name) (phase=\($phase))"
    ] | .[]?' <<<"$pods_json")
  if [[ -n "$pod_terminal_failures" ]]; then
    pod_terminal_failures_streak=$((pod_terminal_failures_streak + 1))
  else
    pod_terminal_failures_streak=0
  fi

  pod_crash_backoffs=$(jq_crash_backoffs <<<"$pods_json")
  if [[ -n "$pod_crash_backoffs" ]]; then
    pod_crash_backoffs_streak=$((pod_crash_backoffs_streak + 1))
  else
    pod_crash_backoffs_streak=0
  fi

  deploy_failures=$(jq -r '
    [.items[] as $dep |
      ($dep.status.conditions // []) as $conditions |
      select(
        $conditions | any(
          (.type == "Progressing" and .status == "False" and (.reason // "") == "ProgressDeadlineExceeded") or
          (.type == "Available" and .status == "False" and ((.reason // "") != "MinimumReplicasAvailable" and (.reason // "") != "MinimumReplicasUnavailable"))
        )
      )
      | "\($dep.metadata.name): " + ($conditions | map("\(.type)=\(.status) (\(.reason // "no reason"))") | join(", "))
    ] | .[]?' <<<"$deployments_json")
  if [[ -n "$deploy_failures" ]]; then
    log "Deployment failure detected"
    echo "$deploy_failures"
    fail_with_diagnostics
  fi

  missing_apps=$(jq -r --argjson required "$REQUIRED_APPS_JSON" '
    [$required[] as $name | select(any(.items[]?; .metadata.name == $name) | not) | $name]
    | .[]?' <<<"$apps_json")

  unsynced_apps=$(jq -r --argjson required "$REQUIRED_APPS_JSON" '
    [.items[]? | select(.metadata.name as $n | $required | index($n) != null)
      | select((.status.sync.status // "Unknown") != "Synced" or (.status.health.status // "Unknown") != "Healthy")
      | "\(.metadata.name) (sync=\(.status.sync.status // "Unknown"), health=\(.status.health.status // "Unknown"))"]
    | .[]?' <<<"$apps_json")

  job_pending=$(jq -r '
    [.items[] | select(((.status.conditions // []) | any(.type == "Complete" and .status == "True")) | not)
      | "\(.metadata.name)"]
    | .[]?' <<<"$jobs_json")

  deploy_pending=$(jq -r '
    [.items[] as $dep |
      ($dep.spec.replicas // 1) as $desired |
      select((($dep.status.readyReplicas // 0) < $desired) or (($dep.status.updatedReplicas // 0) < $desired))
      | "\($dep.metadata.name) (ready=\($dep.status.readyReplicas // 0)/\($desired), updated=\($dep.status.updatedReplicas // 0))"
    ] | .[]?' <<<"$deployments_json")

  sts_pending=$(jq -r '
    [.items[] as $sts |
      ($sts.spec.replicas // 1) as $desired |
      ($sts.status.readyReplicas // 0) as $ready |
      ($sts.status.currentReplicas // 0) as $current |
      ($sts.spec.updateStrategy.type // "RollingUpdate") as $strategy |
      ($sts.status.updateRevision // "") as $update |
      ($sts.status.currentRevision // "") as $currentRev |
      select(
        $ready < $desired or
        $current < $desired or
        ($strategy == "OnDelete" and ($update == "" or $currentRev == "" or $update != $currentRev))
      )
      | "\($sts.metadata.name) (ready=\($ready)/\($desired), current=\($current), strategy=\($strategy), revisions=\($currentRev)->\($update))"
    ] | .[]?' <<<"$sts_json")

  pod_pending=$(jq -r '
    [.items[] as $pod |
      ($pod.status.containerStatuses // [] + $pod.status.initContainerStatuses // []) as $statuses |
      select(
        ($pod.status.phase // "") == "Pending" or
        (($pod.status.phase // "") == "Running" and any($statuses[]?; (.ready // false) | not))
      )
      | "\($pod.metadata.name) (phase=\($pod.status.phase // "Unknown"))"
    ] | .[]?' <<<"$pods_json")

  ziti_missing=()
  ziti_controller_count=$(jq '.items | length' <<<"$ziti_controller_json")
  ziti_router_count=$(jq '.items | length' <<<"$ziti_router_json")
  if (( ziti_controller_count == 0 )); then
    ziti_missing+=("ziti-controller")
  fi
  if (( ziti_router_count == 0 )); then
    ziti_missing+=("ziti-router")
  fi

  ziti_unhealthy=$(
    {
      jq_unhealthy_pods <<<"$ziti_controller_json"
      jq_unhealthy_pods <<<"$ziti_router_json"
    } | sed '/^$/d'
  )
  ziti_crash_backoffs=$(
    {
      jq_crash_backoffs <<<"$ziti_controller_json"
      jq_crash_backoffs <<<"$ziti_router_json"
    } | sed '/^$/d'
  )
  if [[ -n "$ziti_crash_backoffs" ]]; then
    log "Detected Ziti pods in CrashLoopBackOff/ImagePull errors"
    echo "$ziti_crash_backoffs"
    dump_ziti_diagnostics
    exit 1
  fi

  outstanding=()

  if [[ -n "$missing_apps" ]]; then
    outstanding+=("waiting for Argo CD applications: $(join_lines "$missing_apps")")
  fi
  if [[ -n "$unsynced_apps" ]]; then
    outstanding+=("waiting for Argo CD health: $(join_lines "$unsynced_apps")")
  fi
  if [[ -n "$job_pending" ]]; then
    outstanding+=("waiting for Jobs: $(join_lines "$job_pending")")
  fi
  if [[ -n "$deploy_pending" ]]; then
    outstanding+=("waiting for Deployments: $(join_lines "$deploy_pending")")
  fi
  if [[ -n "$sts_pending" ]]; then
    outstanding+=("waiting for StatefulSets: $(join_lines "$sts_pending")")
  fi
  if [[ -n "$pod_pending" ]]; then
    outstanding+=("waiting for Pods: $(join_lines "$pod_pending")")
  fi
  if [[ -n "$pod_terminal_failures" ]]; then
    outstanding+=("pods in terminal state (${pod_terminal_failures_streak}/${POD_TERMINAL_FAILURE_GRACE_CYCLES}): $(join_lines "$pod_terminal_failures")")
  fi
  if [[ -n "$pod_crash_backoffs" ]]; then
    outstanding+=("pods restarting (${pod_crash_backoffs_streak}/${POD_CRASH_BACKOFF_GRACE_CYCLES}): $(join_lines "$pod_crash_backoffs")")
  fi
  if (( ${#ziti_missing[@]} > 0 )); then
    outstanding+=("waiting for Ziti pods: $(join_lines "$(printf '%s\n' "${ziti_missing[@]}")")")
  fi
  if [[ -n "$ziti_unhealthy" ]]; then
    outstanding+=("waiting for Ziti pods ready: $(join_lines "$ziti_unhealthy")")
  fi

  if [[ -n "$pod_terminal_failures" ]] && (( pod_terminal_failures_streak >= POD_TERMINAL_FAILURE_GRACE_CYCLES )); then
    log "Pods stuck in terminal state for ${pod_terminal_failures_streak} checks"
    echo "$pod_terminal_failures"
    fail_with_diagnostics
  fi

  if [[ -n "$pod_crash_backoffs" ]] && (( pod_crash_backoffs_streak >= POD_CRASH_BACKOFF_GRACE_CYCLES )); then
    log "Pods stuck in CrashLoopBackOff/ImagePull errors for ${pod_crash_backoffs_streak} checks"
    echo "$pod_crash_backoffs"
    fail_with_diagnostics
  fi

  if (( ${#outstanding[@]} == 0 )); then
    ziti_overlay_pending=()
    ziti_admin_username=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" \
      get secret ziti-controller-admin-secret \
      -o go-template='{{index .data "admin-user" | base64decode}}' 2>/dev/null || true)
    ziti_admin_password=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ZITI_NAMESPACE" \
      get secret ziti-controller-admin-secret \
      -o go-template='{{index .data "admin-password" | base64decode}}' 2>/dev/null || true)

    if [[ -z "$ziti_admin_username" || -z "$ziti_admin_password" ]]; then
      ziti_overlay_pending+=("admin secret")
    else
      if ! ziti_token=$(ziti_authenticate "$ziti_admin_username" "$ziti_admin_password"); then
        ziti_overlay_pending+=("management API authentication")
      elif [[ -z "$ziti_token" ]]; then
        ziti_overlay_pending+=("management API authentication")
      else
        if ! ziti_edge_routers_json=$(ziti_api_get "$ziti_token" "/edge-routers"); then
          ziti_overlay_pending+=("edge router status")
        else
          ziti_online_routers=$(jq -r '[.data[]? | select(.isOnline == true)] | length' \
            <<<"$ziti_edge_routers_json" 2>/dev/null || true)
          if ! [[ "$ziti_online_routers" =~ ^[0-9]+$ ]]; then
            ziti_overlay_pending+=("online edge routers")
          elif (( ziti_online_routers < 1 )); then
            ziti_overlay_pending+=("online edge routers")
          fi
        fi

        for service_name in "${ZITI_OVERLAY_SERVICES[@]}"; do
          if ! ziti_terminators_json=$(ziti_api_get "$ziti_token" \
            "/terminators?filter=service.name%3D%22${service_name}%22"); then
            ziti_overlay_pending+=("${service_name} terminators")
            continue
          fi

          ziti_terminator_count=$(jq -r '[.data[]?] | length' \
            <<<"$ziti_terminators_json" 2>/dev/null || true)
          if ! [[ "$ziti_terminator_count" =~ ^[0-9]+$ ]]; then
            ziti_overlay_pending+=("${service_name} terminators")
          elif (( ziti_terminator_count < 1 )); then
            ziti_overlay_pending+=("${service_name} terminators")
          fi
        done

        for role_attr in "${ZITI_OVERLAY_ROLE_CHECKS[@]}"; do
          if ! ziti_services_json=$(ziti_api_get "$ziti_token" \
            "/services?filter=anyOf(roleAttributes)%3D%22${role_attr}%22"); then
            ziti_overlay_pending+=("${role_attr} services")
            continue
          fi

          ziti_service_count=$(jq -r '[.data[]?] | length' \
            <<<"$ziti_services_json" 2>/dev/null || true)
          if ! [[ "$ziti_service_count" =~ ^[0-9]+$ ]] || (( ziti_service_count < 1 )); then
            ziti_overlay_pending+=("${role_attr} services")
            continue
          fi

          role_has_terminator=false
          while IFS= read -r svc_name; do
            if ziti_term_json=$(ziti_api_get "$ziti_token" \
              "/terminators?filter=service.name%3D%22${svc_name}%22"); then
              term_count=$(jq -r '[.data[]?] | length' <<<"$ziti_term_json" 2>/dev/null || true)
              if [[ "$term_count" =~ ^[0-9]+$ ]] && (( term_count >= 1 )); then
                role_has_terminator=true
                break
              fi
            fi
          done < <(jq -r '.data[]?.name // empty' <<<"$ziti_services_json")

          if [[ "$role_has_terminator" != "true" ]]; then
            ziti_overlay_pending+=("${role_attr} terminators")
          fi
        done
      fi
    fi

    if (( ${#ziti_overlay_pending[@]} > 0 )); then
      ziti_overlay_message=$(join_lines "$(printf '%s\n' "${ziti_overlay_pending[@]}")")
      outstanding+=("waiting for Ziti overlay: ${ziti_overlay_message}")
    fi
  fi

  if (( ${#outstanding[@]} == 0 )); then
    log "Platform namespace ${PLATFORM_NAMESPACE} and Argo CD applications are healthy"
    exit 0
  fi

  log "Pending conditions (time left ${time_left}s):"
  for msg in "${outstanding[@]}"; do
    log "  - ${msg}"
  done
  sleep "$POLL_INTERVAL"
done

log "Timeout (${TOTAL_TIMEOUT}s) exceeded while waiting for platform health"
fail_with_diagnostics
