provider "argocd" {
  server_addr = "argocd.agyn.dev:8080"
  username    = var.argocd_admin_username
  password    = var.argocd_admin_password
  insecure    = true
  plain_text  = false
  grpc_web    = true
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
