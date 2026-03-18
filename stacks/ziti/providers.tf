provider "ziti" {
  username = var.ziti_admin_username
  password = var.ziti_admin_password
  host     = "https://127.0.0.1:1281/edge/management/v1"
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
