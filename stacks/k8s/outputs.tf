output "cluster_name" {
  value       = k3d_cluster.this.name
  description = "Created cluster name"
}

output "kubeconfig_path" {
  value       = local.kubeconfig_path
  description = "Local kubeconfig path"
}

output "servers" {
  value       = k3d_cluster.this.servers
  description = "Server node count"
}

output "agents" {
  value       = k3d_cluster.this.agents
  description = "Agent node count"
}

output "kube_api_endpoint" {
  value       = var.expose_api ? format("https://127.0.0.1:%d", var.api_port) : null
  description = "Local Kubernetes API endpoint (if exposed)"
}
