output "platform_app_names" {
  description = "Names of Argo CD applications managed by this stack"
  value = [
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
    argocd_application.threads.metadata[0].name,
    argocd_application.metering.metadata[0].name,
    argocd_application.tracing.metadata[0].name,
    argocd_application.chat.metadata[0].name,
    argocd_application.secrets.metadata[0].name,
    argocd_application.authorization.metadata[0].name,
    argocd_application.identity.metadata[0].name,
    argocd_application.token_counting.metadata[0].name,
    argocd_application.notifications_redis.metadata[0].name,
    argocd_application.runners.metadata[0].name,
    argocd_application.apps.metadata[0].name,
    argocd_application.agents.metadata[0].name,
    argocd_application.ziti_management.metadata[0].name,
    argocd_application.users.metadata[0].name,
    argocd_application.expose.metadata[0].name,
    argocd_application.organizations.metadata[0].name,
    argocd_application.llm.metadata[0].name,
    argocd_application.files.metadata[0].name,
    argocd_application.notifications.metadata[0].name,
    argocd_application.agents_orchestrator.metadata[0].name,
    argocd_application.media_proxy.metadata[0].name,
    argocd_application.chat_app.metadata[0].name,
    argocd_application.console_app.metadata[0].name,
    argocd_application.tracing_app.metadata[0].name,
    argocd_application.gateway.metadata[0].name,
    argocd_application.llm_proxy.metadata[0].name,
  ]
}

output "platform_app_ids" {
  description = "Identifiers returned by the Argo CD provider for the applications"
  value = [
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
    argocd_application.threads.id,
    argocd_application.metering.id,
    argocd_application.tracing.id,
    argocd_application.chat.id,
    argocd_application.secrets.id,
    argocd_application.authorization.id,
    argocd_application.identity.id,
    argocd_application.token_counting.id,
    argocd_application.notifications_redis.id,
    argocd_application.runners.id,
    argocd_application.apps.id,
    argocd_application.agents.id,
    argocd_application.ziti_management.id,
    argocd_application.users.id,
    argocd_application.expose.id,
    argocd_application.organizations.id,
    argocd_application.llm.id,
    argocd_application.files.id,
    argocd_application.notifications.id,
    argocd_application.agents_orchestrator.id,
    argocd_application.media_proxy.id,
    argocd_application.chat_app.id,
    argocd_application.console_app.id,
    argocd_application.tracing_app.id,
    argocd_application.gateway.id,
    argocd_application.llm_proxy.id,
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

output "ziti_workload_dns_service_ip" {
  value       = kubernetes_service_v1.ziti_workload_dns.spec[0].cluster_ip
  description = "ClusterIP for the dev/local workload-only Ziti DNS resolver"
}
