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
  istio_gateway_namespace = data.terraform_remote_state.system.outputs.istio_gateway_namespace
}
