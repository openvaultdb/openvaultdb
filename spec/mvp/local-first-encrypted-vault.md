# GitHub/InGitDB MVP Vault

## Purpose

Define the conservative MVP target.

## Key Concepts

- InGitDB-backed vault: data and metadata stored in a Git repository layout generated from ModelSpec.
- Explicit registration: apps identify themselves before requesting access.
- Capability grants: least-privilege permissions approved by the user.
- Audit-first behavior: security-relevant actions are recorded.

## Normative Requirements

- The MVP MUST support creating, opening, backing up, restoring, and inspecting a vault.
- The MVP MUST NOT encrypt vault data.
- The MVP MUST treat authentication and access recovery as implementation details of the hoster or provider.
- The MVP SHOULD target InGitDB/GitHub-backed storage first, SQLite second, and Firestore third.
- The MVP MUST require explicit application registration.
- The MVP MUST use capability-based permissions.
- The MVP MUST record append-only audit events for grants, revocations, reads where configured, writes, migrations, exports, key events, and denials.
- The MVP MUST support explicit schema versions and migration plans.
- The MVP MUST state that GitHub, hosters, repository administrators, and provider operators may access vault data unless a future encryption mode is added.
- The MVP MUST distinguish the principal responsible for an action when that information is available, but the same API may be called by websites, applications, or AI agents.

## MVP Behavior

Users manage the vault through CLI commands. Applications request grants. Migrations are planned and approved before execution. GitHub-backed InGitDB storage is the first implementation target; restore from Git history is part of the operational recovery story.

## Risks

- Local malware and total device compromise remain out of scope.
- A CLI-only MVP may be difficult for non-technical users to evaluate.
- Hoster/provider recovery can become an account-takeover path if implemented poorly.
- Git history can restore accidental data changes, but it can also retain deleted secrets and metadata.
- Repository access exposes vault data in the MVP.

## Open Questions

- Should read events be audited by default for all collections?
- What exact InGitDB layout is required before implementation?
- What minimum hoster/provider recovery behavior must be documented?

## Acceptance Criteria

- A user can create a GitHub-backed vault, register an app, approve a grant, write data, inspect audit events, and run a safe migration.
- A confused AI agent cannot exceed the capabilities granted to the principal it uses.
- Accidental data changes can be restored from Git history when repository history has not been rewritten.
- The README and specs clearly state that MVP vault data is not encrypted by OpenVaultDB.

## Related Specifications

- [non-goals.md](non-goals.md)
- [roadmap.md](roadmap.md)
- [../storage/git-backend.md](../storage/git-backend.md)
- [../storage/local-first.md](../storage/local-first.md)
- [../security/permissions-model.md](../security/permissions-model.md)
