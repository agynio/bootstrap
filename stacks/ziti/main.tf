locals {
  openziti_repository_url           = "https://openziti.io/helm-charts"
  ziti_namespace                    = "ziti"
  router_enrollment_secret_name     = "ziti-router-enrollment"
  gateway_identity_secret_name      = "ziti-gateway-enrollment"
  management_identity_secret_name   = "ziti-management-enrollment"
  orchestrator_identity_secret_name = "ziti-orchestrator-enrollment"

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

resource "ziti_service_policy" "agents_dial_llm_proxy" {
  name          = "agents-dial-llm-proxy"
  type          = "Dial"
  identityroles = ["#agents"]
  serviceroles  = [format("@%s", ziti_service.llm_proxy.id)]
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
