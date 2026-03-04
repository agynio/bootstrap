locals {
  istio_gateway_namespace       = data.terraform_remote_state.system.outputs.istio_gateway_namespace
  istio_gateway_tls_secret_name = data.terraform_remote_state.system.outputs.wildcard_tls_gateway_secret_name
}

resource "kubernetes_manifest" "platform_gateway" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "platform-gateway"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway"
      }
      "servers" = [
        {
          "port" = {
            "number"   = 443
            "name"     = "https"
            "protocol" = "HTTPS"
          }
          "tls" = {
            "mode"           = "SIMPLE"
            "credentialName" = local.istio_gateway_tls_secret_name
          }
          "hosts" = [
            "agyn.dev",
            "*.agyn.dev",
          ]
        }
      ]
    }
  }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
  ]
}

resource "kubernetes_manifest" "virtualservice_argocd" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "argocd"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["argocd.agyn.dev"]
      "gateways" = ["platform-gateway"]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "argo-cd-argocd-server.argocd.svc.cluster.local"
                "port" = {
                  "number" = 8080
                }
              }
            }
          ]
        }
      ]
    }
  }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
  ]
}
