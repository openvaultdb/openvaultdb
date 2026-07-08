---
kind: event
id: rollback-detected
name: RollbackDetected
status: draft
subject: storage.backend
participants:
  - vault.vault
sources:
  - integration
summary: Integrity metadata indicates the provider served an unexpected earlier state.
---

# Event: RollbackDetected

## Description

Provider rollback can resurrect revoked grants or old data; detection is
raised from backend integration checks, not from a command.

## Open Questions

None at this time.
