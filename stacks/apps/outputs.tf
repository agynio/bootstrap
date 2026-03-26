output "app_ids" {
  description = "App IDs keyed by slug"
  value = {
    reminders = agyn_app.reminders.id
  }
}

output "app_identity_ids" {
  description = "App identity IDs keyed by slug"
  value = {
    reminders = agyn_app.reminders.identity_id
  }
}

output "argocd_app_names" {
  description = "Names of Argo CD applications managed by this stack"
  value = [
    argocd_application.reminders_db.metadata[0].name,
    argocd_application.reminders.metadata[0].name,
  ]
}

output "argocd_app_ids" {
  description = "Identifiers returned by the Argo CD provider for the applications"
  value = [
    argocd_application.reminders_db.id,
    argocd_application.reminders.id,
  ]
}
