---
kind: entity
id: migration-plan
name: MigrationPlan
status: draft
model: modelspec:///migration.MigrationPlan
lifecycle:
  states: [proposed, approved, executing, completed, rolled-back]
summary: A reviewable proposal identifying requester, scope, risk, reversibility, and approvals.
---

# Entity: MigrationPlan

## Description

Produced by comparing the current and target ModelSpec before any
backend-specific steps; distinguishes ModelSpec semantic changes from
OpenVaultDB-owned permission, audit, and backend changes.

## Open Questions

None at this time.
