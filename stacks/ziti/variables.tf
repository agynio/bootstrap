variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for connecting to the cluster"
  default     = "../k8s/.kube/agyn-local-kubeconfig.yaml"
}

variable "ziti_admin_username" {
  type        = string
  description = "Admin username used for Ziti controller authentication"
  default     = "admin"
}

variable "ziti_admin_password" {
  type        = string
  description = "Admin password used for Ziti controller authentication"
  sensitive   = true
}

variable "ziti_router_chart_version" {
  type        = string
  description = "OpenZiti router chart version"
  default     = "2.1.0"
}

variable "platform_namespace" {
  type        = string
  description = "Namespace where platform services and identity secrets live"
  default     = "agyn"
}
