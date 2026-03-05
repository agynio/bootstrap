terraform {
  required_version = ">= 1.5.0"
  required_providers {
    k3d = {
      source  = "agynio/k3d"
      version = "~> 0.2.3"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}
