# Platform stack

Deploy platform workloads via Argo CD applications that reference the Helm charts in [agynio/platform](https://github.com/agynio/platform) plus their runtime dependencies.

## Prerequisites

- `stacks/k8s` and `stacks/system` applied so that Argo CD is installed in the cluster and the `argocd-platform-automation-token` secret exists in the `argocd` namespace.
- (Optional) Manual Argo CD authentication token if you disable the secret-based workflow.
- Persistent storage classes available for PostgreSQL, Vault, and registry mirror PVCs.

## Usage

```bash
cd stacks/platform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars if you need to override the secret location or provide a manual token
terraform init
terraform validate
terraform apply
```

For local clusters, Argo CD is typically reached via port-forwarding:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Use the forwarded host and port (`localhost:8080`). A token is read from the Kubernetes secret by default; set `argocd_auth_token` only when overriding the secret-based workflow.

## Applications deployed

| Sync wave | Application        | Purpose                             | Notes |
|-----------|--------------------|-------------------------------------|-------|
| 0         | `platform-db`      | Bitnami PostgreSQL for platform     | Auth defaults: `agents` user/password, database `agents` |
| 0         | `litellm-db`       | Bitnami PostgreSQL for LiteLLM      | Auth defaults: `litellm` user, password `change-me` |
| 1         | `registry-mirror`  | Twuni docker-registry proxy         | Proxies Docker Hub with persistent storage |
| 10        | `vault`            | HashiCorp Vault in standalone mode  | PVC size configurable via `vault_pvc_size` |
| 11        | `vault-init`       | Vault initialization/unseal job     | Creates/updates `vault-root-token` with root and unseal keys |
| 12        | `litellm`          | LiteLLM API deployment              | Connects to `litellm-db` using provided secrets |
| 13        | `litellm-bootstrap` | LiteLLM default key bootstrap job   | Generates default alias and writes `litellm-default-key` secret |
| 18        | `docker-runner`    | Platform workspace runner           | Uses shared secret and exposes gRPC on 7071 |
| 20        | `platform-server`  | Core platform API                   | Reads Vault token and LiteLLM client key from Kubernetes secrets |
| 25        | `platform-ui`      | Platform web UI                     | Connects to `platform-server` |

All chart versions, image tags, and critical secrets are pinned via Terraform variables for reproducibility. Adjust the defaults in `terraform.tfvars` to match your environment before applying.
