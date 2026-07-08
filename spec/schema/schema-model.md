# Schema Model

## Purpose

Define how vault data is described independently of any implementation language and storage backend.

## Key Concepts

- ModelSpec JSON module: the application-published logical model consumed by the vault.
- Collection: a named record set derived from or bound to a ModelSpec entity or projection.
- Field: named value with type and constraints derived from ModelSpec, plus OpenVaultDB-owned sensitivity and permission labels.
- Index: derived structure for lookup or ordering.
- Constraint: validation rule that can reject writes or migrations.
- Permission label: schema metadata used by grants and prompts.

## Normative Requirements

- Every application schema MUST identify the ModelSpec JSON module and version it was loaded from.
- OpenVaultDB MUST load the current ModelSpec and target ModelSpec before planning schema migrations.
- Fields MUST derive type, nullability, constraints, and migration behavior from ModelSpec plus OpenVaultDB-owned metadata.
- Sensitive fields SHOULD be labeled for prompt, audit, and export redaction.
- Indexes MUST be declared explicitly and migrated explicitly.
- Schema definitions MUST be reviewable as text.
- Schema changes MUST NOT silently broaden permissions.
- OpenVaultDB MUST keep permission labels, capability grants, audit policy, encryption state, and user approvals outside ModelSpec semantics.

## MVP Behavior

The MVP supports typed ModelSpec-backed collections, required and optional fields, simple indexes, sensitivity labels, and collection-level plus field-aware permission metadata.

## Risks

- Overly dynamic schemas can bypass review.
- Field renames can be mistaken for delete-and-add operations.
- Permission labels can drift from application expectations.

## Open Questions

- Are computed fields in MVP or deferred?
- How should schema validation errors be surfaced to users versus applications?

## Acceptance Criteria

- A schema reviewer can identify all fields, constraints, indexes, and permission labels.
- A field rename is represented as a rename with source and target, not as hidden data loss.
- Schema validation failures produce deterministic errors.

## Related Specifications

- [versioning.md](versioning.md)
- [modelspec-integration.md](modelspec-integration.md)
- [migrations.md](migrations.md)
- [../security/permissions-model.md](../security/permissions-model.md)
- [../api/api-model.md](../api/api-model.md)
