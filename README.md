# bootstrap

## Quickstart

Runs the prebuilt Platform Server and UI images via Docker Compose (not a development environment). For development workflows, see [agynio/platform](https://github.com/agynio/platform).

Prereqs: Docker with Compose v2 enabled and access to the host Docker socket (`/var/run/docker.sock`).

Copy `.env.example` to `.env` and change `DOCKER_RUNNER_SHARED_SECRET` to a long random string before starting the stack.

```bash
git clone --recurse-submodules https://github.com/agynio/bootstrap.git
cd bootstrap/agyn
docker compose up -d
```

Open http://localhost:2496 in your browser.

> Notes:
> - `agyn/docker-compose.yaml` is the compose file, and the `graph` submodule is required.
> - The stack now includes the `docker-runner` service, which brokers privileged Docker access for the platform-server. Ensure the host socket is available and the shared secret matches `DOCKER_RUNNER_SHARED_SECRET` in your `.env` file.
