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
  default     = "2.1.2"
}

variable "save_private_keys" {
  type        = bool
  description = "Write generated private keys to local-certs when true"
  default     = false
}
