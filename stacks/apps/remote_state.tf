data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../k8s/state/terraform.tfstate"
  }
}

data "terraform_remote_state" "platform" {
  backend = "local"

  config = {
    path = "../platform/state/terraform.tfstate"
  }
}

locals {
  base_domain         = data.terraform_remote_state.k8s.outputs.domain
  ingress_port        = data.terraform_remote_state.k8s.outputs.ingress_port
  gateway_url         = format("https://gateway.%s:%d", local.base_domain, local.ingress_port)
  cluster_admin_token = data.terraform_remote_state.platform.outputs.cluster_admin_api_token
}
