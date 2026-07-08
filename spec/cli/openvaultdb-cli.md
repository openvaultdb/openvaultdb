# OpenVaultDB CLI

## Purpose

Define CLI design principles for the MVP.

## Key Concepts

- Inspect before act: commands should show proposed effects before mutation.
- Explicit confirmation: high-risk operations require clear user approval.
- Audit correlation: commands receive or emit IDs that connect to audit events.
- Automation mode: machine-readable output without weakening approval semantics.

## Normative Requirements

- Mutating commands MUST check capabilities before execution.
- High-risk commands MUST support a dry-run or plan mode.
- Destructive commands MUST name affected collections and data classes.
- Commands MUST avoid printing secrets by default.
- Automation flags MUST NOT bypass approval for operations that require human approval.

## MVP Behavior

The MVP CLI is the primary interface for vault creation, application registration, grants, schemas, migrations, audit inspection, and backup/restore.

## Risks

- Environment variables and shell history can leak secrets.
- Scripting interfaces can accidentally normalize unsafe approvals.
- Human-readable prompts can diverge from machine-readable plans.

## Open Questions

- Should the CLI require TTY for high-risk approvals?
- What command output must be stable before MVP release?
- How should secrets be supplied safely in CI-like environments?

## Acceptance Criteria

- Every high-risk command has a visible plan before execution.
- Commands produce audit correlation IDs.
- JSON output represents the same facts shown to humans.

## Related Specifications

- [commands.md](commands.md)
- [../security/audit-log.md](../security/audit-log.md)
- [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
