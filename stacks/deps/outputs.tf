output "applications" {
  value = [
    argocd_application.cert_manager.metadata[0].name,
    argocd_application.trust_manager.metadata[0].name,
    argocd_application.ziti_controller.metadata[0].name,
  ]
  description = "Argo CD applications managed by the deps stack"
}
