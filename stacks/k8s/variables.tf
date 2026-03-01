variable "cluster_name" {
  type        = string
  description = "Name of the k3d cluster"
  default     = "agyn-local"
}

variable "servers" {
  type        = number
  description = "Number of server nodes"
  default     = 1
}

variable "agents" {
  type        = number
  description = "Number of agent nodes"
  default     = 2
}

variable "k3s_version" {
  type        = string
  description = "k3s version tag (e.g., v1.28.4-k3s1)"
  default     = "v1.28.4-k3s1"
}

variable "k3s_extra_args" {
  type        = list(string)
  description = "Additional k3s server args (e.g., --disable=traefik)"
  default     = []
}

variable "expose_api" {
  type        = bool
  description = "Expose Kubernetes API on a host port"
  default     = true
}

variable "api_port" {
  type        = number
  description = "Host port for Kubernetes API (6443)"
  default     = 6443
}

variable "ports" {
  type = list(object({
    container_port = number
    host_port      = number
    protocol       = string
  }))
  description = "Additional port mappings for cluster ingress/services"
  default = [
    {
      container_port = 8080
      host_port      = 8080
      protocol       = "tcp"
    },
    {
      container_port = 8443
      host_port      = 8443
      protocol       = "tcp"
    }
  ]
}
