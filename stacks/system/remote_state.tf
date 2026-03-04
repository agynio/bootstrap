data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../k8s/state/terraform.tfstate"
  }
}

locals {
  base_domain = data.terraform_remote_state.k8s.outputs.domain
}
