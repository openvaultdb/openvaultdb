# Schema Specifications

## Purpose

Index OpenVaultDB schema and migration specifications.

## Key Concepts

- Applications publish ModelSpec JSON as the logical application schema.
- OpenVaultDB loads current and target ModelSpec for validation, migration planning, backend mapping, GraphQL generation, DTQL typing metadata, DALGO metadata, and backend generators.
- Permissions, audit policy, encryption, and user approvals remain OpenVaultDB concerns, not ModelSpec concerns.
- Migrations are plans, not hidden side effects.
- Data, permission, index, encryption, and storage format changes are auditable.

## Contents

| Path | Purpose |
|---|---|
| [modelspec-integration.md](modelspec-integration.md) | How OpenVaultDB consumes ModelSpec directly. |
| [schema-model.md](schema-model.md) | Collections, records, fields, constraints, indexes, and labels. |
| [versioning.md](versioning.md) | Schema version identity and compatibility. |
| [migrations.md](migrations.md) | Migration planning, approval, execution, rollback, and resume. |
| [data-migrations.md](data-migrations.md) | Record transformation requirements. |
| [user-visible-migration-flow.md](user-visible-migration-flow.md) | User-facing approval and progress behavior. |

## Normative Requirements

- Schema changes MUST be explicit and reviewable.
- OpenVaultDB MUST treat ModelSpec JSON as the first MVP ingestion format for application data models.
- OpenVaultDB MUST NOT make SpecScore a runtime dependency merely because SpecScore can validate ModelSpec.
- Migrations MUST be permission-aware, checkpointed or idempotent, and auditable.
- Destructive changes MUST require user approval.

## MVP Behavior

The MVP supports versioned ModelSpec schemas and explicit migrations through the CLI.

## Risks

- Schema drift can break applications or permissions.
- Interrupted migrations can corrupt data.
- AI-triggered migrations can hide risky changes.

## Open Questions

- Which migration classes can be reversible by default?

## Acceptance Criteria

- Each migration plan names requester, affected resources, risk, permissions, backup, rollback, and resume behavior.
- Progress reporting exposes phase, counts, warnings, errors, and checkpoint status.

## Related Specifications

- [../security/permissions-model.md](../security/permissions-model.md)
- [../testing/migration-test-matrix.md](../testing/migration-test-matrix.md)
