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

variable "ziti_router_chart_version" {
  type        = string
  description = "OpenZiti router chart version"
  default     = "3.0.0-pre5"
}

variable "enable_ziti_diagnostics" {
  type        = bool
  description = "DEV/E2E-only: create the ziti-diagnostics admin identity and credentials. Production deployments must leave this false."
  default     = false
}

variable "ziti_cli_version" {
  type        = string
  description = "OpenZiti CLI version used by the ziti stack to create enrolled runtime identity secrets"
  default     = "1.6.7"
}

variable "ziti_cli_linux_amd64_sha256" {
  type        = string
  description = "SHA256 checksum for the OpenZiti CLI Linux amd64 archive"
  default     = "85e940bd340db61aaf16a533e899ea9cf3bcaf318ebda28e433a88fefe698b61"
}

variable "ziti_cli_linux_arm64_sha256" {
  type        = string
  description = "SHA256 checksum for the OpenZiti CLI Linux arm64 archive"
  default     = "c5760cd02c15c429876f0188ce446ef2d9592cbfcff9bcc036b733bdd032128e"
}
