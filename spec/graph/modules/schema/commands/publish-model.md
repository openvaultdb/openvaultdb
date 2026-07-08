---
kind: command
id: publish-model
name: PublishModel
status: draft
subject: schema.schema-version
actors:
  - identity.application
inputs:
  - name: namespace
    ref: vault.namespace
  - name: module-source
    model: modelspec:///schema.ModelSource
possibleEvents:
  - schema.model-published
summary: An application publishes a ModelSpec module version for its namespace.
---

# Command: PublishModel

## Description

The MVP ingestion path accepts a ModelSpec JSON AST serialization first,
remaining compatible with HCL-authored modules. Publishing a model does not
change stored data; adopting it happens through a migration plan.

## Failure Cases

- The payload is not a valid ModelSpec serialization.
- The publishing application does not own the namespace.

## Open Questions

None at this time.
