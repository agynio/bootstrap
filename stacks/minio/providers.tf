provider "argocd" {
  server_addr = format("argocd.%s:%d", local.base_domain, local.ingress_port)
  username    = var.argocd_admin_username
  password    = var.argocd_admin_password
  insecure    = true
  plain_text  = false
  grpc_web    = true
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
