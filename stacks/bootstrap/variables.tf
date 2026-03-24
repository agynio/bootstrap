variable "cluster_admin_name" {
  type        = string
  description = "Display name for the bootstrap cluster admin user"
  default     = "Cluster Admin"
}

variable "users_db_password" {
  type        = string
  description = "Password for the users PostgreSQL database user"
  default     = "users"
  sensitive   = true
}

variable "users_db_host" {
  type        = string
  description = "Host address for the users PostgreSQL database"
  default     = "127.0.0.1"
}

variable "users_db_port" {
  type        = number
  description = "Port for the users PostgreSQL database"
  default     = 25432
}
