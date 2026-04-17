locals {
  resolved_reminders_image_tag  = trimspace(var.reminders_image_tag) != "" ? var.reminders_image_tag : format("v%s", var.reminders_chart_version)
  resolved_k8s_runner_image_tag = trimspace(var.k8s_runner_image_tag) != "" ? var.k8s_runner_image_tag : var.k8s_runner_chart_version
  admin_oidc_subject            = trimspace(var.admin_oidc_subject)
  platform_chart_repo_host      = "ghcr.io"
  postgres_chart_repo_host      = "ghcr.io"
  postgres_chart_name           = "agynio/charts/postgres-helm"
  reminders_chart_name          = "agynio/charts/reminders"
  k8s_runner_chart_name         = "agynio/charts/k8s-runner"
  users_gateway_url             = format("%s/agynio.api.gateway.v1.UsersGateway", local.gateway_url)

  default_sync_options = [
    "CreateNamespace=true",
    "PrunePropagationPolicy=foreground",
    "PruneLast=true",
    "ApplyOutOfSyncOnly=true",
  ]

  postgres_sync_options = [
    "CreateNamespace=true",
    "ApplyOutOfSyncOnly=true",
    "RespectIgnoreDifferences=true",
  ]

  reminders_db_values = yamlencode({
    fullnameOverride = "reminders-db"
    postgres = {
      database = "reminders"
      username = "reminders"
      password = var.reminders_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.reminders_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "reminders", "-d", "reminders"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "reminders", "-d", "reminders"]
      }
    }
  })

  reminders_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "reminders"
    service = {
      port = 8080
    }
    image = {
      repository = "ghcr.io/agynio/reminders"
      tag        = local.resolved_reminders_image_tag
      pullPolicy = "IfNotPresent"
    }
    extraVolumes = [
      {
        name     = "ziti"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "ziti"
        mountPath = "/ziti"
      }
    ]
    env = [
      {
        name  = "HTTP_ADDRESS"
        value = ":8080"
      },
      {
        name  = "DATABASE_URL"
        value = format("postgresql://reminders:%s@reminders-db:5432/reminders?sslmode=disable", var.reminders_db_password)
      },
      {
        name  = "ZITI_IDENTITY_FILE"
        value = "/ziti/identity.json"
      },
      {
        name  = "ZITI_SERVICE_NAME"
        value = "app-reminders"
      },
      {
        name  = "GATEWAY_SERVICE_NAME"
        value = "gateway"
      },
      {
        name  = "GATEWAY_URL"
        value = "http://gateway-gateway.platform.svc.cluster.local:8080"
      },
      {
        name = "SERVICE_TOKEN"
        valueFrom = {
          secretKeyRef = {
            name = "reminders-service-token"
            key  = "token"
          }
        }
      },
    ]
  })

  k8s_runner_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "k8s-runner"
    image = {
      repository = "ghcr.io/agynio/k8s-runner"
      tag        = local.resolved_k8s_runner_image_tag
      pullPolicy = "IfNotPresent"
    }
    rbac = {
      clusterWide = true
    }
    securityContext = {
      runAsNonRoot             = true
      runAsUser                = 100
      runAsGroup               = 101
      readOnlyRootFilesystem   = true
      allowPrivilegeEscalation = false
    }
    env = [
      {
        name  = "KUBE_NAMESPACE"
        value = "agyn-workloads"
      },
      {
        name  = "ZITI_ENABLED"
        value = "true"
      },
      {
        name  = "GATEWAY_ADDRESS"
        value = "gateway-gateway:8080"
      },
      {
        name = "SERVICE_TOKEN"
        valueFrom = {
          secretKeyRef = {
            name = "k8s-runner-service-token"
            key  = "token"
          }
        }
      }
    ]
    containerPorts = [
      {
        name          = "grpc"
        containerPort = 50051
        protocol      = "TCP"
      }
    ]
    service = {
      enabled = true
      type    = "ClusterIP"
      ports = [
        {
          name       = "grpc"
          port       = 50051
          targetPort = "grpc"
          protocol   = "TCP"
        }
      ]
    }
  })
}

resource "agyn_organization" "platform" {
  name = "Platform"
}

resource "agyn_app" "reminders" {
  organization_id = agyn_organization.platform.id
  slug            = "reminders"
  name            = "Reminders"
  description     = "Delayed message delivery to threads"
  visibility      = "internal"
  permissions     = ["thread:write"]
}

resource "agyn_app_installation" "reminders" {
  app_id          = agyn_app.reminders.id
  organization_id = agyn_organization.platform.id
  slug            = "reminders"
}

resource "kubernetes_secret_v1" "reminders_service_token" {
  metadata {
    name      = "reminders-service-token"
    namespace = var.platform_namespace
  }

  type = "Opaque"

  data = {
    token = agyn_app.reminders.service_token
  }
}

