variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for connecting to the cluster"
  default     = "../k8s/.kube/agyn-local-kubeconfig.yaml"
}

variable "argocd_server_addr" {
  type        = string
  description = "Argo CD API server address (e.g. http://localhost:8080 when port-forwarding)"
}

variable "argocd_auth_token" {
  type        = string
  description = "Argo CD authentication token with permissions to manage applications"
  sensitive   = true
}

variable "argocd_insecure" {
  type        = bool
  description = "Allow insecure TLS or plaintext connections to the Argo CD API"
  default     = true
}

variable "platform_repo_url" {
  type        = string
  description = "Git repository URL containing platform Helm charts"
  default     = "https://github.com/agynio/platform.git"
}

variable "platform_stack_repo_url" {
  type        = string
  description = "Git repository URL containing raw Kubernetes manifests managed in this stack"
  default     = "https://github.com/agynio/bootstrap_v2.git"
}

variable "platform_stack_target_revision" {
  type        = string
  description = "Git revision for raw Kubernetes manifests managed in this stack"
  default     = "main"
}

variable "platform_target_revision" {
  type        = string
  description = "Git revision for platform Helm charts"
  default     = "v0.15.2"
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
  default     = "0.15.2"
}

variable "platform_server_replica_count" {
  type        = number
  description = "Replica count for the platform-server deployment"
  default     = 2
}

variable "docker_runner_image_tag" {
  type        = string
  description = "Optional override for the docker-runner image tag"
  default     = "0.15.2"
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

variable "litellm_master_key" {
  type        = string
  description = "LiteLLM master key used by platform workloads"
  default     = "sk-dev-master"
  sensitive   = true
}

variable "litellm_salt_key" {
  type        = string
  description = "LiteLLM salt key used by platform workloads"
  default     = "sk-dev-salt"
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
