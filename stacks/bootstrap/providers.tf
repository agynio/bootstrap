provider "openfga" {
  api_url = local.openfga_api_url_external
}

provider "sql" {
  url = "postgres://users:${var.users_db_password}@${var.users_db_host}:${var.users_db_port}/users?sslmode=disable"
}
