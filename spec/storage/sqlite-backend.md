# SQLite Backend

## Purpose

Define expectations for the second OpenVaultDB storage backend after InGitDB/GitHub.

## Key Concepts

- SQLite store: local durable database file for vault content and metadata.
- Transaction: atomic unit for metadata, audit, and checkpoint updates.
- WAL mode: write-ahead logging behavior that may affect durability and leakage.
- Vacuum: maintenance operation that may affect deleted content retention.

## Normative Requirements

- SQLite storage MAY add encryption after MVP review; it is not the MVP storage mode.
- Transaction boundaries MUST protect grant updates, audit writes, and migration checkpoints.
- Temporary files, journals, and WAL files MUST be considered part of the security boundary.
- SQLite schema changes for vault internals MUST be treated as storage format migrations.
- Backup and restore procedures MUST include integrity verification.

## MVP Behavior

SQLite is the second backend target after the InGitDB/GitHub MVP. It may become the local metadata and payload store if journaling and checkpoint behavior are reviewed.

## Risks

- Journals or temporary files may retain sensitive plaintext.
- SQLite locking can complicate concurrent app access and migrations.
- Corruption recovery can conflict with audit-log append-only semantics.

## Open Questions

- Should post-MVP SQLite use SQLCipher, application-layer encryption, or neither?
- What SQLite pragmas are required for durability and leakage control?
- Is concurrent access allowed or mediated by a single vault process?

## Acceptance Criteria

- SQLite plaintext retention in pages, WAL, journals, and temp files is documented for non-encrypted deployments.
- Migration checkpoints and audit events commit atomically with data changes where required.
- Restore validation detects corrupt or mismatched vault files.

## Related Specifications

- [local-first.md](local-first.md)
- [storage-backends.md](storage-backends.md)
- [../schema/migrations.md](../schema/migrations.md)
- [../security/audit-log.md](../security/audit-log.md)
