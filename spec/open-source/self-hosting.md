# Self-Hosting Guide (Draft Specification)

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the self-hosting model: what it means to run an OpenVaultDB instance, what configuration is required, what responsibilities the operator assumes, and what the expected operator experience should be.

## Self-Hosting Use Cases

| Use Case | Operator | Notes |
|---|---|---|
| Personal vault | Individual developer | Single user; local or VPS |
| Team vault | Small team | Shared vault; multiple users |
| Enterprise deployment | IT department | Multi-tenant; custom IdP; compliance |
| Air-gapped deployment | Regulated industry | No external network; manual updates |
| Development / evaluation | Developer | Local Docker Compose |

## Quick Start (Draft)

### Docker Compose (Recommended for Evaluation)

```bash
git clone https://github.com/openvaultdb/openvaultdb
cd openvaultdb
docker compose up
```

A default SQLite-backed instance starts at `http://localhost:8080`.

Default configuration:
- Storage: local SQLite
- Identity: built-in username/password
- Billing: disabled
- Audit log: local file

> **Note**: The quick-start configuration is not suitable for production. It uses SQLite with no replication and stores credentials locally.

### CLI Start

```bash
ovdb server start --config ovdb.yaml
```

### Minimal `ovdb.yaml` (Draft)

```yaml
server:
  host: 0.0.0.0
  port: 8080
  base_url: http://localhost:8080

storage:
  provider: sqlite
  path: ./vault.db

identity:
  provider: builtin
  admin_email: admin@example.com

billing:
  provider: disabled

audit:
  provider: local
  path: ./audit.log
```

> **Open question**: Should `ovdb.yaml` be a SpecScore-validated schema? This would allow linting configuration files before deployment.

## Production Self-Hosting (Draft)

For production deployments, the following are recommended (not normative at this stage):

| Concern | Recommended Approach | Notes |
|---|---|---|
| Storage backend | PostgreSQL or Firestore | SQLite not recommended for multi-user |
| Identity | External OIDC provider (Google, Auth0, Okta) | Avoid builtin IdP in production |
| TLS | Terminate at reverse proxy (nginx, Caddy, Cloudflare) | Server does not terminate TLS in reference implementation |
| Secrets | Environment variables or secrets manager | Never hardcode in config file |
| Backup | Depends on storage backend | See [../storage/storage-backends.md](../storage/storage-backends.md) |
| Audit log | External export (Datadog, Splunk, CloudWatch) | Tamper-evidence TBD |

## Operator Responsibilities

When self-hosting, the operator assumes responsibility for:

1. **Security**: TLS certificates, credential rotation, network isolation.
2. **Availability**: uptime, backups, failover.
3. **Updates**: applying server security patches.
4. **Compliance**: regulatory requirements for data storage location, retention, and access.
5. **Encryption**: key management for vault encryption (OpenVaultDB provides tooling; operator configures it).
6. **Plugin security**: vetting third-party plugins before deployment.

> **Risk**: Many self-hosting users underestimate operational requirements. The project should provide clear documentation of the minimum viable production configuration.

## Configuration Reference (Draft Outline)

Configuration categories:

- `server`: host, port, base_url, TLS settings
- `storage`: provider selection, provider-specific config
- `identity`: provider selection, OIDC config, passkey settings
- `billing`: provider selection (disabled for self-hosting)
- `audit`: provider selection, retention policy
- `secrets`: provider for credential storage (env, Vault, AWS SSM, etc.)
- `notifications`: provider selection (email, webhook, etc.)
- `backup`: provider selection and schedule
- `migrations`: approval workflow settings

## Upgrade Path (Draft)

1. Stop server.
2. Backup database and audit log.
3. Replace server binary or pull new Docker image.
4. Run `ovdb server migrate` to apply database schema changes.
5. Verify with `ovdb server health`.
6. Restart server.

> **Risk**: Silent database schema incompatibilities between versions. Migration tooling must be tested against real data.

## Open Questions

1. What is the minimum hardware requirement for a single-user self-hosted instance?
2. Should `ovdb server migrate` be a separate command or automatic on startup?
3. How should operators handle vault encryption key rotation?
4. What is the recommended backup strategy for each storage backend?
5. How are plugin updates handled in self-hosted deployments?

## Risks

- Operators may skip TLS, leaving credentials in transit unprotected.
- Self-hosted instances may not receive security updates promptly.
- Plugin ecosystem: malicious third-party plugins can access all vault data.
- Key management errors can make vaults permanently inaccessible.

## Acceptance Criteria

- `docker compose up` produces a working local instance in under 2 minutes.
- Documentation clearly states what the quick-start configuration lacks for production.
- `ovdb server health` returns a structured response indicating all required plugins are configured.
- Self-hosted instances can import data exported from `api.openvaultdb.com`.

## Related Specifications

- [strategy.md](strategy.md)
- [third-party-hosting.md](third-party-hosting.md)
- [../deployment/docker-compose.md](../deployment/docker-compose.md)
- [../deployment/kubernetes.md](../deployment/kubernetes.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
- [../cli/commands.md](../cli/commands.md)
