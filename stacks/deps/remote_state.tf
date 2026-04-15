data "terraform_remote_state" "system" {
  backend = "local"

  config = {
    path = "../system/state/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../k8s/state/terraform.tfstate"
  }
}

locals {
  base_domain             = data.terraform_remote_state.k8s.outputs.domain
  ingress_port            = data.terraform_remote_state.k8s.outputs.ingress_port
  installed_namespaces    = data.terraform_remote_state.system.outputs.installed_namespaces
  argocd_namespace        = local.installed_namespaces[4]
  cert_manager_namespace  = local.installed_namespaces[0]
  ziti_namespace          = local.installed_namespaces[1]
  ziti_admin_secret_name  = "ziti-controller-admin-secret"
  destination_server      = "https://kubernetes.default.svc"
  istio_gateway_namespace = data.terraform_remote_state.system.outputs.istio_gateway_namespace
}
