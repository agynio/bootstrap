#!/bin/sh
set -euo pipefail

log() {
  printf '[vault-auto-init] %s\n' "$@"
}

WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-300}"
CHECK_INTERVAL_SECONDS="${CHECK_INTERVAL_SECONDS:-5}"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_VERSION="${VAULT_VERSION:-1.17.2}"
DATA_DIR="${VAULT_AUTO_INIT_DATA_DIR:-/vault/data}"
CLUSTER_KEYS_FILE="${DATA_DIR}/cluster-keys.json"
ROOT_TOKEN_FILE="${DATA_DIR}/root-token.txt"
UNSEAL_KEYS_FILE="${DATA_DIR}/unseal-keys.txt"
DEV_ROOT_FILE="${DATA_DIR}/dev-root.txt"
DEV_ROOT_TOKEN="${VAULT_DEV_ROOT_TOKEN:-dev-root}"

root_token=""
unseal_key=""

umask 077
mkdir -p "$DATA_DIR"
export VAULT_ADDR

ensure_tooling() {
  packages=""
  for pkg in curl jq unzip; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      packages="$packages $pkg"
    fi
  done

  if [ -n "$(printf '%s' "$packages" | tr -d ' ')" ]; then
    log "installing packages:$packages"
    apk add --no-cache $packages >/dev/null
  fi

  if ! command -v vault >/dev/null 2>&1; then
    log "installing vault ${VAULT_VERSION}"
    tmp_zip="$(mktemp)"
    curl -fsSL "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" -o "$tmp_zip"
    unzip -oq "$tmp_zip" -d /usr/local/bin
    chmod +x /usr/local/bin/vault
    rm -f "$tmp_zip"
  fi
}

write_secure_file() {
  dest="$1"
  content="$2"
  tmp_file="$(mktemp)"
  printf '%s\n' "$content" > "$tmp_file"
  chmod 600 "$tmp_file"
  mv "$tmp_file" "$dest"
}

load_artifacts() {
  if [ -z "$root_token" ] && [ -f "$ROOT_TOKEN_FILE" ]; then
    root_token="$(cat "$ROOT_TOKEN_FILE" 2>/dev/null || true)"
  fi
  if [ -z "$unseal_key" ] && [ -f "$UNSEAL_KEYS_FILE" ]; then
    unseal_key="$(cat "$UNSEAL_KEYS_FILE" 2>/dev/null || true)"
  fi
}

wait_for_health() {
  elapsed=0
  while true; do
    if response=$(curl -fsS "$VAULT_ADDR/v1/sys/health" 2>/dev/null); then
      printf '%s' "$response"
      return 0
    fi

    if [ "$elapsed" -ge "$WAIT_TIMEOUT_SECONDS" ]; then
      log "ERROR: Vault API unreachable after ${WAIT_TIMEOUT_SECONDS}s"
      sleep 5
      elapsed=0
    fi

    sleep 1
    elapsed=$((elapsed + 1))
  done
}

ensure_initialized() {
  initialized_flag="$1"

  if [ "$initialized_flag" = "true" ]; then
    load_artifacts
    return
  fi

  log "initializing vault"
  init_json="$(vault operator init -key-shares=1 -key-threshold=1 -format=json)"
  printf '%s\n' "$init_json" > "$CLUSTER_KEYS_FILE"
  chmod 600 "$CLUSTER_KEYS_FILE"

  root_token="$(printf '%s' "$init_json" | jq -r '.root_token // empty')"
  unseal_key="$(printf '%s' "$init_json" | jq -r '.unseal_keys_b64[0] // empty')"

  if [ -z "$root_token" ] || [ -z "$unseal_key" ]; then
    log "ERROR: failed to parse init response"
    exit 1
  fi

  write_secure_file "$ROOT_TOKEN_FILE" "$root_token"
  write_secure_file "$UNSEAL_KEYS_FILE" "$unseal_key"
}

ensure_unsealed() {
  load_artifacts

  if [ -z "$unseal_key" ]; then
    log "ERROR: Vault sealed but unseal key unavailable"
    exit 1
  fi

  log "vault sealed -> unsealing"
  vault operator unseal "$unseal_key" >/dev/null
}

ensure_dev_root_token() {
  load_artifacts

  if [ -z "$root_token" ]; then
    log "WARN: root token unavailable; skipping dev-root token reconcile"
    return
  fi

  if ! VAULT_TOKEN="$root_token" vault token lookup "$DEV_ROOT_TOKEN" >/dev/null 2>&1; then
    log "creating dev-root token"
    VAULT_TOKEN="$root_token" vault token create -id="$DEV_ROOT_TOKEN" -policy=root >/dev/null 2>&1
  fi

  if [ ! -f "$DEV_ROOT_FILE" ] || [ "$(cat "$DEV_ROOT_FILE" 2>/dev/null || true)" != "$DEV_ROOT_TOKEN" ]; then
    write_secure_file "$DEV_ROOT_FILE" "$DEV_ROOT_TOKEN"
  fi
}

ensure_tooling

while true; do
  health="$(wait_for_health)"

  initialized="$(printf '%s' "$health" | jq -r '.initialized // false')"
  ensure_initialized "$initialized"

  if [ "$initialized" != "true" ]; then
    sleep 2
    continue
  fi

  sealed="$(printf '%s' "$health" | jq -r '.sealed // true')"
  if [ "$sealed" = "true" ]; then
    ensure_unsealed
    sleep 2
    continue
  fi

  ensure_dev_root_token
  sleep "$CHECK_INTERVAL_SECONDS"
done
