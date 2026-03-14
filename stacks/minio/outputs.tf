output "minio_app_name" {
  description = "Name of the MinIO Argo CD application"
  value       = argocd_application.minio.metadata[0].name
}
