output "edge_router_id" {
  value       = ziti_edge_router.default.id
  description = "ID of the default Ziti edge router"
}

output "identity_ids" {
  value = {
    gateway         = ziti_identity.gateway.id
    egress_gateway  = ziti_identity.egress_gateway.id
    ziti_management = ziti_identity.ziti_management.id
    orchestrator    = ziti_identity.orchestrator.id
  }
  description = "Ziti identity IDs"
}

output "service_ids" {
  value = {
    gateway   = ziti_service.gateway.id
    llm_proxy = ziti_service.llm_proxy.id
  }
  description = "Ziti service IDs"
}

output "ziti_management_enrollment_token" {
  value       = ziti_identity.ziti_management.enrollment_token
  description = "Enrollment JWT for the ziti-management identity"
  sensitive   = true
}

output "ziti_diagnostics_credentials" {
  value = var.enable_ziti_diagnostics ? {
    username = ziti_identity_updb.ziti_diagnostics[0].updb_username
    password = random_password.ziti_diagnostics[0].result
  } : null
  description = "DEV/E2E-only username and password for ziti-diagnostics. Null when disabled; production must keep it disabled."
  sensitive   = true

  depends_on = [terraform_data.ziti_diagnostics_enrollment]
}

data "local_file" "egress_gateway_identity" {
  filename = local.egress_gateway_identity_json_file

  depends_on = [terraform_data.egress_gateway_enrollment]
}

output "egress_gateway_identity_json" {
  value       = data.local_file.egress_gateway_identity.content
  description = "Enrolled OpenZiti identity JSON for egress-gateway. Bootstrap local environments store this in the platform egress-gateway-ziti-identity Secret. Rotate by replacing the ziti egress-gateway identity."
  sensitive   = true

  depends_on = [terraform_data.egress_gateway_enrollment]
}
