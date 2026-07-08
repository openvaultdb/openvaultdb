---
kind: entity
id: schema-version
name: SchemaVersion
status: draft
model: modelspec://schema.SchemaVersion
lifecycle:
  states: [loaded, current, superseded]
summary: A loaded ModelSpec module version governing a namespace's stored records.
---

# Entity: SchemaVersion

## Description

Identifies the ModelSpec module and version a namespace's records are
governed by. Migration planning compares the current and target schema
versions (see [versioning](../../../../schema/versioning.md)).

## Open Questions

None at this time.
