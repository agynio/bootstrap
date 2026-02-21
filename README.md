# bootstrap

## Quickstart

Runs the prebuilt Platform Server and UI images via Docker Compose (not a development environment). For development workflows, see [agynio/platform](https://github.com/agynio/platform).

Prereqs: Docker with Compose v2 enabled and access to the host Docker socket (`/var/run/docker.sock`).

From the repo root, copy `agyn/.env.example` to `agyn/.env` and set `DOCKER_RUNNER_SHARED_SECRET` if you need a custom secret. For local runs the stack defaults to `change-me`, but shared/team environments should override it:

```bash
cp agyn/.env.example agyn/.env
DOCKER_RUNNER_SHARED_SECRET=$(openssl rand -hex 32)
```

```bash
git clone --recurse-submodules https://github.com/agynio/bootstrap.git
cd bootstrap/agyn
docker compose up -d
```

Open http://localhost:2496 in your browser.

> Notes:
> - `agyn/docker-compose.yaml` is the compose file, and the `graph` submodule is required.
> - The stack now includes the `docker-runner` service, which brokers privileged Docker access for the platform-server. Ensure the host socket is available. The default shared secret is `change-me`; override `DOCKER_RUNNER_SHARED_SECRET` in `agyn/.env` for shared deployments.
