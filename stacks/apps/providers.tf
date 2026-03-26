provider "argocd" {
  server_addr = format("argocd.%s:%d", local.base_domain, local.ingress_port)
  username    = var.argocd_admin_username
  password    = var.argocd_admin_password
  insecure    = true
  plain_text  = false
  grpc_web    = true
}

provider "agyn" {
  api_url   = local.gateway_url
  api_token = local.cluster_admin_token
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
