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

variable "save_private_keys" {
  type        = bool
  description = "Write generated private keys to local-certs when true"
  default     = false
}
