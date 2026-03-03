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
      pilot = {
        traceSampling = 1.0
      }
      meshConfig = {
        ingressClass    = "istio"
        ingressSelector = "ingressgateway"
        ingressService  = "istio-ingressgateway"
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

  depends_on = [helm_release.istiod]
  wait       = false

  values = [
    yamlencode({
      name = "istio-ingressgateway",
      service = {
        type = "LoadBalancer",
        ports = [{
          name       = "http-80",
          port       = 80,
          targetPort = 80,
          protocol   = "TCP"
        }]
      }
    })
  ]
}

# Argo CD
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = local.argo_repository_url
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

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
          tls              = false
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
