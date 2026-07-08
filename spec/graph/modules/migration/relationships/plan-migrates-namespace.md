---
kind: relationship
id: plan-migrates-namespace
name: planMigratesNamespace
status: draft
from: migration.migration-plan
to: vaults.namespace
cardinality: many-to-many
metadata:
  risk: modelspec://common.RiskLevel
summary: A migration plan names the namespaces whose collections it affects.
---

# Relationship: planMigratesNamespace

## Description

Affected namespaces and estimated affected records are part of the
reviewable plan; risk level drives the approval policy.

## Open Questions

None at this time.
