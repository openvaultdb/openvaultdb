---
kind: event
id: migration-interrupted
name: MigrationInterrupted
status: draft
subject: migration.migration-plan
sources:
  - external-system
  - automation
summary: Execution stopped before completion due to a crash, kill, or environmental failure.
---

# Event: MigrationInterrupted

## Description

Interruption originates outside the command flow (process kill, host
failure, watchdog); resume or rollback follows from the last checkpoint.

## Open Questions

None at this time.
