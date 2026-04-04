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
  default     = "0.2.0"
}

variable "reminders_image_tag" {
  type        = string
  description = "Optional override for the reminders image tag"
  default     = ""
}

variable "reminders_app_id" {
  type        = string
  description = "UUID for the reminders app"
  default     = "3ef512f4-b48e-491a-b3a9-d005e22a5ee0"
}

variable "reminders_app_identity_id" {
  type        = string
  description = "Identity UUID for the reminders app"
  default     = "d1bb8c2d-7f89-4f3c-b049-a5de7d310b14"
}

variable "reminders_service_token" {
  type        = string
  description = "Service token for the reminders app"
  default     = "reminders"
  sensitive   = true
}

variable "k8s_runner_chart_version" {
  type        = string
  description = "Version of the k8s-runner Helm chart published to GHCR"
  default     = "0.7.0"
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
