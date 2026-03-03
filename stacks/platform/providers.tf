provider "argocd" {
  server_addr = local.argocd_server_addr_normalized
  username    = var.argocd_admin_username
  password    = var.argocd_admin_password
  insecure    = true
  plain_text  = true
  grpc_web    = true
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
