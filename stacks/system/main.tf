# Helm repositories
locals {
  istio_repository_url = "https://istio-release.storage.googleapis.com/charts"
  argo_repository_url  = "https://argoproj.github.io/argo-helm"
}

# Istio base (CRDs)
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = local.istio_repository_url
  chart      = "base"
  version    = var.istio_chart_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
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

  values = [
    yamlencode({
      meshConfig = {
        ingressClass            = "istio"
        ingressControllerMode   = "STRICT"
        ingressServiceNamespace = kubernetes_namespace.istio_gateway.metadata[0].name
        ingressService          = "istio-ingressgateway"
        ingressServicePort      = 443
        ingressServicePortName  = "https"
        ingressListenerPort     = 443
        ingressListenerPortName = "https"
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
  wait = false

  values = [
    yamlencode({
      name = "istio-ingressgateway",
      service = {
        type = "LoadBalancer",
        ports = [
          {
            name       = "https"
            port       = 443
            targetPort = 8443
            protocol   = "TCP"
          }
        ]
      }
    })
  ]
}

# Wildcard TLS certificate for *.agyn.dev
resource "tls_private_key" "wildcard_agyn_dev" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "wildcard_agyn_dev" {
  private_key_pem = tls_private_key.wildcard_agyn_dev.private_key_pem

  subject {
    common_name  = "agyn.dev"
    organization = "Agyn"
  }

  dns_names             = ["agyn.dev", "*.agyn.dev"]
  validity_period_hours = 24 * 365
  early_renewal_hours   = 24 * 30
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret_v1" "wildcard_tls_argocd" {
  metadata {
    name      = "wildcard-agyn-dev-tls"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.wildcard_agyn_dev.cert_pem
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
    "tls.crt" = tls_self_signed_cert.wildcard_agyn_dev.cert_pem
    "tls.key" = tls_private_key.wildcard_agyn_dev.private_key_pem
  }
}

# Argo CD
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = local.argo_repository_url
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  depends_on = [kubernetes_secret_v1.wildcard_tls_argocd]

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
          enabled          = true
          ingressClassName = "istio"
          hostname         = "argocd.agyn.dev"
          https            = true
          tls              = false
          extraTls = [
            {
              hosts      = ["argocd.agyn.dev"]
              secretName = kubernetes_secret_v1.wildcard_tls_argocd.metadata[0].name
            }
          ]
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
        }
        secret = {
          argocdServerAdminPassword      = "$2a$10$hR1GwTdUGuvKqOZBrM2ctu8eAwE70ItpOXOHgslxBqG6UHIRhRrzK"
          argocdServerAdminPasswordMtime = "2026-02-27T14:54:31Z"
        }
      }
    })
  ]
}
