resource "kubernetes_namespace" "cert_manager" {
  metadata { name = "cert-manager" }
}

resource "kubernetes_namespace" "ziti" {
  metadata { name = "ziti" }
}

resource "kubernetes_namespace" "istio_system" {
  metadata { name = "istio-system" }
}

resource "kubernetes_namespace" "istio_gateway" {
  metadata { name = "istio-gateway" }
}

resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}
