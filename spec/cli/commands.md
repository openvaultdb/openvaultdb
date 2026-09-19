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
| `cloud` | `login`, `status`, `logout` |

Local onboarding and configuration commands of the `ovdb` binary (Draft, 2026-09-17; named
user-facing commands and their local defaults public after founder approval on 2026-09-19).
They call a person's own authenticated local OVDB server; output, errors and exit codes follow
the machine contracts in [configuration parity](../features/configuration-parity/README.md).

Only the unfinished bare-command TUI remains behind `OVDB_PREVIEW=1`. Internal plumbing
(`ovdb server run`) MUST NOT appear in normal help.

| Group | Examples | Specification |
|---|---|---|
| (root) | `ovdb`, `status`, `open` | [first-run onboarding](../features/first-run-onboarding/README.md) |
| `server`, `config` | `start`, `stop`, `restart`, `status`; `open` (root); `get`, `set server.port` | [local server and web console](../features/local-server-and-web-console/README.md) |
| `engines`, `databases`, `token` | `engines`; `create`, `connect` (`--path` or `--manifest`), `remove`; `token create`, `list`, `revoke` against the local server | [database setup](../features/database-setup-and-providers/README.md) |
| context and data | `use`, `cd`, `pwd`, `list`, `get`, `set`, `add`, `delete` | [database context and navigation](../features/database-context-navigation/README.md) |
| `demo` | `install`, `open`, `status` | [TODO demo](../features/todo-demo/README.md) |
| `skills` | `list`, `install` | [AI agent skills](../features/ai-agent-skills/README.md) |
| `explore` | `datatug-cli`, `datatug-app` | [explore data hand-off](../features/explore-data-handoff/README.md) |
| `telemetry` | `status`, `enable`, `disable` | [telemetry consent](../features/telemetry-consent/README.md) |

The full CLI, TUI and web console capability matrix is in
[configuration parity](../features/configuration-parity/README.md).

`cloud login` uses browser-approved OAuth 2.0 device authorization and stores
the credential in the operating-system keyring by default. It MUST NOT silently
fall back to plaintext storage. `cloud status` validates the credential with the
cloud host rather than trusting local presence alone. `cloud logout` revokes
the remote token before removing the local credential.

## Risks

- Names may imply safety where none exists.
- Combining plan and run in one command can weaken review.
- Export commands can create new unprotected copies.

## Open Questions

- Should `migration run` refuse unapproved plans even for local user sessions?
- Which commands require hoster/provider authentication re-entry?
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
- [../features/configuration-parity/README.md](../features/configuration-parity/README.md)
