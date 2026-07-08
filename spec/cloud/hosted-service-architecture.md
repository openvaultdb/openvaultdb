# Hosted Service Architecture

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the proposed internal architecture of the OpenVaultDB Cloud hosted service. This document covers the service topology, component responsibilities, data flows, and deployment model for `api.openvaultdb.com`.

## Architectural Principle

The hosted service is an instance of the Apache 2.0 open-source reference implementation with production plugin configuration. No proprietary server functionality. All commercial differentiation lives in operations, SLAs, and managed plugins — not the server binary.

## Component Overview (Proposed)

```
┌─────────────────────────────────────────────────────────────────┐
│                      api.openvaultdb.com                        │
│                                                                 │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────────────┐ │
│  │  API Gateway │   │  Auth Service│   │   Control Plane API  │ │
│  │  (TLS term.) │──▶│  (OIDC/JWT)  │──▶│   (vault, app, grant)│ │
│  └─────────────┘   └──────────────┘   └──────────────────────┘ │
│                                                 │                │
│                          ┌─────────────────────┼──────────────┐ │
│                          │                     │              │ │
│                    ┌─────▼──────┐  ┌───────────▼────┐  ┌─────▼─┐ │
│                    │ Migration  │  │  Schema Service │  │ Audit │ │
│                    │  Service   │  │                 │  │  Log  │ │
│                    └─────┬──────┘  └────────────────┘  └───────┘ │
│                          │                                        │
│              ┌───────────▼───────────────────────────┐           │
│              │         Storage Plugin Layer           │           │
│              │  ┌─────────────┐  ┌─────────────────┐ │           │
│              │  │  GitHub     │  │    Firestore     │ │           │
│              │  │  Provider   │  │    Provider      │ │           │
│              │  └─────────────┘  └─────────────────┘ │           │
│              └───────────────────────────────────────┘           │
│                                                                 │
│  Plugin Layer: BillingProvider | IdentityProvider | ...        │
└─────────────────────────────────────────────────────────────────┘
```

> **Note**: This topology is a draft proposal. Component boundaries, deployment units, and communication patterns require review.

## Control Plane vs. Data Plane

| Concern | Control Plane | Data Plane |
|---|---|---|
| Account and vault metadata | OpenVaultDB Cloud | n/a |
| Application registrations | OpenVaultDB Cloud | n/a |
| Permission grants | OpenVaultDB Cloud | n/a |
| Audit log (control events) | OpenVaultDB Cloud | n/a |
| Record data (BYOS) | Never | User's storage provider |
| Record data (Managed) | Never (proposed) | OpenVaultDB-operated Firestore |
| Schema definitions | OpenVaultDB Cloud | Replicated to storage |
| Migration state | OpenVaultDB Cloud | Checkpoints written to storage |

> **Open question**: For managed storage, OpenVaultDB operates the data plane. This creates a trust boundary that must be explicitly modeled. See [../security/trust-model.md](../security/trust-model.md).

## Key Services

### API Gateway

- TLS termination
- Rate limiting
- Request routing
- Authentication token validation (delegates to Auth Service)

> **Assumption**: API Gateway is commodity (e.g., Cloudflare, nginx, AWS ALB). The reference implementation should not assume a specific gateway.

### Auth Service

Responsibilities:
- OIDC federation (Google, GitHub, Apple, Microsoft)
- Passkey registration and authentication
- API key issuance and validation
- Service account token issuance
- AI agent credential issuance (scoped, short-lived)
- Token introspection endpoint

> **Risk**: Auth Service is a single point of failure for all vault access. Compromise allows impersonation of any user.

### Control Plane API

Responsibilities:
- Account lifecycle (CRUD)
- Vault lifecycle (CRUD)
- Application registration
- Capability grant management
- Schema change proposal intake and approval workflow
- Webhook management

### Migration Service

Responsibilities:
- Migration plan generation from schema diffs
- Migration approval workflow coordination
- Migration execution with progress tracking
- Checkpoint creation and resumability
- Rollback coordination

> **Risk**: Migration Service has read/write access to storage providers during migration. This is a high-privilege operation requiring additional audit coverage.

### Schema Service

Responsibilities:
- ModelSpec ingestion and validation
- Schema version management
- Schema diff computation
- Index management
- Permission migration planning

### Audit Log Service

Responsibilities:
- Append-only event ingestion
- Tamper-evidence (mechanism TBD)
- Retention policy enforcement
- Export API
- Query API (filtered by principal, time range, event type)

> **Open question**: What tamper-evidence mechanism is appropriate? Hash chaining? Merkle tree? Signed event batches? This has significant implementation cost implications.

## Deployment Model (Draft)

Proposed deployment targets for the reference implementation:

| Target | Use Case | Notes |
|---|---|---|
| Docker Compose | Local development, evaluation | Single-file deployment |
| Kubernetes | Production self-hosting | Helm chart TBD |
| Cloud Run / Fly.io | Managed hosting | Stateless container; external DB required |
| Binary | Lightweight self-hosting | Single binary, SQLite-backed |

For `api.openvaultdb.com`:
- Proposed platform: GCP (rationale: Firestore for managed storage tier)
- Proposed region strategy: TBD (single-region MVP; multi-region later)
- Proposed database: Firestore (control plane metadata) or PostgreSQL

> **Alternative**: Use PostgreSQL as the control plane database instead of Firestore. This would improve self-hosting symmetry (no GCP dependency) but requires more operational complexity.

## Scalability Assumptions (Draft)

- Control plane is stateless; horizontally scalable.
- Migration Service may be stateful during active migrations; checkpoints allow handoff.
- Audit Log Service is append-only; scalable with write-ahead buffering.
- Storage providers (GitHub, Firestore) impose their own rate limits; the server must handle backpressure.

## Security Boundaries

| Boundary | Enforcement Mechanism | Risk |
|---|---|---|
| User ↔ API Gateway | TLS, authentication token | Token theft |
| API Gateway ↔ Services | mTLS (proposed) or service mesh | Internal network attack |
| Services ↔ Storage Providers | Scoped credentials per vault | Credential exposure |
| Migration Service ↔ Storage | Temporary elevated credentials | Privilege escalation window |
| Audit Log ↔ Storage | Write-only credentials for ingest | Log tampering |

## Open Questions

1. Should the control plane database be Firestore or PostgreSQL? This affects self-hosting complexity.
2. What is the recommended deployment footprint for a small self-hosted instance?
3. How should the Migration Service handle concurrent migrations on the same vault?
4. What isolation is required between tenants in the managed Firestore tier?
5. How are secrets (BYOS credentials) stored? HSM, KMS, or application-level encryption?
6. What is the expected RPS at launch? Affects gateway and rate-limiting design.

## Risks

- Shared control plane database creates cross-tenant blast radius if misconfigured.
- Migration Service requires temporary elevated storage credentials; this window must be minimized.
- BYOS credential storage in the control plane is a high-value target.
- Single-region MVP creates availability risk; data loss risk on datacenter failure.

## Related Specifications

- [api-openvaultdb-com.md](api-openvaultdb-com.md)
- [../architecture/overview.md](../architecture/overview.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../security/threat-model.md](../security/threat-model.md)
- [../storage/github-provider.md](../storage/github-provider.md)
- [../storage/firestore-provider.md](../storage/firestore-provider.md)
- [../deployment/kubernetes.md](../deployment/kubernetes.md)
