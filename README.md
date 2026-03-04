# bootstrap_v2

Terraform stacks for local Kubernetes development using k3d, with decoupled system and app layers.

Stacks (planned):
- k8s: local k3d cluster (this repository includes the initial stack)
- system: Istio, Argo CD, and other dependencies (future)
- apps: our services deployed via Argo CD Application CRs (future)

All stacks use local directory backend state per stack.

## Ingress routing

The system stack provisions an Istio ingress gateway that exposes a single LoadBalancer listener on port 8080. Traffic is routed by hostname; ensure the following DNS entries resolve to `127.0.0.1` on your workstation (e.g. via `/etc/hosts`):

- `agyn.dev`
- `api.agyn.dev`
- `argocd.agyn.dev`
- `litellm.agyn.dev`
- `vault.agyn.dev`

Common endpoints served through the gateway:

- Platform UI: `https://agyn.dev:8080`
- Platform API: `https://api.agyn.dev:8080`
- Argo CD UI/API: `https://argocd.agyn.dev:8080`
- LiteLLM API: `https://litellm.agyn.dev:8080`
- Vault UI/API: `https://vault.agyn.dev:8080`

Terraform defaults expect Argo CD to be served at `argocd.agyn.dev:8080` (see `stacks/platform/terraform.tfvars.example`), matching the `argocd_server_addr` provider setting.

Each workload publishes a Kubernetes `Ingress` with `ingressClassName: istio`. Requests enter via the Istio ingress gateway's HTTPS listener on port 443 (exposed locally on host port 8080) and route by hostname to the target ClusterIP services. Access services over TLS at `https://<host>:8080` (accept the self-signed certificate locally with `curl -k`).

## Trusting the generated certificate authority

Running `terraform -chdir=stacks/system apply` writes the generated CA and wildcard certificates to `local-certs/`. Import `local-certs/ca-agyn-dev.pem` into your host trust store to avoid browser warnings:

- **macOS**: Keychain Access → *System* → *Certificates* → File → Import… → select `ca-agyn-dev.pem`, then double-click the certificate and set *Always Trust*.
- **Ubuntu/Debian**: Copy the file to `/usr/local/share/ca-certificates/agyn-dev.crt` and run `sudo update-ca-certificates`.
- **Fedora/RHEL**: Copy the file to `/etc/pki/ca-trust/source/anchors/ca-agyn-dev.pem` and run `sudo update-ca-trust`.
- **Windows**: Open `mmc`, add the *Certificates* snap-in for *Local Computer*, navigate to *Trusted Root Certification Authorities*, and import `ca-agyn-dev.pem`.

> Private keys are not written to disk unless `-var save_private_keys=true` is provided for the system stack.

## Inotify requirements for DinD (k3d/k3s)

Running k3d/k3s inside Docker-in-Docker relies on the host kernel's inotify limits - those sysctls are not namespaced. These fs.inotify sysctls are host-level and are not adjusted automatically by the sandbox; you must change them on the host. If `fs.inotify.max_user_instances` remains at distribution defaults, containerd's CRI plugin can fail with errors such as `unknown service runtime.v1.RuntimeService` and `fsnotify: too many open files`.

Recommended host settings when using this stack:

- `fs.inotify.max_user_instances`: 2048 for one or two clusters, 4096 for three to five clusters, and 8192 for maximum headroom.
- `fs.inotify.max_user_watches`: between 524288 and 1048576 (1048576 is a safe default).

Apply the setting temporarily:

```
sudo sysctl -w fs.inotify.max_user_instances=4096
```

Make the change persistent:

```
echo 'fs.inotify.max_user_instances=4096' | sudo tee /etc/sysctl.d/99-inotify.conf && sudo sysctl --system
```

Verify containerd is healthy and the cluster registers:

```
ctr plugins list | grep cri
kubectl get nodes
```

`ctr` should report the `cri` plugin as `ok`, and `kubectl` should list the server node.

> Platform v0.15.2 already raises `RLIMIT_NOFILE` and `RLIMIT_NPROC` inside Docker-in-Docker; the guidance above specifically addresses inotify limits that must be tuned on the host.
