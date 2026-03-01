locals {
  argocd_platform_automation_job_script = <<-EOT
    set -euo pipefail

    SECRET_NAMESPACE="$${SECRET_NAMESPACE:-argocd}"
    SECRET_NAME="$${SECRET_NAME:-argocd-platform-automation-token}"
    ACCOUNT_NAME="$${ACCOUNT_NAME:-platform-automation}"
    TOKEN_KEY="$${TOKEN_KEY:-token}"
    JOB_ID="$${JOB_ID:-platform-automation-bootstrap}"
    ARGOCD_DEPLOYMENT="$${ARGOCD_DEPLOYMENT:-argocd-server}"

    log() {
      printf '%s\n' "$1"
    }

    log "Waiting for Argo CD server deployment..."
    kubectl -n "$${SECRET_NAMESPACE}" rollout status "deployment/$${ARGOCD_DEPLOYMENT}" --timeout=300s

    EXISTING_TOKEN="$(kubectl -n "$${SECRET_NAMESPACE}" get secret "$${SECRET_NAME}" -o jsonpath="{.data.$${TOKEN_KEY}}" 2>/dev/null || true)"

    if [ -n "$${EXISTING_TOKEN}" ]; then
      log "Secret $${SECRET_NAME} already contains a token; skipping generation."
      exit 0
    fi

    log "Generating authentication token for $${ACCOUNT_NAME}..."
    TOKEN="$(argocd account generate-token --core --account "$${ACCOUNT_NAME}" --id "$${JOB_ID}-$(date +%s)")"

    if [ -z "$${TOKEN}" ]; then
      echo "Failed to generate token" >&2
      exit 1
    fi

    log "Writing token to $${SECRET_NAMESPACE}/$${SECRET_NAME}..."
    kubectl -n "$${SECRET_NAMESPACE}" create secret generic "$${SECRET_NAME}" \
      --from-literal="$${TOKEN_KEY}=$${TOKEN}" \
      --dry-run=client -o yaml | kubectl apply -f -

    log "Token bootstrap complete."
  EOT
}

resource "kubernetes_job_v1" "argocd_platform_automation_token" {
  metadata {
    name      = "argocd-platform-automation-token"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = "argocd-platform-automation-token"
      "app.kubernetes.io/component"  = "bootstrap"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    ttl_seconds_after_finished = 600
    backoff_limit              = 5

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "argocd-platform-automation-token"
          "app.kubernetes.io/component" = "bootstrap"
        }
      }

      spec {
        service_account_name = "argocd-server"
        restart_policy       = "OnFailure"

        container {
          name    = "argocd-token-bootstrap"
          image   = local.argocd_platform_automation_image
          command = ["/bin/sh", "-c"]
          args    = [local.argocd_platform_automation_job_script]
          env {
            name  = "SECRET_NAMESPACE"
            value = kubernetes_namespace.argocd.metadata[0].name
          }
          env {
            name  = "SECRET_NAME"
            value = "argocd-platform-automation-token"
          }
          env {
            name  = "TOKEN_KEY"
            value = "token"
          }
          env {
            name  = "ACCOUNT_NAME"
            value = "platform-automation"
          }
          env {
            name  = "JOB_ID"
            value = "platform-automation-bootstrap"
          }
          env {
            name  = "ARGOCD_DEPLOYMENT"
            value = "argocd-server"
          }
        }
      }
    }
  }

  depends_on = [helm_release.argo_cd]
}
