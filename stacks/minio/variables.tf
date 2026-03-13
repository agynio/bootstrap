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

variable "minio_chart_version" {
  type        = string
  description = "Version of the official MinIO Helm chart"
  default     = "5.4.0"
}

variable "minio_image_tag" {
  type        = string
  description = "Image tag for the MinIO server"
  default     = "RELEASE.2024-11-07T00-52-20Z"
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
