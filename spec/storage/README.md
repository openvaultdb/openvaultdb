# Storage Specifications

## Purpose

Index OpenVaultDB storage specifications.

## Key Concepts

- Local-first storage is the MVP posture.
- Providers store encrypted vault bytes and are not trusted with plaintext.
- Backend choice affects security, auditability, migration, and recovery.

## Contents

| Path | Purpose |
|---|---|
| [storage-backends.md](storage-backends.md) | Backend abstraction and requirements. |
| [local-first.md](local-first.md) | Local-first behavior and constraints. |
| [git-backend.md](git-backend.md) | Git-backed storage risks and restrictions. |
| [sqlite-backend.md](sqlite-backend.md) | SQLite backend expectations for MVP. |
| [provider-trust.md](provider-trust.md) | Provider compromise and trust assumptions. |

## Normative Requirements

- Storage backends MUST preserve confidentiality, integrity, and migration safety requirements for their supported threat model.
- Provider support MUST NOT imply provider trust.

## MVP Behavior

The MVP uses local encrypted storage, likely backed by SQLite or an equivalent local durable store.

## Risks

- Backups can copy keys and encrypted data together.
- Filesystem metadata can leak vault existence or activity.
- Git history can retain sensitive material indefinitely.

## Open Questions

- Is SQLite the only MVP backend?
- Should file-level encrypted blob storage be considered before SQLite?

## Acceptance Criteria

- Each backend spec names trust assumptions, risks, and non-goals.
- Cloud sync is excluded until provider trust is reviewed.

## Related Specifications

- [../security/trust-model.md](../security/trust-model.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
