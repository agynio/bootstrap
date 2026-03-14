locals {
  minio_chart_repo_url     = "https://charts.min.io"
  minio_chart_name         = "minio"
  openfga_chart_repo_url   = "https://openfga.github.io/helm-charts"
  openfga_chart_name       = "openfga"
  postgres_chart_repo_host = "ghcr.io"
  postgres_chart_name      = "agynio/charts/postgres-helm"

  default_sync_options = [
    "PrunePropagationPolicy=foreground",
    "PruneLast=true",
    "ApplyOutOfSyncOnly=true",
  ]

  postgres_sync_options = [
    "CreateNamespace=true",
    "ApplyOutOfSyncOnly=true",
    "RespectIgnoreDifferences=true",
  ]

  minio_values = yamlencode({
    fullnameOverride = "minio"
    mode             = "standalone"
    replicas         = 1
    rootUser         = var.minio_root_user
    rootPassword     = var.minio_root_password
    image = {
      repository = "quay.io/minio/minio"
      tag        = var.minio_image_tag
      pullPolicy = "IfNotPresent"
    }
    persistence = {
      enabled = true
      size    = var.minio_pvc_size
    }
    resources = {
      requests = {
        memory = "256Mi"
      }
    }
    buckets        = []
    users          = []
    policies       = []
    customCommands = []
    svcaccts       = []
  })

  openfga_db_values = yamlencode({
    fullnameOverride = "openfga-db"
    postgres = {
      database = "openfga"
      username = "openfga"
      password = var.openfga_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.openfga_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "openfga", "-d", "openfga"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "openfga", "-d", "openfga"]
      }
    }
  })

  openfga_values = yamlencode({
    fullnameOverride = "openfga"
    replicaCount     = 1
    datastore = {
      engine          = "postgres"
      uri             = format("postgresql://openfga:%s@openfga-db:5432/openfga?sslmode=disable", var.openfga_db_password)
      applyMigrations = true
    }
    postgresql = {
      enabled = false
    }
    authn = {
      method = "none"
    }
    grpc = {
      addr = "0.0.0.0:8081"
    }
    http = {
      enabled = true
      addr    = "0.0.0.0:8080"
    }
    playground = {
      enabled = true
      port    = 3000
    }
  })
}

resource "kubernetes_namespace" "minio" {
  metadata {
    name = var.minio_namespace
  }
}

resource "kubernetes_namespace" "openfga" {
  metadata {
    name = var.openfga_namespace
  }
}

resource "argocd_repository" "minio" {
  repo = local.minio_chart_repo_url
  type = "helm"
}

resource "argocd_repository" "postgres" {
  repo       = local.postgres_chart_repo_host
  type       = "helm"
  enable_oci = true
}

resource "argocd_repository" "openfga" {
  repo = local.openfga_chart_repo_url
  type = "helm"
}

resource "argocd_application" "minio" {
  depends_on = [
    argocd_repository.minio,
    kubernetes_namespace.minio,
  ]
  wait = true

  metadata {
    name      = "minio"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = local.minio_chart_repo_url
      chart           = local.minio_chart_name
      target_revision = var.minio_chart_version

      helm {
        values = local.minio_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.minio_namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = var.argocd_automated_sync_enabled ? [1] : []
        content {
          prune       = var.argocd_prune_enabled
          self_heal   = var.argocd_self_heal_enabled
          allow_empty = false
        }
      }

      sync_options = local.default_sync_options
    }
  }

  timeouts {
    create = "10m"
    update = "5m"
    delete = "5m"
  }
}

resource "argocd_application" "openfga_db" {
  depends_on = [
    argocd_repository.postgres,
    kubernetes_namespace.openfga,
  ]
  wait = true

  metadata {
    name      = "openfga-db"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.openfga_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.openfga_namespace
    }

    sync_policy {
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

resource "argocd_application" "openfga" {
  depends_on = [
    argocd_repository.openfga,
    argocd_application.openfga_db,
    kubernetes_namespace.openfga,
  ]
  wait = true

  metadata {
    name      = "openfga"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = local.openfga_chart_repo_url
      chart           = local.openfga_chart_name
      target_revision = var.openfga_chart_version

      helm {
        values = local.openfga_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.openfga_namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = var.argocd_automated_sync_enabled ? [1] : []
        content {
          prune       = var.argocd_prune_enabled
          self_heal   = var.argocd_self_heal_enabled
          allow_empty = false
        }
      }

      sync_options = local.default_sync_options
    }
  }

  timeouts {
    create = "10m"
    update = "5m"
    delete = "5m"
  }
}

resource "kubernetes_manifest" "virtualservice_minio_console" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "minio"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["minio.${local.base_domain}"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "minio-console.minio.svc.cluster.local"
                "port" = {
                  "number" = 9001
                }
              }
            }
          ]
        }
      ]
    }
  }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
  ]

  depends_on = [
    data.terraform_remote_state.system,
  ]
}

resource "kubernetes_manifest" "virtualservice_minio_api" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "minio-api"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["minio-api.${local.base_domain}"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "minio.minio.svc.cluster.local"
                "port" = {
                  "number" = 9000
                }
              }
            }
          ]
        }
      ]
    }
  }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
  ]

  depends_on = [
    data.terraform_remote_state.system,
  ]
}

resource "kubernetes_manifest" "virtualservice_openfga" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "openfga"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["openfga.${local.base_domain}"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "openfga.openfga.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        }
      ]
    }
  }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
  ]

  depends_on = [
    data.terraform_remote_state.system,
  ]
}

resource "kubernetes_manifest" "virtualservice_openfga_playground" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "openfga-playground"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["openfga-playground.${local.base_domain}"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "openfga.openfga.svc.cluster.local"
                "port" = {
                  "number" = 3000
                }
              }
            }
          ]
        }
      ]
    }
  }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
  ]

  depends_on = [
    data.terraform_remote_state.system,
  ]
}
