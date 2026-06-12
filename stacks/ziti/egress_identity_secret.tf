locals {
  egress_gateway_identity_secret_name = "egress-gateway-ziti-identity"
}

resource "terraform_data" "egress_gateway_identity" {
  input = {
    ziti_cli_version            = var.ziti_cli_version
    ziti_cli_linux_amd64_sha256 = var.ziti_cli_linux_amd64_sha256
    ziti_cli_linux_arm64_sha256 = var.ziti_cli_linux_arm64_sha256
    ziti_namespace              = local.ziti_namespace
    secret_name                 = local.egress_gateway_identity_secret_name
    identity_id                 = ziti_identity.egress_gateway.id
  }

  triggers_replace = [
    ziti_identity.egress_gateway.id,
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/enroll-egress-gateway-identity.sh"

    environment = {
      IDENTITY_ID                 = self.input.identity_id
      KUBECONFIG                  = var.kubeconfig_path
      SECRET_NAME                 = self.input.secret_name
      ZITI_CLI_LINUX_AMD64_SHA256 = self.input.ziti_cli_linux_amd64_sha256
      ZITI_CLI_LINUX_ARM64_SHA256 = self.input.ziti_cli_linux_arm64_sha256
      ZITI_CLI_VERSION            = self.input.ziti_cli_version
      ZITI_NAMESPACE              = self.input.ziti_namespace
    }
  }
}
