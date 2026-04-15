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
    cluster = {
      mode = "standalone"
    }
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
    useCustomAdminSecret  = true
    customAdminSecretName = local.ziti_admin_secret_name
  })
  ziti_admin_password = var.ziti_admin_password_override != "" ? var.ziti_admin_password_override : random_password.ziti_controller_admin.result
}

resource "random_password" "ziti_controller_admin" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "ziti_controller_admin" {
  metadata {
    name      = local.ziti_admin_secret_name
    namespace = local.ziti_namespace
  }

  type = "Opaque"

  data = {
    "admin-user"     = "admin"
    "admin-password" = local.ziti_admin_password
  }

  lifecycle {
    ignore_changes = [data]
  }
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
  wait       = false

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
  wait = false

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
    kubernetes_secret_v1.ziti_controller_admin,
  ]
  wait = false

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
# Router pods and SDK clients (orchestrator, k8s-runner) must resolve these
# hostnames to reach the controller and edge router; without the rewrites
# they resolve to 127.0.0.1 (public wildcard DNS) and connections fail.
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
          # ziti-management runs in the platform namespace and must reach the
          # controller management API during startup for cert-based auth.
          rewrite name ziti-mgmt.${local.base_domain} ziti-controller-mgmt.${local.ziti_namespace}.svc.cluster.local
          rewrite name ziti-router.${local.base_domain} ziti-router-edge.${local.ziti_namespace}.svc.cluster.local
          rewrite name chat.${local.base_domain} istio-ingressgateway.${local.istio_gateway_namespace}.svc.cluster.local
          rewrite name tracing.${local.base_domain} istio-ingressgateway.${local.istio_gateway_namespace}.svc.cluster.local
          rewrite name console.${local.base_domain} istio-ingressgateway.${local.istio_gateway_namespace}.svc.cluster.local
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
