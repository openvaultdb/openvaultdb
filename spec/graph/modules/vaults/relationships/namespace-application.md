---
kind: relationship
id: namespace-application
name: namespaceApplication
status: draft
from: vaults.namespace
to: identity.application
cardinality: many-to-one
summary: A namespace is provisioned and schema-owned by exactly one application.
---

# Relationship: namespaceApplication

## Description

Namespaces are created by applications when the user connects them to a
vault; the application owns the structure, the user owns the data.

## Open Questions

None at this time.
