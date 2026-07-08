# Vision

## Purpose

Define the project intent for OpenVaultDB before implementation begins.

## Key Concepts

- User-controlled vault: the user owns the data model, permissions, migration approvals, and provider choice.
- ModelSpec consumption: applications publish ModelSpec and the vault maps it to the selected backend.
- Hostile application assumption: applications are not trusted merely because the user installed them.
- Specification-first workflow: architecture and security requirements are reviewed before production code.
- GitHub/InGitDB MVP: the first implementation stores vault data in a GitHub-backed InGitDB layout without OpenVaultDB-managed encryption.

## Normative Requirements

- OpenVaultDB MUST make user consent explicit for access, schema changes, destructive operations, and migrations.
- OpenVaultDB MUST consume ModelSpec directly for logical application schemas and MUST NOT require applications to author backend-specific schemas as the primary contract.
- OpenVaultDB MUST treat applications, AI agents, extensions, and storage providers as separate principals.
- OpenVaultDB MUST support auditability for permission grants, revocations, reads, writes, migrations, and key events.
- OpenVaultDB MUST NOT require a trusted cloud provider for the MVP.

## MVP Behavior

The MVP is a CLI-first GitHub/InGitDB-backed vault with explicit application registration, capability-based permissions, append-only audit logging, ModelSpec-based schema versioning, and reviewable migrations. It does not encrypt vault data.

## Risks

- A too-broad MVP could blur security boundaries before they are validated.
- A too-complex permission model could push users into unsafe approvals.
- GitHub/InGitDB storage can expose data through repository access, backups, Git history, logs, or installed integrations.

## Open Questions

- What is the minimum viable UI for non-expert migration approval?
- Which operations require mandatory human approval even when delegated to an AI agent?
- What minimum hoster/provider recovery behavior must be documented for MVP?

## Acceptance Criteria

- Public documentation explains what OpenVaultDB is and what it is not.
- MVP scope excludes OpenVaultDB-managed encryption until the trust model is reviewed.
- Security, schema, storage, CLI, API, testing, and Fable review briefs exist and cross-reference each other.

## Related Specifications

- [mvp/local-first-encrypted-vault.md](mvp/local-first-encrypted-vault.md)
- [security/trust-model.md](security/trust-model.md)
- [security/threat-model.md](security/threat-model.md)
- [schema/migrations.md](schema/migrations.md)
- [schema/modelspec-integration.md](schema/modelspec-integration.md)
