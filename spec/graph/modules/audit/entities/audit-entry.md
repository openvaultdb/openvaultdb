---
kind: entity
id: audit-entry
name: AuditEntry
status: draft
model: modelspec:///audit.AuditEntry
summary: A structured, append-only record of an action, decision, denial, or state transition.
---

# Entity: AuditEntry

## Description

Every entry carries timestamp, event type, actor chain, subject resource,
outcome, and correlation ID; entries avoid plaintext secrets and
unnecessary payloads.

## Open Questions

None at this time.
