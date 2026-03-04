locals {
  kubeconfig_dir         = "${path.module}/.kube"
  kubeconfig_path        = "${local.kubeconfig_dir}/${var.cluster_name}-kubeconfig.yaml"
  ingress_container_port = 30443
  ingress_host_port      = 8080
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

resource "null_resource" "configure_lb_port" {
  triggers = {
    cluster_id = k3d_cluster.this.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -euo pipefail
      PATH=/workspace/bin:$PATH
      ports=$(docker ps --filter "name=k3d-${var.cluster_name}-serverlb" --format '{{.Ports}}' || true)
      if echo "$ports" | grep -q ":${local.ingress_host_port}->${local.ingress_container_port}/tcp"; then
        echo "Load balancer already exposes host ${local.ingress_host_port} -> ${local.ingress_container_port}/tcp"
      else
        k3d cluster edit ${var.cluster_name} --port-add ${local.ingress_host_port}:${local.ingress_container_port}@loadbalancer
      fi

      mapfile -t nodes < <(k3d node list --no-headers | awk -v cluster="${var.cluster_name}" '$3==cluster && ($2=="agent" || $2=="server"){print $1}')
      if [ $${#nodes[@]} -eq 0 ]; then
        echo "No nodes found for load balancer backend"
        exit 1
      fi

      mapfile -t servers < <(k3d node list --no-headers | awk -v cluster="${var.cluster_name}" '$3==cluster && $2=="server"{print $1}')
      if [ $${#servers[@]} -eq 0 ]; then
        echo "No server nodes found for API backend"
        exit 1
      fi

      tmpfile=$(mktemp)
      trap "rm -f $${tmpfile}" EXIT
      {
        echo "ports:"
        echo "  6443.tcp:"
        for n in "$${servers[@]}"; do
          echo "  - $${n}"
        done
        echo "  ${local.ingress_container_port}.tcp:"
        for n in "$${nodes[@]}"; do
          echo "  - $${n}"
        done
        echo "settings:"
        echo "  workerConnections: 1024"
      } > "$${tmpfile}"

      docker cp "$${tmpfile}" k3d-${var.cluster_name}-serverlb:/etc/confd/values.yaml
      docker exec k3d-${var.cluster_name}-serverlb nginx -s reload
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [k3d_cluster.this]
}
