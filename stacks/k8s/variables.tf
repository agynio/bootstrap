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
  description = "k3s version tag (e.g., v1.34.3-k3s1)"
  default     = "v1.34.3-k3s1"
}

variable "k3s_extra_args" {
  type        = list(string)
  description = "Additional k3s server args (e.g., --disable=traefik)"
  default = [
    "--disable=traefik",
  ]
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

variable "domain" {
  type        = string
  description = "Base domain used for ingress endpoints"
  default     = "agyn.dev"

  validation {
    condition     = can(regex("^([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,}$", lower(var.domain)))
    error_message = "Domain must be a valid DNS name (e.g., example.com)."
  }
}

variable "port" {
  type        = number
  description = "Host port exposed for ingress traffic"
  default     = 2496

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "ports" {
  type = list(object({
    container_port = number
    host_port      = number
    protocol       = string
    node_filters   = optional(list(string), [])
  }))
  description = "Optional custom port mappings overriding the default derived from var.port"
  default     = null
}
