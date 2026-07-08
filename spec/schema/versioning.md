# Schema Versioning

## Purpose

Define how schemas are identified, compared, and upgraded.

## Key Concepts

- Schema version: immutable identifier for a loaded ModelSpec definition plus OpenVaultDB-owned metadata.
- Compatibility: whether readers or writers can operate across versions.
- Drift: mismatch between declared schema and stored records.
- Version pin: application request to use a specific schema version.

## Normative Requirements

- A published schema version MUST be immutable.
- A loaded application schema version MUST record the ModelSpec module id, version, and source digest where available.
- Schema versions MUST identify parent version or origin.
- Compatibility metadata MUST state whether reads, writes, and migrations are allowed.
- Applications MUST declare the schema version they expect or accept.
- The vault MUST detect records whose stored schema version is inconsistent with collection metadata.

## MVP Behavior

The MVP uses monotonically ordered collection schema versions with immutable definitions and explicit upgrade plans.

## Risks

- Semantic versioning may imply compatibility that is not real.
- Old applications may write records that violate new constraints.
- Schema drift can become permission drift when labels change.

## Open Questions

- Should version identifiers be sequential, content-addressed, or both?
- How long should old schema versions remain writable?
- Should compatibility be computed or author-declared?

## Acceptance Criteria

- Stored records can be traced to the schema version that validated them.
- Applications cannot silently write against an unknown newer schema.
- Drift detection reports affected collections and record counts where known.

## Related Specifications

- [schema-model.md](schema-model.md)
- [modelspec-integration.md](modelspec-integration.md)
- [migrations.md](migrations.md)
- [../cli/commands.md](../cli/commands.md)
