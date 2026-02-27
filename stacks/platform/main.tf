locals {
  resolved_platform_server_image_tag = trimspace(var.platform_server_image_tag) != "" ? var.platform_server_image_tag : var.platform_target_revision
  resolved_docker_runner_image_tag   = trimspace(var.docker_runner_image_tag) != "" ? var.docker_runner_image_tag : var.platform_target_revision
  resolved_platform_ui_image_tag     = local.resolved_platform_server_image_tag

  vault_chart_version            = "0.28.1"
  bitnami_charts_repo_url        = "https://github.com/bitnami/charts.git"
  postgresql_chart_path          = "bitnami/postgresql"
  postgresql_chart_revision      = "postgresql/15.5.17"
  registry_mirror_repo_url       = "https://github.com/twuni/docker-registry.helm.git"
  registry_mirror_chart_path     = "."
  registry_mirror_chart_revision = "v2.2.2"
  litellm_chart_repo_url         = "https://github.com/BerriAI/litellm.git"
  litellm_chart_path             = "deploy/charts/litellm-helm"
  litellm_chart_revision         = "adb9d94833cfc38d615e92ca12cef58a5897817a"
  litellm_image_repository       = "ghcr.io/berriai/litellm-database"
  litellm_image_tag              = "main-1.80.15-stable.1"

  default_sync_options = [
    "CreateNamespace=true",
    "PrunePropagationPolicy=foreground",
    "PruneLast=true",
    "ApplyOutOfSyncOnly=true",
  ]

  vault_standalone_config = <<-EOT
    listener "tcp" {
      address = "0.0.0.0:8200"
      tls_disable = 1
    }

    storage "file" {
      path = "/vault/data"
    }

    ui = true
  EOT

  platform_db_values = yamlencode({
    image = {
      registry   = "docker.io"
      repository = "bitnami/postgresql"
      tag        = "latest"
      digest     = "sha256:e8b68936d05ee665974430bb4765fedcdc5c9ba399e133e120e2deed77f54dbf"
      pullPolicy = "IfNotPresent"
    }
    auth = {
      username = "agents"
      password = var.platform_db_password
      database = "agents"
    }
    primary = {
      persistence = {
        enabled = true
        size    = var.platform_db_pvc_size
      }
    }
  })

  litellm_db_values = yamlencode({
    image = {
      registry   = "docker.io"
      repository = "bitnami/postgresql"
      tag        = "latest"
      digest     = "sha256:e8b68936d05ee665974430bb4765fedcdc5c9ba399e133e120e2deed77f54dbf"
      pullPolicy = "IfNotPresent"
    }
    auth = {
      username = "litellm"
      password = var.litellm_db_password
      database = "litellm"
    }
    primary = {
      persistence = {
        enabled = true
        size    = var.litellm_db_pvc_size
      }
    }
  })

  vault_values = yamlencode({
    fullnameOverride = "vault"
    server = {
      ha = {
        enabled = false
      }
      standalone = {
        enabled = true
        config  = trimspace(local.vault_standalone_config)
      }
      dataStorage = {
        enabled = true
        size    = var.vault_pvc_size
      }
    }
    ui = {
      enabled = true
    }
  })

  registry_mirror_values = yamlencode({
    fullnameOverride = "registry-mirror"
    persistence = {
      enabled = true
      size    = var.registry_mirror_pvc_size
    }
    proxy = {
      enabled   = true
      remoteurl = "https://registry-1.docker.io"
    }
  })

  litellm_values = yamlencode({
    fullnameOverride = "litellm"
    image = {
      repository = local.litellm_image_repository
      tag        = local.litellm_image_tag
      pullPolicy = "IfNotPresent"
    }
    service = {
      port = 4000
      type = "ClusterIP"
    }
    db = {
      deployStandalone = false
      useExisting      = false
    }
    envVars = {
      LITELLM_MASTER_KEY = var.litellm_master_key
      LITELLM_SALT_KEY   = var.litellm_salt_key
      DATABASE_URL       = format("postgresql://litellm:%s@litellm-db-postgresql:5432/litellm", var.litellm_db_password)
    }
    proxy_config = {
      model_list = [
        {
          model_name = "health-check"
          litellm_params = {
            model   = "openai/fake"
            api_key = "placeholder"
          }
        }
      ]
      general_settings = {
        master_key = "os.environ/LITELLM_MASTER_KEY"
      }
    }
    migrationJob = {
      enabled = true
    }
  })

  docker_runner_values = yamlencode({
    replicaCount = var.docker_runner_replica_count
    image = {
      repository = "ghcr.io/agynio/docker-runner"
      tag        = local.resolved_docker_runner_image_tag
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
        value = var.docker_runner_shared_secret
      },
      {
        name  = "DOCKER_RUNNER_GRPC_HOST"
        value = "0.0.0.0"
      },
      {
        name  = "DOCKER_RUNNER_PORT"
        value = "7071"
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
          name       = "grpc"
          port       = 7071
          targetPort = "grpc"
          protocol   = "TCP"
        }
      ]
    }
    containerPorts = [
      {
        name          = "grpc"
        containerPort = 7071
        protocol      = "TCP"
      }
    ]
  })

  platform_server_values = yamlencode({
    replicaCount = var.platform_server_replica_count
    image = {
      repository = "ghcr.io/agynio/platform-server"
      tag        = local.resolved_platform_server_image_tag
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
    initContainers = [
      {
        name            = "platform-server-migrations"
        image           = format("ghcr.io/agynio/platform-server:%s", local.resolved_platform_server_image_tag)
        imagePullPolicy = "IfNotPresent"
        command         = ["corepack"]
        args = [
          "pnpm",
          "--dir",
          "/opt/app/packages/platform-server",
          "exec",
          "prisma",
          "migrate",
          "deploy",
        ]
        env = [
          {
            name  = "AGENTS_DATABASE_URL"
            value = format("postgresql://agents:%s@platform-db-postgresql:5432/agents", var.platform_db_password)
          },
          {
            name  = "NODE_ENV"
            value = "production"
          }
        ]
        volumeMounts = [
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
        securityContext = {
          runAsNonRoot = true
          runAsUser    = 1000
          runAsGroup   = 1000
        }
      }
    ]
    env = [
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "PORT"
        value = "3010"
      },
      {
        name  = "AGENTS_DATABASE_URL"
        value = format("postgresql://agents:%s@platform-db-postgresql:5432/agents", var.platform_db_password)
      },
      {
        name  = "LLM_PROVIDER"
        value = "litellm"
      },
      {
        name  = "LITELLM_BASE_URL"
        value = "http://litellm:4000"
      },
      {
        name  = "LITELLM_MASTER_KEY"
        value = var.litellm_master_key
      },
      {
        name  = "LITELLM_SALT_KEY"
        value = var.litellm_salt_key
      },
      {
        name  = "DOCKER_RUNNER_GRPC_HOST"
        value = "docker-runner"
      },
      {
        name  = "DOCKER_RUNNER_GRPC_PORT"
        value = "7071"
      },
      {
        name  = "DOCKER_RUNNER_SHARED_SECRET"
        value = var.docker_runner_shared_secret
      },
      {
        name  = "VAULT_ENABLED"
        value = "true"
      },
      {
        name  = "VAULT_ADDR"
        value = "http://vault:8200"
      },
      {
        name  = "VAULT_TOKEN"
        value = var.vault_token
      },
      {
        name  = "GRAPH_BRANCH"
        value = "v0.10.1"
      },
      {
        name  = "GRAPH_AUTHOR_NAME"
        value = "Agyn Platform"
      },
      {
        name  = "GRAPH_AUTHOR_EMAIL"
        value = "rowan.stein@agyn.io"
      }
    ]
  })

  platform_ui_values = yamlencode({
    image = {
      repository = "ghcr.io/agynio/platform-ui"
      tag        = local.resolved_platform_ui_image_tag
      pullPolicy = "IfNotPresent"
    }
    fullnameOverride = "platform-ui"
    service = {
      type = "NodePort"
      ports = [
        {
          name       = "http"
          port       = 3000
          targetPort = "http"
          protocol   = "TCP"
        }
      ]
    }
    env = [
      {
        name  = "API_UPSTREAM"
        value = "http://platform-server:3010"
      }
    ]
  })
}

