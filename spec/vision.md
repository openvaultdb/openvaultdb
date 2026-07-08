# Vision

## Purpose

Define the project intent for OpenVaultDB before implementation begins.

## Key Concepts

- User-controlled vault: the user owns the data, keys, permissions, and migration approvals.
- Hostile application assumption: applications are not trusted merely because the user installed them.
- Specification-first workflow: architecture and security requirements are reviewed before production code.
- Local-first MVP: the first implementation stores an encrypted vault locally and avoids cloud sync.

## Normative Requirements

- OpenVaultDB MUST make user consent explicit for access, schema changes, destructive operations, and migrations.
- OpenVaultDB MUST treat applications, AI agents, extensions, and storage providers as separate principals.
- OpenVaultDB MUST support auditability for permission grants, revocations, reads, writes, migrations, and key events.
- OpenVaultDB MUST NOT require a trusted cloud provider for the MVP.

## MVP Behavior

The MVP is a CLI-first encrypted local vault with explicit application registration, capability-based permissions, append-only audit logging, schema versioning, and reviewable migrations.

## Risks

- A too-broad MVP could blur security boundaries before they are validated.
- A too-complex permission model could push users into unsafe approvals.
- Local-first storage can still leak data through backups, Git history, logs, or filesystem indexing.

## Open Questions

- What is the minimum viable UI for non-expert migration approval?
- Which operations require mandatory human approval even when delegated to an AI agent?
- How much recovery complexity is acceptable in the MVP?

## Acceptance Criteria

- Public documentation explains what OpenVaultDB is and what it is not.
- MVP scope excludes cloud sync until the trust model is reviewed.
- Security, schema, storage, CLI, API, testing, and Fable review briefs exist and cross-reference each other.

## Related Specifications

- [mvp/local-first-encrypted-vault.md](mvp/local-first-encrypted-vault.md)
- [security/trust-model.md](security/trust-model.md)
- [security/threat-model.md](security/threat-model.md)
- [schema/migrations.md](schema/migrations.md)
