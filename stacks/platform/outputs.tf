output "platform_app_names" {
  description = "Names of Argo CD applications managed by this stack"
  value       = [argocd_application.platform_server.metadata[0].name, argocd_application.docker_runner.metadata[0].name]
}

output "platform_app_ids" {
  description = "Identifiers returned by the Argo CD provider for the applications"
  value       = [argocd_application.platform_server.id, argocd_application.docker_runner.id]
}

output "platform_namespace" {
  description = "Namespace where platform workloads are deployed"
  value       = var.platform_namespace
}
