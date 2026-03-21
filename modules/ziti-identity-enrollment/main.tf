locals {
  # Enrollment artifacts include private keys; keep the directory secured.
  jwt_file      = "${var.enrollment_dir}/${var.identity_name}.jwt"
  identity_file = "${var.enrollment_dir}/${var.identity_name}.json"
}

resource "terraform_data" "enrollment" {
  triggers_replace = {
    enrollment_token = var.enrollment_token
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      enrollment_dir="${var.enrollment_dir}"
      jwt_file="${local.jwt_file}"
      identity_file="${local.identity_file}"

      mkdir -p "$enrollment_dir"
      printf '%s' "$ZITI_JWT" > "$jwt_file"
      ziti edge enroll --jwt "$jwt_file" --out "$identity_file"
      chmod 600 "$identity_file"
      rm -f "$jwt_file"
    EOT

    environment = {
      ZITI_JWT = var.enrollment_token
    }
  }
}

data "local_file" "identity" {
  depends_on = [terraform_data.enrollment]
  filename   = local.identity_file
}

locals {
  decoded_identity = jsondecode(data.local_file.identity.content)
}

resource "kubernetes_secret_v1" "identity" {
  metadata {
    name      = var.secret_name
    namespace = var.namespace
  }

  type = "Opaque"

  data = var.unpack_id ? {
    cert = local.decoded_identity.id.cert
    key  = local.decoded_identity.id.key
    ca   = local.decoded_identity.id.ca
    } : {
    (var.identity_json_key) = data.local_file.identity.content
  }
}
