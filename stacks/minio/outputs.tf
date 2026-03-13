output "minio_app_name" {
  description = "Name of the MinIO Argo CD application"
  value       = argocd_application.minio.metadata[0].name
}

output "minio_bucket_name" {
  description = "Name of the MinIO bucket provisioned for files"
  value       = minio_s3_bucket.files.bucket
}

output "minio_endpoint" {
  description = "MinIO API endpoint exposed via Istio"
  value       = format("https://minio-api.%s:%d", local.base_domain, local.ingress_port)
}
