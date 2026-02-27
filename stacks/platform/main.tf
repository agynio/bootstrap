locals {
  platform_server_values = yamlencode(
    merge(
      {
        replicaCount = var.platform_server_replica_count
      },
      var.platform_server_image_tag != "" ? {
        image = {
          tag = var.platform_server_image_tag
        }
      } : {}
    )
  )

  docker_runner_values = yamlencode(
    merge(
      {
        replicaCount = var.docker_runner_replica_count
      },
      var.docker_runner_image_tag != "" ? {
        image = {
          tag = var.docker_runner_image_tag
        }
      } : {}
    )
  )
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
