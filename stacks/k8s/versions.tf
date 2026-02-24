terraform {
  required_version = ">= 1.5.0"
  required_providers {
    k3d = {
      source  = "agynio/k3d"
      version = "~> 0.1.0"
    }
  }
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
