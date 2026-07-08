---
kind: entity
id: grant
name: Grant
status: draft
model: modelspec://access.Grant
lifecycle:
  states: [requested, approved, revoked, expired]
summary: A user-approved assignment of capabilities to a principal.
---

# Entity: Grant

## Description

Grants are explicit, scoped, and auditable; permission broadening requires
fresh approval; revocation invalidates future authorization decisions.

## Open Questions

None at this time.
