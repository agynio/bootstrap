# bootstrap_v2

Terraform stacks for local Kubernetes development using k3d, with decoupled system and app layers.

Stacks (planned):
- k8s: local k3d cluster (this repository includes the initial stack)
- system: Istio, Argo CD, and other dependencies (future)
- apps: our services deployed via Argo CD Application CRs (future)

All stacks use local directory backend state per stack.
