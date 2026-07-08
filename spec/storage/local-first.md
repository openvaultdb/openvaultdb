# Local-First Storage

## Purpose

Define the conservative local-first posture for the MVP.

## Key Concepts

- Local authority: the local vault controls grants and schema state.
- Offline operation: core operations work without cloud services.
- Local encryption: vault data is encrypted before durable storage.
- Sync deferral: cloud synchronization is intentionally out of MVP.

## Normative Requirements

- The MVP MUST operate without a cloud account.
- The MVP MUST encrypt vault contents at rest.
- Local grant state MUST be authoritative for authorization decisions.
- Cloud synchronization MUST NOT be added until provider trust, conflict resolution, and rollback risks are specified.
- Local backups MUST document whether they include keys, encrypted data, audit logs, and checkpoints.

## MVP Behavior

Users create and manage a local encrypted vault using the CLI. Applications interact with the local vault authority after registration and grant approval.

## Risks

- Local-only storage can still be copied or deleted.
- OS-level backup and search tools may expose metadata.
- Device compromise remains outside the protection boundary.

## Open Questions

- Which OS keystore integrations are acceptable for MVP?
- Should vault files be portable by default?
- Should local network access be supported or banned initially?

## Acceptance Criteria

- A vault can be created, opened, locked, backed up, and inspected locally.
- No MVP operation requires cloud synchronization.
- Documentation clearly states local-first residual risks.

## Related Specifications

- [sqlite-backend.md](sqlite-backend.md)
- [provider-trust.md](provider-trust.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
