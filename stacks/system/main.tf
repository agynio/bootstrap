# Helm repositories
locals {
  istio_repository_url = "https://istio-release.storage.googleapis.com/charts"
  argo_repository_url  = "https://argoproj.github.io/argo-helm"
  platform_ingress_hosts = [
    "argocd.agyn.dev",
    "agyn.dev",
    "api.agyn.dev",
    "vault.agyn.dev",
    "litellm.agyn.dev",
  ]
  istio_gateway_name = "platform-http"
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
        ingressClass            = "istio"
        ingressSelector         = "ingressgateway"
        ingressService          = "istio-ingressgateway"
        ingressServicePort      = 8080
        ingressServicePortName  = "http-8080"
        ingressListenerPort     = 8080
        ingressListenerPortName = "http-8080"
      }
    })
  ]
}

resource "time_sleep" "wait_for_istio_crds" {
  depends_on      = [helm_release.istio_base]
  create_duration = "30s"
}

# Istio gateway (minimal)
resource "helm_release" "istio_gateway" {
  name       = "istio-gateway"
  repository = local.istio_repository_url
  chart      = "gateway"
  version    = var.istio_chart_version
  namespace  = kubernetes_namespace.istio_gateway.metadata[0].name

  depends_on = [helm_release.istiod]
  wait       = true

  values = [
    yamlencode({
      name = "istio-ingressgateway",
      service = {
        type = "LoadBalancer",
        ports = [
          {
            name       = "http-8080"
            nodePort   = 8080
            port       = 8080
            targetPort = 8080
            protocol   = "TCP"
          }
        ]
      }
    })
  ]
}

resource "kubernetes_manifest" "istio_gateway_http" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = local.istio_gateway_name
      namespace = kubernetes_namespace.istio_gateway.metadata[0].name
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [
        {
          port = {
            number   = 8080
            name     = "http-8080"
            protocol = "HTTP"
          }
          hosts = local.platform_ingress_hosts
        }
      ]
    }
  }

  depends_on = [time_sleep.wait_for_istio_crds, helm_release.istio_gateway, helm_release.istiod]
}

resource "kubernetes_manifest" "virtual_service_argocd" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "argocd-http"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      hosts = ["argocd.agyn.dev"]
      gateways = [
        format("%s/%s", kubernetes_namespace.istio_gateway.metadata[0].name, local.istio_gateway_name)
      ]
      http = [
        {
          route = [
            {
              destination = {
                host = "argo-cd-argocd-server.argocd.svc.cluster.local"
                port = {
                  number = 8080
                }
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.istio_gateway_http, helm_release.argo_cd]
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
