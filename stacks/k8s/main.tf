locals {
  kubeconfig_path = "${path.module}/.kube/${var.cluster_name}-kubeconfig.yaml"
}

resource "k3d_cluster" "this" {
  name    = var.cluster_name
  servers = var.servers
  agents  = var.agents

  k3s_version    = var.k3s_version
  k3s_extra_args = var.k3s_extra_args

  expose_api = var.expose_api
  api_port   = var.api_port

  ports = [
    for p in var.ports : {
      container_port = p.container_port
      host_port      = p.host_port
      protocol       = p.protocol
    }
  ]

  kubeconfig_path = local.kubeconfig_path
}
