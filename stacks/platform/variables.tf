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

variable "platform_chart_version" {
  type        = string
  description = "Version of the platform Helm charts published to GHCR"
  default     = "0.15.2"
}

variable "docker_runner_chart_version" {
  type        = string
  description = "Version of the docker-runner Helm chart published to GHCR"
  default     = "0.1.2"
}

variable "gateway_chart_version" {
  type        = string
  description = "Version of the gateway Helm chart published to GHCR"
  default     = "0.6.0"
}

variable "agent_state_chart_version" {
  type        = string
  description = "Version of the agent-state Helm chart published to GHCR"
  default     = "0.1.0"
}

variable "threads_chart_version" {
  type        = string
  description = "Version of the threads Helm chart published to GHCR"
  default     = "0.1.1"
}

variable "token_counting_chart_version" {
  type        = string
  description = "Version of the token-counting Helm chart published to GHCR"
  default     = "0.2.0"
}

variable "postgres_chart_version" {
  type        = string
  description = "Version of the postgres-helm chart published to GHCR"
  default     = "0.1.1"
}

variable "teams_chart_version" {
  type        = string
  description = "Version of the teams Helm chart published to GHCR"
  default     = "0.1.0"
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

variable "platform_server_image_tag" {
  type        = string
  description = "Optional override for the platform-server image tag"
  default     = ""
}

variable "docker_runner_image_tag" {
  type        = string
  description = "Optional override for the docker-runner image tag"
  default     = ""
}

variable "agent_state_image_tag" {
  type        = string
  description = "Optional override for the agent-state image tag"
  default     = ""
}

variable "threads_image_tag" {
  type        = string
  description = "Optional override for the threads image tag"
  default     = ""
}

variable "chat_chart_version" {
  type        = string
  description = "Version of the chat Helm chart published to GHCR"
  default     = "0.1.0"
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

variable "teams_image_tag" {
  type        = string
  description = "Optional override for the teams image tag"
  default     = ""
}

variable "gateway_image_tag" {
  type        = string
  description = "Optional override for the gateway image tag"
  default     = ""
}

variable "docker_runner_replica_count" {
  type        = number
  description = "Replica count for the docker-runner deployment"
  default     = 1
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

variable "threads_db_password" {
  type        = string
  description = "Password for the threads PostgreSQL database user"
  default     = "threads"
  sensitive   = true
}

variable "agent_state_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the agent-state PostgreSQL primary"
  default     = "5Gi"
}

variable "threads_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the threads PostgreSQL primary"
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
  default     = "0.1.0"
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

variable "teams_db_password" {
  type        = string
  description = "Password for the teams PostgreSQL database user"
  default     = "teams"
  sensitive   = true
}

variable "teams_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the teams PostgreSQL primary"
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

variable "minio_pvc_size" {
  type        = string
  description = "Persistent volume claim size for MinIO data"
  default     = "10Gi"
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

variable "docker_runner_shared_secret" {
  type        = string
  description = "Shared secret used by docker-runner and platform-server"
  default     = "change-me"
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
