locals {
  openziti_repository_url           = "https://openziti.io/helm-charts"
  ziti_namespace                    = "ziti"
  router_enrollment_secret_name     = "ziti-router-enrollment"
  gateway_identity_secret_name      = "ziti-gateway-enrollment"
  management_identity_secret_name   = "ziti-management-enrollment"
  orchestrator_identity_secret_name = "ziti-orchestrator-enrollment"
  egress_gateway_identity_json_file = abspath("${path.root}/../../local-certs/egress-gateway-identity.json")

  router_values = yamlencode({
    ctrl = {
      # Use controller service port (ingress advertised port), not container 1280.
      endpoint = "ziti.${local.base_domain}:${local.ingress_port}"
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

resource "ziti_intercept_v1_config" "gateway_intercept" {
  name      = "gateway-intercept-v1"
  addresses = ["gateway.ziti"]
  protocols = ["tcp"]
  port_ranges = [
    {
      low  = 443
      high = 443
    }
  ]
}

resource "ziti_intercept_v1_config" "llm_proxy_intercept" {
  name      = "llm-proxy-intercept-v1"
  addresses = ["llm-proxy.ziti"]
  protocols = ["tcp"]
  port_ranges = [
    {
      low  = 80
      high = 80
    }
  ]
}

resource "ziti_service" "gateway" {
  name            = "gateway"
  configs         = [ziti_intercept_v1_config.gateway_intercept.id]
  role_attributes = ["gateway"]
}

resource "ziti_service" "llm_proxy" {
  name            = "llm-proxy"
  configs         = [ziti_intercept_v1_config.llm_proxy_intercept.id]
  role_attributes = ["llm-proxy"]
}

resource "ziti_identity" "egress_gateway" {
  name            = "egress-gateway"
  type            = "Device"
  role_attributes = ["egress-gateway-hosts"]
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

resource "random_password" "ziti_diagnostics" {
  count = var.enable_ziti_diagnostics ? 1 : 0

  length  = 32
  special = false
}

# DEV/E2E ONLY: ziti-diagnostics is an admin UPDB identity used
# solely by diagnostics tests. Production deployments must not enable this.
resource "ziti_auth_policy" "ziti_diagnostics" {
  count = var.enable_ziti_diagnostics ? 1 : 0

  name = "ziti-diagnostics"

  primary = {
    cert = {
      allowed             = false
      allow_expired_certs = false
    }
    ext_jwt = {
      allowed         = false
      allowed_signers = []
    }
    updb = {
      allowed                  = true
      lockout_duration_minutes = 5
      max_attempts             = 5
      min_password_length      = 8
      require_mixed_case       = false
      require_number_char      = false
      require_special_char     = false
    }
  }

  secondary = {
    require_totp = false
  }
}

# DEV/E2E ONLY: this admin identity is for diagnostics tests and must not
# exist in production. Keep enable_ziti_diagnostics=false for prod.
resource "ziti_identity_updb" "ziti_diagnostics" {
  name           = "ziti-diagnostics"
  count          = var.enable_ziti_diagnostics ? 1 : 0
  type           = "User"
  updb_username  = "ziti-diagnostics"
  auth_policy_id = ziti_auth_policy.ziti_diagnostics[0].id
  # The current Terraform provider does not expose OpenZiti's permissions
  # field, so this identity must be an admin to access management endpoints.
  # E2E only stores its one-time login credential in the platform namespace.
  is_admin        = true
  role_attributes = []
}

locals {
  ziti_diagnostics_enrollment_jwt_payload = var.enable_ziti_diagnostics ? split(".", ziti_identity_updb.ziti_diagnostics[0].enrollment_token)[1] : ""
  ziti_diagnostics_enrollment_jwt_padding = substr("===", 0, (4 - length(local.ziti_diagnostics_enrollment_jwt_payload) % 4) % 4)
  ziti_diagnostics_enrollment_token       = var.enable_ziti_diagnostics ? jsondecode(base64decode(format("%s%s", replace(replace(local.ziti_diagnostics_enrollment_jwt_payload, "-", "+"), "_", "/"), local.ziti_diagnostics_enrollment_jwt_padding))).jti : ""
}

# DEV/E2E ONLY: enroll the ziti-diagnostics identity so tests can
# read the generated password from the platform namespace. Do not enable in prod.
resource "terraform_data" "ziti_diagnostics_enrollment" {
  count = var.enable_ziti_diagnostics ? 1 : 0

  input = {
    endpoint = format("https://ziti-mgmt.%s:%d/edge/client/v1", local.base_domain, local.ingress_port)
    password = random_password.ziti_diagnostics[0].result
    token    = local.ziti_diagnostics_enrollment_token
    username = ziti_identity_updb.ziti_diagnostics[0].updb_username
  }

  triggers_replace = [
    random_password.ziti_diagnostics[0].result,
    ziti_identity_updb.ziti_diagnostics[0].id,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      curl -fsS -k -X POST \
        -H 'Content-Type: application/json' \
        -d "{\"username\":\"$ZITI_USERNAME\",\"password\":\"$ZITI_PASSWORD\"}" \
        "$ZITI_ENDPOINT/enroll?method=updb&token=$ZITI_TOKEN"
    EOT

    environment = {
      ZITI_ENDPOINT = self.input.endpoint
      ZITI_PASSWORD = self.input.password
      ZITI_TOKEN    = self.input.token
      ZITI_USERNAME = self.input.username
    }
  }
}

resource "ziti_identity" "orchestrator" {
  name            = "orchestrator"
  type            = "Device"
  role_attributes = ["orchestrators"]
}

resource "kubernetes_secret_v1" "gateway_identity_enrollment" {
  metadata {
    name      = local.gateway_identity_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    enrollmentJwt = ziti_identity.gateway.enrollment_token
  }
}

resource "kubernetes_secret_v1" "ziti_management_identity_enrollment" {
  metadata {
    name      = local.management_identity_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    enrollmentJwt = ziti_identity.ziti_management.enrollment_token
  }
}

resource "kubernetes_secret_v1" "orchestrator_identity_enrollment" {
  metadata {
    name      = local.orchestrator_identity_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    enrollmentJwt = ziti_identity.orchestrator.enrollment_token
  }
}

resource "terraform_data" "egress_gateway_enrollment" {
  input = {
    endpoint = format("https://ziti-mgmt.%s:%d/edge/client/v1", local.base_domain, local.ingress_port)
    file     = local.egress_gateway_identity_json_file
    token    = ziti_identity.egress_gateway.enrollment_token
  }

  triggers_replace = [ziti_identity.egress_gateway.id]

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      mkdir -p "$(dirname "$ZITI_IDENTITY_FILE")"
      tmp="$(mktemp)"
      curl -fsS -k -X POST "$ZITI_ENDPOINT/enroll?method=ott&token=$ZITI_TOKEN" -o "$tmp"
      mv "$tmp" "$ZITI_IDENTITY_FILE"
      chmod 0600 "$ZITI_IDENTITY_FILE"
    EOT

    interpreter = ["/bin/bash", "-c"]

    environment = {
      ZITI_ENDPOINT      = self.input.endpoint
      ZITI_IDENTITY_FILE = self.input.file
      ZITI_TOKEN         = self.input.token
    }
  }
}

resource "ziti_service_policy" "agents_dial_gateway" {
  name          = "agents-dial-gateway"
  type          = "Dial"
  identityroles = ["#agents"]
  serviceroles  = [format("@%s", ziti_service.gateway.id)]
}

resource "ziti_service_policy" "orchestrators_dial_runners" {
  name          = "orchestrators-dial-runners"
  type          = "Dial"
  identityroles = ["#orchestrators"]
  serviceroles  = ["#runner-services"]
}

resource "ziti_service_policy" "terminal_proxy_dial_runners" {
  name          = "terminal-proxy-dial-runners"
  type          = "Dial"
  identityroles = ["#terminal-proxy-hosts"]
  serviceroles  = ["#runner-services"]
}

resource "ziti_service_policy" "gateway_bind" {
  name          = "gateway-bind"
  type          = "Bind"
  identityroles = ["#gateway-hosts"]
  serviceroles  = [format("@%s", ziti_service.gateway.id)]
}

resource "ziti_service_policy" "llm_proxy_bind" {
  name          = "llm-proxy-bind"
  type          = "Bind"
  identityroles = ["#llm-proxy-hosts"]
  serviceroles  = [format("@%s", ziti_service.llm_proxy.id)]
}

resource "ziti_service_policy" "egress_gateway_bind" {
  name          = "egress-gateway-bind"
  type          = "Bind"
  identityroles = ["#egress-gateway-hosts"]
  serviceroles  = ["#egress-services"]
}

resource "ziti_service_policy" "agents_dial_llm_proxy" {
  name          = "agents-dial-llm-proxy"
  type          = "Dial"
  identityroles = ["#agents"]
  serviceroles  = [format("@%s", ziti_service.llm_proxy.id)]
}

resource "ziti_intercept_v1_config" "tracing_intercept" {
  name      = "tracing-intercept-v1"
  addresses = ["tracing.ziti"]
  protocols = ["tcp"]
  port_ranges = [
    {
      low  = 443
      high = 443
    }
  ]
}

resource "ziti_service" "tracing" {
  name            = "tracing"
  configs         = [ziti_intercept_v1_config.tracing_intercept.id]
  role_attributes = ["tracing"]
}

resource "ziti_service_policy" "tracing_bind" {
  name          = "tracing-bind"
  type          = "Bind"
  identityroles = ["#tracing-hosts"]
  serviceroles  = [format("@%s", ziti_service.tracing.id)]
}

resource "ziti_service_policy" "agents_dial_tracing" {
  name          = "agents-dial-tracing"
  type          = "Dial"
  identityroles = ["#agents"]
  serviceroles  = [format("@%s", ziti_service.tracing.id)]
}

resource "ziti_service_policy" "runners_bind" {
  name          = "runners-bind"
  type          = "Bind"
  identityroles = ["#runners"]
  serviceroles  = ["#runner-services"]
}

resource "ziti_service_policy" "apps_dial_gateway" {
  name          = "apps-dial-gateway"
  type          = "Dial"
  identityroles = ["#apps"]
  serviceroles  = [format("@%s", ziti_service.gateway.id)]
}

resource "ziti_service_policy" "apps_bind" {
  name          = "apps-bind"
  type          = "Bind"
  identityroles = ["#apps"]
  serviceroles  = ["#app-services"]
}

resource "ziti_service_policy" "gateway_dial_apps" {
  name          = "gateway-dial-apps"
  type          = "Dial"
  identityroles = ["#gateway-hosts"]
  serviceroles  = ["#app-services"]
}

resource "ziti_service_policy" "runners_service_dial_runners" {
  name          = "runners-service-dial-runners"
  type          = "Dial"
  identityroles = ["#runners-service-hosts"]
  serviceroles  = ["#runner-services"]
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
