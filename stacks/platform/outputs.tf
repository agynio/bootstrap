output "platform_app_names" {
  description = "Names of Argo CD applications managed by this stack"
  value = [
    argocd_application.registry_mirror.metadata[0].name,
    argocd_application.platform_db.metadata[0].name,
    argocd_application.threads_db.metadata[0].name,
    argocd_application.metering_db.metadata[0].name,
    argocd_application.chat_db.metadata[0].name,
    argocd_application.tracing_db.metadata[0].name,
    argocd_application.secrets_db.metadata[0].name,
    argocd_application.llm_db.metadata[0].name,
    argocd_application.agents_db.metadata[0].name,
    argocd_application.ziti_management_db.metadata[0].name,
    argocd_application.users_db.metadata[0].name,
    argocd_application.expose_db.metadata[0].name,
    argocd_application.organizations_db.metadata[0].name,
    argocd_application.agents_orchestrator_db.metadata[0].name,
    argocd_application.identity_db.metadata[0].name,
    argocd_application.runners_db.metadata[0].name,
    argocd_application.apps_db.metadata[0].name,
    argocd_application.ncps.metadata[0].name,
    argocd_application.platform.metadata[0].name,
  ]
}

output "platform_app_ids" {
  description = "Identifiers returned by the Argo CD provider for the applications"
  value = [
    argocd_application.registry_mirror.id,
    argocd_application.platform_db.id,
    argocd_application.threads_db.id,
    argocd_application.metering_db.id,
    argocd_application.chat_db.id,
    argocd_application.tracing_db.id,
    argocd_application.secrets_db.id,
    argocd_application.llm_db.id,
    argocd_application.agents_db.id,
    argocd_application.ziti_management_db.id,
    argocd_application.users_db.id,
    argocd_application.expose_db.id,
    argocd_application.organizations_db.id,
    argocd_application.agents_orchestrator_db.id,
    argocd_application.identity_db.id,
    argocd_application.runners_db.id,
    argocd_application.apps_db.id,
    argocd_application.ncps.id,
    argocd_application.platform.id,
  ]
}

output "platform_namespace" {
  description = "Namespace where platform workloads are deployed"
  value       = var.platform_namespace
}

output "openfga_store_id" {
  description = "OpenFGA store identifier for authorization"
  value       = module.openfga_authorization.store_id
}

output "openfga_model_id" {
  description = "OpenFGA model identifier for authorization"
  value       = module.openfga_authorization.model_id
}

output "cluster_admin_identity_id" {
  description = "Identity ID of the bootstrap cluster admin"
  value       = local.cluster_admin_identity_id
}

output "cluster_admin_api_token" {
  description = "Static bootstrap token for the cluster admin (sensitive)"
  value       = random_password.cluster_admin_token.result
  sensitive   = true
}
