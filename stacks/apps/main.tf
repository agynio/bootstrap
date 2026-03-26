locals {
  resolved_reminders_image_tag = trimspace(var.reminders_image_tag) != "" ? var.reminders_image_tag : format("v%s", var.reminders_chart_version)
  platform_chart_repo_host     = "ghcr.io"
  postgres_chart_repo_host     = "ghcr.io"
  postgres_chart_name          = "agynio/charts/postgres-helm"
  reminders_chart_name         = "agynio/charts/reminders"

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
}

resource "argocd_repository" "ghcr" {
  repo       = local.platform_chart_repo_host
  type       = "helm"
  enable_oci = true
}

resource "agyn_app" "reminders" {
  slug        = "reminders"
  name        = "Reminders"
  description = "Delayed message delivery to threads"
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
  depends_on = [argocd_repository.ghcr]
  wait       = true

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
    argocd_repository.ghcr,
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
