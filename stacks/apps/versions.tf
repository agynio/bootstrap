terraform {
  required_version = ">= 1.5.0"

  required_providers {
    agyn = {
      source  = "agynio/agyn"
      version = "~> 0.4"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
  }

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
