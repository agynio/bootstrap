locals {
  minio_chart_repo_url = "https://charts.min.io"
  minio_chart_name     = "minio"

  default_sync_options = [
    "CreateNamespace=true",
    "PrunePropagationPolicy=foreground",
    "PruneLast=true",
    "ApplyOutOfSyncOnly=true",
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
    buckets        = []
    users          = []
    policies       = []
    customCommands = []
    svcaccts       = []
  })
}

resource "argocd_repository" "minio" {
  repo = local.minio_chart_repo_url
  type = "helm"
}

resource "argocd_application" "minio" {
  depends_on = [argocd_repository.minio]
  wait       = true

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
      namespace = var.platform_namespace
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
                "host" = "minio.platform.svc.cluster.local"
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
                "host" = "minio.platform.svc.cluster.local"
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

resource "minio_s3_bucket" "files" {
  bucket = var.minio_bucket_name
  acl    = "private"

  depends_on = [
    argocd_application.minio,
    kubernetes_manifest.virtualservice_minio_api,
  ]
}
