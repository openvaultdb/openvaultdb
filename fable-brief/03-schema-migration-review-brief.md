# Fable 5 Brief: Schema And Migration Review

## Current Proposal

Schemas are explicit and versioned. Migrations are reviewable plans covering schema, data, permissions, indexes, storage format, encryption, and key rotation. MVP migrations block application writes, fail fast on failed records, are checkpointed or idempotent, show progress, and use backup settings plus Git history restore where applicable.

## Key Risks

- Interrupted migrations can corrupt data or permission state.
- Destructive changes and field renames can cause silent data loss.
- Encryption and key rotation may be non-reversible.
- AI-triggered migrations may understate risk.
- Backend migrations can introduce provider-trust issues.

## Unresolved Questions

- Should all writes be blocked during migration?
- Which backup settings are mandatory before destructive migrations?
- What transform sandboxing is required?
- When should quarantine be added after the fail-fast MVP?

## Expected Fable Review

Review whether migration plan fields, progress reporting, approval rules, rollback strategy, and resume guarantees are sufficient for a trust-critical database layer.

## Related Specification Files

- [../spec/schema/schema-model.md](../spec/schema/schema-model.md)
- [../spec/schema/versioning.md](../spec/schema/versioning.md)
- [../spec/schema/migrations.md](../spec/schema/migrations.md)
- [../spec/schema/data-migrations.md](../spec/schema/data-migrations.md)
- [../spec/schema/user-visible-migration-flow.md](../spec/schema/user-visible-migration-flow.md)
- [../spec/testing/migration-test-matrix.md](../spec/testing/migration-test-matrix.md)
