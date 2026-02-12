# bootstrap

## Quickstart

Prereqs: Docker with Compose v2 enabled.

```bash
git clone --recurse-submodules https://github.com/agynio/bootstrap.git
cd bootstrap/agyn
docker compose up -d
```

Open http://localhost:2496 in your browser.

> Note: `agyn/docker-compose.yaml` is the compose file, and the `graph` submodule is required.
