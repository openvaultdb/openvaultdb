# SQLite Backend

## Purpose

Define expectations for a likely local MVP storage backend.

## Key Concepts

- SQLite store: local durable database file for encrypted vault content and metadata.
- Transaction: atomic unit for metadata, audit, and checkpoint updates.
- WAL mode: write-ahead logging behavior that may affect durability and leakage.
- Vacuum: maintenance operation that may affect deleted content retention.

## Normative Requirements

- SQLite storage MUST encrypt sensitive vault content before persistence or use a reviewed encrypted SQLite layer.
- Transaction boundaries MUST protect grant updates, audit writes, and migration checkpoints.
- Temporary files, journals, and WAL files MUST be considered part of the security boundary.
- SQLite schema changes for vault internals MUST be treated as storage format migrations.
- Backup and restore procedures MUST include integrity verification.

## MVP Behavior

The MVP may use SQLite as the local metadata and encrypted payload store if encryption, journaling, and checkpoint behavior are reviewed.

## Risks

- Journals or temporary files may retain sensitive plaintext if encryption is layered incorrectly.
- SQLite locking can complicate concurrent app access and migrations.
- Corruption recovery can conflict with audit-log append-only semantics.

## Open Questions

- Should MVP use SQLCipher, application-layer encryption, or both?
- What SQLite pragmas are required for durability and leakage control?
- Is concurrent access allowed or mediated by a single vault process?

## Acceptance Criteria

- Sensitive data is not written to plaintext SQLite pages, WAL, journals, or temp files.
- Migration checkpoints and audit events commit atomically with data changes where required.
- Restore validation detects corrupt or mismatched vault files.

## Related Specifications

- [local-first.md](local-first.md)
- [storage-backends.md](storage-backends.md)
- [../schema/migrations.md](../schema/migrations.md)
- [../security/audit-log.md](../security/audit-log.md)
