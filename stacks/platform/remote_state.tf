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
  base_domain  = data.terraform_remote_state.k8s.outputs.domain
  ingress_port = data.terraform_remote_state.k8s.outputs.ingress_port
}

data "terraform_remote_state" "ziti" {
  backend = "local"

  config = {
    path = "../ziti/state/terraform.tfstate"
  }
}

data "kubernetes_service_v1" "ziti_controller_client" {
  metadata {
    name      = "ziti-controller-client"
    namespace = local.ziti_namespace
  }
}

data "kubernetes_service_v1" "ziti_router_edge" {
  metadata {
    name      = "ziti-router-edge"
    namespace = local.ziti_namespace
  }
}

data "kubernetes_service_v1" "istio_ingressgateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = local.istio_gateway_namespace
  }
}

data "kubernetes_service_v1" "kube_dns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
}
