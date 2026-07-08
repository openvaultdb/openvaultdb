# Docker Compose Deployment

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Specify the Docker Compose configuration for local development, evaluation, and lightweight self-hosted deployments.

## Quick Start

```bash
git clone https://github.com/openvaultdb/openvaultdb
cd openvaultdb
docker compose up
```

After startup:
- API: `http://localhost:8080`
- Health check: `http://localhost:8080/health`

## Proposed `docker-compose.yml` (Draft)

```yaml
# docker-compose.yml
# Draft — not production-ready. See warnings below.
version: "3.9"

services:
  ovdb:
    image: ghcr.io/openvaultdb/ovdb:latest
    ports:
      - "8080:8080"
    environment:
      OVDB_STORAGE_PROVIDER: sqlite
      OVDB_STORAGE_SQLITE_PATH: /data/vault.db
      OVDB_IDENTITY_PROVIDER: builtin
      OVDB_IDENTITY_ADMIN_EMAIL: admin@localhost
      OVDB_BILLING_PROVIDER: disabled
      OVDB_AUDIT_PROVIDER: local
      OVDB_AUDIT_LOCAL_PATH: /data/audit.log
    volumes:
      - ovdb_data:/data
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  ovdb_data:
```

> **⚠️ This configuration is for development and evaluation only. It does not use TLS, and uses builtin authentication. Do not use in production without additional hardening.**

## Configuration via Environment Variables

All server configuration can be provided via environment variables using the `OVDB_` prefix:

| Environment Variable | Default | Description |
|---|---|---|
| `OVDB_STORAGE_PROVIDER` | `sqlite` | Storage backend: `sqlite`, `github`, `firestore` |
| `OVDB_STORAGE_SQLITE_PATH` | `./vault.db` | Path for SQLite database |
| `OVDB_IDENTITY_PROVIDER` | `builtin` | Identity: `builtin`, `oidc` |
| `OVDB_IDENTITY_ADMIN_EMAIL` | (required) | Admin account email for builtin |
| `OVDB_BILLING_PROVIDER` | `disabled` | Billing: `disabled`, `stripe` |
| `OVDB_AUDIT_PROVIDER` | `local` | Audit: `local`, `stdout` |
| `OVDB_SERVER_HOST` | `0.0.0.0` | Server bind address |
| `OVDB_SERVER_PORT` | `8080` | Server port |
| `OVDB_SERVER_BASE_URL` | (required for OIDC) | External base URL |

## Multi-Service Docker Compose (GitHub Storage)

For evaluation with GitHub storage:

```yaml
# docker-compose.github.yml
version: "3.9"

services:
  ovdb:
    image: ghcr.io/openvaultdb/ovdb:latest
    ports:
      - "8080:8080"
    environment:
      OVDB_STORAGE_PROVIDER: github
      OVDB_STORAGE_GITHUB_OWNER: ${GITHUB_OWNER}
      OVDB_STORAGE_GITHUB_REPO: ${GITHUB_REPO}
      OVDB_STORAGE_GITHUB_BRANCH: main
      OVDB_STORAGE_GITHUB_TOKEN: ${GITHUB_TOKEN}
      OVDB_IDENTITY_PROVIDER: oidc
      OVDB_IDENTITY_OIDC_ISSUER: https://accounts.google.com
      OVDB_IDENTITY_OIDC_CLIENT_ID: ${GOOGLE_CLIENT_ID}
      OVDB_IDENTITY_OIDC_CLIENT_SECRET: ${GOOGLE_CLIENT_SECRET}
      OVDB_SERVER_BASE_URL: http://localhost:8080
      OVDB_BILLING_PROVIDER: disabled
      OVDB_AUDIT_PROVIDER: local
      OVDB_AUDIT_LOCAL_PATH: /data/audit.log
    volumes:
      - ovdb_data:/data
    env_file:
      - .env

volumes:
  ovdb_data:
```

> **Note**: GitHub token should never be hardcoded. Use `.env` file or secrets manager.

## Developer Workflow

```bash
# Start server
docker compose up -d

# Check health
curl http://localhost:8080/health

# Create first vault (using CLI)
ovdb --server http://localhost:8080 vault create --name my-vault

# Register an application
ovdb --server http://localhost:8080 app register --vault my-vault --name my-app

# Stop server
docker compose down

# View logs
docker compose logs -f ovdb
```

## Production Hardening Notes

The Docker Compose quick-start is not production-ready. For production:

1. Use a reverse proxy (Caddy, nginx) for TLS termination.
2. Replace builtin identity with OIDC.
3. Use a proper secrets manager instead of environment variables.
4. Add a persistent volume with appropriate backup strategy.
5. Configure audit log export to an external system.
6. Enable rate limiting at the reverse proxy.

See [kubernetes.md](kubernetes.md) for production deployment.

## Open Questions

1. Should the default Docker Compose include a Caddy reverse proxy for automatic TLS?
2. Should the server auto-generate a self-signed certificate for HTTPS in development mode?
3. Should there be a `docker-compose.override.yml` convention for local customization?
4. What is the recommended approach for managing secrets in Docker Compose?

## Acceptance Criteria

- `docker compose up` starts a working instance within 60 seconds.
- `curl http://localhost:8080/health` returns `{"status":"healthy"}`.
- The quick-start README displays a clear "not production-ready" warning.
- Environment variable documentation covers all required and optional variables.

## Related Specifications

- [kubernetes.md](kubernetes.md)
- [../open-source/self-hosting.md](../open-source/self-hosting.md)
- [../architecture/reference-implementation.md](../architecture/reference-implementation.md)
- [../cli/commands.md](../cli/commands.md)
