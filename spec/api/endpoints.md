# API Endpoints

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Draft the OpenVaultDB REST API endpoint surface. This document is structured in OpenAPI style but is not a formal OpenAPI spec yet. The goal is to define the endpoint taxonomy, request/response shapes, and key behaviors.

## Base URL

```
https://api.openvaultdb.com/v1
```

Self-hosted:
```
https://vault.example.com/v1
http://localhost:8080/v1
```

## Authentication

See [auth.md](auth.md) for authentication details.

All endpoints except `/health` and `/auth/*` require a valid Bearer token.

## Endpoint Index

### Health and Discovery

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Server health and plugin status |
| GET | `/v1/info` | Server version, capabilities, supported auth methods |
| GET | `/.well-known/openid-configuration` | OIDC discovery (if OIDC identity provider configured) |

#### `GET /health` Response (Draft)

```json
{
  "status": "healthy",
  "version": "0.1.0",
  "plugins": {
    "storage": { "provider": "github", "status": "healthy" },
    "identity": { "provider": "oidc", "status": "healthy" },
    "billing":  { "provider": "stripe", "status": "healthy" },
    "audit":    { "provider": "local",  "status": "healthy" }
  },
  "timestamp": "2026-01-01T00:00:00Z"
}
```

---

### Authentication

| Method | Path | Description |
|---|---|---|
| POST | `/v1/auth/token` | Exchange credentials for access token |
| POST | `/v1/auth/refresh` | Refresh access token |
| POST | `/v1/auth/revoke` | Revoke token |
| GET  | `/v1/auth/me` | Current principal info |
| POST | `/v1/auth/oidc/callback` | OIDC callback handler |
| POST | `/v1/auth/passkey/register` | Begin passkey registration |
| POST | `/v1/auth/passkey/authenticate` | Passkey authentication |

---

### Accounts

| Method | Path | Description |
|---|---|---|
| POST | `/v1/accounts` | Create account |
| GET  | `/v1/accounts/me` | Get current account |
| PATCH | `/v1/accounts/me` | Update account |
| DELETE | `/v1/accounts/me` | Delete account (initiates deletion workflow) |
| GET  | `/v1/accounts/me/subscription` | Get current subscription |
| POST | `/v1/accounts/me/subscription` | Create or update subscription |
| GET  | `/v1/accounts/me/usage` | Get usage summary |

---

### Vaults

| Method | Path | Description |
|---|---|---|
| POST | `/v1/vaults` | Create vault |
| GET  | `/v1/vaults` | List vaults (current account) |
| GET  | `/v1/vaults/{vaultID}` | Get vault details |
| PATCH | `/v1/vaults/{vaultID}` | Update vault metadata |
| DELETE | `/v1/vaults/{vaultID}` | Delete vault (initiates deletion workflow) |
| GET  | `/v1/vaults/{vaultID}/storage` | Get storage backend config |
| PUT  | `/v1/vaults/{vaultID}/storage` | Update storage backend |
| POST | `/v1/vaults/{vaultID}/export` | Initiate data export |
| GET  | `/v1/vaults/{vaultID}/export/{exportID}` | Get export status/download |

#### `POST /v1/vaults` Request (Draft)

```json
{
  "name": "my-vault",
  "storage": {
    "provider": "github",
    "config": {
      "owner": "myuser",
      "repo": "my-vault-data",
      "branch": "main"
    }
  }
}
```

---

### Applications

| Method | Path | Description |
|---|---|---|
| POST | `/v1/vaults/{vaultID}/apps` | Register application |
| GET  | `/v1/vaults/{vaultID}/apps` | List registered applications |
| GET  | `/v1/vaults/{vaultID}/apps/{appID}` | Get application details |
| PATCH | `/v1/vaults/{vaultID}/apps/{appID}` | Update application |
| DELETE | `/v1/vaults/{vaultID}/apps/{appID}` | Deregister application |
| POST | `/v1/vaults/{vaultID}/apps/{appID}/credentials` | Rotate credentials |

---

### Grants

| Method | Path | Description |
|---|---|---|
| POST | `/v1/vaults/{vaultID}/grants` | Create grant (user approval) |
| GET  | `/v1/vaults/{vaultID}/grants` | List active grants |
| GET  | `/v1/vaults/{vaultID}/grants/{grantID}` | Get grant details |
| DELETE | `/v1/vaults/{vaultID}/grants/{grantID}` | Revoke grant |
| POST | `/v1/vaults/{vaultID}/grants/request` | Application requests grant (creates pending grant) |
| GET  | `/v1/vaults/{vaultID}/grants/pending` | List pending grant requests (user reviews) |
| POST | `/v1/vaults/{vaultID}/grants/pending/{grantID}/approve` | User approves grant |
| POST | `/v1/vaults/{vaultID}/grants/pending/{grantID}/reject` | User rejects grant |

---

### Collections

| Method | Path | Description |
|---|---|---|
| POST | `/v1/vaults/{vaultID}/collections` | Create collection |
| GET  | `/v1/vaults/{vaultID}/collections` | List collections |
| GET  | `/v1/vaults/{vaultID}/collections/{collectionID}` | Get collection details |
| DELETE | `/v1/vaults/{vaultID}/collections/{collectionID}` | Delete collection |

---

### Records

