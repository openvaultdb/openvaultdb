# CLI Specifications

## Purpose

Index OpenVaultDB CLI specifications.

## Key Concepts

- CLI-first MVP: initial workflows are explicit and inspectable.
- Command safety: high-risk commands require review and confirmation.
- Machine-readable output: automation can inspect plans without bypassing approval.

## Contents

| Path | Purpose |
|---|---|
| [openvaultdb-cli.md](openvaultdb-cli.md) | CLI principles and workflow behavior. |
| [commands.md](commands.md) | Proposed command surface. |

## Normative Requirements

- The CLI MUST expose plans before executing migrations or high-risk operations.
- The CLI MUST support non-destructive inspection of grants, schemas, audit logs, and migration status.

## MVP Behavior

The MVP provides vault creation, registration, permission, schema, migration, audit, backup, and inspection commands.

## Risks

- Automation flags can bypass user approval if poorly designed.
- Verbose output can leak sensitive data.

## Open Questions

- Which commands require interactive mode only?
- What JSON output schema is needed for automation?

## Acceptance Criteria

- CLI commands map to capability checks.
- High-risk commands display risks and require explicit approval.

## Related Specifications

- [../security/capability-model.md](../security/capability-model.md)
- [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md)
