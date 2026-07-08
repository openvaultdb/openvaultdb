# Fable 5 Brief: Schema And Migration Review

## Current Proposal

Schemas are explicit and versioned. Migrations are reviewable plans covering schema, data, permissions, indexes, storage format, encryption, and key rotation. Execution is checkpointed or idempotent, progress is visible, and rollback or resume behavior is part of the plan.

## Key Risks

- Interrupted migrations can corrupt data or permission state.
- Destructive changes and field renames can cause silent data loss.
- Encryption and key rotation may be non-reversible.
- AI-triggered migrations may understate risk.
- Backend migrations can introduce provider-trust issues.

## Unresolved Questions

- Should all writes be blocked during migration?
- What backup format is mandatory before destructive migrations?
- What transform sandboxing is required?
- Should failed records block migration or enter quarantine?

## Expected Fable Review

Review whether migration plan fields, progress reporting, approval rules, rollback strategy, and resume guarantees are sufficient for a trust-critical database layer.

## Related Specification Files

- [../spec/schema/schema-model.md](../spec/schema/schema-model.md)
- [../spec/schema/versioning.md](../spec/schema/versioning.md)
- [../spec/schema/migrations.md](../spec/schema/migrations.md)
- [../spec/schema/data-migrations.md](../spec/schema/data-migrations.md)
- [../spec/schema/user-visible-migration-flow.md](../spec/schema/user-visible-migration-flow.md)
- [../spec/testing/migration-test-matrix.md](../spec/testing/migration-test-matrix.md)
