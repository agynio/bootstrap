variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for connecting to the cluster"
  default     = "../k8s/.kube/agyn-local-kubeconfig.yaml"
}

variable "platform_namespace" {
  type        = string
  description = "Namespace where platform workloads should be deployed"
  default     = "platform"
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

variable "admin_oidc_subject" {
  type        = string
  description = "OIDC subject for the bootstrap cluster admin user"
  default     = "admin@agyn.io"

  validation {
    condition     = trimspace(var.admin_oidc_subject) != ""
    error_message = "admin_oidc_subject must not be empty."
  }
}

variable "destination_server" {
  type        = string
  description = "Kubernetes API server address for Argo CD application destinations"
  default     = "https://kubernetes.default.svc"
}

variable "postgres_chart_version" {
  type        = string
  description = "Version of the postgres-helm chart published to GHCR"
  default     = "0.1.1"
}

variable "reminders_chart_version" {
  type        = string
  description = "Version of the reminders Helm chart published to GHCR"
  default     = "0.2.0"
}

variable "reminders_image_tag" {
  type        = string
  description = "Optional override for the reminders image tag"
  default     = ""
}

variable "k8s_runner_chart_version" {
  type        = string
  description = "Version of the k8s-runner Helm chart published to GHCR"
  default     = "0.10.12"
}

variable "k8s_runner_image_tag" {
  type        = string
  description = "Optional override for the k8s-runner image tag"
  default     = ""
}

variable "reminders_db_password" {
  type        = string
  description = "Password for the reminders PostgreSQL database user"
  default     = "reminders"
  sensitive   = true
}

variable "reminders_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the reminders PostgreSQL primary"
  default     = "5Gi"
}

variable "telegram_connector_chart_version" {
  type        = string
  description = "Version of the telegram-connector Helm chart published to GHCR"
  default     = "0.1.5"
}

variable "telegram_connector_image_tag" {
  type        = string
  description = "Optional override for the telegram-connector image tag"
  default     = ""
}

variable "telegram_connector_db_password" {
  type        = string
  description = "Password for the telegram-connector PostgreSQL database user"
  default     = "telegram"
  sensitive   = true
}

variable "telegram_connector_db_pvc_size" {
  type        = string
  description = "Persistent volume claim size for the telegram-connector PostgreSQL primary"
  default     = "5Gi"
}
