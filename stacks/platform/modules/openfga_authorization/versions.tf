terraform {
  required_version = ">= 1.5.0"

  required_providers {
    openfga = {
      source  = "openfga/openfga"
      version = "~> 0.5"
    }
  }
}
