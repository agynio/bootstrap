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
  default     = "0.1.0"
}

variable "reminders_image_tag" {
  type        = string
  description = "Optional override for the reminders image tag"
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
