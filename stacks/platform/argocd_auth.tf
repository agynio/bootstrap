data "kubernetes_secret_v1" "argocd_platform_token" {
  count = var.argocd_token_secret_enabled ? 1 : 0

  metadata {
    name      = var.argocd_token_secret_name
    namespace = var.argocd_token_secret_namespace
  }
}

locals {
  argocd_secret_raw = (
    var.argocd_token_secret_enabled && can(data.kubernetes_secret_v1.argocd_platform_token[0])
    ? try(data.kubernetes_secret_v1.argocd_platform_token[0].data[var.argocd_token_secret_key], "")
    : ""
  )

  argocd_secret_value = local.argocd_secret_raw != "" ? trimspace(base64decode(local.argocd_secret_raw)) : ""

  argocd_secret_token = (
    var.argocd_token_secret_enabled && local.argocd_secret_value != ""
    ? local.argocd_secret_value
    : null
  )

  argocd_manual_token = (
    var.argocd_auth_token != null && trimspace(var.argocd_auth_token) != ""
    ? trimspace(var.argocd_auth_token)
    : null
  )

  argocd_provider_token = local.argocd_manual_token != null ? local.argocd_manual_token : local.argocd_secret_token
}
