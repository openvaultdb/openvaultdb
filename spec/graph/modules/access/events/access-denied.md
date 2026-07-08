---
kind: event
id: access-denied
name: AccessDenied
status: draft
subject: access.capability
participants:
  - identity.application
sources:
  - automation
summary: An operation was denied by capability evaluation.
---

# Event: AccessDenied

## Description

Denials are produced by the vault's own enforcement (not by a command) and
must be auditable with inspectable reasons.

## Open Questions

None at this time.
