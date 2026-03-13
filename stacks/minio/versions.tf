terraform {
  required_version = ">= 1.5.0"

  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.2"
    }
  }

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
