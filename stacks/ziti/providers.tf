provider "ziti" {
  username = var.ziti_admin_username
  password = var.ziti_admin_password
  host     = format("https://ziti-mgmt.%s:%d/edge/management/v1", local.base_domain, local.ingress_port)
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
