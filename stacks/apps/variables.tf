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
