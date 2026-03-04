provider "kubernetes" {
  config_path = abspath("${path.module}/../k8s/.kube/agyn-local-kubeconfig.yaml")
}
