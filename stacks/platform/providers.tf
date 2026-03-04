provider "argocd" {
  server_addr                 = var.argocd_port_forward_enabled ? null : local.argocd_server_addr_normalized
  username                    = var.argocd_admin_username
  password                    = var.argocd_admin_password
  insecure                    = true
  plain_text                  = var.argocd_plain_text
  grpc_web                    = true
  port_forward                = var.argocd_port_forward_enabled
  port_forward_with_namespace = var.argocd_port_forward_enabled ? var.argocd_port_forward_namespace : null
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
