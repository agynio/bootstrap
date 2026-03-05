locals {
  kubeconfig_dir  = "${path.module}/.kube"
  kubeconfig_path = "${local.kubeconfig_dir}/${var.cluster_name}-kubeconfig.yaml"
  ports_effective = coalesce(var.ports, [
    {
      container_port = 443
      host_port      = var.port
      protocol       = "tcp"
      node_filters   = ["loadbalancer"]
    }
  ])
  effective_k3d_host_shared_path = abspath("${path.module}/../../shared")
}

resource "null_resource" "k3d_host_shared_path" {
  triggers = {
    path = local.effective_k3d_host_shared_path
  }

  provisioner "local-exec" {
    command = "mkdir -p \"${local.effective_k3d_host_shared_path}\" && chmod 0777 \"${local.effective_k3d_host_shared_path}\""
  }
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
    for_each = local.ports_effective

    content {
      host           = try(port.value.host, "")
      host_port      = port.value.host_port
      container_port = port.value.container_port
      protocol       = upper(port.value.protocol)
      node_filters   = try(port.value.node_filters, [])
    }
  }

  volume {
    source       = local.effective_k3d_host_shared_path
    destination  = "/shared"
    node_filters = ["all"]
  }

  depends_on = [null_resource.k3d_host_shared_path]

}

resource "local_sensitive_file" "kubeconfig" {
  filename             = local.kubeconfig_path
  content              = one(k3d_cluster.this.credentials).raw
  file_permission      = "0600"
  directory_permission = "0700"
}
