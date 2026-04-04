variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for connecting to the cluster"
  default     = "../k8s/.kube/agyn-local-kubeconfig.yaml"
}

variable "argocd_admin_username" {
  type        = string
  description = "Admin username used for Argo CD provider authentication"
  default     = "admin"
}

variable "argocd_admin_password" {
  type        = string
  description = "Admin password used for Argo CD provider authentication"
  default     = "admin"
  sensitive   = true
}

variable "gateway_chart_version" {
  type        = string
  description = "Version of the gateway Helm chart published to GHCR"
  default     = "0.16.0"
}

variable "agent_state_chart_version" {
  type        = string
  description = "Version of the agent-state Helm chart published to GHCR"
  default     = "0.1.0"
}

variable "agents_orchestrator_chart_version" {
  type        = string
  description = "Version of the agents-orchestrator Helm chart published to GHCR"
  default     = "0.9.0"
}

variable "k8s_runner_chart_version" {
  type        = string
  description = "Version of the k8s-runner Helm chart published to GHCR"
  default     = "0.6.0"
}

variable "k8s_runner_identity_id" {
  type        = string
  description = "Stable UUID identifying the singleton k8s-runner instance for Ziti identity management"
  default     = "439e0da2-88cd-46d7-bb9c-56c723c15606"
}

variable "threads_chart_version" {
  type        = string
  description = "Version of the threads Helm chart published to GHCR"
  default     = "0.3.2"
}

variable "tracing_chart_version" {
  type        = string
  description = "Version of the tracing Helm chart published to GHCR"
  default     = "0.2.0"
}

variable "token_counting_chart_version" {
  type        = string
  description = "Version of the token-counting Helm chart published to GHCR"
  default     = "0.2.0"
}

variable "notifications_chart_version" {
  type        = string
  description = "Version of the notifications Helm chart published to GHCR"
  default     = "0.2.2"
}

variable "notifications_redis_chart_version" {
  type        = string
  description = "Version of the Bitnami Redis Helm chart for notifications"
  default     = "25.3.2"
}

variable "postgres_chart_version" {
  type        = string
  description = "Version of the postgres-helm chart published to GHCR"
  default     = "0.1.1"
}

variable "agents_chart_version" {
  type        = string
  description = "Version of the agents Helm chart published to GHCR"
  default     = "0.6.0"
}

variable "ziti_management_chart_version" {
  type        = string
  description = "Version of the ziti-management Helm chart published to GHCR"
  default     = "0.7.0"
}

variable "users_chart_version" {
  type        = string
  description = "Version of the users Helm chart published to GHCR"
  default     = "0.3.0"
}

variable "organizations_chart_version" {
  type        = string
  description = "Version of the organizations Helm chart published to GHCR"
  default     = "0.2.0"
}

variable "identity_chart_version" {
  type        = string
  description = "Version of the identity Helm chart published to GHCR"
  default     = "0.1.0"
}

variable "runners_chart_version" {
  type        = string
  description = "Version of the runners Helm chart published to GHCR"
  default     = "0.1.1"
}

variable "chat_app_chart_version" {
  type        = string
  description = "Version of the chat-app Helm chart published to GHCR"
  default     = "0.2.0"
}

variable "chat_app_image_tag" {
  type        = string
  description = "Optional override for the chat-app container image tag"
  default     = ""
}

variable "console_app_chart_version" {
  type        = string
  description = "Version of the console-app Helm chart published to GHCR"
  default     = "0.1.0"
}

variable "console_app_image_tag" {
  type        = string
  description = "Optional override for the console-app container image tag"
  default     = ""
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL (authority) for frontend apps"
  default     = "https://mockauth.dev/r/301ebb13-15a8-48f4-baac-e3fa25be29fc/oidc"
}

variable "oidc_client_id" {
  type        = string
  description = "OIDC client ID for frontend apps (public client)"
  default     = "client_MU95KU3gHQf5Ir7p"
}

variable "console_app_oidc_client_id" {
  type        = string
  description = "OIDC client ID for the console-app (public client)"
  default     = "client_4XUh4_1VfUzpfYkN"
}

variable "oidc_client_secret" {
  type        = string
  description = "OIDC client secret (dev/QA only - production should use a K8s Secret)"
  default     = "XPKka2i9uzISrKZ95zxli8sY51BK4eTJ"
  sensitive   = true
}

variable "tracing_app_chart_version" {
  type        = string
  description = "Version of the tracing-app Helm chart published to GHCR"
  default     = "0.2.0"
}

variable "tracing_app_image_tag" {
  type        = string
  description = "Optional override for the tracing-app container image tag"
  default     = ""
}

