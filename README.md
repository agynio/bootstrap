## Requirements

- terraform
- kubectl (optional; only needed for kubeconfig merge and cluster interaction)

## Setup

**Fast**

```sh
chmod +x apply.sh
./apply.sh
```

Use auto-apply mode to skip prompts and run Terraform with `-input=false -auto-approve`:

```sh
./apply.sh -y
```

`apply.sh` exports `K3D_IMAGE_LOADBALANCER` before Terraform runs so k3d uses a
pinned load balancer image tag instead of resolving
`ghcr.io/k3d-io/k3d-proxy:latest` at cluster creation time. The default is
pinned for the installed k3d CLI version (`v5.7.5`):

```sh
ghcr.io/k3d-io/k3d-proxy:5.7.5
```

When upgrading k3d, update this tag to the proxy image published for the new k3d
release. To test a different image locally or in CI, provide
`K3D_IMAGE_LOADBALANCER` in the environment before running `apply.sh`.

**Manual**

```sh
terraform -chdir=stacks/k8s init
terraform -chdir=stacks/k8s apply

terraform -chdir=stacks/system init
terraform -chdir=stacks/system apply

terraform -chdir=stacks/routing init
terraform -chdir=stacks/routing apply

terraform -chdir=stacks/data init
terraform -chdir=stacks/data apply

terraform -chdir=stacks/platform init
terraform -chdir=stacks/platform apply
```

Update kubeconfig after the k8s stack creates the cluster:

```sh
merged="$(KUBECONFIG=\"$KUBECONFIG:$HOME/.kube/config:$(pwd)/stacks/k8s/.kube/agyn-local-kubeconfig.yaml\" \
  kubectl config view --merge --flatten)"
printf '%s\n' "$merged" > "$HOME/.kube/config"
```

## Usage

Default domain and port: `agyn.dev` on `2496`.

- Platform UI: https://agyn.dev:2496/
- Platform API: https://agyn.dev:2496/api
- Argo CD: https://argocd.agyn.dev:2496/
- OpenFGA API: https://openfga.agyn.dev:2496/
- OpenFGA Playground: https://openfga-playground.agyn.dev:2496/

## NATS JetStream event bus

The platform stack deploys NATS JetStream for durable service-to-service
events used by private Networks and Groups service deployments.

The local deployment creates the `nats` Argo CD application in the platform
namespace, enables JetStream file storage with a PVC, and configures the
`AGYN_GROUPS` and `AGYN_NETWORKS` streams. The stable in-cluster endpoint is
available from the platform stack output `nats_endpoint`.

## DEV/E2E-only diagnostics credentials

The `ziti-diagnostics` Ziti identity, Kubernetes secret, and RBAC are for local
development and reusable E2E diagnostics only. They intentionally expose a
dedicated admin UPDB credential so the E2E diagnostics framework can query Ziti
management state after failures. Production deployments must not create or
publish these resources.

Both the `stacks/ziti` and `stacks/platform` Terraform stacks guard the
diagnostics resources behind `enable_ziti_diagnostics`, which
defaults to `false`. Only enable it in DEV/E2E environments, and keep the value
disabled for production plans and applies.
