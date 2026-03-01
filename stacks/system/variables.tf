variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for connecting to the cluster"
  default     = "../k8s/.kube/agyn-local-kubeconfig.yaml"
}

variable "istio_chart_version" {
  type        = string
  description = "Istio chart version"
  default     = "1.21.0"
}

variable "argocd_chart_version" {
  type        = string
  description = "Argo CD chart version"
  default     = "9.4.3"
}

variable "argocd_admin_username" {
  type        = string
  description = "Admin username used by the automation bootstrap job"
  default     = "admin"
}

variable "argocd_admin_password" {
  type        = string
  description = "Admin password used by the automation bootstrap job"
  default     = "admin"
}

variable "argocd_server_addr" {
  type        = string
  description = "Internal address of the Argo CD server"
  default     = "argo-cd-argocd-server.argocd.svc.cluster.local"
}
