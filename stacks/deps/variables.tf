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

variable "ziti_admin_password_override" {
  type        = string
  description = "Optional override for the Ziti admin password to preserve existing credentials during upgrades"
  default     = ""
  sensitive   = true
}

variable "cert_manager_chart_version" {
  type        = string
  description = "cert-manager chart version"
  default     = "v1.20.0"
}

variable "trust_manager_chart_version" {
  type        = string
  description = "trust-manager chart version"
  default     = "v0.22.0"
}

variable "ziti_controller_chart_version" {
  type        = string
  description = "OpenZiti controller chart version"
  default     = "3.2.0-pre6"
}
