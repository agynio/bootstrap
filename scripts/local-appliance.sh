#!/usr/bin/env bash

set -euo pipefail

DEFAULT_CLUSTER_NAME="agyn-local"
DEFAULT_RESTORE_CLUSTER_NAME="agyn-local"
DEFAULT_ARTIFACT_DIR="dist/local-appliance"
DEFAULT_IMAGE_REPOSITORY="ghcr.io/agynio/bootstrap-local-appliance"
DEFAULT_IMAGE_TAG="dev"
DEFAULT_DOMAIN="agyn.dev"
DEFAULT_PORT="2496"
DEFAULT_API_PORT="6443"
DEFAULT_SERVERS="1"
DEFAULT_AGENTS="0"
DEFAULT_K3S_VERSION="v1.34.3-k3s1"
DEFAULT_PLATFORM_HEALTH_TIMEOUT="900"
DEFAULT_ARTIFACT_VERSION="1"
KUBECONFIG_PATH="stacks/k8s/.kube/agyn-local-kubeconfig.yaml"

mode=""
cluster_name="${APPLIANCE_CLUSTER_NAME:-$DEFAULT_CLUSTER_NAME}"
restore_cluster_name="${APPLIANCE_RESTORE_CLUSTER_NAME:-$DEFAULT_RESTORE_CLUSTER_NAME}"
artifact_dir="${APPLIANCE_ARTIFACT_DIR:-$DEFAULT_ARTIFACT_DIR}"
image_repository="${APPLIANCE_IMAGE_REPOSITORY:-$DEFAULT_IMAGE_REPOSITORY}"
image_tag="${APPLIANCE_IMAGE_TAG:-$DEFAULT_IMAGE_TAG}"
domain="${DOMAIN:-$DEFAULT_DOMAIN}"
port="${PORT:-$DEFAULT_PORT}"
api_port="${APPLIANCE_API_PORT:-$DEFAULT_API_PORT}"
servers="${APPLIANCE_SERVERS:-$DEFAULT_SERVERS}"
agents="${APPLIANCE_AGENTS:-$DEFAULT_AGENTS}"
k3s_version="${APPLIANCE_K3S_VERSION:-$DEFAULT_K3S_VERSION}"
platform_health_timeout="${APPLIANCE_PLATFORM_HEALTH_TIMEOUT:-$DEFAULT_PLATFORM_HEALTH_TIMEOUT}"
publish="false"
skip_provision="false"
skip_restore_validation="false"

usage() {
  cat <<'USAGE'
Usage: scripts/local-appliance.sh <command> [options]

Commands:
  build     Provision a normal bootstrap k3d cluster and capture an appliance artifact.
  restore   Restore a captured appliance artifact into a new k3d cluster.
  publish   Push appliance images and OCI artifact metadata to GHCR.

Options:
  --cluster-name NAME           Source cluster for build (default: agyn-local).
  --restore-cluster-name NAME   Restore target cluster (default: agyn-local).
  --artifact-dir DIR            Appliance artifact directory (default: dist/local-appliance).
  --image-repository REPO       OCI repository for published images/artifacts.
  --image-tag TAG               Image/artifact tag (default: dev).
  --domain DOMAIN               Bootstrap ingress domain (default: agyn.dev).
  --port PORT                   Bootstrap ingress host port (default: 2496).
  --api-port PORT               Kubernetes API host port (default: 6443).
  --servers N                   k3d server node count (default: 1).
  --agents N                    k3d agent node count for the restore shell (default: 0).
  --k3s-version VERSION         k3s image tag without rancher/k3s: prefix.
  --platform-health-timeout S   Timeout for verify_platform_health.sh (default: 900).
  --publish                     Build command also publishes after capture.
  --skip-provision              Build command captures an already-provisioned cluster.
  --skip-restore-validation     Build command skips restore smoke test.
  -h, --help                    Show this help.

Environment variables mirror the option names with APPLIANCE_ prefixes where
applicable. The path is opt-in only and does not change apply.sh behavior.
USAGE
}

