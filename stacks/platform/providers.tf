provider "argocd" {
  server_addr = var.argocd_server_addr
  auth_token  = var.argocd_auth_token
  insecure    = var.argocd_insecure
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
