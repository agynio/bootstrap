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

provider "minio" {
  minio_server   = format("minio-api.%s:%d", local.base_domain, local.ingress_port)
  minio_user     = var.minio_root_user
  minio_password = var.minio_root_password
  minio_ssl      = true
  minio_insecure = true
}

provider "openfga" {
  api_url = local.openfga_api_url
}
