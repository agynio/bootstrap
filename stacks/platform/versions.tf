terraform {
  required_version = ">= 1.5.0"

  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 6.0"
    }
  }

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
