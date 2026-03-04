locals {
  kubeconfig_dir  = "${path.module}/.kube"
  kubeconfig_path = "${local.kubeconfig_dir}/${var.cluster_name}-kubeconfig.yaml"
}

resource "k3d_cluster" "this" {
  name    = var.cluster_name
  servers = var.servers
  agents  = var.agents

  image = "rancher/k3s:${var.k3s_version}"

  dynamic "kube_api" {
    for_each = var.expose_api ? [true] : []

    content {
      host      = "127.0.0.1"
      host_ip   = "127.0.0.1"
      host_port = var.api_port
    }
  }

  dynamic "k3s" {
    for_each = length(var.k3s_extra_args) > 0 ? [true] : []

    content {
      dynamic "extra_args" {
        for_each = var.k3s_extra_args

        content {
          arg          = extra_args.value
          node_filters = ["server:*"]
        }
      }
    }
  }

  dynamic "port" {
    for_each = var.ports

    content {
      host           = try(port.value.host, "")
      host_port      = port.value.host_port
      container_port = port.value.container_port
      protocol       = upper(port.value.protocol)
      node_filters   = try(port.value.node_filters, [])
    }
  }

}

resource "local_sensitive_file" "kubeconfig" {
  filename             = local.kubeconfig_path
  content              = one(k3d_cluster.this.credentials).raw
  file_permission      = "0600"
  directory_permission = "0700"
}
