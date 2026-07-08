# Local-First Encrypted Vault

## Purpose

Define the conservative MVP target.

## Key Concepts

- Local encrypted vault: encrypted data and metadata stored on the user device.
- Explicit registration: apps identify themselves before requesting access.
- Capability grants: least-privilege permissions approved by the user.
- Audit-first behavior: security-relevant actions are recorded.

## Normative Requirements

- The MVP MUST support creating, opening, locking, backing up, and inspecting a local encrypted vault.
- The MVP MUST require explicit application registration.
- The MVP MUST use capability-based permissions.
- The MVP MUST record append-only audit events for grants, revocations, reads where configured, writes, migrations, exports, key events, and denials.
- The MVP MUST support explicit schema versions and migration plans.
- The MVP MUST NOT include cloud synchronization.
- The MVP MUST NOT grant implicit AI write access.

## MVP Behavior

Users manage the vault through CLI commands. Applications request grants. Migrations are planned and approved before execution. The vault remains useful offline.

## Risks

- Local malware and total device compromise remain out of scope.
- A CLI-only MVP may be difficult for non-technical users to evaluate.
- Key loss can permanently lose data unless recovery is added with clear tradeoffs.

## Open Questions

- What key recovery mode, if any, is acceptable for MVP?
- Should read events be audited by default for all collections?
- Is SQLite the MVP storage backend?

## Acceptance Criteria

- A user can create a vault, register an app, approve a narrow grant, write data, inspect audit events, and run a safe migration locally.
- A confused AI agent cannot write or migrate without explicit delegation and approval.
- A cloud provider is not required for any MVP operation.

## Related Specifications

- [non-goals.md](non-goals.md)
- [roadmap.md](roadmap.md)
- [../storage/local-first.md](../storage/local-first.md)
- [../security/permissions-model.md](../security/permissions-model.md)
