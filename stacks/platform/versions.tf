terraform {
  required_version = ">= 1.5.0"

  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.14"
    }
  }

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
