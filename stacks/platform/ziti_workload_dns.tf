resource "kubernetes_config_map_v1" "ziti_workload_dns" {
  metadata {
    name      = "ziti-workload-dns"
    namespace = local.ziti_namespace
    labels = {
      "app.kubernetes.io/name"      = "ziti-workload-dns"
      "app.kubernetes.io/component" = "dns"
    }
  }

  data = {
    Corefile = <<-COREFILE
      .:53 {
          errors
          health
          ready
          hosts {
              ${data.kubernetes_service_v1.ziti_controller_client.spec[0].cluster_ip} ziti.${local.base_domain}
              ${data.kubernetes_service_v1.ziti_router_edge.spec[0].cluster_ip} ziti-router.${local.base_domain}
              fallthrough
          }
          forward . 1.1.1.1
          cache 30
          loop
          reload
      }
    COREFILE
  }
}

resource "kubernetes_deployment_v1" "ziti_workload_dns" {
  metadata {
    name      = "ziti-workload-dns"
    namespace = local.ziti_namespace
    labels = {
      "app.kubernetes.io/name"      = "ziti-workload-dns"
      "app.kubernetes.io/component" = "dns"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "ziti-workload-dns"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "ziti-workload-dns"
          "app.kubernetes.io/component" = "dns"
        }
      }

      spec {
        container {
          name  = "coredns"
          image = "coredns/coredns:1.12.4"
          args  = ["-conf", "/etc/coredns/Corefile"]

          port {
            name           = "dns"
            container_port = 53
            protocol       = "UDP"
          }

          port {
            name           = "dns-tcp"
            container_port = 53
            protocol       = "TCP"
          }

          port {
            name           = "health"
            container_port = 8080
            protocol       = "TCP"
          }

          port {
            name           = "ready"
            container_port = 8181
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = "health"
            }
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = "ready"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/coredns"
            read_only  = true
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map_v1.ziti_workload_dns.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "ziti_workload_dns" {
  metadata {
    name      = "ziti-workload-dns"
    namespace = local.ziti_namespace
    labels = {
      "app.kubernetes.io/name"      = "ziti-workload-dns"
      "app.kubernetes.io/component" = "dns"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "ziti-workload-dns"
    }

    port {
      name        = "dns"
      port        = 53
      target_port = "dns"
      protocol    = "UDP"
    }

    port {
      name        = "dns-tcp"
      port        = 53
      target_port = "dns-tcp"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_network_policy_v1" "ziti_workload_dns" {
  metadata {
    name      = "ziti-workload-dns"
    namespace = local.ziti_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "ziti-workload-dns"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = local.workload_namespace
          }
        }
      }

      ports {
        port     = "dns"
        protocol = "UDP"
      }

      ports {
        port     = "dns-tcp"
        protocol = "TCP"
      }
    }
  }
}
