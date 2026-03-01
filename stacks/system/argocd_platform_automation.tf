locals {
  argocd_platform_automation_job_script = <<-EOT
    set -euo pipefail

    SECRET_NAMESPACE="$${SECRET_NAMESPACE:-argocd}"
    SECRET_NAME="$${SECRET_NAME:-argocd-platform-automation-token}"
    ACCOUNT_NAME="$${ACCOUNT_NAME:-platform-automation}"
    TOKEN_KEY="$${TOKEN_KEY:-token}"
    JOB_ID="$${JOB_ID:-platform-automation-bootstrap}"
    ARGOCD_DEPLOYMENT="$${ARGOCD_DEPLOYMENT:-argo-cd-argocd-server}"
    ARGOCD_VERSION="$${ARGOCD_VERSION:-v3.3.1}"
    KUBECTL_VERSION="$${KUBECTL_VERSION:-v1.35.0}"
    ARGOCD_SERVER_ADDR="$${ARGOCD_SERVER_ADDR:-argo-cd-argocd-server.argocd.svc.cluster.local}"
    ARGOCD_ADMIN_USERNAME="$${ARGOCD_ADMIN_USERNAME:-admin}"
    ARGOCD_ADMIN_PASSWORD="$${ARGOCD_ADMIN_PASSWORD:-admin}"

    log() {
      printf '%s\n' "$1"
    }

    ensure_curl() {
      if command -v curl >/dev/null 2>&1; then
        return 0
      fi

      if command -v apk >/dev/null 2>&1; then
        log "Installing curl dependencies..."
        apk add --no-cache curl ca-certificates >/dev/null
        return 0
      fi

      echo "curl is required but not available in the container" >&2
      exit 1
    }

    install_kubectl() {
      KUBECTL_URL="https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
      curl -sSL -o /usr/local/bin/kubectl "$${KUBECTL_URL}"
      chmod +x /usr/local/bin/kubectl
    }

    install_argocd() {
      CLI_URL="https://github.com/argoproj/argo-cd/releases/download/$${ARGOCD_VERSION}/argocd-linux-amd64"
      if command -v curl >/dev/null 2>&1; then
        curl -sSL -o /usr/local/bin/argocd "$${CLI_URL}"
      elif command -v wget >/dev/null 2>&1; then
        wget -qO /usr/local/bin/argocd "$${CLI_URL}"
      else
        echo "Neither curl nor wget is available to install argocd CLI" >&2
        exit 1
      fi
      chmod +x /usr/local/bin/argocd
    }

    configure_kubectl() {
      KUBECONFIG_PATH="/tmp/kubeconfig"
      CA_FILE="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      TOKEN_CONTENT="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
      cat <<EOF > "$${KUBECONFIG_PATH}"
apiVersion: v1
clusters:
- cluster:
    certificate-authority: $${CA_FILE}
    server: https://kubernetes.default.svc
  name: in-cluster
contexts:
- context:
    cluster: in-cluster
    namespace: $${SECRET_NAMESPACE}
    user: in-cluster
  name: in-cluster
current-context: in-cluster
kind: Config
preferences: {}
users:
- name: in-cluster
  user:
    token: $${TOKEN_CONTENT}
EOF
      export KUBECONFIG="$${KUBECONFIG_PATH}"
    }

    ensure_curl

    if ! command -v kubectl >/dev/null 2>&1; then
      log "Installing kubectl $${KUBECTL_VERSION}..."
      install_kubectl
    fi

    configure_kubectl

    if ! command -v argocd >/dev/null 2>&1; then
      log "Installing Argo CD CLI $${ARGOCD_VERSION}..."
      install_argocd
    fi

    EXISTING_TOKEN="$(kubectl -n "$${SECRET_NAMESPACE}" get secret "$${SECRET_NAME}" -o jsonpath="{.data.$${TOKEN_KEY}}" 2>/dev/null || true)"

    if [ -n "$${EXISTING_TOKEN}" ]; then
      log "Secret $${SECRET_NAME} already contains a token; skipping generation."
      exit 0
    fi

    log "Waiting for Argo CD server deployment..."
    kubectl -n "$${SECRET_NAMESPACE}" rollout status "deployment/$${ARGOCD_DEPLOYMENT}" --timeout=5m

    log "Logging into Argo CD server..."
    argocd login "$${ARGOCD_SERVER_ADDR}" \
      --username "$${ARGOCD_ADMIN_USERNAME}" \
      --password "$${ARGOCD_ADMIN_PASSWORD}" \
      --insecure \
      --grpc-web >/dev/null

    log "Generating authentication token for $${ACCOUNT_NAME}..."
    TOKEN="$(argocd account generate-token --account "$${ACCOUNT_NAME}" --id "$${JOB_ID}-$(date +%s)")"

    if [ -z "$${TOKEN}" ]; then
      echo "Failed to generate token" >&2
      exit 1
    fi

    log "Persisting automation token secret..."
    kubectl -n "$${SECRET_NAMESPACE}" create secret generic "$${SECRET_NAME}" \
      --from-literal="$${TOKEN_KEY}=$${TOKEN}" \
      --dry-run=client -o yaml | kubectl apply -f -

    log "Token bootstrap complete."
  EOT
}

resource "kubernetes_service_account" "argocd_platform_automation" {
  metadata {
    name      = "argocd-platform-automation"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = "argocd-platform-automation"
      "app.kubernetes.io/component"  = "bootstrap"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_role" "argocd_platform_automation" {
  metadata {
    name      = "argocd-platform-automation"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "create", "patch", "update"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/portforward"]
    verbs      = ["get", "list", "watch", "create"]
  }
}

resource "kubernetes_role_binding" "argocd_platform_automation" {
  metadata {
    name      = "argocd-platform-automation"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.argocd_platform_automation.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.argocd_platform_automation.metadata[0].name
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
}

resource "kubernetes_job_v1" "argocd_platform_automation_token" {
  wait_for_completion = false

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
        service_account_name = kubernetes_service_account.argocd_platform_automation.metadata[0].name
        restart_policy       = "OnFailure"

        container {
          name    = "argocd-token-bootstrap"
          image   = local.argocd_platform_automation_job_image
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
            value = "argo-cd-argocd-server"
          }
          env {
            name  = "ARGOCD_VERSION"
            value = local.argocd_platform_automation_cli_version
          }
          env {
            name  = "KUBECTL_VERSION"
            value = local.argocd_platform_automation_kubectl_version
          }
          env {
            name  = "ARGOCD_SERVER_ADDR"
            value = local.argocd_platform_automation_server_addr
          }
          env {
            name  = "ARGOCD_ADMIN_USERNAME"
            value = local.argocd_platform_automation_admin_username
          }
          env {
            name  = "ARGOCD_ADMIN_PASSWORD"
            value = local.argocd_platform_automation_admin_password
          }
        }
      }
    }
  }

  depends_on = [helm_release.argo_cd]
}
