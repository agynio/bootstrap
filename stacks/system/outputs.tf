output "installed_namespaces" {
  value       = [
    kubernetes_namespace.istio_system.metadata[0].name,
    kubernetes_namespace.istio_gateway.metadata[0].name,
    kubernetes_namespace.argocd.metadata[0].name,
  ]
  description = "Installed namespaces"
}

output "releases" {
  value       = [
    helm_release.istio_base.name,
    helm_release.istiod.name,
    helm_release.istio_gateway.name,
    helm_release.argo_cd.name,
  ]
  description = "Installed Helm releases"
}
