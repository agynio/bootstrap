resource "kubernetes_namespace" "istio_system" {
  metadata { name = "istio-system" }
}

resource "kubernetes_namespace" "istio_gateway" {
  metadata { name = "istio-gateway" }
}

resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}
