locals {
  openziti_repository_url           = "https://openziti.io/helm-charts"
  ziti_namespace                    = "ziti"
  router_enrollment_secret_name     = "ziti-router-enrollment"
  gateway_identity_secret_name      = "ziti-gateway-identity"
  management_identity_secret_name   = "ziti-management-identity"
  orchestrator_identity_secret_name = "ziti-orchestrator-identity"
  runner_identity_secret_name       = "ziti-runner-identity"
  identity_enrollment_dir           = "${path.module}/.terraform/ziti-identities"

  router_values = yamlencode({
    ctrl = {
      # Use controller service port (ingress advertised port), not container 1280.
      endpoint = "ziti-controller-client.ziti.svc:${local.ingress_port}"
    }
    edge = {
      advertisedHost = "ziti-router.${local.base_domain}"
      advertisedPort = local.ingress_port
    }
    tunnel = {
      mode = "host"
    }
    linkListeners = {
      transport = {
        enabled = false
      }
    }
    enrollmentJwtFromSecret = true
    enrollmentJwtSecretName = local.router_enrollment_secret_name
  })
}

resource "ziti_edge_router" "default" {
  name            = "edge-router-1"
  role_attributes = ["public", "all"]
}

resource "kubernetes_secret_v1" "edge_router_enrollment" {
  metadata {
    name      = local.router_enrollment_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    enrollmentJwt = ziti_edge_router.default.enrollment_token
  }
}

resource "helm_release" "ziti_router" {
  name       = "ziti-router"
  repository = local.openziti_repository_url
  chart      = "ziti-router"
  version    = var.ziti_router_chart_version
  namespace  = local.ziti_namespace
  depends_on = [kubernetes_secret_v1.edge_router_enrollment]
  wait       = true
  timeout    = 600

  values = [local.router_values]
}

resource "ziti_service" "gateway" {
  name            = "gateway"
  role_attributes = ["gateway"]
}

resource "ziti_service" "runner" {
  name            = "runner"
  role_attributes = ["runner"]
}

resource "ziti_identity" "gateway" {
  name            = "gateway"
  type            = "Device"
  role_attributes = ["gateway-hosts"]
}

resource "ziti_identity" "ziti_management" {
  name            = "ziti-management"
  type            = "Device"
  is_admin        = true
  role_attributes = []
}

resource "ziti_identity" "orchestrator" {
  name            = "orchestrator"
  type            = "Device"
  role_attributes = ["orchestrators"]
}

resource "ziti_identity" "runner" {
  name            = "runner"
  type            = "Device"
  role_attributes = ["runners"]
}

resource "terraform_data" "gateway_identity_enrollment" {
  triggers_replace = {
    enrollment_token = ziti_identity.gateway.enrollment_token
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      enrollment_dir="${local.identity_enrollment_dir}"
      jwt_file="${local.identity_enrollment_dir}/gateway.jwt"
      identity_file="${local.identity_enrollment_dir}/gateway.json"

      mkdir -p "$enrollment_dir"
      printf '%s' "$ZITI_JWT" > "$jwt_file"
      ziti edge enroll --jwt "$jwt_file" --out "$identity_file"
    EOT

    environment = {
      ZITI_JWT = ziti_identity.gateway.enrollment_token
    }
  }
}

data "local_file" "gateway_identity" {
  depends_on = [terraform_data.gateway_identity_enrollment]
  filename   = "${local.identity_enrollment_dir}/gateway.json"
}

resource "kubernetes_secret_v1" "gateway_identity" {
  metadata {
    name      = local.gateway_identity_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    "identity.json" = data.local_file.gateway_identity.content
  }
}

resource "terraform_data" "ziti_management_identity_enrollment" {
  triggers_replace = {
    enrollment_token = ziti_identity.ziti_management.enrollment_token
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      enrollment_dir="${local.identity_enrollment_dir}"
      jwt_file="${local.identity_enrollment_dir}/ziti-management.jwt"
      identity_file="${local.identity_enrollment_dir}/ziti-management.json"

      mkdir -p "$enrollment_dir"
      printf '%s' "$ZITI_JWT" > "$jwt_file"
      ziti edge enroll --jwt "$jwt_file" --out "$identity_file"
    EOT

    environment = {
      ZITI_JWT = ziti_identity.ziti_management.enrollment_token
    }
  }
}

