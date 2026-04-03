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
  base_domain         = data.terraform_remote_state.k8s.outputs.domain
  ingress_port        = data.terraform_remote_state.k8s.outputs.ingress_port
  gateway_url         = format("https://gateway.%s:%d", local.base_domain, local.ingress_port)
  cluster_admin_token = random_password.cluster_admin_token.result
}

data "terraform_remote_state" "ziti" {
  backend = "local"

  config = {
    path = "../ziti/state/terraform.tfstate"
  }
}
