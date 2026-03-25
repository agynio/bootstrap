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
