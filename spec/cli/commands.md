# Commands

## Purpose

Propose the MVP command surface without committing to exact flags.

## Key Concepts

- Vault commands: create, lock, unlock, inspect, backup, restore.
- App commands: register, list, inspect, revoke.
- Grant commands: request, approve, deny, narrow, revoke.
- Schema commands: publish ModelSpec, inspect, diff, validate, migrate.
- Migration commands: plan, approve, run, status, resume, rollback.

## Normative Requirements

- Commands that mutate data, permissions, schemas, keys, or storage MUST require capabilities.
- Commands that execute migrations MUST require an approved migration plan.
- Commands that export data MUST record audit events and require export capability.
- Commands SHOULD provide `--json` output for inspection and automation.

## MVP Behavior

| Group | Examples |
|---|---|
| `vault` | `init`, `status`, `lock`, `unlock`, `backup`, `restore` |
| `app` | `register`, `list`, `inspect`, `revoke` |
| `grant` | `request`, `approve`, `deny`, `revoke`, `list` |
| `schema` | `publish`, `show`, `diff`, `validate` |
| `migration` | `plan`, `approve`, `run`, `status`, `resume`, `rollback` |
| `audit` | `tail`, `show`, `export`, `verify` |

## Risks

- Names may imply safety where none exists.
- Combining plan and run in one command can weaken review.
- Export commands can create new unprotected copies.

## Open Questions

- Should `migration run` refuse unapproved plans even for local user sessions?
- Which commands require passphrase or OS authentication re-entry?
- Should `audit export` support redaction profiles?

## Acceptance Criteria

- Command documentation maps each operation to required capabilities.
- Schema commands document that applications publish ModelSpec and the vault owns backend mapping.
- Migration status exposes progress, warnings, errors, and checkpoint state.
- Export and destructive commands are auditable.

## Related Specifications

- [openvaultdb-cli.md](openvaultdb-cli.md)
- [../security/capability-model.md](../security/capability-model.md)
- [../schema/migrations.md](../schema/migrations.md)
- [../security/audit-log.md](../security/audit-log.md)
