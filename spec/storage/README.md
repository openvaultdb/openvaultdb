# Storage Specifications

## Purpose

Index OpenVaultDB storage specifications.

## Key Concepts

- InGitDB/Git-backed storage is the first MVP backend target.
- Providers store vault data and metadata; the MVP does not encrypt vault data.
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
- The initial backend order SHOULD be InGitDB/GitHub first, SQLite second, and Firestore third.

## MVP Behavior

The MVP uses an InGitDB/GitHub-backed vault first, with Git history as a recovery/audit aid. SQLite is the next backend target and Firestore follows after provider-trust review.

## Risks

- Backups and Git history can retain sensitive data indefinitely.
- Filesystem metadata can leak vault existence or activity.
- Git history can retain sensitive material indefinitely.

## Open Questions

- Which InGitDB layout details remain implementation-specific after ADR-0002?
- Which SQLite capabilities are required before it becomes the second backend?

## Acceptance Criteria

- Each backend spec names trust assumptions, risks, and non-goals.
- Cloud sync is excluded until provider trust is reviewed.

## Related Specifications

- [../security/trust-model.md](../security/trust-model.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
