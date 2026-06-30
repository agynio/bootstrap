locals {
  resolved_gateway_image_tag             = trimspace(var.gateway_image_tag) != "" ? var.gateway_image_tag : var.gateway_chart_version
  resolved_agents_orchestrator_image_tag = trimspace(var.agents_orchestrator_image_tag) != "" ? var.agents_orchestrator_image_tag : var.agents_orchestrator_chart_version
  resolved_threads_image_tag             = trimspace(var.threads_image_tag) != "" ? var.threads_image_tag : var.threads_chart_version
  resolved_metering_image_tag            = trimspace(var.metering_image_tag) != "" ? var.metering_image_tag : var.metering_chart_version
  resolved_tracing_image_tag             = trimspace(var.tracing_image_tag) != "" ? var.tracing_image_tag : format("v%s", var.tracing_chart_version)
  resolved_chat_image_tag                = trimspace(var.chat_image_tag) != "" ? var.chat_image_tag : var.chat_chart_version
  resolved_chat_app_image_tag            = trimspace(var.chat_app_image_tag) != "" ? var.chat_app_image_tag : var.chat_app_chart_version
  resolved_console_app_image_tag         = trimspace(var.console_app_image_tag) != "" ? var.console_app_image_tag : var.console_app_chart_version
  resolved_tracing_app_image_tag         = trimspace(var.tracing_app_image_tag) != "" ? var.tracing_app_image_tag : var.tracing_app_chart_version
  resolved_tracing_app_oidc_client_id    = trimspace(var.tracing_app_oidc_client_id)
  resolved_files_image_tag               = trimspace(var.files_image_tag) != "" ? var.files_image_tag : var.files_chart_version
  resolved_media_proxy_image_tag         = trimspace(var.media_proxy_image_tag) != "" ? var.media_proxy_image_tag : var.media_proxy_chart_version
  resolved_llm_image_tag                 = trimspace(var.llm_image_tag) != "" ? var.llm_image_tag : format("v%s", var.llm_chart_version)
  resolved_llm_proxy_image_tag           = trimspace(var.llm_proxy_image_tag) != "" ? var.llm_proxy_image_tag : var.llm_proxy_chart_version
  resolved_secrets_image_tag             = trimspace(var.secrets_image_tag) != "" ? var.secrets_image_tag : format("v%s", var.secrets_chart_version)
  resolved_token_counting_image_tag      = trimspace(var.token_counting_image_tag) != "" ? var.token_counting_image_tag : format("v%s", var.token_counting_chart_version)
  resolved_notifications_image_tag       = trimspace(var.notifications_image_tag) != "" ? var.notifications_image_tag : var.notifications_chart_version
  resolved_agents_image_tag              = trimspace(var.agents_image_tag) != "" ? var.agents_image_tag : var.agents_chart_version
  resolved_ziti_management_image_tag     = trimspace(var.ziti_management_image_tag) != "" ? var.ziti_management_image_tag : var.ziti_management_chart_version
  resolved_users_image_tag               = trimspace(var.users_image_tag) != "" ? var.users_image_tag : var.users_chart_version
  resolved_expose_image_tag              = trimspace(var.expose_image_tag) != "" ? var.expose_image_tag : var.expose_chart_version
  resolved_organizations_image_tag       = trimspace(var.organizations_image_tag) != "" ? var.organizations_image_tag : var.organizations_chart_version
  resolved_authorization_image_tag       = trimspace(var.authorization_image_tag) != "" ? var.authorization_image_tag : var.authorization_chart_version
  resolved_identity_image_tag            = trimspace(var.identity_image_tag) != "" ? var.identity_image_tag : var.identity_chart_version
  resolved_runners_image_tag             = trimspace(var.runners_image_tag) != "" ? var.runners_image_tag : var.runners_chart_version
  resolved_apps_image_tag                = trimspace(var.apps_image_tag) != "" ? var.apps_image_tag : var.apps_chart_version
  resolved_egress_image_tag              = trimspace(var.egress_image_tag) != "" ? var.egress_image_tag : var.egress_chart_version
  resolved_egress_gateway_image_tag      = trimspace(var.egress_gateway_image_tag) != "" ? var.egress_gateway_image_tag : var.egress_gateway_chart_version

  postgres_image                 = "postgres:16.6-alpine"
  platform_chart_repo_host       = "ghcr.io"
  postgres_chart_repo_host       = "ghcr.io"
  postgres_chart_name            = "agynio/charts/postgres-helm"
  agents_orchestrator_chart_name = "agynio/charts/agents-orchestrator"
  threads_chart_name             = "agynio/charts/threads"
  metering_chart_name            = "agynio/charts/metering"
  tracing_chart_name             = "agynio/charts/tracing"
  chat_chart_name                = "agynio/charts/chat"
  chat_app_chart_name            = "agynio/charts/chat-app"
  console_app_chart_name         = "agynio/charts/console-app"
  tracing_app_chart_name         = "agynio/charts/tracing-app"
  files_chart_name               = "agynio/charts/files"
  media_proxy_chart_name         = "agynio/charts/media-proxy"
  llm_chart_name                 = "agynio/charts/llm"
  llm_proxy_chart_name           = "agynio/charts/llm-proxy"
  secrets_chart_name             = "agynio/charts/secrets"
  token_counting_chart_name      = "agynio/charts/token-counting"
  notifications_chart_name       = "agynio/charts/notifications"
  nats_chart_name                = "nats"
  redis_chart_name               = "redis"
  agents_chart_name              = "agynio/charts/agents"
  ziti_management_chart_name     = "agynio/charts/ziti-management"
  users_chart_name               = "agynio/charts/users"
  expose_chart_name              = "agynio/charts/expose"
  organizations_chart_name       = "agynio/charts/organizations"
  authorization_chart_name       = "agynio/charts/authorization"
  identity_chart_name            = "agynio/charts/identity"
  runners_chart_name             = "agynio/charts/runners"
  apps_chart_name                = "agynio/charts/apps"
  egress_chart_name              = "agynio/charts/egress"
  egress_gateway_chart_name      = "agynio/charts/egress-gateway"
  # DEV/E2E ONLY: this secret name is used by diagnostics tests and must not
  # be published in production deployments.
  ziti_diagnostics_secret_name  = "ziti-diagnostics"
  istio_gateway_namespace       = data.terraform_remote_state.system.outputs.istio_gateway_namespace
  istio_gateway_tls_secret_name = data.terraform_remote_state.system.outputs.wildcard_tls_gateway_secret_name
  ziti_namespace                = data.terraform_remote_state.system.outputs.installed_namespaces[1]
  workload_namespace            = "agyn-workloads"
  openfga_api_url_external      = format("https://openfga.%s:%d", local.base_domain, local.ingress_port)
  openfga_api_url_internal      = format("http://openfga.%s.svc.cluster.local:8080", var.openfga_namespace)
  nats_endpoint                 = format("nats://nats.%s.svc.cluster.local:4222", var.platform_namespace)
  # Deterministic v5 UUID for the cluster admin identity.
  # This is a synthetic identity used only during bootstrap;
  # it does not correspond to a user record in the Users DB.
  cluster_admin_identity_id = "a3c1e9d2-7f4b-5e1a-9c3d-2b8f6a4e7d10"

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

  platform_db_values = yamlencode({
    fullnameOverride = "platform-db"
    postgres = {
      database = "agents"
      username = "agents"
      password = var.platform_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.platform_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "agents", "-d", "agents"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "agents", "-d", "agents"]
      }
    }
  })

  threads_db_values = yamlencode({
    fullnameOverride = "threads-db"
    postgres = {
      database = "threads"
      username = "threads"
      password = var.threads_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.threads_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "threads", "-d", "threads"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "threads", "-d", "threads"]
      }
    }
  })

  metering_db_values = yamlencode({
    fullnameOverride = "metering-db"
    postgres = {
      database = "metering"
      username = "metering"
      password = var.metering_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.metering_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "metering", "-d", "metering"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "metering", "-d", "metering"]
      }
    }
  })

  chat_db_values = yamlencode({
    fullnameOverride = "chat-db"
    postgres = {
      database = "chat"
      username = "chat"
      password = var.chat_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.chat_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "chat", "-d", "chat"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "chat", "-d", "chat"]
      }
    }
  })

  tracing_db_values = yamlencode({
    fullnameOverride = "tracing-db"
    postgres = {
      database = "tracing"
      username = "tracing"
      password = var.tracing_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.tracing_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "tracing", "-d", "tracing"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "tracing", "-d", "tracing"]
      }
    }
  })

  secrets_db_values = yamlencode({
    fullnameOverride = "secrets-db"
    postgres = {
      database = "secrets"
      username = "secrets"
      password = var.secrets_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.secrets_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "secrets", "-d", "secrets"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "secrets", "-d", "secrets"]
      }
    }
  })

  egress_db_values = yamlencode({
    fullnameOverride = "egress-db"
    postgres = {
      database = "egress"
      username = "egress"
      password = var.egress_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.egress_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "egress", "-d", "egress"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "egress", "-d", "egress"]
      }
    }
  })

  llm_db_values = yamlencode({
    fullnameOverride = "llm-db"
    postgres = {
      database = "llm"
      username = "llm"
      password = var.llm_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.llm_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "llm", "-d", "llm"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "llm", "-d", "llm"]
      }
    }
  })

  agents_db_values = yamlencode({
    fullnameOverride = "agents-db"
    postgres = {
      database = "agents"
      username = "agents"
      password = var.agents_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.agents_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "agents", "-d", "agents"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "agents", "-d", "agents"]
      }
    }
  })

  ziti_management_db_values = yamlencode({
    fullnameOverride = "ziti-management-db"
    postgres = {
      database = "ziti_management"
      username = "ziti_management"
      password = var.ziti_management_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.ziti_management_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "ziti_management", "-d", "ziti_management"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "ziti_management", "-d", "ziti_management"]
      }
    }
  })

  users_db_values = yamlencode({
    fullnameOverride = "users-db"
    postgres = {
      database = "users"
      username = "users"
      password = var.users_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.users_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "users", "-d", "users"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "users", "-d", "users"]
      }
    }
  })

  expose_db_values = yamlencode({
    fullnameOverride = "expose-db"
    postgres = {
      database = "expose"
      username = "expose"
      password = var.expose_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.expose_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "expose", "-d", "expose"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "expose", "-d", "expose"]
      }
    }
  })

  organizations_db_values = yamlencode({
    fullnameOverride = "organizations-db"
    postgres = {
      database = "organizations"
      username = "organizations"
      password = var.organizations_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.organizations_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "organizations", "-d", "organizations"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "organizations", "-d", "organizations"]
      }
    }
  })

  agents_orchestrator_db_values = yamlencode({
    fullnameOverride = "agents-orchestrator-db"
    postgres = {
      database = "orchestrator"
      username = "orchestrator"
      password = var.agents_orchestrator_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.agents_orchestrator_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "orchestrator", "-d", "orchestrator"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "orchestrator", "-d", "orchestrator"]
      }
    }
  })

  identity_db_values = yamlencode({
    fullnameOverride = "identity-db"
    postgres = {
      database = "identity"
      username = "identity"
      password = var.identity_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.identity_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "identity", "-d", "identity"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "identity", "-d", "identity"]
      }
    }
  })

  runners_db_values = yamlencode({
    fullnameOverride = "runners-db"
    postgres = {
      database = "runners"
      username = "runners"
      password = var.runners_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.runners_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "runners", "-d", "runners"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "runners", "-d", "runners"]
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

  threads_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "threads"
    service = {
      ports = [
        {
          name       = "grpc"
          port       = 50051
          targetPort = "grpc"
          protocol   = "TCP"
        }
      ]
    }
    env = [
      {
        name  = "GRPC_ADDRESS"
        value = ":50051"
      },
      {
        name  = "DATABASE_URL"
        value = format("postgresql://threads:%s@threads-db:5432/threads?sslmode=disable", var.threads_db_password)
      },
    ]
    securityContext = {
      runAsUser  = 100
      runAsGroup = 101
    }
    image = {
      repository = "ghcr.io/agynio/threads"
      tag        = local.resolved_threads_image_tag
      pullPolicy = "IfNotPresent"
    }
  })

  metering_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "metering"
    image = {
      repository = "ghcr.io/agynio/metering"
      tag        = local.resolved_metering_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "GRPC_ADDRESS"
        value = ":50051"
      },
      {
        name  = "DATABASE_URL"
        value = format("postgresql://metering:%s@metering-db:5432/metering?sslmode=disable", var.metering_db_password)
      },
      {
        name  = "LOG_LEVEL"
        value = "info"
      },
    ]
  })

  tracing_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "tracing"
    service = {
      port = 50051
    }
    extraEnvVars = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://tracing:%s@tracing-db:5432/tracing?sslmode=disable", var.tracing_db_password)
      },
      {
        name  = "ZITI_ENABLED"
        value = "true"
      },
    ]
    image = {
      repository = "ghcr.io/agynio/tracing"
      tag        = local.resolved_tracing_image_tag
      pullPolicy = "IfNotPresent"
    }
  })

  chat_values = yamlencode({
    fullnameOverride = "chat"
    image = {
      repository = "ghcr.io/agynio/chat"
      tag        = local.resolved_chat_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://chat:%s@chat-db:5432/chat?sslmode=disable", var.chat_db_password)
      },
    ]
  })

  secrets_values = yamlencode({
    fullnameOverride = "secrets"
    service = {
      port = 50051
    }
    database = {
      url = format("postgresql://secrets:%s@secrets-db:5432/secrets?sslmode=disable", var.secrets_db_password)
      existingSecret = {
        name = ""
      }
    }
    image = {
      repository = "ghcr.io/agynio/secrets"
      tag        = local.resolved_secrets_image_tag
      pullPolicy = "IfNotPresent"
    }
    secrets = {
      encryptionKeyFile       = "/etc/secrets-encryption/encryptionKey"
      encryptionKeySecretName = "secrets-encryption-key"
    }
    egressRules = {
      grpcTarget = "egress:50051"
    }
  })

  egress_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "egress"
    image = {
      repository = "ghcr.io/agynio/egress"
      tag        = local.resolved_egress_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      { name = "GRPC_ADDRESS", value = ":50051" },
      { name = "DATABASE_URL", value = format("postgresql://egress:%s@egress-db:5432/egress?sslmode=disable", var.egress_db_password) },
      { name = "ZITI_MANAGEMENT_ADDRESS", value = "ziti-management:50051" },
      { name = "AUTHORIZATION_SERVICE_ADDRESS", value = "authorization:50051" },
      { name = "SECRETS_SERVICE_ADDRESS", value = "secrets:50051" },
      { name = "NOTIFICATIONS_ADDRESS", value = "notifications:50051" },
      { name = "RECONCILIATION_INTERVAL", value = "30s" },
    ]
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { cpu = "500m", memory = "256Mi" }
    }
  })

  egress_gateway_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "egress-gateway"
    image = {
      repository = "ghcr.io/agynio/egress-gateway"
      tag        = local.resolved_egress_gateway_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      { name = "GRPC_ADDRESS", value = ":50051" },
      { name = "EGRESS_ADDRESS", value = "egress:50051" },
      { name = "SECRETS_SERVICE_ADDRESS", value = "secrets:50051" },
      { name = "NOTIFICATIONS_ADDRESS", value = "notifications:50051" },
      { name = "METERING_ADDRESS", value = "metering:50051" },
      { name = "TRACING_ADDRESS", value = "tracing:50051" },
      { name = "AGENTS_SERVICE_ADDRESS", value = "agents:50051" },
      { name = "ZITI_MANAGEMENT_ADDRESS", value = "ziti-management:50051" },
      { name = "ZITI_IDENTITY_FILE", value = "/var/lib/ziti/identity.json" },
      { name = "ZITI_LEASE_INTERVAL", value = "30s" },
      { name = "ZITI_SERVICE_NAME", value = "" },
      { name = "EGRESS_CA_CERT_PATH", value = "/var/run/agyn/egress-ca/tls.crt" },
      { name = "EGRESS_CA_KEY_PATH", value = "/var/run/agyn/egress-ca/tls.key" },
    ]
    extraVolumeMounts = [
      { name = "ziti-identity", mountPath = "/var/lib/ziti", readOnly = false },
      { name = "egress-ca", mountPath = "/var/run/agyn/egress-ca", readOnly = true },
    ]
    extraVolumes = [
      { name = "ziti-identity", emptyDir = {} },
      { name = "egress-ca", secret = { secretName = "egress-ca" } },
    ]
    resources = {
      requests = { cpu = "100m", memory = "128Mi" }
      limits   = { cpu = "1000m", memory = "512Mi" }
    }
  })

  agents_values = yamlencode({
    fullnameOverride = "agents"
    image = {
      repository = "ghcr.io/agynio/agents"
      tag        = local.resolved_agents_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://agents:%s@agents-db:5432/agents?sslmode=disable", var.agents_db_password)
      },
    ]
  })

  ziti_management_values = yamlencode({
    fullnameOverride  = "ziti-management"
    zitiControllerUrl = format("https://ziti-mgmt.%s:%d/edge/management/v1", local.base_domain, local.ingress_port)
    image = {
      repository = "ghcr.io/agynio/ziti-management"
      tag        = local.resolved_ziti_management_image_tag
      pullPolicy = "IfNotPresent"
    }
    updateStrategy = {
      type = "Recreate"
    }
    securityContext = {
      enabled                  = true
      runAsNonRoot             = true
      runAsUser                = 100
      runAsGroup               = 101
      readOnlyRootFilesystem   = true
      allowPrivilegeEscalation = false
      capabilities = {
        drop = ["ALL"]
      }
      seccompProfile = {
        type = "RuntimeDefault"
      }
    }
    persistence = {
      enabled    = true
      accessMode = "ReadWriteOnce"
      size       = "10Mi"
    }
    zitiControllerUrl = format("https://ziti-mgmt.%s:%d/edge/management/v1", local.base_domain, local.ingress_port)
    configMounts = [
      {
        name       = "ziti-enrollment"
        sourceName = "ziti-management-enrollment"
        type       = "secret"
        mountPath  = "/etc/ziti-enrollment"
        readOnly   = true
      },
    ]
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://ziti_management:%s@ziti-management-db:5432/ziti_management?sslmode=disable", var.ziti_management_db_password)
      },
      {
        name  = "ZITI_CONTROLLER_URL"
        value = format("https://ziti-mgmt.%s:%d/edge/management/v1", local.base_domain, local.ingress_port)
      },
      {
        name  = "ZITI_CERT_FILE"
        value = "/var/lib/ziti/tls.crt"
      },
      {
        name  = "ZITI_KEY_FILE"
        value = "/var/lib/ziti/tls.key"
      },
      {
        name  = "ZITI_CA_FILE"
        value = "/var/lib/ziti/ca.crt"
      },
      {
        name  = "ZITI_ENROLLMENT_JWT_FILE"
        value = "/etc/ziti-enrollment/enrollmentJwt"
      },
      {
        name  = "ZITI_IDENTITY_NAME_RESOLVE"
        value = "true"
      },
    ]
  })

  users_values = yamlencode({
    fullnameOverride = "users"
    image = {
      repository = "ghcr.io/agynio/users"
      tag        = local.resolved_users_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://users:%s@users-db:5432/users?sslmode=disable", var.users_db_password)
      },
    ]
  })

  expose_values = yamlencode({
    fullnameOverride = "expose"
    image = {
      repository = "ghcr.io/agynio/expose"
      tag        = local.resolved_expose_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://expose:%s@expose-db:5432/expose?sslmode=disable", var.expose_db_password)
      },
      {
        name  = "ZITI_MANAGEMENT_ADDRESS"
        value = "ziti-management:50051"
      },
      {
        name  = "RUNNERS_ADDRESS"
        value = "runners:50051"
      },
      {
        name  = "NOTIFICATIONS_ADDRESS"
        value = "notifications:50051"
      },
      {
        name  = "RECONCILIATION_INTERVAL"
        value = "30s"
      },
    ]
  })

  organizations_values = yamlencode({
    fullnameOverride = "organizations"
    image = {
      repository = "ghcr.io/agynio/organizations"
      tag        = local.resolved_organizations_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://organizations:%s@organizations-db:5432/organizations?sslmode=disable", var.organizations_db_password)
      },
    ]
  })

  identity_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "identity"
    image = {
      repository = "ghcr.io/agynio/identity"
      tag        = local.resolved_identity_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://identity:%s@identity-db:5432/identity?sslmode=disable", var.identity_db_password)
      },
    ]
  })

  runners_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "runners"
    image = {
      repository = "ghcr.io/agynio/runners"
      tag        = local.resolved_runners_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://runners:%s@runners-db:5432/runners?sslmode=disable", var.runners_db_password)
      },
    ]
  })

  apps_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "apps"
    image = {
      repository = "ghcr.io/agynio/apps"
      tag        = local.resolved_apps_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://apps:%s@apps-db:5432/apps?sslmode=disable", var.apps_db_password)
      },
    ]
  })

  agents_orchestrator_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "agents-orchestrator"
    service = {
      enabled = false
    }
    image = {
      repository = "ghcr.io/agynio/agents-orchestrator"
      tag        = local.resolved_agents_orchestrator_image_tag
      pullPolicy = "IfNotPresent"
    }
    env = [
      {
        name  = "DATABASE_URL"
        value = format("postgresql://orchestrator:%s@agents-orchestrator-db:5432/orchestrator?sslmode=disable", var.agents_orchestrator_db_password)
      },
      {
        name  = "POLL_INTERVAL"
        value = "5s"
      },
      {
        name  = "IDLE_TIMEOUT"
        value = "30s"
      },
      {
        name  = "ZITI_ENABLED"
        value = "true"
      },
      {
        name  = "ZITI_SIDECAR_IMAGE"
        value = "openziti/ziti-tunnel:2.0.0"
      },
      {
        name  = "WORKLOAD_DNS_UPSTREAM"
        value = kubernetes_service_v1.ziti_workload_dns.spec[0].cluster_ip
      },
      {
        name  = "ZITI_ENROLLMENT_DNS_UPSTREAM"
        value = "10.43.0.10"
      },
      {
        name  = "ZITI_ENROLLMENT_CONTROLLER_RESOLVE_HOST"
        value = format("ziti-controller-client.%s.svc.cluster.local", local.ziti_namespace)
      },
      {
        name  = "ZITI_ENROLLMENT_CONTROLLER_PORT"
        value = tostring(local.ingress_port)
      },
      {
        name  = "ZITI_RUNTIME_CONTROLLER_RESOLVE_HOST"
        value = format("istio-ingressgateway.%s.svc.cluster.local", local.istio_gateway_namespace)
      },
      {
        name  = "ZITI_RUNTIME_CONTROLLER_PORT"
        value = "443"
      },
      {
        name  = "RUNNER_ADDRESS"
        value = "k8s-runner:50051"
      },
      {
        name  = "RUNNERS_ADDRESS"
        value = "runners:50051"
      },
      {
        name  = "EGRESS_CA_NAMESPACE"
        value = var.platform_namespace
      }

    ]
  })

  authorization_values = yamlencode({
    fullnameOverride = "authorization"
    image = {
      repository = "ghcr.io/agynio/authorization"
      tag        = local.resolved_authorization_image_tag
    }
    env = [
      {
        name  = "GRPC_ADDRESS"
        value = ":50051"
      },
      {
        name  = "OPENFGA_API_URL"
        value = local.openfga_api_url_internal
      },
      {
        name  = "OPENFGA_STORE_ID"
        value = module.openfga_authorization.store_id
      },
      {
        name  = "OPENFGA_MODEL_ID"
        value = module.openfga_authorization.model_id
      }
    ]
    securityContext = {
      runAsUser  = 100
      runAsGroup = 101
    }
  })

  token_counting_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "token-counting"
    service = {
      port = 50051
    }
    image = {
      repository = "ghcr.io/agynio/token-counting"
      tag        = local.resolved_token_counting_image_tag
      pullPolicy = "IfNotPresent"
    }
  })

  redis_values = yamlencode({
    fullnameOverride = "notifications-redis"
    architecture     = "standalone"
    auth = {
      enabled = false
    }
    master = {
      persistence = {
        enabled = false
      }
    }
  })

  notifications_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "notifications"
    image = {
      repository = "ghcr.io/agynio/notifications"
      tag        = local.resolved_notifications_image_tag
      pullPolicy = "IfNotPresent"
    }
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
    env = [
      {
        name  = "GRPC_ADDR"
        value = "0.0.0.0:50051"
      },
      {
        name  = "REDIS_ADDR"
        value = var.notifications_redis_addr
      },
      {
        name  = "REDIS_DB"
        value = "0"
      },
      {
        name  = "REDIS_CHANNEL"
        value = "notifications.v1"
      },
      {
        name  = "LOG_LEVEL"
        value = "info"
      }
    ]
  })

  nats_values = yamlencode({
    fullnameOverride = "nats"
    config = {
      jetstream = {
        enabled = true
        fileStore = {
          enabled = true
          pvc = {
            enabled = true
            size    = var.nats_jetstream_file_store_pvc_size
          }
          maxSize = var.nats_jetstream_file_store_max_size
        }
        memoryStore = {
          enabled = false
        }
      }
    }
    service = {
      enabled = true
      ports = {
        nats = {
          enabled = true
        }
        monitor = {
          enabled = false
        }
      }
    }
    natsBox = {
      enabled = false
    }
    extraResources = [for resource in [
      {
        apiVersion = "v1"
        kind       = "ConfigMap"
        metadata = {
          name = "nats-platform-streams"
          annotations = {
            "argocd.argoproj.io/sync-wave" = "0"
          }
          labels = {
            "app.kubernetes.io/name"       = "nats-platform-streams"
            "app.kubernetes.io/managed-by" = "terraform"
          }
        }
        data = {
          "AGYN_GROUPS.json" = jsonencode({
            name                    = "AGYN_GROUPS"
            subjects                = ["agyn.groups.>"]
            retention               = "limits"
            max_consumers           = -1
            max_msgs                = -1
            max_bytes               = var.nats_platform_stream_max_bytes
            discard                 = "old"
            max_age                 = var.nats_platform_stream_max_age
            max_msgs_per_subject    = -1
            max_msg_size            = -1
            storage                 = "file"
            num_replicas            = var.nats_platform_stream_replicas
            duplicate_window        = var.nats_platform_stream_duplicate_window
            sealed                  = false
            deny_delete             = false
            deny_purge              = false
            allow_rollup_hdrs       = false
            allow_direct            = false
            mirror_direct           = false
            discard_new_per_subject = false
            allow_msg_ttl           = false
            metadata = {
              managed_by = "bootstrap"
            }
          })
          "AGYN_NETWORKS.json" = jsonencode({
            name                    = "AGYN_NETWORKS"
            subjects                = ["agyn.networks.>"]
            retention               = "limits"
            max_consumers           = -1
            max_msgs                = -1
            max_bytes               = var.nats_platform_stream_max_bytes
            discard                 = "old"
            max_age                 = var.nats_platform_stream_max_age
            max_msgs_per_subject    = -1
            max_msg_size            = -1
            storage                 = "file"
            num_replicas            = var.nats_platform_stream_replicas
            duplicate_window        = var.nats_platform_stream_duplicate_window
            sealed                  = false
            deny_delete             = false
            deny_purge              = false
            allow_rollup_hdrs       = false
            allow_direct            = false
            mirror_direct           = false
            discard_new_per_subject = false
            allow_msg_ttl           = false
            metadata = {
              managed_by = "bootstrap"
            }
          })
        }
      },
      {
        apiVersion = "batch/v1"
        kind       = "Job"
        metadata = {
          name = "nats-platform-streams"
          annotations = {
            "argocd.argoproj.io/hook"               = "PostSync"
            "argocd.argoproj.io/hook-delete-policy" = "BeforeHookCreation,HookSucceeded"
            "argocd.argoproj.io/sync-wave"          = "1"
            "helm.sh/hook"                          = "post-install,post-upgrade"
            "helm.sh/hook-delete-policy"            = "before-hook-creation,hook-succeeded"
            "helm.sh/hook-weight"                   = "1"
          }
          labels = {
            "app.kubernetes.io/name"       = "nats-platform-streams"
            "app.kubernetes.io/managed-by" = "terraform"
          }
        }
        spec = {
          backoffLimit = 6
          template = {
            metadata = {
              labels = {
                "app.kubernetes.io/name" = "nats-platform-streams"
              }
            }
            spec = {
              restartPolicy = "OnFailure"
              containers = [
                {
                  name            = "configure-streams"
                  image           = format("natsio/nats-box:%s", var.nats_box_image_tag)
                  imagePullPolicy = "IfNotPresent"
                  env = [
                    {
                      name  = "NATS_URL"
                      value = local.nats_endpoint
                    }
                  ]
                  command = ["/bin/sh", "-ec"]
                  args = [<<-EOT
                    for config in /etc/agyn/nats-streams/*.json; do
                      stream="$(basename "$config" .json)"
                      nats --server "$NATS_URL" \
                        --timeout "${var.nats_platform_stream_wait_timeout}" \
                        stream add --config "$config" --defaults || \
                        nats --server "$NATS_URL" \
                          --timeout "${var.nats_platform_stream_wait_timeout}" \
                          stream edit "$stream" --config "$config" --force
                    done
                  EOT
                  ]
                  volumeMounts = [
                    {
                      name      = "stream-config"
                      mountPath = "/etc/agyn/nats-streams"
                      readOnly  = true
                    }
                  ]
                }
              ]
              volumes = [
                {
                  name = "stream-config"
                  configMap = {
                    name = "nats-platform-streams"
                  }
                }
              ]
            }
          }
        }
      }
    ] : resource if var.nats_platform_streams_enabled]
  })

  files_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "files"
    image = {
      repository = "ghcr.io/agynio/files"
      tag        = local.resolved_files_image_tag
      pullPolicy = "IfNotPresent"
    }
    securityContext = {
      enabled                  = true
      runAsNonRoot             = true
      runAsUser                = 65532
      runAsGroup               = 65532
      readOnlyRootFilesystem   = true
      allowPrivilegeEscalation = false
      capabilities = {
        drop = ["ALL"]
      }
      seccompProfile = {
        type = "RuntimeDefault"
      }
    }
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
    livenessProbe = {
      enabled = true
      grpc = {
        port = 50051
      }
    }
    readinessProbe = {
      enabled = true
      grpc = {
        port = 50051
      }
    }
    files = {
      databaseUrl = {
        value = format("postgresql://files:%s@files-db:5432/files?sslmode=disable", var.files_db_password)
      }
      urlExpiry = "1h"
      s3 = {
        endpoint = "minio.minio.svc.cluster.local:9000"
        bucket   = var.minio_bucket_name
        region   = "us-east-1"
        useSSL   = false
        accessKey = {
          value = var.minio_root_user
        }
        secretKey = {
          value = var.minio_root_password
        }
      }
    }
  })

  media_proxy_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "media-proxy"
    image = {
      repository = "ghcr.io/agynio/media-proxy"
      tag        = local.resolved_media_proxy_image_tag
      pullPolicy = "IfNotPresent"
    }
    containerPorts = [
      {
        name          = "http"
        containerPort = 8080
        protocol      = "TCP"
      }
    ]
    service = {
      enabled = true
      type    = "ClusterIP"
      ports = [
        {
          name       = "http"
          port       = 8080
          targetPort = "http"
          protocol   = "TCP"
        }
      ]
    }
    mediaProxy = {
      listenAddr        = ":8080"
      oidcIssuerUrl     = var.oidc_issuer_url
      oidcClientId      = var.oidc_client_id
      usersGrpcTarget   = "users:50051"
      filesGrpcTarget   = "files:50051"
      corsAllowedOrigin = format("https://chat.%s:%d", local.base_domain, local.ingress_port)
    }
  })

  llm_values = yamlencode({
    fullnameOverride = "llm"
    image = {
      repository = "ghcr.io/agynio/llm"
      tag        = local.resolved_llm_image_tag
      pullPolicy = "IfNotPresent"
    }
    securityContext = {
      enabled                  = true
      runAsNonRoot             = true
      runAsUser                = 65532
      runAsGroup               = 65532
      readOnlyRootFilesystem   = true
      allowPrivilegeEscalation = false
      capabilities = {
        drop = ["ALL"]
      }
      seccompProfile = {
        type = "RuntimeDefault"
      }
    }
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
    livenessProbe = {
      enabled = true
      grpc = {
        port = 50051
      }
    }
    readinessProbe = {
      enabled = true
      grpc = {
        port = 50051
      }
    }
    llm = {
      databaseUrl = {
        value = format("postgresql://llm:%s@llm-db:5432/llm?sslmode=disable", var.llm_db_password)
      }
    }
  })
  chat_app_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "chat-app"
    image = {
      repository = "ghcr.io/agynio/chat-app"
      tag        = local.resolved_chat_app_image_tag
      pullPolicy = "IfNotPresent"
    }
    service = {
      type = "ClusterIP"
      ports = [
        {
          name       = "http"
          port       = 3000
          targetPort = "http"
          protocol   = "TCP"
        }
      ]
    }
    extraVolumes = [
      {
        name     = "chat-app-cache"
        emptyDir = {}
      },
      {
        name     = "chat-app-run"
        emptyDir = {}
      },
      {
        name     = "chat-app-tmp"
        emptyDir = {}
      },
      {
        name     = "chat-app-conf"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "chat-app-cache"
        mountPath = "/var/cache/nginx"
      },
      {
        name      = "chat-app-run"
        mountPath = "/var/run"
      },
      {
        name      = "chat-app-tmp"
        mountPath = "/tmp"
      },
      {
        name      = "chat-app-conf"
        mountPath = "/etc/nginx/conf.d"
      }
    ]
    env = [
      {
        name  = "OIDC_AUTHORITY"
        value = var.oidc_issuer_url
      },
      {
        name  = "OIDC_CLIENT_ID"
        value = var.oidc_client_id
      },
      {
        name  = "OIDC_REDIRECT_URI"
        value = format("https://chat.%s:%d/callback", local.base_domain, local.ingress_port)
      },
      {
        name  = "OIDC_POST_LOGOUT_REDIRECT_URI"
        value = format("https://chat.%s:%d", local.base_domain, local.ingress_port)
      },
      {
        name  = "OIDC_SCOPE"
        value = "openid profile email offline_access"
      },
      {
        name  = "API_BASE_URL"
        value = "/api"
      },
      {
        name  = "MEDIA_PROXY_URL"
        value = format("https://media.%s:%d", local.base_domain, local.ingress_port)
      }
    ]
  })

  console_app_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "console-app"
    image = {
      repository = "ghcr.io/agynio/console-app"
      tag        = local.resolved_console_app_image_tag
      pullPolicy = "IfNotPresent"
    }
    service = {
      type = "ClusterIP"
      ports = [
        {
          name       = "http"
          port       = 3000
          targetPort = "http"
          protocol   = "TCP"
        }
      ]
    }
    extraVolumes = [
      {
        name     = "console-app-cache"
        emptyDir = {}
      },
      {
        name     = "console-app-run"
        emptyDir = {}
      },
      {
        name     = "console-app-tmp"
        emptyDir = {}
      },
      {
        name     = "console-app-conf"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "console-app-cache"
        mountPath = "/var/cache/nginx"
      },
      {
        name      = "console-app-run"
        mountPath = "/var/run"
      },
      {
        name      = "console-app-tmp"
        mountPath = "/tmp"
      },
      {
        name      = "console-app-conf"
        mountPath = "/etc/nginx/conf.d"
      }
    ]
    env = [
      {
        name  = "OIDC_AUTHORITY"
        value = var.oidc_issuer_url
      },
      {
        name  = "OIDC_CLIENT_ID"
        value = var.console_app_oidc_client_id
      },
      {
        name  = "OIDC_SCOPE"
        value = "openid profile email offline_access"
      },
      {
        name  = "API_BASE_URL"
        value = "/api"
      }
    ]
  })

  tracing_app_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "tracing-app"
    image = {
      repository = "ghcr.io/agynio/tracing-app"
      tag        = local.resolved_tracing_app_image_tag
      pullPolicy = "IfNotPresent"
    }
    service = {
      type = "ClusterIP"
      ports = [
        {
          name       = "http"
          port       = 3000
          targetPort = "http"
          protocol   = "TCP"
        }
      ]
    }
    extraVolumes = [
      {
        name     = "tracing-app-cache"
        emptyDir = {}
      },
      {
        name     = "tracing-app-run"
        emptyDir = {}
      },
      {
        name     = "tracing-app-tmp"
        emptyDir = {}
      },
      {
        name     = "tracing-app-conf"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "tracing-app-cache"
        mountPath = "/var/cache/nginx"
      },
      {
        name      = "tracing-app-run"
        mountPath = "/var/run"
      },
      {
        name      = "tracing-app-tmp"
        mountPath = "/tmp"
      },
      {
        name      = "tracing-app-conf"
        mountPath = "/etc/nginx/conf.d"
      }
    ]
    env = [
      {
        name  = "API_BASE_URL"
        value = "/api"
      },
      {
        name  = "OIDC_AUTHORITY"
        value = var.oidc_issuer_url
      },
      {
        name  = "OIDC_CLIENT_ID"
        value = local.resolved_tracing_app_oidc_client_id
      },
      {
        name  = "OIDC_SCOPE"
        value = "openid profile email offline_access"
      }
    ]
  })
}

# NOTE: The module ref (v0.5.2) must be updated in lockstep with
# var.authorization_chart_version to ensure the provisioned FGA model
# matches the model expected by the deployed Helm chart.
module "openfga_authorization" {
  source          = "github.com/agynio/authorization//terraform?ref=v0.5.4"
  openfga_api_url = local.openfga_api_url_external
}

resource "random_password" "cluster_admin_token" {
  length  = 32
  special = false
}

resource "openfga_relationship_tuple" "cluster_admin" {
  store_id               = module.openfga_authorization.store_id
  authorization_model_id = module.openfga_authorization.model_id
  user                   = "identity:${local.cluster_admin_identity_id}"
  relation               = "admin"
  object                 = "cluster:global"

  depends_on = [module.openfga_authorization]
}

resource "kubernetes_namespace" "platform" {
  metadata {
    name = var.platform_namespace
  }
}

resource "kubernetes_namespace_v1" "agyn_workloads" {
  metadata {
    name = "agyn-workloads"
  }
}

# Enrollment JWT for ziti-management self-enrollment at startup.
# The token is created by the ziti stack and passed via remote state.
resource "kubernetes_secret_v1" "ziti_management_enrollment" {
  metadata {
    name      = "ziti-management-enrollment"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  type = "Opaque"

  data = {
    enrollmentJwt = data.terraform_remote_state.ziti.outputs.ziti_management_enrollment_token
  }
}

resource "kubernetes_secret_v1" "egress_gateway_enrollment" {
  metadata {
    name      = "egress-gateway-enrollment"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  type = "Opaque"

  data = {
    enrollmentJwt = data.terraform_remote_state.ziti.outputs.egress_gateway_enrollment_token
  }
}
resource "kubernetes_manifest" "agyn_selfsigned_cluster_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "agyn-selfsigned"
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

resource "kubernetes_manifest" "egress_ca_certificate" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "egress-ca"
      "namespace" = kubernetes_namespace.platform.metadata[0].name
    }
    "spec" = {
      "isCA"        = true
      "commonName"  = "Agyn Egress CA"
      "secretName"  = "egress-ca"
      "duration"    = "87600h"
      "renewBefore" = "8760h"
      "privateKey" = {
        "algorithm"      = "ECDSA"
        "rotationPolicy" = "Always"
        "size"           = 256
      }
      "issuerRef" = {
        "name"  = kubernetes_manifest.agyn_selfsigned_cluster_issuer.manifest.metadata.name
        "kind"  = "ClusterIssuer"
        "group" = "cert-manager.io"
      }
    }
  }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
  ]

  depends_on = [kubernetes_manifest.agyn_selfsigned_cluster_issuer]
}

# DEV/E2E ONLY: ziti-diagnostics contains admin UPDB credentials
# for diagnostics tests. Keep enable_ziti_diagnostics=false in prod.
resource "kubernetes_secret_v1" "ziti_diagnostics" {
  count = var.enable_ziti_diagnostics ? 1 : 0

  metadata {
    name      = local.ziti_diagnostics_secret_name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = data.terraform_remote_state.ziti.outputs.ziti_diagnostics_credentials.username
    password = data.terraform_remote_state.ziti.outputs.ziti_diagnostics_credentials.password
  }
}

resource "kubernetes_role_v1" "ziti_diagnostics_reader" {
  count = var.enable_ziti_diagnostics ? 1 : 0

  metadata {
    name      = "ziti-diagnostics-reader"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = [kubernetes_secret_v1.ziti_diagnostics[0].metadata[0].name]
    verbs          = ["get"]
  }
}

# DEV/E2E ONLY: grants agents-orchestrator-e2e access to the diagnostics
# secret. Production deployments must not create this binding.
resource "kubernetes_role_binding_v1" "ziti_diagnostics_reader" {
  count = var.enable_ziti_diagnostics ? 1 : 0

  metadata {
    name      = "ziti-diagnostics-reader"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.ziti_diagnostics_reader[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "agents-orchestrator-e2e"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }
}

resource "kubernetes_secret_v1" "secrets_encryption_key" {
  metadata {
    name      = "secrets-encryption-key"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  type = "Opaque"

  data = {
    encryptionKey = var.secrets_encryption_key
  }
}

resource "kubernetes_manifest" "virtualservice_chat_app" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "chat-app"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["chat.${local.base_domain}"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/api/"
              }
            },
            {
              "uri" = {
                "exact" = "/api"
              }
            }
          ]
          "rewrite" = {
            "uri" = "/"
          }
          "route" = [
            {
              "destination" = {
                "host" = "gateway.platform.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        },
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/socket.io"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "gateway.platform.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        },
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
                "host" = "chat-app.platform.svc.cluster.local"
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

resource "kubernetes_manifest" "virtualservice_console_app" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "console-app"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["console.${local.base_domain}"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/api/"
              }
            },
            {
              "uri" = {
                "exact" = "/api"
              }
            }
          ]
          "rewrite" = {
            "uri" = "/"
          }
          "route" = [
            {
              "destination" = {
                "host" = "gateway.platform.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        },
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/socket.io"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "gateway.platform.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        },
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
                "host" = "console-app.platform.svc.cluster.local"
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

resource "kubernetes_manifest" "virtualservice_tracing_app" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "tracing-app"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["tracing.${local.base_domain}"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/api/"
              }
            },
            {
              "uri" = {
                "exact" = "/api"
              }
            }
          ]
          "rewrite" = {
            "uri" = "/"
          }
          "route" = [
            {
              "destination" = {
                "host" = "gateway.platform.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        },
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/socket.io"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "gateway.platform.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        },
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
                "host" = "tracing-app.platform.svc.cluster.local"
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

resource "kubernetes_manifest" "virtualservice_gateway" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "gateway"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["gateway.${local.base_domain}"]
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
                "host" = "gateway.platform.svc.cluster.local"
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

resource "kubernetes_manifest" "virtualservice_media_proxy" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "media-proxy"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["media.${local.base_domain}"]
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
                "host" = "media-proxy.platform.svc.cluster.local"
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

resource "kubernetes_manifest" "virtualservice_llm_proxy" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "llm-proxy"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["llm.${local.base_domain}"]
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
                "host" = "llm-proxy.platform.svc.cluster.local"
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

resource "kubernetes_service_v1" "files_db" {
  metadata {
    name      = "files-db"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "files-db"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "files-db"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_stateful_set_v1" "files_db" {
  metadata {
    name      = "files-db"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "files-db"
    }
  }

  spec {
    service_name = kubernetes_service_v1.files_db.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "files-db"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "files-db"
        }
      }

      spec {
        termination_grace_period_seconds = 30

        container {
          name              = "postgres"
          image             = local.postgres_image
          image_pull_policy = "IfNotPresent"
          env {
            name  = "POSTGRES_DB"
            value = "files"
          }
          env {
            name  = "POSTGRES_USER"
            value = "files"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.files_db_password
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          port {
            name           = "postgres"
            container_port = 5432
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "files", "-d", "files"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "files", "-d", "files"]
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = var.files_db_pvc_size
          }
        }
      }
    }
  }
}
resource "argocd_repository" "bitnami_repo" {
  repo = "https://charts.bitnami.com/bitnami"
  type = "helm"
}

resource "argocd_repository" "nats_repo" {
  repo = "https://nats-io.github.io/k8s/helm/charts/"
  type = "helm"
}

resource "argocd_application" "platform_db" {
  wait = true

  metadata {
    name      = "platform-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "5"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.platform_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "threads_db" {
  wait = true

  metadata {
    name      = "threads-db"
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
        values = local.threads_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "metering_db" {
  wait = true

  metadata {
    name      = "metering-db"
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
        values = local.metering_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "chat_db" {
  wait = true

  metadata {
    name      = "chat-db"
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
        values = local.chat_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "tracing_db" {
  wait = true

  metadata {
    name      = "tracing-db"
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
        values = local.tracing_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "secrets_db" {
  wait = true

  metadata {
    name      = "secrets-db"
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
        values = local.secrets_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "egress_db" {
  wait = true

  metadata {
    name      = "egress-db"
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
        values = local.egress_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "llm_db" {
  wait = true

  metadata {
    name      = "llm-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.llm_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "agents_db" {
  wait = true

  metadata {
    name      = "agents-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.agents_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "ziti_management_db" {
  wait = true

  metadata {
    name      = "ziti-management-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.ziti_management_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "users_db" {
  wait = true

  metadata {
    name      = "users-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.users_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "expose_db" {
  wait = true

  metadata {
    name      = "expose-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.expose_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "organizations_db" {
  wait = true

  metadata {
    name      = "organizations-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.organizations_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "agents_orchestrator_db" {
  wait = true

  metadata {
    name      = "agents-orchestrator-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.agents_orchestrator_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "identity_db" {
  wait = true

  metadata {
    name      = "identity-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.identity_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "runners_db" {
  wait = true

  metadata {
    name      = "runners-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.runners_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "apps_db" {
  wait = true

  metadata {
    name      = "apps-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "8"
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
      namespace = kubernetes_namespace.platform.metadata[0].name
    }

    sync_policy {
      # DB apps always use automated sync with prune disabled for stateful safety,
      # independent of var.argocd_automated_sync_enabled.
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

resource "argocd_application" "threads" {
  depends_on = [
    argocd_application.threads_db,
  ]
  metadata {
    name      = "threads"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.threads_chart_name
      target_revision = var.threads_chart_version

      helm {
        values = local.threads_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "metering" {
  depends_on = [
    argocd_application.metering_db,
  ]
  metadata {
    name      = "metering"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.metering_chart_name
      target_revision = var.metering_chart_version

      helm {
        values = local.metering_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "tracing" {
  depends_on = [
    argocd_application.tracing_db,
    argocd_application.ziti_management,
  ]
  metadata {
    name      = "tracing"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.tracing_chart_name
      target_revision = var.tracing_chart_version

      helm {
        values = local.tracing_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "chat" {
  depends_on = [
    argocd_application.chat_db,
    argocd_application.threads,
  ]
  metadata {
    name      = "chat"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.chat_chart_name
      target_revision = var.chat_chart_version

      helm {
        values = local.chat_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "secrets" {
  depends_on = [
    argocd_application.secrets_db,
  ]
  metadata {
    name      = "secrets"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.secrets_chart_name
      target_revision = var.secrets_chart_version

      helm {
        values = local.secrets_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "authorization" {
  depends_on = [
    module.openfga_authorization,
  ]
  wait = true
  metadata {
    name      = "authorization"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.authorization_chart_name
      target_revision = var.authorization_chart_version

      helm {
        values = local.authorization_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "argocd_application" "identity" {
  depends_on = [
    argocd_application.identity_db,
  ]
  metadata {
    name      = "identity"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.identity_chart_name
      target_revision = var.identity_chart_version

      helm {
        values = local.identity_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "token_counting" {
  metadata {
    name      = "token-counting"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.token_counting_chart_name
      target_revision = var.token_counting_chart_version

      helm {
        values = local.token_counting_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "notifications_redis" {
  depends_on = [argocd_repository.bitnami_repo]
  metadata {
    name      = "notifications-redis"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://charts.bitnami.com/bitnami"
      chart           = local.redis_chart_name
      target_revision = var.notifications_redis_chart_version

      helm {
        values = local.redis_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "nats" {
  depends_on = [argocd_repository.nats_repo]
  wait       = true

  metadata {
    name      = "nats"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://nats-io.github.io/k8s/helm/charts/"
      chart           = local.nats_chart_name
      target_revision = var.nats_chart_version

      helm {
        values = local.nats_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

      sync_options = local.postgres_sync_options
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "argocd_application" "runners" {
  depends_on = [
    argocd_application.runners_db,
    argocd_application.identity,
    argocd_application.authorization,
    argocd_application.ziti_management,
  ]
  metadata {
    name      = "runners"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.runners_chart_name
      target_revision = var.runners_chart_version

      helm {
        values = local.runners_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "apps" {
  depends_on = [
    argocd_application.apps_db,
    argocd_application.identity,
    argocd_application.authorization,
    argocd_application.ziti_management,
  ]
  metadata {
    name      = "apps"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.apps_chart_name
      target_revision = var.apps_chart_version

      helm {
        values = local.apps_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "egress" {
  depends_on = [
    argocd_application.egress_db,
    argocd_application.authorization,
    argocd_application.ziti_management,
    argocd_application.secrets,
    argocd_application.notifications,
  ]
  metadata {
    name      = "egress"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "18"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.egress_chart_name
      target_revision = var.egress_chart_version

      helm {
        values = local.egress_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "egress_gateway" {
  depends_on = [
    argocd_application.egress,
    argocd_application.secrets,
    argocd_application.metering,
    argocd_application.tracing,
    argocd_application.notifications,
    kubernetes_manifest.egress_ca_certificate,
  ]
  metadata {
    name      = "egress-gateway"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "19"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.egress_gateway_chart_name
      target_revision = var.egress_gateway_chart_version

      helm {
        values = local.egress_gateway_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "agents" {
  depends_on = [
    argocd_application.agents_db,
  ]
  metadata {
    name      = "agents"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.agents_chart_name
      target_revision = var.agents_chart_version

      helm {
        values = local.agents_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "ziti_management" {
  depends_on = [
    argocd_application.ziti_management_db,
  ]

  metadata {
    name      = "ziti-management"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.ziti_management_chart_name
      target_revision = var.ziti_management_chart_version

      helm {
        values = local.ziti_management_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "users" {
  depends_on = [
    argocd_application.users_db,
  ]
  wait = true
  metadata {
    name      = "users"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.users_chart_name
      target_revision = var.users_chart_version

      helm {
        values = local.users_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "expose" {
  depends_on = [
    argocd_application.expose_db,
    argocd_application.ziti_management,
    argocd_application.runners,
    argocd_application.notifications,
  ]
  wait = true
  metadata {
    name      = "expose"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.expose_chart_name
      target_revision = var.expose_chart_version

      helm {
        values = local.expose_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "organizations" {
  depends_on = [
    argocd_application.organizations_db,
    argocd_application.authorization,
  ]
  metadata {
    name      = "organizations"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.organizations_chart_name
      target_revision = var.organizations_chart_version

      helm {
        values = local.organizations_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "llm" {
  depends_on = [
    argocd_application.llm_db,
  ]
  metadata {
    name      = "llm"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.llm_chart_name
      target_revision = var.llm_chart_version

      helm {
        values = local.llm_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "minio_s3_bucket" "files" {
  bucket = var.minio_bucket_name
  acl    = "private"
}

resource "argocd_application" "files" {
  depends_on = [
    kubernetes_stateful_set_v1.files_db,
    minio_s3_bucket.files,
  ]
  metadata {
    name      = "files"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.files_chart_name
      target_revision = var.files_chart_version

      helm {
        values = local.files_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "notifications" {
  depends_on = [
    argocd_application.notifications_redis,
  ]
  metadata {
    name      = "notifications"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.notifications_chart_name
      target_revision = var.notifications_chart_version

      helm {
        values = local.notifications_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "agents_orchestrator" {
  depends_on = [
    argocd_application.agents_orchestrator_db,
    argocd_application.ziti_management,
    argocd_application.threads,
    argocd_application.notifications,
    argocd_application.agents,
    argocd_application.secrets,
    argocd_application.runners,
    argocd_application.egress,
    kubernetes_manifest.egress_ca_certificate,
  ]
  metadata {
    name      = "agents-orchestrator"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "19"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.agents_orchestrator_chart_name
      target_revision = var.agents_orchestrator_chart_version

      helm {
        values = local.agents_orchestrator_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "media_proxy" {
  depends_on = [
    argocd_application.users,
    argocd_application.files,
    argocd_application.authorization,
  ]
  metadata {
    name      = "media-proxy"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "20"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.media_proxy_chart_name
      target_revision = var.media_proxy_chart_version

      helm {
        values = local.media_proxy_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "chat_app" {
  metadata {
    name      = "chat-app"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "25"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.chat_app_chart_name
      target_revision = var.chat_app_chart_version

      helm {
        values = local.chat_app_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "console_app" {
  metadata {
    name      = "console-app"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "25"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.console_app_chart_name
      target_revision = var.console_app_chart_version

      helm {
        values = local.console_app_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "tracing_app" {
  metadata {
    name      = "tracing-app"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "25"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.tracing_app_chart_name
      target_revision = var.tracing_app_chart_version

      helm {
        values = local.tracing_app_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "gateway" {
  depends_on = [argocd_application.llm, argocd_application.ziti_management, argocd_application.expose]
  wait       = true
  metadata {
    name      = "gateway"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "30"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = "ghcr.io"
      chart           = "agynio/charts/gateway"
      target_revision = var.gateway_chart_version

      helm {
        values = yamlencode({
          replicaCount     = 1
          fullnameOverride = "gateway"
          image = {
            tag = local.resolved_gateway_image_tag
          }
          gateway = {
            oidcIssuerUrl           = var.oidc_issuer_url
            oidcClientId            = var.oidc_client_id
            clusterAdminToken       = random_password.cluster_admin_token.result
            clusterAdminIdentityId  = local.cluster_admin_identity_id
            usersGrpcTarget         = "users:50051"
            organizationsGrpcTarget = "organizations:50051"
            egressRulesGrpcTarget   = "egress:50051"
          }
          env = [
            {
              name  = "ZITI_ENABLED"
              value = "true"
            },
          ]
        })
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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

resource "argocd_application" "llm_proxy" {
  depends_on = [
    argocd_application.llm,
    argocd_application.users,
    argocd_application.authorization,
    argocd_application.ziti_management,
  ]
  metadata {
    name      = "llm-proxy"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "30"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.llm_proxy_chart_name
      target_revision = var.llm_proxy_chart_version

      helm {
        values = yamlencode({
          replicaCount     = 1
          fullnameOverride = "llm-proxy"
          image = {
            tag = local.resolved_llm_proxy_image_tag
          }
          securityContext = {
            enabled                  = true
            runAsNonRoot             = true
            runAsUser                = 65532
            runAsGroup               = 65532
            readOnlyRootFilesystem   = true
            allowPrivilegeEscalation = false
            capabilities = {
              drop = ["ALL"]
            }
            seccompProfile = {
              type = "RuntimeDefault"
            }
          }
          env = [
            {
              name  = "ZITI_ENABLED"
              value = "true"
            },
          ]
        })
      }
    }

    destination {
      server    = var.destination_server
      namespace = kubernetes_namespace.platform.metadata[0].name
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
