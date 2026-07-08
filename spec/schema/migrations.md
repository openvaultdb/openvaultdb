# Migrations

## Purpose

Define planning, approval, execution, rollback, and resume behavior for schema-related change.

## Key Concepts

- Migration plan: reviewable proposal before execution.
- Current ModelSpec: schema version currently governing stored data.
- Target ModelSpec: schema version requested by an application, user, or migration.
- Migration classes: schema, data, permission, index, storage format, encryption, and key rotation.
- Checkpoint: durable execution state.
- Rollback: planned return path or compensating action.
- Resume: continuation after interruption without duplicating unsafe effects.

## Normative Requirements

- Every migration MUST have a plan before execution.
- Schema migration planning MUST compare the current ModelSpec and target ModelSpec before producing backend-specific migration steps.
- Migration plans MUST distinguish ModelSpec semantic changes from OpenVaultDB-owned permission, audit, encryption, and backend changes.
- A migration plan MUST identify requester, app or AI agent, affected collections, estimated affected records, estimated duration, risk level, reversibility, backup strategy, rollback strategy, required permissions, and user approvals.
- Migrations MUST be checkpointed or idempotent.
- Destructive changes, permission broadening, encryption changes, key rotation, storage backend migration, and AI-triggered migrations MUST require explicit approval.
- Execution MUST emit audit events for proposal, approval, start, checkpoint, warning, error, completion, rollback, and resume.
- Interrupted migrations MUST resume safely or stop in a clearly recoverable state.
- Permission and index migrations MUST be planned as first-class migration types.

## MVP Behavior

The MVP runs one migration at a time per vault. The CLI displays a plan, requires approval for risky changes, creates a backup or restore point where feasible, executes in phases, records checkpoints, and supports resume after interruption.

## Risks

- Rollback may be impossible after destructive changes or key rotation.
- Record counts and ETA can be expensive or unavailable.
- User approval prompts can understate real risk.
- Concurrent app writes can invalidate migration assumptions.

## Open Questions

- Should MVP block all writes during migration?
- What backup format is required before destructive migrations?
- How should non-reversible migrations be represented in prompts?

## Acceptance Criteria

- Migration progress exposes phase, percentage, processed records, total records where known, ETA where possible, warnings, errors, checkpoint status, and resumability status.
- A killed migration can be resumed or reported as requiring rollback without silent corruption.
- Permission broadening and destructive field changes are blocked without explicit approval.

## Related Specifications

- [data-migrations.md](data-migrations.md)
- [modelspec-integration.md](modelspec-integration.md)
- [user-visible-migration-flow.md](user-visible-migration-flow.md)
- [../security/audit-log.md](../security/audit-log.md)
- [../testing/migration-test-matrix.md](../testing/migration-test-matrix.md)
