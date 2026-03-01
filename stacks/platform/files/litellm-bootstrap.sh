set -euo pipefail
echo "[litellm-bootstrap] installing tooling"
apk add --no-cache ca-certificates curl jq >/dev/null

KUBECTL_VERSION="v1.29.2"
curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

api="$LITELLM_BASE_URL"
alias="$LITELLM_DEFAULT_ALIAS"

raw_master="$LITELLM_MASTER_KEY"
master_key="$raw_master"
if printf '%s' "$raw_master" | base64 -d >/tmp/master-key 2>/dev/null; then
  master_key="$(cat /tmp/master-key)"
fi
rm -f /tmp/master-key

echo "[litellm-bootstrap] waiting for LiteLLM..."
health_ready() {
  url="$1"
  code=$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)
  code=$(echo "${code:-000}" | tr -d '\r\n')
  case "$code" in
    200|401|403) return 0 ;;
    *) return 1 ;;
  esac
}

for i in $(seq 1 180); do
  if health_ready "$api/health" || health_ready "$api/v1/health"; then
    break
  fi
  sleep 1
  if [ "$i" = "180" ]; then
    echo "[litellm-bootstrap] ERROR: LiteLLM not reachable"
    exit 1
  fi
done

auth="Authorization: Bearer $master_key"
ct="Content-Type: application/json"

gen_body='{"key_alias":"'"$alias"'","duration":null,"metadata":{"bootstrap":true}}'

try_generate() {
  base="$1"
  url="$base/key/generate"
  echo "[litellm-bootstrap] POST $url"
  resp=$(curl -sS -w '\n%{http_code}' -H "$auth" -H "$ct" -d "$gen_body" "$url" || true)
  code=$(echo "$resp" | tail -n1)
  body=$(echo "$resp" | sed '$d')
  echo "$code" > /tmp/code
  echo "$body" > /tmp/body
}

try_generate "$api"
code=$(cat /tmp/code)
body=$(cat /tmp/body)

if [ "$code" = "404" ]; then
  try_generate "$api/v1"
  code=$(cat /tmp/code)
  body=$(cat /tmp/body)
fi

normalized="$(printf '%s' "$body" | tr '[:upper:]' '[:lower:]')"
status_reason="unknown"

case "$code" in
  2??)
    echo "[litellm-bootstrap] key generate response code=$code"
    status_reason="generated"
    ;;
  409)
    echo "[litellm-bootstrap] key generate response conflict code=$code"
    status_reason="exists"
    ;;
  400)
    if printf '%s' "$normalized" | grep -q 'alias' && printf '%s' "$normalized" | grep -q 'already exists'; then
      echo "[litellm-bootstrap] key alias already exists (code=$code)"
      status_reason="alias-exists"
    else
      echo "[litellm-bootstrap] ERROR: key generation failed code=$code body=$body"
      exit 1
    fi
    ;;
  *)
    echo "[litellm-bootstrap] ERROR: key generation failed code=$code body=$body"
    exit 1
    ;;
esac

key=$(echo "$body" | tr -d '\n' | sed -n 's/.*"key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1 || true)

if [ -n "$key" ]; then
  echo "[litellm-bootstrap] got key; writing secret ${NAMESPACE}/${OUTPUT_SECRET_NAME}"
  kubectl -n "$NAMESPACE" apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${OUTPUT_SECRET_NAME}
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  ${OUTPUT_SECRET_KEY}: "$key"
EOF
else
  echo "[litellm-bootstrap] no key returned (${status_reason}); attempting to reuse existing secret ${OUTPUT_SECRET_NAME}."
  selector="{.data.${OUTPUT_SECRET_KEY}}"
  existing_b64="$(kubectl -n "$NAMESPACE" get secret "$OUTPUT_SECRET_NAME" -o jsonpath="${selector}" 2>/dev/null || true)"
  if [ -z "$existing_b64" ]; then
    existing_b64="$(kubectl -n "$NAMESPACE" get secret "$OUTPUT_SECRET_NAME" -o jsonpath='{.data.LITELLM_DEFAULT_KEY}' 2>/dev/null || true)"
  fi

  if [ -n "$existing_b64" ]; then
    existing_plain="$(printf '%s' "$existing_b64" | base64 -d 2>/dev/null || true)"
    if [ -n "$existing_plain" ]; then
      echo "[litellm-bootstrap] reusing stored key; enforcing ${OUTPUT_SECRET_KEY}."
      patch_payload="$(printf '{"stringData":{"%s":"%s"}}' "$OUTPUT_SECRET_KEY" "$existing_plain")"
      kubectl -n "$NAMESPACE" patch secret "$OUTPUT_SECRET_NAME" --type merge -p "$patch_payload" >/dev/null
    else
      echo "[litellm-bootstrap] existing secret data unreadable; leaving ${OUTPUT_SECRET_NAME} unchanged."
    fi
  else
    echo "[litellm-bootstrap] no existing key to reuse; leaving ${OUTPUT_SECRET_NAME} unchanged."
  fi
fi

echo "[litellm-bootstrap] done"
