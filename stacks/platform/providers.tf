provider "argocd" {
  server_addr = var.argocd_server_addr
  auth_token  = local.argocd_provider_token
  insecure    = var.argocd_insecure
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
