output "installed_namespaces" {
  value = [
    kubernetes_namespace.cert_manager.metadata[0].name,
    kubernetes_namespace.ziti.metadata[0].name,
    kubernetes_namespace.istio_system.metadata[0].name,
    kubernetes_namespace.istio_gateway.metadata[0].name,
    kubernetes_namespace.argocd.metadata[0].name,
  ]
  description = "Installed namespaces"
}

output "releases" {
  value = [
    "cert-manager",
    "trust-manager",
    "ziti-controller",
    helm_release.istio_base.name,
    helm_release.istiod.name,
    helm_release.istio_gateway.name,
    helm_release.argo_cd.name,
  ]
  description = "Installed Helm releases"
}

output "wildcard_agyn_dev_certificate" {
  value       = tls_locally_signed_cert.wildcard_agyn_dev.cert_pem
  sensitive   = true
  description = "PEM-encoded wildcard TLS certificate for agyn.dev"
}

output "wildcard_agyn_dev_private_key" {
  value       = tls_private_key.wildcard_agyn_dev.private_key_pem
  sensitive   = true
  description = "PEM-encoded private key for the agyn.dev wildcard certificate"
}

output "istio_gateway_namespace" {
  value       = kubernetes_namespace.istio_gateway.metadata[0].name
  description = "Namespace hosting the Istio ingress gateway"
}

output "wildcard_tls_gateway_secret_name" {
  value       = kubernetes_secret_v1.wildcard_tls_gateway.metadata[0].name
  description = "TLS secret name containing the agyn.dev wildcard certificate for the ingress gateway"
}
