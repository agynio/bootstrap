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

**Manual**

```sh
terraform -chdir=stacks/k8s init
terraform -chdir=stacks/k8s apply

terraform -chdir=stacks/system init
terraform -chdir=stacks/system apply

terraform -chdir=stacks/routing init
terraform -chdir=stacks/routing apply

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
- LiteLLM: https://litellm.agyn.dev:2496/
- Vault: https://vault.agyn.dev:2496/

## Gateway DevSpace

After the cluster is running, you can develop the gateway service from source
with DevSpace:

```sh
git clone git@github.com:agynio/gateway.git
cd gateway
devspace dev
```

The DevSpace pipeline patches the gateway deployment in the `platform`
namespace, syncs sources into the pod, and forwards port `8080`.
