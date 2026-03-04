output "installed_namespaces" {
  value = [
    kubernetes_namespace.istio_system.metadata[0].name,
    kubernetes_namespace.istio_gateway.metadata[0].name,
    kubernetes_namespace.argocd.metadata[0].name,
  ]
  description = "Installed namespaces"
}

output "releases" {
  value = [
    helm_release.istio_base.name,
    helm_release.istiod.name,
    helm_release.istio_gateway.name,
    helm_release.argo_cd.name,
  ]
  description = "Installed Helm releases"
}

output "wildcard_agyn_dev_certificate" {
  value       = tls_self_signed_cert.wildcard_agyn_dev.cert_pem
  sensitive   = true
  description = "PEM-encoded wildcard TLS certificate for agyn.dev"
}

output "wildcard_agyn_dev_private_key" {
  value       = tls_private_key.wildcard_agyn_dev.private_key_pem
  sensitive   = true
  description = "PEM-encoded private key for the agyn.dev wildcard certificate"
}
