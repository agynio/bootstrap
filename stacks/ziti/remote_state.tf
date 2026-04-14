data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../k8s/state/terraform.tfstate"
  }
}

data "kubernetes_secret_v1" "ziti_admin" {
  metadata {
    name      = "ziti-controller-admin-secret"
    namespace = "ziti"
  }
}

locals {
  base_domain         = data.terraform_remote_state.k8s.outputs.domain
  ingress_port        = data.terraform_remote_state.k8s.outputs.ingress_port
  ziti_admin_password = data.kubernetes_secret_v1.ziti_admin.data["admin-password"]
}
