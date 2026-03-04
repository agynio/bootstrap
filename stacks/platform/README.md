# Platform stack

Deploy platform workloads via Argo CD applications sourced from [agynio/platform](https://github.com/agynio/platform) alongside Terraform-managed bootstrap jobs and supporting configuration. PostgreSQL databases are provisioned through the shared [agynio/postgres-helm](https://github.com/agynio/postgres-helm) chart published to GHCR.

## Prerequisites

- `stacks/k8s` and `stacks/system` applied so that Argo CD, Istio, and Vault are running in the cluster.
- Local `kubectl` access to the target cluster (the stack uses the kubeconfig defined by `kubeconfig_path`).
- Persistent storage classes available for PostgreSQL, Vault, and registry mirror PVCs (stateful components rely on dynamic provisioning).

## Usage

```bash
cd stacks/platform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform apply
```

After the system stack is applied, Istio exposes a single ingress listener on port 8080 and routes traffic by hostname. Ensure the following hostnames resolve to `127.0.0.1` on your workstation (for example via `/etc/hosts`):

- `agyn.dev`
- `api.agyn.dev`
- `argocd.agyn.dev`
- `litellm.agyn.dev`
- `vault.agyn.dev`

Terraform connects to Argo CD through the ingress at `https://argocd.agyn.dev:8080` (default credentials `admin/admin`; accept the self-signed certificate). The same listener serves the application endpoints:

- Platform UI: `https://agyn.dev:8080`
- Platform API: `https://api.agyn.dev:8080`
- LiteLLM API: `https://litellm.agyn.dev:8080`
- Vault UI/API: `https://vault.agyn.dev:8080`

Each application chart enables a Kubernetes `Ingress` with `ingressClassName: istio`, routing hostnames through the Istio ingress gateway's HTTPS listener (exposed on host port 8080). No additional ingress controller is required; ensure the hostnames above resolve locally and use `curl -k` or your browser to trust the self-signed certificates.

### LiteLLM defaults

For development parity with bootstrap v1, LiteLLM deploys with:

- UI credentials: `admin` / `admin`
- Master key: `sk-dev-master-1234`
- Salt key: `sk-dev-salt-1234`
- PostgreSQL password: `change-me`

### Repository authentication

If the platform Helm charts are private, supply credentials via Terraform variables (environment variables shown below) before running `terraform apply`:

```bash
export TF_VAR_platform_repo_username="x-access-token"
export TF_VAR_platform_repo_password="$GITHUB_TOKEN"
```

Any GitHub personal access token with `repo` scope works. The credentials are passed to Argo CD as basic-auth values and are not stored in Kubernetes secrets by this stack. Override them per environment as needed.

## Terraform-managed components

| Component | Kind | Purpose | Notes |
|-----------|------|---------|-------|
| `vault-auto-init` | `ConfigMap` | Provides the init/unseal script used by Vault sidecar | Script now supports optional persistence flags and one-shot execution |
| `vault-init-unseal` | `Job` | Mounts Vault data PVC and performs initial init/unseal | Uses the shared script with `EXIT_AFTER_UNSEAL=true`; no keys are written to Kubernetes Secrets |
| `litellm-bootstrap-default-key` | `Job` | Generates/reconciles the default LiteLLM key secret | Uses in-cluster RBAC scoped to `secrets` writes in the `platform` namespace; waits for the `litellm-db` Application |

The jobs wait for successful completion during `terraform apply` to ensure bootstrap steps finish before dependent services roll out.

## Applications deployed

| Sync wave | Application        | Purpose                             | Notes |
|-----------|--------------------|-------------------------------------|-------|
| 1         | `registry-mirror`  | Twuni docker-registry proxy         | Proxies Docker Hub with persistent storage |
| 5         | `platform-db`      | PostgreSQL for platform workloads   | Uses chart `oci://ghcr.io/agynio/charts/postgres-helm` with inline Helm values |
| 6         | `litellm-db`       | PostgreSQL backing LiteLLM          | Same chart with LiteLLM-specific credentials and PVC sizing |
| 10        | `vault`            | HashiCorp Vault in standalone mode  | Sidecar consumes the Terraform-managed script and PVC for init/unseal |
| 12        | `litellm`          | LiteLLM API deployment              | Connects to Argo CD-managed `litellm-db`; master key sourced from `litellm-master-key` secret |
| 18        | `docker-runner`    | Platform workspace runner           | Uses shared secret and exposes gRPC on 7071 |
| 20        | `platform-server`  | Core platform API                   | Depends on `platform-db`, LiteLLM bootstrap, and Vault dev-root token |
| 25        | `platform-ui`      | Platform web UI                     | Connects to `platform-server` |

All chart versions, image tags, and critical secrets are pinned via Terraform variables for reproducibility. Adjust the defaults in `terraform.tfvars` to match your environment before applying.
