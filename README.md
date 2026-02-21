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

```bash
git clone --recurse-submodules https://github.com/agynio/bootstrap.git
cd bootstrap/agyn
docker compose up -d
```

Open http://localhost:2496 in your browser.

> Notes:
> - `agyn/docker-compose.yaml` is the compose file, and the `graph` submodule is required.
> - The stack now includes the `docker-runner` service, which brokers privileged Docker access for the platform-server. Ensure the host socket is available. The default shared secret is `change-me`; override `DOCKER_RUNNER_SHARED_SECRET` in `agyn/.env` for shared deployments.
