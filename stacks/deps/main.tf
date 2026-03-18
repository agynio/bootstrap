locals {
  jetstack_repository_url = "https://charts.jetstack.io"
  openziti_repository_url = "https://openziti.io/helm-charts"

  cert_manager_values = yamlencode({
    crds = {
      enabled = true
      keep    = true
    }
  })

  trust_manager_values = yamlencode({
    crds = {
      keep = false
    }
    app = {
      trust = {
        namespace = local.ziti_namespace
      }
    }
  })

  ziti_controller_values = yamlencode({
    clientApi = {
      advertisedHost = "ziti.${local.base_domain}"
      advertisedPort = local.ingress_port
      service = {
        enabled = true
        type    = "ClusterIP"
      }
    }
    managementApi = {
      advertisedHost = "ziti-mgmt.${local.base_domain}"
      advertisedPort = local.ingress_port
      service = {
        enabled = true
        type    = "ClusterIP"
      }
    }
    persistence = {
      enabled = true
      size    = "2Gi"
    }
  })
}

resource "argocd_repository" "jetstack" {
  repo = local.jetstack_repository_url
  type = "helm"
}

resource "argocd_repository" "openziti" {
  repo = local.openziti_repository_url
  type = "helm"
}

resource "argocd_application" "cert_manager" {
  depends_on = [argocd_repository.jetstack]
  wait       = true

  metadata {
    name      = "cert-manager"
    namespace = local.argocd_namespace
    annotations = {
      "argocd.argoproj.io/compare-options" = "ServerSideDiff=true"
    }
  }

  spec {
    project = "default"

    source {
      repo_url        = local.jetstack_repository_url
      chart           = "cert-manager"
      target_revision = var.cert_manager_chart_version

      helm {
        values = local.cert_manager_values
      }
    }

    destination {
      server    = local.destination_server
      namespace = local.cert_manager_namespace
    }

    ignore_difference {
      group = "admissionregistration.k8s.io"
      kind  = "MutatingWebhookConfiguration"
      jq_path_expressions = [
        ".webhooks[]?.clientConfig.caBundle",
      ]
    }

    ignore_difference {
      group = "admissionregistration.k8s.io"
      kind  = "ValidatingWebhookConfiguration"
      jq_path_expressions = [
        ".webhooks[]?.clientConfig.caBundle",
      ]
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }

      sync_options = [
        "ServerSideApply=true",
        "ApplyOutOfSyncOnly=true",
        "CreateNamespace=false",
        "RespectIgnoreDifferences=true",
      ]

      retry {
        limit = 5
        backoff {
          duration     = "5s"
          factor       = 2
          max_duration = "3m"
        }
      }
    }
  }

  timeouts {
    create = "10m"
    update = "5m"
    delete = "5m"
  }
}

resource "argocd_application" "trust_manager" {
  depends_on = [
    argocd_application.cert_manager,
    argocd_repository.jetstack,
  ]
  wait = true

  metadata {
    name      = "trust-manager"
    namespace = local.argocd_namespace
  }

  spec {
    project = "default"

    source {
      repo_url        = local.jetstack_repository_url
      chart           = "trust-manager"
      target_revision = var.trust_manager_chart_version

      helm {
        values = local.trust_manager_values
      }
    }

    destination {
      server    = local.destination_server
      namespace = local.cert_manager_namespace
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }

      sync_options = [
        "ServerSideApply=true",
        "ApplyOutOfSyncOnly=true",
        "CreateNamespace=false",
      ]

      retry {
        limit = 5
        backoff {
          duration     = "5s"
          factor       = 2
          max_duration = "3m"
        }
      }
    }
  }

  timeouts {
    create = "10m"
    update = "5m"
    delete = "5m"
  }
}

resource "argocd_application" "ziti_controller" {
  depends_on = [
    argocd_application.cert_manager,
    argocd_application.trust_manager,
    argocd_repository.openziti,
  ]
  wait = true

  metadata {
    name      = "ziti-controller"
    namespace = local.argocd_namespace
  }

  spec {
    project = "default"

    source {
      repo_url        = local.openziti_repository_url
      chart           = "ziti-controller"
      target_revision = var.ziti_controller_chart_version

      helm {
        values = local.ziti_controller_values
      }
    }

    destination {
      server    = local.destination_server
      namespace = local.ziti_namespace
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }

      sync_options = [
        "ServerSideApply=true",
        "ApplyOutOfSyncOnly=true",
        "CreateNamespace=false",
      ]

      retry {
        limit = 5
        backoff {
          duration     = "5s"
          factor       = 2
          max_duration = "3m"
        }
      }
    }
  }

  timeouts {
    create = "10m"
    update = "5m"
    delete = "5m"
  }
}

# CoreDNS rewrite rules for OpenZiti in-cluster resolution.
# The controller bakes ziti.<domain> into enrollment JWTs as the issuer URL.
# Router pods must resolve this hostname during enrollment; without the rewrite
# it resolves to loopback and enrollment fails. The ziti-mgmt and ziti-router
# hostnames are only used by external clients or host-side tooling, so they do
# not need in-cluster rewrites.
resource "kubernetes_config_map_v1_data" "coredns_ziti_rewrites" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }

  force = true

  data = {
    Corefile = <<-COREFILE
      .:53 {
          errors
          health
          ready
          # The controller bakes its external hostname into enrollment JWTs.
          # Router pods must contact this URL to enroll. Without the rewrite it
          # resolves to 127.0.0.1 (loopback) and enrollment fails.
          rewrite name ziti.${local.base_domain} ziti-controller-client.${local.ziti_namespace}.svc.cluster.local
          kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
          }
          hosts /etc/coredns/NodeHosts {
            ttl 60
            reload 15s
            fallthrough
          }
          prometheus :9153
          forward . /etc/resolv.conf
          cache 30
          loop
          reload
          loadbalance
      }
    COREFILE
  }

  lifecycle {
    ignore_changes = [data["NodeHosts"]]
  }

  depends_on = [argocd_application.ziti_controller]
}
