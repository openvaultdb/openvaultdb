---
kind: entity
id: application
name: Application
status: draft
model: modelspec://identity.Application
summary: Registered software requesting access to vault data or schema operations.
---

# Entity: Application

## Description

Software that registers with a vault, publishes its ModelSpec schema, and
requests capability grants. Applications own their namespaces' schemas but
never the user's data (see [vision](../../../../vision.md)).

## Open Questions

None at this time.
