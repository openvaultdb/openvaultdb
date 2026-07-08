---
kind: command
id: approve-grant
name: ApproveGrant
status: draft
subject: access.grant
actors:
  - identity.user
possibleEvents:
  - access.grant-approved
summary: The vault owner approves (possibly narrowed) requested capabilities.
---

# Command: ApproveGrant

## Description

Approval records the principal, capabilities, resources, risk level, and
approving user context for audit reconstruction.

## Failure Cases

- The grant is no longer in the requested state.

## Open Questions

None at this time.
