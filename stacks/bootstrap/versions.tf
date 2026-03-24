terraform {
  required_version = ">= 1.5.0"

  required_providers {
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