log() {
  printf '[appliance] %s\n' "$*"
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

require_command() {
  local command_name=$1

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "required command not found: ${command_name}"
  fi
}

require_common_commands() {
  local commands=(docker k3d kubectl jq tar)
  local command_name

  for command_name in "${commands[@]}"; do
    require_command "$command_name"
  done
}

require_build_commands() {
  require_common_commands
  require_command terraform
  require_command curl
}

validate_integer() {
  local name=$1
  local value=$2

  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    fail "${name} must be an integer"
  fi
}

validate_port() {
  local name=$1
  local value=$2

  validate_integer "$name" "$value"
  if (( value < 1 || value > 65535 )); then
    fail "${name} must be between 1 and 65535"
  fi
}

parse_args() {
  if [[ $# -lt 1 ]]; then
    usage >&2
    exit 1
  fi

  mode=$1
  shift

  case "$mode" in
    build | restore | publish)
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cluster-name)
        cluster_name="${2:-}"
        shift 2
        ;;
      --restore-cluster-name)
        restore_cluster_name="${2:-}"
        shift 2
        ;;
      --artifact-dir)
        artifact_dir="${2:-}"
        shift 2
        ;;
      --image-repository)
        image_repository="${2:-}"
        shift 2
        ;;
      --image-tag)
        image_tag="${2:-}"
        shift 2
        ;;
      --domain)
        domain="${2:-}"
        shift 2
        ;;
      --port)
        port="${2:-}"
        shift 2
        ;;
      --api-port)
        api_port="${2:-}"
        shift 2
        ;;
      --servers)
        servers="${2:-}"
        shift 2
        ;;
      --agents)
        agents="${2:-}"
        shift 2
        ;;
      --k3s-version)
        k3s_version="${2:-}"
        shift 2
        ;;
      --platform-health-timeout)
        platform_health_timeout="${2:-}"
        shift 2
        ;;
      --publish)
        publish="true"
        shift
        ;;
      --skip-provision)
        skip_provision="true"
        shift
        ;;
      --skip-restore-validation)
        skip_restore_validation="true"
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        exit 1
        ;;
    esac
  done

  [[ -n "$cluster_name" ]] || fail "cluster name cannot be empty"
  [[ -n "$restore_cluster_name" ]] || fail "restore cluster name cannot be empty"
  [[ -n "$artifact_dir" ]] || fail "artifact directory cannot be empty"
  [[ -n "$image_repository" ]] || fail "image repository cannot be empty"
  [[ -n "$image_tag" ]] || fail "image tag cannot be empty"
  [[ -n "$domain" ]] || fail "domain cannot be empty"
  [[ -n "$k3s_version" ]] || fail "k3s version cannot be empty"

  validate_port "port" "$port"
  validate_port "api port" "$api_port"
  validate_integer "servers" "$servers"
  validate_integer "agents" "$agents"
  validate_integer "platform health timeout" "$platform_health_timeout"

  if (( servers != 1 )); then
    fail "this spike captures exactly one k3d server; set --servers 1"
  fi

  if (( agents != 0 )); then
    fail "restore validation is limited to a single-node k3d shell; set --agents 0"
  fi
}

cluster_exists() {
  local name=$1

  k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -Fxq "$name"
}

remove_restore_cluster_if_present() {
  if cluster_exists "$restore_cluster_name"; then
    log "Deleting existing restore cluster ${restore_cluster_name}."
    k3d cluster delete "$restore_cluster_name"
  fi
}

source_node_name() {
  printf 'k3d-%s-server-0' "$cluster_name"
}

source_load_balancer_name() {
  printf 'k3d-%s-serverlb' "$cluster_name"
}

restore_node_name() {
  printf 'k3d-%s-server-0' "$restore_cluster_name"
}

image_ref() {
  printf '%s:%s' "$image_repository" "$image_tag"
}

runtime_image_ref() {
  printf '%s-runtime:%s' "$image_repository" "$image_tag"
}

metadata_ref() {
  printf '%s-metadata:%s' "$image_repository" "$image_tag"
}

run_bootstrap() {
  log "Provisioning ${cluster_name} with existing apply.sh."
  DOMAIN="$domain" PORT="$port" ./apply.sh -y
}

wait_for_platform_health() {
  log "Waiting for platform health."
  timeout "${platform_health_timeout}s" ./.github/scripts/verify_platform_health.sh
}

volume_name_for_destination() {
  local container_name=$1
  local destination=$2

  docker inspect "$container_name" | jq -r --arg destination "$destination" '
    .[0].Mounts[]
    | select(.Destination == $destination and .Type == "volume")
    | .Name
  '
}

bind_source_for_destination() {
  local container_name=$1
  local destination=$2

  docker inspect "$container_name" | jq -r --arg destination "$destination" '
    .[0].Mounts[]
    | select(.Destination == $destination and .Type == "bind")
    | .Source
  '
}

capture_volume() {
  local volume_name=$1
  local destination=$2
  local output_path=$3

  [[ -n "$volume_name" ]] || fail "missing Docker volume for ${destination}"
  log "Capturing ${destination} from volume ${volume_name}."
  docker run --rm \
    -v "${volume_name}:/source:ro" \
    alpine:3.20 \
    tar -C /source -czf - . >"$output_path"
}

write_json_array() {
  local output_path=$1
  shift

  jq -n '$ARGS.positional' --args "$@" >"$output_path"
}