variable "platform_namespace" {
  type        = string
  description = "Namespace where platform workloads should be deployed"
  default     = "platform"
}

variable "destination_server" {
  type        = string
  description = "Kubernetes API server address for Argo CD application destinations"
  default     = "https://kubernetes.default.svc"
}

variable "agent_state_image_tag" {
  type        = string
  description = "Optional override for the agent-state image tag"
  default     = ""
}

variable "agents_orchestrator_image_tag" {
  type        = string
  description = "Optional override for the agents-orchestrator image tag"
  default     = ""
}

variable "k8s_runner_image_tag" {
  type        = string
  description = "Optional override for the k8s-runner image tag"
  default     = ""
}

variable "threads_image_tag" {
  type        = string
  description = "Optional override for the threads image tag"
  default     = ""
}

variable "tracing_image_tag" {
  type        = string
  description = "Optional override for the tracing image tag"
  default     = ""
}

variable "chat_chart_version" {
  type        = string
  description = "Version of the chat Helm chart published to GHCR"
  default     = "0.2.2"
}

variable "chat_image_tag" {
  type        = string
  description = "Optional override for the chat image tag"
  default     = ""
}

variable "token_counting_image_tag" {
  type        = string
  description = "Optional override for the token-counting image tag"
  default     = ""
}

variable "notifications_image_tag" {
  type        = string
  description = "Optional override for the notifications image tag"
  default     = ""
}

variable "agents_image_tag" {
  type        = string
  description = "Optional override for the agents image tag"
  default     = ""
}

variable "ziti_management_image_tag" {
  type        = string
  description = "Optional override for the ziti-management container image tag"
  default     = ""
}

variable "users_image_tag" {
  type        = string
  description = "Optional override for the users image tag"
  default     = ""
}

variable "organizations_image_tag" {
  type        = string
  description = "Optional override for the organizations image tag"
  default     = ""
}

variable "identity_image_tag" {
  type        = string
  description = "Optional override for the identity image tag"
  default     = ""
}

variable "runners_image_tag" {
  type        = string
  description = "Optional override for the runners image tag"
  default     = ""
}

variable "gateway_image_tag" {
  type        = string
  description = "Optional override for the gateway image tag"
  default     = ""
}

variable "notifications_redis_addr" {
  type        = string
  description = "Redis address used by the notifications service"
  default     = "notifications-redis-master.platform.svc.cluster.local:6379"
}

variable "argocd_automated_sync_enabled" {
  type        = bool
  description = "Enable automated sync for Argo CD applications"
  default     = true
}

variable "argocd_prune_enabled" {
  type        = bool
  description = "Enable pruning during automated sync"
  default     = true
}

variable "argocd_self_heal_enabled" {
  type        = bool
  description = "Enable self-healing during automated sync"
  default     = true
}

variable "platform_db_password" {
  type        = string
  description = "Password for the platform PostgreSQL database user"
  default     = "agents"
  sensitive   = true
}

variable "platform_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the platform PostgreSQL primary"
  default     = "5Gi"
}

variable "litellm_db_password" {
  type        = string
  description = "Password for the LiteLLM PostgreSQL database user"
  default     = "change-me"
  sensitive   = true
}

variable "litellm_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the LiteLLM PostgreSQL primary"
  default     = "5Gi"
}

variable "agent_state_db_password" {
  type        = string
  description = "Password for the agent-state PostgreSQL database user"
  default     = "agentstate"
  sensitive   = true
}

variable "agents_orchestrator_db_password" {
  type        = string
  description = "Password for the agents-orchestrator PostgreSQL database user"
  default     = "orchestrator"
  sensitive   = true
}

variable "identity_db_password" {
  type        = string
  description = "Password for the identity PostgreSQL database user"
  default     = "identity"
  sensitive   = true
}

variable "runners_db_password" {
  type        = string
  description = "Password for the runners PostgreSQL database user"
  default     = "runners"
  sensitive   = true
}

variable "threads_db_password" {
  type        = string
  description = "Password for the threads PostgreSQL database user"
  default     = "threads"
  sensitive   = true
}

variable "tracing_db_password" {
  type        = string
  description = "Password for the tracing PostgreSQL database user"
  default     = "tracing"
  sensitive   = true
}

variable "agent_state_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the agent-state PostgreSQL primary"
  default     = "5Gi"
}

variable "agents_orchestrator_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the agents-orchestrator PostgreSQL primary"
  default     = "5Gi"
}

variable "identity_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the identity PostgreSQL primary"
  default     = "5Gi"
}

variable "runners_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the runners PostgreSQL primary"
  default     = "5Gi"
}

variable "threads_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the threads PostgreSQL primary"
  default     = "5Gi"
}

