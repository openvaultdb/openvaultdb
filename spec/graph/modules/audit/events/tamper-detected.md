---
kind: event
id: tamper-detected
name: TamperDetected
status: draft
subject: audit.audit-entry
participants:
  - vaults.vault
sources:
  - automation
summary: Tamper-evidence verification failed for the audit log.
---

# Event: TamperDetected

## Description

Raised by hash-chain (or equivalent) verification, not by a command.
Tamper-evidence failure is visible to the user and blocks high-risk
operations until acknowledged.

## Open Questions

None at this time.
