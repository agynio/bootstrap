variable "identity_name" {
  type        = string
  description = "Identity name used for enrollment artifacts"
}

variable "enrollment_token" {
  type        = string
  description = "Enrollment JWT for the identity"
  sensitive   = true
}

variable "secret_name" {
  type        = string
  description = "Kubernetes secret name to store the enrolled identity"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the identity secret"
}

variable "enrollment_dir" {
  type        = string
  description = "Directory for enrollment artifacts (contains private keys)"
}

variable "unpack_id" {
  type        = bool
  description = "Whether to store id.cert/key/ca fields instead of identity.json"
  default     = false
}

variable "identity_json_key" {
  type        = string
  description = "Secret key name for the identity JSON"
  default     = "identity.json"
}
