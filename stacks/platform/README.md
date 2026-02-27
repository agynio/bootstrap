# Platform stack

Deploy platform workloads via Argo CD applications that reference the Helm charts in [agynio/platform](https://github.com/agynio/platform) plus their runtime dependencies.

## Prerequisites

- `stacks/k8s` and `stacks/system` applied so that Argo CD is installed in the cluster.
- Argo CD authentication token with permissions to manage applications.
- Persistent storage classes available for PostgreSQL, Vault, and registry mirror PVCs.

## Usage

```bash
cd stacks/platform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Argo CD details
terraform init
terraform validate
terraform apply
```

For local clusters, Argo CD is typically reached via port-forwarding:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Use the forwarded host and port (`localhost:8080`) along with an Argo CD token in `terraform.tfvars` when running this stack.

## Applications deployed

| Sync wave | Application        | Purpose                             | Notes |
|-----------|--------------------|-------------------------------------|-------|
| 0         | `platform-db`      | Bitnami PostgreSQL for platform     | Auth defaults: `agents` user/password, database `agents` |
| 0         | `litellm-db`       | Bitnami PostgreSQL for LiteLLM      | Auth defaults: `litellm` user, password `change-me` |
| 1         | `vault`            | HashiCorp Vault in standalone mode  | PVC size configurable via `vault_pvc_size` |
| 1         | `registry-mirror`  | Twuni docker-registry proxy         | Proxies Docker Hub with persistent storage |
| 2         | `litellm`          | LiteLLM API deployment              | Connects to `litellm-db` using provided secrets |
| 3         | `docker-runner`    | Platform workspace runner           | Uses shared secret and exposes gRPC on 7071 |
| 4         | `platform-server`  | Core platform API                   | Relies on Vault, LiteLLM, docker-runner, Postgres |
| 5         | `platform-ui`      | Platform web UI                     | Connects to `platform-server` |

All chart versions, image tags, and critical secrets are pinned via Terraform variables for reproducibility. Adjust the defaults in `terraform.tfvars` to match your environment before applying.
