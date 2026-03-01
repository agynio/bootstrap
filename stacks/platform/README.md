# Platform stack

Deploy platform workloads via Argo CD applications that reference the Helm charts in [agynio/platform](https://github.com/agynio/platform) plus their runtime dependencies.

## Prerequisites

- `stacks/k8s` and `stacks/system` applied so that Argo CD, Istio, and Vault are running in the cluster.
- Local `kubectl` access to the target cluster (the stack uses the kubeconfig defined by `kubeconfig_path`).
- Persistent storage classes available for PostgreSQL, Vault, and registry mirror PVCs.

## Usage

```bash
cd stacks/platform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform apply
```

Terraform automatically establishes a background port-forward to `svc/argo-cd-argocd-server` on `localhost:8080` and authenticates with the admin credentials (`argocd_admin_username` / `argocd_admin_password`, default `admin/admin`). The port-forward PID and logs are stored under `/tmp/agynio-bootstrap-v2/`. Destroying the stack tears the tunnel down.

### Repository authentication

Both the platform Helm charts and the bootstrap manifests live in private GitHub repositories. Supply credentials via Terraform variables (environment variables shown below) before running `terraform apply`:

```bash
export TF_VAR_platform_repo_username="x-access-token"
export TF_VAR_platform_repo_password="$GITHUB_TOKEN"
export TF_VAR_platform_stack_repo_username="x-access-token"
export TF_VAR_platform_stack_repo_password="$GITHUB_TOKEN"
```

Any GitHub personal access token with `repo` scope works. The values are passed to Argo CD as basic-auth credentials and are not stored in Kubernetes secrets by this stack. Override them per environment as needed.

## Applications deployed

| Sync wave | Application        | Purpose                             | Notes |
|-----------|--------------------|-------------------------------------|-------|
| 0         | `platform-db`      | Bitnami PostgreSQL for platform     | Auth defaults: `agents` user/password, database `agents` |
| 0         | `litellm-db`       | Bitnami PostgreSQL for LiteLLM      | Auth defaults: `litellm` user, password `change-me` |
| 1         | `vault-auto-init`  | ConfigMap with Vault auto-init script | Consumed by the Vault StatefulSet sidecar for init/unseal |
| 1         | `registry-mirror`  | Twuni docker-registry proxy         | Proxies Docker Hub with persistent storage |
| 10        | `vault`            | HashiCorp Vault in standalone mode  | Sidecar initialises Vault, writes artifacts under `/vault/data`, and unseals when required |
| 12        | `litellm`          | LiteLLM API deployment              | Connects to `litellm-db` using provided secrets |
| 13        | `litellm-bootstrap` | LiteLLM default key bootstrap job   | Generates default alias and writes `litellm-default-key` secret |
| 18        | `docker-runner`    | Platform workspace runner           | Uses shared secret and exposes gRPC on 7071 |
| 20        | `platform-server`  | Core platform API                   | Uses `VAULT_TOKEN=dev-root` and LiteLLM secrets |
| 25        | `platform-ui`      | Platform web UI                     | Connects to `platform-server` |

All chart versions, image tags, and critical secrets are pinned via Terraform variables for reproducibility. Adjust the defaults in `terraform.tfvars` to match your environment before applying.
