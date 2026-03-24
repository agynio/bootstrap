output "cluster_admin_identity_id" {
  description = "Identity ID of the bootstrap cluster admin user"
  value       = local.cluster_admin_identity_id
}

output "cluster_admin_api_token" {
  description = "API token for the bootstrap cluster admin (sensitive)"
  value       = local.cluster_admin_api_token_plaintext
  sensitive   = true
}
