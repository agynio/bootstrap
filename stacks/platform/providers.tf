provider "argocd" {
  username                    = var.argocd_admin_username
  password                    = var.argocd_admin_password
  insecure                    = true
  plain_text                  = true
  port_forward_with_namespace = var.argocd_port_forward_enabled ? var.argocd_port_forward_namespace : null
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
