terraform {
  required_version = ">= 1.5.0"

  required_providers {
    ziti = {
      source  = "netfoundry/ziti"
      version = "~> 1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
