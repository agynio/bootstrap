output "edge_router_id" {
  value       = ziti_edge_router.default.id
  description = "ID of the default Ziti edge router"
}

output "identity_ids" {
  value = {
    gateway         = ziti_identity.gateway.id
    ziti_management = ziti_identity.ziti_management.id
    orchestrator    = ziti_identity.orchestrator.id
    runner          = ziti_identity.runner.id
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