data "local_file" "ziti_management_identity" {
  depends_on = [terraform_data.ziti_management_identity_enrollment]
  filename   = "${local.identity_enrollment_dir}/ziti-management.json"
}

locals {
  ziti_management_identity = jsondecode(data.local_file.ziti_management_identity.content)
}

resource "kubernetes_secret_v1" "ziti_management_identity" {
  metadata {
    name      = local.management_identity_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    cert = local.ziti_management_identity.cert
    key  = local.ziti_management_identity.key
    ca   = local.ziti_management_identity.ca
  }
}

resource "terraform_data" "orchestrator_identity_enrollment" {
  triggers_replace = {
    enrollment_token = ziti_identity.orchestrator.enrollment_token
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      enrollment_dir="${local.identity_enrollment_dir}"
      jwt_file="${local.identity_enrollment_dir}/orchestrator.jwt"
      identity_file="${local.identity_enrollment_dir}/orchestrator.json"

      mkdir -p "$enrollment_dir"
      printf '%s' "$ZITI_JWT" > "$jwt_file"
      ziti edge enroll --jwt "$jwt_file" --out "$identity_file"
    EOT

    environment = {
      ZITI_JWT = ziti_identity.orchestrator.enrollment_token
    }
  }
}

data "local_file" "orchestrator_identity" {
  depends_on = [terraform_data.orchestrator_identity_enrollment]
  filename   = "${local.identity_enrollment_dir}/orchestrator.json"
}

resource "kubernetes_secret_v1" "orchestrator_identity" {
  metadata {
    name      = local.orchestrator_identity_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    "identity.json" = data.local_file.orchestrator_identity.content
  }
}

resource "terraform_data" "runner_identity_enrollment" {
  triggers_replace = {
    enrollment_token = ziti_identity.runner.enrollment_token
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      enrollment_dir="${local.identity_enrollment_dir}"
      jwt_file="${local.identity_enrollment_dir}/runner.jwt"
      identity_file="${local.identity_enrollment_dir}/runner.json"

      mkdir -p "$enrollment_dir"
      printf '%s' "$ZITI_JWT" > "$jwt_file"
      ziti edge enroll --jwt "$jwt_file" --out "$identity_file"
    EOT

    environment = {
      ZITI_JWT = ziti_identity.runner.enrollment_token
    }
  }
}

data "local_file" "runner_identity" {
  depends_on = [terraform_data.runner_identity_enrollment]
  filename   = "${local.identity_enrollment_dir}/runner.json"
}

resource "kubernetes_secret_v1" "runner_identity" {
  metadata {
    name      = local.runner_identity_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    "identity.json" = data.local_file.runner_identity.content
  }
}

resource "ziti_service_policy" "agents_dial_gateway" {
  name          = "agents-dial-gateway"
  type          = "Dial"
  identityroles = ["#agents"]
  serviceroles  = [format("@%s", ziti_service.gateway.id)]
}

resource "ziti_service_policy" "channels_dial_gateway" {
  name          = "channels-dial-gateway"
  type          = "Dial"
  identityroles = ["#channels"]
  serviceroles  = [format("@%s", ziti_service.gateway.id)]
}

resource "ziti_service_policy" "orchestrators_dial_runners" {
  name          = "orchestrators-dial-runners"
  type          = "Dial"
  identityroles = ["#orchestrators"]
  serviceroles  = [format("@%s", ziti_service.runner.id)]
}

resource "ziti_service_policy" "gateway_bind" {
  name          = "gateway-bind"
  type          = "Bind"
  identityroles = ["#gateway-hosts"]
  serviceroles  = [format("@%s", ziti_service.gateway.id)]
}

resource "ziti_service_policy" "runners_bind" {
  name          = "runners-bind"
  type          = "Bind"
  identityroles = ["#runners"]
  serviceroles  = [format("@%s", ziti_service.runner.id)]
}

resource "ziti_edge_router_policy" "all_identities_all_routers" {
  name            = "all-identities-all-routers"
  identityroles   = ["#all"]
  edgerouterroles = ["#all"]
}

resource "ziti_service_edge_router_policy" "all_services_all_routers" {
  name            = "all-services-all-routers"
  serviceroles    = ["#all"]
  edgerouterroles = ["#all"]
}
