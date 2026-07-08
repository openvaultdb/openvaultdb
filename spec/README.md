# Specifications

> **Status: Draft — pending Fable 5 architecture and security review.**

Implementation-independent specifications for OpenVaultDB.

## Contents

### Foundation

| Path | Purpose |
|---|---|
| [vision.md](vision.md) | Project intent, principles, and review posture. |
| [glossary.md](glossary.md) | Shared vocabulary for vault, schema, permission, and storage concepts. |
| [open-questions.md](open-questions.md) | Cross-cutting unresolved questions. |
| [risky-assumptions.md](risky-assumptions.md) | Assumptions that could invalidate the architecture. |
| [decision-log.md](decision-log.md) | Current high-level decisions before formal ADRs. |

### Architecture and Implementation

| Path | Purpose |
|---|---|
| [architecture/](architecture/README.md) | High-level architecture, plugin model, reference implementation scope. |
| [api/](api/README.md) | Application and agent API model, endpoints, authentication. |
| [cli/](cli/README.md) | CLI behavior and command surface. |
| [deployment/](deployment/README.md) | Docker Compose and Kubernetes deployment guides. |

### Cloud and Open-Source Strategy

| Path | Purpose |
|---|---|
| [cloud/](cloud/README.md) | Hosted service at api.openvaultdb.com, architecture, pricing. |
| [open-source/](open-source/README.md) | Apache 2.0 strategy, self-hosting, third-party hosting. |
| [billing/](billing/README.md) | BillingProvider interface and pricing model. |

### Security and Trust

| Path | Purpose |
|---|---|
| [security/](security/README.md) | Trust, threat, permission, capability, AI-agent, and audit models. |

### Schema and Data

| Path | Purpose |
|---|---|
| [schema/](schema/README.md) | ModelSpec consumption, schema definition, versioning, and migration behavior. |

### Storage

| Path | Purpose |
|---|---|
| [storage/](storage/README.md) | Storage backends, GitHub provider, Firestore provider, provider trust. |

### Integrations

| Path | Purpose |
|---|---|
| [sneat-integration/](sneat-integration/README.md) | Sneat Space storage selection, provider discovery, migration flow. |

### Testing

| Path | Purpose |
|---|---|
| [testing/](testing/README.md) | Security, migration, and plugin test matrices. |

### MVP

| Path | Purpose |
|---|---|
| [mvp/](mvp/README.md) | Conservative local-first encrypted vault MVP. |

### Process

| Path | Purpose |
|---|---|
| [rfcs/](rfcs/README.md) | Proposal process for material changes. |
| [decisions/](decisions/README.md) | Architectural decision record index. |
| [features/](features/README.md) | SpecScore feature specifications. |
| [ideas/](ideas/README.md) | SpecScore pre-spec ideas. |

## Normative Guidance

- Specifications MUST distinguish decisions, assumptions, open questions, and requirements.
- Security-sensitive behavior MUST reference [security/threat-model.md](security/threat-model.md).
- Schema-changing behavior MUST reference [schema/modelspec-integration.md](schema/modelspec-integration.md) and [schema/migrations.md](schema/migrations.md).
- MVP implementation work SHOULD reference [mvp/local-first-encrypted-vault.md](mvp/local-first-encrypted-vault.md).

## Open Questions

- Which requirements should be promoted into executable conformance tests first?
- Which formal ADRs should replace the provisional [decision-log.md](decision-log.md)?
