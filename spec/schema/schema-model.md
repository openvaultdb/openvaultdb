# Schema Model

## Purpose

Define how vault data is described independently of any implementation language.

## Key Concepts

- Collection: a named record set with a current schema version.
- Field: named value with type, constraints, sensitivity, and permission labels.
- Index: derived structure for lookup or ordering.
- Constraint: validation rule that can reject writes or migrations.
- Permission label: schema metadata used by grants and prompts.

## Normative Requirements

- Every collection MUST declare a schema identifier and version.
- Fields MUST declare type, nullability, and migration behavior when changed.
- Sensitive fields SHOULD be labeled for prompt, audit, and export redaction.
- Indexes MUST be declared explicitly and migrated explicitly.
- Schema definitions MUST be reviewable as text.
- Schema changes MUST NOT silently broaden permissions.

## MVP Behavior

The MVP supports typed collections, required and optional fields, simple indexes, sensitivity labels, and collection-level plus field-aware permission metadata.

## Risks

- Overly dynamic schemas can bypass review.
- Field renames can be mistaken for delete-and-add operations.
- Permission labels can drift from application expectations.

## Open Questions

- Should schema definitions use JSON Schema, a custom DSL, or a constrained profile?
- Are computed fields in MVP or deferred?
- How should schema validation errors be surfaced to users versus applications?

## Acceptance Criteria

- A schema reviewer can identify all fields, constraints, indexes, and permission labels.
- A field rename is represented as a rename with source and target, not as hidden data loss.
- Schema validation failures produce deterministic errors.

## Related Specifications

- [versioning.md](versioning.md)
- [migrations.md](migrations.md)
- [../security/permissions-model.md](../security/permissions-model.md)
- [../api/api-model.md](../api/api-model.md)
