locals {
  kubeconfig_dir  = "${path.module}/.kube"
  kubeconfig_path = "${local.kubeconfig_dir}/${var.cluster_name}-kubeconfig.yaml"
  k3s_required_extra_args = [for idx in range(var.servers) : {
    arg          = "--service-node-port-range=80-32767"
    node_filters = ["server:${idx}"]
  }]
  k3s_user_extra_args = [for arg in var.k3s_extra_args : {
    arg          = arg
    node_filters = []
  }]
  k3s_args = concat(local.k3s_required_extra_args, local.k3s_user_extra_args)
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
    for_each = length(local.k3s_args) > 0 ? [true] : []

    content {
      dynamic "extra_args" {
        for_each = local.k3s_args

        content {
          arg          = extra_args.value.arg
          node_filters = extra_args.value.node_filters
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
    }
  }
}

resource "local_sensitive_file" "kubeconfig" {
  filename             = local.kubeconfig_path
  content              = one(k3d_cluster.this.credentials).raw
  file_permission      = "0600"
  directory_permission = "0700"
}
