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
            local.base_domain,
            "*.${local.base_domain}",
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

resource "kubernetes_manifest" "ziti_passthrough_gateway" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "ziti-passthrough-gateway"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway"
      }
      "servers" = [
        {
          "port" = {
            "number"   = local.ingress_port
            "name"     = "tls-ziti"
            "protocol" = "TLS"
          }
          "tls" = {
            "mode" = "PASSTHROUGH"
          }
          "hosts" = [
            "ziti.${local.base_domain}",
            "ziti-mgmt.${local.base_domain}",
            "ziti-router.${local.base_domain}",
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
      "hosts"    = ["argocd.${local.base_domain}"]
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

resource "kubernetes_manifest" "virtualservice_ziti_controller" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "ziti-controller"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["ziti.${local.base_domain}"]
      "gateways" = ["ziti-passthrough-gateway"]
      "tls" = [
        {
          "match" = [
            {
              "port"     = local.ingress_port
              "sniHosts" = ["ziti.${local.base_domain}"]
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "ziti-controller-client.ziti.svc.cluster.local"
                "port" = {
                  "number" = 1280
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

resource "kubernetes_manifest" "virtualservice_ziti_router" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "ziti-router"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts"    = ["ziti-router.${local.base_domain}"]
      "gateways" = ["ziti-passthrough-gateway"]
      "tls" = [
        {
          "match" = [
            {
              "port"     = local.ingress_port
              "sniHosts" = ["ziti-router.${local.base_domain}"]
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "ziti-router-edge.ziti.svc.cluster.local"
                "port" = {
                  "number" = 3022
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

resource "kubernetes_manifest" "virtualservice_ziti_mgmt" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "ziti-controller-mgmt"
      "namespace" = local.istio_gateway_namespace
    }
    "spec" = {
      "hosts" = ["ziti-mgmt.${local.base_domain}"]
      "gateways" = [
        kubernetes_manifest.ziti_passthrough_gateway.manifest.metadata.name,
      ]
      "tls" = [
        {
          "match" = [
            {
              "port"     = local.ingress_port
              "sniHosts" = ["ziti-mgmt.${local.base_domain}"]
            }
          ]
          "route" = [
            {
              "destination" = {
                "host" = "ziti-controller-mgmt.ziti.svc.cluster.local"
                "port" = {
                  "number" = 1281
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
