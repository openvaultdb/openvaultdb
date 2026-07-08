---
kind: entity
id: vault
name: Vault
status: draft
model: modelspec://vaults.Vault
lifecycle:
  states: [active, migrating, locked]
summary: The user-owned unit of data, schemas, permissions, audit log, and metadata.
---

# Entity: Vault

## Description

The primary user-facing concept: the unit the user owns, names, and grants
applications access to. MVP migrations block application writes, which the
`migrating` lifecycle state captures (see [migrations](../../../../schema/migrations.md)).

## Open Questions

- Should `locked` cover tamper-evidence failure as well as administrative locks?
