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

variable "agent_state_chart_version" {
  type        = string
  description = "Version of the agent-state Helm chart published to GHCR"
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

variable "agent_state_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the agent-state PostgreSQL primary"
  default     = "5Gi"
}

variable "files_chart_version" {
  type        = string
  description = "Version of the files Helm chart published to GHCR"
  default     = "0.1.0"
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
