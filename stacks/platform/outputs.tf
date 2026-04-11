output "platform_app_names" {
  description = "Names of Argo CD applications managed by this stack"
  value = [
    argocd_application.vault.metadata[0].name,
    argocd_application.registry_mirror.metadata[0].name,
    argocd_application.platform_db.metadata[0].name,
    argocd_application.litellm_db.metadata[0].name,
    argocd_application.agent_state_db.metadata[0].name,
    argocd_application.tracing_db.metadata[0].name,
    argocd_application.apps_db.metadata[0].name,
    argocd_application.litellm.metadata[0].name,
    argocd_application.ncps.metadata[0].name,
    argocd_application.agent_state.metadata[0].name,
    argocd_application.tracing.metadata[0].name,
    argocd_application.authorization.metadata[0].name,
    argocd_application.token_counting.metadata[0].name,
    argocd_application.notifications_redis.metadata[0].name,
    argocd_application.notifications.metadata[0].name,
    argocd_application.expose.metadata[0].name,
    argocd_application.files.metadata[0].name,
    argocd_application.media_proxy.metadata[0].name,
    argocd_application.apps.metadata[0].name,
    argocd_application.chat_app.metadata[0].name,
    argocd_application.console_app.metadata[0].name,
    argocd_application.tracing_app.metadata[0].name,
  ]
}

output "platform_app_ids" {
  description = "Identifiers returned by the Argo CD provider for the applications"
  value = [
    argocd_application.vault.id,
    argocd_application.registry_mirror.id,
    argocd_application.platform_db.id,
    argocd_application.litellm_db.id,
    argocd_application.agent_state_db.id,
    argocd_application.tracing_db.id,
    argocd_application.apps_db.id,
    argocd_application.litellm.id,
    argocd_application.ncps.id,
    argocd_application.agent_state.id,
    argocd_application.tracing.id,
    argocd_application.authorization.id,
    argocd_application.token_counting.id,
    argocd_application.notifications_redis.id,
    argocd_application.notifications.id,
    argocd_application.expose.id,
    argocd_application.files.id,
    argocd_application.media_proxy.id,
    argocd_application.apps.id,
    argocd_application.chat_app.id,
    argocd_application.console_app.id,
    argocd_application.tracing_app.id,
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