capture_source_state() {
  local source_node
  local server_rancher_volume
  local server_kubelet_volume
  local server_cni_volume
  local shared_source
  local artifact_image
  local runtime_image
  local created_at

  source_node=$(source_node_name)
  artifact_image=$(image_ref)
  runtime_image=$(runtime_image_ref)
  created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  docker inspect "$source_node" >/dev/null

  log "Stopping ${cluster_name} cleanly before capture."
  k3d cluster stop "$cluster_name"

  rm -rf "$artifact_dir"
  mkdir -p "${artifact_dir}/volumes" "${artifact_dir}/inspect"
  artifact_dir=$(cd "$artifact_dir" && pwd)

  log "Committing ${source_node} to ${artifact_image}."
  docker commit "$source_node" "$artifact_image"

  server_rancher_volume=$(volume_name_for_destination "$source_node" /var/lib/rancher/k3s)
  server_kubelet_volume=$(volume_name_for_destination "$source_node" /var/lib/kubelet)
  server_cni_volume=$(volume_name_for_destination "$source_node" /var/lib/cni)
  shared_source=$(bind_source_for_destination "$source_node" /shared)

  capture_volume "$server_rancher_volume" /var/lib/rancher/k3s "${artifact_dir}/volumes/server-var-lib-rancher-k3s.tar.gz"
  capture_volume "$server_kubelet_volume" /var/lib/kubelet "${artifact_dir}/volumes/server-var-lib-kubelet.tar.gz"
  capture_volume "$server_cni_volume" /var/lib/cni "${artifact_dir}/volumes/server-var-lib-cni.tar.gz"

  if [[ -n "$shared_source" && -d "$shared_source" ]]; then
    log "Capturing /shared bind source ${shared_source}."
    tar -C "$shared_source" -czf "${artifact_dir}/volumes/shared.tar.gz" .
  else
    log "No /shared bind source found; creating empty shared snapshot."
    tar -C /tmp --files-from /dev/null -czf "${artifact_dir}/volumes/shared.tar.gz"
  fi

  docker inspect "$source_node" >"${artifact_dir}/inspect/source-server.json"
  if docker inspect "$(source_load_balancer_name)" >/dev/null 2>&1; then
    docker inspect "$(source_load_balancer_name)" >"${artifact_dir}/inspect/source-load-balancer.json"
  fi

  write_json_array "${artifact_dir}/agent-images.json" "rancher/k3s:${k3s_version}"

  jq -n \
    --arg artifact_version "$DEFAULT_ARTIFACT_VERSION" \
    --arg created_at "$created_at" \
    --arg source_cluster_name "$cluster_name" \
    --arg restore_cluster_name "$restore_cluster_name" \
    --arg image "$artifact_image" \
    --arg runtime_image "$runtime_image" \
    --arg k3s_image "rancher/k3s:${k3s_version}" \
    --arg domain "$domain" \
    --argjson port "$port" \
    --argjson api_port "$api_port" \
    --argjson agents "$agents" \
    '{
      artifactVersion: $artifact_version,
      createdAt: $created_at,
      sourceClusterName: $source_cluster_name,
      defaultRestoreClusterName: $restore_cluster_name,
      image: $image,
      runtimeImage: $runtime_image,
      k3sImage: $k3s_image,
      domain: $domain,
      port: $port,
      apiPort: $api_port,
      servers: 1,
      agents: $agents,
      capturedPaths: [
        "/var/lib/rancher/k3s",
        "/var/lib/kubelet",
        "/var/lib/cni",
        "/shared"
      ]
    }' >"${artifact_dir}/manifest.json"

  tar -C "$artifact_dir" -czf "${artifact_dir}.tar.gz" .

  cat >"${artifact_dir}/Dockerfile.metadata" <<EOF_METADATA
FROM scratch
LABEL org.opencontainers.image.title="agyn-local-appliance-metadata"
LABEL org.opencontainers.image.description="Metadata and volume snapshots for the opt-in Agyn local appliance spike"
ADD manifest.json /manifest.json
ADD agent-images.json /agent-images.json
ADD volumes /volumes
ADD inspect /inspect
EOF_METADATA
  docker build -f "${artifact_dir}/Dockerfile.metadata" -t "$runtime_image" "$artifact_dir"

  log "Artifact written to ${artifact_dir} and ${artifact_dir}.tar.gz."
  log "Committed source server image: ${artifact_image}."
  log "Metadata image: ${runtime_image}."
}

