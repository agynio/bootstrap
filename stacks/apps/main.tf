resource "agyn_app" "reminders" {
  slug        = "reminders"
  name        = "Reminders"
  description = "Delayed message delivery to threads"
}

resource "kubernetes_secret_v1" "reminders_service_token" {
  metadata {
    name      = "reminders-service-token"
    namespace = var.platform_namespace
  }

  type = "Opaque"

  data = {
    token = agyn_app.reminders.service_token
  }
}
