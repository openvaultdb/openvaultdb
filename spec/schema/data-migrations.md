# Data Migrations

## Purpose

Define requirements for transforming stored records between schema versions.

## Key Concepts

- Transform: deterministic conversion from old record shape to new record shape.
- Batch: bounded group of records processed between checkpoints.
- Validation: checking transformed records against target schema.
- Quarantine: isolated state for records that fail migration.

## Normative Requirements

- Data migrations MUST be deterministic or explicitly mark non-deterministic inputs.
- Each transformed record MUST be validated against the target schema before commit.
- Data migrations MUST preserve record identity unless the plan states otherwise.
- Failed records MUST be reported with safe diagnostics and MUST NOT be silently dropped.
- Migrations touching encrypted fields MUST state whether plaintext is exposed in memory and how failures are handled.
- AI-generated transforms MUST be reviewable and MUST NOT execute without approval.

## MVP Behavior

The MVP supports batch data migrations with checkpointed progress, validation, failed-record reporting, and rollback where a backup exists.

## Risks

- Field rename mistakes can duplicate or erase data.
- Transform code can exfiltrate data if treated as trusted.
- Encryption changes can create unrecoverable records.
- Large datasets can make progress estimates inaccurate.

## Open Questions

- Should transform code run in a sandbox for MVP?
- Should failed records block the entire migration or enter quarantine?
- What diagnostics can be shown without leaking sensitive data?

## Acceptance Criteria

- A migration plan shows affected record count or states why it is unknown.
- Every failed record has a traceable error and recovery state.
- Re-running a migration after interruption does not duplicate side effects.

## Related Specifications

- [migrations.md](migrations.md)
- [schema-model.md](schema-model.md)
- [../security/capability-model.md](../security/capability-model.md)
- [../testing/migration-test-matrix.md](../testing/migration-test-matrix.md)
