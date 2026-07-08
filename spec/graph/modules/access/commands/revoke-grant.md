---
kind: command
id: revoke-grant
name: RevokeGrant
status: draft
subject: access.grant
actors:
  - identity.user
possibleEvents:
  - access.grant-revoked
summary: The vault owner removes or narrows an active grant.
---

# Command: RevokeGrant

## Description

Revocation invalidates future authorization decisions; stale permission
caches must not authorize access after the grant version changes.

## Failure Cases

- The grant is already revoked or expired.

## Open Questions

None at this time.
