# Git Backend

## Purpose

Define the Git-backed storage posture for the first OpenVaultDB MVP backend.

## Key Concepts

- InGitDB: the first OpenVaultDB storage target, using a Git repository layout generated from ModelSpec.
- Git history: immutable or replicated commit objects that can retain deleted content and support point-in-time restore.
- Secret retention: accidental persistence of data thought deleted.
- Merge conflict: divergent history requiring reconciliation.
- Public remote risk: accidental push of vault material to public repositories.

## Normative Requirements

- InGitDB/Git-backed storage SHOULD be the first MVP backend.
- A Git backend MUST NOT store plaintext vault data.
- A Git backend MUST address deleted-secret retention, history rewriting limits, remote exposure, merge conflicts, branch protection, and key rotation before production use.
- Git-backed migration MUST include provider-trust and audit-log implications.
- MVP Git-backed deployments SHOULD prohibit normal users from deleting the vault repository or rewriting/squashing commit history.
- Git history MAY be used for accidental recovery, but it MUST NOT be treated as a confidentiality control.

## MVP Behavior

The MVP targets an InGitDB repository layout first. SQLite is the second backend target and Firestore is the third. GitHub-backed storage is expected to use a private, user-owned repository with branch protection and application-level encryption.

## Risks

- Deleted secrets may remain in local or remote Git history.
- Public remotes can make mistakes irreversible.
- Merge conflict resolution can corrupt encrypted or structured state.
- Commit metadata can leak activity patterns.
- Git restore helps recover accidental writes or deletes, but it does not prevent data exposure if plaintext or weakly encrypted data is committed.

## Open Questions

- Can content-addressed encrypted chunks avoid meaningful history leaks?
- What branch protection settings are mandatory for MVP?
- Should encrypted schema metadata be required, or may ModelSpec files remain plaintext?

## Acceptance Criteria

- The MVP Git backend documents its repository layout, branch protection requirements, encryption expectations, and recovery workflow.
- Public push accidents are treated as a first-class threat.
- Conflict resolution is specified before implementation.

## Related Specifications

- [provider-trust.md](provider-trust.md)
- [storage-backends.md](storage-backends.md)
- [../security/threat-model.md](../security/threat-model.md)
- [../mvp/non-goals.md](../mvp/non-goals.md)
