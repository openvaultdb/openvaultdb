---
kind: relationship
id: vault-stored-in
name: vaultStoredIn
status: draft
from: vaults.vault
to: storage.backend
cardinality: many-to-many
summary: A vault's data and metadata live in one or more storage backends.
---

# Relationship: vaultStoredIn

## Description

Backend choice stays under vault control; backend migration uses the
migration workflow.

## Open Questions

None at this time.
