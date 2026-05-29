output "edge_router_id" {
  value       = ziti_edge_router.default.id
  description = "ID of the default Ziti edge router"
}

output "identity_ids" {
  value = {
    gateway         = ziti_identity.gateway.id
    ziti_management = ziti_identity.ziti_management.id
    orchestrator    = ziti_identity.orchestrator.id
  }
  description = "Ziti identity IDs"
}

output "service_ids" {
  value = {
    gateway = ziti_service.gateway.id
  }
  description = "Ziti service IDs"
}

output "ziti_management_enrollment_token" {
  value       = ziti_identity.ziti_management.enrollment_token
  description = "Enrollment JWT for the ziti-management identity"
  sensitive   = true
}

output "ziti_diagnostics_credentials" {
  value = var.enable_ziti_management_diagnostics ? {
    username = ziti_identity_updb.ziti_management_diagnostics[0].updb_username
    password = random_password.ziti_management_diagnostics[0].result
  } : null
  description = "DEV/E2E-only username and password for ziti-management-diagnostics. Null when disabled; production must keep it disabled."
  sensitive   = true

  depends_on = [terraform_data.ziti_management_diagnostics_enrollment]
}
