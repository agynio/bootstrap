# Local appliance spike

This is an opt-in spike path for building a pre-provisioned local Agyn
appliance from the normal bootstrap source of truth. It does not change
`apply.sh`, default CI, Terraform stacks, or downstream users by default.

The spike currently produces the closest feasible artifact instead of relying on
one Docker image alone:

- a committed k3d server container image,
- compressed snapshots of the Docker volumes that k3d mounts at
  `/var/lib/rancher/k3s`, `/var/lib/kubelet`, and `/var/lib/cni` for the server
  and each configured agent node,
- a compressed `/shared` bind-mount snapshot,
- Docker inspect output for the captured k3d containers,
- a manifest and metadata image that can be pushed to GHCR and extracted by the
  restore command on a clean machine.

A plain `docker commit` is not enough for k3d state portability. k3d stores the
k3s datastore, kubelet state, CNI state, and image-related state in Docker
volumes mounted into each node container. Those mounts are outside the writable
container layer and are not included in a committed image. The restore path
therefore creates a matching k3d shell, stops it, restores the captured volumes,
and starts it again.

## Requirements

- Docker Engine
- k3d
- kubectl
- jq
- tar
- terraform and curl for `build` without `--skip-provision`
- GHCR login with package write permission before `publish`

## Build and validate locally

```sh
scripts/local-appliance.sh build \
  --image-repository ghcr.io/agynio/bootstrap-local-appliance \
  --image-tag dev
```

The build command:

1. runs `./apply.sh -y` with selected domain, port, and topology/version
   overrides,
2. runs `.github/scripts/verify_platform_health.sh`,
3. stops the source k3d cluster cleanly,
4. commits the server container image,
5. captures the mounted state volumes and inspect metadata for the server and
   each configured agent,
6. attempts to recreate a matching k3d cluster from the artifact,
7. validates that the Kubernetes API starts, nodes are Ready, PVC/PV objects are
   visible, and Argo CD Application objects are present.

Local smoke testing showed that capture succeeds, but restoring the k3s data
volume can hang before k3d observes `k3s is up and running`. That failure is the
expected spike limitation to investigate next; use `--skip-restore-validation`
when you only need to produce the artifact.

For an already-provisioned source cluster, skip the provisioning phase:

```sh
scripts/local-appliance.sh build --skip-provision
```

To capture without immediately running restore validation:

```sh
scripts/local-appliance.sh build --skip-restore-validation
```

## Topology and version options

`build` applies the following options during provisioning by passing Terraform
variables through the existing `apply.sh` execution:

- `--cluster-name`
- `--servers` (currently limited to `1`)
- `--agents`
- `--k3s-version`
- `--api-port`
- `--domain`
- `--port`

The capture and restore steps use the same values so node names, volume archives,
and manifest metadata stay consistent.

## Restore an existing artifact

```sh
scripts/local-appliance.sh restore \
  --artifact-dir dist/local-appliance \
  --image-repository ghcr.io/agynio/bootstrap-local-appliance \
  --image-tag dev
```

If `--artifact-dir` already contains `manifest.json`, restore uses the local
artifact directory. If it does not, restore pulls
`ghcr.io/agynio/bootstrap-local-appliance-metadata:<tag>` and extracts the
manifest, volume snapshots, and inspect metadata into `--artifact-dir` before
creating the k3d shell. The server image is pulled by `k3d cluster create` when
it is not already present locally.

The default restore cluster name is `agyn-local` so persisted node names match
objects stored in the k3s datastore. Use a different name only for experiments;
renaming a captured k3d cluster is not expected to be portable without rewriting
cluster state.

## Publish to GHCR

```sh
docker login ghcr.io
scripts/local-appliance.sh publish \
  --image-repository ghcr.io/agynio/bootstrap-local-appliance \
  --image-tag $(git rev-parse --short HEAD)
```

`publish` pushes two restorable tags:

- `ghcr.io/agynio/bootstrap-local-appliance:<tag>`: committed k3d server image,
- `ghcr.io/agynio/bootstrap-local-appliance-metadata:<tag>`: manifest, Docker
  inspect metadata, and compressed volume snapshots.

The build command can publish after local capture and restore validation with
`--publish`. The CLI rejects `--publish` when `--skip-restore-validation` is set
so GHCR tags are only pushed after a successful restore smoke test.

## Security notes