resource "argocd_application" "reminders_db" {
  wait = true

  metadata {
    name      = "reminders-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "7"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.reminders_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.platform_namespace
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety.
      automated {
        prune       = false
        self_heal   = true
        allow_empty = false
      }

      sync_options = local.postgres_sync_options
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "argocd_application" "reminders" {
  depends_on = [
    argocd_application.reminders_db,
    kubernetes_secret_v1.reminders_service_token,
  ]

  metadata {
    name      = "reminders"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "30"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.reminders_chart_name
      target_revision = var.reminders_chart_version

      helm {
        values = local.reminders_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.platform_namespace
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }

      sync_options = local.default_sync_options
    }
  }
}

resource "agyn_runner" "k8s_runner" {
  name = "k8s-runner"
  labels = {
    type = "kubernetes"
  }
}

resource "kubernetes_secret_v1" "k8s_runner_service_token" {
  metadata {
    name      = "k8s-runner-service-token"
    namespace = var.platform_namespace
  }

  type = "Opaque"

  data = {
    token = agyn_runner.k8s_runner.service_token
  }
}

resource "argocd_application" "k8s_runner" {
  depends_on = [
    kubernetes_secret_v1.k8s_runner_service_token,
  ]

  metadata {
    name      = "k8s-runner"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "18"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.k8s_runner_chart_name
      target_revision = var.k8s_runner_chart_version

      helm {
        values = local.k8s_runner_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.platform_namespace
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }

      sync_options = local.default_sync_options
    }
  }
}

resource "null_resource" "bootstrap_admin_oidc_user" {
  triggers = {
    admin_oidc_subject       = local.admin_oidc_subject
    gateway_url              = local.gateway_url
    cluster_admin_token_hash = sha256(local.cluster_admin_token)
  }

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]

    environment = {
      ADMIN_OIDC_SUBJECT = local.admin_oidc_subject
      ADMIN_TOKEN        = local.cluster_admin_token
      GATEWAY_URL        = local.gateway_url
      USERS_GATEWAY_URL  = local.users_gateway_url
    }

    command = <<-EOT
      set -euo pipefail

      if ! command -v python3 >/dev/null 2>&1; then
        echo "Error: python3 is required to provision the admin OIDC user." >&2
        exit 1
      fi

      create_response="$(mktemp)"
      update_response="$(mktemp)"

      cleanup() {
        rm -f "$create_response" "$update_response"
      }
      trap cleanup EXIT

      show_response_snippet() {
        local label="$1"
        local status="$2"
        local file="$3"

        python3 - "$label" "$status" "$file" <<'PY'
import sys

label = sys.argv[1]
status = sys.argv[2]
path = sys.argv[3]

with open(path, "rb") as handle:
    data = handle.read()

snippet = data.decode("utf-8", errors="replace")[:200]
sys.stderr.write(f"{label} failed (status {status}): {snippet}\n")
PY
      }

      create_payload="$(python3 - <<'PY'
import json
import os

oidc_subject = os.environ["ADMIN_OIDC_SUBJECT"]
print(json.dumps({"oidcSubject": oidc_subject, "name": oidc_subject}))
PY
      )"

      create_status=$(curl -sk --compressed -o "$create_response" -w "%%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "Connect-Protocol-Version: 1" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        "$USERS_GATEWAY_URL/CreateUser" \
        -d "$create_payload")

      if [[ "$create_status" != "200" ]]; then
        show_response_snippet "CreateUser" "$create_status" "$create_response"
        exit 1
      fi

      identity_id="$(python3 - "$create_response" "$create_status" <<'PY'
import json
import sys

path = sys.argv[1]
status = sys.argv[2]

with open(path, "rb") as handle:
    data = handle.read()

try:
    payload = json.loads(data)
except json.JSONDecodeError:
    snippet = data.decode("utf-8", errors="replace")[:200]
    sys.stderr.write(f"CreateUser response not JSON (status {status}): {snippet}\n")
    sys.exit(1)

user = payload.get("user") or {}
meta = user.get("meta") or {}
identity_id = meta.get("id") or ""
if not identity_id:
    raise SystemExit("CreateUser response missing user.meta.id")
print(identity_id)
PY
      )"

      update_payload="$(IDENTITY_ID="$identity_id" python3 - <<'PY'
import json
import os

identity_id = os.environ["IDENTITY_ID"]
print(json.dumps({"identityId": identity_id, "clusterRole": "CLUSTER_ROLE_ADMIN"}))
PY
      )"

      update_status=$(curl -sk --compressed -o "$update_response" -w "%%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "Connect-Protocol-Version: 1" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        "$USERS_GATEWAY_URL/UpdateUser" \
        -d "$update_payload")

      if [[ "$update_status" != "200" ]]; then
        if python3 - "$update_response" "$update_status" <<'PY'; then
import json
import sys

path = sys.argv[1]
status = sys.argv[2]

with open(path, "rb") as handle:
    data = handle.read()

try:
    payload = json.loads(data)
except json.JSONDecodeError:
    snippet = data.decode("utf-8", errors="replace")[:200]
    sys.stderr.write(f"UpdateUser response not JSON (status {status}): {snippet}\n")
    sys.exit(1)

code = str(payload.get("code", "")).lower()
message = str(payload.get("message", "")).lower()

if code == "already_exists" or "already exists" in message:
    sys.exit(0)

snippet = data.decode("utf-8", errors="replace")[:200]
sys.stderr.write(f"UpdateUser failed (status {status}): {snippet}\n")
sys.exit(1)
PY
        then
          echo "Cluster admin role already set for $identity_id."
          exit 0
        fi
        exit 1
      fi

      echo "Cluster admin role ensured for $ADMIN_OIDC_SUBJECT (identity $identity_id)."
    EOT
  }

  depends_on = [agyn_organization.platform]
}
