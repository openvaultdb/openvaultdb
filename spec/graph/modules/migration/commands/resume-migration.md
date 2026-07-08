---
kind: command
id: resume-migration
name: ResumeMigration
status: draft
subject: migration.migration-plan
actors:
  - identity.user
possibleEvents:
  - migration.migration-completed
  - migration.migration-rolled-back
summary: Continue an interrupted migration from its last checkpoint without duplicating unsafe effects.
---

# Command: ResumeMigration

## Description

A killed migration is resumed or reported as requiring rollback without
silent corruption.

## Failure Cases

- No usable checkpoint exists and the plan requires rollback instead.

## Open Questions

None at this time.
