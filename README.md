# bootstrap

## Quickstart

Runs the prebuilt Platform Server and UI images via Docker Compose (not a development environment). For development workflows, see [agynio/platform](https://github.com/agynio/platform).

Prereqs: Docker with Compose v2 enabled.

```bash
git clone --recurse-submodules https://github.com/agynio/bootstrap.git
cd bootstrap/agyn
docker compose up -d
```

Open http://localhost:2496 in your browser.

> Note: `agyn/docker-compose.yaml` is the compose file, and the `graph` submodule is required.
