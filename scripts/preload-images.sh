#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/preload-images.sh --mode auto|always|never [--cluster CLUSTER] --manifest FILE [--images IMAGE...] [--pull-only] [--retry-pulls N]

Options:
  --mode        Preload behavior: auto warns and continues, always fails, never no-ops.
  --cluster     k3d cluster name used for imports. Required unless --pull-only is set.
  --manifest    Image manifest file. Lines may contain comments beginning with #.
  --images      Optional explicit images to preload instead of manifest images.
  --pull-only   Pull missing images into the Docker cache without importing into k3d.
  --retry-pulls Number of docker pull attempts per image (default: 3).
USAGE
}

mode="auto"
cluster_name=""
manifest_path="image-cache/bootstrap-images.txt"
pull_only="false"
pull_attempts="3"
declare -a cli_images=()
declare -a images=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      if [[ $# -lt 2 ]]; then
        echo "Error: --mode requires a value." >&2
        exit 1
      fi
      mode="$2"
      shift 2
      ;;
    --cluster)
      if [[ $# -lt 2 ]]; then
        echo "Error: --cluster requires a value." >&2
        exit 1
      fi
      cluster_name="$2"
      shift 2
      ;;
    --manifest)
      if [[ $# -lt 2 ]]; then
        echo "Error: --manifest requires a value." >&2
        exit 1
      fi
      manifest_path="$2"
      shift 2
      ;;
    --images)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Error: --images requires at least one image." >&2
        exit 1
      fi
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --*)
            break
            ;;
          *)
            cli_images+=("$1")
            shift
            ;;
        esac
      done
      ;;
    --pull-only)
      pull_only="true"
      shift
      ;;
    --retry-pulls)
      if [[ $# -lt 2 ]]; then
        echo "Error: --retry-pulls requires a value." >&2
        exit 1
      fi
      pull_attempts="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "${mode}" in
  auto|always|never)
    ;;
  *)
    echo "Error: --mode must be one of: auto, always, never." >&2
    exit 1
    ;;
esac

if ! [[ "${pull_attempts}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --retry-pulls must be a positive integer." >&2
  exit 1
fi

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

normalize_manifest_line() {
  local line="$1"

  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s' "${line}"
}

load_manifest_images() {
  local image
  local line
  local -A seen=()

  if [[ ! -f "${manifest_path}" ]]; then
    echo "Error: image manifest not found: ${manifest_path}" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    image="$(normalize_manifest_line "${line}")"
    if [[ -z "${image}" || -n "${seen[${image}]:-}" ]]; then
      continue
    fi
    seen["${image}"]=1
    images+=("${image}")
  done <"${manifest_path}"
}

pull_image() {
  local image="$1"
  local attempt

  for attempt in $(seq 1 "${pull_attempts}"); do
    echo "Image preload: pulling ${image} (attempt ${attempt}/${pull_attempts})"
    if docker pull "${image}"; then
      return 0
    fi

    if (( attempt == pull_attempts )); then
      return 1
    fi

    sleep $(( attempt * 5 ))
  done
}

run_preload() {
  local image
  local start_time="${SECONDS}"
  local cache_hits=0
  local pulls=0
  local imports=0
  local elapsed
  local formatted_duration

  if (( ${#images[@]} == 0 )); then
    echo "Image preload: no images to preload (mode=${mode})."
    return 0
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: required command not found: docker" >&2
    return 1
  fi

  if [[ "${pull_only}" == "false" ]]; then
    if ! command -v k3d >/dev/null 2>&1; then
      echo "Error: required command not found: k3d" >&2
      return 1
    fi

    if [[ -z "${cluster_name}" ]]; then
      echo "Error: --cluster is required unless --pull-only is set." >&2
      return 1
    fi
  fi

  echo "Image preload: mode=${mode} cluster=${cluster_name:-none} pull_only=${pull_only} images=${#images[@]}"

  for image in "${images[@]}"; do
    if docker image inspect "${image}" >/dev/null 2>&1; then
      cache_hits=$(( cache_hits + 1 ))
      echo "Image preload: cache hit ${image}"
    else
      pull_image "${image}"
      pulls=$(( pulls + 1 ))
    fi

    if [[ "${pull_only}" == "false" ]]; then
      echo "Image preload: importing ${image}"
      k3d image import "${image}" --cluster "${cluster_name}"
      imports=$(( imports + 1 ))
    fi
  done

  elapsed=$(( SECONDS - start_time ))
  formatted_duration="$(format_duration "${elapsed}")"
  echo "Image preload summary: images=${#images[@]} cache_hits=${cache_hits} pulls=${pulls} imports=${imports} duration=${formatted_duration}"
}

main() {
  local preload_status=0

  echo "Image preload requested: mode=${mode} manifest=${manifest_path} pull_only=${pull_only}"

  if [[ "${mode}" == "never" ]]; then
    echo "Image preload skipped because mode=never."
    return 0
  fi

  if (( ${#cli_images[@]} > 0 )); then
    images=("${cli_images[@]}")
  else
    load_manifest_images || preload_status=$?
  fi

  if [[ "${preload_status}" -eq 0 ]]; then
    run_preload || preload_status=$?
  fi

  if [[ "${preload_status}" -eq 0 ]]; then
    return 0
  fi

  if [[ "${mode}" == "auto" ]]; then
    echo "Warning: image preload failed with exit code ${preload_status}; continuing because mode=auto." >&2
    return 0
  fi

  echo "Error: image preload failed with exit code ${preload_status}." >&2
  return "${preload_status}"
}

main
