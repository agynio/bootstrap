output "minio_app_name" {
  description = "Name of the MinIO Argo CD application"
  value       = argocd_application.minio.metadata[0].name
}

output "platform_namespace" {
  description = "Namespace where platform workloads are deployed"
  value       = kubernetes_namespace.platform.metadata[0].name
}