variable "tracing_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the tracing PostgreSQL primary"
  default     = "5Gi"
}

variable "files_chart_version" {
  type        = string
  description = "Version of the files Helm chart published to GHCR"
  default     = "0.1.2"
}

variable "files_image_tag" {
  type        = string
  description = "Optional override for the files image tag"
  default     = ""
}

variable "files_db_password" {
  type        = string
  description = "Password for the files PostgreSQL database user"
  default     = "files"
  sensitive   = true
}

variable "files_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the files PostgreSQL primary"
  default     = "5Gi"
}

variable "llm_chart_version" {
  type        = string
  description = "Version of the llm Helm chart published to GHCR"
  default     = "0.3.0"
}

variable "llm_image_tag" {
  type        = string
  description = "Optional override for the llm image tag"
  default     = ""
}

variable "llm_db_password" {
  type        = string
  description = "Password for the llm PostgreSQL database user"
  default     = "llm"
  sensitive   = true
}

variable "llm_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the llm PostgreSQL primary"
  default     = "5Gi"
}

variable "agents_db_password" {
  type        = string
  description = "Password for the agents PostgreSQL database user"
  default     = "agents"
  sensitive   = true
}

variable "ziti_management_db_password" {
  type        = string
  description = "Password for the ziti-management PostgreSQL database user"
  default     = "ziti_management"
  sensitive   = true
}

variable "tenants_db_password" {
  type        = string
  description = "Password for the tenants PostgreSQL database user"
  default     = "tenants"
  sensitive   = true
}

variable "agents_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the agents PostgreSQL primary"
  default     = "5Gi"
}

variable "ziti_management_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the ziti-management PostgreSQL primary"
  default     = "5Gi"
}

variable "users_db_password" {
  type        = string
  description = "Password for the users PostgreSQL database user"
  default     = "users"
  sensitive   = true
}

variable "users_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the users PostgreSQL primary"
  default     = "5Gi"
}

variable "tenants_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the tenants PostgreSQL primary"
  default     = "5Gi"
}

variable "minio_root_user" {
  type        = string
  description = "MinIO root user access key"
  default     = "minioadmin"
}

variable "minio_root_password" {
  type        = string
  description = "MinIO root user secret key"
  default     = "minioadmin"
  sensitive   = true
}

variable "minio_bucket_name" {
  type        = string
  description = "Default MinIO bucket name for files service"
  default     = "files"
}

variable "litellm_master_key" {
  type        = string
  description = "LiteLLM master key used by platform workloads"
  default     = "sk-dev-master-1234"
  sensitive   = true
}

variable "litellm_salt_key" {
  type        = string
  description = "LiteLLM salt key used by platform workloads"
  default     = "sk-dev-salt-1234"
  sensitive   = true
}

variable "litellm_ui_username" {
  type        = string
  description = "LiteLLM UI username for dev-only admin access"
  default     = "admin"
}

variable "litellm_ui_password" {
  type        = string
  description = "LiteLLM UI password for dev-only admin access"
  default     = "admin"
  sensitive   = true
}

variable "vault_pvc_size" {
  type        = string
  description = "Persistent volume claim size for Vault data"
  default     = "5Gi"
}

variable "registry_mirror_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the registry mirror"
  default     = "5Gi"
}

variable "secrets_chart_version" {
  type        = string
  description = "Version of the secrets Helm chart published to GHCR"
  default     = "0.1.0"
}

variable "secrets_image_tag" {
  type        = string
  description = "Optional override for the secrets image tag"
  default     = ""
}

variable "secrets_db_password" {
  type        = string
  description = "Password for the secrets PostgreSQL database user"
  default     = "secrets"
  sensitive   = true
}

variable "secrets_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the secrets PostgreSQL primary"
  default     = "5Gi"
}

variable "secrets_encryption_key" {
  type        = string
  description = "Symmetric encryption key for locally-stored secret values in the Secrets service"
  default     = "dev-encryption-key-32bytes!!@#$%"
  sensitive   = true
}

variable "authorization_chart_version" {
  type        = string
  description = "Version of the authorization Helm chart published to GHCR"
  default     = "0.1.1"
}

variable "authorization_image_tag" {
  type        = string
  description = "Optional override for the authorization image tag"
  default     = ""
}

variable "openfga_namespace" {
  type        = string
  description = "Namespace where OpenFGA is deployed"
  default     = "openfga"
}

variable "llm_proxy_chart_version" {
  type        = string
  description = "Version of the llm-proxy Helm chart published to GHCR"
  default     = "0.7.0"
}

variable "llm_proxy_image_tag" {
  type        = string
  description = "Optional override for the llm-proxy image tag"
  default     = "0.4.0"
}
