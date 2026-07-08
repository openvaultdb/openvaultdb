---
kind: relationship
id: grant-scopes-namespace
name: grantScopesNamespace
status: draft
from: access.grant
to: vault.namespace
cardinality: many-to-many
metadata:
  risk: modelspec:///common.RiskLevel
summary: A grant scopes a principal's capabilities to namespaces within a vault.
---

# Relationship: grantScopesNamespace

## Description

Connect-style grants bind a principal to app namespaces inside one vault;
risk level drives the approval prompt.

## Open Questions

None at this time.
