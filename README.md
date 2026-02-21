# bootstrap

## Quickstart

Runs the prebuilt Platform Server and UI images via Docker Compose (not a development environment). For development workflows, see [agynio/platform](https://github.com/agynio/platform).

Prereqs: Docker with Compose v2 enabled and access to the host Docker socket (`/var/run/docker.sock`).

For local development you can `cd agyn && docker compose up -d` without creating an env file; the stack defaults `DOCKER_RUNNER_SHARED_SECRET` to `change-me` so it just works out of the box.

To override the secret (recommended for team or shared environments), copy `agyn/.env.example` to `agyn/.env` and set a long random value:

```bash
cp agyn/.env.example agyn/.env
echo "DOCKER_RUNNER_SHARED_SECRET=$(openssl rand -hex 32)" >> agyn/.env
```

# Quick start (default: solo agent)
```bash
git clone --recurse-submodules https://github.com/agynio/bootstrap.git
cd bootstrap/agyn
docker compose up -d
```

# Reset graph to Team
```
# switch graph template
cd bootstrap/graph
git fetch origin
git checkout main
git reset --hard origin/example/team

# restart services
cd ../agyn
docker compose up -d --force-recreate
```

# Reset graph to Solo Agent
```
# switch graph template
cd bootstrap/graph
git fetch origin
git checkout main
git reset --hard origin/example/solo-agent

# restart services
cd ../agyn
docker compose up -d --force-recreate
```

Open http://localhost:2496 in your browser.

> Notes:
> - `agyn/docker-compose.yaml` is the compose file, and the `graph` submodule is required.
> - The stack now includes the `docker-runner` service, which brokers privileged Docker access for the platform-server. Ensure the host socket is available. The default shared secret is `change-me`; override `DOCKER_RUNNER_SHARED_SECRET` in `agyn/.env` for shared deployments.

## Docker registry mirror

Bootstrap now ships a pull-through Docker registry cache (`registry-mirror` service) backed by `registry:2` in proxy mode. The service stays on the internal `agents_stack` network by default and is only used when the host Docker daemon points at it.

1. **Opt-in loopback publish (optional):**
   ```bash
   cp agyn/docker-compose.override.yaml.example agyn/docker-compose.override.yaml
   cd agyn
   docker compose up -d registry-mirror
   ```
   This publishes `127.0.0.1:5000->5000` while leaving other services unchanged. Remove the override to return to internal-only operation.

2. **Configure the host Docker daemon (`/etc/docker/daemon.json`):**
   ```json
   {
     "registry-mirrors": ["http://127.0.0.1:5000"]
   }
   ```
   Restart Docker afterwards (e.g. `sudo systemctl restart docker`). This is required because bootstrap services reuse the host Docker socket.

3. **Containerd note:** if you run containerd directly, add the mirror endpoint to `/etc/containerd/config.toml` and restart containerd:
   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
     endpoint = ["http://127.0.0.1:5000"]
   ```

4. **Validate the mirror:**
   - `docker compose ps registry-mirror` should show `healthy` once the service starts.
   - `curl -fsSL http://127.0.0.1:5000/v2/` returns `{}`.
   - Pull an image twice (e.g. `docker pull alpine:3.19` twice) and observe `docker compose logs -f registry-mirror` showing cache hits on the second run.

5. **Rollback:** stop the service (`docker compose stop registry-mirror && docker compose rm -f registry-mirror`), remove the loopback override, delete the mirror entry from `daemon.json`/containerd config, and restart Docker/containerd. Existing pulls will then bypass the cache again.

> The mirror only accelerates pulls when the host daemon is configured as above. Containers inside the stack do not access it directly otherwise.
