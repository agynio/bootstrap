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
      version = "~> 3.28"
    }
    openfga = {
      source  = "openfga/openfga"
      version = "~> 0.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    sql = {
      source  = "paultyng/sql"
      version = "0.5.0"
    }
  }

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
