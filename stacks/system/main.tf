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

resource "kubernetes_manifest" "platform_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "platform-gateway"
      namespace = kubernetes_namespace.istio_gateway.metadata[0].name
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [{
        port = {
          number   = 8080
          name     = "http-8080"
          protocol = "HTTP"
        }
        hosts = ["*.agyn.dev", "agyn.dev"]
      }]
    }
  }

  depends_on = [helm_release.istio_gateway]
}

# Argo CD
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = local.argo_repository_url
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  wait       = false

  depends_on = [kubernetes_manifest.platform_gateway]

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
      dex = {
        enabled = false
      }
      configs = {
        params = {
          "server.insecure" = "true"
        }
        cm = {
          admin = {
            enabled = true
          }
        }
        secret = {
          argocdServerAdminPassword      = "$2y$10$gE/JaT4x8KfNOkChbr8/AOP4PLOclnWYYFQVMeax3dg3H7UHfmtgK"
          argocdServerAdminPasswordMtime = "2026-03-03T12:00:00Z"
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "argocd_virtual_service" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "argocd"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      hosts = ["argocd.agyn.dev"]
      gateways = [
        "${kubernetes_namespace.istio_gateway.metadata[0].name}/platform-gateway"
      ]
      http = [{
        match = [{
          uri = {
            prefix = "/"
          }
        }]
        route = [{
          destination = {
            host = "argo-cd-argocd-server.argocd.svc.cluster.local"
            port = {
              number = 8080
            }
          }
        }]
      }]
    }
  }

  depends_on = [helm_release.argo_cd, kubernetes_manifest.platform_gateway]
}
