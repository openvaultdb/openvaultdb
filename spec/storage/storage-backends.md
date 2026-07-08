# Storage Backends

## Purpose

Define how OpenVaultDB talks to durable storage without making storage providers trusted.

## Key Concepts

- Backend adapter: implementation-specific persistence layer.
- ModelSpec projection: mapping from a logical application model to backend-specific structures.
- Vault storage format: encrypted records, schemas, grants, audit entries, and checkpoints.
- Integrity metadata: information used to detect corruption, replay, or tampering.
- Backend migration: movement from one storage backend to another.

## Normative Requirements

- Backends MUST NOT receive plaintext record data unless explicitly marked trusted and out of MVP.
- Backends MUST consume vault-approved projections from ModelSpec rather than application-authored backend schemas as the primary contract.
- Backends MUST support atomic or recoverable writes for vault metadata, audit events, and migration checkpoints.
- Backend migrations MUST use the migration workflow.
- Storage formats MUST include version metadata.
- Implementations SHOULD detect corruption and unexpected rollback where feasible.

## MVP Behavior

The MVP uses one local backend with encrypted content, durable metadata, recoverable writes, and explicit backup behavior.

## Risks

- Backend APIs can make partial writes appear successful.
- Provider rollback can resurrect revoked grants or old data.
- Format changes can strand old vaults without migration tooling.

## Open Questions

- What integrity mechanism is required for rollback detection?
- Should backup creation be part of the backend contract or migration layer?

## Acceptance Criteria

- A backend can explain its atomicity and recovery behavior.
- Backend migration plans list source, target, risk, backup, rollback, and verification steps.
- Provider failure does not silently corrupt grant state.

## Related Specifications

- [local-first.md](local-first.md)
- [provider-trust.md](provider-trust.md)
- [../schema/migrations.md](../schema/migrations.md)
- [../schema/modelspec-integration.md](../schema/modelspec-integration.md)
- [../security/audit-log.md](../security/audit-log.md)
