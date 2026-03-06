# bootstrap_v2

Terraform stacks for local Kubernetes development using k3d, with decoupled system and app layers.

Stacks (planned):
- k8s: local k3d cluster (this repository includes the initial stack)
- system: Istio, Argo CD, and other dependencies (future)
- apps: our services deployed via Argo CD Application CRs (future)

All stacks use local directory backend state per stack.

## Gateway routing

The system stack provisions a shared Istio `Gateway` (`platform-gateway`) that terminates TLS on port 443. When using the default k3d configuration, this listener is exposed on host port **2496** (`443/tcp` inside the cluster → `127.0.0.1:2496` on the host, configurable via the k8s stack `port` variable).

Apply `terraform -chdir=stacks/k8s apply` before other stacks so the chosen domain and ingress port are published through `terraform_remote_state`. The command prompts once for `domain` (default `agyn.dev`) and `port` (default `2496`). Override non-interactively with flags such as `terraform -chdir=stacks/k8s apply -var='domain=example.dev' -var='port=8443'` or via environment variables `TF_VAR_domain` / `TF_VAR_port`.

Traffic is routed purely through Istio `VirtualService` objects—there are no Kubernetes `Ingress` resources in the platform stack. Ensure the following DNS entries resolve to `127.0.0.1` on your workstation (e.g. via `/etc/hosts`):

- `agyn.dev`
- `api.agyn.dev`
- `argocd.agyn.dev`
- `litellm.agyn.dev`
- `vault.agyn.dev`

Update the hostnames accordingly if you override the base domain.

Common HTTPS endpoints exposed through the gateway (accept the self-signed wildcard certificate locally):

- Platform UI: `https://agyn.dev:2496`
- Platform API: `https://api.agyn.dev:2496`
- Argo CD UI/API: `https://argocd.agyn.dev:2496`
- LiteLLM API: `https://litellm.agyn.dev:2496`
- Vault UI/API: `https://vault.agyn.dev:2496`

Verify routing after `terraform apply` with `curl -kI --resolve <host>:2496:127.0.0.1 https://<host>:2496/` (for example `curl -kI --resolve agyn.dev:2496:127.0.0.1 https://agyn.dev:2496/`).

## Quick apply (`apply.sh`)

The root script consolidates the stack applies so you only enter the domain and port once. It executes the stacks sequentially (`k8s` → `system` → `routing` → `platform`) and stops immediately on errors.

Interactive run (prompts for the defaults shown):

```
./apply.sh
```

Non-interactive run with custom values and auto-approve:

```
DOMAIN=example.dev PORT=8443 ./apply.sh -y
```

Override inputs by exporting `DOMAIN` / `PORT` environment variables or pass `-y` to skip interactive confirmations entirely (`apply.sh` adds `-input=false -auto-approve` to each Terraform apply when `-y` is set).

## LiteLLM defaults

LiteLLM is deployed with the following development defaults:

- UI credentials: `admin` / `admin`
- Master key: `sk-dev-master-1234`
- Salt key: `sk-dev-salt-1234`
- PostgreSQL password: `change-me`

## Vault defaults

Vault boots with a standalone auto-init sidecar that now guarantees a KV v2
secrets engine at the `secret/` mount. A sample development secret is written to
`secret/platform/example` (note `Provisioned by bootstrap_v2`, token
`dev-placeholder`) so the platform detects an available mount immediately. Set
`VAULT_SEED_SAMPLE_SECRET=false` or adjust `VAULT_SAMPLE_SECRET_PATH` on the
`vault-auto-init` container to customize this behaviour.

The platform stack now connects to Argo CD exclusively via `kubectl port-forward`. The `argocd` Terraform provider opens a tunnel directly to the in-cluster service in the `argocd` namespace, so no external DNS entry is required during bootstrap. Disable this behaviour only if you have a routable control-plane endpoint by setting `-var 'argocd_port_forward_enabled=false'` and providing a matching hostname/IP via `kubectl`'s current context.

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
