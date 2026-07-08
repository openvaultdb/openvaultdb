# Architecture Overview

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Provide a high-level architecture overview of OpenVaultDB: the key components, their responsibilities, and how they fit together. This document is the entry point for the architecture specification set.

## One-Sentence Summary

OpenVaultDB is a plugin-based, user-controlled data vault server with capability-scoped access, schema-driven storage, append-only audit, and explicit migration approval — deployable from laptop to cloud.

## Core Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Client Layer                                │
│   CLI (ovdb)   │   Go SDK   │   TypeScript SDK   │   REST API      │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────────┐
│                        API Server                                   │
│   Authentication  │  Authorization  │  Routing  │  Rate Limiting   │
└──────────┬───────────────┬──────────────────┬───────────────────────┘
           │               │                  │
┌──────────▼──────┐ ┌──────▼──────┐  ┌───────▼───────────────────────┐
│  Vault Service  │ │Schema Service│  │     Migration Service         │
│                 │ │             │  │                               │
│ account, vault, │ │ modelspec,  │  │ plan, approve, execute,       │
│ app, grant,     │ │ versioning, │  │ checkpoint, rollback          │
│ revoke, export  │ │ diff, index │  │                               │
└──────────┬──────┘ └──────┬──────┘  └───────┬───────────────────────┘
           │               │                  │
┌──────────▼───────────────▼──────────────────▼───────────────────────┐
│                       Plugin Layer                                  │
│                                                                     │
│  StorageProvider  │  IdentityProvider  │  BillingProvider          │
│  AuditProvider    │  BackupProvider    │  SecretsProvider          │
│  NotificationProvider  │  SearchProvider                           │
└──────────────────────────────────────────────────────────────────────┘
```

## Principal Model

OpenVaultDB distinguishes four principal types:

| Principal | Description | Authentication |
|---|---|---|
| User | Human owner of the vault | OIDC, Passkey, API key |
| Application | Registered software that accesses vault data | Client credentials, signed JWT |
| AI Agent | Automated agent acting on behalf of a user | Scoped delegated token |
| Service Account | Server-to-server identity | Client credentials |

> **Key rule**: Applications, AI agents, and service accounts are NOT trusted merely because a user installed them. Each principal requires explicit capability grants.

## Vault Model

A **vault** is the unit of user ownership. Each vault has:
- An owner (user principal)
- One or more storage backends
- A schema (versioned ModelSpec)
- A permission grant store
- An append-only audit log
- A migration history

Vaults are isolated: applications granted access to vault A cannot access vault B without a separate grant.

## Capability Model

Access is granted via **capabilities** — scoped, revocable grants that specify:
- Which principal is granted access
- Which collections and operations are permitted
- Expiry time (if any)
- Delegation constraints (can the grantee further delegate?)

See [../security/capability-model.md](../security/capability-model.md).

## Schema Model

Schemas are defined using ModelSpec. The Schema Service:
1. Ingests ModelSpec from an application.
2. Computes a diff against the current schema version.
3. Presents the diff to the user for approval.
4. Generates a migration plan if data changes are required.
5. Executes the migration after user approval.

See [../schema/schema-model.md](../schema/schema-model.md).

## Migration Model

Migrations are first-class operations:
- Always planned before execution.
- Always presented to the user for approval.
- Always checkpointed for resumability.
- Always audited.

See [../schema/migrations.md](../schema/migrations.md).

## Audit Model

All significant operations emit an audit event:
- Account and vault lifecycle
- Grant creation and revocation
- Schema changes and approvals
- Migration planning, approval, and execution
- Reads and writes above a configurable threshold
- Authentication events
- Plugin errors

Audit events are append-only. Tamper-evidence mechanism TBD.

See [../security/audit-log.md](../security/audit-log.md).

## Request Lifecycle (Read Example)

```
1. Application sends request with scoped access token.
2. Auth middleware validates token signature and expiry.
3. Authorization middleware checks: is this capability still granted? Not revoked?
4. Request routed to Vault Service.
5. Vault Service resolves storage backend for target collection.
6. StorageProvider reads record(s).
7. Response assembled and returned.
8. Audit event emitted (async, non-blocking).
```

> **Risk at step 3**: Stale permission cache. If revocation propagates with delay, an application may access data after its grant is revoked. See [../security/permissions-model.md](../security/permissions-model.md).

## Deployment Flexibility

The same binary is deployable as:
- Local single-user (SQLite, builtin auth, no billing)
- Team server (PostgreSQL, OIDC, disabled billing)
- Hosted cloud (`api.openvaultdb.com` plugin configuration)
- Air-gapped enterprise (custom plugins, no external network calls)

## Open Questions

1. Should the API server and plugin layer be the same process, or should plugins run in separate processes for isolation?
2. What is the authorization performance budget? (Revocation check frequency vs. cache TTL trade-off)
3. Should audit event emission be synchronous (slower, guaranteed) or asynchronous (faster, possible loss on crash)?
4. How should the server handle a StorageProvider that returns inconsistent results?

## Risks

- Plugin isolation: malicious or buggy plugins can access all vault data if run in-process.
- Revocation lag: cached permissions may authorize access after revocation.
- Schema service complexity: ModelSpec parsing and migration planning are high-risk code paths.
- Single vault model: if a user's vault is compromised, all their applications lose data access simultaneously.

## Related Specifications

- [plugin-model.md](plugin-model.md)
- [reference-implementation.md](reference-implementation.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../security/capability-model.md](../security/capability-model.md)
- [../schema/schema-model.md](../schema/schema-model.md)
- [../schema/migrations.md](../schema/migrations.md)
- [../api/api-model.md](../api/api-model.md)