create_restore_cluster_shell() {
  local restore_image
  local tmp_kubeconfig

  restore_image=$(image_ref)
  tmp_kubeconfig=$(mktemp)

  remove_restore_cluster_if_present
  log "Creating restore cluster ${restore_cluster_name} from ${restore_image}."
  k3d cluster create "$restore_cluster_name" \
    --servers 1 \
    --agents "$agents" \
    --image "$restore_image" \
    --api-port "127.0.0.1:${api_port}" \
    --port "127.0.0.1:${port}:443@loadbalancer" \
    --volume "$(pwd)/shared:/shared@all" \
    --k3s-arg "--disable=traefik@server:0" \
    --wait \
    --timeout 180s

  k3d kubeconfig get "$restore_cluster_name" >"$tmp_kubeconfig"
  mkdir -p "$(dirname "$KUBECONFIG_PATH")"
  cp "$tmp_kubeconfig" "$KUBECONFIG_PATH"
  rm -f "$tmp_kubeconfig"
}

restore_volume_into_container() {
  local archive_path=$1
  local container_name=$2
  local destination=$3
  local volume_name

  [[ -f "$archive_path" ]] || fail "missing archive ${archive_path}"
  volume_name=$(volume_name_for_destination "$container_name" "$destination")
  [[ -n "$volume_name" ]] || fail "restore cluster does not expose ${destination} as a Docker volume"

  log "Restoring ${destination} into volume ${volume_name}."
  docker run --rm -i \
    -v "${volume_name}:/target" \
    alpine:3.20 \
    sh -c "rm -rf /target/* /target/.[!.]* /target/..?* 2>/dev/null || true; tar -C /target -xzf -" <"$archive_path"
}

restore_shared_snapshot() {
  local archive_path="${artifact_dir}/volumes/shared.tar.gz"

  [[ -f "$archive_path" ]] || fail "missing archive ${archive_path}"
  mkdir -p shared
  log "Restoring /shared snapshot into $(pwd)/shared."
  rm -rf shared/* shared/.[!.]* shared/..?* 2>/dev/null || true
  tar -C shared -xzf "$archive_path"
}

restore_artifact() {
  local restore_node

  require_common_commands
  create_restore_cluster_shell
  restore_node=$(restore_node_name)

  log "Stopping ${restore_cluster_name} before volume restore."
  k3d cluster stop "$restore_cluster_name"

  restore_volume_into_container "${artifact_dir}/volumes/server-var-lib-rancher-k3s.tar.gz" "$restore_node" /var/lib/rancher/k3s
  restore_volume_into_container "${artifact_dir}/volumes/server-var-lib-kubelet.tar.gz" "$restore_node" /var/lib/kubelet
  restore_volume_into_container "${artifact_dir}/volumes/server-var-lib-cni.tar.gz" "$restore_node" /var/lib/cni

  restore_shared_snapshot

  log "Starting restored cluster ${restore_cluster_name}."
  k3d cluster start "$restore_cluster_name" --wait --timeout 180s
  k3d kubeconfig get "$restore_cluster_name" >"$KUBECONFIG_PATH"

  smoke_validate_restore
}

smoke_validate_restore() {
  log "Validating restored Kubernetes API and persisted objects."
  kubectl --kubeconfig "$KUBECONFIG_PATH" wait --for=condition=Ready nodes --all --timeout=180s
  kubectl --kubeconfig "$KUBECONFIG_PATH" get nodes -o wide
  kubectl --kubeconfig "$KUBECONFIG_PATH" get pv,pvc -A
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n argocd get applications.argoproj.io
}

publish_artifact() {
  local artifact_image
  local runtime_image
  local metadata_image

  require_common_commands
  artifact_image=$(image_ref)
  runtime_image=$(runtime_image_ref)
  metadata_image=$(metadata_ref)

  docker image inspect "$artifact_image" >/dev/null
  docker image inspect "$runtime_image" >/dev/null

  log "Tagging metadata artifact ${runtime_image} as ${metadata_image}."
  docker tag "$runtime_image" "$metadata_image"

  log "Pushing ${artifact_image}."
  docker push "$artifact_image"
  log "Pushing ${metadata_image}."
  docker push "$metadata_image"
}

build_artifact() {
  require_build_commands

  if [[ "$skip_provision" == "false" ]]; then
    run_bootstrap
    wait_for_platform_health
  fi

  capture_source_state

  if [[ "$skip_restore_validation" == "false" ]]; then
    restore_artifact
  else
    log "Skipping restore validation; run scripts/local-appliance.sh restore to test the artifact."
  fi

  if [[ "$publish" == "true" ]]; then
    publish_artifact
  fi
}

main() {
  parse_args "$@"

  case "$mode" in
    build)
      build_artifact
      ;;
    restore)
      restore_artifact
      ;;
    publish)
      publish_artifact
      ;;
    *)
      fail "unsupported mode ${mode}"
      ;;
  esac
}

main "$@"