resource "argocd_repository" "bitnami_charts" {
  repo = local.bitnami_charts_repo_url
  type = "git"
}

resource "argocd_repository" "twuni_docker_registry" {
  repo = local.registry_mirror_repo_url
  type = "git"
}

resource "argocd_repository" "litellm_repo" {
  repo = local.litellm_chart_repo_url
  type = "git"
}

resource "argocd_application" "platform_db" {
  depends_on = [argocd_repository.bitnami_charts]
  metadata {
    name      = "platform-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "0"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.bitnami_charts_repo_url
      target_revision = local.postgresql_chart_revision
      path            = local.postgresql_chart_path

      helm {
        values = local.platform_db_values
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

resource "argocd_application" "litellm_db" {
  depends_on = [argocd_repository.bitnami_charts]
  metadata {
    name      = "litellm-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "0"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.bitnami_charts_repo_url
      target_revision = local.postgresql_chart_revision
      path            = local.postgresql_chart_path

      helm {
        values = local.litellm_db_values
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

resource "argocd_application" "vault" {
  metadata {
    name      = "vault"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "1"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://helm.releases.hashicorp.com"
      chart           = "vault"
      target_revision = local.vault_chart_version

      helm {
        values = local.vault_values
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

resource "argocd_application" "registry_mirror" {
  depends_on = [argocd_repository.twuni_docker_registry]
  metadata {
    name      = "registry-mirror"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "1"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.registry_mirror_repo_url
      target_revision = local.registry_mirror_chart_revision
      path            = local.registry_mirror_chart_path

      helm {
        values = local.registry_mirror_values
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

resource "argocd_application" "litellm" {
  depends_on = [argocd_repository.litellm_repo]
  metadata {
    name      = "litellm"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "2"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.litellm_chart_repo_url
      target_revision = local.litellm_chart_revision
      path            = local.litellm_chart_path

      helm {
        values = local.litellm_values
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

resource "argocd_application" "docker_runner" {
  metadata {
    name      = "docker-runner"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "3"
    }
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

      sync_options = local.default_sync_options
    }
  }
}

resource "argocd_application" "platform_server" {
  metadata {
    name      = "platform-server"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "4"
    }
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

      sync_options = local.default_sync_options
    }
  }
}

resource "argocd_application" "platform_ui" {
  metadata {
    name      = "platform-ui"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "5"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = var.platform_repo_url
      target_revision = var.platform_target_revision
      path            = "charts/platform-ui"

      helm {
        values = local.platform_ui_values
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
