locals {
  resolved_reminders_image_tag  = trimspace(var.reminders_image_tag) != "" ? var.reminders_image_tag : format("v%s", var.reminders_chart_version)
  resolved_k8s_runner_image_tag = trimspace(var.k8s_runner_image_tag) != "" ? var.k8s_runner_image_tag : var.k8s_runner_chart_version
  resolved_apps_image_tag       = trimspace(var.apps_image_tag) != "" ? var.apps_image_tag : var.apps_chart_version
  platform_chart_repo_host      = "ghcr.io"
  postgres_chart_repo_host      = "ghcr.io"
  postgres_chart_name           = "agynio/charts/postgres-helm"
  reminders_chart_name          = "agynio/charts/reminders"
  k8s_runner_chart_name         = "agynio/charts/k8s-runner"
  apps_labels = {
    "app.kubernetes.io/name" = "apps"
  }

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

  apps_db_values = yamlencode({
    fullnameOverride = "apps-db"
    postgres = {
      database = "apps"
      username = "apps"
      password = var.apps_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.apps_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "apps", "-d", "apps"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "apps", "-d", "apps"]
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

resource "argocd_application" "apps_db" {
  wait = true

  metadata {
    name      = "apps-db"
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
        values = local.apps_db_values
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

resource "kubernetes_service_account_v1" "apps" {
  metadata {
    name      = "apps"
    namespace = var.platform_namespace
    labels    = local.apps_labels
  }
}

resource "kubernetes_service_v1" "apps" {
  metadata {
    name      = "apps"
    namespace = var.platform_namespace
    labels    = local.apps_labels
  }

  spec {
    selector = local.apps_labels
    type     = "ClusterIP"

    port {
      name        = "grpc"
      port        = 50051
      target_port = "grpc"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_deployment_v1" "apps" {
  depends_on = [argocd_application.apps_db]

  metadata {
    name      = "apps"
    namespace = var.platform_namespace
    labels    = local.apps_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.apps_labels
    }

    template {
      metadata {
        labels = local.apps_labels
      }

      spec {
        service_account_name = kubernetes_service_account_v1.apps.metadata[0].name

        container {
          name              = "apps"
          image             = "ghcr.io/agynio/apps:${local.resolved_apps_image_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "grpc"
            container_port = 50051
            protocol       = "TCP"
          }

          env {
            name  = "GRPC_ADDRESS"
            value = ":50051"
          }

          env {
            name  = "DATABASE_URL"
            value = format("postgresql://apps:%s@apps-db:5432/apps?sslmode=disable", var.apps_db_password)
          }

          env {
            name  = "IDENTITY_GRPC_TARGET"
            value = "identity:50051"
          }

          env {
            name  = "AUTHORIZATION_GRPC_TARGET"
            value = "authorization:50051"
          }

          env {
            name  = "ZITI_MANAGEMENT_GRPC_TARGET"
            value = "ziti-management:50051"
          }

          liveness_probe {
            tcp_socket {
              port = "grpc"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 1
            failure_threshold     = 3
            success_threshold     = 1
          }

          readiness_probe {
            tcp_socket {
              port = "grpc"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 1
            failure_threshold     = 3
            success_threshold     = 1
          }
        }
      }
    }
  }
}

resource "time_sleep" "apps_gateway_settle" {
  depends_on = [
    kubernetes_deployment_v1.apps,
    kubernetes_service_v1.apps,
  ]

  create_duration = "45s"
}

resource "agyn_app" "reminders" {
  depends_on  = [time_sleep.apps_gateway_settle]
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
