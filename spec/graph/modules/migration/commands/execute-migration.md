---
kind: command
id: execute-migration
name: ExecuteMigration
status: draft
subject: migration.migration-plan
actors:
  - identity.user
possibleEvents:
  - migration.migration-started
  - migration.migration-completed
  - migration.migration-rolled-back
summary: Execute an approved plan in phases with checkpoints; MVP blocks application writes.
---

# Command: ExecuteMigration

## Description

Execution emits audit events for start, checkpoint, warning, error,
completion, rollback, and resume. The MVP runs one migration at a time per
vault.

## Failure Cases

- Checkpointing fails and execution stops in a recoverable state.
- A data migration failure fails fast unless the plan enables quarantine.

## Open Questions

None at this time.
