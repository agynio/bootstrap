locals {
  resolved_platform_server_image_tag     = trimspace(var.platform_server_image_tag) != "" ? var.platform_server_image_tag : var.platform_chart_version
  resolved_docker_runner_image_tag       = trimspace(var.docker_runner_image_tag) != "" ? var.docker_runner_image_tag : var.docker_runner_chart_version
  resolved_platform_ui_image_tag         = local.resolved_platform_server_image_tag
  resolved_gateway_image_tag             = trimspace(var.gateway_image_tag) != "" ? var.gateway_image_tag : var.gateway_chart_version
  resolved_agent_state_image_tag         = trimspace(var.agent_state_image_tag) != "" ? var.agent_state_image_tag : format("v%s", var.agent_state_chart_version)
  resolved_agents_orchestrator_image_tag = trimspace(var.agents_orchestrator_image_tag) != "" ? var.agents_orchestrator_image_tag : var.agents_orchestrator_chart_version
  resolved_threads_image_tag             = trimspace(var.threads_image_tag) != "" ? var.threads_image_tag : format("v%s", var.threads_chart_version)
  resolved_chat_image_tag                = trimspace(var.chat_image_tag) != "" ? var.chat_image_tag : format("v%s", var.chat_chart_version)
  resolved_chat_app_image_tag            = trimspace(var.chat_app_image_tag) != "" ? var.chat_app_image_tag : var.chat_app_chart_version
  resolved_tracing_app_image_tag         = trimspace(var.tracing_app_image_tag) != "" ? var.tracing_app_image_tag : var.tracing_app_chart_version
  resolved_files_image_tag               = trimspace(var.files_image_tag) != "" ? var.files_image_tag : var.files_chart_version
  resolved_llm_image_tag                 = trimspace(var.llm_image_tag) != "" ? var.llm_image_tag : format("v%s", var.llm_chart_version)
  resolved_secrets_image_tag             = trimspace(var.secrets_image_tag) != "" ? var.secrets_image_tag : format("v%s", var.secrets_chart_version)
  resolved_token_counting_image_tag      = trimspace(var.token_counting_image_tag) != "" ? var.token_counting_image_tag : format("v%s", var.token_counting_chart_version)
  resolved_notifications_image_tag       = trimspace(var.notifications_image_tag) != "" ? var.notifications_image_tag : var.notifications_chart_version
  resolved_teams_image_tag               = trimspace(var.teams_image_tag) != "" ? var.teams_image_tag : format("v%s", var.teams_chart_version)
  resolved_authorization_image_tag       = trimspace(var.authorization_image_tag) != "" ? var.authorization_image_tag : format("v%s", var.authorization_chart_version)

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
  ncps_chart_repo_host           = "ghcr.io"
  ncps_chart_name                = "agynio/charts/ncps"
  ncps_chart_revision            = "0.1.3"
  platform_chart_repo_host       = "ghcr.io"
  postgres_chart_repo_host       = "ghcr.io"
  postgres_chart_name            = "agynio/charts/postgres-helm"
  docker_runner_chart_name       = "agynio/charts/docker-runner"
  platform_server_chart_name     = "agynio/charts/platform-server"
  platform_ui_chart_name         = "agynio/charts/platform-ui"
  agent_state_chart_name         = "agynio/charts/agent-state"
  agents_orchestrator_chart_name = "agynio/charts/agents-orchestrator"
  threads_chart_name             = "agynio/charts/threads"
  chat_chart_name                = "agynio/charts/chat"
  chat_app_chart_name            = "agynio/charts/chat-app"
  tracing_app_chart_name         = "agynio/charts/tracing-app"
  files_chart_name               = "agynio/charts/files"
  llm_chart_name                 = "agynio/charts/llm"
  secrets_chart_name             = "agynio/charts/secrets"
  token_counting_chart_name      = "agynio/charts/token-counting"
  notifications_chart_name       = "agynio/charts/notifications"
  redis_chart_name               = "redis"
  teams_chart_name               = "agynio/charts/teams"
  authorization_chart_name       = "agynio/charts/authorization"
  istio_gateway_namespace        = data.terraform_remote_state.system.outputs.istio_gateway_namespace
  istio_gateway_tls_secret_name  = data.terraform_remote_state.system.outputs.wildcard_tls_gateway_secret_name
  openfga_api_url_external       = format("https://openfga.%s:%d", local.base_domain, local.ingress_port)
  openfga_api_url_internal       = format("http://openfga.%s.svc.cluster.local:8080", var.openfga_namespace)

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
    # shellcheck disable=SC3040
    set -euo pipefail

    log() {
      printf '[vault-auto-init] %s\n' "$@"
    }

    WAIT_TIMEOUT_SECONDS="$${WAIT_TIMEOUT_SECONDS:-300}"
    CHECK_INTERVAL_SECONDS="$${CHECK_INTERVAL_SECONDS:-5}"
    VAULT_ADDR="$${VAULT_ADDR:-http://127.0.0.1:8200}"
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
    SEED_SAMPLE_SECRET="$${VAULT_SEED_SAMPLE_SECRET:-true}"
    SAMPLE_SECRET_PATH="$${VAULT_SAMPLE_SECRET_PATH:-secret/platform/example}"

    umask 077
    mkdir -p "$DATA_DIR"
    export VAULT_ADDR

    root_token=""
    unseal_key=""

    ensure_tooling() {
      missing_packages=""
      for pkg in curl jq; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
          missing_packages="$missing_packages $pkg"
        fi
      done

      if [ -n "$(printf '%s' "$missing_packages" | tr -d ' ')" ]; then
        log "installing packages:$missing_packages"
        # shellcheck disable=SC2086
        set -- $missing_packages
        apk add --no-cache "$@" >/dev/null
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
      if ! init_json="$(vault operator init -key-shares=1 -key-threshold=1 -format=json 2>&1)"; then
        if vault status -format=json 2>/dev/null | jq -e '.initialized == true' >/dev/null 2>&1; then
          log "vault was initialized by another process; loading artifacts"
          load_artifacts
          return
        fi
        log "ERROR: vault operator init failed: $init_json"
        exit 1
      fi
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
        if ! VAULT_TOKEN="$root_token" vault token create -id="$DEV_ROOT_TOKEN" -policy=root >/dev/null 2>&1; then
          if VAULT_TOKEN="$root_token" vault token lookup "$DEV_ROOT_TOKEN" >/dev/null 2>&1; then
            log "dev-root token created by another process"
          else
            log "ERROR: failed to create dev-root token"
            exit 1
          fi
        fi
      fi

      if [ "$PERSIST_DEV_ROOT_TOKEN" = "true" ]; then
        if [ ! -f "$DEV_ROOT_FILE" ] || [ "$(cat "$DEV_ROOT_FILE" 2>/dev/null || true)" != "$DEV_ROOT_TOKEN" ]; then
          write_secure_file "$DEV_ROOT_FILE" "$DEV_ROOT_TOKEN"
        fi
      fi
    }

    ensure_kv_v2_secret_mount() {
      load_artifacts

      if [ -z "$root_token" ]; then
        log "WARN: root token unavailable; skipping kv secrets engine reconcile"
        return
      fi

      secrets_json="$(VAULT_TOKEN="$root_token" vault secrets list -format=json 2>/dev/null || true)"
      if [ -z "$secrets_json" ]; then
        log "WARN: unable to list secrets engines; skipping kv secrets engine reconcile"
        return
      fi

      if printf '%s' "$secrets_json" | jq -e '."secret/" | select(.type == "kv" and ((.options.version // "") | tostring) == "2")' >/dev/null 2>&1; then
        return
      fi

      log "enabling kv v2 secrets engine at path secret/"
      if ! VAULT_TOKEN="$root_token" vault secrets enable -path=secret -version=2 kv >/dev/null 2>&1; then
        recheck="$(VAULT_TOKEN="$root_token" vault secrets list -format=json 2>/dev/null || true)"
        if printf '%s' "$recheck" | jq -e '."secret/" | select(.type == "kv" and ((.options.version // "") | tostring) == "2")' >/dev/null 2>&1; then
          log "secret/ engine created by another process"
        else
          log "ERROR: failed to enable kv v2 secrets engine at secret/"
          exit 1
        fi
      fi

      log "kv v2 secrets engine enabled at secret/"
    }

    seed_sample_secret() {
      if [ "$SEED_SAMPLE_SECRET" != "true" ]; then
        return
      fi

      load_artifacts

      if [ -z "$root_token" ]; then
        log "WARN: root token unavailable; skipping sample secret seed"
        return
      fi

      if VAULT_TOKEN="$root_token" vault kv get "$SAMPLE_SECRET_PATH" >/dev/null 2>&1; then
        return
      fi

      log "seeding sample secret at $SAMPLE_SECRET_PATH"
      if ! VAULT_TOKEN="$root_token" vault kv put "$SAMPLE_SECRET_PATH" note="Provisioned by bootstrap_v2" token="dev-placeholder" >/dev/null 2>&1; then
        log "WARN: failed to seed sample secret at $SAMPLE_SECRET_PATH"
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
      ensure_kv_v2_secret_mount
      seed_sample_secret

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
          image           = "public.ecr.aws/hashicorp/vault:1.17.2"
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

  litellm_db_values = yamlencode({
    fullnameOverride = "litellm-db"
    postgres = {
      database = "litellm"
      username = "litellm"
      password = var.litellm_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.litellm_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "litellm", "-d", "litellm"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "litellm", "-d", "litellm"]
      }
    }
  })

  agent_state_db_values = yamlencode({
    fullnameOverride = "agent-state-db"
    postgres = {
      database = "agentstate"
      username = "agentstate"
      password = var.agent_state_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.agent_state_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "agentstate", "-d", "agentstate"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "agentstate", "-d", "agentstate"]
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

  teams_db_values = yamlencode({
    fullnameOverride = "teams-db"
    postgres = {
      database = "teams"
      username = "teams"
      password = var.teams_db_password
      pgdata   = "/var/lib/postgresql/data/pgdata"
    }
    persistence = {
      size                    = var.teams_db_pvc_size
      mountPath               = "/var/lib/postgresql/data"
      volumeClaimTemplateName = "data"
    }
    probes = {
      readiness = {
        execCommand = ["pg_isready", "-U", "teams", "-d", "teams"]
      }
      liveness = {
        execCommand = ["pg_isready", "-U", "teams", "-d", "teams"]
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
      UI_USERNAME  = var.litellm_ui_username
      UI_PASSWORD  = var.litellm_ui_password
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
        master_key        = "os.environ/LITELLM_MASTER_KEY"
        store_model_in_db = true
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

  agent_state_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "agent-state"
    service = {
      port = 50051
    }
    database = {
      url = format("postgresql://agentstate:%s@agent-state-db:5432/agentstate?sslmode=disable", var.agent_state_db_password)
    }
    image = {
      repository = "ghcr.io/agynio/agent-state"
      tag        = local.resolved_agent_state_image_tag
      pullPolicy = "IfNotPresent"
    }
  })

  threads_values = yamlencode({
    replicaCount     = 1
    fullnameOverride = "threads"
    service = {
      port = 50051
    }
    database = {
      url = format("postgresql://threads:%s@threads-db:5432/threads?sslmode=disable", var.threads_db_password)
    }
    notifications = {
      address = "notifications:50051"
    }
    image = {
      repository = "ghcr.io/agynio/threads"
      tag        = local.resolved_threads_image_tag
      pullPolicy = "IfNotPresent"
    }
  })

  chat_values = yamlencode({
    fullnameOverride = "chat"
    service = {
      port = 50051
    }
    threads = {
      address = "threads:50051"
    }
    image = {
      repository = "ghcr.io/agynio/chat"
      tag        = local.resolved_chat_image_tag
      pullPolicy = "IfNotPresent"
    }
  })

  secrets_values = yamlencode({
    fullnameOverride = "secrets"
    service = {
      port = 50051
    }
    database = {
      url = format("postgresql://secrets:%s@secrets-db:5432/secrets?sslmode=disable", var.secrets_db_password)
    }
    image = {
      repository = "ghcr.io/agynio/secrets"
      tag        = local.resolved_secrets_image_tag
      pullPolicy = "IfNotPresent"
    }
  })

  teams_values = yamlencode({
    fullnameOverride = "teams"
    service = {
      port = 50051
    }
    database = {
      url = format("postgresql://teams:%s@teams-db:5432/teams?sslmode=disable", var.teams_db_password)
    }
    image = {
      repository = "ghcr.io/agynio/teams"
      tag        = local.resolved_teams_image_tag
      pullPolicy = "IfNotPresent"
    }
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
        name  = "DEFAULT_AGENT_IMAGE"
        value = "alpine:3.21"
      },
      {
        name  = "POLL_INTERVAL"
        value = "5s"
      },
      {
        name  = "IDLE_TIMEOUT"
        value = "30s"
      }
    ]
  })

  authorization_values = yamlencode({
    image = {
      repository = "ghcr.io/agynio/authorization"
      tag        = local.resolved_authorization_image_tag
    }
    openfga = {
      apiUrl  = local.openfga_api_url_internal
      storeId = module.openfga_authorization.store_id
      modelId = module.openfga_authorization.model_id
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
  ncps_values = yamlencode({
    fullnameOverride = "ncps"
    replicaCount     = 1
    image = {
      repository = "kalbasit/ncps"
      tag        = "v0.9.3"
      pullPolicy = "IfNotPresent"
    }
    securityContext = {
      runAsNonRoot = false
    }
    command = ["/bin/ncps"]
    args = [
      "serve",
      "--server-addr=0.0.0.0:8501",
      "--cache-hostname=ncps",
      "--cache-storage-local=/storage",
      "--cache-temp-path=/storage/tmp",
      "--cache-database-url=sqlite:/storage/var/ncps/db/db.sqlite",
      "--cache-upstream-url=https://cache.nixos.org",
      "--cache-upstream-public-key=cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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
          "mkdir -m 0755 -p /storage/var && mkdir -m 0700 -p /storage/var/ncps && mkdir -m 0700 -p /storage/var/ncps/db && mkdir -m 0700 -p /storage/tmp"
        ]
        volumeMounts = [
          {
            name      = "storage"
            mountPath = "/storage"
          }
        ]
      },
      {
        name  = "ncps-migrate"
        image = "kalbasit/ncps:v0.9.3"
        command = [
          "/bin/dbmate",
        ]
        args = [
          "--url=sqlite:/storage/var/ncps/db/db.sqlite",
          "up",
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
      enabled     = true
      accessModes = ["ReadWriteOnce"]
      size        = "10Gi"
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
    migrationJob = {
      enabled = false
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
        args = [
          "--host=unix:///var/run/docker/docker.sock",
          "--host=tcp://0.0.0.0:2375",
          "--group=1000",
        ]
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
        value = "50051"
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
          port       = 50051
          targetPort = "grpc"
          protocol   = "TCP"
        }
      ]
    }
    containerPorts = [
      {
        name          = "grpc"
        containerPort = 50051
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
      },
      {
        name = "graph-data"
        hostPath = {
          path = "/shared"
          type = "DirectoryOrCreate"
        }
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
      },
      {
        name      = "graph-data"
        mountPath = "/mnt/graph"
      },
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
        value = "50051"
      },
      {
        name  = "DOCKER_RUNNER_PORT"
        value = "50051"
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
      },
      {
        name  = "GRAPH_REPO_PATH"
        value = "/mnt/graph/graph"
      }
    ]
  })

  platform_ui_values = yamlencode({
    replicaCount = 1
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
  })
}

# NOTE: The module ref (v0.1.1) must be updated in lockstep with
# var.authorization_chart_version to ensure the provisioned FGA model
# matches the model expected by the deployed Helm chart.
module "openfga_authorization" {
  source          = "github.com/agynio/authorization//terraform?ref=v0.1.1"
  openfga_api_url = local.openfga_api_url_external
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
                "prefix" = "/apiv2/"
              }
            },
            {
              "uri" = {
                "exact" = "/apiv2"
              }
            }
          ]
          "rewrite" = {
            "uri" = "/"
          }
          "route" = [
            {
              "destination" = {
                "host" = "gateway-gateway.platform.svc.cluster.local"
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
                "prefix" = "/api"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "gateway-gateway.platform.svc.cluster.local"
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
                "host" = "gateway-gateway.platform.svc.cluster.local"
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
                "prefix" = "/api"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "gateway-gateway.platform.svc.cluster.local"
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
                "host" = "gateway-gateway.platform.svc.cluster.local"
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
                "host" = "gateway-gateway.platform.svc.cluster.local"
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
resource "argocd_repository" "twuni_docker_registry" {
  repo = local.registry_mirror_repo_url
  type = "git"
}

resource "argocd_repository" "bitnami_repo" {
  repo = "https://charts.bitnami.com/bitnami"
  type = "helm"
}
resource "argocd_repository" "litellm_repo" {
  repo       = local.litellm_chart_repo_host
  type       = "helm"
  enable_oci = true
}

resource "argocd_application" "platform_db" {
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

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
      namespace = var.platform_namespace
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

resource "argocd_application" "litellm_db" {
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

  metadata {
    name      = "litellm-db"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "6"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.postgres_chart_repo_host
      chart           = local.postgres_chart_name
      target_revision = var.postgres_chart_version

      helm {
        values = local.litellm_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.platform_namespace
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

resource "argocd_application" "agent_state_db" {
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

  metadata {
    name      = "agent-state-db"
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
        values = local.agent_state_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.platform_namespace
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
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

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
      namespace = var.platform_namespace
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
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

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
      namespace = var.platform_namespace
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

resource "argocd_application" "llm_db" {
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

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
      namespace = var.platform_namespace
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

resource "argocd_application" "teams_db" {
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

  metadata {
    name      = "teams-db"
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
        values = local.teams_db_values
      }
    }

    destination {
      server    = var.destination_server
      namespace = var.platform_namespace
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
  depends_on = [argocd_repository.litellm_repo]
  wait       = true

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
      namespace = var.platform_namespace
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
    argocd_application.litellm_db,
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

resource "argocd_application" "agent_state" {
  depends_on = [
    argocd_repository.litellm_repo,
    argocd_application.agent_state_db,
  ]
  metadata {
    name      = "agent-state"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "16"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.agent_state_chart_name
      target_revision = var.agent_state_chart_version

      helm {
        values = local.agent_state_values
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

resource "argocd_application" "threads" {
  depends_on = [
    argocd_repository.litellm_repo,
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

resource "argocd_application" "chat" {
  depends_on = [
    argocd_repository.litellm_repo,
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

resource "argocd_application" "secrets" {
  depends_on = [
    argocd_repository.litellm_repo,
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

resource "argocd_application" "authorization" {
  depends_on = [
    argocd_repository.litellm_repo,
    module.openfga_authorization,
  ]
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

resource "argocd_application" "token_counting" {
  depends_on = [argocd_repository.litellm_repo]
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

resource "argocd_application" "teams" {
  depends_on = [
    argocd_repository.litellm_repo,
    argocd_application.teams_db,
  ]
  metadata {
    name      = "teams"
    namespace = "argocd"
    annotations = {
      "argocd.argoproj.io/sync-wave" = "17"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.platform_chart_repo_host
      chart           = local.teams_chart_name
      target_revision = var.teams_chart_version

      helm {
        values = local.teams_values
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

resource "argocd_application" "llm" {
  depends_on = [
    argocd_repository.litellm_repo,
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

resource "minio_s3_bucket" "files" {
  bucket = var.minio_bucket_name
  acl    = "private"
}

resource "argocd_application" "files" {
  depends_on = [
    argocd_repository.litellm_repo,
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

resource "argocd_application" "notifications" {
  depends_on = [
    argocd_repository.litellm_repo,
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
  depends_on = [argocd_repository.litellm_repo]
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
      repo_url        = local.platform_chart_repo_host
      chart           = local.docker_runner_chart_name
      target_revision = var.docker_runner_chart_version

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

resource "argocd_application" "agents_orchestrator" {
  depends_on = [
    argocd_repository.litellm_repo,
    argocd_application.agents_orchestrator_db,
    argocd_application.threads,
    argocd_application.notifications,
    argocd_application.teams,
    argocd_application.secrets,
    argocd_application.docker_runner,
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
    argocd_repository.litellm_repo,
    argocd_application.platform_db,
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
      repo_url        = local.platform_chart_repo_host
      chart           = local.platform_server_chart_name
      target_revision = var.platform_chart_version

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
  depends_on = [argocd_repository.litellm_repo]
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
      repo_url        = local.platform_chart_repo_host
      chart           = local.platform_ui_chart_name
      target_revision = var.platform_chart_version

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

resource "argocd_application" "chat_app" {
  depends_on = [argocd_repository.litellm_repo]
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

resource "argocd_application" "tracing_app" {
  depends_on = [argocd_repository.litellm_repo]
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

resource "argocd_application" "gateway" {
  depends_on = [argocd_application.llm]
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
          replicaCount = 1
          image = {
            tag = local.resolved_gateway_image_tag
          }
        })
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
