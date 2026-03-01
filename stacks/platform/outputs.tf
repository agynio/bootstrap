output "platform_app_names" {
  description = "Names of Argo CD applications managed by this stack"
  value = [
    argocd_application.platform_db.metadata[0].name,
    argocd_application.litellm_db.metadata[0].name,
    argocd_application.vault.metadata[0].name,
    argocd_application.vault_auto_init.metadata[0].name,
    argocd_application.registry_mirror.metadata[0].name,
    argocd_application.litellm.metadata[0].name,
    argocd_application.docker_runner.metadata[0].name,
    argocd_application.platform_server.metadata[0].name,
    argocd_application.platform_ui.metadata[0].name,
  ]
}

output "platform_app_ids" {
  description = "Identifiers returned by the Argo CD provider for the applications"
  value = [
    argocd_application.platform_db.id,
    argocd_application.litellm_db.id,
    argocd_application.vault.id,
    argocd_application.vault_auto_init.id,
    argocd_application.registry_mirror.id,
    argocd_application.litellm.id,
    argocd_application.docker_runner.id,
    argocd_application.platform_server.id,
    argocd_application.platform_ui.id,
  ]
}

output "platform_namespace" {
  description = "Namespace where platform workloads are deployed"
  value       = var.platform_namespace
}
