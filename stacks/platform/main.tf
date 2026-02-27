locals {
  platform_server_values = yamlencode({
    replicaCount = var.platform_server_replica_count
    image = {
      repository = "ghcr.io/agynio/platform-server"
      tag        = "0.13.2"
      pullPolicy = "IfNotPresent"
    }
    securityContext = {
      enabled                  = true
      runAsNonRoot             = true
      runAsUser                = 1000
      runAsGroup               = 1000
      readOnlyRootFilesystem   = true
      allowPrivilegeEscalation = false
      capabilities = {
        drop = ["ALL"]
      }
      seccompProfile = {
        type = "RuntimeDefault"
      }
    }
    podSecurityContext = {
      enabled = true
      fsGroup = 1000
    }
    extraVolumes = [
      {
        name     = "tmp"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "tmp"
        mountPath = "/tmp"
      }
    ]
  })

  docker_runner_values = yamlencode({
    replicaCount = var.docker_runner_replica_count
    image = {
      repository = "ghcr.io/agynio/docker-runner"
      tag        = "main"
      pullPolicy = "IfNotPresent"
    }
    securityContext = {
      enabled                  = true
      runAsNonRoot             = true
      runAsUser                = 1000
      runAsGroup               = 1000
      readOnlyRootFilesystem   = true
      allowPrivilegeEscalation = false
      capabilities = {
        drop = ["ALL"]
      }
      seccompProfile = {
        type = "RuntimeDefault"
      }
    }
    podSecurityContext = {
      enabled = true
      fsGroup = 1000
    }
    serviceAccount = {
      create = false
      name   = "default"
    }
    automountServiceAccountToken = true
    extraVolumes = [
      {
        name     = "tmp"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "tmp"
        mountPath = "/tmp"
      }
    ]
  })
}

resource "argocd_application" "platform_server" {
  metadata {
    name      = "platform-server"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = var.platform_repo_url
      target_revision = var.platform_target_revision
      path            = "charts/platform-server"

      helm {
        values = local.platform_server_values
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

      sync_options = [
        "CreateNamespace=true",
        "PrunePropagationPolicy=foreground",
        "PruneLast=true",
        "ApplyOutOfSyncOnly=true",
      ]
    }
  }
}

resource "argocd_application" "docker_runner" {
  metadata {
    name      = "docker-runner"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = var.platform_repo_url
      target_revision = var.platform_target_revision
      path            = "charts/docker-runner"

      helm {
        values = local.docker_runner_values
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

      sync_options = [
        "CreateNamespace=true",
        "PrunePropagationPolicy=foreground",
        "PruneLast=true",
        "ApplyOutOfSyncOnly=true",
      ]
    }
  }
}
