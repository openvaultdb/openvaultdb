---
kind: command
id: register-application
name: RegisterApplication
status: draft
subject: identity.application
actors:
  - identity.user
possibleEvents:
  - access.application-registered
summary: Establish an application principal with a vault before any grant exists.
---

# Command: RegisterApplication

## Description

Explicit application registration precedes capability requests in the MVP
(see [api model](../../../../api/api-model.md) registration API).

## Failure Cases

- The application identity cannot be authenticated.

## Open Questions

None at this time.
