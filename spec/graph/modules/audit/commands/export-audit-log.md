---
kind: command
id: export-audit-log
name: ExportAuditLog
status: draft
subject: audit.audit-entry
actors:
  - identity.user
possibleEvents:
  - audit.audit-exported
summary: Export audit entries preserving order and integrity metadata.
---

# Command: ExportAuditLog

## Description

Export preserves event order and integrity metadata for third-party
review; exports are themselves audited.

## Failure Cases

- Tamper-evidence verification fails and the export is blocked until acknowledged.

## Open Questions

None at this time.
