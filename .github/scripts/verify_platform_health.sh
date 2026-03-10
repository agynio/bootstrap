#!/usr/bin/env bash

set -euo pipefail

TOTAL_TIMEOUT=${TOTAL_TIMEOUT:-1200}
POLL_INTERVAL=${POLL_INTERVAL:-10}
PLATFORM_NAMESPACE=${PLATFORM_NAMESPACE:-platform}
ARGO_NAMESPACE=${ARGO_NAMESPACE:-argocd}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
readonly KUBECONFIG_PATH="$REPO_ROOT/stacks/k8s/.kube/agyn-local-kubeconfig.yaml"

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  printf 'Unable to locate kubeconfig at %s\n' "$KUBECONFIG_PATH" >&2
  exit 1
fi

REQUIRED_APPS_JSON='["vault","registry-mirror","platform-db","litellm-db","agent-state-db","litellm","agent-state","docker-runner","platform-server","platform-ui"]'

deadline=$((SECONDS + TOTAL_TIMEOUT))

log() {
  printf '[%(%Y-%m-%dT%H:%M:%SZ)T] %s\n' -1 "$1"
}

dump_diagnostics() {
  log "Collecting diagnostics before exit"
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get pods -o wide || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" describe pods || true
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ARGO_NAMESPACE" get applications.argoproj.io -o yaml | grep -E "(name:|status:)" | sed -n '1,200p' || true
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

while (( SECONDS < deadline )); do
  time_left=$((deadline - SECONDS))

  jobs_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get jobs -o json 2>/dev/null || echo '{"items": []}')
  deployments_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get deployments -o json 2>/dev/null || echo '{"items": []}')
  sts_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get statefulsets -o json 2>/dev/null || echo '{"items": []}')
  pods_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$PLATFORM_NAMESPACE" get pods -o json 2>/dev/null || echo '{"items": []}')
  apps_json=$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n "$ARGO_NAMESPACE" get applications.argoproj.io -o json 2>/dev/null || echo '{"items": []}')

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
      ($pod.metadata.ownerReferences // []) as $owners |
      select(
        $phase == "Failed" or
        $phase == "Unknown" or
        ($phase == "Succeeded" and (any($owners[]?; .kind == "Job") | not))
      )
      | "\($pod.metadata.name) (phase=\($phase))"
    ] | .[]?' <<<"$pods_json")
  if [[ -n "$pod_terminal_failures" ]]; then
    log "Detected unhealthy pods"
    echo "$pod_terminal_failures"
    fail_with_diagnostics
  fi

  pod_crash_backoffs=$(jq -r '
    [.items[] as $pod |
      ($pod.status.containerStatuses // [] + $pod.status.initContainerStatuses // []) as $statuses |
      [$statuses[]? | select((.state.waiting.reason? // "") as $reason | ($reason == "CrashLoopBackOff" or $reason == "ImagePullBackOff" or $reason == "ErrImagePull"))]
      as $crash |
      select($crash | length > 0)
      | "\($pod.metadata.name) (reason=\($crash[0].state.waiting.reason))"
    ] | .[]?' <<<"$pods_json")

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
  if [[ -n "$pod_crash_backoffs" ]]; then
    outstanding+=("pods restarting: $(join_lines "$pod_crash_backoffs")")
  fi

  if (( ${#outstanding[@]} == 0 )); then
    if [[ -n "$pod_crash_backoffs" ]]; then
      log "Detected pods stuck in CrashLoopBackOff/ImagePull errors"
      echo "$pod_crash_backoffs"
      fail_with_diagnostics
    fi
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
