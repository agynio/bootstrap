# Routing Stack

This Terraform stack owns the Istio routing resources that front-end the
platform services. It must be applied after the `system` stack (which
installs Istio and publishes the wildcard TLS secret) and before the
`platform` stack (which deploys the applications behind these routes).
