---
kind: command
id: propose-migration
name: ProposeMigration
status: draft
subject: migration.migration-plan
actors:
  - identity.application
  - identity.ai-agent
inputs:
  - name: target-schema
    ref: schema.schema-version
possibleEvents:
  - migration.migration-proposed
summary: Produce a reviewable migration plan from a current-to-target ModelSpec diff.
---

# Command: ProposeMigration

## Description

Planning loads the current and target ModelSpec versions and computes a
semantic diff before producing backend-specific steps.

## Failure Cases

- The target schema version is unknown or fails validation.

## Open Questions

None at this time.
