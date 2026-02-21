# bootstrap

## Quickstart

Runs the prebuilt Platform Server and UI images via Docker Compose (not a development environment). For development workflows, see [agynio/platform](https://github.com/agynio/platform).

Prereqs: Docker with Compose v2 enabled.

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

> Note: `agyn/docker-compose.yaml` is the compose file, and the `graph` submodule is required.
