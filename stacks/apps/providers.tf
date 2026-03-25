provider "agyn" {
  api_url   = local.gateway_url
  api_token = local.cluster_admin_token
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
