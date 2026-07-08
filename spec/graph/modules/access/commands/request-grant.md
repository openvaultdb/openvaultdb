---
kind: command
id: request-grant
name: RequestGrant
status: draft
subject: access.grant
actors:
  - identity.application
  - identity.ai-agent
inputs:
  - name: capability
    ref: access.capability
  - name: validity
    model: modelspec:///common.TimeWindow
possibleEvents:
  - access.grant-requested
summary: A principal requests capabilities; the CLI presents scopes and risk to the user.
---

# Command: RequestGrant

## Description

Requested scopes and risk are presented for user decision; the user may
approve, deny, or narrow (see [permissions model](../../../../security/permissions-model.md)).

## Failure Cases

- The requesting principal is not registered.
- The requested capability names an unknown resource.

## Open Questions

None at this time.
