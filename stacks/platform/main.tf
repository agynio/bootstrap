locals {
  platform_server_values = yamlencode({
    replicaCount = var.platform_server_replica_count
    image = {
      repository = "ghcr.io/agynio/platform-server"
      tag        = "0.13.2"
      pullPolicy = "IfNotPresent"
    }
    fullnameOverride = "platform-server"
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
      },
      {
        name     = "data"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "tmp"
        mountPath = "/tmp"
      },
      {
        name      = "data"
        mountPath = "/opt/app/data"
      },
      {
        name      = "data"
        mountPath = "/opt/app/packages/platform-server/data"
      },
      {
        name      = "data"
        mountPath = "/data"
      }
    ]
    env = [
      {
        name  = "LLM_PROVIDER"
        value = "litellm"
      },
      {
        name  = "LITELLM_BASE_URL"
        value = "http://litellm.platform.svc.cluster.local:4000"
      },
      {
        name  = "LITELLM_MASTER_KEY"
        value = "sk-dev-master"
      },
      {
        name  = "AGENTS_DATABASE_URL"
        value = "postgresql://postgres:postgres@postgres.platform.svc.cluster.local:5432/agents"
      },
      {
        name  = "DOCKER_RUNNER_SHARED_SECRET"
        value = "dev-shared-secret"
      },
      {
        name  = "DOCKER_RUNNER_BASE_URL"
        value = "http://docker-runner.platform.svc.cluster.local:7171"
      },
      {
        name  = "DOCKER_RUNNER_GRPC_HOST"
        value = "docker-runner"
      },
      {
        name  = "DOCKER_RUNNER_GRPC_PORT"
        value = "7171"
      },
      {
        name  = "NCPS_ENABLED"
        value = "false"
      },
      {
        name  = "VAULT_ENABLED"
        value = "false"
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
    fullnameOverride = "docker-runner"
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
    env = [
      {
        name  = "DOCKER_RUNNER_SHARED_SECRET"
        value = "dev-shared-secret"
      },
      {
        name  = "DOCKER_RUNNER_GRPC_HOST"
        value = "0.0.0.0"
      },
      {
        name  = "DOCKER_RUNNER_PORT"
        value = "7171"
      },
      {
        name  = "DOCKER_RUNNER_SIGNATURE_TTL_MS"
        value = "60000"
      },
      {
        name  = "DOCKER_RUNNER_LOG_LEVEL"
        value = "info"
      }
    ]
    service = {
      enabled = true
      ports = [
        {
          name       = "http"
          port       = 7171
          targetPort = "http"
          protocol   = "TCP"
        }
      ]
    }
    containerPorts = [
      {
        name          = "http"
        containerPort = 7171
        protocol      = "TCP"
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
