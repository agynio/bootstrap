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
pinned load balancer image instead of resolving `ghcr.io/k3d-io/k3d-proxy:latest`
at cluster creation time. The default is pinned for the installed k3d CLI
version (`v5.7.5`):

```sh
ghcr.io/k3d-io/k3d-proxy@sha256:6466619f9f2b34273e927f96e5d606c485c5803aaa8033193793b5d8137aba9e
```

When upgrading k3d, update this digest to the proxy image published for the new
k3d release. To test a different image locally or in CI, provide
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
