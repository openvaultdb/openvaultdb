# Local-First Storage

## Purpose

Define the conservative local-first posture for the MVP.

## Key Concepts

- Local authority: the vault runtime controls grants and schema state, even when durable storage is a user-owned GitHub repository.
- Offline operation: local cached operations MAY work without cloud services, but the first GitHub-backed MVP may require network access for durable writes.
- Local encryption: vault data is encrypted before durable storage.
- Git-backed storage: the first MVP backend persists vault state to an InGitDB/GitHub repository.

## Normative Requirements

- The MVP SHOULD keep vault authority separate from the storage provider.
- The MVP MUST encrypt vault contents at rest.
- Local grant state MUST be authoritative for authorization decisions.
- GitHub-backed storage MUST be treated as provider-backed durable storage, not as a trusted database.
- Local backups MUST document whether they include keys, encrypted data, audit logs, and checkpoints.

## MVP Behavior

Users create and manage an encrypted vault using the CLI. The first backend stores vault state in an InGitDB/GitHub repository; SQLite follows as a local backend. Applications interact with the vault authority after registration and grant approval.

## Risks

- GitHub-backed storage introduces repository visibility, token, API-limit, and history-retention risks.
- OS-level backup and search tools may expose metadata.
- Device compromise remains outside the protection boundary.

## Open Questions

- Which local cache guarantees are required for GitHub-backed MVP operation?
- Which OS keystore integrations should follow the passphrase MVP?
- Should GitHub repositories be private-only for all vaults?

## Acceptance Criteria

- A vault can be created, opened, locked, backed up, restored from Git history, and inspected through the CLI.
- GitHub-backed storage requirements are documented separately from local authority requirements.
- Documentation clearly states provider-backed residual risks.

## Related Specifications

- [git-backend.md](git-backend.md)
- [sqlite-backend.md](sqlite-backend.md)
- [provider-trust.md](provider-trust.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
