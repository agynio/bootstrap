# bootstrap_v2

Terraform stacks for local Kubernetes development using k3d, with decoupled system and app layers.

Stacks (planned):
- k8s: local k3d cluster (this repository includes the initial stack)
- system: Istio, Argo CD, and other dependencies (future)
- apps: our services deployed via Argo CD Application CRs (future)

All stacks use local directory backend state per stack.

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