| Method | Path | Description |
|---|---|---|
| POST | `/v1/vaults/{vaultID}/collections/{collectionID}/records` | Create record |
| GET  | `/v1/vaults/{vaultID}/collections/{collectionID}/records` | List/query records |
| GET  | `/v1/vaults/{vaultID}/collections/{collectionID}/records/{recordID}` | Get record |
| PUT  | `/v1/vaults/{vaultID}/collections/{collectionID}/records/{recordID}` | Replace record |
| PATCH | `/v1/vaults/{vaultID}/collections/{collectionID}/records/{recordID}` | Update record |
| DELETE | `/v1/vaults/{vaultID}/collections/{collectionID}/records/{recordID}` | Delete record |

#### Query Parameters for List/Query Records (Draft)

| Parameter | Type | Description |
|---|---|---|
| `filter` | string | Filter expression (syntax TBD) |
| `order_by` | string | Field name, optionally with `asc`/`desc` |
| `limit` | int | Max records returned (default: 50, max: 1000) |
| `cursor` | string | Pagination cursor |

> **Open question**: What query language? Simple field equality, or a richer expression? Rich expressions require backend-specific query translation.

---

### Schema

| Method | Path | Description |
|---|---|---|
| GET  | `/v1/vaults/{vaultID}/schema` | Get current schema |
| POST | `/v1/vaults/{vaultID}/schema/proposals` | Submit schema change proposal |
| GET  | `/v1/vaults/{vaultID}/schema/proposals` | List pending schema proposals |
| GET  | `/v1/vaults/{vaultID}/schema/proposals/{proposalID}` | Get proposal diff |
| POST | `/v1/vaults/{vaultID}/schema/proposals/{proposalID}/approve` | Approve proposal |
| POST | `/v1/vaults/{vaultID}/schema/proposals/{proposalID}/reject` | Reject proposal |
| GET  | `/v1/vaults/{vaultID}/schema/history` | Schema version history |

---

### Migrations

| Method | Path | Description |
|---|---|---|
| POST | `/v1/vaults/{vaultID}/migrations/plan` | Generate migration plan |
| GET  | `/v1/vaults/{vaultID}/migrations` | List migrations |
| GET  | `/v1/vaults/{vaultID}/migrations/{migrationID}` | Get migration details and progress |
| POST | `/v1/vaults/{vaultID}/migrations/{migrationID}/approve` | Approve migration |
| POST | `/v1/vaults/{vaultID}/migrations/{migrationID}/start` | Start approved migration |
| POST | `/v1/vaults/{vaultID}/migrations/{migrationID}/pause` | Pause running migration |
| POST | `/v1/vaults/{vaultID}/migrations/{migrationID}/resume` | Resume paused migration |
| POST | `/v1/vaults/{vaultID}/migrations/{migrationID}/rollback` | Rollback migration |
| GET  | `/v1/vaults/{vaultID}/migrations/{migrationID}/progress` | Migration progress (polling) |
| GET  | `/v1/vaults/{vaultID}/migrations/{migrationID}/progress/stream` | Migration progress (SSE) |

#### Migration Progress Response (Draft)

```json
{
  "migrationID": "mig_123",
  "status": "running",
  "phase": "transform",
  "progressPercent": 42,
  "processedRecords": 4200,
  "totalRecords": 10000,
  "estimatedRemainingSeconds": 180,
  "checkpointAt": 4000,
  "resumable": true,
  "warnings": [],
  "errors": [],
  "startedAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:03:00Z"
}
```

---

### Audit Log

| Method | Path | Description |
|---|---|---|
| GET  | `/v1/vaults/{vaultID}/audit` | Query audit events |
| POST | `/v1/vaults/{vaultID}/audit/export` | Export audit log |

#### Audit Query Parameters (Draft)

| Parameter | Type | Description |
|---|---|---|
| `principal` | string | Filter by principal ID |
| `event_type` | string | Filter by event type |
| `from` | ISO8601 | Start time |
| `to` | ISO8601 | End time |
| `limit` | int | Max events (default: 100, max: 1000) |
| `cursor` | string | Pagination cursor |

---

### Metrics

| Method | Path | Description |
|---|---|---|
| GET  | `/v1/vaults/{vaultID}/metrics` | Usage metrics for current account |
| GET  | `/metrics` | Prometheus-compatible metrics (operator use) |

---

### Billing Webhooks

| Method | Path | Description |
|---|---|---|
| POST | `/v1/webhooks/billing` | Billing provider webhook receiver |

---

## Error Response Format (Draft)

```json
{
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "The requested capability is not granted.",
    "details": {
      "required_capability": "collections:read",
      "vault_id": "vault_123",
      "app_id": "app_456"
    },
    "request_id": "req_789"
  }
}
```

## Versioning

- API version is embedded in the path: `/v1/`.
- Breaking changes require a new major version (`/v2/`).
- Non-breaking additions are backward-compatible within a major version.
- Deprecated endpoints are supported for at least 2 major versions.

## Open Questions

1. Should the API use REST or support GraphQL for richer queries?
2. What query language should be supported for record filtering?
3. Should migrations support SSE for real-time progress, or is polling sufficient?
4. How should the API handle partial vault outages (storage provider down)?
5. Should webhooks be supported for vault events (grant created, migration completed)?
6. What rate limiting headers should be returned?

## Related Specifications

- [auth.md](auth.md)
- [api-model.md](api-model.md)
- [../architecture/overview.md](../architecture/overview.md)
- [../schema/migrations.md](../schema/migrations.md)
- [../security/capability-model.md](../security/capability-model.md)
