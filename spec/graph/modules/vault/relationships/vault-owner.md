---
kind: relationship
id: vault-owner
name: vaultOwner
status: draft
from: vault.vault
to: identity.user
cardinality: many-to-one
summary: Every vault has exactly one owning user principal.
---

# Relationship: vaultOwner

## Description

Ownership anchors approvals: the owner approves grants, migrations, and
destructive operations for the vault.

## Open Questions

None at this time.
