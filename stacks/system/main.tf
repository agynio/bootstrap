# Helm repositories
locals {
  istio_repository_url    = "https://istio-release.storage.googleapis.com/charts"
  argo_repository_url     = "https://argoproj.github.io/argo-helm"
  jetstack_repository_url = "https://charts.jetstack.io"
  openziti_repository_url = "https://openziti.io/helm-charts"
  local_certs_dir         = abspath("${path.root}/../../local-certs")
}

# cert-manager (OpenZiti prerequisite)
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = local.jetstack_repository_url
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  wait       = true

  values = [
    yamlencode({
      crds = {
        enabled = true
        keep    = true
      }
    })
  ]
}

# trust-manager (OpenZiti prerequisite)
resource "helm_release" "trust_manager" {
  name       = "trust-manager"
  repository = local.jetstack_repository_url
  chart      = "trust-manager"
  version    = var.trust_manager_chart_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  depends_on = [helm_release.cert_manager]
  wait       = true

  values = [
    yamlencode({
      crds = {
        keep = false
      }
      app = {
        trust = {
          namespace = kubernetes_namespace.ziti.metadata[0].name
        }
      }
    })
  ]
}

# OpenZiti controller
resource "helm_release" "ziti_controller" {
  name       = "ziti-controller"
  repository = local.openziti_repository_url
  chart      = "ziti-controller"
  version    = var.ziti_controller_chart_version
  namespace  = kubernetes_namespace.ziti.metadata[0].name
  depends_on = [
    helm_release.cert_manager,
    helm_release.trust_manager,
  ]
  wait = true

  values = [
    yamlencode({
      clientApi = {
        advertisedHost = "ziti.${local.base_domain}"
        advertisedPort = local.ingress_port
        service = {
          enabled = true
          type    = "ClusterIP"
        }
      }
      managementApi = {
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
  ]
}

# Istio base (CRDs)
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = local.istio_repository_url
  chart      = "base"
  version    = var.istio_chart_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  wait       = true
  atomic     = true
}

# Istio ingress class for Kubernetes Ingress resources
resource "kubernetes_ingress_class_v1" "istio" {
  metadata {
    name = "istio"
  }

  spec {
    controller = "istio.io/ingress-controller"
  }
}

# Istio control plane
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = local.istio_repository_url
  chart      = "istiod"
  version    = var.istio_chart_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  depends_on = [helm_release.istio_base]
  wait       = true

  values = [
    yamlencode({
      meshConfig = {
        ingressControllerMode   = "STRICT"
        ingressClass            = "istio"
        ingressService          = "istio-ingressgateway"
        ingressServiceNamespace = kubernetes_namespace.istio_gateway.metadata[0].name
      }
      pilot = {
        traceSampling = 1.0
      }
    })
  ]
}

# Istio gateway (minimal)
resource "helm_release" "istio_gateway" {
  name       = "istio-gateway"
  repository = local.istio_repository_url
  chart      = "gateway"
  version    = var.istio_chart_version
  namespace  = kubernetes_namespace.istio_gateway.metadata[0].name

  depends_on = [
    helm_release.istiod,
    kubernetes_secret_v1.wildcard_tls_gateway,
  ]
  wait = true

  values = [
    yamlencode({
      name = "istio-ingressgateway"
      service = {
        type = "LoadBalancer"
        ports = [
          {
            name       = "status-port"
            port       = 15021
            protocol   = "TCP"
            targetPort = 15021
          },
          {
            name       = "http2"
            port       = 80
            protocol   = "TCP"
            targetPort = 80
          },
          {
            name       = "https"
            port       = 443
            protocol   = "TCP"
            targetPort = 443
          }
        ]
      }
    })
  ]
}

# Certificate authority for agyn.dev
resource "tls_private_key" "ca_agyn_dev" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca_agyn_dev" {
  private_key_pem       = tls_private_key.ca_agyn_dev.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 24 * 365
  early_renewal_hours   = 24 * 30

  subject {
    common_name  = "Agyn Local CA"
    organization = "Agyn"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

# Wildcard TLS certificate for *.agyn.dev signed by CA
resource "tls_private_key" "wildcard_agyn_dev" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "wildcard_agyn_dev" {
  private_key_pem = tls_private_key.wildcard_agyn_dev.private_key_pem

  subject {
    common_name  = local.base_domain
    organization = "Agyn"
  }

  dns_names = [local.base_domain, "*.${local.base_domain}"]
}

resource "tls_locally_signed_cert" "wildcard_agyn_dev" {
  cert_request_pem      = tls_cert_request.wildcard_agyn_dev.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca_agyn_dev.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca_agyn_dev.cert_pem
  validity_period_hours = 24 * 365
  early_renewal_hours   = 24 * 30

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

locals {
  wildcard_fullchain_pem = "${tls_locally_signed_cert.wildcard_agyn_dev.cert_pem}${tls_self_signed_cert.ca_agyn_dev.cert_pem}"
}

resource "kubernetes_secret_v1" "wildcard_tls_argocd" {
  metadata {
    name      = "wildcard-agyn-dev-tls"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = local.wildcard_fullchain_pem
    "tls.key" = tls_private_key.wildcard_agyn_dev.private_key_pem
  }
}

resource "kubernetes_secret_v1" "wildcard_tls_gateway" {
  metadata {
    name      = "wildcard-agyn-dev-tls"
    namespace = kubernetes_namespace.istio_gateway.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = local.wildcard_fullchain_pem
    "tls.key" = tls_private_key.wildcard_agyn_dev.private_key_pem
  }
}

resource "local_file" "ca_certificate" {
  filename             = "${local.local_certs_dir}/ca-agyn-dev.pem"
  content              = tls_self_signed_cert.ca_agyn_dev.cert_pem
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "wildcard_certificate" {
  filename             = "${local.local_certs_dir}/wildcard-agyn-dev.crt"
  content              = tls_locally_signed_cert.wildcard_agyn_dev.cert_pem
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "wildcard_fullchain" {
  filename             = "${local.local_certs_dir}/wildcard-agyn-dev.fullchain.crt"
  content              = local.wildcard_fullchain_pem
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "wildcard_private_key" {
  count                = var.save_private_keys ? 1 : 0
  filename             = "${local.local_certs_dir}/wildcard-agyn-dev.key"
  sensitive_content    = tls_private_key.wildcard_agyn_dev.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "ca_private_key" {
  count                = var.save_private_keys ? 1 : 0
  filename             = "${local.local_certs_dir}/ca-agyn-dev.key"
  sensitive_content    = tls_private_key.ca_agyn_dev.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

# Argo CD
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = local.argo_repository_url
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  depends_on = [
    kubernetes_secret_v1.wildcard_tls_argocd,
    helm_release.istio_gateway,
  ]

  values = [
    yamlencode({
      server = {
        insecure = true
        service = {
          type             = "ClusterIP"
          servicePortHttp  = 8080
          servicePortHttps = 8443
        }
        ingress = {
          enabled = false
        }
      }
      configs = {
        params = {
          "server.insecure" = true
        }
        cm = {
          admin = {
            enabled = true
          }
          "exec.enabled" = "true"
        }
        rbac = {
          "policy.csv"     = "p, role:admin, exec, create, */*, allow"
          "policy.default" = "role:readonly"
        }
        secret = {
          argocdServerAdminPassword      = "$2a$10$hR1GwTdUGuvKqOZBrM2ctu8eAwE70ItpOXOHgslxBqG6UHIRhRrzK"
          argocdServerAdminPasswordMtime = "2026-02-27T14:54:31Z"
        }
      }
    })
  ]
}
