# Platform stack

Deploy platform workloads via Argo CD applications sourced from [agynio/platform](https://github.com/agynio/platform) alongside Terraform-managed bootstrap jobs and supporting configuration. PostgreSQL databases are provisioned through the shared [agynio/postgres-helm](https://github.com/agynio/postgres-helm) chart published to GHCR.

## Prerequisites

- `stacks/k8s` and `stacks/system` applied so that Argo CD, Istio, and Vault are running in the cluster.
- Local `kubectl` access to the target cluster (the stack uses the kubeconfig defined by `kubeconfig_path`).
- Persistent storage classes available for PostgreSQL, Vault, and registry mirror PVCs (stateful components rely on dynamic provisioning).

> Apply `terraform -chdir=stacks/k8s apply` before this stack so the chosen `domain` and ingress `port` are available via `terraform_remote_state`. The apply prompts with defaults (`agyn.dev` / `2496`); override non-interactively via flags like `terraform -chdir=stacks/k8s apply -var='domain=example.dev' -var='port=8443'` or environment variables `TF_VAR_domain` / `TF_VAR_port`.

## Usage

```bash
cd stacks/platform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform apply
```

After the system stack is applied, Istio exposes a single ingress listener on port 2496 and routes traffic by hostname (the port is configurable via the k8s stack `port` variable):

- `agyn.dev`
- `api.agyn.dev`
- `argocd.agyn.dev`
- `litellm.agyn.dev`
- `vault.agyn.dev`

Terraform connects to Argo CD through the ingress at `https://argocd.agyn.dev:2496` (default credentials `admin/admin`; accept the self-signed certificate). The same listener serves the application endpoints:

- Platform UI: `https://agyn.dev:2496`
- Platform API: `https://api.agyn.dev:2496`
- LiteLLM API: `https://litellm.agyn.dev:2496`
- Vault UI/API: `https://vault.agyn.dev:2496`

Each application chart enables a Kubernetes `Ingress` with `ingressClassName: istio`, routing hostnames through the Istio ingress gateway's HTTPS listener (exposed on host port 2496). No additional ingress controller is required; ensure the hostnames above resolve locally and use `curl -k` or your browser to trust the self-signed certificates.

### LiteLLM defaults

For development parity with bootstrap v1, LiteLLM deploys with:

- UI credentials: `admin` / `admin`
- Master key: `sk-dev-master-1234`
- Salt key: `sk-dev-salt-1234`
- PostgreSQL password: `change-me`

### Vault defaults

The Vault auto-init sidecar ensures a KV v2 secrets engine is mounted at
`secret/` after initialization. The sidecar seeds a sample development secret at
`secret/platform/example` (note `Provisioned by bootstrap_v2`, token
`dev-placeholder`) so platform services detect an available mount immediately.
Override this behaviour by setting the optional environment variables
`VAULT_SEED_SAMPLE_SECRET=false` or `VAULT_SAMPLE_SECRET_PATH` on the
`vault-auto-init` container if a different path or seeding strategy is required.

### Chart source

Platform charts are pulled from the GHCR OCI registry (`ghcr.io/agynio/charts`). Pin the release with `platform_chart_version` in `terraform.tfvars`. The PostgreSQL Argo CD applications use the same registry and are pinned via `postgres_chart_version`. If you need private registry credentials, register the GHCR repo in Argo CD before applying the stack. The `registry-mirror` app is the exception: it still pulls the upstream git chart from `https://github.com/twuni/docker-registry.helm.git`.

### Graph persistence

`platform-server` mounts `/shared` (sourced from the repository-root `./shared` directory created by the k3d stack) into `/mnt/graph` and sets `GRAPH_REPO_PATH=/mnt/graph/graph`. The graph repository is created under the host directory at `./shared/graph`, and swap artifacts land transiently under `./shared`.

Verify persistence by:

1. Applying the stack (`terraform -chdir=stacks/platform apply`).
2. Confirming the `platform-server` pod is running (`kubectl get pods -n platform`).
3. Triggering a graph write via the Platform API.
4. Inspecting `./shared/graph` on the host for new repository contents.
5. Restarting the `platform-server` pod and re-confirming the graph data is still served.

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
| 7         | `agent-state-db`   | PostgreSQL backing agent-state      | Same chart with agent-state credentials and PVC sizing |
| 10        | `vault`            | HashiCorp Vault in standalone mode  | Sidecar consumes the Terraform-managed script and PVC for init/unseal |
| 12        | `litellm`          | LiteLLM API deployment              | Connects to Argo CD-managed `litellm-db`; master key sourced from `litellm-master-key` secret |
| 16        | `agent-state`      | Agent state gRPC service            | Internal-only gRPC; no external routing required |
| 18        | `docker-runner`    | Platform workspace runner           | Uses shared secret and exposes gRPC on 7071 |
| 20        | `platform-server`  | Core platform API                   | Depends on `platform-db`, LiteLLM bootstrap, and Vault dev-root token |
| 25        | `platform-ui`      | Platform web UI                     | Connects to `platform-server` |

All chart versions, image tags, and critical secrets are pinned via Terraform variables for reproducibility. Adjust the defaults in `terraform.tfvars` to match your environment before applying.
