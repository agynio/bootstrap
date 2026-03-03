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

  values = [
    yamlencode({
      name = "istio-ingressgateway",
      service = {
        type = "LoadBalancer",
        ports = [{
          name       = "http-8080",
          port       = 8080,
          targetPort = 8080,
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
        service = {
          type             = "ClusterIP"
          servicePortHttp  = 8080
          servicePortHttps = 8443
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

resource "helm_release" "istio_routing" {
  name      = "istio-routing"
  chart     = "${path.module}/charts/istio-routing"
  namespace = kubernetes_namespace.istio_gateway.metadata[0].name
  version   = "0.1.1"

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod,
    helm_release.istio_gateway,
    helm_release.argo_cd,
  ]
}
