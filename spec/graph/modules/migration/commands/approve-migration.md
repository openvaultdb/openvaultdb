---
kind: command
id: approve-migration
name: ApproveMigration
status: draft
subject: migration.migration-plan
actors:
  - identity.user
possibleEvents:
  - migration.migration-approved
summary: The vault owner approves a migration plan under the configured approval policy.
---

# Command: ApproveMigration

## Description

Destructive changes, permission broadening, and storage backend migration
follow the configured approval policy; a caller can never self-approve
high-risk operations without the approval capability.

## Failure Cases

- The plan is not in the proposed state.

## Open Questions

None at this time.
