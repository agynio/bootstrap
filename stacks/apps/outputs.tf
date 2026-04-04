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

output "runner_ids" {
  description = "Runner IDs keyed by name"
  value = {
    k8s_runner = agyn_runner.k8s_runner.id
  }
}

output "argocd_app_names" {
  description = "Names of Argo CD applications managed by this stack"
  value = [
    argocd_application.apps_db.metadata[0].name,
    argocd_application.reminders_db.metadata[0].name,
    argocd_application.reminders.metadata[0].name,
    argocd_application.k8s_runner.metadata[0].name,
  ]
}

output "argocd_app_ids" {
  description = "Identifiers returned by the Argo CD provider for the applications"
  value = [
    argocd_application.apps_db.id,
    argocd_application.reminders_db.id,
    argocd_application.reminders.id,
    argocd_application.k8s_runner.id,
  ]
}