The artifact is intended for local development only. Do not build or publish it
from an environment containing GitHub tokens, cloud credentials,
production/staging credentials, real external Ziti enrollment tokens, or any
secret granting access to non-local Agyn infrastructure.

## Known limitations and next shape

- The artifact is not a single standalone Docker image. Docker volumes are
  required because k3d mounts core node state outside the committed container
  layer.
- The restore path is cluster-name sensitive. The default restore name remains
  `agyn-local` to match the captured k3s node records.
- The metadata image is a pragmatic OCI carrier for the volume snapshots. A
  follow-up can replace it with an OCI artifact layout once registry and client
  tooling is standardized.
- k3d load balancer and node labels are recreated by k3d rather than restored
  from Docker inspect verbatim.

## Useful investigation commands

```sh
docker inspect k3d-agyn-local-server-0 \
  --format '{{json .Mounts}}' | jq .

docker inspect k3d-agyn-local-agent-0 \
  --format '{{json .Mounts}}' | jq .

kubectl --kubeconfig stacks/k8s/.kube/agyn-local-kubeconfig.yaml get nodes -o wide
kubectl --kubeconfig stacks/k8s/.kube/agyn-local-kubeconfig.yaml get pv,pvc -A
kubectl --kubeconfig stacks/k8s/.kube/agyn-local-kubeconfig.yaml -n argocd get applications.argoproj.io
```

## Local validation results from this spike

Environment used on 2026-06-21:

```text
Docker client 29.4.3 / server 27.5.1 on linux/arm64
k3d 5.8.3 installed with Nix for local smoke testing
kubectl 1.36.1 installed with Nix for local smoke testing
Terraform 1.15.2 already available in the workspace
jq 1.8.1 and ShellCheck 0.11.0 installed with Nix
```

Baseline and static validation:

```sh
terraform fmt -check -recursive
shellcheck scripts/local-appliance.sh apply.sh install-ca-cert.sh .github/scripts/verify_platform_health.sh
bash -n scripts/local-appliance.sh
```

Result: all commands exited 0.

k3d mount investigation command:

```sh
k3d cluster create appliance-probe --servers 1 --agents 1 \
  --image rancher/k3s:v1.34.3-k3s1 --wait --timeout 120s

docker inspect k3d-appliance-probe-server-0 \
  --format '{{json .Mounts}}' | jq .
```

Observed server mounts included Docker volumes for `/var/lib/rancher/k3s`,
`/var/lib/kubelet`, `/var/lib/cni`, `/var/log`, and the shared k3d image volume
at `/k3d/images`. The agent had separate Docker volumes for the same k3s,
kubelet, CNI, and log paths plus the shared image volume. This confirms that a
committed node container image alone cannot contain the required persisted k3d
state.

Artifact capture smoke command:

```sh
scripts/local-appliance.sh build --skip-provision --skip-restore-validation \
  --image-repository local/agyn-bootstrap-appliance \
  --image-tag smoke-skip
```

Result: capture succeeded. The script created a committed server image,
`dist/local-appliance`, `dist/local-appliance.tar.gz`, and a metadata image. The
capture logs showed volume snapshots for `/var/lib/rancher/k3s`,
`/var/lib/kubelet`, `/var/lib/cni`, and `/shared`.

Restore validation smoke command:

```sh
scripts/local-appliance.sh build --skip-provision \
  --image-repository local/agyn-bootstrap-appliance \
  --image-tag smoke
```

Result: capture succeeded, then restore failed while starting the restored k3d
server. The final k3d error was:

```text
Failed to start server k3d-agyn-local-server-0: Node k3d-agyn-local-server-0 failed to get ready: error waiting for log line `k3s is up and running` from node 'k3d-agyn-local-server-0': stopped returning log lines: context deadline exceeded
```

Docker inspect on the restored server still showed the expected restored mounts:

```text
/var/lib/rancher/k3s -> Docker volume
/var/lib/kubelet -> Docker volume
/var/lib/cni -> Docker volume
/shared -> /workspace/bootstrap/shared bind mount
/k3d/images -> k3d-agyn-local-images Docker volume
```

This means the current closest feasible artifact is an image plus explicit state
snapshots. The next spike should investigate k3s datastore/node identity and k3d
startup assumptions after restoring `/var/lib/rancher/k3s`, or move to a more
explicit artifact shape such as a tarred k3d Docker volume set with a restore
controller script instead of treating the committed server image as the primary
artifact.
