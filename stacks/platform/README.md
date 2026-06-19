# Platform stack

Deploy platform workloads via Argo CD applications sourced from [agynio/platform](https://github.com/agynio/platform) alongside Terraform-managed bootstrap jobs and supporting configuration. PostgreSQL databases are provisioned through the shared [agynio/postgres-helm](https://github.com/agynio/postgres-helm) chart published to GHCR.

## Prerequisites

- `stacks/k8s` and `stacks/system` applied so that Argo CD and Istio are running in the cluster.
- Local `kubectl` access to the target cluster (the stack uses the kubeconfig defined by `kubeconfig_path`).
- Persistent storage classes available for PostgreSQL PVCs (stateful components rely on dynamic provisioning).

> Apply `terraform -chdir=stacks/k8s apply` before this stack so the chosen `domain` and ingress `port` are available via `terraform_remote_state`. The apply prompts with defaults (`agyn.dev` / `2496`); override non-interactively via flags like `terraform -chdir=stacks/k8s apply -var='domain=example.dev' -var='port=8443'` or environment variables `TF_VAR_domain` / `TF_VAR_port`.

## Usage

```bash
cd stacks/platform
terraform init
terraform validate
terraform apply
```

After the system stack is applied, Istio exposes a single ingress listener on port 2496 and routes traffic by hostname (the port is configurable via the k8s stack `port` variable):

- `agyn.dev`
- `api.agyn.dev`
- `argocd.agyn.dev`

Terraform connects to Argo CD through the ingress at `https://argocd.agyn.dev:2496` (default credentials `admin/admin`; accept the self-signed certificate). The same listener serves the application endpoints:

- Platform UI: `https://agyn.dev:2496`
- Platform API: `https://api.agyn.dev:2496`

Each application chart enables a Kubernetes `Ingress` with `ingressClassName: istio`, routing hostnames through the Istio ingress gateway's HTTPS listener (exposed on host port 2496). No additional ingress controller is required; ensure the hostnames above resolve locally and use `curl -k` or your browser to trust the self-signed certificates.

### Chart source

Platform charts are pulled from the GHCR OCI registry (`ghcr.io/agynio/charts`). Pin the releases with the per-service chart version variables. The PostgreSQL Argo CD applications use the same registry and are pinned via `postgres_chart_version`.

### NATS JetStream event bus

NATS JetStream is deployed as a core platform application for durable
service-to-service events. Terraform creates an Argo CD application named
`nats` in the platform namespace using the upstream NATS Helm chart. The
application enables
JetStream file storage with a PVC (`nats_jetstream_file_store_pvc_size`,
default `10Gi`) and a matching file store max size
(`nats_jetstream_file_store_max_size`, default `10Gi`). The stable in-cluster
endpoint is exposed as the `nats_endpoint` output and defaults to:

```text
nats://nats.platform.svc.cluster.local:4222
```

By default, the NATS application also runs a stream configuration job for the
platform event streams required by private Networks and Groups:

- `AGYN_GROUPS` on subject `agyn.groups.>`
- `AGYN_NETWORKS` on subject `agyn.networks.>`

Set `nats_platform_streams_enabled=false` only if streams are managed outside
bootstrap. The stream configuration Job is annotated as an Argo CD PostSync hook
and Helm post-install/post-upgrade hook with before-hook-creation cleanup, so
stream config changes delete and recreate the Job instead of attempting an
immutable Job update. Stream retention knobs follow the NATS API schema: age and
duplicate window values are in nanoseconds, and size values are in bytes.


### Graph persistence

`platform-server` mounts `/shared` (sourced from the repository-root `./shared` directory created by the k3d stack) into `/mnt/graph` and sets `GRAPH_REPO_PATH=/mnt/graph/graph`. The graph repository is created under the host directory at `./shared/graph`, and swap artifacts land transiently under `./shared`.

Verify persistence by:

1. Applying the stack (`terraform -chdir=stacks/platform apply`).
2. Confirming the `platform-server` pod is running (`kubectl get pods -n platform`).
3. Triggering a graph write via the Platform API.
4. Inspecting `./shared/graph` on the host for new repository contents.
5. Restarting the `platform-server` pod and re-confirming the graph data is still served.

## Applications deployed

| Sync wave | Application        | Purpose                             | Notes |
|-----------|--------------------|-------------------------------------|-------|
| 5         | `platform-db`      | PostgreSQL for platform workloads   | Uses chart `oci://ghcr.io/agynio/charts/postgres-helm` with inline Helm values |
| 18        | `k8s-runner`       | Kubernetes workspace runner         | Uses cluster-wide RBAC; TCP-only runner mode |
| 16        | `nats`             | NATS JetStream event bus            | Required by Groups and private Networks |
| 20        | `platform-server`  | Core platform API                   | Depends on `platform-db` |
| 25        | `platform-ui`      | Platform web UI                     | Connects to `platform-server` |

All chart versions, image tags, and critical secrets are pinned via Terraform variables for reproducibility.

## DEV/E2E-only Ziti diagnostics secret

`ziti-diagnostics` is reserved for development and reusable E2E diagnostics.
When explicitly enabled, the platform stack publishes a Kubernetes secret with
dedicated Ziti diagnostics credentials and grants the `agents-orchestrator-e2e`
service account get-only access to that secret for failure diagnostics.

Production deployments must leave `enable_ziti_diagnostics` at its
default value of `false` so the secret and RBAC do not exist.
