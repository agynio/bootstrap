data "terraform_remote_state" "platform" {
  backend = "local"

  config = {
    path = "../platform/state/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../k8s/state/terraform.tfstate"
  }
}

locals {
  base_domain              = data.terraform_remote_state.k8s.outputs.domain
  ingress_port             = data.terraform_remote_state.k8s.outputs.ingress_port
  openfga_api_url_external = format("https://openfga.%s:%d", local.base_domain, local.ingress_port)
  openfga_store_id         = data.terraform_remote_state.platform.outputs.openfga_store_id
  openfga_model_id         = data.terraform_remote_state.platform.outputs.openfga_model_id
}
