locals {
  resolved_platform_server_image_tag = trimspace(var.platform_server_image_tag) != "" ? var.platform_server_image_tag : var.platform_target_revision
  resolved_docker_runner_image_tag   = trimspace(var.docker_runner_image_tag) != "" ? var.docker_runner_image_tag : var.platform_target_revision
  resolved_platform_ui_image_tag     = local.resolved_platform_server_image_tag

  postgres_image                 = "postgres:16.6-alpine"
  vault_chart_version            = "0.28.1"
  registry_mirror_repo_url       = "https://github.com/twuni/docker-registry.helm.git"
  registry_mirror_chart_path     = "."
  registry_mirror_chart_revision = "v2.2.2"
  litellm_chart_repo_host        = "ghcr.io"
  litellm_chart_repo_url         = "oci://ghcr.io/berriai/litellm-helm"
  litellm_chart_name             = "litellm-helm"
  litellm_chart_full_name        = replace(local.litellm_chart_repo_url, "oci://${local.litellm_chart_repo_host}/", "")
  litellm_chart_revision         = "1.81.12-stable.1"
  istio_gateway_namespace        = data.terraform_remote_state.system.outputs.istio_gateway_namespace
  istio_gateway_tls_secret_name  = data.terraform_remote_state.system.outputs.wildcard_tls_gateway_secret_name

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

  vault_auto_init_script = <<-EOT
    #!/bin/sh
    set -euo pipefail

    log() {
      printf '[vault-auto-init] %s\n' "$@"
    }

    WAIT_TIMEOUT_SECONDS="$${WAIT_TIMEOUT_SECONDS:-300}"
    CHECK_INTERVAL_SECONDS="$${CHECK_INTERVAL_SECONDS:-5}"
    VAULT_ADDR="$${VAULT_ADDR:-http://127.0.0.1:8200}"
    VAULT_VERSION="$${VAULT_VERSION:-1.17.2}"
    DATA_DIR="$${VAULT_AUTO_INIT_DATA_DIR:-/vault/data}"
    CLUSTER_KEYS_FILE="$${DATA_DIR}/cluster-keys.json"
    ROOT_TOKEN_FILE="$${DATA_DIR}/root-token.txt"
    UNSEAL_KEYS_FILE="$${DATA_DIR}/unseal-keys.txt"
    DEV_ROOT_FILE="$${DATA_DIR}/dev-root.txt"
    DEV_ROOT_TOKEN="$${VAULT_DEV_ROOT_TOKEN:-dev-root}"
    EXIT_AFTER_UNSEAL="$${EXIT_AFTER_UNSEAL:-false}"
    PERSIST_ROOT_TOKEN="$${PERSIST_ROOT_TOKEN:-true}"
    PERSIST_UNSEAL_KEY="$${PERSIST_UNSEAL_KEY:-true}"
    PERSIST_DEV_ROOT_TOKEN="$${PERSIST_DEV_ROOT_TOKEN:-true}"

    umask 077
    mkdir -p "$DATA_DIR"
    export VAULT_ADDR

    root_token=""
    unseal_key=""

    ensure_tooling() {
      packages=""
      for pkg in curl jq unzip; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
          packages="$packages $pkg"
        fi
      done

      if [ -n "$(printf '%s' "$packages" | tr -d ' ')" ]; then
        log "installing packages:$packages"
        apk add --no-cache $packages >/dev/null
      fi

      if ! command -v vault >/dev/null 2>&1; then
        log "installing vault $VAULT_VERSION"
        tmp_zip="$(mktemp)"
        curl -fsSL "$(printf 'https://releases.hashicorp.com/vault/%s/vault_%s_linux_amd64.zip' "$VAULT_VERSION" "$VAULT_VERSION")" -o "$tmp_zip"
        unzip -oq "$tmp_zip" -d /usr/local/bin
        chmod +x /usr/local/bin/vault
        rm -f "$tmp_zip"
      fi
    }

    write_secure_file() {
      dest="$1"
      content="$2"
      tmp_file="$(mktemp)"
      printf '%s\n' "$content" > "$tmp_file"
      chmod 600 "$tmp_file"
      mv "$tmp_file" "$dest"
    }

    load_artifacts() {
      if [ -z "$root_token" ] && [ -f "$ROOT_TOKEN_FILE" ]; then
        root_token="$(cat "$ROOT_TOKEN_FILE" 2>/dev/null || true)"
      fi
      if [ -z "$unseal_key" ] && [ -f "$UNSEAL_KEYS_FILE" ]; then
        unseal_key="$(cat "$UNSEAL_KEYS_FILE" 2>/dev/null || true)"
      fi
    }

    wait_for_health() {
      elapsed=0
      while true; do
        if response=$(curl -sS "$VAULT_ADDR/v1/sys/health" 2>/dev/null); then
          printf '%s' "$response"
          return 0
        fi

        if [ "$elapsed" -ge "$WAIT_TIMEOUT_SECONDS" ]; then
          log "$(printf 'ERROR: Vault API unreachable after %ss' "$WAIT_TIMEOUT_SECONDS")"
          sleep 5
          elapsed=0
        fi

        sleep 1
        elapsed=$((elapsed + 1))
      done
    }

    ensure_initialized() {
      initialized_flag="$1"

      if [ "$initialized_flag" = "true" ]; then
        load_artifacts
        return
      fi

      log "initializing vault"
      init_json="$(vault operator init -key-shares=1 -key-threshold=1 -format=json)"
      if [ "$PERSIST_UNSEAL_KEY" = "true" ] || [ "$PERSIST_ROOT_TOKEN" = "true" ]; then
        printf '%s\n' "$init_json" > "$CLUSTER_KEYS_FILE"
        chmod 600 "$CLUSTER_KEYS_FILE"
      fi

      root_token="$(printf '%s' "$init_json" | jq -r '.root_token // empty')"
      unseal_key="$(printf '%s' "$init_json" | jq -r '.unseal_keys_b64[0] // empty')"

      if [ -z "$root_token" ] || [ -z "$unseal_key" ]; then
        log "ERROR: failed to parse init response"
        exit 1
      fi

      if [ "$PERSIST_ROOT_TOKEN" = "true" ]; then
        write_secure_file "$ROOT_TOKEN_FILE" "$root_token"
      fi

      if [ "$PERSIST_UNSEAL_KEY" = "true" ]; then
        write_secure_file "$UNSEAL_KEYS_FILE" "$unseal_key"
      fi
    }

    ensure_unsealed() {
      load_artifacts

      if [ -z "$unseal_key" ]; then
        log "ERROR: Vault sealed but unseal key unavailable"
        exit 1
      fi

      log "vault sealed -> unsealing"
      vault operator unseal "$unseal_key" >/dev/null
    }

    ensure_dev_root_token() {
      load_artifacts

      if [ -z "$root_token" ]; then
        log "WARN: root token unavailable; skipping dev-root token reconcile"
        return
      fi

      if ! VAULT_TOKEN="$root_token" vault token lookup "$DEV_ROOT_TOKEN" >/dev/null 2>&1; then
        log "creating dev-root token"
        VAULT_TOKEN="$root_token" vault token create -id="$DEV_ROOT_TOKEN" -policy=root >/dev/null 2>&1
      fi

      if [ "$PERSIST_DEV_ROOT_TOKEN" = "true" ]; then
        if [ ! -f "$DEV_ROOT_FILE" ] || [ "$(cat "$DEV_ROOT_FILE" 2>/dev/null || true)" != "$DEV_ROOT_TOKEN" ]; then
          write_secure_file "$DEV_ROOT_FILE" "$DEV_ROOT_TOKEN"
        fi
      fi
    }

    ensure_tooling

    while true; do
      health="$(wait_for_health)"

      initialized="$(printf '%s' "$health" | jq -r 'if has("initialized") then .initialized else false end')"
      ensure_initialized "$initialized"

      if [ "$initialized" != "true" ]; then
        sleep 2
        continue
      fi

      sealed="$(printf '%s' "$health" | jq -r 'if has("sealed") then .sealed else true end')"
      if [ "$sealed" = "true" ]; then
        ensure_unsealed
        sleep 2
        continue
      fi

      ensure_dev_root_token

      if [ "$EXIT_AFTER_UNSEAL" = "true" ]; then
        log "vault initialized and unsealed; exiting"
        exit 0
      fi

      sleep "$CHECK_INTERVAL_SECONDS"
    done
  EOT


  vault_values = yamlencode({
    fullnameOverride = "vault"
    server = {
      image = {
        repository = "public.ecr.aws/hashicorp/vault"
        tag        = "1.17.2"
        pullPolicy = "IfNotPresent"
      }
      ha = {
        enabled = false
      }
      standalone = {
        enabled = true
        config  = trimspace(local.vault_standalone_config)
      }
      ingress = {
        enabled = false
      }
      podSecurityContext = {
        runAsNonRoot = false
        runAsUser    = 0
        runAsGroup   = 0
        fsGroup      = 0
      }
      securityContext = {
        allowPrivilegeEscalation = false
        runAsNonRoot             = false
        runAsUser                = 0
        runAsGroup               = 0
      }
      dataStorage = {
        enabled = true
        size    = var.vault_pvc_size
      }
      volumes = [
        {
          name = "vault-auto-init"
          configMap = {
            name = "vault-auto-init"
          }
        }
      ]
      extraContainers = [
        {
          name            = "vault-auto-init"
          image           = "public.ecr.aws/docker/library/alpine:3.19.1"
          imagePullPolicy = "IfNotPresent"
          command         = ["/bin/sh", "-ec", "/bin/sh /opt/vault-auto-init/auto-init.sh"]
          env = [
            {
              name  = "VAULT_ADDR"
              value = "http://127.0.0.1:8200"
            },
            {
              name  = "WAIT_TIMEOUT_SECONDS"
              value = "300"
            },
            {
              name  = "CHECK_INTERVAL_SECONDS"
              value = "5"
            },
            {
              name  = "VAULT_VERSION"
              value = "1.17.2"
            },
            {
              name  = "VAULT_AUTO_INIT_DATA_DIR"
              value = "/vault/data"
            },
            {
              name  = "VAULT_DEV_ROOT_TOKEN"
              value = "dev-root"
            }
          ]
          securityContext = {
            allowPrivilegeEscalation = false
            runAsUser                = 0
            runAsGroup               = 0
            runAsNonRoot             = false
          }
          volumeMounts = [
            {
              name      = "vault-auto-init"
              mountPath = "/opt/vault-auto-init"
              readOnly  = true
            },
            {
              name      = "data"
              mountPath = "/vault/data"
            }
          ]
        }
      ]
    }
    injector = {
      image = {
        repository = "public.ecr.aws/hashicorp/vault-k8s"
        tag        = "1.4.2"
        pullPolicy = "IfNotPresent"
      }
      agentImage = {
        repository = "public.ecr.aws/hashicorp/vault"
        tag        = "1.17.2"
        pullPolicy = "IfNotPresent"
      }
    }
    ui = {
      enabled = true
    }
  })

  registry_mirror_values = yamlencode({
    fullnameOverride = "registry-mirror"
    image = {
      repository = "public.ecr.aws/docker/library/registry"
      tag        = "2"
      pullPolicy = "IfNotPresent"
    }
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
    replicaCount     = 1
    image = {
      pullPolicy = "IfNotPresent"
    }
    ingress = {
      enabled = false
    }
    service = {
      type = "ClusterIP"
      port = 4000
    }
    masterkeySecretName = "litellm-master-key"
    masterkeySecretKey  = "LITELLM_MASTER_KEY"
    environmentSecrets  = ["litellm-master-key"]
    envVars = {
      DATABASE_URL = format("postgresql://litellm:%s@litellm-db:5432/litellm", var.litellm_db_password)
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
    db = {
      deployStandalone = false
    }
    migrationJob = {
      enabled = true
      hooks = {
        argocd = {
          enabled = true
        }
      }
    }
  })

  ncps_chart_repo_host = "ghcr.io"
  ncps_chart_name      = "agynio/charts/ncps"
  ncps_chart_revision  = "0.1.1"

  ncps_values = yamlencode({
    fullnameOverride = "ncps"
    replicaCount     = 1
    image = {
      repository = "kalbasit/ncps"
      tag        = "latest"
      pullPolicy = "IfNotPresent"
    }
    command = ["/bin/ncps"]
    args = [
      "serve",
      "--server-addr=0.0.0.0:8501",
      "--cache-hostname=ncps",
      "--cache-data-path=/storage",
      "--cache-database-url=sqlite:/storage/var/ncps/db/db.sqlite",
      "--upstream-cache=https://cache.nixos.org",
      "--upstream-public-key=cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ]
    env = [
      {
        name  = "PROMETHEUS_ENABLED"
        value = "true"
      }
    ]
    initContainers = [
      {
        name  = "ncps-init"
        image = "alpine:3.20"
        command = [
          "/bin/sh",
          "-c",
          "mkdir -m 0755 -p /storage/var && mkdir -m 0700 -p /storage/var/ncps && mkdir -m 0700 -p /storage/var/ncps/db"
        ]
        volumeMounts = [
          {
            name      = "storage"
            mountPath = "/storage"
          }
        ]
      }
    ]
    containerPorts = [
      {
        name          = "http"
        containerPort = 8501
        protocol      = "TCP"
      }
    ]
    service = {
      enabled = true
      type    = "ClusterIP"
      ports = [
        {
          name       = "http"
          port       = 8501
          targetPort = "http"
        }
      ]
    }
    persistence = {
      enabled       = true
      existingClaim = ""
      mountPath     = "/storage"
      accessModes   = ["ReadWriteOnce"]
      size          = "10Gi"
    }
    livenessProbe = {
      enabled = true
      httpGet = {
        path = "/nix-cache-info"
        port = "http"
      }
      failureThreshold = 3
      periodSeconds    = 30
    }
    readinessProbe = {
      enabled = true
      httpGet = {
        path = "/nix-cache-info"
        port = "http"
      }
      failureThreshold = 3
      periodSeconds    = 10
    }
    startupProbe = {
      enabled = true
      httpGet = {
        path = "/nix-cache-info"
        port = "http"
      }
      failureThreshold = 12
      periodSeconds    = 5
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
    runtime = {
      mode = "dind"
      dind = {
        image = {
          registry   = "public.ecr.aws/docker/library"
          repository = "docker"
          tag        = "24.0.7-dind"
          pullPolicy = "IfNotPresent"
        }
      }
    }
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
    replicaCount = 1
    image = {
      repository = "ghcr.io/agynio/platform-server"
      tag        = local.resolved_platform_server_image_tag
      pullPolicy = "IfNotPresent"
    }
    fullnameOverride = "platform-server"
    ingress = {
      enabled = false
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
    livenessProbe = {
      enabled = false
    }
    readinessProbe = {
      enabled = false
    }
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
            value = format("postgresql://agents:%s@platform-db:5432/agents", var.platform_db_password)
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
        value = format("postgresql://agents:%s@platform-db:5432/agents", var.platform_db_password)
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
        name  = "OPENAI_BASE_URL"
        value = "http://litellm:4000/v1"
      },
      {
        name  = "OPENAI_API_KEY"
        value = var.litellm_master_key
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
        name  = "DOCKER_RUNNER_OPTIONAL"
        value = "true"
      },
      {
        name  = "DOCKER_RUNNER_TIMEOUT_MS"
        value = "60000"
      },
      {
        name  = "DOCKER_RUNNER_CONNECT_RETRY_BASE_DELAY_MS"
        value = "1000"
      },
      {
        name  = "DOCKER_RUNNER_CONNECT_RETRY_MAX_DELAY_MS"
        value = "60000"
      },
      {
        name  = "DOCKER_RUNNER_CONNECT_RETRY_JITTER_MS"
        value = "500"
      },
      {
        name  = "DOCKER_RUNNER_CONNECT_PROBE_INTERVAL_MS"
        value = "10000"
      },
      {
        name  = "DOCKER_RUNNER_CONNECT_MAX_RETRIES"
        value = "120"
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
        value = "dev-root"
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
    ingress = {
      enabled = false
    }
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
    extraVolumes = [
      {
        name     = "platform-ui-cache"
        emptyDir = {}
      },
      {
        name     = "platform-ui-run"
        emptyDir = {}
      },
      {
        name     = "platform-ui-tmp"
        emptyDir = {}
      },
      {
        name     = "platform-ui-conf"
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = "platform-ui-cache"
        mountPath = "/var/cache/nginx"
      },
      {
        name      = "platform-ui-run"
        mountPath = "/var/run"
      },
      {
        name      = "platform-ui-tmp"
        mountPath = "/tmp"
      },
      {
        name      = "platform-ui-conf"
        mountPath = "/etc/nginx/conf.d"
      }
    ]
    livenessProbe = {
      enabled = true
    }
    readinessProbe = {
      enabled = true
    }
    env = [
      {
        name  = "API_UPSTREAM"
        value = "http://platform-server:3010"
      }
    ]
  })
}

resource "kubernetes_namespace" "platform" {
  metadata {
    name = var.platform_namespace
  }
}

resource "kubernetes_secret" "litellm_master_key" {
  metadata {
    name      = "litellm-master-key"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  data = {
    LITELLM_MASTER_KEY = var.litellm_master_key
    LITELLM_SALT_KEY   = var.litellm_salt_key
  }

  type = "Opaque"
}

resource "kubernetes_config_map_v1" "vault_auto_init" {
  metadata {
    name      = "vault-auto-init"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "vault-auto-init"
    }
  }

  data = {
    "auto-init.sh" = trimspace(local.vault_auto_init_script)
  }
}

resource "kubernetes_service_account_v1" "vault_auto_init" {
  metadata {
    name      = "vault-auto-init"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "vault-auto-init"
    }
  }
}

resource "kubernetes_role_v1" "vault_auto_init" {
  metadata {
    name      = "vault-auto-init"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "vault-auto-init"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "vault_auto_init" {
  metadata {
    name      = "vault-auto-init"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "vault-auto-init"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.vault_auto_init.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault_auto_init.metadata[0].name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }
}

resource "kubernetes_job_v1" "vault_init_unseal" {
  metadata {
    name      = "vault-init-unseal"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "vault-init-unseal"
    }
  }

  wait_for_completion = false

  spec {
    backoff_limit = 6

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "vault-init-unseal"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.vault_auto_init.metadata[0].name
        restart_policy       = "OnFailure"

        container {
          name              = "vault-init-unseal"
          image             = "public.ecr.aws/docker/library/alpine:3.19.1"
          image_pull_policy = "IfNotPresent"
          command           = ["/bin/sh", "-ec", "/bin/sh /opt/vault-auto-init/auto-init.sh"]

          env {
            name  = "VAULT_ADDR"
            value = "http://vault:8200"
          }

          env {
            name  = "EXIT_AFTER_UNSEAL"
            value = "true"
          }

          env {
            name  = "VAULT_AUTO_INIT_DATA_DIR"
            value = "/vault/data"
          }

          env {
            name  = "VAULT_DEV_ROOT_TOKEN"
            value = "dev-root"
          }
          volume_mount {
            name       = "vault-auto-init"
            mount_path = "/opt/vault-auto-init"
            read_only  = true
          }
          volume_mount {
            name       = "vault-data"
            mount_path = "/vault/data"
          }
        }

        volume {
          name = "vault-auto-init"
          config_map {
            name = kubernetes_config_map_v1.vault_auto_init.metadata[0].name
          }
        }

        volume {
          name = "vault-data"
          persistent_volume_claim {
            claim_name = "data-vault-0"
          }
        }
      }
    }

  }

  depends_on = [
    kubernetes_config_map_v1.vault_auto_init,
    argocd_application.vault,
  ]
}

resource "kubernetes_manifest" "virtualservice_platform_ui" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "platform-ui"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = [local.base_domain]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/api"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "platform-server.platform.svc.cluster.local"
                "port" = {
                  "number" = 3010
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
                "host" = "platform-server.platform.svc.cluster.local"
                "port" = {
                  "number" = 3010
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
                "host" = "platform-ui.platform.svc.cluster.local"
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

resource "kubernetes_manifest" "virtualservice_litellm" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "litellm"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["litellm.${local.base_domain}"]
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
                "host" = "litellm.platform.svc.cluster.local"
                "port" = {
                  "number" = 4000
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

resource "kubernetes_manifest" "virtualservice_vault" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "vault"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["vault.${local.base_domain}"]
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
                "host" = "vault.platform.svc.cluster.local"
                "port" = {
                  "number" = 8200
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

resource "kubernetes_service_v1" "platform_db" {
  metadata {
    name      = "platform-db"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "platform-db"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "platform-db"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_stateful_set_v1" "platform_db" {
  metadata {
    name      = "platform-db"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "platform-db"
    }
  }

  spec {
    service_name = kubernetes_service_v1.platform_db.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "platform-db"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "platform-db"
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
            value = "agents"
          }
          env {
            name  = "POSTGRES_USER"
            value = "agents"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.platform_db_password
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
              command = ["pg_isready", "-U", "agents", "-d", "agents"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "agents", "-d", "agents"]
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
            storage = var.platform_db_pvc_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "litellm_db" {
  metadata {
    name      = "litellm-db"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "litellm-db"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "litellm-db"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_stateful_set_v1" "litellm_db" {
  metadata {
    name      = "litellm-db"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "litellm-db"
    }
  }

  spec {
    service_name = kubernetes_service_v1.litellm_db.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "litellm-db"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "litellm-db"
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
            value = "litellm"
          }
          env {
            name  = "POSTGRES_USER"
            value = "litellm"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.litellm_db_password
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
              command = ["pg_isready", "-U", "litellm", "-d", "litellm"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "litellm", "-d", "litellm"]
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
            storage = var.litellm_db_pvc_size
          }
        }
      }
    }
  }
}


resource "argocd_repository" "twuni_docker_registry" {
  repo = local.registry_mirror_repo_url
  type = "git"
}

resource "argocd_repository" "litellm_repo" {
  repo       = local.litellm_chart_repo_host
  type       = "helm"
  enable_oci = true
}

resource "argocd_repository" "platform" {
  repo     = var.platform_repo_url
  type     = "git"
  username = trimspace(var.platform_repo_username) == "" ? null : var.platform_repo_username
  password = trimspace(var.platform_repo_password) == "" ? null : var.platform_repo_password
}

resource "argocd_application" "vault" {
  depends_on = [kubernetes_config_map_v1.vault_auto_init]

  metadata {
    name      = "vault"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "10"
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

    ignore_difference {
      group = "admissionregistration.k8s.io"
      kind  = "MutatingWebhookConfiguration"
      name  = "vault-agent-injector-cfg"
      json_pointers = [
        "/webhooks/0/clientConfig/caBundle"
      ]
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
  depends_on = [
    argocd_repository.litellm_repo,
    kubernetes_stateful_set_v1.litellm_db,
  ]
  metadata {
    name      = "litellm"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "12"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.litellm_chart_repo_host
      chart           = local.litellm_chart_full_name
      target_revision = local.litellm_chart_revision

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

resource "argocd_application" "ncps" {
  depends_on = [argocd_repository.litellm_repo]
  metadata {
    name      = "ncps"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "15"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.ncps_chart_repo_host
      chart           = local.ncps_chart_name
      target_revision = local.ncps_chart_revision

      helm {
        values = local.ncps_values
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
  depends_on = [argocd_repository.platform]
  metadata {
    name      = "docker-runner"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "18"
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
  depends_on = [
    argocd_repository.platform,
    kubernetes_stateful_set_v1.platform_db,
  ]
  metadata {
    name      = "platform-server"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "20"
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
  depends_on = [argocd_repository.platform]
  metadata {
    name      = "platform-ui"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "25"
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
